import "dart:isolate";

import "package:u/utilities.dart";

// =============================================================================
// u_camera_platform — the native camera layer of the `u` plugin.
//
// One method channel per process plus one event channel per session, backed by
// Camera2 on Android, AVFoundation on iOS/macOS, Media Foundation on Windows,
// V4L2/GStreamer on Linux and getUserMedia on the web. Everything the six
// platforms can do is exposed here; [UCameraCapabilities] says what the current
// device actually supports so UI can hide the rest.
//
// Nothing in this file needs reading to use the package — the surface is
// [UCameraController], [UCameraConfig] and [UCameraValue].
// =============================================================================

enum UCameraFacing { back, front, external, unspecified }

enum UCameraLens { wide, ultraWide, telephoto, macro, depth, infrared, unknown }

enum UFlashMode { off, auto, on, torch }

enum UFocusMode { auto, continuousPicture, continuousVideo, macro, manual, locked, infinity }

enum UExposureMode { auto, locked, manual, continuous }

enum UWhiteBalanceMode { auto, incandescent, fluorescent, warmFluorescent, daylight, cloudy, twilight, shade, manual, locked }

/// Preview / capture resolution presets, resolved to the closest supported size.
enum UCameraResolution { low, medium, high, veryHigh, ultraHigh, max }

enum UVideoCodec { auto, h264, hevc, vp8, vp9, av1 }

enum UAudioCodec { auto, aac, opus, pcm, amrNb }

enum UVideoContainer { mp4, mov, webm, mkv }

enum UPhotoFormat { jpeg, png, heic, webp, raw }

enum UStabilizationMode { off, standard, cinematic, cinematicExtended, auto }

enum UHdrMode { off, on, auto }

enum UNightMode { off, on, auto }

enum UFrameFormat { nv21, yuv420, bgra8888, rgba8888, gray8, jpeg }

enum UCameraPermission { granted, denied, permanentlyDenied, restricted, unknown }

enum UCameraState { uninitialized, initializing, ready, capturing, recording, recordingPaused, previewPaused, error, disposed }

enum UCameraErrorCode { permission, notFound, inUse, configuration, capture, recording, unsupported, disconnected, timeout, storage, unknown }

/// How barcode decoding is performed for a session.
enum UScanEngine {
  /// Platform decoder where one is free (Apple Vision, browser BarcodeDetector),
  /// otherwise the bundled Dart engine.
  auto,

  /// Always use the bundled Dart engine — identical results on all platforms.
  dart,

  /// Only use the platform decoder; yields nothing where none exists.
  platform,
}

enum UCameraOrientation { portraitUp, landscapeRight, portraitDown, landscapeLeft }

extension UCameraOrientationX on UCameraOrientation {
  int get degrees {
    switch (this) {
      case UCameraOrientation.portraitUp:
        return 0;
      case UCameraOrientation.landscapeRight:
        return 90;
      case UCameraOrientation.portraitDown:
        return 180;
      case UCameraOrientation.landscapeLeft:
        return 270;
    }
  }

  static UCameraOrientation fromDegrees(int degrees) {
    switch (((degrees % 360) + 360) % 360) {
      case 90:
        return UCameraOrientation.landscapeRight;
      case 180:
        return UCameraOrientation.portraitDown;
      case 270:
        return UCameraOrientation.landscapeLeft;
      default:
        return UCameraOrientation.portraitUp;
    }
  }
}

class UCameraException implements Exception {
  const UCameraException({required this.code, required this.message, this.detail, this.platformCode});

  final UCameraErrorCode code;
  final String message;
  final String? detail;
  final String? platformCode;

  bool get isRecoverable => code == UCameraErrorCode.inUse || code == UCameraErrorCode.timeout || code == UCameraErrorCode.disconnected;

  factory UCameraException.fromMap(Map<Object?, Object?> map) => UCameraException(
    code: UCameraErrorCode.values.firstWhere((UCameraErrorCode c) => c.name == map["code"], orElse: () => UCameraErrorCode.unknown),
    message: (map["message"] as String?) ?? "",
    detail: map["detail"] as String?,
    platformCode: map["platformCode"] as String?,
  );

  factory UCameraException.fromPlatform(PlatformException error) => UCameraException(
    code: UCameraErrorCode.values.firstWhere((UCameraErrorCode c) => c.name == error.code, orElse: () => UCameraErrorCode.unknown),
    message: error.message ?? error.code,
    detail: error.details?.toString(),
    platformCode: error.code,
  );

  @override
  String toString() => "UCameraException(${code.name}): $message${detail == null ? "" : " — $detail"}";
}

/// A numeric capability range. [supported] is false when the platform cannot
/// change the value at all.
class UCameraRange {
  const UCameraRange(this.min, this.max, {this.step = 0, this.supported = true});

  final double min;
  final double max;
  final double step;
  final bool supported;

  static const UCameraRange unsupported = UCameraRange(0, 0, supported: false);

  double clamp(double value) => value < min ? min : (value > max ? max : value);

  bool get isFixed => !supported || max <= min;

  factory UCameraRange.fromMap(Object? raw) {
    if (raw is! Map<Object?, Object?>) return unsupported;
    return UCameraRange(
      ((raw["min"] as num?) ?? 0).toDouble(),
      ((raw["max"] as num?) ?? 0).toDouble(),
      step: ((raw["step"] as num?) ?? 0).toDouble(),
      supported: raw["supported"] != false,
    );
  }

  @override
  String toString() => supported ? "$min..$max" : "unsupported";
}

class UCameraSize {
  const UCameraSize(this.width, this.height);

  final int width;
  final int height;

  double get aspectRatio => height == 0 ? 1 : width / height;

  int get pixels => width * height;

  Size get size => Size(width.toDouble(), height.toDouble());

  factory UCameraSize.fromMap(Object? raw) {
    if (raw is! Map<Object?, Object?>) return const UCameraSize(0, 0);
    return UCameraSize(((raw["width"] as num?) ?? 0).toInt(), ((raw["height"] as num?) ?? 0).toInt());
  }

  Map<String, Object?> toMap() => <String, Object?>{"width": width, "height": height};

  @override
  String toString() => "${width}x$height";
}

/// One selectable output configuration reported by the device.
class UCameraFormat {
  const UCameraFormat({required this.size, this.minFps = 0, this.maxFps = 0, this.isHighSpeed = false, this.supportsHdr = false, this.supportsDepth = false});

  final UCameraSize size;
  final double minFps;
  final double maxFps;
  final bool isHighSpeed;
  final bool supportsHdr;
  final bool supportsDepth;

  factory UCameraFormat.fromMap(Map<Object?, Object?> map) => UCameraFormat(
    size: UCameraSize.fromMap(map["size"] ?? map),
    minFps: ((map["minFps"] as num?) ?? 0).toDouble(),
    maxFps: ((map["maxFps"] as num?) ?? 0).toDouble(),
    isHighSpeed: map["highSpeed"] == true,
    supportsHdr: map["hdr"] == true,
    supportsDepth: map["depth"] == true,
  );

  @override
  String toString() => "$size @${maxFps.toStringAsFixed(0)}fps";
}

class UCameraDevice {
  const UCameraDevice({
    required this.id,
    required this.name,
    required this.facing,
    this.lens = UCameraLens.unknown,
    this.sensorOrientation = 0,
    this.hasFlash = false,
    this.isLogical = false,
    this.physicalDeviceIds = const <String>[],
    this.focalLengths = const <double>[],
    this.minFocusDistance = 0,
    this.formats = const <UCameraFormat>[],
    this.minZoom = 1,
    this.maxZoom = 1,
    this.neutralZoom = 1,
  });

  final String id;
  final String name;
  final UCameraFacing facing;
  final UCameraLens lens;

  /// Clockwise rotation, in degrees, from the sensor to the device's natural
  /// orientation.
  final int sensorOrientation;
  final bool hasFlash;

  /// True for a multi-camera virtual device that switches lenses by zoom.
  final bool isLogical;
  final List<String> physicalDeviceIds;
  final List<double> focalLengths;
  final double minFocusDistance;
  final List<UCameraFormat> formats;
  final double minZoom;
  final double maxZoom;

  /// Zoom factor where a logical device sits on its main lens.
  final double neutralZoom;

  bool get isFront => facing == UCameraFacing.front;

  UCameraFormat? get largestFormat {
    if (formats.isEmpty) return null;
    UCameraFormat best = formats.first;
    for (final UCameraFormat format in formats) {
      if (format.size.pixels > best.size.pixels) best = format;
    }
    return best;
  }

