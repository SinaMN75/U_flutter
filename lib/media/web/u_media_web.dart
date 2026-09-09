import "dart:async";
import "dart:convert";
import "dart:js_interop";
import "dart:typed_data";
import "dart:ui_web" as ui_web;

import "package:flutter/services.dart";
import "package:flutter_web_plugins/flutter_web_plugins.dart";
import "package:web/web.dart" as web;

class UMediaWeb {
  UMediaWeb(this._messenger);

  final BinaryMessenger _messenger;
  static const StandardMethodCodec _codec = StandardMethodCodec();

  final Map<int, _WebPlayer> _players = <int, _WebPlayer>{};
  int _nextId = 1;

  static void registerWith(Registrar registrar) {
    final UMediaWeb instance = UMediaWeb(registrar);
    MethodChannel("u/media", _codec, registrar).setMethodCallHandler(instance._handle);
    MethodChannel("u/media_session", _codec, registrar).setMethodCallHandler(instance._handleSession);
  }

  Future<Object?> _handleSession(MethodCall call) async {
    switch (call.method) {
      case "requestFocus":
        return true;
      case "abandonFocus":
        return null;
      default:
        throw MissingPluginException("u/media_session.${call.method}");
    }
  }

  Future<Object?> _handle(MethodCall call) async {
    if (call.method == "isAvailable") return true;

    final Map<Object?, Object?> arguments = (call.arguments as Map<Object?, Object?>?) ?? <Object?, Object?>{};

    if (call.method == "create") {
      final int id = _nextId++;
      final Map<Object?, Object?> config = (arguments["config"] as Map<Object?, Object?>?) ?? <Object?, Object?>{};
      _players[id] = _WebPlayer(id, config, _emit, arguments["kind"] == "video");
      return id;
    }

    final int? id = arguments["id"] as int?;
    final _WebPlayer? player = id == null ? null : _players[id];
    if (player == null) throw PlatformException(code: "ERROR_NOT_FOUND", message: "Player $id not found");

    switch (call.method) {
      case "open":
        player.open((arguments["source"] as Map<Object?, Object?>?) ?? <Object?, Object?>{}, arguments["autoPlay"] == true, arguments["resumeMs"] as int?);
        return null;
      case "play":
        await player.play();
        return null;
      case "pause":
        player.pause();
        return null;
      case "stop":
        player.stop();
        return null;
      case "seek":
        player.seek(arguments["positionMs"] as int? ?? 0);
        return null;
      case "stepFrame":
        player.seek(player.positionMs + (1000 ~/ 30) * ((arguments["frames"] as int?) ?? 1));
        return null;
      case "setSpeed":
        player.setSpeed((arguments["speed"] as num?)?.toDouble() ?? 1);
        return null;
      case "setVolume":
        player.setVolume((arguments["volume"] as num?)?.toDouble() ?? 1);
        return null;
      case "setMuted":
        player.setMuted(arguments["muted"] == true);
        return null;
      case "setRepeat":
        player.setRepeat(arguments["mode"] as String?);
        return null;
      case "selectTrack":
        player.selectTrack(arguments["trackId"] as String? ?? "", arguments["type"] as String?);
        return null;
      case "setAutoQuality":
      case "setMaxHeight":
      case "setAudioDelay":
      case "setNotification":
        return null;
      case "enterPip":
        return player.enterPip();
      case "exitPip":
        player.exitPip();
        return null;
      case "screenshot":
        return player.screenshot();
      case "dispose":
        player.dispose();
        _players.remove(id);
        return null;
      default:
        throw MissingPluginException("u/media.${call.method}");
    }
  }

  void _emit(int id, Map<String, Object?> payload) {
    _messenger.send("u/media/events/$id", _codec.encodeSuccessEnvelope(payload));
  }
}

