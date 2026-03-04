import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/data/service/local_notification_service.dart';
import 'package:nook_lounge_app/presentation/state/push_offer_intent_notifier.dart';

class PushMessageService {
  PushMessageService({
    required FirebaseMessaging messaging,
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required LocalNotificationService localNotificationService,
    required PushOfferIntentNotifier offerIntentNotifier,
  }) : _messaging = messaging,
       _auth = auth,
       _firestore = firestore,
       _localNotificationService = localNotificationService,
       _offerIntentNotifier = offerIntentNotifier;

  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final LocalNotificationService _localNotificationService;
  final PushOfferIntentNotifier _offerIntentNotifier;

  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<User?>? _authSubscription;
  String? _lastSyncedUid;
  String? _lastSyncedToken;
  bool _initialized = false;
  static const List<Duration> _tokenRetryDelays = <Duration>[
    Duration(seconds: 1),
    Duration(seconds: 3),
  ];
  static const List<Duration> _apnsTokenRetryDelays = <Duration>[
    Duration(milliseconds: 600),
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 3),
  ];

  static const String _diagNotificationPermissionDenied =
      'NOTIFICATION_PERMISSION_DENIED';
  static const String _diagApnsTokenUnavailable = 'APNS_TOKEN_UNAVAILABLE';
  static const String _diagApnsEnvironmentInvalid = 'APNS_ENVIRONMENT_INVALID';
  static const String _diagFirebaseProjectMismatch =
      'FIREBASE_PROJECT_MISMATCH';
  static const String _diagFirebaseServiceUnavailable =
      'FIREBASE_SERVICE_UNAVAILABLE';
  static const String _diagNetworkUnavailable = 'NETWORK_UNAVAILABLE';
  static const String _diagLocalNotificationShowFailed =
      'LOCAL_NOTIFICATION_SHOW_FAILED';
  static const String _diagLocalNotificationInitFailed =
      'LOCAL_NOTIFICATION_INIT_FAILED';
  static const String _diagUnknown = 'UNKNOWN';

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    try {
      await _localNotificationService.initialize(
        onNotificationTap: _handleNotificationTap,
      );
    } catch (error, stackTrace) {
      _logPushDiagnosis(
        stage: 'local_notification_initialize',
        error: error,
        stackTrace: stackTrace,
        classification: _diagLocalNotificationInitFailed,
        summary: '로컬 알림 서비스 초기화에 실패했습니다.',
        action: 'flutter_local_notifications 초기화 설정과 플랫폼 권한 상태를 확인하세요.',
      );
    }

    final permissionSettings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    final isNotificationPermissionGranted = _isPermissionGranted(
      permissionSettings.authorizationStatus,
    );
    if (!isNotificationPermissionGranted) {
      _logPushDiagnosis(
        stage: 'permission_request',
        authorizationStatus: permissionSettings.authorizationStatus,
        classification: _diagNotificationPermissionDenied,
        summary: '알림 권한이 허용되지 않아 푸시 수신이 차단됩니다.',
        action: 'iOS 설정 > 알림에서 앱 권한을 허용하고, 앱 첫 진입 권한 팝업 흐름을 점검하세요.',
      );
    }

    // 유지보수 포인트:
    // foreground 푸시는 flutter_local_notifications로 직접 렌더링하므로
    // iOS 시스템 foreground 표시(alert/badge/sound)는 중복 방지를 위해 비활성화합니다.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
    await _messaging.setAutoInitEnabled(true);

    await _safeSyncCurrentToken(reason: 'initialize');
    if (isNotificationPermissionGranted) {
      // 유지보수 포인트:
      // iOS는 APNs 토큰 생성이 지연되면 초기 getToken이 null/실패가 될 수 있어
      // APNs 토큰 준비 이후 FCM 토큰을 한 번 더 동기화합니다.
      unawaited(_syncTokenWhenApnsReady());
    }

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data);
    }

    _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      _handleNotificationTap(message.data);
    });

    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((
      message,
    ) {
      // 유지보수 포인트:
      // foreground 메시지는 flutter_local_notifications로 직접 표시해
      // 플랫폼 간 표시 동작을 일관되게 유지합니다.
      unawaited(_showForegroundLocalNotification(message));
      debugPrint(
        '[PushMessageService] foreground message: ${message.messageId}',
      );
    });

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (token) async {
        try {
          await _upsertTokenForCurrentUser(token);
        } catch (error) {
          final diagnosis = _diagnoseFromError(error);
          _logPushDiagnosis(
            stage: 'token_refresh_sync',
            error: error,
            classification: diagnosis.classification,
            summary: diagnosis.summary,
            action: diagnosis.action,
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        final diagnosis = _diagnoseFromError(error);
        _logPushDiagnosis(
          stage: 'token_refresh_stream',
          error: error,
          stackTrace: stackTrace,
          classification: diagnosis.classification,
          summary: diagnosis.summary,
          action: diagnosis.action,
        );
      },
    );

    _authSubscription = _auth.authStateChanges().listen((user) async {
      if (user == null) {
        return;
      }
      await _safeSyncCurrentToken(reason: 'auth_state_changed');
      unawaited(_syncTokenWhenApnsReady());
    });
  }

  void dispose() {
    _messageOpenedSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _authSubscription?.cancel();
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final offerId = _extractOfferId(data);
    if (offerId == null) {
      return;
    }
    _offerIntentNotifier.setOfferId(offerId);
  }

  String? _extractOfferId(Map<String, dynamic> data) {
    final candidates = <String>[
      data['offerId']?.toString() ?? '',
      data['marketOfferId']?.toString() ?? '',
      data['postId']?.toString() ?? '',
    ];

    for (final candidate in candidates) {
      final normalized = candidate.trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }

  Future<void> _showForegroundLocalNotification(RemoteMessage message) async {
    try {
      await _localNotificationService
          .showForegroundNotificationFromRemoteMessage(message);
    } catch (error, stackTrace) {
      _logPushDiagnosis(
        stage: 'foreground_local_notification',
        error: error,
        stackTrace: stackTrace,
        classification: _diagLocalNotificationShowFailed,
        summary: 'foreground 로컬 알림 표시에 실패했습니다.',
        action: '채널 생성/알림 권한/알림 아이콘 리소스를 점검하세요.',
      );
    }
  }

  Future<void> _syncCurrentToken() async {
    final token = await _getTokenWithRetry();
    if (token == null || token.trim().isEmpty) {
      return;
    }
    await _upsertTokenForCurrentUser(token);
  }

  Future<void> _safeSyncCurrentToken({required String reason}) async {
    try {
      await _syncCurrentToken();
    } catch (error) {
      // 유지보수 포인트:
      // FCM 서비스 일시 불가(예: SERVICE_NOT_AVAILABLE)는 앱 시작 실패로
      // 이어지지 않도록 삼키고, 이후 토큰 리프레시/재시도 시점에 복구합니다.
      if (_isServiceNotAvailableError(error)) {
        _logPushDiagnosis(
          stage: 'token_sync_$reason',
          error: error,
          classification: _diagFirebaseServiceUnavailable,
          summary: 'FCM 토큰 발급 서비스가 일시적으로 불가합니다.',
          action: '잠시 후 재시도되며, 반복되면 네트워크 상태와 Firebase 상태 페이지를 확인하세요.',
        );
        return;
      }
      final diagnosis = _diagnoseFromError(error);
      _logPushDiagnosis(
        stage: 'token_sync_$reason',
        error: error,
        classification: diagnosis.classification,
        summary: diagnosis.summary,
        action: diagnosis.action,
      );
    }
  }

  Future<String?> _getTokenWithRetry() async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await _messaging.getToken();
      } catch (error) {
        final canRetry =
            _isServiceNotAvailableError(error) &&
            attempt < _tokenRetryDelays.length;
        if (!canRetry) {
          rethrow;
        }
        final delay = _tokenRetryDelays[attempt];
        debugPrint(
          '[PushMessageService] FCM getToken unavailable '
          '(attempt ${attempt + 1}/${_tokenRetryDelays.length + 1}), '
          'retry in ${delay.inSeconds}s',
        );
        await Future<void>.delayed(delay);
      }
    }
  }

  bool _isServiceNotAvailableError(Object error) {
    if (error is FirebaseException) {
      final message = (error.message ?? '').toUpperCase();
      if (message.contains('SERVICE_NOT_AVAILABLE')) {
        return true;
      }
      if ((error.code == 'unknown' || error.code == 'unavailable') &&
          error.plugin == 'firebase_messaging') {
        return true;
      }
    }
    final text = error.toString().toUpperCase();
    return text.contains('SERVICE_NOT_AVAILABLE');
  }

  bool _isPermissionGranted(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  Future<void> _syncTokenWhenApnsReady() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    for (var attempt = 0; ; attempt++) {
      try {
        final apnsToken = await _messaging.getAPNSToken();
        if ((apnsToken ?? '').trim().isNotEmpty) {
          await _safeSyncCurrentToken(reason: 'ios_apns_ready');
          return;
        }
      } catch (error) {
        final diagnosis = _diagnoseFromError(error);
        _logPushDiagnosis(
          stage: 'ios_apns_wait',
          error: error,
          classification: diagnosis.classification,
          summary: diagnosis.summary,
          action: diagnosis.action,
          apnsTokenAvailable: false,
        );
      }

      if (attempt >= _apnsTokenRetryDelays.length) {
        _logPushDiagnosis(
          stage: 'ios_apns_wait',
          classification: _diagApnsTokenUnavailable,
          summary: 'APNs 토큰이 준비되지 않아 iOS FCM 토큰 동기화를 보류합니다.',
          action:
              'Runner Push Capability, aps-environment entitlements, 실기기 테스트 여부를 확인하세요.',
          apnsTokenAvailable: false,
        );
        return;
      }
      await Future<void>.delayed(_apnsTokenRetryDelays[attempt]);
    }
  }

  ({String classification, String summary, String action}) _diagnoseFromError(
    Object error,
  ) {
    final normalizedError = error.toString().toUpperCase();

    if (normalizedError.contains('NO APNS TOKEN SPECIFIED') ||
        (normalizedError.contains('APNS') &&
            normalizedError.contains('TOKEN') &&
            normalizedError.contains('NOT'))) {
      return (
        classification: _diagApnsTokenUnavailable,
        summary: 'APNs 토큰이 없는 상태에서 FCM 토큰을 요청했습니다.',
        action: 'iOS 권한 허용 후 APNs 토큰 등록 완료 시점에 FCM 토큰을 재동기화하세요.',
      );
    }

    if (normalizedError.contains('APS-ENVIRONMENT') ||
        normalizedError.contains('MISSING ENTITLEMENT') ||
        normalizedError.contains('NO VALID \'APS-ENVIRONMENT\' ENTITLEMENT')) {
      return (
        classification: _diagApnsEnvironmentInvalid,
        summary:
            'aps-environment entitlement 또는 Push Capability 설정이 유효하지 않습니다.',
        action:
            'Xcode Signing & Capabilities에서 Push Notifications 활성화와 프로비저닝 프로필을 점검하세요.',
      );
    }

    if (normalizedError.contains('INVALID_FETCH_RESPONSE') ||
        normalizedError.contains('SENDER ID') ||
        normalizedError.contains('MISMATCH') ||
        normalizedError.contains('INVALID-ARGUMENT')) {
      return (
        classification: _diagFirebaseProjectMismatch,
        summary: 'Firebase 앱 구성값(프로젝트/번들 ID/Sender ID) 불일치 가능성이 있습니다.',
        action:
            'GoogleService-Info.plist, firebase_options.dart, 번들 ID가 동일 프로젝트를 가리키는지 확인하세요.',
      );
    }

    if (_isServiceNotAvailableError(error) ||
        normalizedError.contains('UNAVAILABLE')) {
      return (
        classification: _diagFirebaseServiceUnavailable,
        summary: 'Firebase Messaging 서비스가 일시적으로 응답하지 않습니다.',
        action: '토큰 리프레시 재시도 후에도 반복되면 Firebase 상태와 네트워크를 확인하세요.',
      );
    }

    if (normalizedError.contains('NETWORK') ||
        normalizedError.contains('TIMEOUT') ||
        normalizedError.contains('SOCKET') ||
        normalizedError.contains('HOST LOOKUP')) {
      return (
        classification: _diagNetworkUnavailable,
        summary: '네트워크 상태 불안정으로 FCM 토큰 동기화가 실패했습니다.',
        action: '기기 네트워크 연결 및 방화벽/VPN 상태를 확인하세요.',
      );
    }

    return (
      classification: _diagUnknown,
      summary: '패턴에 매핑되지 않은 푸시 오류입니다.',
      action: 'error 원문과 stage 로그를 함께 확인해 추가 규칙을 보강하세요.',
    );
  }

  void _logPushDiagnosis({
    required String stage,
    required String classification,
    required String summary,
    required String action,
    Object? error,
    StackTrace? stackTrace,
    AuthorizationStatus? authorizationStatus,
    bool? apnsTokenAvailable,
  }) {
    final authText = authorizationStatus?.name ?? 'unknown';
    final apnsText = switch (apnsTokenAvailable) {
      true => 'ready',
      false => 'missing',
      null => 'unknown',
    };
    final errorText = (error?.toString() ?? '-').replaceAll('\n', ' ');

    debugPrint(
      '[PushDiag][$stage][$classification] $summary '
      '| action=$action | auth=$authText | apns=$apnsText | error=$errorText',
    );

    if (stackTrace != null) {
      debugPrint('[PushDiag][$stage][$classification][stack] $stackTrace');
    }
  }

  Future<void> _upsertTokenForCurrentUser(String token) async {
    final user = _auth.currentUser;
    if (user == null || user.uid.trim().isEmpty) {
      return;
    }
    final uid = user.uid.trim();
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      return;
    }

    final userRef = _firestore.doc(FirestorePaths.user(uid));

    // 유지보수 포인트:
    // 같은 유저에서 토큰이 재발급되면 이전 토큰 하위 문서를 제거합니다.
    // 토큰 저장은 users/{uid}/fcmTokens/{token} 단일 경로만 사용합니다.
    final previousUid = _lastSyncedUid;
    final previousToken = _lastSyncedToken;
    if (previousUid == uid &&
        previousToken != null &&
        previousToken.isNotEmpty &&
        previousToken != normalizedToken) {
      await _safeDeleteDoc(userRef.collection('fcmTokens').doc(previousToken));
      await _safeDeleteDoc(userRef.collection('devices').doc(previousToken));
      await _safeDeleteDoc(userRef.collection('pushTokens').doc(previousToken));
    }

    final tokenDoc = userRef.collection('fcmTokens').doc(normalizedToken);

    final now = FieldValue.serverTimestamp();
    final platform = defaultTargetPlatform.name;
    await tokenDoc.set(<String, dynamic>{
      'token': normalizedToken,
      'platform': platform,
      'updatedAt': now,
      'createdAt': now,
    }, SetOptions(merge: true));

    await userRef.set(<String, dynamic>{
      // 유지보수 포인트:
      // FCM 토큰 이중 저장을 방지하기 위해 루트 문서 토큰 필드는 정리하고
      // 하위 컬렉션(users/{uid}/fcmTokens)만 단일 소스로 유지합니다.
      'fcmtoken': FieldValue.delete(),
      'fcmToken': FieldValue.delete(),
      'fcmTokens': FieldValue.delete(),
      'pushToken': FieldValue.delete(),
      'pushTokens': FieldValue.delete(),
      'deviceToken': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _lastSyncedUid = uid;
    _lastSyncedToken = normalizedToken;
  }

  Future<void> _safeDeleteDoc(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      await ref.delete();
    } catch (_) {
      // no-op: 문서가 이미 없으면 무시합니다.
    }
  }
}
