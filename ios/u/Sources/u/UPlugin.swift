import Flutter
import UIKit
import UserNotifications

public final class UPlugin: NSObject, FlutterPlugin {
    private var screenGuard: ScreenGuardHandler?
    private var media: UMediaHandler?
    private var camera: UCameraHandler?
    private var ar: UArHandler?
    private var files: UFilesHandler?
    private var device: UDeviceHandler?
    private var launch: ULaunchHandler?
    private var share: UShareHandler?
    private var location: ULocationHandler?
    private var notify: UNotifyHandler?

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
        instance.device = UDeviceHandler(
            messenger: registrar.messenger()
        )
        instance.launch = ULaunchHandler(messenger: registrar.messenger())
        instance.share = UShareHandler(messenger: registrar.messenger())
        instance.location = ULocationHandler(messenger: registrar.messenger())
        instance.notify = UNotifyHandler(messenger: registrar.messenger())
        registrar.addApplicationDelegate(instance)
        if #available(iOS 13.0, *) {
            registrar.addSceneDelegate(instance)
        }
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

// MARK: - Incoming URLs: deep links go to ULaunch, files ("Open with") to UShare.

extension UPlugin {
    fileprivate func route(_ url: URL) -> Bool {
        if url.isFileURL {
            share?.receive(files: [url])
        } else {
            launch?.receive(url)
        }
        return true
    }

    @objc(application:openURL:options:)
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        route(url)
    }

    @objc(application:continueUserActivity:restorationHandler:)
    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]) -> Void) -> Bool {
        guard let url = userActivity.webpageURL else { return false }
        return route(url)
    }
}

// MARK: - Notifications forwarded by FlutterAppDelegate when it owns the notification-center delegate.
// Only our notifications (carrying u_id) are completed here, so no other plugin's handler is called twice.

extension UPlugin {
    @objc(userNotificationCenter:willPresentNotification:withCompletionHandler:)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard let notify = notify, !notify.isDelegate, UNotifyHandler.isOurs(notification) else { return }
        notify.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
    }

    @objc(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let notify = notify, !notify.isDelegate, UNotifyHandler.isOurs(response.notification) else { return }
        notify.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }
}

// Apps on the UIScene lifecycle deliver links here instead of the app delegate.
@available(iOS 13.0, *)
extension UPlugin: FlutterSceneLifeCycleDelegate {
    @objc(scene:willConnectToSession:options:)
    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions?) -> Bool {
        connectionOptions?.urlContexts.forEach { _ = route($0.url) }
        connectionOptions?.userActivities.forEach { activity in
            if let url = activity.webpageURL { _ = route(url) }
        }
        return false
    }

    @objc(scene:openURLContexts:)
    public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
        URLContexts.forEach { _ = route($0.url) }
        return !URLContexts.isEmpty
    }

    @objc(scene:continueUserActivity:)
    public func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> Bool {
        guard let url = userActivity.webpageURL else { return false }
        return route(url)
    }
}
