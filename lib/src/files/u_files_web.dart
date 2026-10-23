import "dart:async";
import "dart:js_interop";
import "dart:typed_data";

import "package:flutter/services.dart";
import "package:flutter_web_plugins/flutter_web_plugins.dart";
import "package:web/web.dart" as web;

/// Browser half of "u/files": the file picker. Every other method falls back to Dart.
class UFilesWeb {
  static void registerWith(Registrar registrar) => MethodChannel("u/files", const StandardMethodCodec(), registrar).setMethodCallHandler(_handle);

  static Future<Object?> _handle(MethodCall call) async {
    final Map<Object?, Object?> args = (call.arguments as Map<Object?, Object?>?) ?? <Object?, Object?>{};
    switch (call.method) {
      case "pick":
        return _pick(args);
      case "pickDirectory":
        return null;
      default:
        throw MissingPluginException();
    }
  }

  static String _accept(String type, List<Object?>? extensions) => switch (type) {
    "image" => "image/*",
    "video" => "video/*",
    "media" => "image/*,video/*",
    "audio" => "audio/*",
    "custom" => (extensions ?? <Object?>[]).map((Object? e) => ".$e").join(","),
    _ => "",
  };

  static Future<List<Map<String, Object?>>?> _pick(Map<Object?, Object?> args) async {
    final web.HTMLInputElement input = web.document.createElement("input") as web.HTMLInputElement
      ..type = "file"
      ..accept = _accept("${args["type"] ?? "any"}", args["extensions"] as List<Object?>?)
      ..multiple = args["multiple"] == true
      ..style.display = "none";
    web.document.body?.append(input);
    final Completer<web.FileList?> chosen = Completer<web.FileList?>();
    input
      ..addEventListener("change", ((web.Event _) => chosen.isCompleted ? null : chosen.complete(input.files)).toJS)
      ..addEventListener("cancel", ((web.Event _) => chosen.isCompleted ? null : chosen.complete(null)).toJS)
      ..click();
    final web.FileList? files = await chosen.future;
    input.remove();
    if (files == null || files.length == 0) return null;
    final int maxCount = (args["maxCount"] as num?)?.toInt() ?? 0;
    final int count = maxCount > 0 && maxCount < files.length ? maxCount : files.length;
    final List<Map<String, Object?>> picked = <Map<String, Object?>>[];
    for (int i = 0; i < count; i++) {
      final web.File file = files.item(i)!;
      final ByteBuffer buffer = (await file.arrayBuffer().toDart).toDart;
      picked.add(<String, Object?>{"name": file.name, "bytes": buffer.asUint8List()});
    }
    return picked;
  }
}
