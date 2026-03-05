abstract class AuthRepository {
  Stream<String?> watchUserId();
  Stream<bool> watchUserDocumentExists(String uid);

  String? get currentUserId;
  bool get isAnonymous;
  Future<bool> hasUserDocument(String uid);

  Future<void> signInWithGoogle();

  Future<void> signInWithApple();

  Future<void> signInAnonymously();

  Future<void> signOut();

  Future<void> requestWithdrawal();
}
