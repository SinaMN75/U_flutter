// Shared verbatim between ios/ and macos/ — edit both copies together.
#if os(iOS)
import Flutter
import PhotosUI
import UIKit
#else
import AppKit
import FlutterMacOS
#endif
import Foundation
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// The native file and folder picker behind "u/files" pick / pickDirectory.
final class UFilesPicker: NSObject {
    private var result: FlutterResult?
    private var maxCount = 0
    private var directory = false

    func pick(_ args: [String: Any], result: @escaping FlutterResult) {
        finish(nil)
        self.result = result
        directory = false
        let type = args["type"] as? String ?? "any"
        let multiple = args["multiple"] as? Bool ?? false
        maxCount = multiple ? (args["maxCount"] as? Int ?? 0) : 1
        let extensions = args["extensions"] as? [String] ?? []
        let initial = (args["initialDirectory"] as? String).map { URL(fileURLWithPath: $0) }
        #if os(iOS)
        guard let presenter = Self.topViewController() else {
            return finish(FlutterError(code: "no_view", message: "No view controller to present from", details: nil))
        }
        if #available(iOS 14.0, *), ["image", "video", "media"].contains(type) {
            var configuration = PHPickerConfiguration()
            configuration.filter = type == "image" ? PHPickerFilter.images : type == "video" ? PHPickerFilter.videos : PHPickerFilter.any(of: [.images, .videos])
            configuration.selectionLimit = maxCount
            if #available(iOS 15.0, *) { configuration.selection = .ordered }
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            presenter.present(picker, animated: true)
            return
        }
        let picker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            picker = UIDocumentPickerViewController(forOpeningContentTypes: Self.contentTypes(type, extensions), asCopy: true)
        } else {
            picker = UIDocumentPickerViewController(documentTypes: Self.legacyTypes(type), in: .import)
        }
        picker.allowsMultipleSelection = multiple
        picker.directoryURL = initial
        picker.delegate = self
        presenter.present(picker, animated: true)
        #else
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = multiple
        panel.resolvesAliases = true
        panel.message = args["title"] as? String
        panel.directoryURL = initial
        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = Self.contentTypes(type, extensions)
        } else if !extensions.isEmpty {
            panel.allowedFileTypes = extensions
        }
        panel.begin { [weak self] response in
            self?.deliver(response == .OK ? panel.urls : [], copy: false)
        }
        #endif
    }

    func pickDirectory(_ args: [String: Any], result: @escaping FlutterResult) {
        finish(nil)
        self.result = result
        directory = true
        let initial = (args["initialDirectory"] as? String).map { URL(fileURLWithPath: $0) }
        #if os(iOS)
        guard let presenter = Self.topViewController() else {
            return finish(FlutterError(code: "no_view", message: "No view controller to present from", details: nil))
        }
        let picker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        } else {
            picker = UIDocumentPickerViewController(documentTypes: ["public.folder"], in: .open)
        }
        picker.directoryURL = initial
        picker.delegate = self
        presenter.present(picker, animated: true)
        #else
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = args["title"] as? String
        panel.directoryURL = initial
        panel.begin { [weak self] response in
            self?.finish(response == .OK ? panel.url?.path : nil)
        }
        #endif
    }

    private func finish(_ value: Any?) {
        let pending = result
        result = nil
        pending?(value)
    }

    // Reads every file off the main thread; [copy] stages it in the temp folder first, so the
    // returned path outlives the picker's own short-lived copy.
    private func deliver(_ urls: [URL], copy: Bool) {
        let selected = maxCount > 0 ? Array(urls.prefix(maxCount)) : urls
        guard !selected.isEmpty else { return finish(nil) }
        DispatchQueue.global(qos: .userInitiated).async {
            let files: [[String: Any]] = selected.compactMap { url in
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                let target = copy ? Self.stage(url) : url
                guard let target, let data = try? Data(contentsOf: target) else { return nil }
                return ["name": url.lastPathComponent, "path": target.path, "bytes": FlutterStandardTypedData(bytes: data)]
            }
            DispatchQueue.main.async { self.finish(files) }
        }
    }

    private static func stage(_ url: URL) -> URL? {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("u_picker/\(UUID().uuidString)", isDirectory: true)
        let target = folder.appendingPathComponent(url.lastPathComponent)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: url, to: target)
            return target
        } catch {
            return nil
        }
    }

    @available(iOS 14.0, macOS 11.0, *)
    private static func contentTypes(_ type: String, _ extensions: [String]) -> [UTType] {
        switch type {
        case "image": return [.image]
        case "video": return [.movie]
        case "media": return [.image, .movie]
        case "audio": return [.audio]
        case "custom":
            let types = extensions.compactMap { UTType(filenameExtension: $0) }
            return types.isEmpty ? [.item] : types
        default: return [.item]
        }
    }

    #if os(iOS)
    private static func legacyTypes(_ type: String) -> [String] {
        switch type {
        case "image": return ["public.image"]
        case "video": return ["public.movie"]
        case "media": return ["public.image", "public.movie"]
        case "audio": return ["public.audio"]
        default: return ["public.item"]
        }
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
    #endif
}

#if os(iOS)
extension UFilesPicker: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard directory else { return deliver(urls, copy: true) }
        guard let url = urls.first else { return finish(nil) }
        // Folder access lasts for the session, so the app can list and read it afterwards.
        _ = url.startAccessingSecurityScopedResource()
        finish(url.path)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        finish(nil)
    }
}

@available(iOS 14.0, *)
extension UFilesPicker: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return finish(nil) }
        var staged = [URL?](repeating: nil, count: results.count)
        let lock = NSLock()
        let group = DispatchGroup()
        for (index, item) in results.enumerated() {
            let provider = item.itemProvider
            guard let identifier = provider.registeredTypeIdentifiers.first(where: { id in
                UTType(id).map { $0.conforms(to: .image) || $0.conforms(to: .movie) } ?? false
            }) ?? provider.registeredTypeIdentifiers.first else { continue }
            group.enter()
            // The provided file is deleted when this callback returns, so it is copied inside it.
            provider.loadFileRepresentation(forTypeIdentifier: identifier) { url, _ in
                if let url {
                    let named = provider.suggestedName.map { name -> String in
                        name.contains(".") ? name : "\(name).\(url.pathExtension)"
                    }
                    if var copy = Self.stage(url) {
                        if let named, named != copy.lastPathComponent {
                            let renamed = copy.deletingLastPathComponent().appendingPathComponent(named)
                            if (try? FileManager.default.moveItem(at: copy, to: renamed)) != nil { copy = renamed }
                        }
                        lock.lock()
                        staged[index] = copy
                        lock.unlock()
                    }
                }
                group.leave()
            }
        }
        group.notify(queue: .main) { self.deliver(staged.compactMap { $0 }, copy: false) }
    }
}
#endif
