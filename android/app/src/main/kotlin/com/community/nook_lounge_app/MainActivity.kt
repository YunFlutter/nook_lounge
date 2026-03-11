package com.community.nook_lounge_app

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  companion object {
    private const val appVersionChannelName = "nook_lounge_app/app_version"
    private const val getAppVersionMethod = "getAppVersion"
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      appVersionChannelName,
    ).setMethodCallHandler { call, result ->
      if (call.method != getAppVersionMethod) {
        result.notImplemented()
        return@setMethodCallHandler
      }

      result.success(resolveAppVersion())
    }
  }

  @Suppress("DEPRECATION")
  private fun resolveAppVersion(): String? {
    return try {
      val packageInfo =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
          packageManager.getPackageInfo(
            packageName,
            PackageManager.PackageInfoFlags.of(0),
          )
        } else {
          packageManager.getPackageInfo(packageName, 0)
        }

      packageInfo.versionName
    } catch (_: Exception) {
      null
    }
  }
}