  factory UCameraDevice.fromMap(Map<Object?, Object?> map) {
    final Object? rawFormats = map["formats"];
    final Object? rawPhysical = map["physicalDeviceIds"];
    final Object? rawFocal = map["focalLengths"];
    return UCameraDevice(
      id: (map["id"] as String?) ?? "",
      name: (map["name"] as String?) ?? "",
      facing: UCameraFacing.values.firstWhere((UCameraFacing f) => f.name == map["facing"], orElse: () => UCameraFacing.unspecified),
      lens: UCameraLens.values.firstWhere((UCameraLens l) => l.name == map["lens"], orElse: () => UCameraLens.unknown),
      sensorOrientation: ((map["sensorOrientation"] as num?) ?? 0).toInt(),
      hasFlash: map["hasFlash"] == true,
      isLogical: map["isLogical"] == true,
      physicalDeviceIds: rawPhysical is List<Object?> ? rawPhysical.whereType<String>().toList(growable: false) : const <String>[],
      focalLengths: rawFocal is List<Object?> ? rawFocal.whereType<num>().map((num v) => v.toDouble()).toList(growable: false) : const <double>[],
      minFocusDistance: ((map["minFocusDistance"] as num?) ?? 0).toDouble(),
      formats: rawFormats is List<Object?> ? rawFormats.whereType<Map<Object?, Object?>>().map(UCameraFormat.fromMap).toList(growable: false) : const <UCameraFormat>[],
      minZoom: ((map["minZoom"] as num?) ?? 1).toDouble(),
      maxZoom: ((map["maxZoom"] as num?) ?? 1).toDouble(),
      neutralZoom: ((map["neutralZoom"] as num?) ?? 1).toDouble(),
    );
  }

  @override
  String toString() => "UCameraDevice($id, ${facing.name}, ${lens.name})";
}

/// What the currently open session can actually do. Drive UI from this rather
/// than from the platform name.
class UCameraCapabilities {
  const UCameraCapabilities({
    this.flash = false,
    this.torch = false,
    this.zoom = UCameraRange.unsupported,
    this.exposureOffset = UCameraRange.unsupported,
    this.iso = UCameraRange.unsupported,
    this.exposureDuration = UCameraRange.unsupported,
    this.focusDistance = UCameraRange.unsupported,
    this.temperature = UCameraRange.unsupported,
    this.focusPoint = false,
    this.exposurePoint = false,
    this.manualFocus = false,
    this.manualExposure = false,
    this.whiteBalance = false,
    this.stabilization = const <UStabilizationMode>[],
    this.hdr = false,
    this.nightMode = false,
    this.rawCapture = false,
    this.depthCapture = false,
    this.videoRecording = false,
    this.pauseRecording = false,
    this.audioRecording = false,
    this.imageStream = false,
    this.platformScanning = false,
    this.multiCamera = false,
    this.pictureInPicture = false,
    this.lensSwitching = false,
    this.orientationLock = false,
    this.snapshot = false,
    this.videoCodecs = const <UVideoCodec>[],
    this.photoFormats = const <UPhotoFormat>[],
    this.frameFormats = const <UFrameFormat>[],
    this.maxPhotoSize,
    this.maxVideoSize,
    this.maxFps = 30,
  });

  final bool flash;
  final bool torch;
  final UCameraRange zoom;
  final UCameraRange exposureOffset;
  final UCameraRange iso;
  final UCameraRange exposureDuration;
  final UCameraRange focusDistance;
  final UCameraRange temperature;
  final bool focusPoint;
  final bool exposurePoint;
  final bool manualFocus;
  final bool manualExposure;
  final bool whiteBalance;
  final List<UStabilizationMode> stabilization;
  final bool hdr;
  final bool nightMode;
  final bool rawCapture;
  final bool depthCapture;
  final bool videoRecording;
  final bool pauseRecording;
  final bool audioRecording;
  final bool imageStream;
  final bool platformScanning;
  final bool multiCamera;
  final bool pictureInPicture;
  final bool lensSwitching;
  final bool orientationLock;
  final bool snapshot;
  final List<UVideoCodec> videoCodecs;
  final List<UPhotoFormat> photoFormats;
  final List<UFrameFormat> frameFormats;
  final UCameraSize? maxPhotoSize;
  final UCameraSize? maxVideoSize;
  final double maxFps;

  static const UCameraCapabilities none = UCameraCapabilities();

  factory UCameraCapabilities.fromMap(Map<Object?, Object?> map) {
    List<T> enums<T extends Enum>(Object? raw, List<T> values) {
      if (raw is! List<Object?>) return <T>[];
      final List<T> out = <T>[];
      for (final String name in raw.whereType<String>()) {
        for (final T candidate in values) {
          if (candidate.name != name) continue;
          out.add(candidate);
          break;
        }
      }
      return out;
    }

    return UCameraCapabilities(
      flash: map["flash"] == true,
      torch: map["torch"] == true,
      zoom: UCameraRange.fromMap(map["zoom"]),
      exposureOffset: UCameraRange.fromMap(map["exposureOffset"]),
      iso: UCameraRange.fromMap(map["iso"]),
      exposureDuration: UCameraRange.fromMap(map["exposureDuration"]),
      focusDistance: UCameraRange.fromMap(map["focusDistance"]),
      temperature: UCameraRange.fromMap(map["temperature"]),
      focusPoint: map["focusPoint"] == true,
      exposurePoint: map["exposurePoint"] == true,
      manualFocus: map["manualFocus"] == true,
      manualExposure: map["manualExposure"] == true,
      whiteBalance: map["whiteBalance"] == true,
      stabilization: enums<UStabilizationMode>(map["stabilization"], UStabilizationMode.values),
      hdr: map["hdr"] == true,
      nightMode: map["nightMode"] == true,
      rawCapture: map["rawCapture"] == true,
      depthCapture: map["depthCapture"] == true,
      videoRecording: map["videoRecording"] == true,
      pauseRecording: map["pauseRecording"] == true,
      audioRecording: map["audioRecording"] == true,
      imageStream: map["imageStream"] == true,
      platformScanning: map["platformScanning"] == true,
      multiCamera: map["multiCamera"] == true,
      pictureInPicture: map["pictureInPicture"] == true,
      lensSwitching: map["lensSwitching"] == true,
      orientationLock: map["orientationLock"] == true,
      snapshot: map["snapshot"] == true,
      videoCodecs: enums<UVideoCodec>(map["videoCodecs"], UVideoCodec.values),
      photoFormats: enums<UPhotoFormat>(map["photoFormats"], UPhotoFormat.values),
      frameFormats: enums<UFrameFormat>(map["frameFormats"], UFrameFormat.values),
      maxPhotoSize: map["maxPhotoSize"] == null ? null : UCameraSize.fromMap(map["maxPhotoSize"]),
      maxVideoSize: map["maxVideoSize"] == null ? null : UCameraSize.fromMap(map["maxVideoSize"]),
      maxFps: ((map["maxFps"] as num?) ?? 30).toDouble(),
    );
  }
}

/// A single analysis frame handed to Dart. [planes] holds one entry for packed
/// formats and three for planar YUV.
class UCameraFrame {
  const UCameraFrame({
    required this.planes,
    required this.format,
    required this.width,
    required this.height,
    this.rowStrides = const <int>[],
    this.pixelStrides = const <int>[],
    this.rotation = 0,
    this.mirrored = false,
    this.timestampUs = 0,
  });

  final List<Uint8List> planes;
  final UFrameFormat format;
  final int width;
  final int height;
  final List<int> rowStrides;
  final List<int> pixelStrides;

  /// Clockwise rotation needed to make the frame upright, in degrees.
  final int rotation;
  final bool mirrored;
  final int timestampUs;

  Uint8List get bytes => planes.isEmpty ? Uint8List(0) : planes.first;

  /// Wraps the luminance data as a grayscale image without copying when the
  /// frame already carries a Y plane.
  UGrayImage toGray() {
    switch (format) {
      case UFrameFormat.nv21:
      case UFrameFormat.yuv420:
      case UFrameFormat.gray8:
        final int stride = rowStrides.isNotEmpty ? rowStrides.first : width;
        return UGrayImage(bytes, width, height, rowStride: stride);
      case UFrameFormat.bgra8888:
        return UGrayImage.fromPacked(bytes, width, height, rowStride: rowStrides.isNotEmpty ? rowStrides.first : 0);
      case UFrameFormat.rgba8888:
        return UGrayImage.fromPacked(bytes, width, height, bgra: false, rowStride: rowStrides.isNotEmpty ? rowStrides.first : 0);
      case UFrameFormat.jpeg:
        return UGrayImage(Uint8List(0), 0, 0);
    }
  }

