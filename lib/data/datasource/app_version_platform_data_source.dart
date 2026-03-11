import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nook_lounge_app/core/constants/app_strings.dart';

class AppVersionPlatformDataSource {
  static const MethodChannel _channel = MethodChannel(
    'nook_lounge_app/app_version',
  );

  Future<String> fetchCurrentVersion() async {
    try {
      final version = await _channel.invokeMethod<String>('getAppVersion');
      final normalizedVersion = version?.trim();
      if (normalizedVersion != null && normalizedVersion.isNotEmpty) {
        return normalizedVersion;
      }
    } on PlatformException catch (error, stackTrace) {
      debugPrint('fetchCurrentVersion failed: $error\n$stackTrace');
    }

    // 유지보수 포인트:
    // 네이티브 채널 연결이 아직 없는 환경(테스트/미구현 플랫폼)에서는
    // 최소 동작을 보장하도록 앱 상수 버전으로 안전하게 폴백합니다.
    return AppStrings.appVersion;
  }
}
