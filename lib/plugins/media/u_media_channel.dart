import "package:u/utilities.dart";

// The native "u/media" player channel and the OS media session (audio focus, lock-screen controls).

abstract final class UMediaChannel {
  static const MethodChannel _method = MethodChannel("u/media");

  static Future<int> create({required UMediaKind kind, required UMediaConfig config}) async {
    final int? id = await _method.invokeMethod<int>("create", <String, Object?>{"kind": kind.name, "config": config.toMap()});
    if (id == null) throw const UMediaError(code: UMediaErrorCode.unknown, message: "Player could not be created");
    return id;
  }

  static Future<T?> call<T>(int id, String method, [Map<String, Object?>? arguments]) =>
      _method.invokeMethod<T>(method, <String, Object?>{"id": id, ...?arguments});

  static Stream<Map<Object?, Object?>> events(int id) =>
      EventChannel("u/media/events/$id").receiveBroadcastStream().where((Object? event) => event is Map).cast<Map<Object?, Object?>>();

  static Future<bool> isAvailable() async {
    try {
      return (await _method.invokeMethod<bool>("isAvailable")) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static UMediaError toError(PlatformException exception, {String? sourceId}) => UMediaError(
    code: _codeFrom(exception.code),
    message: exception.message ?? exception.code,
    detail: exception.details?.toString(),
    platformCode: exception.code,
    sourceId: sourceId,
  );

  static UMediaErrorCode _codeFrom(String value) {
    for (final UMediaErrorCode code in UMediaErrorCode.values) {
      if (code.name == value) return code;
    }
    switch (value) {
      case "ERROR_NETWORK":
        return UMediaErrorCode.network;
      case "ERROR_TIMEOUT":
        return UMediaErrorCode.timeout;
      case "ERROR_FORMAT":
      case "ERROR_UNSUPPORTED":
        return UMediaErrorCode.unsupportedFormat;
      case "ERROR_DECODER":
        return UMediaErrorCode.decoder;
      case "ERROR_DRM":
        return UMediaErrorCode.drm;
      case "ERROR_NOT_FOUND":
        return UMediaErrorCode.notFound;
      case "ERROR_PERMISSION":
        return UMediaErrorCode.permission;
      default:
        return UMediaErrorCode.unknown;
    }
  }
}

abstract final class UMediaSession {
  static const MethodChannel _channel = MethodChannel("u/media_session");
  static final List<UMediaController> _registered = <UMediaController>[];
  static UMediaController? _holder;
  static bool _handlerAttached = false;

  static UMediaController? get holder => _holder;

  static List<UMediaController> get controllers => List<UMediaController>.unmodifiable(_registered);

  static void register(UMediaController controller) {
    if (_registered.contains(controller)) return;
    _registered.add(controller);
    _attachHandler();
  }

  static void unregister(UMediaController controller) {
    _registered.remove(controller);
    if (identical(_holder, controller)) _holder = null;
  }

  static Future<bool> requestFocus(UMediaController requester) async {
    if (requester.config.focusPolicy == UAudioFocusPolicy.mixWithOthers) return true;

    for (final UMediaController other in List<UMediaController>.of(_registered)) {
      if (identical(other, requester)) continue;
      if (!other.value.isPlaying) continue;
      if (other.config.focusPolicy == UAudioFocusPolicy.mixWithOthers) continue;
      await other.pause();
    }
    _holder = requester;

    try {
      return (await _channel.invokeMethod<bool>("requestFocus", <String, Object?>{
            "policy": requester.config.focusPolicy.name,
            "kind": requester.kind.name,
          })) ??
          true;
    } on MissingPluginException {
      return true;
    } on PlatformException {
      return true;
    }
  }

  static Future<void> abandonFocus(UMediaController controller) async {
    if (!identical(_holder, controller)) return;
    _holder = null;
    try {
      await _channel.invokeMethod<void>("abandonFocus");
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  static void _attachHandler() {
    if (_handlerAttached) return;
    _handlerAttached = true;
    _channel.setMethodCallHandler(_handle);
  }

  static Future<void> _handle(MethodCall call) async {
    final UMediaController? target = _holder;
    if (target == null) return;
    switch (call.method) {
      case "onFocusLost":
        await target.pause();
        break;
      case "onFocusLostTransient":
        await target.pauseForInterruption();
        break;
      case "onFocusGained":
        await target.resumeAfterInterruption();
        break;
      case "onDuck":
        await target.applyDuck(true);
        break;
      case "onUnduck":
        await target.applyDuck(false);
        break;
      case "onBecomingNoisy":
        if (target.config.pauseOnBecomingNoisy) await target.pause();
        break;
      case "onRemotePlay":
        await target.play();
        break;
      case "onRemotePause":
        await target.pause();
        break;
      case "onRemoteNext":
        await target.next();
        break;
      case "onRemotePrevious":
        await target.previous();
        break;
      case "onRemoteStop":
        await target.stop();
        break;
      case "onRemoteSeek":
        final int ms = (call.arguments as Map<Object?, Object?>?)?["positionMs"] as int? ?? 0;
        await target.seek(Duration(milliseconds: ms));
        break;
    }
  }

  static Future<void> pauseAll() async {
    for (final UMediaController controller in List<UMediaController>.of(_registered)) {
      if (controller.value.isPlaying) await controller.pause();
    }
  }
}
