import 'package:nook_lounge_app/domain/model/blocked_user_summary.dart';

abstract class UserBlockRepository {
  Stream<Set<String>> watchBlockedUserIds(String uid);

  Stream<Set<String>> watchInvisibleUserIds(String uid);

  Stream<List<BlockedUserSummary>> watchBlockedUsers(String uid);

  Future<void> blockUser({required String uid, required String blockedUid});

  Future<void> unblockUser({required String uid, required String blockedUid});

  Future<bool> hasBlockRelationship({
    required String uid,
    required String otherUid,
  });
}
