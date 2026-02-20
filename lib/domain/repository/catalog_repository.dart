import 'package:nook_lounge_app/domain/model/catalog_item.dart';

abstract class CatalogRepository {
  Future<List<CatalogItem>> loadAll();

  Future<List<CatalogItem>> search({
    required String keyword,
    String? category,
    int limit,
  });
}
