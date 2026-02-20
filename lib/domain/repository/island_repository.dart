import 'package:nook_lounge_app/domain/model/create_island_draft.dart';

abstract class IslandRepository {
  Future<bool> hasPrimaryIsland(String uid);

  Future<void> createPrimaryIsland({
    required String uid,
    required CreateIslandDraft draft,
  });
}
