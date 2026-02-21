import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/core/error/resident_limit_exceeded_exception.dart';
import 'package:nook_lounge_app/domain/model/catalog_user_state.dart';
import 'package:nook_lounge_app/domain/repository/catalog_repository.dart';

class CatalogBindingViewModel
    extends StateNotifier<Map<String, CatalogUserState>> {
  static const int _maxResidentCount = 10;

  CatalogBindingViewModel({
    required CatalogRepository catalogRepository,
    required String uid,
    required String islandId,
  }) : _catalogRepository = catalogRepository,
       _uid = uid,
       _islandId = islandId,
       super(const <String, CatalogUserState>{}) {
    if (islandId.isEmpty) {
      return;
    }
    _subscription = _catalogRepository
        .watchUserStates(uid: uid, islandId: islandId)
        .listen((states) {
          state = states;
        });
  }

  final CatalogRepository _catalogRepository;
  final String _uid;
  final String _islandId;
  StreamSubscription<Map<String, CatalogUserState>>? _subscription;

  Future<void> setCompleted({
    required String itemId,
    required String category,
    required bool donationMode,
    required bool completed,
  }) async {
    if (_islandId.isEmpty) {
      return;
    }

    final isResidentCategory = category == '주민' && !donationMode;
    if (isResidentCategory && completed) {
      final currentState = state[itemId];
      final isAlreadyResident = currentState?.owned ?? false;
      if (!isAlreadyResident) {
        final residentCount = state.values
            .where((value) => value.category == '주민' && value.owned)
            .length;
        if (residentCount >= _maxResidentCount) {
          throw const ResidentLimitExceededException(
            maxCount: _maxResidentCount,
          );
        }
      }
    }

    final current = state[itemId];
    final optimistic =
        (current ??
                CatalogUserState(
                  itemId: itemId,
                  owned: false,
                  donated: false,
                  favorite: false,
                  category: category,
                  memo: '',
                ))
            .copyWith(
              category: category,
              owned: donationMode ? current?.owned : completed,
              donated: donationMode ? completed : current?.donated,
            );

    state = <String, CatalogUserState>{...state, itemId: optimistic};

    if (donationMode) {
      await _catalogRepository.setDonatedStatus(
        uid: _uid,
        islandId: _islandId,
        itemId: itemId,
        category: category,
        donated: completed,
      );
      return;
    }

    await _catalogRepository.setOwnedStatus(
      uid: _uid,
      islandId: _islandId,
      itemId: itemId,
      category: category,
      owned: completed,
    );
  }

  Future<void> setFavorite({
    required String itemId,
    required String category,
    required bool favorite,
  }) async {
    if (_islandId.isEmpty) {
      return;
    }
    final current = state[itemId];
    final optimistic =
        (current ??
                CatalogUserState(
                  itemId: itemId,
                  owned: false,
                  donated: false,
                  favorite: false,
                  category: category,
                  memo: '',
                ))
            .copyWith(category: category, favorite: favorite);

    state = <String, CatalogUserState>{...state, itemId: optimistic};

    await _catalogRepository.setFavoriteStatus(
      uid: _uid,
      islandId: _islandId,
      itemId: itemId,
      category: category,
      favorite: favorite,
    );
  }

  Future<void> setVillagerMemo({
    required String itemId,
    required String category,
    required String memo,
  }) async {
    if (_islandId.isEmpty) {
      return;
    }
    final current = state[itemId];
    final optimistic =
        (current ??
                CatalogUserState(
                  itemId: itemId,
                  owned: false,
                  donated: false,
                  favorite: false,
                  category: category,
                  memo: '',
                ))
            .copyWith(category: category, memo: memo);

    state = <String, CatalogUserState>{...state, itemId: optimistic};

    await _catalogRepository.setVillagerMemo(
      uid: _uid,
      islandId: _islandId,
      itemId: itemId,
      category: category,
      memo: memo,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
