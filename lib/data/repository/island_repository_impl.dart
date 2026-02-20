import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nook_lounge_app/data/datasource/island_firestore_data_source.dart';
import 'package:nook_lounge_app/domain/model/create_island_draft.dart';
import 'package:nook_lounge_app/domain/model/island_profile.dart';
import 'package:nook_lounge_app/domain/repository/island_repository.dart';

class IslandRepositoryImpl implements IslandRepository {
  IslandRepositoryImpl({required IslandFirestoreDataSource dataSource})
    : _dataSource = dataSource;

  final IslandFirestoreDataSource _dataSource;

  @override
  Future<bool> hasPrimaryIsland(String uid) =>
      _dataSource.hasPrimaryIsland(uid);

  @override
  Future<void> createPrimaryIsland({
    required String uid,
    required CreateIslandDraft draft,
  }) {
    final islandId = FirebaseFirestore.instance.collection('tmp').doc().id;

    final profile = IslandProfile(
      id: islandId,
      islandName: draft.islandName,
      representativeName: draft.representativeName,
      hemisphere: draft.hemisphere,
      nativeFruit: draft.nativeFruit,
      imageUrl: draft.imageUrl,
    );

    return _dataSource.createPrimaryIsland(uid: uid, profile: profile);
  }
}
