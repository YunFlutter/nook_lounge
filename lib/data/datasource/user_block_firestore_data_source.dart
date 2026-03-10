import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/domain/model/blocked_user_summary.dart';

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
        blockerSubscription = _watchBlockedByUserIds(normalizedUid).listen((
          ids,
        ) {
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

  Stream<List<BlockedUserSummary>> watchBlockedUsers(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return Stream<List<BlockedUserSummary>>.value(
        const <BlockedUserSummary>[],
      );
    }

    return _firestore
        .collection(FirestorePaths.blockedUsers(normalizedUid))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final summaries = await Future.wait(
            snapshot.docs.map((doc) {
              return _buildBlockedUserSummary(
                ownerUid: normalizedUid,
                blockedUid: doc.id,
                blockedAtRaw: doc.data()['createdAt'],
              );
            }),
          );
          summaries.sort((a, b) => b.blockedAt.compareTo(a.blockedAt));
          return summaries;
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

    final batch = _firestore.batch();
    batch.set(
      _firestore.doc(
        FirestorePaths.blockedUser(normalizedUid, normalizedBlockedUid),
      ),
      <String, dynamic>{
        // 유지보수 포인트:
        // 문서 ID를 차단 대상 uid로 고정해 중복 차단 문서 생성을 막습니다.
        'blockedUid': normalizedBlockedUid,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _firestore.doc(
        FirestorePaths.blockedByUser(normalizedBlockedUid, normalizedUid),
      ),
      <String, dynamic>{
        // 유지보수 포인트:
        // 역방향 컬렉션을 함께 유지해 collectionGroup 없이도
        // "나를 차단한 사용자" 목록을 직접 구독할 수 있게 합니다.
        'blockerUid': normalizedUid,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> unblockUser({
    required String uid,
    required String blockedUid,
  }) async {
    final normalizedUid = uid.trim();
    final normalizedBlockedUid = blockedUid.trim();
    if (normalizedUid.isEmpty || normalizedBlockedUid.isEmpty) {
      throw StateError('invalid_unblock_user_payload');
    }

    final batch = _firestore.batch();
    batch.delete(
      _firestore.doc(
        FirestorePaths.blockedUser(normalizedUid, normalizedBlockedUid),
      ),
    );
    batch.delete(
      _firestore.doc(
        FirestorePaths.blockedByUser(normalizedBlockedUid, normalizedUid),
      ),
    );
    await batch.commit();
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

  Stream<Set<String>> _watchBlockedByUserIds(String uid) {
    return _firestore
        .collection(FirestorePaths.blockedByUsers(uid))
        .snapshots()
        .map((snapshot) {
          final ids = <String>{};
          for (final doc in snapshot.docs) {
            final blockerUid = ((doc.data()['blockerUid'] as String?) ?? doc.id)
                .trim();
            if (blockerUid.isNotEmpty && blockerUid != uid) {
              ids.add(blockerUid);
            }
          }
          return ids;
        });
  }

  Future<BlockedUserSummary> _buildBlockedUserSummary({
    required String ownerUid,
    required String blockedUid,
    required Object? blockedAtRaw,
  }) async {
    final normalizedOwnerUid = ownerUid.trim();
    final normalizedBlockedUid = blockedUid.trim();
    if (normalizedBlockedUid.isEmpty) {
      return BlockedUserSummary(
        uid: '',
        displayName: '알 수 없는 유저',
        islandName: '',
        avatarUrl: '',
        blockedAt: _readDateTime(blockedAtRaw) ?? DateTime.now(),
      );
    }

    try {
      final userSnapshot = await _firestore
          .doc(FirestorePaths.user(normalizedBlockedUid))
          .get();
      final userData = userSnapshot.data() ?? const <String, dynamic>{};
      final primaryIslandId =
          (userData['primaryIslandId'] as String?)?.trim() ?? '';
      Map<String, dynamic> islandData = const <String, dynamic>{};

      if (primaryIslandId.isNotEmpty) {
        final islandSnapshot = await _firestore
            .doc(FirestorePaths.island(normalizedBlockedUid, primaryIslandId))
            .get();
        islandData = islandSnapshot.data() ?? const <String, dynamic>{};
      }

      return BlockedUserSummary(
        uid: normalizedBlockedUid,
        displayName: _pickFirstNonEmpty(<Object?>[
          islandData['representativeName'],
          userData['displayName'],
          normalizedBlockedUid == normalizedOwnerUid ? '나' : '이름 없는 유저',
        ]),
        islandName: _pickFirstNonEmpty(<Object?>[
          islandData['islandName'],
          userData['islandName'],
        ]),
        avatarUrl: _pickFirstNonEmpty(<Object?>[
          islandData['imageUrl'],
          userData['avatarUrl'],
          userData['photoUrl'],
          userData['imageUrl'],
        ]),
        blockedAt: _readDateTime(blockedAtRaw) ?? DateTime.now(),
      );
    } catch (_) {
      return BlockedUserSummary(
        uid: normalizedBlockedUid,
        displayName: '알 수 없는 유저',
        islandName: '',
        avatarUrl: '',
        blockedAt: _readDateTime(blockedAtRaw) ?? DateTime.now(),
      );
    }
  }
}

String _pickFirstNonEmpty(List<Object?> values) {
  for (final value in values) {
    final normalized = value?.toString().trim() ?? '';
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }
  return '';
}

DateTime? _readDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  try {
    final dynamic converted = (value as dynamic).toDate();
    if (converted is DateTime) {
      return converted;
    }
  } catch (_) {}
  return null;
}
