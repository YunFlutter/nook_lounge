import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AppTelemetry {
  AppTelemetry({
    required FirebaseAnalytics analytics,
    required FirebaseCrashlytics crashlytics,
  }) : _analytics = analytics,
       _crashlytics = crashlytics;

  static const bool _analyticsCollectionEnabled = bool.fromEnvironment(
    'ENABLE_ANALYTICS_COLLECTION',
    defaultValue: true,
  );
  static const bool _crashlyticsInDebugEnabled = bool.fromEnvironment(
    'ENABLE_CRASHLYTICS_IN_DEBUG',
    defaultValue: false,
  );

  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;

  String? _lastScreenName;

  bool get shouldCaptureUncaughtErrors =>
      kReleaseMode || kProfileMode || _crashlyticsInDebugEnabled;

  Future<void> initialize() async {
    await _runSafely(() async {
      await _analytics.setAnalyticsCollectionEnabled(
        _analyticsCollectionEnabled,
      );
      await _crashlytics.setCrashlyticsCollectionEnabled(
        shouldCaptureUncaughtErrors,
      );
      await _crashlytics.setCustomKey('build_mode', _buildMode);
      await _crashlytics.setCustomKey(
        'analytics_collection_enabled',
        _analyticsCollectionEnabled,
      );
      await _crashlytics.setCustomKey(
        'crashlytics_collection_enabled',
        shouldCaptureUncaughtErrors,
      );
      await _crashlytics.setCustomKey('platform', defaultTargetPlatform.name);
    });
  }

  void installErrorHandlers() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);

      if (!shouldCaptureUncaughtErrors) {
        return;
      }

      _runSafely(() async {
        await _crashlytics.recordFlutterFatalError(details);
      });
    };

    if (!shouldCaptureUncaughtErrors) {
      return;
    }

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      _runSafely(() async {
        await _crashlytics.recordError(
          error,
          stackTrace,
          reason: 'platform_dispatcher',
          fatal: true,
        );
      });
      return true;
    };
  }

  Future<void> setUserContext({
    String? uid,
    required String sessionType,
  }) async {
    await _runSafely(() async {
      final normalizedUid = uid?.trim();
      final effectiveUid = (normalizedUid?.isEmpty ?? true)
          ? null
          : normalizedUid;

      await _analytics.setUserId(id: effectiveUid);
      await _analytics.setUserProperty(
        name: 'session_type',
        value: sessionType,
      );

      await _crashlytics.setUserIdentifier(effectiveUid ?? sessionType);
      await _crashlytics.setCustomKey('session_type', sessionType);
      await _crashlytics.setCustomKey('user_id_present', effectiveUid != null);
    });
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, Object?> parameters = const <String, Object?>{},
  }) async {
    final normalizedScreenName = screenName.trim();
    if (normalizedScreenName.isEmpty) {
      return;
    }

    final sanitizedParameters = _sanitizeParameters(parameters);
    await _runSafely(() async {
      await _analytics.logScreenView(
        screenName: normalizedScreenName,
        screenClass: screenClass ?? normalizedScreenName,
        parameters: sanitizedParameters.isEmpty ? null : sanitizedParameters,
      );
      _lastScreenName = normalizedScreenName;
      await _crashlytics.setCustomKey('current_screen', normalizedScreenName);
    });
  }

  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const <String, Object?>{},
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      return;
    }

    final sanitizedParameters = _sanitizeParameters(parameters);
    await _runSafely(() async {
      await _analytics.logEvent(
        name: normalizedName,
        parameters: sanitizedParameters.isEmpty ? null : sanitizedParameters,
      );
      await _crashlytics.setCustomKey('last_event', normalizedName);
      if (_lastScreenName != null) {
        await _crashlytics.setCustomKey('last_event_screen', _lastScreenName!);
      }
      await _crashlytics.log(
        sanitizedParameters.isEmpty
            ? normalizedName
            : '$normalizedName $sanitizedParameters',
      );
    });
  }

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    await _runSafely(() async {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    });
  }

  String get _buildMode {
    if (kReleaseMode) {
      return 'release';
    }
    if (kProfileMode) {
      return 'profile';
    }
    return 'debug';
  }

  Map<String, Object> _sanitizeParameters(Map<String, Object?> parameters) {
    final sanitized = <String, Object>{};

    parameters.forEach((key, value) {
      final normalizedKey = key.trim();
      if (normalizedKey.isEmpty || value == null) {
        return;
      }

      switch (value) {
        case String stringValue when stringValue.trim().isNotEmpty:
          sanitized[normalizedKey] = stringValue;
        case num numberValue:
          sanitized[normalizedKey] = numberValue;
        case bool boolValue:
          sanitized[normalizedKey] = boolValue;
        default:
          sanitized[normalizedKey] = value.toString();
      }
    });

    return sanitized;
  }

  Future<void> _runSafely(Future<void> Function() task) async {
    try {
      await task();
    } catch (_) {
      // 유지보수 포인트:
      // 계측 실패가 본 기능 흐름을 막지 않도록 모든 오류는 삼킵니다.
    }
  }
}
