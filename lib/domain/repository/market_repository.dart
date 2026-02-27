import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/model/market_trade_proposal.dart';
import 'package:nook_lounge_app/domain/model/market_trade_code_session.dart';
import 'package:nook_lounge_app/domain/model/market_user_notification.dart';

abstract class MarketRepository {
  Stream<List<MarketOffer>> watchOffers();

  Future<MarketOffer?> fetchOfferById(String offerId);

  Future<void> createOffer({required String uid, required MarketOffer offer});

  Future<void> updateOffer({required String uid, required MarketOffer offer});

  Future<void> updateOfferLifecycle({
    required String offerId,
    required MarketLifecycleTab lifecycle,
    MarketOfferStatus? status,
  });

  Future<void> completeTrade({
    required String offerId,
    required String requesterUid,
    required String offerTitle,
  });

  Future<void> updateOfferBasicInfo({
    required String offerId,
    required String title,
    required String description,
  });

  Future<void> deleteOffer(String offerId);

  Future<void> sendTradeProposalNotification({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required String offerTitle,
  });

  Stream<List<MarketTradeProposal>> watchTradeProposals(String offerId);

  Stream<MarketTradeProposal?> watchMyTradeProposal({
    required String offerId,
    required String proposerUid,
  });

  Future<MarketTradeCodeSession> acceptTradeProposal({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required MarketMoveType moveType,
    required String offerTitle,
  });

  Future<MarketTradeCodeSession> prepareTradeCodeSession({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required MarketMoveType moveType,
  });

  Stream<MarketTradeCodeSession?> watchTradeCodeSession(String offerId);

  Future<MarketTradeCodeSession?> fetchTradeCodeSession(String offerId);

  Future<String?> fetchPreferredTradeDodoCode({
    required String offerId,
    required String senderUid,
  });

  Future<void> sendTradeAcceptNotification({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required String offerTitle,
  });

  Future<void> sendTradeCode({
    required String offerId,
    required String senderUid,
    required String receiverUid,
    required String code,
    required String offerTitle,
  });

  Future<void> cancelTrade({
    required String offerId,
    required String ownerUid,
    required String requesterUid,
    required String offerTitle,
  });

  Future<void> reportTradeOffer({
    required String offerId,
    required String ownerUid,
    required String reporterUid,
    required String reason,
    required String detail,
  });

  Stream<Set<String>> watchHiddenOfferIds(String uid);

  Future<void> hideOfferForUser({required String uid, required String offerId});

  Stream<List<MarketUserNotification>> watchUserNotifications(String uid);

  Future<void> markUserNotificationRead({
    required String uid,
    required String notificationId,
  });
}
