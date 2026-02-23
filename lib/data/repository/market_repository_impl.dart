import 'package:nook_lounge_app/data/datasource/market_firestore_data_source.dart';
import 'package:nook_lounge_app/data/datasource/market_storage_data_source.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/model/market_trade_proposal.dart';
import 'package:nook_lounge_app/domain/model/market_trade_code_session.dart';
import 'package:nook_lounge_app/domain/model/market_user_notification.dart';
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
  Future<MarketOffer?> fetchOfferById(String offerId) {
    return _firestoreDataSource.fetchOfferById(offerId);
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
  Future<void> completeTrade({
    required String offerId,
    required String requesterUid,
    required String offerTitle,
  }) {
    return _firestoreDataSource.completeTrade(
      offerId: offerId,
      requesterUid: requesterUid,
      offerTitle: offerTitle,
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

  @override
  Future<void> sendTradeProposalNotification({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required String offerTitle,
  }) {
    return _firestoreDataSource.sendTradeProposalNotification(
      offerId: offerId,
      ownerUid: ownerUid,
      proposerUid: proposerUid,
      offerTitle: offerTitle,
    );
  }

  @override
  Stream<List<MarketTradeProposal>> watchTradeProposals(String offerId) {
    return _firestoreDataSource.watchTradeProposals(offerId);
  }

  @override
  Stream<MarketTradeProposal?> watchMyTradeProposal({
    required String offerId,
    required String proposerUid,
  }) {
    return _firestoreDataSource.watchMyTradeProposal(
      offerId: offerId,
      proposerUid: proposerUid,
    );
  }

  @override
  Future<MarketTradeCodeSession> acceptTradeProposal({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required MarketMoveType moveType,
    required String offerTitle,
  }) {
    return _firestoreDataSource.acceptTradeProposal(
      offerId: offerId,
      ownerUid: ownerUid,
      proposerUid: proposerUid,
      moveType: moveType,
      offerTitle: offerTitle,
    );
  }

  @override
  Future<MarketTradeCodeSession> prepareTradeCodeSession({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required MarketMoveType moveType,
  }) {
    return _firestoreDataSource.prepareTradeCodeSession(
      offerId: offerId,
      ownerUid: ownerUid,
      proposerUid: proposerUid,
      moveType: moveType,
    );
  }

  @override
  Stream<MarketTradeCodeSession?> watchTradeCodeSession(String offerId) {
    return _firestoreDataSource.watchTradeCodeSession(offerId);
  }

  @override
  Future<MarketTradeCodeSession?> fetchTradeCodeSession(String offerId) {
    return _firestoreDataSource.fetchTradeCodeSession(offerId);
  }

  @override
  Future<void> sendTradeAcceptNotification({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required String offerTitle,
  }) {
    return _firestoreDataSource.sendTradeAcceptNotification(
      offerId: offerId,
      ownerUid: ownerUid,
      proposerUid: proposerUid,
      offerTitle: offerTitle,
    );
  }

  @override
  Future<void> sendTradeCode({
    required String offerId,
    required String senderUid,
    required String receiverUid,
    required String code,
    required String offerTitle,
  }) {
    return _firestoreDataSource.sendTradeCode(
      offerId: offerId,
      senderUid: senderUid,
      receiverUid: receiverUid,
      code: code,
      offerTitle: offerTitle,
    );
  }

  @override
  Future<void> cancelTrade({
    required String offerId,
    required String ownerUid,
    required String requesterUid,
    required String offerTitle,
  }) {
    return _firestoreDataSource.cancelTrade(
      offerId: offerId,
      ownerUid: ownerUid,
      requesterUid: requesterUid,
      offerTitle: offerTitle,
    );
  }

  @override
  Future<void> reportTradeOffer({
    required String offerId,
    required String ownerUid,
    required String reporterUid,
    required String reason,
    required String detail,
  }) {
    return _firestoreDataSource.reportTradeOffer(
      offerId: offerId,
      ownerUid: ownerUid,
      reporterUid: reporterUid,
      reason: reason,
      detail: detail,
    );
  }

  @override
  Stream<Set<String>> watchHiddenOfferIds(String uid) {
    return _firestoreDataSource.watchHiddenOfferIds(uid);
  }

  @override
  Future<void> hideOfferForUser({
    required String uid,
    required String offerId,
  }) {
    return _firestoreDataSource.hideOfferForUser(uid: uid, offerId: offerId);
  }

  @override
  Stream<List<MarketUserNotification>> watchUserNotifications(String uid) {
    return _firestoreDataSource.watchUserNotifications(uid);
  }

  @override
  Future<void> markUserNotificationRead({
    required String uid,
    required String notificationId,
  }) {
    return _firestoreDataSource.markUserNotificationRead(
      uid: uid,
      notificationId: notificationId,
    );
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
