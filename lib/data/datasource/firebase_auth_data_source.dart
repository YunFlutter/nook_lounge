import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/core/error/app_exception.dart';
import 'package:nook_lounge_app/domain/model/user_service_block.dart';
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
  bool _isWithdrawalInProgress = false;

  Stream<String?> watchUserId() {
    return _firebaseAuth.authStateChanges().map((User? user) => user?.uid);
  }

  Stream<bool> watchUserDocumentExists(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return const Stream<bool>.empty();
    }

    return _firestore
        .doc(FirestorePaths.user(normalizedUid))
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .map((snapshot) => snapshot.exists)
        .distinct();
  }

  String? get currentUserId => _firebaseAuth.currentUser?.uid;
  bool get isAnonymous => _firebaseAuth.currentUser?.isAnonymous ?? false;
  bool get isWithdrawalInProgress => _isWithdrawalInProgress;

  Future<bool> hasUserDocument(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return false;
    }

    final userRef = _firestore.doc(FirestorePaths.user(normalizedUid));

    try {
      final cachedDoc = await userRef.get(
        const GetOptions(source: Source.cache),
      );
      if (cachedDoc.exists) {
        return true;
      }
    } on FirebaseException {
      // 유지보수 포인트:
      // 캐시 조회 실패는 오프라인/로컬 상태 이슈일 수 있으므로
      // 서버 확인 결과를 최종 기준으로 사용합니다.
    }

    final serverDoc = await userRef.get(
      const GetOptions(source: Source.server),
    );
    return serverDoc.exists;
  }

  Future<UserServiceBlock?> getActiveServiceBlock(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return null;
    }

    final blockRef = _firestore.doc(
      FirestorePaths.userServiceBlock(normalizedUid),
    );

    try {
      final serverDoc = await blockRef.get(
        const GetOptions(source: Source.server),
      );

      // 유지보수 포인트:
      // 서비스 차단은 users 문서가 아닌 전용 컬렉션(userServiceBlocks/{uid})을
      // 단일 소스로 보고, 서버 상태를 최우선으로 확인합니다.
      return parseActiveServiceBlock(serverDoc.data());
    } on FirebaseException {
      // 유지보수 포인트:
      // 서버 확인이 실패하면 마지막 캐시 상태로만 제한적으로 fallback 합니다.
    }

    final cachedDoc = await blockRef.get(
      const GetOptions(source: Source.cache),
    );
    return parseActiveServiceBlock(cachedDoc.data());
  }

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
    final user = userCredential.user;
    await _syncUserDocument(user);
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
    final user = userCredential.user;
    await _syncUserDocument(user);
  }

  Future<void> signInAnonymously() async {
    final userCredential = await _firebaseAuth.signInAnonymously();
    final user = userCredential.user;
    await _syncUserDocument(user);
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();

      if (_googleInitialized) {
        await _googleSignIn.signOut();
      }
    } finally {
      _isWithdrawalInProgress = false;
    }
  }

  Future<void> requestWithdrawal() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw AppException('로그인 사용자 정보를 찾을 수 없어요.');
    }

    _isWithdrawalInProgress = true;

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'deleteUserAccount',
      );
      await callable.call(<String, dynamic>{});
    } on FirebaseFunctionsException catch (error) {
      _isWithdrawalInProgress = false;
      final message = _resolveWithdrawalErrorMessage(error);
      if (message != null && message.isNotEmpty) {
        throw AppException(message);
      }
      if (error.code == 'unauthenticated') {
        throw AppException('로그인 정보가 만료되었어요. 다시 로그인 후 시도해 주세요.');
      }
      throw AppException('탈퇴 처리 중 오류가 발생했어요. 잠시 후 다시 시도해 주세요.');
    } catch (_) {
      _isWithdrawalInProgress = false;
      rethrow;
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

  @visibleForTesting
  static UserServiceBlock? parseActiveServiceBlock(
    Map<String, dynamic>? data, {
    DateTime? now,
  }) {
    if (data == null || data.isEmpty) {
      return null;
    }

    final blockedUntilDateTime = _readFirestoreDateTime(
      data['blockedUntilDateTime'],
    );
    if (blockedUntilDateTime == null) {
      return null;
    }

    final currentTime = now ?? DateTime.now();
    final block = UserServiceBlock(
      blockedUntilDateTime: blockedUntilDateTime,
      blockedAtDateTime: _readFirestoreDateTime(data['blockedAtDateTime']),
      reason: _readTrimmedString(data['reason']),
    );

    if (!block.isActiveAt(currentTime)) {
      return null;
    }

    return block;
  }

  static DateTime? _readFirestoreDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  static String? _readTrimmedString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return null;
    }
    return trimmedValue;
  }

  String? _resolveWithdrawalErrorMessage(FirebaseFunctionsException error) {
    final details = error.details;
    if (details is Map) {
      final detailMessage = _readTrimmedString(details['message']);
      if (detailMessage != null) {
        return detailMessage;
      }
    }

    final rawMessage = error.message?.trim();
    if (rawMessage == null ||
        rawMessage.isEmpty ||
        rawMessage.toUpperCase() == error.code.toUpperCase()) {
      return null;
    }
    return rawMessage;
  }
}
