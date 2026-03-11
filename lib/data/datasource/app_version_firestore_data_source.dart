import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/domain/model/app_version_config.dart';

class AppVersionFirestoreDataSource {
  AppVersionFirestoreDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<AppVersionConfig?> watchConfig() async* {
    try {
      await for (final snapshot
          in _firestore
              .collection(FirestorePaths.appVersions())
              .orderBy(FieldPath.documentId)
              .limit(1)
              .snapshots()) {
        if (snapshot.docs.isEmpty) {
          yield null;
          continue;
        }

        final document = snapshot.docs.first;
        yield parseConfig(documentId: document.id, data: document.data());
      }
    } catch (error, stackTrace) {
      debugPrint('watchConfig failed: $error\n$stackTrace');
      yield null;
    }
  }

  static AppVersionConfig? parseConfig({
    required String documentId,
    Map<String, dynamic>? data,
  }) {
    if (data == null) {
      return null;
    }

    final versionMap = _asStringKeyedMap(data['version']) ?? data;
    final androidVersion = _readVersion(
      versionMap,
      keys: const <String>['android', 'andriod'],
    );
    final iosVersion = _readVersion(versionMap, keys: const <String>['ios']);

    if (androidVersion == null && iosVersion == null) {
      return null;
    }

    return AppVersionConfig(
      documentId: documentId,
      androidVersion: androidVersion,
      iosVersion: iosVersion,
    );
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }

    return raw.map<String, dynamic>((key, value) {
      return MapEntry(key.toString(), value);
    });
  }

  static String? _readVersion(
    Map<String, dynamic> source, {
    required List<String> keys,
  }) {
    for (final key in keys) {
      final rawValue = source[key];
      final normalized = rawValue?.toString().trim();
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }

    return null;
  }
}
