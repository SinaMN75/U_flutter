import Cocoa
import FlutterMacOS

/// Native screenshot / screen-recording prevention for macOS.
///
/// `NSWindow.sharingType = .none` excludes every window of the app from
/// screenshots, screen recordings and screen sharing. macOS has no capture
/// notification, so attempts are detected from the system capture UI and the
/// capture key equivalents, then reported to Dart and — when `exitOnCapture`
/// is set — the process is killed.
class ScreenGuardHandler {
  private static let captureUIBundleId = "com.apple.screencaptureui"

  private let channel: FlutterMethodChannel
  private weak var window: NSWindow?
  private var guardEnabled = false
  private var exitOnCapture = true
  private var terminating = false
  private var keyMonitor: Any?
  private var watchdog: Timer?

  init(messenger: FlutterBinaryMessenger, window: NSWindow?) {
    self.window = window
    channel = FlutterMethodChannel(name: "u/screen_guard", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "enable":
        let args = call.arguments as? [String: Any]
        self?.enableGuard(exitOnCapture: args?["exitOnCapture"] as? Bool ?? true)
        result(nil)
      case "disable":
        self?.disableGuard()
        result(nil)
      case "isCaptured":
        result(self?.isCaptureUIRunning ?? false)
      case "terminate":
        self?.terminate()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    NSWorkspace.shared.notificationCenter.addObserver(
      self, selector: #selector(appLaunched(_:)),
      name: NSWorkspace.didLaunchApplicationNotification, object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(reapplyGuard),
      name: NSWindow.didBecomeKeyNotification, object: nil)
  }

  deinit {
    watchdog?.invalidate()
    if let monitor = keyMonitor { NSEvent.removeMonitor(monitor) }
    NotificationCenter.default.removeObserver(self)
    NSWorkspace.shared.notificationCenter.removeObserver(self)
  }

  private func enableGuard(exitOnCapture: Bool) {
    self.exitOnCapture = exitOnCapture
    guardEnabled = true
    applySharingType(.none)
    startKeyMonitor()
    startWatchdog()
    if isCaptureUIRunning { onCapture("screenRecording") }
  }

  private func disableGuard() {
    guardEnabled = false
    applySharingType(.readOnly)
    watchdog?.invalidate()
    watchdog = nil
    if let monitor = keyMonitor {
      NSEvent.removeMonitor(monitor)
      keyMonitor = nil
    }
  }

  @objc private func reapplyGuard() {
    if guardEnabled { applySharingType(.none) }
  }

  // Windows created after enable() (sheets, panels, secondary windows) default
  // back to sharing, so the type is re-asserted across all of them.
  private func applySharingType(_ type: NSWindow.SharingType) {
    let targets: [NSWindow] = NSApplication.shared.windows + [window, NSApplication.shared.mainWindow].compactMap { $0 }
    for target in targets where target.sharingType != type {
      target.sharingType = type
    }
  }

  private func startWatchdog() {
    watchdog?.invalidate()
    watchdog = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      guard let self = self, self.guardEnabled else { return }
      self.applySharingType(.none)
      if self.isCaptureUIRunning { self.onCapture("screenRecording") }
    }
  }

  private func startKeyMonitor() {
    guard keyMonitor == nil else { return }
    keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      guard let self = self, self.guardEnabled else { return event }
      let capture = event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift)
      // 3, 4 and 5 are the system screenshot and screen-recording shortcuts.
      if capture, [20, 21, 23].contains(Int(event.keyCode)) {
        self.onCapture("screenshot")
        return nil
      }
      return event
    }
  }

  private var isCaptureUIRunning: Bool {
    NSWorkspace.shared.runningApplications.contains {
      $0.bundleIdentifier == ScreenGuardHandler.captureUIBundleId
    }
  }

  @objc private func appLaunched(_ notification: Notification) {
    guard guardEnabled else { return }
    let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
    if app?.bundleIdentifier == ScreenGuardHandler.captureUIBundleId {
      onCapture("screenshot")
    }
  }

  private func onCapture(_ reason: String) {
    guard guardEnabled else { return }
    channel.invokeMethod("onScreenshot", arguments: nil)
    channel.invokeMethod("onViolation", arguments: reason)
    if exitOnCapture { terminate() }
  }

  private func terminate() {
    guard !terminating else { return }
    terminating = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      exit(0)
    }
  }
}
