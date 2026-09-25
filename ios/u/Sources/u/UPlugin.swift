import Flutter
import UIKit

public final class UPlugin: NSObject, FlutterPlugin {
    private var screenGuard: ScreenGuardHandler?
    private var media: UMediaHandler?
    private var camera: UCameraHandler?
    private var ar: UArHandler?
    private var files: UFilesHandler?

    public static func register(
        with registrar: FlutterPluginRegistrar
    ) {
        let instance = UPlugin()
        let channel = FlutterMethodChannel(
            name: "u",
            binaryMessenger: registrar.messenger()
        )

        instance.screenGuard = ScreenGuardHandler(
            messenger: registrar.messenger()
        )
        instance.media = UMediaHandler(
            messenger: registrar.messenger(),
            registry: registrar.textures()
        )
        instance.camera = UCameraHandler(
            messenger: registrar.messenger(),
            registry: registrar.textures()
        )
        instance.ar = UArHandler(
            registrar: registrar
        )
        instance.files = UFilesHandler(
            messenger: registrar.messenger()
        )
        registrar.addApplicationDelegate(instance)
        registrar.addMethodCallDelegate(
            instance,
            channel: channel
        )
    }

    public func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch call.method {

        case "getPlatformVersion":
            result(
                "iOS " + UIDevice.current.systemVersion
            )

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // Wakes the background download session when iOS relaunches the app for it.
    public func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) -> Bool {
        files?.handleEventsForBackgroundURLSession(
            identifier: identifier,
            completionHandler: completionHandler
        ) ?? false
    }
}
