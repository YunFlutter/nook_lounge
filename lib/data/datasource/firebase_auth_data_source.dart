import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nook_lounge_app/core/error/app_exception.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FirebaseAuthDataSource {
  FirebaseAuthDataSource({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  bool _googleInitialized = false;

  Stream<String?> watchUserId() {
    return _firebaseAuth.authStateChanges().map((User? user) => user?.uid);
  }

  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  Future<void> signInWithGoogle() async {
    if (!_googleInitialized) {
      await _googleSignIn.initialize();
      _googleInitialized = true;
    }

    final GoogleSignInAccount account = await _googleSignIn.authenticate();

    final GoogleSignInAuthentication auth = account.authentication;
    final String? idToken = auth.idToken;

    if (idToken == null) {
      throw AppException('구글 로그인 토큰을 확인할 수 없어요.');
    }

    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    await _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> signInWithApple() async {
    final AuthorizationCredentialAppleID appleCredential =
        await SignInWithApple.getAppleIDCredential(
          scopes: <AppleIDAuthorizationScopes>[
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

    final String? idToken = appleCredential.identityToken;
    final String authorizationCode = appleCredential.authorizationCode;

    if (idToken == null) {
      throw AppException('애플 로그인 토큰을 확인할 수 없어요.');
    }

    final OAuthCredential credential = OAuthProvider(
      'apple.com',
    ).credential(idToken: idToken, accessToken: authorizationCode);

    await _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> signInAnonymously() async {
    await _firebaseAuth.signInAnonymously();
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();

    if (_googleInitialized) {
      await _googleSignIn.signOut();
    }
  }
}
