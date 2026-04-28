import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  /// Handles the "Check for Updates…" menu item.
  @objc func checkForUpdates(_ sender: Any) {
    guard
      let window = mainFlutterWindow,
      let controller = window.contentViewController as? FlutterViewController
    else { return }

    let channel = FlutterMethodChannel(
      name: "com.lumi/app_menu",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.invokeMethod("checkForUpdates", arguments: nil)
  }
}
