import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry_events.dart';
import 'package:nook_lounge_app/data/datasource/island_firestore_data_source.dart';
import 'package:nook_lounge_app/data/datasource/island_storage_data_source.dart';
import 'package:nook_lounge_app/domain/model/create_island_draft.dart';
import 'package:nook_lounge_app/domain/model/island_profile.dart';
import 'package:nook_lounge_app/domain/repository/island_repository.dart';

class IslandRepositoryImpl implements IslandRepository {
  IslandRepositoryImpl({
    required IslandFirestoreDataSource firestoreDataSource,
    required IslandStorageDataSource storageDataSource,
    required AppTelemetry telemetry,
  }) : _firestoreDataSource = firestoreDataSource,
       _storageDataSource = storageDataSource,
       _telemetry = telemetry;

  final IslandFirestoreDataSource _firestoreDataSource;
  final IslandStorageDataSource _storageDataSource;
  final AppTelemetry _telemetry;

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
    try {
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

      await _firestoreDataSource.createPrimaryIsland(
        uid: uid,
        profile: profile,
      );
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.islandCreated,
          parameters: <String, Object>{
            'has_passport_image': uploadedImageUrl != null,
            'hemisphere': draft.hemisphere,
            'native_fruit': draft.nativeFruit,
          },
        ),
      );
      return islandId;
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'island.create_primary',
        ),
      );
      rethrow;
    }
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
  }) async {
    try {
      await _firestoreDataSource.setPrimaryIsland(uid: uid, islandId: islandId);
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.islandPrimaryChanged,
          parameters: <String, Object>{
            'has_island_id': islandId.trim().isNotEmpty,
          },
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(error, stackTrace, reason: 'island.set_primary'),
      );
      rethrow;
    }
  }

  @override
  Future<void> updateIslandProfile({
    required String uid,
    required IslandProfile profile,
    String? passportImagePath,
  }) async {
    try {
      var imageUrl = profile.imageUrl;
      final imagePath = passportImagePath?.trim() ?? '';
      if (imagePath.isNotEmpty) {
        imageUrl = await _storageDataSource.uploadPassportImage(
          uid: uid,
          islandId: profile.id,
          localFilePath: imagePath,
        );
      }

      await _firestoreDataSource.updateIslandProfile(
        uid: uid,
        profile: profile.copyWith(imageUrl: imageUrl),
      );
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.islandUpdated,
          parameters: <String, Object>{
            'has_passport_image': imageUrl?.trim().isNotEmpty ?? false,
            'native_fruit': profile.nativeFruit,
          },
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'island.update_profile',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteIsland({
    required String uid,
    required String islandId,
  }) async {
    try {
      await _firestoreDataSource.deleteIsland(uid: uid, islandId: islandId);
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.islandDeleted,
          parameters: <String, Object>{
            'has_island_id': islandId.trim().isNotEmpty,
          },
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(error, stackTrace, reason: 'island.delete'),
      );
      rethrow;
    }
  }

  bool _isTransientNetworkError(String code) {
    return code == 'unavailable' ||
        code == 'deadline-exceeded' ||
        code == 'aborted';
  }
}
