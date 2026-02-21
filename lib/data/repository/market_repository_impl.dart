import 'package:nook_lounge_app/data/datasource/market_firestore_data_source.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/repository/market_repository.dart';

class MarketRepositoryImpl implements MarketRepository {
  MarketRepositoryImpl({required MarketFirestoreDataSource firestoreDataSource})
    : _firestoreDataSource = firestoreDataSource;

  final MarketFirestoreDataSource _firestoreDataSource;

  @override
  Stream<List<MarketOffer>> watchOffers() {
    return _firestoreDataSource.watchOffers();
  }

  @override
  Future<void> createOffer(MarketOffer offer) {
    return _firestoreDataSource.createOffer(offer);
  }

  @override
  Future<void> updateOfferLifecycle({
    required String offerId,
    required MarketLifecycleTab lifecycle,
  }) {
    return _firestoreDataSource.updateOfferLifecycle(
      offerId: offerId,
      lifecycle: lifecycle,
    );
  }

  @override
  Future<void> deleteOffer(String offerId) {
    return _firestoreDataSource.deleteOffer(offerId);
  }
}
