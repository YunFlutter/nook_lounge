import 'dart:async';

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

  Stream<Set<String>> watchInvisibleUserIds(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return Stream<Set<String>>.value(const <String>{});
    }

    late final StreamController<Set<String>> controller;
    StreamSubscription<Set<String>>? blockedSubscription;
    StreamSubscription<Set<String>>? blockerSubscription;
    var blockedUserIds = const <String>{};
    var blockerUserIds = const <String>{};

    void emit() {
      controller.add(<String>{...blockedUserIds, ...blockerUserIds});
    }

    controller = StreamController<Set<String>>(
      onListen: () {
        blockedSubscription = watchBlockedUserIds(normalizedUid).listen((ids) {
          blockedUserIds = ids;
          emit();
        }, onError: controller.addError);
        blockerSubscription = _watchBlockerUserIds(normalizedUid).listen((ids) {
          blockerUserIds = ids;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await blockedSubscription?.cancel();
        await blockerSubscription?.cancel();
      },
    );

    return controller.stream;
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

  Future<bool> hasBlockRelationship({
    required String uid,
    required String otherUid,
  }) async {
    final normalizedUid = uid.trim();
    final normalizedOtherUid = otherUid.trim();
    if (normalizedUid.isEmpty || normalizedOtherUid.isEmpty) {
      return false;
    }
    if (normalizedUid == normalizedOtherUid) {
      return true;
    }

    final snapshots = await Future.wait(
      <Future<DocumentSnapshot<Map<String, dynamic>>>>[
        _firestore
            .doc(FirestorePaths.blockedUser(normalizedUid, normalizedOtherUid))
            .get(),
        _firestore
            .doc(FirestorePaths.blockedUser(normalizedOtherUid, normalizedUid))
            .get(),
      ],
    );
    return snapshots.any((snapshot) => snapshot.exists);
  }

  Stream<Set<String>> _watchBlockerUserIds(String uid) {
    return _firestore
        .collectionGroup('blockedUsers')
        .where('blockedUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final ids = <String>{};
          for (final doc in snapshot.docs) {
            final blockerUid = extractBlockerUid(doc.reference.path);
            if (blockerUid.isNotEmpty && blockerUid != uid) {
              ids.add(blockerUid);
            }
          }
          return ids;
        });
  }

  static String extractBlockerUid(String documentPath) {
    final segments = documentPath.split('/');
    if (segments.length != 4) {
      return '';
    }
    if (segments[0] != 'users' || segments[2] != 'blockedUsers') {
      return '';
    }
    return segments[1].trim();
  }
}
