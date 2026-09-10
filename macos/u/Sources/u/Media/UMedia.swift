import AVFoundation

#if canImport(Flutter)
    import Flutter
    import UIKit
#elseif canImport(FlutterMacOS)
    import Cocoa
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

public final class UMediaPlayer: NSObject, FlutterTexture, FlutterStreamHandler {
    private let playerId: Int
    private let registry: FlutterTextureRegistry
    private let isVideo: Bool
    private let config: [String: Any]

    private let player = AVPlayer()
    private var output: AVPlayerItemVideoOutput?
    private var eventChannel: FlutterEventChannel?
    private var sink: FlutterEventSink?

    private var textureId: Int64 = -1
    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var sizeObservation: NSKeyValueObservation?
    private var bufferObservation: NSKeyValueObservation?
    private var playingObservation: NSKeyValueObservation?
    private var didAnnounceReady = false
    private var lastPixelBuffer: CVPixelBuffer?

    #if os(iOS)
        private var displayLink: CADisplayLink?
        private var pictureInPictureController: AVPictureInPictureController?
        private var pictureInPictureLayer: AVPlayerLayer?
    #else
        private var frameTimer: Timer?
    #endif

    public init(
        playerId: Int,
        messenger: FlutterBinaryMessenger,
        registry: FlutterTextureRegistry,
        config: [String: Any],
        isVideo: Bool
    ) {
        self.playerId = playerId
        self.registry = registry
        self.config = config
        self.isVideo = isVideo
        super.init()

        eventChannel = FlutterEventChannel(name: "u/media/events/\(playerId)", binaryMessenger: messenger)
        eventChannel?.setStreamHandler(self)

        player.actionAtItemEnd = .pause
        player.volume = Float(config["volume"] as? Double ?? 1.0)
        if config["muted"] as? Bool == true { player.isMuted = true }
        if isVideo { textureId = registry.register(self) }

        configureAudioSession()
        observeItemEnd()
    }

    public var currentTextureId: Int64 { textureId }

    private func configureAudioSession() {
        #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            let background = config["allowBackgroundPlayback"] as? Bool ?? false
            let policy = config["focusPolicy"] as? String ?? "exclusive"
            do {
                if policy == "mixWithOthers" {
                    try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                } else {
                    try session.setCategory(isVideo && !background ? .playback : .playback, mode: isVideo ? .moviePlayback : .default)
                }
                try session.setActive(true)
            } catch {
                return
            }
        #endif
    }

