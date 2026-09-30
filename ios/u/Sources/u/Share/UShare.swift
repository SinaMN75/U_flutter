// Shared by ios/ and macos/: keep the two copies identical.
import Foundation
#if os(iOS)
import Flutter
import LinkPresentation
import UIKit
#else
import AppKit
import FlutterMacOS
#endif

/// Native side of UShare ("u/share" + "u/share/received"): the share sheet with its outcome,
/// direct shares, and files other apps open with this one (routed here by UPlugin).
final class UShareHandler: NSObject, FlutterStreamHandler {
    private let channel: FlutterMethodChannel
    private let events: FlutterEventChannel
    private var sink: FlutterEventSink?
    private var queued: [[String: Any]] = []
    private var initial: [String: Any]?
    private var initialAsked = false
    private var pendingResult: FlutterResult?

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "u/share", binaryMessenger: messenger)
        events = FlutterEventChannel(name: "u/share/received", binaryMessenger: messenger)
        super.init()
        channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
        events.setStreamHandler(self)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "share": share(args, result: result)
        case "shareTo": shareTo(args, result: result)
        case "canShareTo": result(canShareTo(args["target"] as? String ?? ""))
        case "initialShare":
            initialAsked = true
            result(initial)
        default: result(FlutterMethodNotImplemented)
        }
    }

    private func finish(_ value: [String: Any?]) {
        pendingResult?(value)
        pendingResult = nil
    }

    // MARK: - Share sheet

    private func share(_ args: [String: Any], result: @escaping FlutterResult) {
        let text = args["text"] as? String
        let url = (args["url"] as? String).flatMap(URL.init(string:))
        let files = (args["files"] as? [[String: Any]] ?? []).compactMap { ($0["path"] as? String).map { URL(fileURLWithPath: $0) } }
        let origin = args["origin"] as? [Double]
        finish(["status": "dismissed"])
        #if os(iOS)
        guard let top = ULaunchHandler.topViewController() else { return result(["status": "unavailable"]) }
        var items: [Any] = []
        if text != nil || url != nil { items.append(UShareTextItem(text: text, url: url, subject: args["subject"] as? String, title: args["title"] as? String)) }
        if let url = url { items.append(url) }
        items.append(contentsOf: files)
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            // Required on iPad, otherwise UIKit raises an exception.
            popover.sourceView = top.view
            if let o = origin, o.count == 4 {
                popover.sourceRect = CGRect(x: o[0], y: o[1], width: max(o[2], 1), height: max(o[3], 1))
            } else {
                popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }
        pendingResult = result
        controller.completionWithItemsHandler = { [weak self] type, completed, _, _ in
            self?.finish(completed ? ["status": "success", "target": type?.rawValue] : ["status": "dismissed"])
        }
        top.present(controller, animated: true)
        #else
        guard let view = NSApp.keyWindow?.contentView ?? NSApp.windows.first?.contentView else { return result(["status": "unavailable"]) }
        var items: [Any] = []
        let joined = [text, url?.absoluteString].compactMap { $0 }.joined(separator: "\n")
        if !joined.isEmpty { items.append(joined) }
        items.append(contentsOf: files)
        let picker = NSSharingServicePicker(items: items)
        picker.delegate = self
        var rect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        if let o = origin, o.count == 4 {
            // Flutter measures from the top-left; AppKit views (unless flipped) from the bottom-left.
            let y = view.isFlipped ? o[1] : view.bounds.height - o[1] - o[3]
            rect = CGRect(x: o[0], y: y, width: max(o[2], 1), height: max(o[3], 1))
        }
        pendingResult = result
        picker.show(relativeTo: rect, of: view, preferredEdge: .minY)
        #endif
    }

    // MARK: - Direct shares

    private func shareTo(_ args: [String: Any], result: @escaping FlutterResult) {
        let target = args["target"] as? String ?? ""
        let text = args["text"] as? String ?? ""
        let hasFiles = !(args["files"] as? [Any] ?? []).isEmpty
        #if os(iOS)
        // Apps expose text-only URL schemes; files always go through the sheet (Dart falls back).
        guard !hasFiles, let scheme = Self.textScheme(target, text), let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) else {
            return result(["status": "unavailable"])
        }
        UIApplication.shared.open(url, options: [:]) { result(["status": $0 ? "success" : "unavailable", "target": target]) }
        #else
        let name: NSSharingService.Name? = target == "email" ? .composeEmail : (target == "sms" ? .composeMessage : nil)
        guard let serviceName = name, let service = NSSharingService(named: serviceName) else { return result(["status": "unavailable"]) }
        let items: [Any] = [text] + (args["files"] as? [[String: Any]] ?? []).compactMap { ($0["path"] as? String).map { URL(fileURLWithPath: $0) } }
        guard service.canPerform(withItems: items) else { return result(["status": "unavailable"]) }
        service.perform(withItems: items)
        result(["status": "success", "target": target])
        #endif
    }

    private func canShareTo(_ target: String) -> Bool {
        #if os(iOS)
        if target == "email" || target == "sms" { return true }
        guard let scheme = Self.textScheme(target, ""), let url = URL(string: scheme) else { return false }
        return UIApplication.shared.canOpenURL(url)
        #else
        return target == "email" || target == "sms"
        #endif
    }

    #if os(iOS)
    // Needs the scheme in LSApplicationQueriesSchemes (u:app adds whatsapp and tg).
    private static func textScheme(_ target: String, _ text: String) -> String? {
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        switch target {
        case "whatsapp": return "whatsapp://send?text=\(encoded)"
        case "telegram": return "tg://msg?text=\(encoded)"
        case "email": return "mailto:?body=\(encoded)"
        case "sms": return "sms:&body=\(encoded)"
        default: return nil
        }
    }
    #endif

    // MARK: - Receiving (called by UPlugin)

    func receive(files urls: [URL]) {
        let copied = urls.compactMap(copyIn)
        guard !copied.isEmpty else { return }
        let share: [String: Any] = ["files": copied]
        if !initialAsked && initial == nil && sink == nil {
            initial = share
        } else if let sink = sink {
            sink(share)
        } else {
            queued.append(share)
        }
    }

    // Files opened from elsewhere may be security-scoped and vanish from Inbox: copy them in.
    private func copyIn(_ url: URL) -> [String: Any]? {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("u_received/\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let target = dir.appendingPathComponent(url.lastPathComponent)
            try FileManager.default.copyItem(at: url, to: target)
            return ["path": target.path, "name": url.lastPathComponent]
        } catch {
            return nil
        }
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        queued.forEach { events($0) }
        queued.removeAll()
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }
}

#if os(iOS)
/// Text with a subject for mail targets and a rich preview (title, link) at the top of the sheet.
final class UShareTextItem: NSObject, UIActivityItemSource {
    private let text: String?
    private let url: URL?
    private let subject: String?
    private let title: String?

    init(text: String?, url: URL?, subject: String?, title: String?) {
        self.text = text
        self.url = url
        self.subject = subject
        self.title = title
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any { text ?? "" }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? { text }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String { subject ?? "" }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title ?? subject ?? text
        if let url = url {
            metadata.originalURL = url
            metadata.url = url
        }
        return metadata
    }
}
#else
extension UShareHandler: NSSharingServicePickerDelegate {
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
        finish(service == nil ? ["status": "dismissed"] : ["status": "shown", "target": service?.title])
    }
}
#endif