  factory UCameraFrame.fromMap(Map<Object?, Object?> map) {
    final Object? rawPlanes = map["planes"];
    final Object? rawRowStrides = map["rowStrides"];
    final Object? rawPixelStrides = map["pixelStrides"];
    return UCameraFrame(
      planes: rawPlanes is List<Object?> ? rawPlanes.whereType<Uint8List>().toList(growable: false) : const <Uint8List>[],
      format: UFrameFormat.values.firstWhere((UFrameFormat f) => f.name == map["format"], orElse: () => UFrameFormat.nv21),
      width: ((map["width"] as num?) ?? 0).toInt(),
      height: ((map["height"] as num?) ?? 0).toInt(),
      rowStrides: rawRowStrides is List<Object?> ? rawRowStrides.whereType<num>().map((num v) => v.toInt()).toList(growable: false) : const <int>[],
      pixelStrides: rawPixelStrides is List<Object?> ? rawPixelStrides.whereType<num>().map((num v) => v.toInt()).toList(growable: false) : const <int>[],
      rotation: ((map["rotation"] as num?) ?? 0).toInt(),
      mirrored: map["mirrored"] == true,
      timestampUs: ((map["timestampUs"] as num?) ?? 0).toInt(),
    );
  }
}

class UCapturedPhoto {
  const UCapturedPhoto({
    required this.width,
    required this.height,
    this.path,
    this.bytes,
    this.format = UPhotoFormat.jpeg,
    this.orientation = 0,
    this.mirrored = false,
    this.sizeInBytes = 0,
    this.thumbnail,
    this.metadata = const <String, Object?>{},
  });

  final int width;
  final int height;
  final String? path;
  final Uint8List? bytes;
  final UPhotoFormat format;
  final int orientation;
  final bool mirrored;
  final int sizeInBytes;
  final Uint8List? thumbnail;
  final Map<String, Object?> metadata;

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;

  String get extension {
    switch (format) {
      case UPhotoFormat.jpeg:
        return "jpg";
      case UPhotoFormat.png:
        return "png";
      case UPhotoFormat.heic:
        return "heic";
      case UPhotoFormat.webp:
        return "webp";
      case UPhotoFormat.raw:
        return "dng";
    }
  }

  factory UCapturedPhoto.fromMap(Map<Object?, Object?> map) {
    final Object? rawMetadata = map["metadata"];
    return UCapturedPhoto(
      width: ((map["width"] as num?) ?? 0).toInt(),
      height: ((map["height"] as num?) ?? 0).toInt(),
      path: map["path"] as String?,
      bytes: map["bytes"] as Uint8List?,
      format: UPhotoFormat.values.firstWhere((UPhotoFormat f) => f.name == map["format"], orElse: () => UPhotoFormat.jpeg),
      orientation: ((map["orientation"] as num?) ?? 0).toInt(),
      mirrored: map["mirrored"] == true,
      sizeInBytes: ((map["sizeInBytes"] as num?) ?? 0).toInt(),
      thumbnail: map["thumbnail"] as Uint8List?,
      metadata: rawMetadata is Map<Object?, Object?> ? rawMetadata.map((Object? k, Object? v) => MapEntry<String, Object?>(k.toString(), v)) : const <String, Object?>{},
    );
  }
}

class UCapturedVideo {
  const UCapturedVideo({
    required this.path,
    required this.duration,
    this.width = 0,
    this.height = 0,
    this.sizeInBytes = 0,
    this.container = UVideoContainer.mp4,
    this.bytes,
    this.thumbnail,
  });

  final String path;
  final Duration duration;
  final int width;
  final int height;
  final int sizeInBytes;
  final UVideoContainer container;
  final Uint8List? bytes;
  final Uint8List? thumbnail;

  factory UCapturedVideo.fromMap(Map<Object?, Object?> map) => UCapturedVideo(
    path: (map["path"] as String?) ?? "",
    duration: Duration(milliseconds: ((map["durationMs"] as num?) ?? 0).toInt()),
    width: ((map["width"] as num?) ?? 0).toInt(),
    height: ((map["height"] as num?) ?? 0).toInt(),
    sizeInBytes: ((map["sizeInBytes"] as num?) ?? 0).toInt(),
    container: UVideoContainer.values.firstWhere((UVideoContainer c) => c.name == map["container"], orElse: () => UVideoContainer.mp4),
    bytes: map["bytes"] as Uint8List?,
    thumbnail: map["thumbnail"] as Uint8List?,
  );
}

/// Everything a session configures up front. Values the device cannot honour
/// are ignored rather than failing the session.
class UCameraConfig {
  const UCameraConfig({
    this.facing = UCameraFacing.back,
    this.deviceId,
    this.lens,
    this.resolution = UCameraResolution.high,
    this.photoResolution,
    this.previewSize,
    this.fps,
    this.enableAudio = true,
    this.photoFormat = UPhotoFormat.jpeg,
    this.photoQuality = 92,
    this.videoCodec = UVideoCodec.auto,
    this.audioCodec = UAudioCodec.auto,
    this.videoContainer = UVideoContainer.mp4,
    this.videoBitrate,
    this.audioBitrate,
    this.stabilization = UStabilizationMode.auto,
    this.hdr = UHdrMode.off,
    this.nightMode = UNightMode.off,
    this.flash = UFlashMode.off,
    this.focusMode = UFocusMode.continuousPicture,
    this.exposureMode = UExposureMode.auto,
    this.whiteBalance = UWhiteBalanceMode.auto,
    this.initialZoom,
    this.mirrorFrontPreview = true,
    this.mirrorFrontCapture = false,
    this.lockOrientation,
    this.imageStream = false,
    this.frameFormat = UFrameFormat.nv21,
    this.frameMaxFps = 12,
    this.frameDownscale = 1,
    this.scanning = false,
    this.scanEngine = UScanEngine.auto,
    this.scanOptions = const UCodeScanOptions(),
    this.scanInterval = const Duration(milliseconds: 120),
    this.scanDedupeWindow = const Duration(milliseconds: 1500),
    this.maxRecordingDuration,
    this.maxRecordingBytes,
    this.saveToGallery = false,
    this.outputDirectory,
    this.keepScreenOn = true,
    this.playShutterSound = false,
  });

  final UCameraFacing facing;

  /// Overrides [facing] and [lens] when set.
  final String? deviceId;
  final UCameraLens? lens;
  final UCameraResolution resolution;

  /// Falls back to [resolution] when null.
  final UCameraResolution? photoResolution;
  final UCameraSize? previewSize;
  final double? fps;
  final bool enableAudio;
  final UPhotoFormat photoFormat;
  final int photoQuality;
  final UVideoCodec videoCodec;
  final UAudioCodec audioCodec;
  final UVideoContainer videoContainer;
  final int? videoBitrate;
  final int? audioBitrate;
  final UStabilizationMode stabilization;
  final UHdrMode hdr;
  final UNightMode nightMode;
  final UFlashMode flash;
  final UFocusMode focusMode;
  final UExposureMode exposureMode;
  final UWhiteBalanceMode whiteBalance;
  final double? initialZoom;
  final bool mirrorFrontPreview;
  final bool mirrorFrontCapture;
  final UCameraOrientation? lockOrientation;

  /// Deliver analysis frames to [UCameraController.frames].
  final bool imageStream;
  final UFrameFormat frameFormat;
  final double frameMaxFps;

  /// Integer downscale applied natively before frames reach Dart.
  final int frameDownscale;

  /// Start barcode scanning as soon as the session is ready.
  final bool scanning;
  final UScanEngine scanEngine;
  final UCodeScanOptions scanOptions;
  final Duration scanInterval;
  final Duration scanDedupeWindow;
  final Duration? maxRecordingDuration;
  final int? maxRecordingBytes;
  final bool saveToGallery;
  final String? outputDirectory;
  final bool keepScreenOn;
  final bool playShutterSound;

  bool get needsFrames => imageStream || scanning;

