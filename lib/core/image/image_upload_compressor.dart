import 'dart:io';

import 'package:image/image.dart' as img;

/// 유지보수 포인트:
/// - 사용자 업로드 이미지를 서버로 올리기 전, 해상도/품질을 공통 압축합니다.
/// - 압축 실패 시 원본 파일을 그대로 반환해 업로드 흐름이 끊기지 않게 설계했습니다.
class ImageUploadCompressor {
  const ImageUploadCompressor();

  Future<File> compressForUpload({
    required File sourceFile,
    int maxDimension = 1440,
    int jpegQuality = 78,
  }) async {
    if (!await sourceFile.exists()) {
      return sourceFile;
    }

    try {
      final originalBytes = await sourceFile.readAsBytes();
      final decoded = img.decodeImage(originalBytes);
      if (decoded == null) {
        return sourceFile;
      }

      final resized = _resizeKeepingRatio(
        source: decoded,
        maxDimension: maxDimension,
      );

      final encoded = img.encodeJpg(resized, quality: jpegQuality);
      if (encoded.isEmpty) {
        return sourceFile;
      }

      final tempPath =
          '${Directory.systemTemp.path}/upload_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final compressedFile = File(tempPath);
      await compressedFile.writeAsBytes(encoded, flush: true);

      // 유지보수 포인트:
      // 드물게 압축본이 더 커질 수 있어, 이 경우 원본을 그대로 사용합니다.
      final compressedSize = await compressedFile.length();
      final originalSize = await sourceFile.length();
      if (compressedSize >= originalSize) {
        await compressedFile.delete();
        return sourceFile;
      }

      return compressedFile;
    } catch (_) {
      return sourceFile;
    }
  }

  img.Image _resizeKeepingRatio({
    required img.Image source,
    required int maxDimension,
  }) {
    final width = source.width;
    final height = source.height;
    if (width <= maxDimension && height <= maxDimension) {
      return source;
    }

    if (width >= height) {
      final nextHeight = (height * (maxDimension / width)).round();
      return img.copyResize(source, width: maxDimension, height: nextHeight);
    }

    final nextWidth = (width * (maxDimension / height)).round();
    return img.copyResize(source, width: nextWidth, height: maxDimension);
  }
}
