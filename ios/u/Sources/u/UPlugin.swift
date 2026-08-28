import Flutter
import UIKit

public final class UPlugin: NSObject, FlutterPlugin {
    private var screenGuard: ScreenGuardHandler?

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
}