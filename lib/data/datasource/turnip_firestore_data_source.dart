import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/domain/model/turnip_saved_data.dart';

class TurnipFirestoreDataSource {
  TurnipFirestoreDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<TurnipSavedData?> watchTurnipState({
    required String uid,
    required String islandId,
  }) {
    return _firestore
        .doc(FirestorePaths.turnipState(uid, islandId: islandId))
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return null;
          }
          final data = doc.data();
          if (data == null) {
            return null;
          }
          try {
            return TurnipSavedData.fromMap(data);
          } catch (error, stackTrace) {
            developer.log(
              '[TurnipFirestoreDataSource] invalid saved data. doc=${doc.reference.path}',
              error: error,
              stackTrace: stackTrace,
              name: 'turnip',
            );
            return null;
          }
        });
  }

  Future<void> saveTurnipState({
    required String uid,
    required String islandId,
    required TurnipSavedData data,
  }) async {
    final payload = data.toMap();

    // 유지보수 포인트:
    // prediction이 없을 때는 이전 예측 데이터를 삭제해 오래된 결과가 남지 않게 합니다.
    if (data.prediction == null) {
      payload['prediction'] = FieldValue.delete();
    }

    payload['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .doc(FirestorePaths.turnipState(uid, islandId: islandId))
        .set(payload, SetOptions(merge: true));
  }
}
