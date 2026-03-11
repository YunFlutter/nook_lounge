import 'package:nook_lounge_app/domain/model/user_service_block.dart';

abstract class AuthRepository {
  Stream<String?> watchUserId();
  Stream<bool> watchUserDocumentExists(String uid);

  String? get currentUserId;
  bool get isAnonymous;
  bool get isWithdrawalInProgress;
  Future<bool> hasUserDocument(String uid);
  Future<UserServiceBlock?> getActiveServiceBlock(String uid);

  Future<void> signInWithGoogle();

  Future<void> signInWithApple();

  Future<void> signInAnonymously();

  Future<void> signOut();

  Future<void> requestWithdrawal();
}
