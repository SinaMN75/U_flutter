// Shared verbatim between ios/ and macos/ — edit both copies together.
#if os(iOS)
import Flutter
import UIKit
#else
import AppKit
import FlutterMacOS
#endif
import Foundation
import Security

/// Native side of the "u/files" channel on Apple platforms: Keychain secrets for the
/// vault master key, a background URLSession for downloads that outlive the app,
/// save-as, open/reveal, keep-awake and backup exclusion.
public final class UFilesHandler: NSObject {
    private let channel: FlutterMethodChannel

    #if os(iOS)
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var documentDelegate: UFilesDocumentDelegate?
    private var previewDelegate: UFilesPreviewDelegate?
    #endif
    private var activity: NSObjectProtocol?

    public init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "u/files", binaryMessenger: messenger)
        super.init()
        // Creating the session at launch re-attaches downloads that finished while the app was dead.
        _ = UFilesBackgroundSession.shared
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else {
                result(nil)
                return
            }
            self.handle(call, result: result)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "freeSpace":
            result(freeSpace(args["path"] as? String ?? NSHomeDirectory()))
        case "saveAs":
            saveAs(source: args["sourcePath"] as! String, fileName: args["fileName"] as! String, result: result)
        case "open":
            result(open(path: args["path"] as! String))
        case "reveal":
            result(reveal(path: args["path"] as! String))
        case "keepAwake":
            keepAwake(args["enabled"] as? Bool ?? false)
            result(nil)
        case "excludeFromBackup":
            var url = URL(fileURLWithPath: args["path"] as! String)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? url.setResourceValues(values)
            result(nil)
        case "storeSecret":
            let data = (args["secret"] as! FlutterStandardTypedData).data
            result(UFilesKeychain.store(alias: args["alias"] as! String, data: data))
        case "loadSecret":
            do {
                let data = try UFilesKeychain.load(alias: args["alias"] as! String)
                result(data.map { FlutterStandardTypedData(bytes: $0) })
            } catch {
                // Locked keychain (e.g. before first unlock): an error, never "missing".
                result(FlutterError(code: "keychain_locked", message: "\(error)", details: nil))
            }
        case "deleteSecret":
            UFilesKeychain.delete(alias: args["alias"] as! String)
            result(nil)
        case "systemSupported":
            result(true)
        case "systemEnqueue":
            result(UFilesBackgroundSession.shared.enqueue(args))
        case "systemCancel":
            UFilesBackgroundSession.shared.cancel(id: args["id"] as! String)
            result(nil)
        case "systemQuery":
            UFilesBackgroundSession.shared.query { items in result(["items": items]) }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func freeSpace(_ path: String) -> NSNumber? {
        var url = URL(fileURLWithPath: path)
        while !FileManager.default.fileExists(atPath: url.path) && url.pathComponents.count > 1 {
            url.deleteLastPathComponent()
        }
        if let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
            let capacity = values.volumeAvailableCapacityForImportantUsage {
            return NSNumber(value: capacity)
        }
        return nil
    }

    // MARK: Keep awake

    private func keepAwake(_ enabled: Bool) {
        if enabled {
            if activity == nil {
                activity = ProcessInfo.processInfo.beginActivity(
                    options: [.userInitiated, .idleSystemSleepDisabled], reason: "Downloading files")
            }
            #if os(iOS)
            // iOS grants a short grace period in the background; OS-owned downloads
            // (useSystemDownloader) are the way to keep going past it.
            if backgroundTask == .invalid {
                backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "u.downloads") { [weak self] in
                    self?.endBackgroundTask()
                }
            }
            #endif
        } else {
            if let activity { ProcessInfo.processInfo.endActivity(activity) }
            activity = nil
            #if os(iOS)
            endBackgroundTask()
            #endif
        }
    }

    #if os(iOS)
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    private func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
    #endif

    // MARK: Save as / open / reveal

    private func saveAs(source: String, fileName: String, result: @escaping FlutterResult) {
        let sourceUrl = URL(fileURLWithPath: source)
        #if os(iOS)
        // The picker exports under the source's name, so stage a copy with the real file name.
        let staged = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: staged)
        do {
            try FileManager.default.copyItem(at: sourceUrl, to: staged)
        } catch {
            result(FlutterError(code: "save_as", message: "\(error)", details: nil))
            return
        }
        guard let presenter = topViewController() else {
            result(FlutterError(code: "no_view", message: "No view controller to present from", details: nil))
            return
        }
        let picker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            picker = UIDocumentPickerViewController(forExporting: [staged], asCopy: true)
        } else {
            picker = UIDocumentPickerViewController(url: staged, in: .exportToService)
        }
        let delegate = UFilesDocumentDelegate { [weak self] url in
            try? FileManager.default.removeItem(at: staged)
            self?.documentDelegate = nil
            result(url?.path)
        }
        documentDelegate = delegate
        picker.delegate = delegate
        presenter.present(picker, animated: true)
        #else
        let panel = NSSavePanel()
        panel.nameFieldStringValue = fileName
        panel.canCreateDirectories = true
        panel.begin { response in
            guard response == .OK, let target = panel.url else {
                result(nil)
                return
            }
            do {
                if FileManager.default.fileExists(atPath: target.path) {
                    _ = try FileManager.default.replaceItemAt(target, withItemAt: sourceUrl, backupItemName: nil, options: [])
                } else {
                    try FileManager.default.copyItem(at: sourceUrl, to: target)
                }
                result(target.path)
            } catch {
                result(FlutterError(code: "save_as", message: "\(error)", details: nil))
            }
        }
        #endif
    }

    private func open(path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        #if os(iOS)
        guard let presenter = topViewController() else { return false }
        let controller = UIDocumentInteractionController(url: url)
        let delegate = UFilesPreviewDelegate(presenter: presenter)
        previewDelegate = delegate
        controller.delegate = delegate
        if controller.presentPreview(animated: true) { return true }
        return controller.presentOpenInMenu(from: presenter.view.bounds, in: presenter.view, animated: true)
        #else
        return NSWorkspace.shared.open(url)
        #endif
    }

    private func reveal(path: String) -> Bool {
        #if os(iOS)
        // Opens the Files app at the file (requires UIFileSharingEnabled for Documents).
        guard let url = URL(string: "shareddocuments://\(path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path)") else { return false }
        guard UIApplication.shared.canOpenURL(url) else { return false }
        UIApplication.shared.open(url)
        return true
        #else
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
        return true
        #endif
    }

    #if os(iOS)
    /// Relays the system's wake-up for finished background downloads.
    public func handleEventsForBackgroundURLSession(identifier: String, completionHandler: @escaping () -> Void) -> Bool {
        UFilesBackgroundSession.shared.handleEvents(identifier: identifier, completionHandler: completionHandler)
    }
    #endif
}

