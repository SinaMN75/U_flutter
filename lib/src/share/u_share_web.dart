import "dart:js_interop";
import "dart:js_interop_unsafe";
import "dart:typed_data";

import "package:u/src/share/u_share_channel.dart";
import "package:web/web.dart" as web;

// Browser half of UShareChannel.
abstract final class UShareWeb {
  static Future<UShareResult> share({String? text, String? subject, String? title, String? url, List<UShareFile> files = const <UShareFile>[]}) async {
    final JSObject navigator = web.window.navigator as JSObject;
    final List<web.File> blobs = <web.File>[
      for (final UShareFile f in files)
        if (f.bytes != null) web.File(<JSAny>[f.bytes!.toJS].toJS, f.fileName, web.FilePropertyBag(type: f.mimeType ?? "")),
    ];
    final web.ShareData data = web.ShareData(
      title: title ?? subject ?? "",
      text: text ?? "",
      url: url ?? "",
    );
    if (blobs.isNotEmpty) (data as JSObject)["files"] = blobs.toJS;
    if (navigator.has("share")) {
      final bool allowed = !navigator.has("canShare") || web.window.navigator.canShare(data);
      if (allowed) {
        try {
          await web.window.navigator.share(data).toDart;
          return const UShareResult(UShareStatus.success);
        } catch (e) {
          // AbortError: the user closed the sheet.
          if (e.toString().contains("AbortError")) return const UShareResult(UShareStatus.dismissed);
        }
      }
    }
    final String joined = <String?>[text, url].whereType<String>().where((String s) => s.isNotEmpty).join("\n");
    if (joined.isEmpty) return const UShareResult(UShareStatus.unavailable);
    try {
      await web.window.navigator.clipboard.writeText(joined).toDart;
      return const UShareResult(UShareStatus.copied);
    } catch (_) {
      return const UShareResult(UShareStatus.unavailable);
    }
  }

  /// Files opened with an installed PWA (File Handling API: manifest "file_handlers").
  static void listenLaunchQueue(void Function(UReceivedShare share) onShare) {
    final JSObject window = web.window as JSObject;
    if (!window.has("launchQueue")) return;
    final JSObject queue = window["launchQueue"]! as JSObject;
    void consume(JSObject params) {
      final JSArray<JSObject>? handles = params["files"] as JSArray<JSObject>?;
      if (handles == null) return;
      Future<void> read() async {
        final List<UShareFile> files = <UShareFile>[];
        for (final JSObject handle in handles.toDart) {
          try {
            final web.File file = await handle.callMethod<JSPromise<web.File>>("getFile".toJS).toDart;
            final Uint8List bytes = (await file.arrayBuffer().toDart).toDart.asUint8List();
            files.add(UShareFile.bytes(bytes, name: file.name, mimeType: file.type.isEmpty ? null : file.type));
          } catch (_) {}
        }
        if (files.isNotEmpty) onShare(UReceivedShare(files: files));
      }

      read();
    }

    queue.callMethod<JSAny?>("setConsumer".toJS, consume.toJS);
  }
}
