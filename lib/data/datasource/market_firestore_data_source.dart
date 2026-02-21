import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';

class MarketFirestoreDataSource {
  MarketFirestoreDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<List<MarketOffer>> watchOffers() {
    return _firestore
        .collection(FirestorePaths.marketPosts())
        .orderBy('createdAtMillis', descending: true)
        .snapshots()
        .map((snapshot) {
          final offers = <MarketOffer>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            offers.add(MarketOffer.fromMap(id: doc.id, data: data));
          }
          return offers;
        });
  }

  Future<void> createOffer(MarketOffer offer) async {
    await _firestore
        .doc(FirestorePaths.marketPost(offer.id))
        .set(offer.toMap(), SetOptions(merge: true));
  }

  Future<void> updateOfferLifecycle({
    required String offerId,
    required MarketLifecycleTab lifecycle,
  }) async {
    await _firestore
        .doc(FirestorePaths.marketPost(offerId))
        .set(<String, dynamic>{
          'lifecycle': lifecycle.name,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
  }

  Future<void> deleteOffer(String offerId) async {
    await _firestore.doc(FirestorePaths.marketPost(offerId)).delete();
  }
}
