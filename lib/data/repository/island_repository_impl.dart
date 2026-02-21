import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nook_lounge_app/data/datasource/island_firestore_data_source.dart';
import 'package:nook_lounge_app/data/datasource/island_storage_data_source.dart';
import 'package:nook_lounge_app/domain/model/create_island_draft.dart';
import 'package:nook_lounge_app/domain/model/island_profile.dart';
import 'package:nook_lounge_app/domain/repository/island_repository.dart';

class IslandRepositoryImpl implements IslandRepository {
  IslandRepositoryImpl({
    required IslandFirestoreDataSource firestoreDataSource,
    required IslandStorageDataSource storageDataSource,
  }) : _firestoreDataSource = firestoreDataSource,
       _storageDataSource = storageDataSource;

  final IslandFirestoreDataSource _firestoreDataSource;
  final IslandStorageDataSource _storageDataSource;

  @override
  Future<bool> hasPrimaryIsland(String uid) =>
      _firestoreDataSource.hasPrimaryIslandFromCache(uid);

  @override
  Future<bool?> revalidatePrimaryIsland(String uid) async {
    try {
      return await _firestoreDataSource.hasPrimaryIslandFromServer(uid);
    } on FirebaseException catch (error) {
      if (_isTransientNetworkError(error.code)) {
        return null;
      }
      rethrow;
    } on SocketException {
      return null;
    }
  }

  @override
  Future<String> createPrimaryIsland({
    required String uid,
    required CreateIslandDraft draft,
    String? passportImagePath,
  }) async {
    final islandId = FirebaseFirestore.instance.collection('tmp').doc().id;

    String? uploadedImageUrl;

    if (passportImagePath != null && passportImagePath.trim().isNotEmpty) {
      uploadedImageUrl = await _storageDataSource.uploadPassportImage(
        uid: uid,
        islandId: islandId,
        localFilePath: passportImagePath,
      );
    }

    final profile = IslandProfile(
      id: islandId,
      islandName: draft.islandName,
      representativeName: draft.representativeName,
      hemisphere: draft.hemisphere,
      nativeFruit: draft.nativeFruit,
      imageUrl: uploadedImageUrl,
    );

    await _firestoreDataSource.createPrimaryIsland(uid: uid, profile: profile);
    return islandId;
  }

  @override
  Stream<String?> watchPrimaryIslandId(String uid) {
    return _firestoreDataSource.watchPrimaryIslandId(uid);
  }

  @override
  Stream<List<IslandProfile>> watchIslands(String uid) {
    return _firestoreDataSource.watchIslands(uid);
  }

  @override
  Future<void> setPrimaryIsland({
    required String uid,
    required String islandId,
  }) {
    return _firestoreDataSource.setPrimaryIsland(uid: uid, islandId: islandId);
  }

  bool _isTransientNetworkError(String code) {
    return code == 'unavailable' ||
        code == 'deadline-exceeded' ||
        code == 'aborted';
  }
}
