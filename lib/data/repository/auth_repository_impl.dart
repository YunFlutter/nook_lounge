import 'dart:async';

import 'package:nook_lounge_app/core/telemetry/app_telemetry.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry_events.dart';
import 'package:nook_lounge_app/domain/model/user_service_block.dart';
import 'package:nook_lounge_app/data/datasource/firebase_auth_data_source.dart';
import 'package:nook_lounge_app/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuthDataSource dataSource,
    required AppTelemetry telemetry,
  }) : _dataSource = dataSource,
       _telemetry = telemetry;

  final FirebaseAuthDataSource _dataSource;
  final AppTelemetry _telemetry;

  @override
  Stream<String?> watchUserId() => _dataSource.watchUserId();

  @override
  Stream<bool> watchUserDocumentExists(String uid) =>
      _dataSource.watchUserDocumentExists(uid);

  @override
  String? get currentUserId => _dataSource.currentUserId;
  @override
  bool get isAnonymous => _dataSource.isAnonymous;

  @override
  Future<bool> hasUserDocument(String uid) => _dataSource.hasUserDocument(uid);

  @override
  Future<UserServiceBlock?> getActiveServiceBlock(String uid) {
    return _dataSource.getActiveServiceBlock(uid);
  }

  @override
  Future<void> signInWithGoogle() async {
    await _trackAuthAction(
      provider: 'google',
      reason: 'auth.sign_in_google',
      task: _dataSource.signInWithGoogle,
    );
  }

  @override
  Future<void> signInWithApple() async {
    await _trackAuthAction(
      provider: 'apple',
      reason: 'auth.sign_in_apple',
      task: _dataSource.signInWithApple,
    );
  }

  @override
  Future<void> signInAnonymously() async {
    await _trackAuthAction(
      provider: 'anonymous',
      reason: 'auth.sign_in_anonymous',
      task: _dataSource.signInAnonymously,
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await _dataSource.signOut();
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.authSignOut,
          parameters: const <String, Object>{'result': 'success'},
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(error, stackTrace, reason: 'auth.sign_out'),
      );
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.authSignOut,
          parameters: const <String, Object>{'result': 'failure'},
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> requestWithdrawal() async {
    try {
      await _dataSource.requestWithdrawal();
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.authWithdrawalRequested,
          parameters: const <String, Object>{'result': 'success'},
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'auth.request_withdrawal',
        ),
      );
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.authWithdrawalRequested,
          parameters: const <String, Object>{'result': 'failure'},
        ),
      );
      rethrow;
    }
  }

  Future<void> _trackAuthAction({
    required String provider,
    required String reason,
    required Future<void> Function() task,
  }) async {
    try {
      await task();
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.authSignIn,
          parameters: <String, Object>{
            'provider': provider,
            'result': 'success',
          },
        ),
      );
    } catch (error, stackTrace) {
      unawaited(_telemetry.recordError(error, stackTrace, reason: reason));
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.authSignIn,
          parameters: <String, Object>{
            'provider': provider,
            'result': 'failure',
          },
        ),
      );
      rethrow;
    }
  }
}
