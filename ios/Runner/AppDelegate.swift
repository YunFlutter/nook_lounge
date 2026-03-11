import Flutter
import FirebaseMessaging
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let appVersionChannelName = "nook_lounge_app/app_version"
  private static let getAppVersionMethod = "getAppVersion"

  private var appVersionChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // 유지보수 포인트:
    // iOS에서 APNs 토큰 수신 경로를 확실히 열기 위해 remote notification 등록을
    // 명시적으로 호출합니다. (Firebase swizzling 유무와 무관하게 안전하게 동작)
    application.registerForRemoteNotifications()
#if targetEnvironment(simulator)
    logPushDiagnosis(
      stage: "didFinish",
      classification: "SIMULATOR_UNSUPPORTED",
      summary: "iOS 시뮬레이터는 APNs 원격 푸시를 수신하지 않습니다.",
      action: "실기기에서 푸시 수신 테스트를 진행하세요."
    )
#endif
    return didFinish
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    appVersionChannel = FlutterMethodChannel(
      name: Self.appVersionChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    appVersionChannel?.setMethodCallHandler { call, result in
      guard call.method == Self.getAppVersionMethod else {
        result(FlutterMethodNotImplemented)
        return
      }

      result(Self.resolveAppVersion())
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // 유지보수 포인트:
    // APNs 토큰을 Firebase Messaging에 직접 전달해 iOS 토큰 매핑 실패 가능성을 줄입니다.
    Messaging.messaging().apnsToken = deviceToken
    logPushDiagnosis(
      stage: "apns_register_success",
      classification: "APNS_REGISTERED",
      summary: "APNs 기기 토큰 등록에 성공했습니다.",
      action: "다음 단계인 FCM 토큰 동기화 로그를 확인하세요.",
      detail: "token_length=\(deviceToken.count)"
    )
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    let diagnosis = diagnoseApnsRegistrationError(error)
    let nsError = error as NSError
    logPushDiagnosis(
      stage: "apns_register_fail",
      classification: diagnosis.classification,
      summary: diagnosis.summary,
      action: diagnosis.action,
      detail: "domain=\(nsError.domain), code=\(nsError.code), error=\(error.localizedDescription)"
    )
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  private func diagnoseApnsRegistrationError(_ error: Error) -> (
    classification: String,
    summary: String,
    action: String
  ) {
    let nsError = error as NSError
    let normalized = error.localizedDescription.uppercased()

    if nsError.code == 3010 {
      return (
        classification: "SIMULATOR_UNSUPPORTED",
        summary: "시뮬레이터에서는 APNs 원격 푸시 등록이 지원되지 않습니다.",
        action: "실기기에서 알림 수신을 테스트하세요."
      )
    }

    if nsError.code == 3000 ||
      normalized.contains("APS-ENVIRONMENT") ||
      normalized.contains("MISSING ENTITLEMENT")
    {
      return (
        classification: "APNS_ENVIRONMENT_INVALID",
        summary: "Push Capability 또는 aps-environment entitlement 설정이 유효하지 않습니다.",
        action: "Xcode Signing & Capabilities와 프로비저닝 프로필을 확인하세요."
      )
    }

    if normalized.contains("NOT ALLOWED") ||
      normalized.contains("DENIED")
    {
      return (
        classification: "NOTIFICATION_PERMISSION_DENIED",
        summary: "기기 알림 권한이 거부되어 APNs 등록에 실패했습니다.",
        action: "iOS 설정에서 앱 알림 권한을 허용하세요."
      )
    }

    return (
      classification: "UNKNOWN",
      summary: "패턴에 매핑되지 않은 APNs 등록 오류입니다.",
      action: "domain/code/error 원문을 기반으로 진단 규칙을 추가하세요."
    )
  }

  private func logPushDiagnosis(
    stage: String,
    classification: String,
    summary: String,
    action: String,
    detail: String = "-"
  ) {
    NSLog(
      "[PushDiag][%@][%@] %@ | action=%@ | detail=%@",
      stage,
      classification,
      summary,
      action,
      detail
    )
  }

  private static func resolveAppVersion() -> String {
    let rawVersion = Bundle.main.object(
      forInfoDictionaryKey: "CFBundleShortVersionString"
    ) as? String
    let normalizedVersion = rawVersion?.trimmingCharacters(in: .whitespacesAndNewlines)
    return normalizedVersion?.isEmpty == false ? normalizedVersion! : "0.0.0"
  }
}
