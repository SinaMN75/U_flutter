import "dart:async";
import "dart:js_interop";
import "dart:js_interop_unsafe";
import "dart:typed_data";

import "package:u/utils/files/u_download_platform.dart";
import "package:u/utils/files/u_storage_backend.dart";
import "package:web/web.dart" as web;

bool get isWeb => true;

UDownloadTransport createTransport(UTransportOptions options) => _FetchTransport(options);

// fetch() + ReadableStream gives a real byte stream with cancellation, which package:http's
// BrowserClient does not: it buffers the whole body, so progress and pause would be impossible.
class _FetchTransport implements UDownloadTransport {
  _FetchTransport(this._options);

  final UTransportOptions _options;
  final Set<web.AbortController> _live = <web.AbortController>{};

  @override
  Future<UHttpResponse> get(Uri uri, Map<String, String> headers) async {
    final web.AbortController controller = web.AbortController();
    _live.add(controller);
    final JSObject requestHeaders = JSObject();
    headers.forEach((String k, String v) => requestHeaders[k] = v.toJS);
    final web.Response response;
    try {
      response = await web.window
          .fetch(
            uri.toString().toJS,
            web.RequestInit(
              method: "GET",
              headers: requestHeaders,
              signal: controller.signal,
              credentials: _options.withCredentials ? "include" : "same-origin",
              cache: "no-store",
            ),
          )
          .toDart
          .timeout(_options.connectTimeout);
    } on TimeoutException {
      controller.abort();
      _live.remove(controller);
      throw const UTransportException("timeout");
    } catch (e) {
      _live.remove(controller);
      throw UTransportException("network", "$e");
    }

    final Map<String, String> map = <String, String>{};
    (response.headers as JSObject).callMethod<JSAny?>(
      "forEach".toJS,
      ((JSString value, JSString name) => map[name.toDart.toLowerCase()] = value.toDart).toJS,
    );

    Stream<Uint8List> body() async* {
      final web.ReadableStream? stream = response.body;
      if (stream == null) return;
      final web.ReadableStreamDefaultReader reader = stream.getReader() as web.ReadableStreamDefaultReader;
      try {
        while (true) {
          final web.ReadableStreamReadResult result;
          try {
            result = await reader.read().toDart;
          } catch (e) {
            throw UTransportException(controller.signal.aborted ? "aborted" : "network", "$e");
          }
          if (result.done) break;
          yield (result.value! as JSUint8Array).toDart;
        }
      } finally {
        _live.remove(controller);
      }
    }

    // dart2js rejects tear-offs of external interop members, so this must stay a closure.
    // ignore: unnecessary_lambdas
    return UHttpResponse(statusCode: response.status, headers: map, body: body(), abort: () => controller.abort());
  }

  @override
  void close() {
    for (final web.AbortController controller in _live) {
      controller.abort();
    }
    _live.clear();
  }
}

Future<web.Blob> _blobOf(UStorageBackend backend, String path, String? mimeType) async {
  final List<web.BlobPart> parts = <web.BlobPart>[];
  await for (final Uint8List chunk in backend.read(path)) {
    parts.add(chunk.toJS);
  }
  return web.Blob(parts.toJS, web.BlobPropertyBag(type: mimeType ?? "application/octet-stream"));
}

void _clickDownload(web.Blob blob, String fileName) {
  final String url = web.URL.createObjectURL(blob);
  final web.HTMLAnchorElement anchor = web.document.createElement("a") as web.HTMLAnchorElement
    ..href = url
    ..download = fileName
    ..style.display = "none";
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  // Revoking immediately can cancel the download in some browsers.
  Timer(const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
}

Future<String?> publishToDownloads(UStorageBackend backend, String sourcePath, String fileName, {String? mimeType, String? subfolder}) async {
  _clickDownload(await _blobOf(backend, sourcePath, mimeType), fileName);
  await backend.delete(sourcePath);
  return fileName;
}

// The File System Access API (Chromium) gives a real "save as" dialog with a streamed write;
// elsewhere the browser's own download flow is the only option.
Future<String?> saveAs(UStorageBackend backend, String sourcePath, String fileName, {String? mimeType}) async {
  if (!web.window.has("showSaveFilePicker")) return publishToDownloads(backend, sourcePath, fileName, mimeType: mimeType);
  try {
    final JSObject options = JSObject()..["suggestedName"] = fileName.toJS;
    final JSObject handle = await web.window.callMethod<JSPromise<JSObject>>("showSaveFilePicker".toJS, options).toDart;
    final JSObject writable = await handle.callMethod<JSPromise<JSObject>>("createWritable".toJS).toDart;
    await for (final Uint8List chunk in backend.read(sourcePath)) {
      await writable.callMethod<JSPromise<JSAny?>>("write".toJS, chunk.toJS).toDart;
    }
    await writable.callMethod<JSPromise<JSAny?>>("close".toJS).toDart;
    await backend.delete(sourcePath);
    return fileName;
  } catch (_) {
    // AbortError: the user dismissed the picker.
    return null;
  }
}

Future<bool> open(String pathOrUri, {String? mimeType}) async {
  web.window.open(pathOrUri, "_blank");
  return true;
}

Future<bool> reveal(String pathOrUri) async => false;
