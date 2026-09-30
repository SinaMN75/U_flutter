// Shared by ios/ and macos/: keep the two copies identical.
import Foundation
import UserNotifications
#if os(iOS)
import Flutter
import UIKit
#else
import AppKit
import FlutterMacOS
#endif

/// Native side of UNotification ("u/notify" + "u/notify/events") on UserNotifications.
final class UNotifyHandler: NSObject, UNUserNotificationCenterDelegate {
    private let channel: FlutterMethodChannel
    private let events: FlutterEventChannel
    private let center = UNUserNotificationCenter.current()
    private var sink: FlutterEventSink?
    private var queued: [[String: Any?]] = []
    private var launchEvent: [String: Any?]?
    private var launchAsked = false
    private var showInForeground = true
    /// True when no one else owns the notification-center delegate and we took it.
    private(set) var isDelegate = false

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "u/notify", binaryMessenger: messenger)
        events = FlutterEventChannel(name: "u/notify/events", binaryMessenger: messenger)
        super.init()
        channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
        events.setStreamHandler(UStreamHandler(listen: { [weak self] _, sink in
            self?.sink = sink
            self?.queued.forEach { sink($0) }
            self?.queued.removeAll()
            return nil
        }, cancel: { [weak self] in self?.sink = nil }))
        // Taps that launched the app arrive right after launch: the delegate must be set now.
        if center.delegate == nil {
            center.delegate = self
            isDelegate = true
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "init":
            showInForeground = args["foreground"] as? Bool ?? true
            result(nil)
        case "permission": permission(result)
        case "requestPermission": requestPermission(args, result: result)
        case "show": add(args, trigger: nil, result: result)
        case "schedule": schedule(args, result: result)
        case "cancel":
            cancel(args["id"] as? Int ?? 0) { result(nil) }
        case "cancelAll":
            center.removeAllPendingNotificationRequests()
            center.removeAllDeliveredNotifications()
            result(nil)
        case "cancelGroup":
            let group = args["group"] as? String
            center.getDeliveredNotifications { [weak self] delivered in
                let ids = delivered.filter { $0.request.content.threadIdentifier == group }.map { $0.request.identifier }
                self?.center.removeDeliveredNotifications(withIdentifiers: ids)
                DispatchQueue.main.async { result(nil) }
            }
        case "pending": pending(result)
        case "active": active(result)
        case "setBadge": result(setBadge(args["count"] as? Int ?? 0))
        case "launchEvent":
            launchAsked = true
            result(launchEvent)
        case "createChannel", "deleteChannel", "createChannelGroup": result(nil)
        case "channels": result([String]())
        default: result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Permission

    private func permission(_ result: @escaping FlutterResult) {
        center.getNotificationSettings { settings in
            var status = "notDetermined"
            switch settings.authorizationStatus {
            case .authorized: status = "granted"
            case .denied: status = "denied"
            case .provisional: status = "provisional"
            case .notDetermined: status = "notDetermined"
            default: status = "ephemeral"
            }
            var map: [String: Any] = [
                "status": status,
                "alert": settings.alertSetting == .enabled,
                "sound": settings.soundSetting == .enabled,
                "badge": settings.badgeSetting == .enabled,
                "critical": settings.criticalAlertSetting == .enabled,
                "exactAlarms": true,
                "fullScreen": false,
            ]
            if #available(iOS 15.0, macOS 12.0, *) { map["timeSensitive"] = settings.timeSensitiveSetting == .enabled }
            DispatchQueue.main.async { result(map) }
        }
    }

    private func requestPermission(_ args: [String: Any], result: @escaping FlutterResult) {
        var options: UNAuthorizationOptions = [.alert, .sound, .badge]
        if args["provisional"] as? Bool == true { options.insert(.provisional) }
        // Critical alerts need Apple's entitlement; without it iOS ignores the option.
        if args["critical"] as? Bool == true { options.insert(.criticalAlert) }
        center.requestAuthorization(options: options) { [weak self] _, _ in
            DispatchQueue.main.async { self?.permission(result) ?? result(nil) }
        }
    }

    // MARK: - Content

    private func content(_ r: [String: Any]) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let id = r["id"] as? Int ?? 0
        content.title = r["title"] as? String ?? ""
        content.subtitle = r["subtitle"] as? String ?? ""
        let lines = r["lines"] as? [String] ?? []
        content.body = (r["body"] as? String) ?? lines.joined(separator: "\n")
        if let progress = r["progress"] as? [String: Any], content.subtitle.isEmpty, let max = progress["max"] as? Int, max > 0, progress["indeterminate"] as? Bool != true {
            content.subtitle = "\((progress["value"] as? Int ?? 0) * 100 / max)%"
        }
        var info: [String: Any] = ["u_id": id]
        if let payload = r["payload"] as? String { info["u_payload"] = payload }
        content.userInfo = info
        if let group = r["group"] as? String { content.threadIdentifier = group }
        if let badge = r["badge"] as? Int { content.badge = NSNumber(value: badge) }
        let interruption = r["interruption"] as? String
        if r["silent"] as? Bool != true {
            if let name = r["sound"] as? String {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(name))
            } else {
                #if os(iOS)
                content.sound = interruption == "critical" ? .defaultCritical : .default
                #else
                content.sound = .default
                #endif
            }
        }
        if #available(iOS 15.0, macOS 12.0, *) {
            switch interruption {
            case "passive": content.interruptionLevel = .passive
            case "timeSensitive": content.interruptionLevel = .timeSensitive
            case "critical": content.interruptionLevel = .critical
            default: content.interruptionLevel = .active
            }
            if let relevance = r["relevance"] as? Double { content.relevanceScore = relevance }
        }
        // Attachments move the file into the notification store: attach a copy.
        content.attachments = ["image", "largeIcon"].compactMap { key in
            guard let path = r[key] as? String, FileManager.default.fileExists(atPath: path) else { return nil }
            let copy = FileManager.default.temporaryDirectory.appendingPathComponent("u_notify_\(UUID().uuidString)_\((path as NSString).lastPathComponent)")
            guard (try? FileManager.default.copyItem(atPath: path, toPath: copy.path)) != nil else { return nil }
            return try? UNNotificationAttachment(identifier: key, url: copy, options: nil)
        }.prefix(1).map { $0 }
        return content
    }

    // Every notification gets a category with customDismissAction so dismissals are reported;
    // requests with buttons get their own category.
    private func withCategory(_ r: [String: Any], _ done: @escaping (String) -> Void) {
        let actions = r["actions"] as? [[String: Any]] ?? []
        let signature = actions.map { "\($0["id"] ?? "")|\($0["title"] ?? "")|\($0["input"] ?? "")" }.joined(separator: ";")
        let id = actions.isEmpty ? "u_default" : "u_" + String(Self.stableHash(signature), radix: 36)
        let built: [UNNotificationAction] = actions.map { a in
            var options: UNNotificationActionOptions = []
            if a["foreground"] as? Bool == true { options.insert(.foreground) }
            if a["destructive"] as? Bool == true { options.insert(.destructive) }
            if a["authenticationRequired"] as? Bool == true { options.insert(.authenticationRequired) }
            let identifier = a["id"] as? String ?? ""
            let title = a["title"] as? String ?? identifier
            if a["input"] as? Bool == true {
                return UNTextInputNotificationAction(identifier: identifier, title: title, options: options, textInputButtonTitle: a["inputButton"] as? String ?? title, textInputPlaceholder: a["inputPlaceholder"] as? String ?? "")
            }
            return UNNotificationAction(identifier: identifier, title: title, options: options)
        }
        let category = UNNotificationCategory(identifier: id, actions: built, intentIdentifiers: [], options: [.customDismissAction])
        center.getNotificationCategories { [weak self] existing in
            guard let self = self else { return }
            self.center.setNotificationCategories(existing.filter { $0.identifier != id }.union([category]))
            DispatchQueue.main.async { done(id) }
        }
    }

    private func add(_ r: [String: Any], trigger: UNNotificationTrigger?, identifier: String? = nil, result: @escaping FlutterResult) {
        withCategory(r) { [weak self] category in
            guard let self = self else { return result(false) }
            let content = self.content(r)
            content.categoryIdentifier = category
            let request = UNNotificationRequest(identifier: identifier ?? "\(r["id"] as? Int ?? 0)", content: content, trigger: trigger)
            self.center.add(request) { error in DispatchQueue.main.async { result(error == nil) } }
        }
    }

    // A batch of dates shares one id: "42", "42#1", "42#2", …
    private static func matches(_ identifier: String, _ id: Int) -> Bool { identifier == "\(id)" || identifier.hasPrefix("\(id)#") }

    private func cancel(_ id: Int, done: @escaping () -> Void) {
        center.getPendingNotificationRequests { [weak self] pending in
            guard let self = self else { return }
            let ids = pending.map { $0.identifier }.filter { Self.matches($0, id) }
            self.center.removePendingNotificationRequests(withIdentifiers: ids + ["\(id)"])
            self.center.removeDeliveredNotifications(withIdentifiers: ["\(id)"])
            DispatchQueue.main.async { done() }
        }
    }

    // Concrete dates computed in Dart (month-end repeats that a repeating trigger would skip).
    private func scheduleTimes(_ request: [String: Any], _ times: [Int], result: @escaping FlutterResult) {
        let id = request["id"] as? Int ?? 0
        cancel(id) { [weak self] in
            guard let self = self else { return result(false) }
            let calendar = Calendar.current
            var remaining = times.count
            var ok = true
            for (index, ms) in times.enumerated() {
                let date = Date(timeIntervalSince1970: Double(ms) / 1000)
                let components = calendar.dateComponents([.era, .year, .month, .day, .hour, .minute, .second], from: date)
                self.add(request, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false), identifier: index == 0 ? "\(id)" : "\(id)#\(index)") { value in
                    ok = ok && (value as? Bool ?? false)
                    remaining -= 1
                    if remaining == 0 { result(ok) }
                }
            }
            if times.isEmpty { result(false) }
        }
    }

    private func schedule(_ args: [String: Any], result: @escaping FlutterResult) {
        if let request = args["request"] as? [String: Any], let times = args["times"] as? [Int] { return scheduleTimes(request, times, result: result) }
        guard let request = args["request"] as? [String: Any], let atMs = args["at"] as? Int else { return result(false) }
        let at = Date(timeIntervalSince1970: Double(atMs) / 1000)
        var calendar = args["calendar"] as? String == "persian" ? Calendar(identifier: .persian) : Calendar.current
        calendar.timeZone = TimeZone.current
        let repeatMode = args["repeat"] as? String ?? "none"
        let fields: Set<Calendar.Component>
        switch repeatMode {
        case "minute":
            return add(request, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: true), result: result)
        case "hourly": fields = [.minute, .second]
        case "daily": fields = [.hour, .minute, .second]
        case "weekly": fields = [.weekday, .hour, .minute, .second]
        case "monthly": fields = [.day, .hour, .minute, .second]
        case "yearly": fields = [.month, .day, .hour, .minute, .second]
        default:
            guard at > Date() else { return result(false) }
            fields = [.era, .year, .month, .day, .hour, .minute, .second]
        }
        var components = calendar.dateComponents(fields, from: at)
        // The trigger matches in this calendar: Jalali "every 1st" stays on the 1st of each Jalali month.
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        add(request, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: repeatMode != "none"), result: result)
    }

    // String.hashValue is randomised per launch; category ids must be stable (FNV-1a).
    private static func stableHash(_ text: String) -> UInt32 {
        var hash: UInt32 = 2_166_136_261
        for byte in text.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16_777_619
        }
        return hash
    }

    // MARK: - Lists

    private static func info(_ request: UNNotificationRequest, next: Date?) -> [String: Any?]? {
        guard let id = Int(request.identifier.split(separator: "#").first ?? "") else { return nil }
        return [
            "id": id,
            "title": request.content.title,
            "body": request.content.body,
            "group": request.content.threadIdentifier.isEmpty ? nil : request.content.threadIdentifier,
            "payload": request.content.userInfo["u_payload"] as? String,
            "next": next.map { Int64($0.timeIntervalSince1970 * 1000) },
        ]
    }

    private func pending(_ result: @escaping FlutterResult) {
        center.getPendingNotificationRequests { requests in
            // One entry per id: the soonest of a batch.
            var byId: [Int: [String: Any?]] = [:]
            for r in requests {
                let next = (r.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? (r.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate()
                guard let info = Self.info(r, next: next), let id = info["id"] as? Int else { continue }
                let current = (byId[id]?["next"] as? Int64) ?? Int64.max
                if (info["next"] as? Int64 ?? Int64.max) < current || byId[id] == nil { byId[id] = info }
            }
            let list = Array(byId.values)
            DispatchQueue.main.async { result(list) }
        }
    }

    private func active(_ result: @escaping FlutterResult) {
        center.getDeliveredNotifications { delivered in
            let list = delivered.compactMap { Self.info($0.request, next: nil) }
            DispatchQueue.main.async { result(list) }
        }
    }

    private func setBadge(_ count: Int) -> Bool {
        if #available(iOS 16.0, macOS 13.0, *) {
            center.setBadgeCount(count)
            #if os(macOS)
            NSApp.dockTile.badgeLabel = count > 0 ? "\(count)" : nil
            #endif
            return true
        }
        #if os(iOS)
        UIApplication.shared.applicationIconBadgeNumber = count
        #else
        NSApp.dockTile.badgeLabel = count > 0 ? "\(count)" : nil
        #endif
        return true
    }

    // MARK: - Delegate (directly, or forwarded by UPlugin through FlutterAppDelegate)

    static func isOurs(_ notification: UNNotification) -> Bool { notification.request.content.userInfo["u_id"] != nil }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard showInForeground else { return completionHandler([]) }
        if #available(iOS 14.0, macOS 11.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let request = response.notification.request
        let info = request.content.userInfo
        var event: [String: Any?] = [
            "id": info["u_id"] as? Int ?? Int(request.identifier) ?? 0,
            "payload": info["u_payload"] as? String,
        ]
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier: event["type"] = "tap"
        case UNNotificationDismissActionIdentifier: event["type"] = "dismiss"
        default:
            event["actionId"] = response.actionIdentifier
            if let text = response as? UNTextInputNotificationResponse {
                event["type"] = "reply"
                event["input"] = text.userText
            } else {
                event["type"] = "action"
            }
        }
        if !launchAsked && launchEvent == nil && event["type"] as? String == "tap" && sink == nil { launchEvent = event }
        if let sink = sink { sink(event) } else { queued.append(event) }
        completionHandler()
    }
}
