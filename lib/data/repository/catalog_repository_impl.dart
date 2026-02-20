import 'package:nook_lounge_app/data/datasource/local_catalog_data_source.dart';
import 'package:nook_lounge_app/domain/model/catalog_item.dart';
import 'package:nook_lounge_app/domain/repository/catalog_repository.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl({required LocalCatalogDataSource dataSource})
    : _dataSource = dataSource;

  final LocalCatalogDataSource _dataSource;

  @override
  Future<List<CatalogItem>> loadAll() => _dataSource.loadAll();

  @override
  Future<List<CatalogItem>> search({
    required String keyword,
    String? category,
    int limit = 50,
  }) {
    return _dataSource.search(
      keyword: keyword,
      category: category,
      limit: limit,
    );
  }
}
