import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:nook_lounge_app/core/image/image_upload_compressor.dart';

class MarketStorageDataSource {
  MarketStorageDataSource({
    required FirebaseStorage storage,
    ImageUploadCompressor? imageUploadCompressor,
  }) : _storage = storage,
       _imageUploadCompressor =
           imageUploadCompressor ?? const ImageUploadCompressor();

  final FirebaseStorage _storage;
  final ImageUploadCompressor _imageUploadCompressor;

  Future<String> uploadOfferProofImage({
    required String uid,
    required String offerId,
    required String localFilePath,
  }) async {
    final originalFile = File(localFilePath);
    final compressedFile = await _imageUploadCompressor.compressForUpload(
      sourceFile: originalFile,
    );
    final ref = _storage.ref('users/$uid/market/$offerId/proof.jpg');

    try {
      await ref.putFile(
        compressedFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return ref.getDownloadURL();
    } finally {
      if (compressedFile.path != originalFile.path) {
        try {
          await compressedFile.delete();
        } catch (_) {}
      }
    }
  }
}
