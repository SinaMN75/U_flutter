import Cocoa
import FlutterMacOS

public class UPlugin: NSObject, FlutterPlugin {
  // Native feature handlers, each owning its own method channel. Retained by
  // the plugin instance (which the registrar keeps alive).
  private var screenGuard: ScreenGuardHandler?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "u", binaryMessenger: registrar.messenger)
    let instance = UPlugin()
    instance.screenGuard = ScreenGuardHandler(
      messenger: registrar.messenger, window: registrar.view?.window)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
