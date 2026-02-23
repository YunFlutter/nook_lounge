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

    await _syncCurrentToken();

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
      debugPrint('[PushMessageService] foreground message: ${message.messageId}');
    });

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      await _upsertTokenForCurrentUser(token);
    });

    _authSubscription = _auth.authStateChanges().listen((user) async {
      if (user == null) {
        return;
      }
      await _syncCurrentToken();
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
    final token = await _messaging.getToken();
    if (token == null || token.trim().isEmpty) {
      return;
    }
    await _upsertTokenForCurrentUser(token);
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

    // 유지보수 포인트:
    // 같은 유저에서 토큰이 재발급되면 이전 토큰을 배열/서브컬렉션에서 제거해
    // 만료 토큰으로 중복 푸시를 보내는 상황을 줄입니다.
    final previousUid = _lastSyncedUid;
    final previousToken = _lastSyncedToken;
    if (previousUid == uid &&
        previousToken != null &&
        previousToken.isNotEmpty &&
        previousToken != normalizedToken) {
      final userRef = _firestore.doc(FirestorePaths.user(uid));
      await userRef.set(<String, dynamic>{
        'fcmTokens': FieldValue.arrayRemove(<String>[previousToken]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final previousTokenRef = _firestore.doc(
        '${FirestorePaths.user(uid)}/fcmTokens/$previousToken',
      );
      try {
        await previousTokenRef.delete();
      } catch (_) {
        // no-op: 문서가 이미 없으면 무시합니다.
      }
    }

    final tokenDoc = _firestore.doc(
      '${FirestorePaths.user(uid)}/fcmTokens/$normalizedToken',
    );

    final now = FieldValue.serverTimestamp();
    final platform = defaultTargetPlatform.name;
    await tokenDoc.set(<String, dynamic>{
      'token': normalizedToken,
      'platform': platform,
      'updatedAt': now,
      'createdAt': now,
    }, SetOptions(merge: true));

    await _firestore.doc(FirestorePaths.user(uid)).set(<String, dynamic>{
      // 유지보수 포인트:
      // 요청사항에 맞춰 users/{uid}.fcmtoken 필드를 최신 토큰으로 유지합니다.
      // 레거시/외부 연동 호환을 위해 fcmToken도 동일값으로 동기화합니다.
      'fcmtoken': normalizedToken,
      'fcmToken': normalizedToken,
      'fcmTokens': FieldValue.arrayUnion(<String>[normalizedToken]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _lastSyncedUid = uid;
    _lastSyncedToken = normalizedToken;
  }
}