#if os(iOS)
private final class UFilesDocumentDelegate: NSObject, UIDocumentPickerDelegate {
    private let done: (URL?) -> Void

    init(done: @escaping (URL?) -> Void) {
        self.done = done
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        done(urls.first)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        done(nil)
    }
}

private final class UFilesPreviewDelegate: NSObject, UIDocumentInteractionControllerDelegate {
    private weak var presenter: UIViewController?

    init(presenter: UIViewController) {
        self.presenter = presenter
    }

    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        presenter ?? UIViewController()
    }
}
#endif

// MARK: - Keychain

enum UFilesKeychain {
    private static let service = "u.files.secrets"

    private static func query(_ alias: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: alias]
    }

    static func store(alias: String, data: Data) -> Bool {
        SecItemDelete(query(alias) as CFDictionary)
        var item = query(alias)
        item[kSecValueData as String] = data
        // Readable in the background after the first unlock, never synced or migrated to another device.
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
    }

    static func load(alias: String) throws -> Data? {
        var item = query(alias)
        item[kSecReturnData as String] = true
        item[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        let status = SecItemCopyMatching(item as CFDictionary, &out)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
        return out as? Data
    }

    static func delete(alias: String) {
        SecItemDelete(query(alias) as CFDictionary)
    }
}

// MARK: - Background URLSession

/// Downloads run by nsurlsessiond: they continue while the app is suspended or killed,
/// and the finished file is moved to its destination the moment the system hands it over.
final class UFilesBackgroundSession: NSObject, URLSessionDownloadDelegate {
    static let shared = UFilesBackgroundSession()

    private let destinationsKey = "u.files.system.destinations"
    private let finishedKey = "u.files.system.finished"
    private let lock = NSLock()
    private var progress: [String: (Int64, Int64)] = [:]
    private var completionHandlers: [String: () -> Void] = [:]
    private lazy var identifier = "\(Bundle.main.bundleIdentifier ?? "u").u.downloads"
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = false
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    private override init() {
        super.init()
        _ = session
    }

    private var defaults: UserDefaults { .standard }

    func enqueue(_ args: [String: Any]) -> Bool {
        guard let id = args["id"] as? String, let urlString = args["url"] as? String, let url = URL(string: urlString) else { return false }
        var request = URLRequest(url: url)
        (args["headers"] as? [String: String])?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        if args["wifiOnly"] as? Bool == true {
            request.allowsCellularAccess = false
            request.allowsExpensiveNetworkAccess = false
        }
        let destination = (args["path"] as? String)
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("u_system_downloads").appendingPathComponent(id).path
        lock.lock()
        var destinations = defaults.dictionary(forKey: destinationsKey) as? [String: String] ?? [:]
        destinations[id] = destination
        defaults.set(destinations, forKey: destinationsKey)
        lock.unlock()
        let task = session.downloadTask(with: request)
        task.taskDescription = id
        task.resume()
        return true
    }