class _WebPlayer {
  _WebPlayer(this.id, this.config, this._emit, this.isVideo) {
    element
      ..autoplay = false
      ..controls = false
      ..playsInline = true
      ..preload = "auto"
      ..style.width = "100%"
      ..style.height = "100%"
      ..style.objectFit = "contain"
      ..style.border = "none";

    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) => element);
    _attachListeners();
  }

  final int id;
  final Map<Object?, Object?> config;
  final void Function(int id, Map<String, Object?> payload) _emit;
  final bool isVideo;
  final web.HTMLVideoElement element = web.HTMLVideoElement();

  Timer? _ticker;
  bool _announced = false;

  String get viewType => "u-media-$id";

  int get positionMs => (element.currentTime * 1000).round();

  void _attachListeners() {
    element.onLoadedMetadata.listen((web.Event _) => _announce());
    element.onDurationChange.listen((web.Event _) => _announce());
    element.onPlaying.listen((web.Event _) {
      _emit(id, <String, Object?>{"event": "state", "state": "playing"});
      _startTicker();
    });
    element.onPause.listen((web.Event _) {
      _emit(id, <String, Object?>{"event": "state", "state": "paused"});
      _stopTicker();
    });
    element.onWaiting.listen((web.Event _) => _emit(id, <String, Object?>{"event": "state", "state": "buffering"}));
    element.onEnded.listen((web.Event _) {
      _stopTicker();
      _emit(id, <String, Object?>{"event": "completed"});
    });
    element.onError.listen((web.Event _) {
      final int code = element.error?.code ?? 0;
      _emit(id, <String, Object?>{
        "event": "error",
        "code": _errorCode(code),
        "message": element.error?.message ?? "Playback failed",
        "platformCode": "$code",
      });
    });
  }

  String _errorCode(int code) {
    switch (code) {
      case 1:
        return "aborted";
      case 2:
        return "network";
      case 3:
        return "decoder";
      case 4:
        return "unsupportedFormat";
      default:
        return "unknown";
    }
  }

  void _announce() {
    if (_announced || element.readyState < 1) return;
    _announced = true;
    final double duration = element.duration;
    _emit(id, <String, Object?>{
      "event": "initialized",
      "textureId": null,
      "durationMs": duration.isFinite ? (duration * 1000).round() : 0,
      "width": element.videoWidth,
      "height": element.videoHeight,
      "rotation": 0,
      "isLive": !duration.isFinite,
      "tracks": _tracks(),
    });
  }

  List<Map<String, Object?>> _tracks() {
    final List<Map<String, Object?>> result = <Map<String, Object?>>[];
    if (element.videoWidth > 0) {
      result.add(<String, Object?>{
        "id": "video:0",
        "type": "video",
        "width": element.videoWidth,
        "height": element.videoHeight,
        "isSelected": true,
        "isDefault": true,
      });
    }
    final web.TextTrackList tracks = element.textTracks;
    for (int i = 0; i < tracks.length; i++) {
      final web.TextTrack track = tracks[i];
      result.add(<String, Object?>{
        "id": "subtitle:$i",
        "type": "subtitle",
        "label": track.label,
        "language": track.language,
        "isSelected": track.mode == "showing",
        "isDefault": i == 0,
      });
    }
    return result;
  }

  void _startTicker() {
    _stopTicker();
    final int interval = (config["positionUpdateMs"] as int?) ?? 250;
    _ticker = Timer.periodic(Duration(milliseconds: interval), (Timer _) => _emitPosition());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _emitPosition() {
    double buffered = 0;
    final web.TimeRanges ranges = element.buffered;
    if (ranges.length > 0) buffered = ranges.end(ranges.length - 1);
    _emit(id, <String, Object?>{
      "event": "position",
      "positionMs": positionMs,
      "bufferedMs": (buffered * 1000).round(),
    });
  }

  void open(Map<Object?, Object?> source, bool autoPlay, int? resumeMs) {
    _announced = false;
    final String url = _resolve(source);
    if (url.isEmpty) {
      _emit(id, <String, Object?>{"event": "error", "code": "notFound", "message": "Unsupported source"});
      return;
    }
    if (url.toLowerCase().contains(".m3u8") && element.canPlayType("application/vnd.apple.mpegurl").isEmpty) {
      _emit(id, <String, Object?>{"event": "error", "code": "unsupportedFormat", "message": "HLS is not natively supported by this browser"});
      return;
    }
    element.src = url;
    element.load();
    if (resumeMs != null && resumeMs > 0) element.currentTime = resumeMs / 1000;
    _emit(id, <String, Object?>{"event": "state", "state": "loading"});
    if (autoPlay) unawaited(play());
  }

  String _resolve(Map<Object?, Object?> source) {
    switch (source["kind"] as String?) {
      case "network":
        return (source["url"] as String?) ?? "";
      case "content":
        return (source["uri"] as String?) ?? "";
      case "asset":
        return "assets/${source["asset"] as String? ?? ""}";
      case "bytes":
        final Object? raw = source["bytes"];
        if (raw is! Uint8List) return "";
        final web.Blob blob = web.Blob(<JSUint8Array>[raw.toJS].toJS);
        return web.URL.createObjectURL(blob);
      default:
        return "";
    }
  }

  Future<void> play() async {
    try {
      await element.play().toDart;
    } on Object {
      _emit(id, <String, Object?>{"event": "error", "code": "permission", "message": "Autoplay was blocked by the browser"});
    }
  }

  void pause() => element.pause();

  void stop() {
    element.pause();
    element.currentTime = 0;
    element.removeAttribute("src");
    element.load();
    _stopTicker();
    _emit(id, <String, Object?>{"event": "state", "state": "idle"});
  }

  void seek(int positionMs) {
    element.currentTime = positionMs / 1000;
    _emitPosition();
  }

  void setSpeed(double speed) => element.playbackRate = speed;

  void setVolume(double volume) {
    element.volume = volume.clamp(0, 1).toDouble();
    element.muted = volume == 0;
  }

  void setMuted(bool muted) => element.muted = muted;

  void setRepeat(String? mode) => element.loop = mode == "one";

  void selectTrack(String trackId, String? type) {
    if (type != "subtitle") return;
    final List<String> parts = trackId.split(":");
    if (parts.length != 2) return;
    final int index = int.tryParse(parts[1]) ?? -1;
    final web.TextTrackList tracks = element.textTracks;
    for (int i = 0; i < tracks.length; i++) {
      tracks[i].mode = i == index ? "showing" : "disabled";
    }
    _emit(id, <String, Object?>{"event": "tracks", "tracks": _tracks()});
  }

  bool enterPip() {
    element.requestPictureInPicture();
    _emit(id, <String, Object?>{"event": "pip", "state": "active"});
    return true;
  }

  void exitPip() {
    web.document.exitPictureInPicture();
    _emit(id, <String, Object?>{"event": "pip", "state": "available"});
  }

  Uint8List? screenshot() {
    if (element.videoWidth == 0) return null;
    final web.HTMLCanvasElement canvas = web.HTMLCanvasElement()
      ..width = element.videoWidth
      ..height = element.videoHeight;
    final web.CanvasRenderingContext2D context = canvas.getContext("2d")! as web.CanvasRenderingContext2D;
    context.drawImage(element, 0, 0);
    final String data = canvas.toDataURL("image/png");
    final int comma = data.indexOf(",");
    if (comma < 0) return null;
    return base64Decode(data.substring(comma + 1));
  }

  void dispose() {
    _stopTicker();
    element.pause();
    element.removeAttribute("src");
    element.remove();
  }
}
