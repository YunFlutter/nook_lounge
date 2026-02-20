import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class IslandStorageDataSource {
  IslandStorageDataSource({required FirebaseStorage storage})
    : _storage = storage;

  final FirebaseStorage _storage;

  Future<String> uploadPassportImage({
    required String uid,
    required String islandId,
    required String localFilePath,
  }) async {
    final file = File(localFilePath);

    final ref = _storage.ref('users/$uid/islands/$islandId/passport.jpg');

    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));

    return ref.getDownloadURL();
  }
}