    private func observeItemEnd() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleItemEnded),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleItemFailed),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: nil
        )
        #if os(iOS)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleInterruption),
                name: AVAudioSession.interruptionNotification,
                object: nil
            )
        #endif
    }

    // MARK: - Flutter stream

    public func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        return nil
    }

    public func onCancel(withArguments _: Any?) -> FlutterError? {
        sink = nil
        return nil
    }

    private func send(_ payload: [String: Any?]) {
        guard let sink else { return }
        DispatchQueue.main.async { sink(payload) }
    }

    // MARK: - Texture

    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        guard let output else { return nil }
        let time = output.itemTime(forHostTime: CACurrentMediaTime())
        guard output.hasNewPixelBuffer(forItemTime: time),
              let buffer = output.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil)
        else {
            if let last = lastPixelBuffer { return Unmanaged.passRetained(last) }
            return nil
        }
        lastPixelBuffer = buffer
        return Unmanaged.passRetained(buffer)
    }

    private func startFrameLoop() {
        guard isVideo else { return }
        #if os(iOS)
            displayLink?.invalidate()
            let link = CADisplayLink(target: self, selector: #selector(onFrameTick))
            link.add(to: .main, forMode: .common)
            displayLink = link
        #else
            frameTimer?.invalidate()
            frameTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
                self?.onFrameTick()
            }
        #endif
    }

    private func stopFrameLoop() {
        #if os(iOS)
            displayLink?.invalidate()
            displayLink = nil
        #else
            frameTimer?.invalidate()
            frameTimer = nil
        #endif
    }

    @objc private func onFrameTick() {
        guard textureId >= 0, let output else { return }
        let time = output.itemTime(forHostTime: CACurrentMediaTime())
        if output.hasNewPixelBuffer(forItemTime: time) { registry.textureFrameAvailable(textureId) }
    }

    // MARK: - Commands

    public func open(source: [String: Any], autoPlay: Bool, resumeMs: Int?) {
        detachItem()

        guard let asset = UMediaMapper.makeAsset(source: source) else {
            send(["event": "error", "code": "notFound", "message": "Unsupported source"])
            return
        }

        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = Double(config["minBufferMs"] as? Int ?? 15000) / 1000.0
        if let maxHeight = config["maxHeight"] as? Int, maxHeight > 0 {
            item.preferredMaximumResolution = CGSize(width: CGFloat(maxHeight) * 16.0 / 9.0, height: CGFloat(maxHeight))
        }

        if isVideo {
            let attributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferIOSurfacePropertiesKey as String: [String: Any](),
                kCVPixelBufferMetalCompatibilityKey as String: true,
            ]
            let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: attributes)
            item.add(videoOutput)
            output = videoOutput
        }

        didAnnounceReady = false
        observe(item: item)
        player.replaceCurrentItem(with: item)

        if let resumeMs, resumeMs > 0 {
            player.seek(to: CMTime(value: CMTimeValue(resumeMs), timescale: 1000), toleranceBefore: .zero, toleranceAfter: .zero)
        }

        addPeriodicObserver()
        send(["event": "state", "state": "loading"])
        if autoPlay { play() }
    }

    private func observe(item: AVPlayerItem) {
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] observed, _ in
            guard let self else { return }
            switch observed.status {
            case .readyToPlay:
                announceReady(item: observed)
            case .failed:
                let error = observed.error as NSError?
                send([
                    "event": "error",
                    "code": UMediaMapper.errorCode(for: error),
                    "message": error?.localizedDescription ?? "Playback failed",
                    "platformCode": "\(error?.code ?? -1)",
                ])
            default:
                send(["event": "state", "state": "buffering"])
            }
        }

        sizeObservation = item.observe(\.presentationSize, options: [.new]) { [weak self] observed, _ in
            let size = observed.presentationSize
            self?.send(["event": "size", "width": Int(size.width), "height": Int(size.height), "rotation": 0])
        }

        bufferObservation = item.observe(\.loadedTimeRanges, options: [.new]) { [weak self] observed, _ in
            guard let self else { return }
            let ranges = observed.loadedTimeRanges.map { value -> [String: Any] in
                let range = value.timeRangeValue
                return [
                    "startMs": Int(CMTimeGetSeconds(range.start) * 1000),
                    "endMs": Int(CMTimeGetSeconds(range.end) * 1000),
                ]
            }
            let buffered = observed.loadedTimeRanges.last.map { CMTimeGetSeconds($0.timeRangeValue.end) * 1000 } ?? 0
            send(["event": "buffered", "ranges": ranges, "bufferedMs": Int(buffered)])
        }

        playingObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] observed, _ in
            guard let self else { return }
            switch observed.timeControlStatus {
            case .playing:
                send(["event": "state", "state": "playing"])
                startFrameLoop()
            case .paused:
                send(["event": "state", "state": "paused"])
                stopFrameLoop()
            case .waitingToPlayAtSpecifiedRate:
                send(["event": "state", "state": "buffering"])
            @unknown default:
                break
            }
        }
    }

    private func announceReady(item: AVPlayerItem) {
        guard !didAnnounceReady else { return }
        didAnnounceReady = true
        let duration = CMTimeGetSeconds(item.duration)
        let size = item.presentationSize
        send([
            "event": "initialized",
            "textureId": textureId >= 0 ? textureId : nil,
            "durationMs": duration.isFinite ? Int(duration * 1000) : 0,
            "width": Int(size.width),
            "height": Int(size.height),
            "rotation": 0,
            "isLive": !duration.isFinite,
            "tracks": UMediaMapper.tracks(for: item),
        ])
        if isVideo { startFrameLoop() }
    }

    private func addPeriodicObserver() {
        removePeriodicObserver()
        let interval = Double(config["positionUpdateMs"] as? Int ?? 250) / 1000.0
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: interval, preferredTimescale: 1000),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            let buffered = player.currentItem?.loadedTimeRanges.last.map { CMTimeGetSeconds($0.timeRangeValue.end) * 1000 } ?? 0
            send([
                "event": "position",
                "positionMs": Int(CMTimeGetSeconds(time) * 1000),
                "bufferedMs": Int(buffered),
            ])
        }
    }

    private func removePeriodicObserver() {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        timeObserver = nil
    }

    public func play() {
        player.play()
        if let speed = config["speed"] as? Double, speed != 1.0 { player.rate = Float(speed) }
    }

    public func pause() {
        player.pause()
    }

    public func stop() {
        player.pause()
        player.seek(to: .zero)
        detachItem()
        send(["event": "state", "state": "idle"])
    }

    public func seek(positionMs: Int, precise: Bool) {
        let target = CMTime(value: CMTimeValue(positionMs), timescale: 1000)
        let tolerance: CMTime = precise ? .zero : CMTime(seconds: 1, preferredTimescale: 1000)
        player.seek(to: target, toleranceBefore: tolerance, toleranceAfter: tolerance)
    }

    public func stepFrame(frames: Int) {
        player.currentItem?.step(byCount: frames)
    }

    public func setSpeed(_ speed: Double, preservePitch: Bool) {
        player.currentItem?.audioTimePitchAlgorithm = preservePitch ? .timeDomain : .varispeed
        if player.timeControlStatus == .playing { player.rate = Float(speed) }
    }

    public func setVolume(_ volume: Double) {
        player.volume = Float(min(max(volume, 0), 1))
        player.isMuted = volume == 0
    }

    public func setMuted(_ muted: Bool) {
        player.isMuted = muted
    }

    public func setRepeat(_ mode: String?) {
        player.actionAtItemEnd = mode == "one" ? .none : .pause
    }

    public func selectTrack(trackId: String, type: String?) {
        guard let item = player.currentItem else { return }
        UMediaMapper.select(trackId: trackId, type: type, in: item)
        send(["event": "tracks", "tracks": UMediaMapper.tracks(for: item)])
    }

    public func setMaxHeight(_ height: Int) {
        guard height > 0 else {
            player.currentItem?.preferredMaximumResolution = .zero
            return
        }
        player.currentItem?.preferredMaximumResolution = CGSize(width: CGFloat(height) * 16.0 / 9.0, height: CGFloat(height))
    }

    public func screenshot() -> Data? {
        guard let asset = player.currentItem?.asset else { return nil }
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        guard let image = try? generator.copyCGImage(at: player.currentTime(), actualTime: nil) else { return nil }
        #if os(iOS)
            return UIImage(cgImage: image).pngData()
        #else
            let representation = NSBitmapImageRep(cgImage: image)
            return representation.representation(using: .png, properties: [:])
        #endif
    }

    public func enterPip(aspectRatio _: Double) -> Bool {
        #if os(iOS)
            guard AVPictureInPictureController.isPictureInPictureSupported() else { return false }
            if pictureInPictureLayer == nil {
                let layer = AVPlayerLayer(player: player)
                layer.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
                UIApplication.shared.connectedScenes
                    .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                    .first?
                    .layer
                    .addSublayer(layer)
                pictureInPictureLayer = layer
                pictureInPictureController = AVPictureInPictureController(playerLayer: layer)
            }
            guard let controller = pictureInPictureController else { return false }
            controller.startPictureInPicture()
            send(["event": "pip", "state": "active"])
            return true
        #else
            return false
        #endif
    }

    public func exitPip() {
        #if os(iOS)
            pictureInPictureController?.stopPictureInPicture()
            send(["event": "pip", "state": "available"])
        #endif
    }

    @objc private func handleItemEnded(notification: Notification) {
        guard let item = notification.object as? AVPlayerItem, item === player.currentItem else { return }
        stopFrameLoop()
        send(["event": "completed"])
    }

    @objc private func handleItemFailed(notification: Notification) {
        guard let item = notification.object as? AVPlayerItem, item === player.currentItem else { return }
        let error = item.error as NSError?
        send([
            "event": "error",
            "code": UMediaMapper.errorCode(for: error),
            "message": error?.localizedDescription ?? "Playback stalled",
        ])
    }

    #if os(iOS)
        @objc private func handleInterruption(notification: Notification) {
            guard let info = notification.userInfo,
                  let rawType = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: rawType)
            else { return }
            if type == .began {
                pause()
                send(["event": "state", "state": "paused"])
            }
        }
    #endif

    private func detachItem() {
        statusObservation?.invalidate()
        sizeObservation?.invalidate()
        bufferObservation?.invalidate()
        statusObservation = nil
        sizeObservation = nil
        bufferObservation = nil
        if let output, let item = player.currentItem { item.remove(output) }
        output = nil
        lastPixelBuffer = nil
        player.replaceCurrentItem(with: nil)
    }

    public func dispose() {
        stopFrameLoop()
        removePeriodicObserver()
        playingObservation?.invalidate()
        playingObservation = nil
        detachItem()
        NotificationCenter.default.removeObserver(self)
        eventChannel?.setStreamHandler(nil)
        eventChannel = nil
        sink = nil
        #if os(iOS)
            pictureInPictureController = nil
            pictureInPictureLayer?.removeFromSuperlayer()
            pictureInPictureLayer = nil
        #endif
        if textureId >= 0 { registry.unregisterTexture(textureId) }
        textureId = -1
    }
}

