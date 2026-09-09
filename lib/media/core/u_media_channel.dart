import "package:u/utilities.dart";

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