    func cancel(id: String) {
        session.getAllTasks { tasks in
            tasks.filter { $0.taskDescription == id }.forEach { $0.cancel() }
        }
        lock.lock()
        var finished = defaults.dictionary(forKey: finishedKey) as? [String: [String: Any]] ?? [:]
        finished.removeValue(forKey: id)
        defaults.set(finished, forKey: finishedKey)
        lock.unlock()
    }

    func query(_ done: @escaping ([[String: Any]]) -> Void) {
        session.getAllTasks { [weak self] tasks in
            guard let self else { return }
            self.lock.lock()
            var items: [[String: Any]] = []
            var seen = Set<String>()
            for task in tasks {
                guard let id = task.taskDescription, task.state != .completed, task.state != .canceling else { continue }
                seen.insert(id)
                let known = self.progress[id]
                items.append([
                    "id": id,
                    "state": task.countOfBytesReceived > 0 ? "running" : "queued",
                    "received": NSNumber(value: known?.0 ?? task.countOfBytesReceived),
                    "total": NSNumber(value: known?.1 ?? task.countOfBytesExpectedToReceive),
                ])
            }
            // Outcomes recorded while the app was not running are reported until acknowledged.
            let finished = self.defaults.dictionary(forKey: self.finishedKey) as? [String: [String: Any]] ?? [:]
            for (id, item) in finished where !seen.contains(id) {
                items.append(item.merging(["id": id]) { _, new in new })
            }
            var remaining = finished
            for (id, item) in finished where (item["reported"] as? Int ?? 0) >= 3 {
                remaining.removeValue(forKey: id)
            }
            for id in remaining.keys {
                var item = remaining[id]!
                item["reported"] = (item["reported"] as? Int ?? 0) + 1
                remaining[id] = item
            }
            self.defaults.set(remaining, forKey: self.finishedKey)
            self.lock.unlock()
            DispatchQueue.main.async { done(items) }
        }
    }

    private func finish(_ id: String, _ item: [String: Any]) {
        lock.lock()
        var finished = defaults.dictionary(forKey: finishedKey) as? [String: [String: Any]] ?? [:]
        finished[id] = item
        defaults.set(finished, forKey: finishedKey)
        var destinations = defaults.dictionary(forKey: destinationsKey) as? [String: String] ?? [:]
        destinations.removeValue(forKey: id)
        defaults.set(destinations, forKey: destinationsKey)
        progress.removeValue(forKey: id)
        lock.unlock()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let id = downloadTask.taskDescription else { return }
        lock.lock()
        progress[id] = (totalBytesWritten, totalBytesExpectedToWrite)
        lock.unlock()
    }

    // The temporary file is deleted as soon as this returns, so it is moved synchronously.
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let id = downloadTask.taskDescription else { return }
        if let http = downloadTask.response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            finish(id, ["state": "failed", "received": 0, "total": -1, "error": "HTTP \(http.statusCode)"])
            return
        }
        lock.lock()
        let destinations = defaults.dictionary(forKey: destinationsKey) as? [String: String] ?? [:]
        lock.unlock()
        guard let path = destinations[id] else { return }
        let target = URL(fileURLWithPath: path)
        do {
            try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: target.path) { try FileManager.default.removeItem(at: target) }
            try FileManager.default.moveItem(at: location, to: target)
            let size = (try? FileManager.default.attributesOfItem(atPath: target.path)[.size] as? NSNumber)?.int64Value ?? 0
            finish(id, ["state": "completed", "received": NSNumber(value: size), "total": NSNumber(value: size), "path": target.path])
        } catch {
            finish(id, ["state": "failed", "received": 0, "total": -1, "error": "\(error.localizedDescription)"])
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let id = task.taskDescription, let error else { return }
        if (error as NSError).code == NSURLErrorCancelled { return }
        finish(id, ["state": "failed", "received": NSNumber(value: task.countOfBytesReceived), "total": -1, "error": error.localizedDescription])
    }

    func handleEvents(identifier: String, completionHandler: @escaping () -> Void) -> Bool {
        guard identifier == self.identifier else { return false }
        lock.lock()
        completionHandlers[identifier] = completionHandler
        lock.unlock()
        _ = session
        return true
    }

    #if os(iOS)
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        lock.lock()
        let handler = completionHandlers.removeValue(forKey: identifier)
        lock.unlock()
        DispatchQueue.main.async { handler?() }
    }
    #endif
}
