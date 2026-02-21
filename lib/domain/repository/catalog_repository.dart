import 'package:nook_lounge_app/domain/model/catalog_item.dart';
import 'package:nook_lounge_app/domain/model/catalog_user_state.dart';

abstract class CatalogRepository {
  Future<List<CatalogItem>> loadAll();

  Future<List<CatalogItem>> search({
    required String keyword,
    String? category,
    int limit,
  });

  Stream<Map<String, CatalogUserState>> watchUserStates(String uid);

  Future<void> setOwnedStatus({
    required String uid,
    required String itemId,
    required String category,
    required bool owned,
  });

  Future<void> setDonatedStatus({
    required String uid,
    required String itemId,
    required String category,
    required bool donated,
  });

  Future<void> setFavoriteStatus({
    required String uid,
    required String itemId,
    required String category,
    required bool favorite,
  });
}