  UCameraConfig copyWith({
    UCameraFacing? facing,
    String? deviceId,
    UCameraLens? lens,
    UCameraResolution? resolution,
    double? fps,
    bool? enableAudio,
    UFlashMode? flash,
    UFocusMode? focusMode,
    double? initialZoom,
    bool? imageStream,
    bool? scanning,
    UScanEngine? scanEngine,
    UCodeScanOptions? scanOptions,
    UFrameFormat? frameFormat,
    double? frameMaxFps,
    UCameraOrientation? lockOrientation,
    bool? mirrorFrontPreview,
    UStabilizationMode? stabilization,
    UHdrMode? hdr,
    UNightMode? nightMode,
  }) => UCameraConfig(
    facing: facing ?? this.facing,
    deviceId: deviceId ?? this.deviceId,
    lens: lens ?? this.lens,
    resolution: resolution ?? this.resolution,
    photoResolution: photoResolution,
    previewSize: previewSize,
    fps: fps ?? this.fps,
    enableAudio: enableAudio ?? this.enableAudio,
    photoFormat: photoFormat,
    photoQuality: photoQuality,
    videoCodec: videoCodec,
    audioCodec: audioCodec,
    videoContainer: videoContainer,
    videoBitrate: videoBitrate,
    audioBitrate: audioBitrate,
    stabilization: stabilization ?? this.stabilization,
    hdr: hdr ?? this.hdr,
    nightMode: nightMode ?? this.nightMode,
    flash: flash ?? this.flash,
    focusMode: focusMode ?? this.focusMode,
    exposureMode: exposureMode,
    whiteBalance: whiteBalance,
    initialZoom: initialZoom ?? this.initialZoom,
    mirrorFrontPreview: mirrorFrontPreview ?? this.mirrorFrontPreview,
    mirrorFrontCapture: mirrorFrontCapture,
    lockOrientation: lockOrientation ?? this.lockOrientation,
    imageStream: imageStream ?? this.imageStream,
    frameFormat: frameFormat ?? this.frameFormat,
    frameMaxFps: frameMaxFps ?? this.frameMaxFps,
    frameDownscale: frameDownscale,
    scanning: scanning ?? this.scanning,
    scanEngine: scanEngine ?? this.scanEngine,
    scanOptions: scanOptions ?? this.scanOptions,
    scanInterval: scanInterval,
    scanDedupeWindow: scanDedupeWindow,
    maxRecordingDuration: maxRecordingDuration,
    maxRecordingBytes: maxRecordingBytes,
    saveToGallery: saveToGallery,
    outputDirectory: outputDirectory,
    keepScreenOn: keepScreenOn,
    playShutterSound: playShutterSound,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    "facing": facing.name,
    "deviceId": deviceId,
    "lens": lens?.name,
    "resolution": resolution.name,
    "photoResolution": (photoResolution ?? resolution).name,
    "previewSize": previewSize?.toMap(),
    "fps": fps,
    "enableAudio": enableAudio,
    "photoFormat": photoFormat.name,
    "photoQuality": photoQuality,
    "videoCodec": videoCodec.name,
    "audioCodec": audioCodec.name,
    "videoContainer": videoContainer.name,
    "videoBitrate": videoBitrate,
    "audioBitrate": audioBitrate,
    "stabilization": stabilization.name,
    "hdr": hdr.name,
    "nightMode": nightMode.name,
    "flash": flash.name,
    "focusMode": focusMode.name,
    "exposureMode": exposureMode.name,
    "whiteBalance": whiteBalance.name,
    "initialZoom": initialZoom,
    "mirrorFrontPreview": mirrorFrontPreview,
    "mirrorFrontCapture": mirrorFrontCapture,
    "lockOrientation": lockOrientation?.name,
    "imageStream": needsFrames,
    "frameFormat": frameFormat.name,
    "frameMaxFps": frameMaxFps,
    "frameDownscale": frameDownscale,
    "scanning": scanning,
    "scanEngine": scanEngine.name,
    "scanOptions": scanOptions.toMap(),
    "maxRecordingDurationMs": maxRecordingDuration?.inMilliseconds,
    "maxRecordingBytes": maxRecordingBytes,
    "saveToGallery": saveToGallery,
    "outputDirectory": outputDirectory,
    "keepScreenOn": keepScreenOn,
    "playShutterSound": playShutterSound,
  };
}

/// Immutable snapshot of a session, exposed through [UCameraController.value].
class UCameraValue {
  const UCameraValue({
    this.state = UCameraState.uninitialized,
    this.device,
    this.capabilities = UCameraCapabilities.none,
    this.previewSize = const UCameraSize(0, 0),
    this.textureId,
    this.viewType,
    this.sensorOrientation = 0,
    this.deviceOrientation = UCameraOrientation.portraitUp,
    this.lockedOrientation,
    this.flash = UFlashMode.off,
    this.torchOn = false,
    this.zoom = 1,
    this.exposureOffset = 0,
    this.exposureMode = UExposureMode.auto,
    this.focusMode = UFocusMode.continuousPicture,
    this.whiteBalance = UWhiteBalanceMode.auto,
    this.iso,
    this.exposureDuration,
    this.stabilization = UStabilizationMode.auto,
    this.hdr = UHdrMode.off,
    this.nightMode = UNightMode.off,
    this.recordingDuration = Duration.zero,
    this.recordingBytes = 0,
    this.isStreamingFrames = false,
    this.isScanning = false,
    this.mirrored = false,
    this.focusPoint,
    this.error,
  });

  final UCameraState state;
  final UCameraDevice? device;
  final UCameraCapabilities capabilities;
  final UCameraSize previewSize;
  final int? textureId;

  /// Platform view identifier used instead of a texture on the web.
  final String? viewType;
  final int sensorOrientation;
  final UCameraOrientation deviceOrientation;
  final UCameraOrientation? lockedOrientation;
  final UFlashMode flash;
  final bool torchOn;
  final double zoom;
  final double exposureOffset;
  final UExposureMode exposureMode;
  final UFocusMode focusMode;
  final UWhiteBalanceMode whiteBalance;
  final double? iso;
  final Duration? exposureDuration;
  final UStabilizationMode stabilization;
  final UHdrMode hdr;
  final UNightMode nightMode;
  final Duration recordingDuration;
  final int recordingBytes;
  final bool isStreamingFrames;
  final bool isScanning;
  final bool mirrored;

  /// Last tap-to-focus point in normalized preview coordinates.
  final Offset? focusPoint;
  final UCameraException? error;

  bool get isInitialized => state != UCameraState.uninitialized && state != UCameraState.initializing && state != UCameraState.disposed && error == null;

  bool get isRecording => state == UCameraState.recording || state == UCameraState.recordingPaused;

  bool get isRecordingPaused => state == UCameraState.recordingPaused;

  bool get isPreviewPaused => state == UCameraState.previewPaused;

  bool get hasError => error != null;

  double get aspectRatio => previewSize.aspectRatio;

  UCameraValue copyWith({
    UCameraState? state,
    UCameraDevice? device,
    UCameraCapabilities? capabilities,
    UCameraSize? previewSize,
    int? textureId,
    String? viewType,
    int? sensorOrientation,
    UCameraOrientation? deviceOrientation,
    UCameraOrientation? lockedOrientation,
    UFlashMode? flash,
    bool? torchOn,
    double? zoom,
    double? exposureOffset,
    UExposureMode? exposureMode,
    UFocusMode? focusMode,
    UWhiteBalanceMode? whiteBalance,
    double? iso,
    Duration? exposureDuration,
    UStabilizationMode? stabilization,
    UHdrMode? hdr,
    UNightMode? nightMode,
    Duration? recordingDuration,
    int? recordingBytes,
    bool? isStreamingFrames,
    bool? isScanning,
    bool? mirrored,
    Offset? focusPoint,
    UCameraException? error,
    bool clearError = false,
    bool clearFocusPoint = false,
    bool clearTexture = false,
  }) => UCameraValue(
    state: state ?? this.state,
    device: device ?? this.device,
    capabilities: capabilities ?? this.capabilities,
    previewSize: previewSize ?? this.previewSize,
    textureId: clearTexture ? null : (textureId ?? this.textureId),
    viewType: clearTexture ? null : (viewType ?? this.viewType),
    sensorOrientation: sensorOrientation ?? this.sensorOrientation,
    deviceOrientation: deviceOrientation ?? this.deviceOrientation,
    lockedOrientation: lockedOrientation ?? this.lockedOrientation,
    flash: flash ?? this.flash,
    torchOn: torchOn ?? this.torchOn,
    zoom: zoom ?? this.zoom,
    exposureOffset: exposureOffset ?? this.exposureOffset,
    exposureMode: exposureMode ?? this.exposureMode,
    focusMode: focusMode ?? this.focusMode,
    whiteBalance: whiteBalance ?? this.whiteBalance,
    iso: iso ?? this.iso,
    exposureDuration: exposureDuration ?? this.exposureDuration,
    stabilization: stabilization ?? this.stabilization,
    hdr: hdr ?? this.hdr,
    nightMode: nightMode ?? this.nightMode,
    recordingDuration: recordingDuration ?? this.recordingDuration,
    recordingBytes: recordingBytes ?? this.recordingBytes,
    isStreamingFrames: isStreamingFrames ?? this.isStreamingFrames,
    isScanning: isScanning ?? this.isScanning,
    mirrored: mirrored ?? this.mirrored,
    focusPoint: clearFocusPoint ? null : (focusPoint ?? this.focusPoint),
    error: clearError ? null : (error ?? this.error),
  );
}

