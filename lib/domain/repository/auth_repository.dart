abstract class AuthRepository {
  Stream<String?> watchUserId();

  String? get currentUserId;
  bool get isAnonymous;

  Future<void> signInWithGoogle();

  Future<void> signInWithApple();

  Future<void> signInAnonymously();

  Future<void> signOut();
}
