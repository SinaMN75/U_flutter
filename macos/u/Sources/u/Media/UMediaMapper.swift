import AVFoundation

#if canImport(Flutter)
    import Flutter
#elseif canImport(FlutterMacOS)
    import FlutterMacOS
#endif

public enum UMediaMapper {
    public static func makeAsset(source: [String: Any]) -> AVURLAsset? {
        guard let url = resolveUrl(source: source) else { return nil }
        var options: [String: Any] = [:]
        if let headers = source["headers"] as? [String: String], !headers.isEmpty {
            options["AVURLAssetHTTPHeaderFieldsKey"] = headers
        }
        return AVURLAsset(url: url, options: options)
    }

    private static func resolveUrl(source: [String: Any]) -> URL? {
        switch source["kind"] as? String {
        case "network":
            guard let value = source["url"] as? String else { return nil }
            return URL(string: value)
        case "file":
            guard let value = source["path"] as? String else { return nil }
            return URL(fileURLWithPath: value)
        case "content":
            guard let value = source["uri"] as? String else { return nil }
            return URL(string: value)
        case "asset":
            guard let value = source["asset"] as? String else { return nil }
            return assetUrl(for: value)
        case "bytes":
            guard let data = (source["bytes"] as? FlutterStandardTypedData)?.data else { return nil }
            return writeTemporary(data: data)
        default:
            return nil
        }
    }

    private static func assetUrl(for asset: String) -> URL? {
        #if canImport(Flutter)
            let key = FlutterDartProject.lookupKey(forAsset: asset)
        #else
            let key = FlutterDartProject.lookupKey(forAsset: asset)
        #endif
        guard let path = Bundle.main.path(forResource: key, ofType: nil) else { return nil }
        return URL(fileURLWithPath: path)
    }

    private static func writeTemporary(data: Data) -> URL? {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("u_media", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("src_\(data.count)_\(data.hashValue).bin")
        if !FileManager.default.fileExists(atPath: file.path) {
            guard (try? data.write(to: file)) != nil else { return nil }
        }
        return file
    }

    public static func tracks(for item: AVPlayerItem) -> [[String: Any?]] {
        var result: [[String: Any?]] = []

        for (index, track) in item.tracks.enumerated() where track.assetTrack?.mediaType == .video {
            guard let assetTrack = track.assetTrack else { continue }
            let size = assetTrack.naturalSize.applying(assetTrack.preferredTransform)
            result.append([
                "id": "video:\(index)",
                "type": "video",
                "label": nil,
                "language": assetTrack.languageCode,
                "codec": nil,
                "bitrate": Int(assetTrack.estimatedDataRate),
                "width": Int(abs(size.width)),
                "height": Int(abs(size.height)),
                "frameRate": Double(assetTrack.nominalFrameRate),
                "isSelected": track.isEnabled,
                "isDefault": index == 0,
                "isForced": false,
                "isAuto": false,
            ])
        }

        result.append(contentsOf: selectionTracks(for: item, characteristic: .audible, type: "audio"))
        result.append(contentsOf: selectionTracks(for: item, characteristic: .legible, type: "subtitle"))
        return result
    }

    private static func selectionTracks(
        for item: AVPlayerItem,
        characteristic: AVMediaCharacteristic,
        type: String
    ) -> [[String: Any?]] {
        guard let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: characteristic) else { return [] }
        let selected = item.currentMediaSelection.selectedMediaOption(in: group)
        return group.options.enumerated().map { index, option in
            [
                "id": "\(type):\(index)",
                "type": type,
                "label": option.displayName,
                "language": option.extendedLanguageTag ?? option.locale?.identifier,
                "codec": nil,
                "isSelected": option == selected,
                "isDefault": index == 0,
                "isForced": option.hasMediaCharacteristic(.containsOnlyForcedSubtitles),
                "isAuto": false,
            ]
        }
    }

    public static func select(trackId: String, type: String?, in item: AVPlayerItem) {
        let parts = trackId.split(separator: ":")
        guard parts.count == 2, let index = Int(parts[1]) else { return }
        let kind = String(parts[0])

        if kind == "video" {
            for (position, track) in item.tracks.enumerated() where track.assetTrack?.mediaType == .video {
                track.isEnabled = position == index
            }
            return
        }

        let characteristic: AVMediaCharacteristic = kind == "audio" ? .audible : .legible
        guard let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: characteristic),
              index >= 0, index < group.options.count
        else { return }
        item.select(group.options[index], in: group)
    }

    public static func errorCode(for error: NSError?) -> String {
        guard let error else { return "unknown" }
        switch error.code {
        case NSURLErrorTimedOut:
            return "timeout"
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorCannotConnectToHost:
            return "network"
        case NSURLErrorFileDoesNotExist, NSURLErrorBadURL:
            return "notFound"
        case NSURLErrorNoPermissionsToReadFile:
            return "permission"
        default:
            break
        }
        if error.domain == AVFoundationErrorDomain {
            switch error.code {
            case AVError.Code.decoderNotFound.rawValue, AVError.Code.failedToLoadMediaData.rawValue:
                return "decoder"
            case AVError.Code.fileFormatNotRecognized.rawValue:
                return "unsupportedFormat"
            default:
                return "decoder"
            }
        }
        return "unknown"
    }
}
