import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/domain/model/catalog_user_state.dart';

class CatalogStateFirestoreDataSource {
  CatalogStateFirestoreDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<Map<String, CatalogUserState>> watchCatalogStates({
    required String uid,
    required String islandId,
  }) {
    return _firestore
        .collection(FirestorePaths.islandCatalogStates(uid, islandId))
        .snapshots()
        .map((snapshot) {
          final map = <String, CatalogUserState>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            map[doc.id] = CatalogUserState.fromMap(itemId: doc.id, data: data);
          }
          return map;
        });
  }

  Future<void> setCatalogState({
    required String uid,
    required String islandId,
    required String itemId,
    required String category,
    required bool? owned,
    required bool? donated,
    required bool? favorite,
    String? memo,
  }) async {
    final payload = <String, dynamic>{
      'category': category,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (owned != null) {
      payload['owned'] = owned;
    }
    if (donated != null) {
      payload['donated'] = donated;
    }
    if (favorite != null) {
      payload['favorite'] = favorite;
    }
    if (memo != null) {
      payload['memo'] = memo;
    }

    await _firestore
        .doc(FirestorePaths.islandCatalogState(uid, islandId, itemId))
        .set(payload, SetOptions(merge: true));
  }
}