// =============================================================================
// Channels
// =============================================================================

abstract class UCameraChannel {
  static const MethodChannel _channel = MethodChannel("u/camera");

  static Future<T?> invoke<T>(String method, [Map<String, Object?>? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw UCameraException.fromPlatform(error);
    } on MissingPluginException {
      throw const UCameraException(code: UCameraErrorCode.unsupported, message: "Camera is not available on this platform");
    }
  }

  static Future<List<Object?>?> invokeList(String method, [Map<String, Object?>? arguments]) => invoke<List<Object?>>(method, arguments);

  static Future<Map<Object?, Object?>?> invokeMap(String method, [Map<String, Object?>? arguments]) => invoke<Map<Object?, Object?>>(method, arguments);

  static Stream<Map<Object?, Object?>> events(int sessionId) =>
      EventChannel("u/camera/events/$sessionId").receiveBroadcastStream().map((Object? event) => (event as Map<Object?, Object?>?) ?? const <Object?, Object?>{});

  static Stream<Map<Object?, Object?>> frames(int sessionId) =>
      EventChannel("u/camera/frames/$sessionId").receiveBroadcastStream().map((Object? event) => (event as Map<Object?, Object?>?) ?? const <Object?, Object?>{});

  /// True when the host platform implements the native camera at all.
  static Future<bool> isSupported() async {
    try {
      return await invoke<bool>("isSupported") ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// Decodes frames off the UI isolate. One worker is shared by every controller.
abstract class UCodeScanWorker {
  static Isolate? _isolate;
  static SendPort? _port;
  static Completer<void>? _starting;
  static final Map<int, Completer<List<UCode>>> _pending = <int, Completer<List<UCode>>>{};
  static int _nextJob = 1;

  static Future<void> _ensureStarted() async {
    if (_port != null) return;
    final Completer<void>? starting = _starting;
    if (starting != null) return starting.future;

    final Completer<void> completer = Completer<void>();
    _starting = completer;
    final ReceivePort receive = ReceivePort();
    _isolate = await Isolate.spawn(_entry, receive.sendPort, debugName: "u-code-scanner");
    receive.listen((Object? message) {
      if (message is SendPort) {
        _port = message;
        if (!completer.isCompleted) completer.complete();
        return;
      }
      if (message is! Map<Object?, Object?>) return;
      final int job = (message["job"] as num?)?.toInt() ?? 0;
      final Completer<List<UCode>>? pending = _pending.remove(job);
      if (pending == null) return;
      final Object? raw = message["codes"];
      final List<UCode> codes = raw is List<Object?> ? raw.whereType<Map<Object?, Object?>>().map(UCode.fromMap).toList(growable: false) : const <UCode>[];
      pending.complete(codes);
    });
    await completer.future;
    _starting = null;
  }

  /// Decodes a grayscale buffer in the worker isolate.
  static Future<List<UCode>> decode(Uint8List gray, int width, int height, int rowStride, UCodeScanOptions options) async {
    await _ensureStarted();
    final SendPort? port = _port;
    if (port == null) return const <UCode>[];
    final int job = _nextJob++;
    final Completer<List<UCode>> completer = Completer<List<UCode>>();
    _pending[job] = completer;
    port.send(<String, Object?>{
      "job": job,
      "gray": gray,
      "width": width,
      "height": height,
      "rowStride": rowStride,
      "options": options.toMap(),
    });
    return completer.future;
  }

  static Future<void> shutdown() async {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _port = null;
    _pending.clear();
  }

  static void _entry(SendPort reply) {
    final ReceivePort receive = ReceivePort();
    reply.send(receive.sendPort);
    receive.listen((Object? message) {
      if (message is! Map<Object?, Object?>) return;
      final int job = (message["job"] as num?)?.toInt() ?? 0;
      final Uint8List gray = (message["gray"] as Uint8List?) ?? Uint8List(0);
      final int width = (message["width"] as num?)?.toInt() ?? 0;
      final int height = (message["height"] as num?)?.toInt() ?? 0;
      final int rowStride = (message["rowStride"] as num?)?.toInt() ?? 0;
      final UCodeScanOptions options = UCodeScanOptions.fromMap((message["options"] as Map<Object?, Object?>?) ?? const <Object?, Object?>{});
      List<UCode> codes;
      try {
        codes = UCodeReader.decode(UGrayImage(gray, width, height, rowStride: rowStride), options);
      } catch (_) {
        codes = const <UCode>[];
      }
      reply.send(<String, Object?>{"job": job, "codes": codes.map((UCode code) => code.toMap()).toList(growable: false)});
    });
  }
}

// =============================================================================
// Controller
// =============================================================================

/// Drives one native camera session. Create it, [initialize] it, hand
/// [UCameraValue.textureId] to a `Texture` widget, and dispose it when done.
class UCameraController extends ValueNotifier<UCameraValue> {
  UCameraController({UCameraConfig config = const UCameraConfig()}) : super(const UCameraValue()) {
    _config = config;
  }

  late UCameraConfig _config;
  int? _sessionId;
  StreamSubscription<Map<Object?, Object?>>? _events;
  StreamSubscription<Map<Object?, Object?>>? _frames;
  Timer? _recordingTicker;
  DateTime? _recordingStartedAt;
  Duration _recordedBeforePause = Duration.zero;
  bool _disposed = false;
  bool _decodeBusy = false;
  DateTime _lastScanAt = DateTime.fromMillisecondsSinceEpoch(0);
  final Map<String, DateTime> _recentCodes = <String, DateTime>{};

  final StreamController<UCameraFrame> _frameController = StreamController<UCameraFrame>.broadcast();
  final StreamController<List<UCode>> _codeController = StreamController<List<UCode>>.broadcast();
  final StreamController<UCameraException> _errorController = StreamController<UCameraException>.broadcast();

  UCameraConfig get config => _config;

  int? get sessionId => _sessionId;

  int? get textureId => value.textureId;

  bool get isDisposed => _disposed;

  /// Analysis frames, when [UCameraConfig.imageStream] is on.
  Stream<UCameraFrame> get frames => _frameController.stream;

  /// Barcodes, when scanning is on.
  Stream<List<UCode>> get codes => _codeController.stream;

  Stream<UCameraException> get errors => _errorController.stream;

  /// Codes flattened to one event per new symbol, already de-duplicated.
  Stream<UCode> get singleCodes => _codeController.stream.expand((List<UCode> list) => list);

  // ---------------------------------------------------------------------------
  // Static helpers
  // ---------------------------------------------------------------------------

  static Future<bool> isSupported() => UCameraChannel.isSupported();

  static Future<List<UCameraDevice>> availableCameras() async {
    final List<Object?>? raw = await UCameraChannel.invokeList("availableCameras");
    if (raw == null) return const <UCameraDevice>[];
    return raw.whereType<Map<Object?, Object?>>().map(UCameraDevice.fromMap).toList(growable: false);
  }

  static Future<UCameraPermissionState> permissionStatus() async {
    final Map<Object?, Object?>? raw = await UCameraChannel.invokeMap("permissionStatus");
    return UCameraPermissionState.fromMap(raw ?? const <Object?, Object?>{});
  }

  static Future<UCameraPermissionState> requestPermission({bool audio = false}) async {
    final Map<Object?, Object?>? raw = await UCameraChannel.invokeMap("requestPermission", <String, Object?>{"audio": audio});
    return UCameraPermissionState.fromMap(raw ?? const <Object?, Object?>{});
  }

  /// Opens the OS settings page so the user can grant a permanently denied
  /// permission. Returns false where the platform has no such screen.
  static Future<bool> openSettings() async => await UCameraChannel.invoke<bool>("openSettings") ?? false;

  /// Decodes an image file or byte buffer without opening a camera.
  static Future<List<UCode>> analyzeImage({
    String? path,
    Uint8List? bytes,
    UCodeScanOptions options = const UCodeScanOptions(multiple: true),
    UScanEngine engine = UScanEngine.auto,
  }) async {
    if (path == null && bytes == null) return const <UCode>[];
    if (engine != UScanEngine.dart) {
      try {
        final List<Object?>? raw = await UCameraChannel.invokeList("analyzeImage", <String, Object?>{
          "path": path,
          "bytes": bytes,
          "options": options.toMap(),
        });
        if (raw != null) {
          final List<UCode> codes = raw.whereType<Map<Object?, Object?>>().map(UCode.fromMap).toList(growable: false);
          if (codes.isNotEmpty || engine == UScanEngine.platform) return codes;
        }
      } catch (_) {
        if (engine == UScanEngine.platform) return const <UCode>[];
      }
    }

    final Map<Object?, Object?>? decoded = await UCameraChannel.invokeMap("decodeImageToGray", <String, Object?>{"path": path, "bytes": bytes});
    if (decoded == null) return const <UCode>[];
    final Uint8List gray = (decoded["gray"] as Uint8List?) ?? Uint8List(0);
    if (gray.isEmpty) return const <UCode>[];
    return UCodeScanWorker.decode(
      gray,
      ((decoded["width"] as num?) ?? 0).toInt(),
      ((decoded["height"] as num?) ?? 0).toInt(),
      ((decoded["rowStride"] as num?) ?? 0).toInt(),
      options,
    );
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    if (_disposed || _sessionId != null) return;
    _emit(value.copyWith(state: UCameraState.initializing, clearError: true));
    try {
      final Map<Object?, Object?>? created = await UCameraChannel.invokeMap("create", <String, Object?>{"config": _config.toMap()});
      if (created == null) throw const UCameraException(code: UCameraErrorCode.configuration, message: "Camera session was not created");
      if (_disposed) {
        final int? id = (created["sessionId"] as num?)?.toInt();
        if (id != null) unawaited(UCameraChannel.invoke<void>("dispose", <String, Object?>{"sessionId": id}));
        return;
      }

      final int sessionId = ((created["sessionId"] as num?) ?? 0).toInt();
      _sessionId = sessionId;
      _events = UCameraChannel.events(sessionId).listen(_onEvent, onError: _onStreamError);
      if (_config.needsFrames) {
        _frames = UCameraChannel.frames(sessionId).listen(_onFrame, onError: _onStreamError);
      }
      _applyCreated(created);
      if (_config.scanning) await startScanning();
    } on UCameraException catch (error) {
      _fail(error);
    }
  }

  void _applyCreated(Map<Object?, Object?> created) {
    final Object? rawDevice = created["device"];
    final Object? rawCapabilities = created["capabilities"];
    _emit(
      value.copyWith(
        state: UCameraState.ready,
        textureId: (created["textureId"] as num?)?.toInt(),
        viewType: created["viewType"] as String?,
        previewSize: UCameraSize.fromMap(created["previewSize"]),
        device: rawDevice is Map<Object?, Object?> ? UCameraDevice.fromMap(rawDevice) : null,
        capabilities: rawCapabilities is Map<Object?, Object?> ? UCameraCapabilities.fromMap(rawCapabilities) : UCameraCapabilities.none,
        sensorOrientation: ((created["sensorOrientation"] as num?) ?? 0).toInt(),
        zoom: ((created["zoom"] as num?) ?? _config.initialZoom ?? 1).toDouble(),
        flash: _config.flash,
        focusMode: _config.focusMode,
        exposureMode: _config.exposureMode,
        whiteBalance: _config.whiteBalance,
        stabilization: _config.stabilization,
        hdr: _config.hdr,
        nightMode: _config.nightMode,
        mirrored: created["mirrored"] == true,
        isStreamingFrames: _config.imageStream,
        clearError: true,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _recordingTicker?.cancel();
    await _events?.cancel();
    await _frames?.cancel();
    final int? id = _sessionId;
    _sessionId = null;
    if (id != null) {
      try {
        await UCameraChannel.invoke<void>("dispose", <String, Object?>{"sessionId": id});
      } catch (_) {
        // The session may already be gone; disposal must not throw.
      }
    }
    await _frameController.close();
    await _codeController.close();
    await _errorController.close();
    super.dispose();
  }

  /// Releases the native session but keeps this controller usable; call
  /// [initialize] again to reopen. Used when the app goes to the background.
  Future<void> suspend() async {
    final int? id = _sessionId;
    if (id == null) return;
    _recordingTicker?.cancel();
    await _events?.cancel();
    await _frames?.cancel();
    _events = null;
    _frames = null;
    _sessionId = null;
    try {
      await UCameraChannel.invoke<void>("dispose", <String, Object?>{"sessionId": id});
    } catch (_) {
      // Ignored: suspension is best effort.
    }
    _emit(value.copyWith(state: UCameraState.uninitialized, clearTexture: true));
  }

  Future<void> resume() => initialize();

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  void _emit(UCameraValue next) {
    if (_disposed) return;
    value = next;
  }

  void _fail(UCameraException error) {
    _emit(value.copyWith(state: UCameraState.error, error: error));
    if (!_errorController.isClosed) _errorController.add(error);
  }

  void _onStreamError(Object error) {
    if (error is PlatformException) _fail(UCameraException.fromPlatform(error));
  }

  void _onEvent(Map<Object?, Object?> event) {
    if (_disposed) return;
    switch ((event["event"] as String?) ?? "") {
      case "initialized":
        _applyCreated(event);
        break;
      case "state":
        final UCameraState state = UCameraState.values.firstWhere((UCameraState s) => s.name == event["state"], orElse: () => value.state);
        _emit(value.copyWith(state: state));
        break;
      case "orientation":
        _emit(value.copyWith(deviceOrientation: UCameraOrientationX.fromDegrees(((event["degrees"] as num?) ?? 0).toInt())));
        break;
      case "zoom":
        _emit(value.copyWith(zoom: ((event["zoom"] as num?) ?? value.zoom).toDouble()));
        break;
      case "torch":
        _emit(value.copyWith(torchOn: event["on"] == true));
        break;
      case "focus":
        final Object? point = event["point"];
        _emit(value.copyWith(focusPoint: point is List<Object?> && point.length >= 2 ? Offset(((point[0] as num?) ?? 0).toDouble(), ((point[1] as num?) ?? 0).toDouble()) : null));
        break;
      case "recording":
        _emit(
          value.copyWith(
            recordingDuration: Duration(milliseconds: ((event["durationMs"] as num?) ?? 0).toInt()),
            recordingBytes: ((event["bytes"] as num?) ?? value.recordingBytes).toInt(),
          ),
        );
        break;
      case "previewSize":
        _emit(value.copyWith(previewSize: UCameraSize.fromMap(event)));
        break;
      case "codes":
        _emitCodes(_codesFromEvent(event), platform: true);
        break;
      case "error":
        _fail(UCameraException.fromMap(event));
        break;
      case "disconnected":
        _fail(const UCameraException(code: UCameraErrorCode.disconnected, message: "Camera disconnected"));
        break;
    }
  }

  List<UCode> _codesFromEvent(Map<Object?, Object?> event) {
    final Object? raw = event["codes"];
    if (raw is! List<Object?>) return const <UCode>[];
    return raw.whereType<Map<Object?, Object?>>().map(UCode.fromMap).toList(growable: false);
  }

  void _onFrame(Map<Object?, Object?> event) {
    if (_disposed) return;
    final UCameraFrame frame = UCameraFrame.fromMap(event);
    if (frame.width <= 0 || frame.height <= 0) return;
    if (_config.imageStream && !_frameController.isClosed) _frameController.add(frame);
    if (value.isScanning && _config.scanEngine != UScanEngine.platform) unawaited(_decodeFrame(frame));
  }

  Future<void> _decodeFrame(UCameraFrame frame) async {
    if (_decodeBusy) return;
    final DateTime now = DateTime.now();
    if (now.difference(_lastScanAt) < _config.scanInterval) return;
    _decodeBusy = true;
    _lastScanAt = now;
    try {
      final UGrayImage gray = frame.toGray();
      if (gray.isEmpty) return;
      final List<UCode> found = await UCodeScanWorker.decode(gray.data, gray.width, gray.height, gray.stride, _config.scanOptions);
      if (found.isNotEmpty) _emitCodes(found, platform: false);
    } catch (_) {
      // A single bad frame must never break the stream.
    } finally {
      _decodeBusy = false;
    }
  }

  void _emitCodes(List<UCode> found, {required bool platform}) {
    if (found.isEmpty || _codeController.isClosed) return;
    final DateTime now = DateTime.now();
    final Duration window = _config.scanDedupeWindow;
    final List<UCode> fresh = <UCode>[];
    for (final UCode code in found) {
      final String key = "${code.format.name}:${code.text}";
      final DateTime? last = _recentCodes[key];
      if (last != null && now.difference(last) < window) continue;
      _recentCodes[key] = now;
      fresh.add(code);
    }
    if (_recentCodes.length > 64) {
      _recentCodes.removeWhere((String key, DateTime at) => now.difference(at) > window * 4);
    }
    if (fresh.isNotEmpty) _codeController.add(fresh);
  }

  // ---------------------------------------------------------------------------
  // Capture
  // ---------------------------------------------------------------------------

  Future<UCapturedPhoto?> takePhoto({
    String? path,
    UPhotoFormat? format,
    int? quality,
    bool? mirror,
    bool includeBytes = true,
    bool includeThumbnail = false,
    UCameraSize? maxSize,
  }) async {
    final int? id = _sessionId;
    if (id == null) return null;
    _emit(value.copyWith(state: UCameraState.capturing));
    try {
      final Map<Object?, Object?>? raw = await UCameraChannel.invokeMap("takePhoto", <String, Object?>{
        "sessionId": id,
        "path": path,
        "format": (format ?? _config.photoFormat).name,
        "quality": quality ?? _config.photoQuality,
        "mirror": mirror ?? _config.mirrorFrontCapture,
        "includeBytes": includeBytes,
        "includeThumbnail": includeThumbnail,
        "maxSize": maxSize?.toMap(),
      });
      _emit(value.copyWith(state: UCameraState.ready));
      return raw == null ? null : UCapturedPhoto.fromMap(raw);
    } on UCameraException catch (error) {
      _emit(value.copyWith(state: UCameraState.ready));
      _fail(error);
      return null;
    }
  }

  /// Grabs the current preview frame as an image without a full capture cycle.
  /// Much faster than [takePhoto] and silent, at preview resolution.
  Future<UCapturedPhoto?> takeSnapshot({UPhotoFormat format = UPhotoFormat.jpeg, int quality = 90}) async {
    final int? id = _sessionId;
    if (id == null) return null;
    final Map<Object?, Object?>? raw = await UCameraChannel.invokeMap("takeSnapshot", <String, Object?>{
      "sessionId": id,
      "format": format.name,
      "quality": quality,
    });
    return raw == null ? null : UCapturedPhoto.fromMap(raw);
  }

  Future<bool> startVideoRecording({String? path, UVideoCodec? codec, int? bitrate, bool? enableAudio, Duration? maxDuration}) async {
    final int? id = _sessionId;
    if (id == null || value.isRecording) return false;
    try {
      await UCameraChannel.invoke<void>("startRecording", <String, Object?>{
        "sessionId": id,
        "path": path,
        "codec": (codec ?? _config.videoCodec).name,
        "bitrate": bitrate ?? _config.videoBitrate,
        "enableAudio": enableAudio ?? _config.enableAudio,
        "maxDurationMs": (maxDuration ?? _config.maxRecordingDuration)?.inMilliseconds,
        "maxBytes": _config.maxRecordingBytes,
      });
      _recordedBeforePause = Duration.zero;
      _recordingStartedAt = DateTime.now();
      _startRecordingTicker();
      _emit(value.copyWith(state: UCameraState.recording, recordingDuration: Duration.zero, recordingBytes: 0));
      return true;
    } on UCameraException catch (error) {
      _fail(error);
      return false;
    }
  }

  Future<UCapturedVideo?> stopVideoRecording() async {
    final int? id = _sessionId;
    if (id == null || !value.isRecording) return null;
    _recordingTicker?.cancel();
    try {
      final Map<Object?, Object?>? raw = await UCameraChannel.invokeMap("stopRecording", <String, Object?>{"sessionId": id});
      _recordingStartedAt = null;
      _recordedBeforePause = Duration.zero;
      _emit(value.copyWith(state: UCameraState.ready, recordingDuration: Duration.zero, recordingBytes: 0));
      return raw == null ? null : UCapturedVideo.fromMap(raw);
    } on UCameraException catch (error) {
      _emit(value.copyWith(state: UCameraState.ready));
      _fail(error);
      return null;
    }
  }

  Future<void> pauseVideoRecording() async {
    final int? id = _sessionId;
    if (id == null || value.state != UCameraState.recording) return;
    await UCameraChannel.invoke<void>("pauseRecording", <String, Object?>{"sessionId": id});
    _recordingTicker?.cancel();
    final DateTime? startedAt = _recordingStartedAt;
    if (startedAt != null) _recordedBeforePause += DateTime.now().difference(startedAt);
    _recordingStartedAt = null;
    _emit(value.copyWith(state: UCameraState.recordingPaused));
  }

  Future<void> resumeVideoRecording() async {
    final int? id = _sessionId;
    if (id == null || value.state != UCameraState.recordingPaused) return;
    await UCameraChannel.invoke<void>("resumeRecording", <String, Object?>{"sessionId": id});
    _recordingStartedAt = DateTime.now();
    _startRecordingTicker();
    _emit(value.copyWith(state: UCameraState.recording));
  }

  void _startRecordingTicker() {
    _recordingTicker?.cancel();
    _recordingTicker = Timer.periodic(const Duration(milliseconds: 200), (Timer _) {
      final DateTime? startedAt = _recordingStartedAt;
      if (startedAt == null) return;
      final Duration elapsed = _recordedBeforePause + DateTime.now().difference(startedAt);
      _emit(value.copyWith(recordingDuration: elapsed));
      final Duration? limit = _config.maxRecordingDuration;
      if (limit != null && elapsed >= limit) unawaited(stopVideoRecording());
    });
  }

  // ---------------------------------------------------------------------------
  // Controls
  // ---------------------------------------------------------------------------

  Future<void> _set(String method, Map<String, Object?> arguments) async {
    final int? id = _sessionId;
    if (id == null) return;
    try {
      await UCameraChannel.invoke<void>(method, <String, Object?>{"sessionId": id, ...arguments});
    } on UCameraException catch (error) {
      if (error.code != UCameraErrorCode.unsupported) _fail(error);
    }
  }

  Future<void> setFlashMode(UFlashMode mode) async {
    if (!value.capabilities.flash && mode != UFlashMode.off) return;
    await _set("setFlashMode", <String, Object?>{"mode": mode.name});
    _emit(value.copyWith(flash: mode, torchOn: mode == UFlashMode.torch));
  }

  Future<void> setTorch(bool on) async {
    if (!value.capabilities.torch) return;
    await _set("setTorch", <String, Object?>{"on": on});
    _emit(value.copyWith(torchOn: on, flash: on ? UFlashMode.torch : UFlashMode.off));
  }

  Future<void> toggleTorch() => setTorch(!value.torchOn);

  Future<void> setZoom(double zoom) async {
    final UCameraRange range = value.capabilities.zoom;
    if (range.isFixed) return;
    final double clamped = range.clamp(zoom);
    await _set("setZoom", <String, Object?>{"zoom": clamped});
    _emit(value.copyWith(zoom: clamped));
  }

  Future<void> setExposureOffset(double offset) async {
    final UCameraRange range = value.capabilities.exposureOffset;
    if (range.isFixed) return;
    final double clamped = range.clamp(offset);
    await _set("setExposureOffset", <String, Object?>{"offset": clamped});
    _emit(value.copyWith(exposureOffset: clamped));
  }

  Future<void> setExposureMode(UExposureMode mode) async {
    await _set("setExposureMode", <String, Object?>{"mode": mode.name});
    _emit(value.copyWith(exposureMode: mode));
  }

  /// [point] is normalized to the preview: (0,0) top-left, (1,1) bottom-right.
  Future<void> setExposurePoint(Offset? point) async {
    if (!value.capabilities.exposurePoint) return;
    await _set("setExposurePoint", <String, Object?>{"x": point?.dx, "y": point?.dy});
  }

  Future<void> setFocusMode(UFocusMode mode) async {
    await _set("setFocusMode", <String, Object?>{"mode": mode.name});
    _emit(value.copyWith(focusMode: mode));
  }

  Future<void> setFocusPoint(Offset? point) async {
    if (!value.capabilities.focusPoint) return;
    await _set("setFocusPoint", <String, Object?>{"x": point?.dx, "y": point?.dy});
    _emit(point == null ? value.copyWith(clearFocusPoint: true) : value.copyWith(focusPoint: point));
  }

  /// Focus and meter at the same normalized point, the usual tap-to-focus.
  Future<void> focusAndMeterAt(Offset point) async {
    await setFocusPoint(point);
    await setExposurePoint(point);
  }

  Future<void> setFocusDistance(double distance) async {
    final UCameraRange range = value.capabilities.focusDistance;
    if (range.isFixed) return;
    await _set("setFocusDistance", <String, Object?>{"distance": range.clamp(distance)});
  }

  Future<void> setIso(double iso) async {
    final UCameraRange range = value.capabilities.iso;
    if (range.isFixed) return;
    final double clamped = range.clamp(iso);
    await _set("setIso", <String, Object?>{"iso": clamped});
    _emit(value.copyWith(iso: clamped));
  }

  Future<void> setExposureDuration(Duration duration) async {
    final UCameraRange range = value.capabilities.exposureDuration;
    if (range.isFixed) return;
    await _set("setExposureDuration", <String, Object?>{"micros": duration.inMicroseconds});
    _emit(value.copyWith(exposureDuration: duration));
  }

  Future<void> setWhiteBalance(UWhiteBalanceMode mode, {double? temperature}) async {
    if (!value.capabilities.whiteBalance) return;
    await _set("setWhiteBalance", <String, Object?>{"mode": mode.name, "temperature": temperature});
    _emit(value.copyWith(whiteBalance: mode));
  }

  Future<void> setStabilization(UStabilizationMode mode) async {
    if (!value.capabilities.stabilization.contains(mode)) return;
    await _set("setStabilization", <String, Object?>{"mode": mode.name});
    _emit(value.copyWith(stabilization: mode));
  }

  Future<void> setHdr(UHdrMode mode) async {
    if (!value.capabilities.hdr) return;
    await _set("setHdr", <String, Object?>{"mode": mode.name});
    _emit(value.copyWith(hdr: mode));
  }

  Future<void> setNightMode(UNightMode mode) async {
    if (!value.capabilities.nightMode) return;
    await _set("setNightMode", <String, Object?>{"mode": mode.name});
    _emit(value.copyWith(nightMode: mode));
  }

  Future<void> lockCaptureOrientation([UCameraOrientation? orientation]) async {
    final UCameraOrientation target = orientation ?? value.deviceOrientation;
    await _set("lockOrientation", <String, Object?>{"orientation": target.name});
    _emit(value.copyWith(lockedOrientation: target));
  }

  Future<void> unlockCaptureOrientation() async {
    await _set("unlockOrientation", const <String, Object?>{});
    _emit(UCameraValue(
      state: value.state,
      device: value.device,
      capabilities: value.capabilities,
      previewSize: value.previewSize,
      textureId: value.textureId,
      viewType: value.viewType,
      sensorOrientation: value.sensorOrientation,
      deviceOrientation: value.deviceOrientation,
      flash: value.flash,
      torchOn: value.torchOn,
      zoom: value.zoom,
      exposureOffset: value.exposureOffset,
      exposureMode: value.exposureMode,
      focusMode: value.focusMode,
      whiteBalance: value.whiteBalance,
      iso: value.iso,
      exposureDuration: value.exposureDuration,
      stabilization: value.stabilization,
      hdr: value.hdr,
      nightMode: value.nightMode,
      recordingDuration: value.recordingDuration,
      recordingBytes: value.recordingBytes,
      isStreamingFrames: value.isStreamingFrames,
      isScanning: value.isScanning,
      mirrored: value.mirrored,
      focusPoint: value.focusPoint,
    ));
  }

  Future<void> pausePreview() async {
    await _set("setPreviewPaused", <String, Object?>{"paused": true});
    _emit(value.copyWith(state: UCameraState.previewPaused));
  }

  Future<void> resumePreview() async {
    await _set("setPreviewPaused", <String, Object?>{"paused": false});
    _emit(value.copyWith(state: UCameraState.ready));
  }

  /// Rebuilds the session on another device. Recording is stopped first.
  Future<void> switchToDevice(String deviceId) async {
    if (value.isRecording) await stopVideoRecording();
    _config = _config.copyWith(deviceId: deviceId);
    await suspend();
    await initialize();
  }

  /// Flips between the first back and front cameras.
  Future<void> switchCamera() async {
    final List<UCameraDevice> devices = await availableCameras();
    if (devices.length < 2) return;
    final UCameraFacing target = value.device?.isFront == true ? UCameraFacing.back : UCameraFacing.front;
    UCameraDevice? next;
    for (final UCameraDevice device in devices) {
      if (device.facing == target) {
        next = device;
        break;
      }
    }
    if (next == null) return;
    if (value.isRecording) await stopVideoRecording();
    _config = _config.copyWith(deviceId: next.id, facing: target);
    await suspend();
    await initialize();
  }

  /// Switches the active physical lens of a logical multi-camera device.
  Future<void> setLens(UCameraLens lens) async {
    if (!value.capabilities.lensSwitching) return;
    await _set("setLens", <String, Object?>{"lens": lens.name});
  }

  Future<void> enterPictureInPicture() async {
    if (!value.capabilities.pictureInPicture) return;
    await _set("enterPip", const <String, Object?>{});
  }

  // ---------------------------------------------------------------------------
  // Streaming and scanning
  // ---------------------------------------------------------------------------

  Future<void> startImageStream({UFrameFormat? format, double? maxFps, int? downscale}) async {
    final int? id = _sessionId;
    if (id == null || value.isStreamingFrames) return;
    _frames ??= UCameraChannel.frames(id).listen(_onFrame, onError: _onStreamError);
    await _set("startImageStream", <String, Object?>{
      "format": (format ?? _config.frameFormat).name,
      "maxFps": maxFps ?? _config.frameMaxFps,
      "downscale": downscale ?? _config.frameDownscale,
    });
    _emit(value.copyWith(isStreamingFrames: true));
  }

  Future<void> stopImageStream() async {
    if (!value.isStreamingFrames) return;
    await _set("stopImageStream", const <String, Object?>{});
    _emit(value.copyWith(isStreamingFrames: false));
  }

  Future<void> startScanning({UCodeScanOptions? options, UScanEngine? engine}) async {
    final int? id = _sessionId;
    if (id == null || value.isScanning) return;
    if (options != null || engine != null) {
      _config = _config.copyWith(scanOptions: options, scanEngine: engine);
    }

    final bool usePlatform = _config.scanEngine != UScanEngine.dart && value.capabilities.platformScanning;
    if (usePlatform) {
      await _set("startScanning", <String, Object?>{"options": _config.scanOptions.toMap()});
    } else {
      _frames ??= UCameraChannel.frames(id).listen(_onFrame, onError: _onStreamError);
      await _set("startImageStream", <String, Object?>{
        "format": _config.frameFormat.name,
        "maxFps": _config.frameMaxFps,
        "downscale": _config.frameDownscale,
      });
    }
    _recentCodes.clear();
    _emit(value.copyWith(isScanning: true));
  }

  Future<void> stopScanning() async {
    if (!value.isScanning) return;
    final bool usedPlatform = _config.scanEngine != UScanEngine.dart && value.capabilities.platformScanning;
    if (usedPlatform) {
      await _set("stopScanning", const <String, Object?>{});
    } else if (!_config.imageStream) {
      await _set("stopImageStream", const <String, Object?>{});
    }
    _emit(value.copyWith(isScanning: false));
  }

  /// Clears the de-duplication window so the same code fires again.
  void resetScanHistory() => _recentCodes.clear();

  /// Restricts decoding to a rectangle of the preview, in normalized
  /// coordinates. Cutting the search area is the cheapest speed win there is.
  void setScanRegion(Rect? normalizedRegion) {
    final UCameraSize preview = value.previewSize;
    if (normalizedRegion == null || preview.width == 0) {
      _config = _config.copyWith(scanOptions: _config.scanOptions.copyWith());
      return;
    }
    _config = _config.copyWith(
      scanOptions: _config.scanOptions.copyWith(
        region: Rect.fromLTWH(
          normalizedRegion.left * preview.width,
          normalizedRegion.top * preview.height,
          normalizedRegion.width * preview.width,
          normalizedRegion.height * preview.height,
        ),
      ),
    );
  }
}

/// Camera and microphone permission state in one object.
class UCameraPermissionState {
  const UCameraPermissionState({this.camera = UCameraPermission.unknown, this.microphone = UCameraPermission.unknown});

  final UCameraPermission camera;
  final UCameraPermission microphone;

  bool get isGranted => camera == UCameraPermission.granted;

  bool get isPermanentlyDenied => camera == UCameraPermission.permanentlyDenied;

  factory UCameraPermissionState.fromMap(Map<Object?, Object?> map) => UCameraPermissionState(
    camera: UCameraPermission.values.firstWhere((UCameraPermission p) => p.name == map["camera"], orElse: () => UCameraPermission.unknown),
    microphone: UCameraPermission.values.firstWhere((UCameraPermission p) => p.name == map["microphone"], orElse: () => UCameraPermission.unknown),
  );
}
