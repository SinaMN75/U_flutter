import Flutter
import UIKit

/// Native screenshot / screen-recording prevention for iOS.
///
/// Screenshots and recordings cannot be hard-blocked on iOS, so the app layer
/// is reparented into a secure `UITextField` canvas (renders blank in captures)
/// and active recordings/mirroring are covered with a black view. Screenshot
/// and recording events are forwarded to Dart as detection callbacks.
class ScreenGuardHandler {
  private let channel: FlutterMethodChannel
  private var guardEnabled = false

  // Hidden secure field whose capture-proof canvas hosts the app layer.
  private let secureField = UITextField()
  // Black cover shown while the screen is being recorded / mirrored.
  private var recordingCover: UIView?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "u/screen_guard", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "enable": self?.enableGuard(); result(nil)
      case "disable": self?.disableGuard(); result(nil)
      default: result(FlutterMethodNotImplemented)
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
  }

  private var keyWindow: UIWindow? {
    return UIApplication.shared.windows.first { $0.isKeyWindow }
      ?? UIApplication.shared.windows.first
  }

  private func enableGuard() {
    guardEnabled = true
    applySecureField()
    captureStateChanged()
  }

  private func disableGuard() {
    guardEnabled = false
    secureField.isSecureTextEntry = false
    removeRecordingCover()
  }

  @objc private func reapplyGuard() {
    if guardEnabled {
      applySecureField()
      captureStateChanged()
    }
  }

  // Reparents the key window's layer into a secure UITextField canvas so that
  // screenshots and screen recordings render the app content as blank.
  private func applySecureField() {
    guard let window = keyWindow else { return }
    secureField.isSecureTextEntry = true
    if secureField.superview == nil {
      secureField.translatesAutoresizingMaskIntoConstraints = false
      window.addSubview(secureField)
      secureField.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
      secureField.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true
      window.layer.superlayer?.addSublayer(secureField.layer)
      secureField.layer.sublayers?.first?.addSublayer(window.layer)
    }
  }

  @objc private func didTakeScreenshot() {
    if guardEnabled { channel.invokeMethod("onScreenshot", arguments: nil) }
  }

  // Screen recording / AirPlay mirroring cannot be blocked, so cover the UI.
  @objc private func captureStateChanged() {
    let captured = UIScreen.main.isCaptured
    channel.invokeMethod("onScreenRecording", arguments: captured)
    if guardEnabled && captured {
      showRecordingCover()
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
    recordingCover = cover
  }

  private func removeRecordingCover() {
    recordingCover?.removeFromSuperview()
    recordingCover = nil
  }
}
