import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/domain/model/island_profile.dart';

class IslandFirestoreDataSource {
  IslandFirestoreDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<bool> hasPrimaryIsland(String uid) async {
    final userRef = _firestore.doc(FirestorePaths.user(uid));

    final cachedDoc = await userRef.get(const GetOptions(source: Source.cache));
    final cachedPrimaryIslandId =
        cachedDoc.data()?['primaryIslandId'] as String?;

    if (cachedPrimaryIslandId != null && cachedPrimaryIslandId.isNotEmpty) {
      return true;
    }

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
}
