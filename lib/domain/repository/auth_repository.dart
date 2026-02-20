abstract class AuthRepository {
  Stream<String?> watchUserId();

  String? get currentUserId;

  Future<void> signInWithGoogle();

  Future<void> signInWithApple();

  Future<void> signInAnonymously();

  Future<void> signOut();
}
