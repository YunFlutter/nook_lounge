import 'package:nook_lounge_app/data/datasource/firebase_auth_data_source.dart';
import 'package:nook_lounge_app/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required FirebaseAuthDataSource dataSource})
    : _dataSource = dataSource;

  final FirebaseAuthDataSource _dataSource;

  @override
  Stream<String?> watchUserId() => _dataSource.watchUserId();

  @override
  String? get currentUserId => _dataSource.currentUserId;
  @override
  bool get isAnonymous => _dataSource.isAnonymous;

  @override
  Future<void> signInWithGoogle() => _dataSource.signInWithGoogle();

  @override
  Future<void> signInWithApple() => _dataSource.signInWithApple();

  @override
  Future<void> signInAnonymously() => _dataSource.signInAnonymously();

  @override
  Future<void> signOut() => _dataSource.signOut();

  @override
  Future<void> requestWithdrawal() => _dataSource.requestWithdrawal();
}
