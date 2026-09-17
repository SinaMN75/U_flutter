import "dart:async";
import "dart:js_interop";
import "dart:js_interop_unsafe";
import "dart:ui_web" as ui_web;

import "package:flutter/services.dart";
import "package:flutter_web_plugins/flutter_web_plugins.dart";
import "package:web/web.dart" as web;

// =============================================================================
// u_camera_web — getUserMedia implementation of the `u` camera plugin.
//
// The preview is a <video> element shown through an HtmlElementView, frames are
// grabbed from a canvas, recording uses MediaRecorder, and scanning prefers the
// browser's own BarcodeDetector where it exists (Chrome and Edge) and otherwise
// falls back to the bundled Dart decoder driven from the frame stream.
// =============================================================================

/// The browser's own decoder, present in Chrome and Edge and absent elsewhere.
bool _hasBarcodeDetectorApi() => globalContext.has("BarcodeDetector");

extension type _BarcodeDetectorOptions._(JSObject _) implements JSObject {
  external factory _BarcodeDetectorOptions({JSArray<JSString> formats});
}

@JS("BarcodeDetector")
extension type _JsBarcodeDetector._(JSObject _) implements JSObject {
  external factory _JsBarcodeDetector(_BarcodeDetectorOptions options);

  external JSPromise<JSArray<JSObject>> detect(JSObject source);
}

extension type _JsDetectedBarcode._(JSObject _) implements JSObject {
  external String get rawValue;
  external String get format;
  external JSObject get boundingBox;
}

class UCameraWeb {
  UCameraWeb(this._messenger);

  final BinaryMessenger _messenger;
  static const StandardMethodCodec _codec = StandardMethodCodec();

  final Map<int, _WebCameraSession> _sessions = <int, _WebCameraSession>{};
  int _nextId = 1;

  static void registerWith(Registrar registrar) {
    final UCameraWeb instance = UCameraWeb(registrar);
    MethodChannel("u/camera", _codec, registrar).setMethodCallHandler(instance._handle);
  }

  static bool get _hasBarcodeDetector => _hasBarcodeDetectorApi();

  Future<Object?> _handle(MethodCall call) async {
    final Map<Object?, Object?> arguments = (call.arguments as Map<Object?, Object?>?) ?? <Object?, Object?>{};

    switch (call.method) {
      case "isSupported":
        return web.window.navigator.mediaDevices.isDefinedAndNotNull;
      case "availableCameras":
        return _availableCameras();
      case "permissionStatus":
        return <String, Object?>{"camera": "unknown", "microphone": "unknown"};
      case "requestPermission":
        return _requestPermission(arguments["audio"] == true);
      case "openSettings":
        return false;
      case "create":
        return _create((arguments["config"] as Map<Object?, Object?>?) ?? <Object?, Object?>{});
      case "analyzeImage":
        return _analyzeImage(arguments);
    }

    final int? id = (arguments["sessionId"] as num?)?.toInt();
    final _WebCameraSession? session = id == null ? null : _sessions[id];
    if (session == null) throw PlatformException(code: "notFound", message: "Camera session not found");

    switch (call.method) {
      case "dispose":
        _sessions.remove(id)?.dispose();
        return null;
      case "takePhoto":
      case "takeSnapshot":
        return session.capture(
          format: arguments["format"] as String? ?? "jpeg",
          quality: ((arguments["quality"] as num?) ?? 92).toDouble() / 100.0,
        );
      case "startRecording":
        await session.startRecording();
        return null;
      case "stopRecording":
        return session.stopRecording();
      case "pauseRecording":
        session.pauseRecording();
        return null;
      case "resumeRecording":
        session.resumeRecording();
        return null;
      case "setTorch":
        await session.setTorch(arguments["on"] == true);
        return null;
      case "setFlashMode":
        await session.setTorch(arguments["mode"] == "torch");
        return null;
      case "setZoom":
        await session.setZoom(((arguments["zoom"] as num?) ?? 1).toDouble());
        return null;
      case "setPreviewPaused":
        session.setPaused(arguments["paused"] == true);
        return null;
      case "startImageStream":
        session.startImageStream(((arguments["maxFps"] as num?) ?? 12).toDouble());
        return null;
      case "stopImageStream":
        session.stopImageStream();
        return null;
      case "startScanning":
        session.startScanning((arguments["options"] as Map<Object?, Object?>?) ?? <Object?, Object?>{});
        return null;
      case "stopScanning":
        session.stopScanning();
        return null;
      default:
        // Controls a browser cannot express are accepted silently so the Dart
        // controller keeps a consistent state.
        return null;
    }
  }