public final class UMediaHandler: NSObject {
    private let channel: FlutterMethodChannel
    private let sessionChannel: FlutterMethodChannel
    private let messenger: FlutterBinaryMessenger
    private let registry: FlutterTextureRegistry

    private var players: [Int: UMediaPlayer] = [:]
    private var nextId = 1

    public init(messenger: FlutterBinaryMessenger, registry: FlutterTextureRegistry) {
        self.messenger = messenger
        self.registry = registry
        channel = FlutterMethodChannel(name: "u/media", binaryMessenger: messenger)
        sessionChannel = FlutterMethodChannel(name: "u/media_session", binaryMessenger: messenger)
        super.init()

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call: call, result: result)
        }
        sessionChannel.setMethodCallHandler { call, result in
            switch call.method {
            case "requestFocus":
                result(true)
            case "abandonFocus":
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "isAvailable" {
            result(true)
            return
        }

        let arguments = call.arguments as? [String: Any] ?? [:]

        if call.method == "create" {
            let kind = arguments["kind"] as? String ?? "video"
            let config = arguments["config"] as? [String: Any] ?? [:]
            let id = nextId
            nextId += 1
            players[id] = UMediaPlayer(
                playerId: id,
                messenger: messenger,
                registry: registry,
                config: config,
                isVideo: kind == "video"
            )
            result(id)
            return
        }

        guard let id = arguments["id"] as? Int else {
            result(FlutterError(code: "ERROR_UNSPECIFIED", message: "Missing player id", details: nil))
            return
        }
        guard let player = players[id] else {
            result(FlutterError(code: "ERROR_NOT_FOUND", message: "Player \(id) not found", details: nil))
            return
        }

        switch call.method {
        case "open":
            player.open(
                source: arguments["source"] as? [String: Any] ?? [:],
                autoPlay: arguments["autoPlay"] as? Bool ?? false,
                resumeMs: arguments["resumeMs"] as? Int
            )
            result(nil)
        case "play":
            player.play()
            result(nil)
        case "pause":
            player.pause()
            result(nil)
        case "stop":
            player.stop()
            result(nil)
        case "seek":
            player.seek(positionMs: arguments["positionMs"] as? Int ?? 0, precise: arguments["precise"] as? Bool ?? true)
            result(nil)
        case "stepFrame":
            player.stepFrame(frames: arguments["frames"] as? Int ?? 1)
            result(nil)
        case "setSpeed":
            player.setSpeed(arguments["speed"] as? Double ?? 1.0, preservePitch: arguments["preservePitch"] as? Bool ?? true)
            result(nil)
        case "setVolume":
            player.setVolume(arguments["volume"] as? Double ?? 1.0)
            result(nil)
        case "setMuted":
            player.setMuted(arguments["muted"] as? Bool ?? false)
            result(nil)
        case "setRepeat":
            player.setRepeat(arguments["mode"] as? String)
            result(nil)
        case "selectTrack":
            player.selectTrack(trackId: arguments["trackId"] as? String ?? "", type: arguments["type"] as? String)
            result(nil)
        case "setAutoQuality":
            player.setMaxHeight(0)
            result(nil)
        case "setMaxHeight":
            player.setMaxHeight(arguments["height"] as? Int ?? 0)
            result(nil)
        case "setAudioDelay":
            result(nil)
        case "enterPip":
            result(player.enterPip(aspectRatio: arguments["aspectRatio"] as? Double ?? 16.0 / 9.0))
        case "exitPip":
            player.exitPip()
            result(nil)
        case "screenshot":
            if let data = player.screenshot() {
                result(FlutterStandardTypedData(bytes: data))
            } else {
                result(nil)
            }
        case "setNotification":
            result(nil)
        case "dispose":
            player.dispose()
            players.removeValue(forKey: id)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func dispose() {
        channel.setMethodCallHandler(nil)
        sessionChannel.setMethodCallHandler(nil)
        players.values.forEach { $0.dispose() }
        players.removeAll()
    }
}
