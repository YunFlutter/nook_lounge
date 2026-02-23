import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
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
    _subscription = _repository.watchOffers().listen(
      _onOffersChanged,
      onError: (Object error, StackTrace stackTrace) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '마켓 데이터를 불러오지 못했어요.',
        );
      },
    );
  }

  final MarketRepository _repository;
  final AuthRepository _authRepository;
  StreamSubscription<List<MarketOffer>>? _subscription;

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

  void _onOffersChanged(List<MarketOffer> offers) {
    final currentUid = _authRepository.currentUserId ?? '';
    final normalized = offers
        .map((offer) {
          final bool isMine = offer.ownerUid == currentUid;
          return offer.copyWith(isMine: isMine);
        })
        .toList(growable: false);

    state = state.copyWith(
      offers: normalized,
      isLoading: false,
      errorMessage: null,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
