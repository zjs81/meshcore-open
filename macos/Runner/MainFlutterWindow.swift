import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let badgeChannel = FlutterMethodChannel(
      name: "meshcore_open/app_badge",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    badgeChannel.setMethodCallHandler { call, result in
      guard call.method == "setBadgeCount" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let count = (call.arguments as? Int) ?? 0
      NSApp.dockTile.badgeLabel = count > 0 ? String(count) : nil
      result(nil)
    }

    super.awakeFromNib()
  }
}
