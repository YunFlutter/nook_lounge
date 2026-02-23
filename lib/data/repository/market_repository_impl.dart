import 'package:nook_lounge_app/data/datasource/market_firestore_data_source.dart';
import 'package:nook_lounge_app/data/datasource/market_storage_data_source.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/repository/market_repository.dart';

class MarketRepositoryImpl implements MarketRepository {
  MarketRepositoryImpl({
    required MarketFirestoreDataSource firestoreDataSource,
    required MarketStorageDataSource storageDataSource,
  }) : _firestoreDataSource = firestoreDataSource,
       _storageDataSource = storageDataSource;

  final MarketFirestoreDataSource _firestoreDataSource;
  final MarketStorageDataSource _storageDataSource;

  @override
  Stream<List<MarketOffer>> watchOffers() {
    return _firestoreDataSource.watchOffers();
  }

  @override
  Future<void> createOffer({
    required String uid,
    required MarketOffer offer,
  }) async {
    var next = offer;
    // 유지보수 포인트:
    // Firestore에는 로컬 파일 경로를 절대 저장하지 않고
    // 압축 업로드 후 받은 다운로드 URL만 저장합니다.
    final localPath = _resolveLocalPath(offer.coverImageUrl);
    if (localPath != null) {
      final url = await _storageDataSource.uploadOfferProofImage(
        uid: uid,
        offerId: offer.id,
        localFilePath: localPath,
      );
      next = next.copyWith(coverImageUrl: url);
    }
    await _firestoreDataSource.createOffer(next);
  }

  @override
  Future<void> updateOffer({
    required String uid,
    required MarketOffer offer,
  }) async {
    var next = offer;
    // 유지보수 포인트:
    // 수정 시에도 로컬 파일 경로 저장을 금지하고
    // 압축 업로드 후 URL만 Firestore에 반영합니다.
    final localPath = _resolveLocalPath(offer.coverImageUrl);
    if (localPath != null) {
      final url = await _storageDataSource.uploadOfferProofImage(
        uid: uid,
        offerId: offer.id,
        localFilePath: localPath,
      );
      next = next.copyWith(coverImageUrl: url);
    }
    await _firestoreDataSource.updateOffer(next);
  }

  @override
  Future<void> updateOfferLifecycle({
    required String offerId,
    required MarketLifecycleTab lifecycle,
    MarketOfferStatus? status,
  }) {
    return _firestoreDataSource.updateOfferLifecycle(
      offerId: offerId,
      lifecycle: lifecycle,
      status: status,
    );
  }

  @override
  Future<void> updateOfferBasicInfo({
    required String offerId,
    required String title,
    required String description,
  }) {
    return _firestoreDataSource.updateOfferBasicInfo(
      offerId: offerId,
      title: title,
      description: description,
    );
  }

  @override
  Future<void> deleteOffer(String offerId) {
    return _firestoreDataSource.deleteOffer(offerId);
  }

  String? _resolveLocalPath(String source) {
    if (source.isEmpty) {
      return null;
    }
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return null;
    }
    if (source.startsWith('/')) {
      return source;
    }
    if (source.startsWith('file://')) {
      try {
        return Uri.parse(source).toFilePath();
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
