import 'package:nook_lounge_app/data/datasource/catalog_state_firestore_data_source.dart';
import 'package:nook_lounge_app/data/datasource/local_catalog_data_source.dart';
import 'package:nook_lounge_app/domain/model/catalog_item.dart';
import 'package:nook_lounge_app/domain/model/catalog_user_state.dart';
import 'package:nook_lounge_app/domain/repository/catalog_repository.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl({
    required LocalCatalogDataSource dataSource,
    required CatalogStateFirestoreDataSource stateDataSource,
  }) : _dataSource = dataSource,
       _stateDataSource = stateDataSource;

  final LocalCatalogDataSource _dataSource;
  final CatalogStateFirestoreDataSource _stateDataSource;

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

  @override
  Stream<Map<String, CatalogUserState>> watchUserStates({
    required String uid,
    required String islandId,
  }) {
    return _stateDataSource.watchCatalogStates(uid: uid, islandId: islandId);
  }

  @override
  Future<void> setOwnedStatus({
    required String uid,
    required String islandId,
    required String itemId,
    required String category,
    required bool owned,
  }) {
    return _stateDataSource.setCatalogState(
      uid: uid,
      islandId: islandId,
      itemId: itemId,
      category: category,
      owned: owned,
      donated: null,
      favorite: null,
    );
  }

  @override
  Future<void> setDonatedStatus({
    required String uid,
    required String islandId,
    required String itemId,
    required String category,
    required bool donated,
  }) {
    return _stateDataSource.setCatalogState(
      uid: uid,
      islandId: islandId,
      itemId: itemId,
      category: category,
      owned: null,
      donated: donated,
      favorite: null,
    );
  }

  @override
  Future<void> setFavoriteStatus({
    required String uid,
    required String islandId,
    required String itemId,
    required String category,
    required bool favorite,
  }) {
    return _stateDataSource.setCatalogState(
      uid: uid,
      islandId: islandId,
      itemId: itemId,
      category: category,
      owned: null,
      donated: null,
      favorite: favorite,
    );
  }

  @override
  Future<void> setVillagerMemo({
    required String uid,
    required String islandId,
    required String itemId,
    required String category,
    required String memo,
  }) {
    return _stateDataSource.setCatalogState(
      uid: uid,
      islandId: islandId,
      itemId: itemId,
      category: category,
      owned: null,
      donated: null,
      favorite: null,
      memo: memo,
    );
  }
}
