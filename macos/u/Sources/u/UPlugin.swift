import Cocoa
import FlutterMacOS

public class UPlugin: NSObject, FlutterPlugin, FlutterAppLifecycleDelegate {
  // Native feature handlers, each owning its own method channel. Retained by
  // the plugin instance (which the registrar keeps alive).
  private var screenGuard: ScreenGuardHandler?
  private var media: UMediaHandler?
  private var camera: UCameraHandler?
  private var files: UFilesHandler?
  private var device: UDeviceHandler?
  private var launch: ULaunchHandler?
  private var share: UShareHandler?
  private var location: ULocationHandler?
  private var notify: UNotifyHandler?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "u", binaryMessenger: registrar.messenger)
    let instance = UPlugin()
    instance.screenGuard = ScreenGuardHandler(
      messenger: registrar.messenger, window: registrar.view?.window)
    instance.media = UMediaHandler(
      messenger: registrar.messenger, registry: registrar.textures)
    instance.camera = UCameraHandler(
      messenger: registrar.messenger, registry: registrar.textures)
    instance.files = UFilesHandler(messenger: registrar.messenger)
    instance.device = UDeviceHandler(messenger: registrar.messenger)
    instance.launch = ULaunchHandler(messenger: registrar.messenger)
    instance.share = UShareHandler(messenger: registrar.messenger)
    instance.location = ULocationHandler(messenger: registrar.messenger)
    instance.notify = UNotifyHandler(messenger: registrar.messenger)
    registrar.addApplicationDelegate(instance)
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

// Incoming URLs: deep links go to ULaunch, files ("Open with", drag onto the Dock icon) to UShare.
extension UPlugin {
  @objc(handleOpenURLs:)
  public func handleOpen(_ urls: [URL]) -> Bool {
    let files = urls.filter { $0.isFileURL }
    if !files.isEmpty { share?.receive(files: files) }
    urls.filter { !$0.isFileURL }.forEach { launch?.receive($0) }
    return !urls.isEmpty
  }
}
