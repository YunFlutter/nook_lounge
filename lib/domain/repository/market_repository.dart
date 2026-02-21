import 'package:nook_lounge_app/domain/model/market_offer.dart';

abstract class MarketRepository {
  Stream<List<MarketOffer>> watchOffers();

  Future<void> createOffer(MarketOffer offer);

  Future<void> updateOfferLifecycle({
    required String offerId,
    required MarketLifecycleTab lifecycle,
  });

  Future<void> deleteOffer(String offerId);
}
