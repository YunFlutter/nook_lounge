abstract class UserBlockRepository {
  Stream<Set<String>> watchBlockedUserIds(String uid);

  Future<void> blockUser({required String uid, required String blockedUid});
}
