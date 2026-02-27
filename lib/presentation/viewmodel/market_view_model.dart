import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/model/market_trade_code_session.dart';
import 'package:nook_lounge_app/domain/repository/auth_repository.dart';
import 'package:nook_lounge_app/domain/repository/market_repository.dart';
import 'package:nook_lounge_app/presentation/state/market_view_state.dart';

class MarketViewModel extends StateNotifier<MarketViewState> {
  MarketViewModel({
    required MarketRepository repository,
    required AuthRepository authRepository,
  }) : _repository = repository,
       _authRepository = authRepository,
       super(const MarketViewState()) {
    _activeUserId = (_authRepository.currentUserId ?? '').trim();
    _offersSubscription = _repository.watchOffers().listen(
      _onOffersChanged,
      onError: (Object error, StackTrace stackTrace) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '마켓 데이터를 불러오지 못했어요.',
        );
      },
    );
    _authSubscription = _authRepository.watchUserId().listen((uid) {
      _onUserChanged(uid);
    });
    _bindHiddenOfferStream(_activeUserId);
  }

  final MarketRepository _repository;
  final AuthRepository _authRepository;
  StreamSubscription<List<MarketOffer>>? _offersSubscription;
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<Set<String>>? _hiddenSubscription;
  List<MarketOffer> _latestOffers = const <MarketOffer>[];
  Set<String> _hiddenOfferIds = const <String>{};
  Set<String> _guestHiddenOfferIds = <String>{};
  String _activeUserId = '';

  String get currentUserId => _authRepository.currentUserId ?? '';

  List<MarketOffer> get visibleOffers {
    final query = state.searchQuery.trim().toLowerCase();
    return state.offers
        .where((offer) {
          if (state.selectedCategory != MarketFilterCategory.all &&
              offer.category != state.selectedCategory) {
            return false;
          }

          if (query.isEmpty) {
            return true;
          }

          return offer.title.toLowerCase().contains(query) ||
              offer.ownerName.toLowerCase().contains(query) ||
              offer.offerItemName.toLowerCase().contains(query) ||
              offer.wantItemName.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  List<MarketOffer> get myOffers {
    return state.offers
        .where((offer) => offer.isMine)
        .where((offer) => offer.lifecycle == state.selectedLifecycle)
        .toList(growable: false);
  }

  MarketOffer? findOfferById(String id) {
    for (final offer in state.offers) {
      if (offer.id == id) {
        return offer;
      }
    }
    return null;
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void setCategory(MarketFilterCategory category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setLifecycle(MarketLifecycleTab tab) {
    state = state.copyWith(selectedLifecycle: tab);
  }

  Future<void> createOffer(MarketOffer offer) async {
    final currentUid = _authRepository.currentUserId ?? '';
    if (currentUid.isEmpty) {
      state = state.copyWith(errorMessage: '로그인 후 거래를 등록할 수 있어요.');
      return;
    }

    final createdAt = DateTime.now();
    final createdAtKey = createdAt.microsecondsSinceEpoch;
    final next = offer.copyWith(
      id: offer.id.isEmpty ? 'offer_$createdAtKey' : offer.id,
      ownerUid: currentUid,
      isMine: true,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    try {
      await _repository.createOffer(uid: currentUid, offer: next);
      state = state.copyWith(errorMessage: null);
    } catch (error) {
      final message = error is StateError
          ? '이미지 업로드 후 URL 저장에 실패했어요. 다시 시도해 주세요.'
          : '거래 등록에 실패했어요.';
      state = state.copyWith(errorMessage: message);
    }
  }

  Future<void> updateOffer(MarketOffer offer) async {
    final currentUid = _authRepository.currentUserId ?? '';
    if (currentUid.isEmpty) {
      state = state.copyWith(errorMessage: '로그인 후 거래를 수정할 수 있어요.');
      return;
    }
    if (offer.id.trim().isEmpty) {
      state = state.copyWith(errorMessage: '수정할 거래 ID를 찾지 못했어요.');
      return;
    }

    final next = offer.copyWith(
      ownerUid: currentUid,
      isMine: true,
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.updateOffer(uid: currentUid, offer: next);
      state = state.copyWith(errorMessage: null);
    } catch (error) {
      final message = error is StateError
          ? '이미지 업로드 후 URL 저장에 실패했어요. 다시 시도해 주세요.'
          : '거래 수정에 실패했어요.';
      state = state.copyWith(errorMessage: message);
    }
  }

  Future<void> setOfferLifecycle({
    required String offerId,
    required MarketLifecycleTab lifecycle,
    MarketOfferStatus? status,
  }) async {
    final optimistic = state.offers
        .map((offer) {
          if (offer.id != offerId) {
            return offer;
          }
          return offer.copyWith(
            lifecycle: lifecycle,
            status: status ?? offer.status,
          );
        })
        .toList(growable: false);
    state = state.copyWith(offers: optimistic);

    try {
      await _repository.updateOfferLifecycle(
        offerId: offerId,
        lifecycle: lifecycle,
        status: status,
      );
    } catch (_) {
      state = state.copyWith(errorMessage: '상태 변경에 실패했어요.');
    }
  }

  Future<void> completeTrade({required MarketOffer offer}) async {
    final requesterUid = currentUserId.trim();
    if (requesterUid.isEmpty) {
      state = state.copyWith(errorMessage: '로그인 후 거래 완료를 처리할 수 있어요.');
      throw StateError('unauthenticated');
    }

    final previous = state.offers;
    final optimistic = previous
        .map((item) {
          if (item.id != offer.id) {
            return item;
          }
          return item.copyWith(
            lifecycle: MarketLifecycleTab.completed,
            status: MarketOfferStatus.closed,
            updatedAt: DateTime.now(),
          );
        })
        .toList(growable: false);

    state = state.copyWith(
      offers: _sortOffersForDisplay(optimistic),
      errorMessage: null,
    );

    final normalizedTitle = offer.title.trim().isEmpty
        ? offer.wantItemName.trim()
        : offer.title.trim();
    try {
      await _repository.completeTrade(
        offerId: offer.id,
        requesterUid: requesterUid,
        offerTitle: normalizedTitle,
      );
    } catch (error) {
      final errorCode = _readStateErrorCode(error);
      final errorMessage =
          errorCode == 'trade_complete_no_active_proposal' ||
              errorCode == 'trade_complete_unavailable'
          ? '거래가 취소되었거나 상대가 없어 완료할 수 없어요.'
          : errorCode == 'trade_complete_permission_denied'
          ? '거래 당사자만 완료할 수 있어요.'
          : '거래 완료 처리에 실패했어요.';
      state = state.copyWith(
        offers: _sortOffersForDisplay(previous),
        errorMessage: errorMessage,
      );
      rethrow;
    }
  }

  Future<void> updateOfferBasicInfo({
    required String offerId,
    required String title,
    required String description,
  }) async {
    final nextTitle = title.trim();
    final nextDescription = description.trim();
    if (nextTitle.isEmpty) {
      state = state.copyWith(errorMessage: '제목을 입력해 주세요.');
      return;
    }

    final previous = state.offers;
    final optimistic = previous
        .map((offer) {
          if (offer.id != offerId) {
            return offer;
          }
          return offer.copyWith(title: nextTitle, description: nextDescription);
        })
        .toList(growable: false);
    state = state.copyWith(offers: optimistic, errorMessage: null);

    try {
      await _repository.updateOfferBasicInfo(
        offerId: offerId,
        title: nextTitle,
        description: nextDescription,
      );
    } catch (_) {
      state = state.copyWith(offers: previous, errorMessage: '거래 글 수정에 실패했어요.');
    }
  }

  Future<void> deleteOffer(String offerId) async {
    final previous = state.offers;
    state = state.copyWith(
      offers: previous
          .where((offer) => offer.id != offerId)
          .toList(growable: false),
    );

    try {
      await _repository.deleteOffer(offerId);
    } catch (_) {
      state = state.copyWith(offers: previous, errorMessage: '거래 삭제에 실패했어요.');
    }
  }

  Future<void> sendTradeProposal({required MarketOffer offer}) async {
    final proposerUid = _authRepository.currentUserId ?? '';
    if (proposerUid.isEmpty) {
      state = state.copyWith(errorMessage: '로그인 후 거래 제안을 보낼 수 있어요.');
      throw StateError('unauthenticated');
    }
    if (offer.ownerUid.trim().isEmpty) {
      state = state.copyWith(errorMessage: '거래 작성자 정보를 찾지 못했어요.');
      throw StateError('invalid_offer_owner');
    }
    if (offer.ownerUid == proposerUid) {
      state = state.copyWith(errorMessage: '내 거래글에는 제안할 수 없어요.');
      throw StateError('own_offer');
    }

    final normalizedTitle = offer.title.trim().isEmpty
        ? offer.wantItemName.trim()
        : offer.title.trim();

    try {
      await _repository.sendTradeProposalNotification(
        offerId: offer.id,
        ownerUid: offer.ownerUid,
        proposerUid: proposerUid,
        offerTitle: normalizedTitle,
      );
    } catch (error) {
      final errorCode = _readStateErrorCode(error);
      final errorMessage = errorCode == 'trade_reproposal_not_allowed'
          ? '해당 거래는 다시 제안할 수 없어요.'
          : errorCode == 'trade_proposal_already_exists'
          ? '이미 제안을 보냈어요. 응답을 기다려 주세요.'
          : '거래 제안을 보내지 못했어요.';
      state = state.copyWith(errorMessage: errorMessage);
      rethrow;
    }

    state = state.copyWith(errorMessage: null);
  }

  Future<({MarketTradeCodeSession session, bool shouldSendCode})>
  acceptTradeProposalAsOwner({
    required MarketOffer offer,
    required String proposerUid,
  }) async {
    final ownerUid = currentUserId;
    if (ownerUid.isEmpty) {
      state = state.copyWith(errorMessage: '로그인 후 거래 승낙을 진행할 수 있어요.');
      throw StateError('unauthenticated');
    }
    if (offer.ownerUid.trim().isEmpty) {
      state = state.copyWith(errorMessage: '거래 작성자 정보를 찾지 못했어요.');
      throw StateError('invalid_offer_owner');
    }
    if (offer.ownerUid != ownerUid) {
      state = state.copyWith(errorMessage: '작성자만 제안을 승낙할 수 있어요.');
      throw StateError('permission_denied');
    }

    final targetProposerUid = proposerUid.trim();
    if (targetProposerUid.isEmpty) {
      state = state.copyWith(errorMessage: '승낙할 제안을 선택해 주세요.');
      throw StateError('invalid_proposer');
    }

    final normalizedTitle = offer.title.trim().isEmpty
        ? offer.wantItemName.trim()
        : offer.title.trim();
    final session = await _repository.acceptTradeProposal(
      offerId: offer.id,
      ownerUid: ownerUid,
      proposerUid: targetProposerUid,
      moveType: offer.moveType,
      offerTitle: normalizedTitle,
    );

    final shouldSendCode = session.isCodeSender(ownerUid);
    state = state.copyWith(errorMessage: null);
    return (session: session, shouldSendCode: shouldSendCode);
  }

  Future<void> sendTradeCode({
    required MarketOffer offer,
    required String receiverUid,
    required String code,
  }) async {
    final senderUid = currentUserId;
    if (senderUid.isEmpty) {
      state = state.copyWith(errorMessage: '로그인 후 코드를 보낼 수 있어요.');
      throw StateError('unauthenticated');
    }
    await _repository.sendTradeCode(
      offerId: offer.id,
      senderUid: senderUid,
      receiverUid: receiverUid,
      code: code,
      offerTitle: offer.title,
    );
    state = state.copyWith(errorMessage: null);
  }

  Future<MarketTradeCodeSession?> fetchTradeCodeSession(String offerId) {
    return _repository.fetchTradeCodeSession(offerId);
  }

  Future<String?> fetchPreferredTradeDodoCode({required String offerId}) async {
    final senderUid = currentUserId.trim();
    if (senderUid.isEmpty) {
      return null;
    }
    return _repository.fetchPreferredTradeDodoCode(
      offerId: offerId,
      senderUid: senderUid,
    );
  }

  Future<void> cancelTrade({required MarketOffer offer}) async {
    final requesterUid = currentUserId.trim();
    if (requesterUid.isEmpty) {
      state = state.copyWith(errorMessage: '로그인 후 거래 취소를 진행할 수 있어요.');
      throw StateError('unauthenticated');
    }

    final ownerUid = offer.ownerUid.trim();
    if (ownerUid.isEmpty) {
      state = state.copyWith(errorMessage: '거래 작성자 정보를 찾지 못했어요.');
      throw StateError('invalid_offer_owner');
    }

    final normalizedTitle = offer.title.trim().isEmpty
        ? offer.wantItemName.trim()
        : offer.title.trim();

    await _repository.cancelTrade(
      offerId: offer.id,
      ownerUid: ownerUid,
      requesterUid: requesterUid,
      offerTitle: normalizedTitle,
    );
    state = state.copyWith(errorMessage: null);
  }

  Future<void> reportOffer({
    required MarketOffer offer,
    required String reason,
    String detail = '',
  }) async {
    final reporterUid = currentUserId.trim();
    if (reporterUid.isEmpty) {
      state = state.copyWith(errorMessage: '로그인 후 신고할 수 있어요.');
      throw StateError('unauthenticated');
    }

    final ownerUid = offer.ownerUid.trim();
    if (ownerUid.isEmpty) {
      state = state.copyWith(errorMessage: '거래 작성자 정보를 찾지 못했어요.');
      throw StateError('invalid_offer_owner');
    }
    if (ownerUid == reporterUid) {
      state = state.copyWith(errorMessage: '내 거래글은 신고할 수 없어요.');
      throw StateError('cannot_report_own_offer');
    }

    await _repository.reportTradeOffer(
      offerId: offer.id,
      ownerUid: ownerUid,
      reporterUid: reporterUid,
      reason: reason,
      detail: detail,
    );
    state = state.copyWith(errorMessage: null);
  }

  Future<void> hideOffer({required MarketOffer offer}) async {
    final offerId = offer.id.trim();
    if (offerId.isEmpty) {
      state = state.copyWith(errorMessage: '숨길 거래 글 정보를 찾지 못했어요.');
      throw StateError('invalid_offer_id');
    }

    final currentUid = currentUserId.trim();
    final isMine = currentUid.isNotEmpty && offer.ownerUid.trim() == currentUid;
    if (isMine) {
      state = state.copyWith(errorMessage: '내 거래글은 숨길 수 없어요.');
      throw StateError('cannot_hide_own_offer');
    }

    if (currentUid.isEmpty) {
      _guestHiddenOfferIds = <String>{..._guestHiddenOfferIds, offerId};
      _applyOffersState();
      state = state.copyWith(errorMessage: null);
      return;
    }

    final previousHidden = _hiddenOfferIds;
    _hiddenOfferIds = <String>{..._hiddenOfferIds, offerId};
    _applyOffersState();

    try {
      await _repository.hideOfferForUser(uid: currentUid, offerId: offerId);
      state = state.copyWith(errorMessage: null);
    } catch (_) {
      _hiddenOfferIds = previousHidden;
      _applyOffersState();
      state = state.copyWith(errorMessage: '거래 글 숨기기에 실패했어요.');
      rethrow;
    }
  }

  void _onOffersChanged(List<MarketOffer> offers) {
    _latestOffers = offers;
    _applyOffersState();
  }

  void _onUserChanged(String? uid) {
    final normalizedUid = (uid ?? '').trim();
    if (_activeUserId == normalizedUid) {
      return;
    }
    _activeUserId = normalizedUid;
    // 유지보수 포인트:
    // 로그인 유저가 바뀌면 비회원 로컬 숨김 상태는 초기화합니다.
    _guestHiddenOfferIds = <String>{};
    _bindHiddenOfferStream(normalizedUid);
    _applyOffersState();
  }

  void _bindHiddenOfferStream(String uid) {
    _hiddenSubscription?.cancel();
    if (uid.isEmpty) {
      _hiddenOfferIds = const <String>{};
      return;
    }
    _hiddenSubscription = _repository
        .watchHiddenOfferIds(uid)
        .listen(
          (hiddenIds) {
            _hiddenOfferIds = hiddenIds;
            _applyOffersState();
          },
          onError: (Object error, StackTrace stackTrace) {
            state = state.copyWith(errorMessage: '숨김 목록을 불러오지 못했어요.');
          },
        );
  }

  void _applyOffersState() {
    final currentUid = _activeUserId;
    final hiddenIds = currentUid.isEmpty
        ? _guestHiddenOfferIds
        : _hiddenOfferIds;
    final normalized = _latestOffers
        .map((offer) {
          final bool isMine = offer.ownerUid == currentUid;
          return offer.copyWith(isMine: isMine);
        })
        .where((offer) {
          if (offer.isMine) {
            return true;
          }
          return !hiddenIds.contains(offer.id);
        })
        .toList(growable: false);

    state = state.copyWith(
      offers: _sortOffersForDisplay(normalized),
      isLoading: false,
    );
  }

  List<MarketOffer> _sortOffersForDisplay(List<MarketOffer> offers) {
    final sorted = offers.toList();
    sorted.sort((a, b) {
      final rankA = _offerDisplayRank(a);
      final rankB = _offerDisplayRank(b);
      if (rankA != rankB) {
        return rankA.compareTo(rankB);
      }
      final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
      if (updatedCompare != 0) {
        return updatedCompare;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted.toList(growable: false);
  }

  int _offerDisplayRank(MarketOffer offer) {
    if (offer.lifecycle == MarketLifecycleTab.completed ||
        offer.status == MarketOfferStatus.closed) {
      return 1;
    }
    return 0;
  }

  String _readStateErrorCode(Object error) {
    if (error is StateError) {
      return error.message.toString();
    }
    return '';
  }

  @override
  void dispose() {
    _offersSubscription?.cancel();
    _authSubscription?.cancel();
    _hiddenSubscription?.cancel();
    super.dispose();
  }
}
