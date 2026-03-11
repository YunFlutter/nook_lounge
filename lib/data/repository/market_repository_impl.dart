import 'dart:async';

import 'package:nook_lounge_app/core/telemetry/app_telemetry.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry_events.dart';
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
    required AppTelemetry telemetry,
  }) : _firestoreDataSource = firestoreDataSource,
       _storageDataSource = storageDataSource,
       _telemetry = telemetry;

  final MarketFirestoreDataSource _firestoreDataSource;
  final MarketStorageDataSource _storageDataSource;
  final AppTelemetry _telemetry;

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
    try {
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
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.marketOfferCreated,
          parameters: <String, Object>{
            'category': offer.category.name,
            'trade_type': offer.tradeType.name,
            'move_type': offer.moveType.name,
            'has_cover_image': next.coverImageUrl.trim().isNotEmpty,
          },
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'market.create_offer',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> updateOffer({
    required String uid,
    required MarketOffer offer,
  }) async {
    try {
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
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.marketOfferUpdated,
          parameters: <String, Object>{
            'update_type': 'full',
            'category': offer.category.name,
            'trade_type': offer.tradeType.name,
          },
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'market.update_offer',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> updateOfferLifecycle({
    required String offerId,
    required MarketLifecycleTab lifecycle,
    MarketOfferStatus? status,
  }) async {
    try {
      await _firestoreDataSource.updateOfferLifecycle(
        offerId: offerId,
        lifecycle: lifecycle,
        status: status,
      );
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.marketOfferUpdated,
          parameters: <String, Object?>{
            'update_type': 'lifecycle',
            'lifecycle': lifecycle.name,
            'status': status?.name,
          },
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'market.update_offer_lifecycle',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> completeTrade({
    required String offerId,
    required String requesterUid,
    required String offerTitle,
  }) async {
    try {
      await _firestoreDataSource.completeTrade(
        offerId: offerId,
        requesterUid: requesterUid,
        offerTitle: offerTitle,
      );
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.marketTradeCompleted,
          parameters: const <String, Object>{'result': 'success'},
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'market.complete_trade',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> updateOfferBasicInfo({
    required String offerId,
    required String title,
    required String description,
  }) async {
    try {
      await _firestoreDataSource.updateOfferBasicInfo(
        offerId: offerId,
        title: title,
        description: description,
      );
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.marketOfferUpdated,
          parameters: const <String, Object>{'update_type': 'basic_info'},
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'market.update_offer_basic_info',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteOffer(String offerId) async {
    try {
      await _firestoreDataSource.deleteOffer(offerId);
      unawaited(_telemetry.logEvent(AppTelemetryEvents.marketOfferDeleted));
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'market.delete_offer',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> sendTradeProposalNotification({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required String offerTitle,
  }) async {
    try {
      await _firestoreDataSource.sendTradeProposalNotification(
        offerId: offerId,
        ownerUid: ownerUid,
        proposerUid: proposerUid,
        offerTitle: offerTitle,
      );
      unawaited(_telemetry.logEvent(AppTelemetryEvents.marketProposalSent));
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'market.send_trade_proposal',
        ),
      );
      rethrow;
    }
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
  Stream<Set<String>> watchMyActiveProposalOfferIds(String proposerUid) {
    return _firestoreDataSource.watchMyActiveProposalOfferIds(proposerUid);
  }

  @override
  Future<MarketTradeCodeSession> acceptTradeProposal({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required MarketMoveType moveType,
    required String offerTitle,
  }) async {
    try {
      final session = await _firestoreDataSource.acceptTradeProposal(
        offerId: offerId,
        ownerUid: ownerUid,
        proposerUid: proposerUid,
        moveType: moveType,
        offerTitle: offerTitle,
      );
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.marketProposalAccepted,
          parameters: <String, Object>{'move_type': moveType.name},
        ),
      );
      return session;
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'market.accept_trade_proposal',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<MarketTradeCodeSession> prepareTradeCodeSession({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required MarketMoveType moveType,
  }) async {
    try {
      final session = await _firestoreDataSource.prepareTradeCodeSession(
        offerId: offerId,
        ownerUid: ownerUid,
        proposerUid: proposerUid,
        moveType: moveType,
      );
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.marketTradeCodePrepared,
          parameters: <String, Object>{'move_type': moveType.name},
        ),
      );
      return session;
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'market.prepare_trade_code_session',
        ),
      );
      rethrow;
    }
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
  Stream<bool> watchTradeRuleAgreement({
    required String offerId,
    required String receiverUid,
  }) {
    return _firestoreDataSource.watchTradeRuleAgreement(
      offerId: offerId,
      receiverUid: receiverUid,
    );
  }

  @override
  Future<String?> fetchPreferredTradeDodoCode({
    required String offerId,
    required String senderUid,
  }) {
    return _firestoreDataSource.fetchPreferredTradeDodoCode(
      offerId: offerId,
      senderUid: senderUid,
    );
  }

  @override
  Future<String?> fetchPreferredTradeIslandRules({
    required String offerId,
    required String senderUid,
  }) {
    return _firestoreDataSource.fetchPreferredTradeIslandRules(
      offerId: offerId,
      senderUid: senderUid,
    );
  }

  @override
  Future<void> sendTradeAcceptNotification({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required String offerTitle,
  }) async {
    try {
      await _firestoreDataSource.sendTradeAcceptNotification(
        offerId: offerId,
        ownerUid: ownerUid,
        proposerUid: proposerUid,
        offerTitle: offerTitle,
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'market.send_trade_accept_notification',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> sendTradeCode({
    required String offerId,
    required String senderUid,
    required String receiverUid,
    required String code,
    required String islandRules,
    required String offerTitle,
  }) async {
    try {
      await _firestoreDataSource.sendTradeCode(
        offerId: offerId,
        senderUid: senderUid,
        receiverUid: receiverUid,
        code: code,
        islandRules: islandRules,
        offerTitle: offerTitle,
      );
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.marketTradeCodeSent,
          parameters: <String, Object>{
            'has_rules': islandRules.trim().isNotEmpty,
          },
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'market.send_trade_code',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> agreeTradeRules({
    required String offerId,
    required String receiverUid,
    required String code,
  }) async {
    try {
      await _firestoreDataSource.agreeTradeRules(
        offerId: offerId,
        receiverUid: receiverUid,
        code: code,
      );
      unawaited(_telemetry.logEvent(AppTelemetryEvents.marketTradeRulesAgreed));
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'market.agree_trade_rules',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> cancelTrade({
    required String offerId,
    required String ownerUid,
    required String requesterUid,
    required String offerTitle,
  }) async {
    try {
      await _firestoreDataSource.cancelTrade(
        offerId: offerId,
        ownerUid: ownerUid,
        requesterUid: requesterUid,
        offerTitle: offerTitle,
      );
      unawaited(_telemetry.logEvent(AppTelemetryEvents.marketTradeCancelled));
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'market.cancel_trade',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> reportTradeOffer({
    required String offerId,
    required String ownerUid,
    required String reporterUid,
    required String reason,
    required String detail,
  }) async {
    try {
      await _firestoreDataSource.reportTradeOffer(
        offerId: offerId,
        ownerUid: ownerUid,
        reporterUid: reporterUid,
        reason: reason,
        detail: detail,
      );
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.marketOfferReported,
          parameters: <String, Object>{'report_reason': reason},
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'market.report_offer',
        ),
      );
      rethrow;
    }
  }

  @override
  Stream<Set<String>> watchHiddenOfferIds(String uid) {
    return _firestoreDataSource.watchHiddenOfferIds(uid);
  }

  @override
  Future<void> hideOfferForUser({
    required String uid,
    required String offerId,
  }) async {
    try {
      await _firestoreDataSource.hideOfferForUser(uid: uid, offerId: offerId);
      unawaited(_telemetry.logEvent(AppTelemetryEvents.marketOfferHidden));
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(error, stackTrace, reason: 'market.hide_offer'),
      );
      rethrow;
    }
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
