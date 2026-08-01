import Cocoa
import FlutterMacOS

/// Native screenshot / screen-recording prevention for macOS.
///
/// `NSWindow.sharingType = .none` excludes the window from screenshots and
/// screen recordings.
class ScreenGuardHandler {
  private let channel: FlutterMethodChannel
  private weak var window: NSWindow?

  init(messenger: FlutterBinaryMessenger, window: NSWindow?) {
    self.window = window
    channel = FlutterMethodChannel(name: "u/screen_guard", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "enable": self?.setScreenGuard(true); result(nil)
      case "disable": self?.setScreenGuard(false); result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
  }

  private func setScreenGuard(_ enabled: Bool) {
    let target: NSWindow? = window ?? NSApplication.shared.mainWindow
    target?.sharingType = enabled ? .none : .readWrite
  }
}
