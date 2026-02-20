import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/core/error/app_exception.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FirebaseAuthDataSource {
  FirebaseAuthDataSource({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore,
       _googleSignIn = googleSignIn;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  bool _googleInitialized = false;

  Stream<String?> watchUserId() {
    return _firebaseAuth.authStateChanges().map((User? user) => user?.uid);
  }

  String? get currentUserId => _firebaseAuth.currentUser?.uid;
  bool get isAnonymous => _firebaseAuth.currentUser?.isAnonymous ?? false;

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

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    await _syncUserDocument(userCredential.user);
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

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    await _syncUserDocument(userCredential.user);
  }

  Future<void> signInAnonymously() async {
    final userCredential = await _firebaseAuth.signInAnonymously();
    await _syncUserDocument(userCredential.user);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();

    if (_googleInitialized) {
      await _googleSignIn.signOut();
    }
  }

  Future<void> _syncUserDocument(User? user) async {
    if (user == null) {
      throw AppException('로그인 사용자 정보를 찾을 수 없어요.');
    }

    final joinedAt = user.metadata.creationTime;
    final lastSignInAt = user.metadata.lastSignInTime;

    // 유지보수 포인트:
    // 로그인/가입 직후 users/{uid} 문서를 즉시 생성·동기화합니다.
    // 초기 프로필 기반 화면은 이 문서를 단일 소스로 사용하면 됩니다.
    await _firestore.doc(FirestorePaths.user(user.uid)).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'isAnonymous': user.isAnonymous,
      'providerIds': user.providerData
          .map((provider) => provider.providerId)
          .where((id) => id.isNotEmpty)
          .toList(growable: false),
      'joinedAt': joinedAt != null
          ? Timestamp.fromDate(joinedAt)
          : FieldValue.serverTimestamp(),
      'lastSignInAt': lastSignInAt != null
          ? Timestamp.fromDate(lastSignInAt)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
