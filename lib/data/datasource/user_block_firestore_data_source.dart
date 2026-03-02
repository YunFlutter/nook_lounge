import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';

class UserBlockFirestoreDataSource {
  UserBlockFirestoreDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<Set<String>> watchBlockedUserIds(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return Stream<Set<String>>.value(const <String>{});
    }
    return _firestore
        .collection(FirestorePaths.blockedUsers(normalizedUid))
        .snapshots()
        .map((snapshot) {
          final ids = <String>{};
          for (final doc in snapshot.docs) {
            final blockedUid = doc.id.trim();
            if (blockedUid.isNotEmpty) {
              ids.add(blockedUid);
            }
          }
          return ids;
        });
  }

  Future<void> blockUser({
    required String uid,
    required String blockedUid,
  }) async {
    final normalizedUid = uid.trim();
    final normalizedBlockedUid = blockedUid.trim();
    if (normalizedUid.isEmpty || normalizedBlockedUid.isEmpty) {
      throw StateError('invalid_block_user_payload');
    }
    if (normalizedUid == normalizedBlockedUid) {
      throw StateError('cannot_block_self');
    }

    await _firestore
        .doc(FirestorePaths.blockedUser(normalizedUid, normalizedBlockedUid))
        .set(<String, dynamic>{
          // 유지보수 포인트:
          // 문서 ID를 차단 대상 uid로 고정해 중복 차단 문서 생성을 막습니다.
          'blockedUid': normalizedBlockedUid,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}
