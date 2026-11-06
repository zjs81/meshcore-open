import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MeshAppBadge") {
      let channel = FlutterMethodChannel(
        name: "meshcore_open/app_badge",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "setBadgeCount" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let count = (call.arguments as? Int) ?? 0
        UNUserNotificationCenter.current().setBadgeCount(max(0, count)) { error in
          if let error = error {
            result(FlutterError(code: "badge", message: error.localizedDescription, details: nil))
          } else {
            result(nil)
          }
        }
      }
    }
  }
}
