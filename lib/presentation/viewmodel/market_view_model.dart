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

    final createdAtMillis = DateTime.now().millisecondsSinceEpoch;
    final next = offer.copyWith(
      id: offer.id.isEmpty ? 'offer_$createdAtMillis' : offer.id,
      ownerUid: currentUid,
      isMine: true,
      createdAtMillis: createdAtMillis,
      createdAtLabel: _buildElapsedLabel(createdAtMillis),
    );

    try {
      await _repository.createOffer(next);
      state = state.copyWith(clearErrorMessage: true);
    } catch (_) {
      state = state.copyWith(errorMessage: '거래 등록에 실패했어요.');
    }
  }

  Future<void> setOfferLifecycle({
    required String offerId,
    required MarketLifecycleTab lifecycle,
  }) async {
    final optimistic = state.offers
        .map((offer) {
          if (offer.id != offerId) {
            return offer;
          }
          return offer.copyWith(lifecycle: lifecycle);
        })
        .toList(growable: false);
    state = state.copyWith(offers: optimistic);

    try {
      await _repository.updateOfferLifecycle(
        offerId: offerId,
        lifecycle: lifecycle,
      );
    } catch (_) {
      state = state.copyWith(errorMessage: '상태 변경에 실패했어요.');
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
          final int millis = offer.createdAtMillis;
          return offer.copyWith(
            isMine: isMine,
            createdAtLabel: _buildElapsedLabel(millis),
          );
        })
        .toList(growable: false);

    state = state.copyWith(
      offers: normalized,
      isLoading: false,
      clearErrorMessage: true,
    );
  }

  String _buildElapsedLabel(int createdAtMillis) {
    if (createdAtMillis <= 0) {
      return '방금 전';
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - createdAtMillis;
    if (diff < 60 * 1000) {
      return '방금 전';
    }
    final minutes = diff ~/ (60 * 1000);
    if (minutes < 60) {
      return '$minutes분 전';
    }
    final hours = diff ~/ (60 * 60 * 1000);
    if (hours < 24) {
      return '$hours시간 전';
    }
    final days = diff ~/ (24 * 60 * 60 * 1000);
    if (days == 1) {
      return '어제';
    }
    return '$days일 전';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
