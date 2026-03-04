import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/presentation/state/push_offer_intent_notifier.dart';

class PushMessageService {
  PushMessageService({
    required FirebaseMessaging messaging,
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required PushOfferIntentNotifier offerIntentNotifier,
  }) : _messaging = messaging,
       _auth = auth,
       _firestore = firestore,
       _offerIntentNotifier = offerIntentNotifier;

  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
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

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 유지보수 포인트:
    // 앱이 포그라운드일 때도 iOS 시스템 푸시 배너/사운드가 표시되도록 설정합니다.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _safeSyncCurrentToken(reason: 'initialize');

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
      // foreground에서도 메시지 수신 스트림을 유지해 플랫폼별 표시/처리 차이를
      // 안정적으로 수용합니다. (iOS는 위 presentation 옵션으로 시스템 배너 노출)
      debugPrint(
        '[PushMessageService] foreground message: ${message.messageId}',
      );
    });

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (token) async {
        try {
          await _upsertTokenForCurrentUser(token);
        } catch (error) {
          debugPrint('[PushMessageService] token refresh sync failed: $error');
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[PushMessageService] token refresh stream error: $error');
      },
    );

    _authSubscription = _auth.authStateChanges().listen((user) async {
      if (user == null) {
        return;
      }
      await _safeSyncCurrentToken(reason: 'auth_state_changed');
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
        debugPrint(
          '[PushMessageService] token sync deferred ($reason): $error',
        );
        return;
      }
      debugPrint('[PushMessageService] token sync failed ($reason): $error');
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
