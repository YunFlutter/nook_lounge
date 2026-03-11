import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/core/constants/market_report_constants.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/model/market_trade_code_session.dart';
import 'package:nook_lounge_app/domain/repository/auth_repository.dart';
import 'package:nook_lounge_app/domain/repository/market_repository.dart';
import 'package:nook_lounge_app/domain/repository/user_block_repository.dart';
import 'package:nook_lounge_app/presentation/state/market_view_state.dart';

class MarketViewModel extends StateNotifier<MarketViewState> {
  MarketViewModel({
    required MarketRepository repository,
    required AuthRepository authRepository,
    required UserBlockRepository userBlockRepository,
  }) : _repository = repository,
       _authRepository = authRepository,
       _userBlockRepository = userBlockRepository,
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
    _bindBlockedUserStream(_activeUserId);
  }

  final MarketRepository _repository;
  final AuthRepository _authRepository;
  final UserBlockRepository _userBlockRepository;
  StreamSubscription<List<MarketOffer>>? _offersSubscription;
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<Set<String>>? _hiddenSubscription;
  StreamSubscription<Set<String>>? _blockedUserSubscription;
  StreamSubscription<Set<String>>? _myActiveProposalOfferIdsSubscription;
  List<MarketOffer> _latestOffers = const <MarketOffer>[];
  Set<String> _hiddenOfferIds = const <String>{};
  Set<String> _guestHiddenOfferIds = <String>{};
  Set<String> _blockedUserIds = const <String>{};
  Set<String> _activeProposalOfferIds = const <String>{};
  final Set<String> _acceptingOfferIds = <String>{};
  final Set<String> _sendingCodeOfferIds = <String>{};
  String _activeUserId = '';
  bool _isProposalTrackingEnabled = false;

  String get currentUserId => _authRepository.currentUserId ?? '';

  bool get isProposalTrackingEnabled => _isProposalTrackingEnabled;

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

  List<MarketOffer> get ongoingTradeOffers {
    final combined = <MarketOffer>[
      ...ownedOffersByLifecycle(MarketLifecycleTab.ongoing),
      ...proposalOffers,
    ];
    return _sortOffersForDisplay(combined);
  }

  int get ongoingTradeCount => ongoingTradeOffers.length;

  Map<MarketLifecycleTab, int> get myOfferCounts {
    final counts = <MarketLifecycleTab, int>{
      MarketLifecycleTab.ongoing: 0,
      MarketLifecycleTab.cancelled: 0,
      MarketLifecycleTab.completed: 0,
    };
    for (final offer in state.offers) {
      if (!offer.isMine) {
        continue;
      }
      counts[offer.lifecycle] = (counts[offer.lifecycle] ?? 0) + 1;
    }
    return counts;
  }

  List<MarketOffer> ownedOffersByLifecycle(MarketLifecycleTab lifecycle) {
    return state.offers
        .where((offer) => offer.isMine)
        .where((offer) => offer.lifecycle == lifecycle)
        .toList(growable: false);
  }

  List<MarketOffer> get proposalOffers {
    return state.offers
        .where((offer) {
          if (offer.isMine) {
            return false;
          }
          // 유지보수 포인트:
          // 내 소유 글이 아니더라도 아직 참여 중인 제안은
          // "진행중" 탭에 함께 보여주기 위해 pending/accepted 제안만 포함합니다.
          return offer.lifecycle == MarketLifecycleTab.ongoing &&
              _activeProposalOfferIds.contains(offer.id);
        })
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

  void ensureProposalTracking() {
    if (_isProposalTrackingEnabled) {
      return;
    }
    _isProposalTrackingEnabled = true;
    _bindMyActiveProposalOfferIdsStream(_activeUserId);
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
    final proposerUid = (_authRepository.currentUserId ?? '').trim();
    if (proposerUid.isEmpty) {
      state = state.copyWith(errorMessage: '로그인 후 거래 제안을 보낼 수 있어요.');
      throw StateError('unauthenticated');
    }
    final ownerUid = offer.ownerUid.trim();
    if (ownerUid.isEmpty) {
      state = state.copyWith(errorMessage: '거래 작성자 정보를 찾지 못했어요.');
      throw StateError('invalid_offer_owner');
    }
    if (ownerUid == proposerUid) {
      state = state.copyWith(errorMessage: '내 거래글에는 제안할 수 없어요.');
      throw StateError('own_offer');
    }
    if (_blockedUserIds.contains(ownerUid) ||
        await _userBlockRepository.hasBlockRelationship(
          uid: proposerUid,
          otherUid: ownerUid,
        )) {
      state = state.copyWith(errorMessage: '차단된 유저와는 거래 제안을 할 수 없어요.');
      throw StateError('blocked_user');
    }

    final normalizedTitle = offer.title.trim().isEmpty
        ? offer.wantItemName.trim()
        : offer.title.trim();
    final previousActiveProposalOfferIds = _activeProposalOfferIds;
    _setProposalOfferActiveLocally(offerId: offer.id, isActive: true);

    try {
      await _repository.sendTradeProposalNotification(
        offerId: offer.id,
        ownerUid: ownerUid,
        proposerUid: proposerUid,
        offerTitle: normalizedTitle,
      );
    } catch (error) {
      final errorCode = _readStateErrorCode(error);
      final errorMessage = errorCode == 'trade_reproposal_not_allowed'
          ? '해당 거래는 다시 제안할 수 없어요.'
          : errorCode == 'trade_offer_locked'
          ? '이미 다른 상대와 진행 중인 거래라 새 제안을 받을 수 없어요.'
          : errorCode == 'trade_offer_unavailable'
          ? '현재 거래가 열려 있지 않아 제안할 수 없어요.'
          : errorCode == 'trade_proposal_already_exists'
          ? '이미 제안을 보냈어요. 응답을 기다려 주세요.'
          : '거래 제안을 보내지 못했어요.';
      _activeProposalOfferIds = previousActiveProposalOfferIds;
      _applyOffersState();
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
    late final MarketTradeCodeSession session;
    try {
      session = await _runSingleFlight<MarketTradeCodeSession>(
        registry: _acceptingOfferIds,
        key: offer.id,
        errorCode: 'trade_accept_in_progress',
        errorMessage: '이미 이 거래의 승낙을 처리 중이에요.',
        action: () {
          return _repository.acceptTradeProposal(
            offerId: offer.id,
            ownerUid: ownerUid,
            proposerUid: targetProposerUid,
            moveType: offer.moveType,
            offerTitle: normalizedTitle,
          );
        },
      );
    } catch (error) {
      final errorCode = _readStateErrorCode(error);
      state = state.copyWith(
        errorMessage: errorCode == 'touching_trade_accept_limit_exceeded'
            ? '만지작 줄서기는 동시에 최대 8명까지만 승낙할 수 있어요.'
            : errorCode == 'trade_accept_in_progress'
            ? '이미 이 거래의 승낙을 처리 중이에요.'
            : errorCode == 'trade_proposal_not_found' ||
                  errorCode == 'trade_proposal_unavailable'
            ? '이미 취소되었거나 지금은 승낙할 수 없는 제안이에요.'
            : errorCode == 'trade_offer_locked'
            ? '이미 진행 중인 상대가 있어요. 현재 거래를 먼저 정리해 주세요.'
            : errorCode == 'trade_offer_unavailable'
            ? '이미 종료되었거나 취소된 거래예요.'
            : '거래 승낙에 실패했어요. 다시 시도해 주세요.',
      );
      rethrow;
    }

    final shouldSendCode = session.isCodeSender(ownerUid);
    state = state.copyWith(errorMessage: null);
    return (session: session, shouldSendCode: shouldSendCode);
  }

  Future<void> sendTradeCode({
    required MarketOffer offer,
    required String receiverUid,
    required String code,
    required String islandRules,
  }) async {
    final senderUid = currentUserId;
    if (senderUid.isEmpty) {
      state = state.copyWith(errorMessage: '로그인 후 코드를 보낼 수 있어요.');
      throw StateError('unauthenticated');
    }
    await _runSingleFlight<void>(
      registry: _sendingCodeOfferIds,
      key: offer.id,
      errorCode: 'trade_code_send_in_progress',
      errorMessage: '이미 이 거래의 코드 전송을 진행 중이에요.',
      action: () {
        return _repository.sendTradeCode(
          offerId: offer.id,
          senderUid: senderUid,
          receiverUid: receiverUid,
          code: code,
          islandRules: islandRules,
          offerTitle: offer.title,
        );
      },
    );
    state = state.copyWith(errorMessage: null);
  }

  Future<void> agreeTradeRules({
    required MarketOffer offer,
    required String inviteCode,
  }) async {
    final receiverUid = currentUserId.trim();
    if (receiverUid.isEmpty) {
      state = state.copyWith(errorMessage: '로그인 후 규칙 동의를 진행해 주세요.');
      throw StateError('unauthenticated');
    }
    final normalizedInviteCode = inviteCode.trim().toUpperCase();
    if (normalizedInviteCode.isEmpty) {
      state = state.copyWith(errorMessage: '아직 확인할 코드가 준비되지 않았어요.');
      throw StateError('trade_code_not_ready');
    }

    await _repository.agreeTradeRules(
      offerId: offer.id,
      receiverUid: receiverUid,
      code: normalizedInviteCode,
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

  Future<String?> fetchPreferredTradeIslandRules({
    required String offerId,
  }) async {
    final senderUid = currentUserId.trim();
    if (senderUid.isEmpty) {
      return null;
    }
    return _repository.fetchPreferredTradeIslandRules(
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
    final requesterIsOwner = requesterUid == ownerUid;
    final previousActiveProposalOfferIds = _activeProposalOfferIds;
    if (!requesterIsOwner) {
      _setProposalOfferActiveLocally(offerId: offer.id, isActive: false);
    }

    try {
      await _repository.cancelTrade(
        offerId: offer.id,
        ownerUid: ownerUid,
        requesterUid: requesterUid,
        offerTitle: normalizedTitle,
      );
      state = state.copyWith(errorMessage: null);
    } catch (error) {
      if (!requesterIsOwner) {
        _activeProposalOfferIds = previousActiveProposalOfferIds;
        _applyOffersState();
      }
      rethrow;
    }
  }

  Future<void> reportOffer({
    required MarketOffer offer,
    required String reason,
    String detail = '',
  }) async {
    final normalizedReason = reason.trim();
    final normalizedDetail = detail.trim();
    final reporterUid = currentUserId.trim();
    if (reporterUid.isEmpty) {
      state = state.copyWith(errorMessage: '로그인 후 신고할 수 있어요.');
      throw StateError('unauthenticated');
    }
    if (normalizedReason.isEmpty) {
      state = state.copyWith(errorMessage: '신고 사유를 선택해 주세요.');
      throw StateError('invalid_trade_report_reason');
    }
    if (normalizedReason == MarketReportConstants.otherReasonLabel &&
        normalizedDetail.isEmpty) {
      state = state.copyWith(errorMessage: '기타 사유를 입력해 주세요.');
      throw StateError('invalid_trade_report_detail');
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
      reason: normalizedReason,
      detail: normalizedDetail,
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

  Future<void> blockUserForMe({required String blockedUid}) async {
    final currentUid = currentUserId.trim();
    if (currentUid.isEmpty) {
      state = state.copyWith(errorMessage: '로그인 후 유저를 차단할 수 있어요.');
      throw StateError('unauthenticated');
    }

    final normalizedBlockedUid = blockedUid.trim();
    if (normalizedBlockedUid.isEmpty) {
      state = state.copyWith(errorMessage: '차단할 유저 정보를 찾지 못했어요.');
      throw StateError('invalid_blocked_uid');
    }
    if (normalizedBlockedUid == currentUid) {
      state = state.copyWith(errorMessage: '본인 계정은 차단할 수 없어요.');
      throw StateError('cannot_block_self');
    }

    final previousBlockedUserIds = _blockedUserIds;
    _blockedUserIds = <String>{..._blockedUserIds, normalizedBlockedUid};
    _applyOffersState();

    try {
      await _userBlockRepository.blockUser(
        uid: currentUid,
        blockedUid: normalizedBlockedUid,
      );
      state = state.copyWith(errorMessage: null);
    } catch (_) {
      _blockedUserIds = previousBlockedUserIds;
      _applyOffersState();
      state = state.copyWith(errorMessage: '유저 차단에 실패했어요.');
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
    _bindBlockedUserStream(normalizedUid);
    if (_isProposalTrackingEnabled) {
      _bindMyActiveProposalOfferIdsStream(normalizedUid);
    } else {
      _activeProposalOfferIds = const <String>{};
      state = state.copyWith(proposalErrorMessage: null);
    }
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

  void _bindBlockedUserStream(String uid) {
    _blockedUserSubscription?.cancel();
    if (uid.isEmpty) {
      _blockedUserIds = const <String>{};
      return;
    }
    _blockedUserSubscription = _userBlockRepository
        .watchInvisibleUserIds(uid)
        .listen(
          (blockedUserIds) {
            _blockedUserIds = blockedUserIds;
            _applyOffersState();
          },
          onError: (Object error, StackTrace stackTrace) {
            state = state.copyWith(errorMessage: '차단/상호 숨김 목록을 불러오지 못했어요.');
          },
        );
  }

  void _bindMyActiveProposalOfferIdsStream(String uid) {
    _myActiveProposalOfferIdsSubscription?.cancel();
    if (uid.isEmpty) {
      _activeProposalOfferIds = const <String>{};
      state = state.copyWith(proposalErrorMessage: null);
      return;
    }
    _myActiveProposalOfferIdsSubscription = _repository
        .watchMyActiveProposalOfferIds(uid)
        .listen(
          (offerIds) {
            _activeProposalOfferIds = offerIds;
            state = state.copyWith(proposalErrorMessage: null);
            _applyOffersState();
          },
          onError: (Object error, StackTrace stackTrace) {
            _activeProposalOfferIds = const <String>{};
            state = state.copyWith(
              proposalErrorMessage: '진행중 거래 일부를 불러오지 못했어요.',
            );
            _applyOffersState();
          },
        );
  }

  void _applyOffersState() {
    final currentUid = _activeUserId;
    final hiddenIds = currentUid.isEmpty
        ? _guestHiddenOfferIds
        : _hiddenOfferIds;
    final blockedUserIds = currentUid.isEmpty
        ? const <String>{}
        : _blockedUserIds;
    final normalized = _latestOffers
        .map((offer) {
          final bool isMine = offer.ownerUid == currentUid;
          return offer.copyWith(isMine: isMine);
        })
        .where((offer) {
          if (offer.isMine) {
            return true;
          }
          if (blockedUserIds.contains(offer.ownerUid.trim())) {
            return false;
          }
          return !hiddenIds.contains(offer.id);
        })
        .toList(growable: false);

    state = state.copyWith(
      offers: _sortOffersForDisplay(normalized),
      isLoading: false,
    );
  }

  void _setProposalOfferActiveLocally({
    required String offerId,
    required bool isActive,
  }) {
    final normalizedOfferId = offerId.trim();
    if (normalizedOfferId.isEmpty) {
      return;
    }
    _activeProposalOfferIds = isActive
        ? <String>{..._activeProposalOfferIds, normalizedOfferId}
        : <String>{
            ..._activeProposalOfferIds.where((id) => id != normalizedOfferId),
          };
    _applyOffersState();
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

  Future<T> _runSingleFlight<T>({
    required Set<String> registry,
    required String key,
    required String errorCode,
    required String errorMessage,
    required Future<T> Function() action,
  }) async {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) {
      return action();
    }
    if (!registry.add(normalizedKey)) {
      state = state.copyWith(errorMessage: errorMessage);
      throw StateError(errorCode);
    }

    try {
      return await action();
    } finally {
      registry.remove(normalizedKey);
    }
  }

  @override
  void dispose() {
    _offersSubscription?.cancel();
    _authSubscription?.cancel();
    _hiddenSubscription?.cancel();
    _blockedUserSubscription?.cancel();
    _myActiveProposalOfferIdsSubscription?.cancel();
    super.dispose();
  }
}
