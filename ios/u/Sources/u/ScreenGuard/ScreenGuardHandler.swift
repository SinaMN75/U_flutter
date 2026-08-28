import Flutter
import UIKit

/// Native screenshot / screen-recording prevention for iOS.
///
/// iOS exposes no API that blocks a capture, so the protection is layered:
/// the key window's layer is reparented into the capture-proof canvas of a
/// secure `UITextField` (captures then come out blank), live recordings and
/// mirroring are covered with an opaque view, and every detected capture is
/// reported to Dart and terminates the process when `exitOnCapture` is set.
class ScreenGuardHandler {
  private let channel: FlutterMethodChannel
  private var guardEnabled = false
  private var exitOnCapture = true
  private var terminating = false

  // Hidden secure field whose capture-proof canvas hosts the window layer.
  private let secureField = UITextField()
  private weak var guardedWindow: UIWindow?
  private weak var originalSuperlayer: CALayer?
  private var recordingCover: UIView?
  private var watchdog: Timer?

  init(messenger: FlutterBinaryMessenger) {
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
        result(self?.isBeingCaptured ?? false)
      case "terminate":
        self?.terminate()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let nc = NotificationCenter.default
    nc.addObserver(
      self, selector: #selector(didTakeScreenshot),
      name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    nc.addObserver(
      self, selector: #selector(captureStateChanged),
      name: UIScreen.capturedDidChangeNotification, object: nil)
    nc.addObserver(
      self, selector: #selector(reapplyGuard),
      name: UIApplication.didBecomeActiveNotification, object: nil)
    nc.addObserver(
      self, selector: #selector(reapplyGuard),
      name: UIWindow.didBecomeKeyNotification, object: nil)
    nc.addObserver(
      self, selector: #selector(reapplyGuard),
      name: UIScene.didActivateNotification, object: nil)
  }

  deinit {
    watchdog?.invalidate()
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - Lifecycle

  private func enableGuard(exitOnCapture: Bool) {
    self.exitOnCapture = exitOnCapture
    guardEnabled = true
    onMain {
      self.applySecureLayer()
      self.captureStateChanged()
      self.startWatchdog()
    }
  }

  private func disableGuard() {
    guardEnabled = false
    onMain {
      self.watchdog?.invalidate()
      self.watchdog = nil
      self.releaseSecureLayer()
      self.removeRecordingCover()
    }
  }

  @objc private func reapplyGuard() {
    guard guardEnabled else { return }
    onMain {
      self.applySecureLayer()
      self.captureStateChanged()
    }
  }

  // The window hierarchy is rebuilt on scene restore, rotation and modal
  // presentation, any of which can drop the secure layer, so re-assert it and
  // re-check the capture flag on a short timer for as long as the guard is on.
  private func startWatchdog() {
    watchdog?.invalidate()
    watchdog = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      guard let self = self, self.guardEnabled else { return }
      self.applySecureLayer()
      self.captureStateChanged()
    }
  }

  // MARK: - Secure layer

  private var keyWindow: UIWindow? {
    let windows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
    return windows.first { $0.isKeyWindow } ?? windows.first
  }

  // The secure canvas is the last sublayer from iOS 17 on and the first below
  // it; picking the wrong one silently leaves the capture unprotected.
  private var secureCanvas: CALayer? {
    if #available(iOS 17.0, *) {
      return secureField.layer.sublayers?.last
    }
    return secureField.layer.sublayers?.first
  }

  private func applySecureLayer() {
    guard guardEnabled, let window = keyWindow else { return }
    // Reparenting a window whose layer is detached would blank the app.
    guard let superlayer = window.layer.superlayer else { return }
    if guardedWindow === window, secureField.layer.superlayer != nil,
      window.layer.superlayer === secureCanvas {
      return
    }
    releaseSecureLayer()

    secureField.isUserInteractionEnabled = false
    secureField.isSecureTextEntry = true
    secureField.translatesAutoresizingMaskIntoConstraints = false
    window.addSubview(secureField)
    secureField.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
    secureField.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true

    superlayer.addSublayer(secureField.layer)
    guard let canvas = secureCanvas else {
      secureField.layer.removeFromSuperlayer()
      secureField.removeFromSuperview()
      return
    }
    canvas.addSublayer(window.layer)
    originalSuperlayer = superlayer
    guardedWindow = window
  }

  private func releaseSecureLayer() {
    if let window = guardedWindow, let superlayer = originalSuperlayer {
      window.layer.removeFromSuperlayer()
      superlayer.addSublayer(window.layer)
    }
    secureField.layer.removeFromSuperlayer()
    secureField.removeFromSuperview()
    secureField.isSecureTextEntry = false
    guardedWindow = nil
    originalSuperlayer = nil
  }

  // MARK: - Detection

  private var isBeingCaptured: Bool {
    if UIScreen.main.isCaptured { return true }
    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .contains { $0.screen.isCaptured }
  }

  @objc private func didTakeScreenshot() {
    guard guardEnabled else { return }
    channel.invokeMethod("onScreenshot", arguments: nil)
    punish("screenshot")
  }

  @objc private func captureStateChanged() {
    let captured = isBeingCaptured
    guard guardEnabled else { return }
    channel.invokeMethod("onScreenRecording", arguments: captured)
    if captured {
      showRecordingCover()
      punish("screenRecording")
    } else {
      removeRecordingCover()
    }
  }

  private func showRecordingCover() {
    guard recordingCover == nil, let window = keyWindow else { return }
    let cover = UIView(frame: window.bounds)
    cover.backgroundColor = .black
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(cover)
    window.bringSubviewToFront(cover)
    recordingCover = cover
  }

  private func removeRecordingCover() {
    recordingCover?.removeFromSuperview()
    recordingCover = nil
  }

  // MARK: - Enforcement

  private func punish(_ reason: String) {
    channel.invokeMethod("onViolation", arguments: reason)
    guard exitOnCapture else { return }
    terminate()
  }

  // The delay is only long enough for the pending channel messages to reach
  // Dart; Apple offers no supported way to quit, so the process is killed.
  private func terminate() {
    guard !terminating else { return }
    terminating = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      exit(0)
    }
  }

  private func onMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
      block()
    } else {
      DispatchQueue.main.async(execute: block)
    }
  }
}
