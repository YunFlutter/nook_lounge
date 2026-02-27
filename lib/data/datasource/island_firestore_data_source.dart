import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/domain/model/island_profile.dart';

class IslandFirestoreDataSource {
  IslandFirestoreDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<bool> hasPrimaryIslandFromCache(String uid) async {
    final userRef = _firestore.doc(FirestorePaths.user(uid));

    try {
      final cachedDoc = await userRef.get(
        const GetOptions(source: Source.cache),
      );
      final cachedPrimaryIslandId =
          cachedDoc.data()?['primaryIslandId'] as String?;

      return cachedPrimaryIslandId != null && cachedPrimaryIslandId.isNotEmpty;
    } on FirebaseException {
      // 유지보수 포인트:
      // 캐시 조회 실패는 네트워크/로컬 상태 이슈일 수 있으므로
      // 앱 시작을 막지 않고 "섬 미보유"로 안전 fallback 합니다.
      return false;
    }
  }

  Future<bool> hasPrimaryIslandFromServer(String uid) async {
    final userRef = _firestore.doc(FirestorePaths.user(uid));

    final serverDoc = await userRef.get(
      const GetOptions(source: Source.server),
    );
    final serverPrimaryIslandId =
        serverDoc.data()?['primaryIslandId'] as String?;

    return serverPrimaryIslandId != null && serverPrimaryIslandId.isNotEmpty;
  }

  Future<void> createPrimaryIsland({
    required String uid,
    required IslandProfile profile,
  }) async {
    final batch = _firestore.batch();

    final userRef = _firestore.doc(FirestorePaths.user(uid));
    final islandRef = _firestore.doc(FirestorePaths.island(uid, profile.id));
    final homeSummaryRef = _firestore.doc(
      FirestorePaths.homeSummary(uid, profile.id),
    );

    batch.set(userRef, <String, dynamic>{
      'primaryIslandId': profile.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(islandRef, <String, dynamic>{
      ...profile.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 유지보수 포인트:
    // 홈 진입 시 필요한 최소 데이터만 별도 summary 문서에 저장해
    // 홈 진입 1회당 읽기 비용을 안정적으로 1 read로 제한합니다.
    batch.set(homeSummaryRef, <String, dynamic>{
      'residentCount': 0,
      'museumProgress': <String, int>{
        'fish': 0,
        'bugs': 0,
        'sea': 0,
        'fossils': 0,
        'art': 0,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<String?> watchPrimaryIslandId(String uid) {
    return _firestore.doc(FirestorePaths.user(uid)).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return null;
      }
      final islandId = (data['primaryIslandId'] as String?)?.trim();
      if (islandId == null || islandId.isEmpty) {
        return null;
      }
      return islandId;
    });
  }

  Stream<List<IslandProfile>> watchIslands(String uid) {
    return _firestore
        .collection(FirestorePaths.islands(uid))
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final islands = <IslandProfile>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            islands.add(IslandProfile.fromMap(data, id: doc.id));
          }
          return islands;
        });
  }

  Future<void> setPrimaryIsland({
    required String uid,
    required String islandId,
  }) async {
    await _firestore.doc(FirestorePaths.user(uid)).set(<String, dynamic>{
      'primaryIslandId': islandId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateIslandProfile({
    required String uid,
    required IslandProfile profile,
  }) async {
    await _firestore.doc(FirestorePaths.island(uid, profile.id)).set(
      <String, dynamic>{
        ...profile.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteIsland({
    required String uid,
    required String islandId,
  }) async {
    final normalizedIslandId = islandId.trim();
    if (normalizedIslandId.isEmpty) {
      return;
    }

    final userRef = _firestore.doc(FirestorePaths.user(uid));
    final islandRef = _firestore.doc(
      FirestorePaths.island(uid, normalizedIslandId),
    );
    final homeSummaryRef = _firestore.doc(
      FirestorePaths.homeSummary(uid, normalizedIslandId),
    );

    final userSnapshot = await userRef.get();
    final userData = userSnapshot.data() ?? const <String, dynamic>{};
    final currentPrimaryIslandId =
        (userData['primaryIslandId'] as String?)?.trim() ?? '';

    final islandSnapshot = await _firestore
        .collection(FirestorePaths.islands(uid))
        .get();
    String? nextPrimaryIslandId;
    for (final doc in islandSnapshot.docs) {
      if (doc.id == normalizedIslandId) {
        continue;
      }
      nextPrimaryIslandId = doc.id;
      break;
    }

    final batch = _firestore.batch();
    batch.delete(islandRef);
    batch.delete(homeSummaryRef);

    if (currentPrimaryIslandId == normalizedIslandId) {
      batch.set(userRef, <String, dynamic>{
        'primaryIslandId': nextPrimaryIslandId ?? FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }
}
