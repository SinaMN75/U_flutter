// Shared by ios/ and macos/: keep the two copies identical.
import AuthenticationServices
import Foundation
import StoreKit
#if os(iOS)
import Flutter
import MessageUI
import SafariServices
import UIKit
import UniformTypeIdentifiers
#else
import AppKit
import FlutterMacOS
#endif

/// Native side of ULaunch ("u/launch" + "u/launch/events"): opening URLs and apps, settings,
/// compose screens, store pages and reviews, OAuth, and deep links handed over by UPlugin.
final class ULaunchHandler: NSObject, FlutterStreamHandler, ASWebAuthenticationPresentationContextProviding {
    private let channel: FlutterMethodChannel
    private let events: FlutterEventChannel
    private var sink: FlutterEventSink?
    private var pending: [[String: Any]] = []
    private var initialLink: String?
    private var initialAsked = false
    private var authSession: ASWebAuthenticationSession?
    private var composeResult: FlutterResult?
    #if os(iOS)
    private weak var safari: SFSafariViewController?
    #endif

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "u/launch", binaryMessenger: messenger)
        events = FlutterEventChannel(name: "u/launch/events", binaryMessenger: messenger)
        super.init()
        channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
        events.setStreamHandler(self)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "open": open(args, result: result)
        case "canOpen": result(canOpen(args["url"] as? String ?? ""))
        case "isInstalled": result(isInstalled(args["id"] as? String ?? ""))
        case "openApp": openApp(args["id"] as? String ?? "", result: result)
        case "openSettings": result(openSettings(args["page"] as? String ?? "app"))
        case "closeInApp": result(closeInApp())
        case "email": email(args, result: result)
        case "sms": sms(args, result: result)
        case "openStore": result(openStore(args["appId"] as? String, review: args["review"] as? Bool ?? false))
        case "requestReview": result(requestReview())
        case "authenticate": authenticate(args, result: result)
        case "initialLink":
            initialAsked = true
            result(initialLink)
        default: result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Opening

    private func open(_ args: [String: Any], result: @escaping FlutterResult) {
        guard let raw = args["url"] as? String, let url = URL(string: raw) else { return result(false) }
        let mode = args["mode"] as? String ?? "platformDefault"
        #if os(iOS)
        let web = url.scheme == "http" || url.scheme == "https"
        // SFSafariViewController throws for anything that is not http(s).
        if mode == "inApp", web, let top = Self.topViewController() {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = args["readerMode"] as? Bool ?? false
            config.barCollapsingEnabled = true
            let controller = SFSafariViewController(url: url, configuration: config)
            if let color = args["toolbarColor"] as? Int { controller.preferredBarTintColor = Self.color(color) }
            if let color = args["controlColor"] as? Int { controller.preferredControlTintColor = Self.color(color) }
            controller.delegate = self
            controller.modalPresentationStyle = .pageSheet
            safari = controller
            top.present(controller, animated: true)
            return result(true)
        }
        let options: [UIApplication.OpenExternalURLOptionsKey: Any] = mode == "nonBrowser" ? [.universalLinksOnly: true] : [:]
        UIApplication.shared.open(url, options: options) { result($0) }
        #else
        result(NSWorkspace.shared.open(url))
        #endif
    }

    private func canOpen(_ raw: String) -> Bool {
        guard let url = URL(string: raw) else { return false }
        #if os(iOS)
        return UIApplication.shared.canOpenURL(url)
        #else
        return NSWorkspace.shared.urlForApplication(toOpen: url) != nil
        #endif
    }

    // iOS: a URL scheme (needs LSApplicationQueriesSchemes); macOS: a bundle identifier.
    private func isInstalled(_ id: String) -> Bool {
        #if os(iOS)
        return canOpen(id.contains("://") ? id : "\(id)://")
        #else
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) != nil
        #endif
    }

    private func openApp(_ id: String, result: @escaping FlutterResult) {
        #if os(iOS)
        guard let url = URL(string: id.contains("://") ? id : "\(id)://") else { return result(false) }
        UIApplication.shared.open(url, options: [:]) { result($0) }
        #else
        guard let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else { return result(false) }
        NSWorkspace.shared.openApplication(at: app, configuration: NSWorkspace.OpenConfiguration()) { running, _ in
            DispatchQueue.main.async { result(running != nil) }
        }
        #endif
    }

    private func closeInApp() -> Bool {
        #if os(iOS)
        guard let controller = safari else { return false }
        controller.dismiss(animated: true)
        return true
        #else
        return false
        #endif
    }

    // MARK: - Settings

    private func openSettings(_ page: String) -> Bool {
        #if os(iOS)
        var target = UIApplication.openSettingsURLString
        if page == "notifications" || page == "notificationChannel", #available(iOS 16.0, *) { target = UIApplication.openNotificationSettingsURLString }
        guard let url = URL(string: target) else { return false }
        UIApplication.shared.open(url)
        return true
        #else
        let pane: String
        switch page {
        case "notifications", "notificationChannel": pane = "com.apple.preference.notifications"
        case "location": pane = "com.apple.preference.security?Privacy_LocationServices"
        case "wifi", "dataUsage", "vpn", "airplaneMode": pane = "com.apple.preference.network"
        case "bluetooth": pane = "com.apple.preferences.Bluetooth"
        case "battery": pane = "com.apple.preference.battery"
        case "display": pane = "com.apple.preference.displays"
        case "sound": pane = "com.apple.preference.sound"
        case "dateTime": pane = "com.apple.preference.datetime"
        case "language": pane = "com.apple.Localization"
        case "accessibility": pane = "com.apple.preference.universalaccess"
        case "allFilesAccess": pane = "com.apple.preference.security?Privacy_AllFiles"
        default: pane = "com.apple.preference.security"
        }
        guard let url = URL(string: "x-apple.systempreferences:\(pane)") else { return false }
        return NSWorkspace.shared.open(url)
        #endif
    }

    // MARK: - Compose

    private func email(_ args: [String: Any], result: @escaping FlutterResult) {
        let to = args["to"] as? [String] ?? []
        let attachments = (args["attachments"] as? [String] ?? []).map { URL(fileURLWithPath: $0) }
        #if os(iOS)
        if MFMailComposeViewController.canSendMail(), let top = Self.topViewController() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(to)
            mail.setCcRecipients(args["cc"] as? [String] ?? [])
            mail.setBccRecipients(args["bcc"] as? [String] ?? [])
            if let subject = args["subject"] as? String { mail.setSubject(subject) }
            if let body = args["body"] as? String { mail.setMessageBody(body, isHTML: args["html"] as? Bool ?? false) }
            for file in attachments {
                if let data = try? Data(contentsOf: file) { mail.addAttachmentData(data, mimeType: Self.mime(file), fileName: file.lastPathComponent) }
            }
            composeResult?("cancelled")
            composeResult = result
            top.present(mail, animated: true)
            return
        }
        #else
        if let service = NSSharingService(named: .composeEmail) {
            service.recipients = to
            service.subject = args["subject"] as? String
            let items: [Any] = [args["body"] as? String ?? ""] + attachments
            if service.canPerform(withItems: items) {
                service.perform(withItems: items)
                return result("opened")
            }
        }
        #endif
        openFallback(args["mailto"] as? String, result: result)
    }

    private func sms(_ args: [String: Any], result: @escaping FlutterResult) {
        let to = args["to"] as? [String] ?? []
        #if os(iOS)
        if MFMessageComposeViewController.canSendText(), let top = Self.topViewController() {
            let message = MFMessageComposeViewController()
            message.messageComposeDelegate = self
            message.recipients = to
            message.body = args["body"] as? String
            if MFMessageComposeViewController.canSendAttachments() {
                for path in args["attachments"] as? [String] ?? [] {
                    message.addAttachmentURL(URL(fileURLWithPath: path), withAlternateFilename: nil)
                }
            }
            composeResult?("cancelled")
            composeResult = result
            top.present(message, animated: true)
            return
        }
        #else
        if let service = NSSharingService(named: .composeMessage) {
            service.recipients = to
            let items: [Any] = [args["body"] as? String ?? ""]
            if service.canPerform(withItems: items) {
                service.perform(withItems: items)
                return result("opened")
            }
        }
        #endif
        openFallback(args["url"] as? String, result: result)
    }

    private func openFallback(_ raw: String?, result: @escaping FlutterResult) {
        guard let raw = raw, let url = URL(string: raw) else { return result("unavailable") }
        #if os(iOS)
        UIApplication.shared.open(url, options: [:]) { result($0 ? "opened" : "unavailable") }
        #else
        result(NSWorkspace.shared.open(url) ? "opened" : "unavailable")
        #endif
    }

    // MARK: - Stores

    // Apple stores need the numeric App Store id.
    private func openStore(_ appId: String?, review: Bool) -> Bool {
        guard let appId = appId, !appId.isEmpty else { return false }
        #if os(iOS)
        let raw = "itms-apps://itunes.apple.com/app/id\(appId)\(review ? "?action=write-review" : "")"
        guard let url = URL(string: raw) else { return false }
        UIApplication.shared.open(url)
        return true
        #else
        let raw = "macappstore://apps.apple.com/app/id\(appId)\(review ? "?action=write-review" : "")"
        guard let url = URL(string: raw) else { return false }
        return NSWorkspace.shared.open(url)
        #endif
    }

    // The system decides whether the prompt actually appears (at most 3 times a year, never in TestFlight).
    private func requestReview() -> Bool {
        #if os(iOS)
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return false }
        if #available(iOS 16.0, *) {
            AppStore.requestReview(in: scene)
        } else if #available(iOS 14.0, *) {
            SKStoreReviewController.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview()
        }
        return true
        #else
        if #available(macOS 13.0, *), let controller = NSApp.keyWindow?.contentViewController {
            AppStore.requestReview(in: controller)
        } else {
            SKStoreReviewController.requestReview()
        }
        return true
        #endif
    }

    // MARK: - OAuth

    private func authenticate(_ args: [String: Any], result: @escaping FlutterResult) {
        guard let raw = args["url"] as? String, let url = URL(string: raw), let scheme = args["scheme"] as? String else { return result(nil) }
        authSession?.cancel()
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme) { [weak self] callback, _ in
            DispatchQueue.main.async {
                self?.authSession = nil
                result(callback?.absoluteString)
            }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = args["ephemeral"] as? Bool ?? false
        authSession = session
        if !session.start() {
            authSession = nil
            result(nil)
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(iOS)
        return Self.keyWindow() ?? ASPresentationAnchor()
        #else
        return NSApp.keyWindow ?? NSApp.windows.first ?? ASPresentationAnchor()
        #endif
    }

    // MARK: - Deep links (called by UPlugin)

    func receive(_ url: URL) {
        let raw = url.absoluteString
        if !initialAsked && initialLink == nil && sink == nil {
            initialLink = raw
            return
        }
        emit(["type": "link", "url": raw])
    }

    private func emit(_ event: [String: Any]) {
        if let sink = sink { sink(event) } else { pending.append(event) }
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        pending.forEach { events($0) }
        pending.removeAll()
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }

    // MARK: - Helpers

    #if os(iOS)
    static func keyWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.flatMap { $0.windows }.first { $0.isKeyWindow } ?? scenes.first?.windows.first
    }

    static func topViewController() -> UIViewController? {
        var top = keyWindow()?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }

    static func color(_ argb: Int) -> UIColor {
        UIColor(red: CGFloat((argb >> 16) & 0xFF) / 255, green: CGFloat((argb >> 8) & 0xFF) / 255, blue: CGFloat(argb & 0xFF) / 255, alpha: CGFloat((argb >> 24) & 0xFF) / 255)
    }

    static func mime(_ url: URL) -> String {
        if #available(iOS 14.0, *), let type = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType { return type }
        return "application/octet-stream"
    }
    #endif
}

#if os(iOS)
extension ULaunchHandler: SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        emit(["type": "closed"])
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
        let value: String
        switch result {
        case .sent: value = "sent"
        case .saved: value = "saved"
        case .cancelled: value = "cancelled"
        default: value = "failed"
        }
        composeResult?(value)
        composeResult = nil
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
        let value: String
        switch result {
        case .sent: value = "sent"
        case .cancelled: value = "cancelled"
        default: value = "failed"
        }
        composeResult?(value)
        composeResult = nil
    }
}
#endif
