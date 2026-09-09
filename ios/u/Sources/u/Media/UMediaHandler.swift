import AVFoundation

#if canImport(Flutter)
    import Flutter
#elseif canImport(FlutterMacOS)
    import FlutterMacOS
#endif

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
