import 'package:nook_lounge_app/domain/model/create_island_draft.dart';
import 'package:nook_lounge_app/domain/model/island_profile.dart';

abstract class IslandRepository {
  /// 앱 시작 시 캐시만 사용해 즉시 분기합니다.
  Future<bool> hasPrimaryIsland(String uid);

  /// 백그라운드 서버 재검증.
  /// - true/false: 서버 기준 결과
  /// - null: 네트워크 일시 장애로 판별 불가(무시)
  Future<bool?> revalidatePrimaryIsland(String uid);

  Future<String> createPrimaryIsland({
    required String uid,
    required CreateIslandDraft draft,
    String? passportImagePath,
  });

  Stream<String?> watchPrimaryIslandId(String uid);

  Stream<List<IslandProfile>> watchIslands(String uid);

  Future<void> setPrimaryIsland({
    required String uid,
    required String islandId,
  });

  Future<void> updateIslandProfile({
    required String uid,
    required IslandProfile profile,
    String? passportImagePath,
  });

  Future<void> deleteIsland({required String uid, required String islandId});
}