  Future<List<Map<String, Object?>>> _availableCameras() async {
    final web.MediaDevices devices = web.window.navigator.mediaDevices;
    final JSArray<web.MediaDeviceInfo> list = await devices.enumerateDevices().toDart;
    final List<Map<String, Object?>> out = <Map<String, Object?>>[];
    for (int i = 0; i < list.length; i++) {
      final web.MediaDeviceInfo info = list[i];
      if (info.kind != "videoinput") continue;
      final String label = info.label.isEmpty ? "Camera ${out.length + 1}" : info.label;
      final String lowered = label.toLowerCase();
      out.add(<String, Object?>{
        "id": info.deviceId,
        "name": label,
        "facing": lowered.contains("front") || lowered.contains("user") ? "front" : (lowered.contains("back") || lowered.contains("environment") ? "back" : "external"),
        "lens": "wide",
        "sensorOrientation": 0,
        "hasFlash": false,
        "isLogical": false,
        "physicalDeviceIds": <String>[],
        "focalLengths": <double>[],
        "minFocusDistance": 0.0,
        "formats": <Object?>[],
        "minZoom": 1.0,
        "maxZoom": 1.0,
        "neutralZoom": 1.0,
      });
    }
    return out;
  }

  Future<Map<String, Object?>> _requestPermission(bool audio) async {
    try {
      final web.MediaStream stream = await web.window.navigator.mediaDevices
          .getUserMedia(web.MediaStreamConstraints(video: true.toJS, audio: audio.toJS))
          .toDart;
      for (final web.MediaStreamTrack track in stream.getTracks().toDart) {
        track.stop();
      }
      return <String, Object?>{"camera": "granted", "microphone": audio ? "granted" : "unknown"};
    } catch (_) {
      return <String, Object?>{"camera": "denied", "microphone": "denied"};
    }
  }

  Future<Map<String, Object?>> _create(Map<Object?, Object?> config) async {
    final int id = _nextId++;
    final _WebCameraSession session = _WebCameraSession(id, config, _messenger);
    await session.open();
    _sessions[id] = session;
    return session.describe();
  }

  Future<List<Map<String, Object?>>> _analyzeImage(Map<Object?, Object?> arguments) async {
    if (!_hasBarcodeDetectorApi()) return <Map<String, Object?>>[];
    final Uint8List? bytes = arguments["bytes"] as Uint8List?;
    if (bytes == null) return <Map<String, Object?>>[];
    final web.Blob blob = web.Blob(<JSUint8Array>[bytes.toJS].toJS);
    final web.ImageBitmap bitmap = await web.window.createImageBitmap(blob).toDart;
    return _detect(bitmap as JSObject, const <String>[]);
  }

  static Future<List<Map<String, Object?>>> _detect(JSObject source, List<String> formats) async {
    final List<String> requested = formats.isEmpty ? _allWebFormats : formats.map(_toWebFormat).where((String name) => name.isNotEmpty).toList(growable: false);
    final _JsBarcodeDetector detector = _JsBarcodeDetector(
      _BarcodeDetectorOptions(formats: requested.map((String name) => name.toJS).toList(growable: false).toJS),
    );
    try {
      final JSArray<JSObject> found = await detector.detect(source).toDart;
      final List<Map<String, Object?>> out = <Map<String, Object?>>[];
      for (int i = 0; i < found.length; i++) {
        final _JsDetectedBarcode barcode = found[i] as _JsDetectedBarcode;
        out.add(<String, Object?>{
          "format": _fromWebFormat(barcode.format),
          "text": barcode.rawValue,
          "bytes": Uint8List.fromList(barcode.rawValue.codeUnits),
          "corners": <Object?>[],
          "inverted": false,
        });
      }
      return out;
    } catch (_) {
      return <Map<String, Object?>>[];
    }
  }

  static const List<String> _allWebFormats = <String>[
    "qr_code", "data_matrix", "aztec", "pdf417", "code_128", "code_39", "code_93", "codabar", "itf", "ean_13", "ean_8", "upc_a", "upc_e",
  ];

  static String _toWebFormat(String name) {
    switch (name) {
      case "qr":
        return "qr_code";
      case "dataMatrix":
        return "data_matrix";
      case "aztec":
        return "aztec";
      case "pdf417":
        return "pdf417";
      case "code128":
        return "code_128";
      case "code39":
        return "code_39";
      case "code93":
        return "code_93";
      case "codabar":
        return "codabar";
      case "itf":
        return "itf";
      case "ean13":
        return "ean_13";
      case "ean8":
        return "ean_8";
      case "upcA":
        return "upc_a";
      case "upcE":
        return "upc_e";
      default:
        return "";
    }
  }

