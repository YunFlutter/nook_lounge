import 'package:nook_lounge_app/domain/model/market_offer.dart';

abstract class MarketRepository {
  Stream<List<MarketOffer>> watchOffers();

  Future<void> createOffer({required String uid, required MarketOffer offer});

  Future<void> updateOffer({required String uid, required MarketOffer offer});

  Future<void> updateOfferLifecycle({
    required String offerId,
    required MarketLifecycleTab lifecycle,
    MarketOfferStatus? status,
  });

  Future<void> updateOfferBasicInfo({
    required String offerId,
    required String title,
    required String description,
  });

  Future<void> deleteOffer(String offerId);
}
