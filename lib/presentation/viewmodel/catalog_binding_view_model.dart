import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/domain/model/catalog_user_state.dart';
import 'package:nook_lounge_app/domain/repository/catalog_repository.dart';

class CatalogBindingViewModel
    extends StateNotifier<Map<String, CatalogUserState>> {
  CatalogBindingViewModel({
    required CatalogRepository catalogRepository,
    required String uid,
  }) : _catalogRepository = catalogRepository,
       _uid = uid,
       super(const <String, CatalogUserState>{}) {
    _subscription = _catalogRepository.watchUserStates(uid).listen((states) {
      state = states;
    });
  }

  final CatalogRepository _catalogRepository;
  final String _uid;
  StreamSubscription<Map<String, CatalogUserState>>? _subscription;

  Future<void> setCompleted({
    required String itemId,
    required String category,
    required bool donationMode,
    required bool completed,
  }) async {
    final current = state[itemId];
    final optimistic =
        (current ??
                CatalogUserState(
                  itemId: itemId,
                  owned: false,
                  donated: false,
                  favorite: false,
                  category: category,
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
        itemId: itemId,
        category: category,
        donated: completed,
      );
      return;
    }

    await _catalogRepository.setOwnedStatus(
      uid: _uid,
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
    final current = state[itemId];
    final optimistic =
        (current ??
                CatalogUserState(
                  itemId: itemId,
                  owned: false,
                  donated: false,
                  favorite: false,
                  category: category,
                ))
            .copyWith(category: category, favorite: favorite);

    state = <String, CatalogUserState>{...state, itemId: optimistic};

    await _catalogRepository.setFavoriteStatus(
      uid: _uid,
      itemId: itemId,
      category: category,
      favorite: favorite,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