  static String _fromWebFormat(String name) {
    switch (name) {
      case "qr_code":
        return "qr";
      case "data_matrix":
        return "dataMatrix";
      case "code_128":
        return "code128";
      case "code_39":
        return "code39";
      case "code_93":
        return "code93";
      case "ean_13":
        return "ean13";
      case "ean_8":
        return "ean8";
      case "upc_a":
        return "upcA";
      case "upc_e":
        return "upcE";
      default:
        return name;
    }
  }
}

class _WebCameraSession {
  _WebCameraSession(this.id, this.config, this._messenger) {
    viewType = "u-camera-$id";
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) => _video);
    _eventChannelName = "u/camera/events/$id";
    _frameChannelName = "u/camera/frames/$id";
    MethodChannel(_eventChannelName, const StandardMethodCodec(), _messenger).setMethodCallHandler(_handleStream);
    MethodChannel(_frameChannelName, const StandardMethodCodec(), _messenger).setMethodCallHandler(_handleStream);
  }

  final int id;
  final Map<Object?, Object?> config;
  final BinaryMessenger _messenger;

  late final String viewType;
  late final String _eventChannelName;
  late final String _frameChannelName;

  final web.HTMLVideoElement _video = web.HTMLVideoElement()
    ..autoplay = true
    ..muted = true
    ..setAttribute("playsinline", "true")
    ..style.objectFit = "cover"
    ..style.width = "100%"
    ..style.height = "100%";

  web.MediaStream? _stream;
  web.MediaRecorder? _recorder;
  final List<web.Blob> _chunks = <web.Blob>[];
  String? _recordingUrl;
  DateTime? _recordingStartedAt;

  web.HTMLCanvasElement? _canvas;
  Timer? _frameTimer;
  Timer? _scanTimer;
  bool _scanning = false;
  List<String> _scanFormats = const <String>[];

  static Future<Object?> _handleStream(MethodCall call) async => null;

  /// Pushes an EventChannel payload into the framework, which is how a web
  /// plugin emits stream events.
  void _push(String channel, Map<String, Object?> payload) {
    final ByteData encoded = const StandardMethodCodec().encodeSuccessEnvelope(payload);
    ServicesBinding.instance.channelBuffers.push(channel, encoded, (ByteData? _) {});
  }

  int get _width => _video.videoWidth;

  int get _height => _video.videoHeight;

  Future<void> open() async {
    final String? deviceId = config["deviceId"] as String?;
    final String facing = (config["facing"] as String?) ?? "back";
    final Map<String, Object?> video = <String, Object?>{
      if (deviceId != null && deviceId.isNotEmpty) "deviceId": <String, Object?>{"exact": deviceId},
      if (deviceId == null || deviceId.isEmpty) "facingMode": facing == "front" ? "user" : "environment",
      ..._resolutionConstraints(),
    };
    final web.MediaStreamConstraints constraints = web.MediaStreamConstraints(
      video: video.jsify()!,
      audio: (config["enableAudio"] == true).toJS,
    );
    _stream = await web.window.navigator.mediaDevices.getUserMedia(constraints).toDart;
    _video.srcObject = _stream;
    await _video.play().toDart;
    await _waitForMetadata();
  }

  Map<String, Object?> _resolutionConstraints() {
    switch (config["resolution"] as String?) {
      case "low":
        return <String, Object?>{"width": 320, "height": 240};
      case "medium":
        return <String, Object?>{"width": 640, "height": 480};
      case "veryHigh":
        return <String, Object?>{"width": 1920, "height": 1080};
      case "ultraHigh":
      case "max":
        return <String, Object?>{"width": 3840, "height": 2160};
      default:
        return <String, Object?>{"width": 1280, "height": 720};
    }
  }

  Future<void> _waitForMetadata() async {
    for (int attempt = 0; attempt < 100 && _video.videoWidth == 0; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  Map<String, Object?> describe() => <String, Object?>{
    "sessionId": id,
    "textureId": null,
    "viewType": viewType,
    "previewSize": <String, Object?>{"width": _width, "height": _height},
    "sensorOrientation": 0,
    "mirrored": (config["facing"] as String?) == "front" && config["mirrorFrontPreview"] != false,
    "zoom": 1.0,
    "device": <String, Object?>{
      "id": config["deviceId"] ?? "",
      "name": "Browser camera",
      "facing": config["facing"] ?? "back",
      "lens": "wide",
      "sensorOrientation": 0,
      "hasFlash": _torchSupported,
      "minZoom": 1.0,
      "maxZoom": 1.0,
    },
    "capabilities": <String, Object?>{
      "flash": _torchSupported,
      "torch": _torchSupported,
      "zoom": _range(1, 1, supported: false),
      "exposureOffset": _range(0, 0, supported: false),
      "iso": _range(0, 0, supported: false),
      "exposureDuration": _range(0, 0, supported: false),
      "focusDistance": _range(0, 0, supported: false),
      "temperature": _range(0, 0, supported: false),
      "focusPoint": false,
      "exposurePoint": false,
      "manualFocus": false,
      "manualExposure": false,
      "whiteBalance": false,
      "stabilization": <String>[],
      "hdr": false,
      "nightMode": false,
      "rawCapture": false,
      "depthCapture": false,
      "videoRecording": true,
      "pauseRecording": true,
      "audioRecording": true,
      "imageStream": true,
      "platformScanning": UCameraWeb._hasBarcodeDetector,
      "multiCamera": false,
      "pictureInPicture": true,
      "lensSwitching": false,
      "orientationLock": false,
      "snapshot": true,
      "videoCodecs": <String>["vp8", "vp9"],
      "photoFormats": <String>["jpeg", "png", "webp"],
      "frameFormats": <String>["rgba8888", "gray8"],
      "maxFps": 60.0,
    },
  };

  bool get _torchSupported {
    final web.MediaStreamTrack? track = _videoTrack;
    if (track == null) return false;
    final JSObject capabilities = track.getCapabilities() as JSObject;
    return capabilities.hasProperty("torch".toJS).toDart;
  }

  web.MediaStreamTrack? get _videoTrack {
    final JSArray<web.MediaStreamTrack>? tracks = _stream?.getVideoTracks();
    if (tracks == null || tracks.length == 0) return null;
    return tracks[0];
  }

  Map<String, Object?> _range(double min, double max, {bool supported = true}) =>
      <String, Object?>{"min": min, "max": max, "step": 0.0, "supported": supported};

  Future<void> setTorch(bool on) async {
    final web.MediaStreamTrack? track = _videoTrack;
    if (track == null || !_torchSupported) return;
    final JSObject constraints = JSObject();
    final JSObject advanced = JSObject();
    advanced.setProperty("torch".toJS, on.toJS);
    constraints.setProperty("advanced".toJS, <JSObject>[advanced].toJS);
    await track.applyConstraints(constraints as web.MediaTrackConstraints).toDart;
  }

  Future<void> setZoom(double zoom) async {
    final web.MediaStreamTrack? track = _videoTrack;
    if (track == null) return;
    final JSObject constraints = JSObject();
    final JSObject advanced = JSObject();
    advanced.setProperty("zoom".toJS, zoom.toJS);
    constraints.setProperty("advanced".toJS, <JSObject>[advanced].toJS);
    try {
      await track.applyConstraints(constraints as web.MediaTrackConstraints).toDart;
    } catch (_) {
      // The browser does not expose zoom for this device.
    }
  }

  void setPaused(bool paused) {
    if (paused) {
      _video.pause();
    } else {
      _video.play();
    }
  }

  web.HTMLCanvasElement _ensureCanvas() {
    final web.HTMLCanvasElement canvas = _canvas ?? web.HTMLCanvasElement();
    canvas.width = _width;
    canvas.height = _height;
    _canvas = canvas;
    return canvas;
  }

  Map<String, Object?> capture({required String format, required double quality}) {
    final web.HTMLCanvasElement canvas = _ensureCanvas();
    final web.CanvasRenderingContext2D context = canvas.context2D;
    context.drawImage(_video, 0, 0);
    final String mime = format == "png" ? "image/png" : (format == "webp" ? "image/webp" : "image/jpeg");
    final String url = canvas.toDataURL(mime, quality.toJS);
    final int comma = url.indexOf(",");
    final Uint8List bytes = comma < 0 ? Uint8List(0) : _decodeBase64(url.substring(comma + 1));
    return <String, Object?>{
      "path": null,
      "bytes": bytes,
      "width": canvas.width,
      "height": canvas.height,
      "format": format == "png" ? "png" : (format == "webp" ? "webp" : "jpeg"),
      "orientation": 0,
      "sizeInBytes": bytes.length,
    };
  }

  static Uint8List _decodeBase64(String data) {
    final String binary = web.window.atob(data);
    final Uint8List bytes = Uint8List(binary.length);
    for (int i = 0; i < binary.length; i++) {
      bytes[i] = binary.codeUnitAt(i);
    }
    return bytes;
  }

  Future<void> startRecording() async {
    final web.MediaStream? stream = _stream;
    if (stream == null || _recorder != null) return;
    _chunks.clear();
    final web.MediaRecorder recorder = web.MediaRecorder(stream);
    recorder.ondataavailable = (web.BlobEvent event) {
      if (event.data.size > 0) _chunks.add(event.data);
    }.toJS;
    recorder.start();
    _recorder = recorder;
    _recordingStartedAt = DateTime.now();
  }

  void pauseRecording() => _recorder?.pause();

  void resumeRecording() => _recorder?.resume();

  Future<Map<String, Object?>?> stopRecording() async {
    final web.MediaRecorder? recorder = _recorder;
    if (recorder == null) return null;
    final Completer<void> completer = Completer<void>();
    recorder.onstop = (web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }.toJS;
    recorder.stop();
    await completer.future;
    _recorder = null;

    final web.Blob blob = web.Blob(_chunks.toJS, web.BlobPropertyBag(type: "video/webm"));
    _recordingUrl = web.URL.createObjectURL(blob);
    final DateTime? startedAt = _recordingStartedAt;
    _recordingStartedAt = null;
    final JSArrayBuffer buffer = await blob.arrayBuffer().toDart;
    return <String, Object?>{
      "path": _recordingUrl,
      "durationMs": startedAt == null ? 0 : DateTime.now().difference(startedAt).inMilliseconds,
      "width": _width,
      "height": _height,
      "sizeInBytes": blob.size,
      "container": "webm",
      "bytes": buffer.toDart.asUint8List(),
    };
  }

  void startImageStream(double maxFps) {
    _frameTimer?.cancel();
    final int periodMs = (1000 / (maxFps <= 0 ? 12 : maxFps)).round();
    _frameTimer = Timer.periodic(Duration(milliseconds: periodMs), (Timer _) => _emitFrame());
  }

  void stopImageStream() {
    _frameTimer?.cancel();
    _frameTimer = null;
  }

  void startScanning(Map<Object?, Object?> options) {
    final Object? rawFormats = options["formats"];
    _scanFormats = rawFormats is List<Object?> ? rawFormats.whereType<String>().toList(growable: false) : const <String>[];
    _scanning = true;
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(milliseconds: 150), (Timer _) => _scanOnce());
  }

  void stopScanning() {
    _scanning = false;
    _scanTimer?.cancel();
    _scanTimer = null;
  }

  Future<void> _scanOnce() async {
    if (!_scanning || !UCameraWeb._hasBarcodeDetector || _width == 0) return;
    final List<Map<String, Object?>> codes = await UCameraWeb._detect(_video as JSObject, _scanFormats);
    if (codes.isEmpty) return;
    _push(_eventChannelName, <String, Object?>{"event": "codes", "codes": codes});
  }

  void _emitFrame() {
    if (_width == 0 || _height == 0) return;
    final web.HTMLCanvasElement canvas = _ensureCanvas();
    final web.CanvasRenderingContext2D context = canvas.context2D;
    context.drawImage(_video, 0, 0);
    final web.ImageData data = context.getImageData(0, 0, _width, _height);
    final Uint8List rgba = data.data.toDart.buffer.asUint8List();
    final Uint8List gray = Uint8List(_width * _height);
    for (int i = 0; i < gray.length; i++) {
      gray[i] = (rgba[i * 4] * 77 + rgba[i * 4 + 1] * 151 + rgba[i * 4 + 2] * 28) >> 8;
    }
    _push(_frameChannelName, <String, Object?>{
      "planes": <Uint8List>[gray],
      "format": "gray8",
      "width": _width,
      "height": _height,
      "rowStrides": <int>[_width],
      "pixelStrides": <int>[1],
      "rotation": 0,
      "mirrored": false,
    });
  }

  void dispose() {
    stopImageStream();
    stopScanning();
    _recorder?.stop();
    _recorder = null;
    final web.MediaStream? stream = _stream;
    if (stream != null) {
      for (final web.MediaStreamTrack track in stream.getTracks().toDart) {
        track.stop();
      }
    }
    _stream = null;
    _video.srcObject = null;
    final String? url = _recordingUrl;
    if (url != null) web.URL.revokeObjectURL(url);
  }
}
