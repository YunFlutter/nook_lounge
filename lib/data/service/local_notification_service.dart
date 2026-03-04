import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService({required FlutterLocalNotificationsPlugin plugin})
    : _plugin = plugin;

  final FlutterLocalNotificationsPlugin _plugin;
  void Function(Map<String, dynamic> data)? _onNotificationTap;
  bool _initialized = false;

  static const String _defaultChannelId = 'default';
  static const String _defaultChannelName = '기본 알림';
  static const String _defaultChannelDescription = '앱 기본 알림 채널';

  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
        _defaultChannelId,
        _defaultChannelName,
        description: _defaultChannelDescription,
        importance: Importance.high,
      );

  Future<void> initialize({
    required void Function(Map<String, dynamic> data) onNotificationTap,
  }) async {
    _onNotificationTap = onNotificationTap;
    if (_initialized) {
      return;
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    await _requestDarwinPermissionsIfNeeded();
    await _createAndroidChannelIfNeeded();
    _initialized = true;

    // 유지보수 포인트:
    // 로컬 알림 탭으로 앱이 시작된 경우 payload 딥링크를 초기 진입 시점에 복원합니다.
    await _dispatchLaunchNotificationTapIfNeeded();
  }

  Future<void> showForegroundNotificationFromRemoteMessage(
    RemoteMessage message,
  ) async {
    if (kIsWeb) {
      return;
    }
    if (!_initialized) {
      debugPrint('[LocalNotificationService] skipped: service not initialized');
      return;
    }

    final data = _normalizeData(message.data);
    final title = _resolveTitle(message: message, data: data);
    final body = _resolveBody(message: message, data: data);
    if (title.isEmpty && body.isEmpty) {
      return;
    }

    await _plugin.show(
      id: _resolveNotificationId(message, data),
      title: title.isEmpty ? '새 알림' : title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _defaultChannelId,
          _defaultChannelName,
          channelDescription: _defaultChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: data.isEmpty ? null : jsonEncode(data),
    );
  }

  Future<void> _requestDarwinPermissionsIfNeeded() async {
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin == null) {
      return;
    }
    await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _createAndroidChannelIfNeeded() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) {
      return;
    }

    await androidPlugin.requestNotificationsPermission();
    await androidPlugin.createNotificationChannel(_defaultChannel);
  }

  Future<void> _dispatchLaunchNotificationTapIfNeeded() async {
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails == null) {
      return;
    }
    if (!launchDetails.didNotificationLaunchApp) {
      return;
    }
    final response = launchDetails.notificationResponse;
    if (response == null) {
      return;
    }
    _onDidReceiveNotificationResponse(response);
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.trim().isEmpty) {
      return;
    }

    final data = _decodePayload(payload);
    if (data.isEmpty) {
      return;
    }
    _onNotificationTap?.call(data);
  }

  Map<String, dynamic> _normalizeData(Map<String, dynamic> rawData) {
    final normalized = <String, dynamic>{};
    for (final entry in rawData.entries) {
      normalized[entry.key] = entry.value?.toString() ?? '';
    }
    return normalized;
  }

  String _resolveTitle({
    required RemoteMessage message,
    required Map<String, dynamic> data,
  }) {
    final dataTitle = data['title']?.toString().trim() ?? '';
    if (dataTitle.isNotEmpty) {
      return dataTitle;
    }
    return message.notification?.title?.trim() ?? '';
  }

  String _resolveBody({
    required RemoteMessage message,
    required Map<String, dynamic> data,
  }) {
    final dataBody = data['body']?.toString().trim() ?? '';
    if (dataBody.isNotEmpty) {
      return dataBody;
    }
    return message.notification?.body?.trim() ?? '';
  }

  int _resolveNotificationId(RemoteMessage message, Map<String, dynamic> data) {
    final offerId = data['offerId']?.toString() ?? '';
    final type = data['type']?.toString() ?? '';
    final source =
        '${message.messageId ?? ''}|'
        '${message.sentTime?.millisecondsSinceEpoch ?? 0}|'
        '$offerId|$type';
    return source.hashCode & 0x7fffffff;
  }

  Map<String, dynamic> _decodePayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        return <String, dynamic>{};
      }
      return decoded.map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), value),
      );
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
