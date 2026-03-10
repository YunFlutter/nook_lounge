abstract class UserBlockRepository {
  Stream<Set<String>> watchBlockedUserIds(String uid);

  Stream<Set<String>> watchInvisibleUserIds(String uid);

  Future<void> blockUser({required String uid, required String blockedUid});

  Future<bool> hasBlockRelationship({
    required String uid,
    required String otherUid,
  });
}
