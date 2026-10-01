import "package:u/utilities.dart";

// =============================================================================
// u_storage_server — streams UFileStorage entries (including encrypted vault
// entries) to native players that only understand URLs or file paths.
//
//   * Binds 127.0.0.1 only, on a random port; nothing outside the device can connect.
//   * Every registration gets an unguessable 256-bit token; unknown tokens get 404.
//   * Range requests decrypt only the chunks they touch, so seeking a large
//     encrypted video never decrypts (or writes) the whole file.
//   * Plaintext only ever exists in memory, one chunk at a time.
//
// App setup:
//   * Android: allow cleartext to 127.0.0.1 only (res/xml network_security_config with a
//     <domain-config cleartextTrafficPermitted="true"> for 127.0.0.1) — ExoPlayer obeys the policy.
//   * macOS: com.apple.security.network.server in the Release *and* DebugProfile entitlements.
//   * iOS/macOS: NSAppTransportSecurity > NSAllowsLocalNetworking = true.
// =============================================================================

/// Serves stored files to players over a private loopback URL. `final Uri url = await UStorageServer.register("course.mp4");`
abstract final class UStorageServer {
  static HttpServer? _server;
  static Future<HttpServer>? _starting;
  static final Map<String, _UServed> _served = <String, _UServed>{};
  static final Random _random = Random.secure();

  /// True while the loopback server is listening.
  static bool get isRunning => _server != null;

  /// A loopback URL that streams [key] from [bucket] until [revoke] is called. Native platforms only.
  static Future<Uri> register(String key, {UStorageBucket bucket = UStorageBucket.vault, String? mimeType, String? fileName}) async {
    if (kIsWeb) throw UnsupportedError("UStorageServer needs a native platform.");
    final UStorageEntry? entry = UFileStorage.entry(key, bucket: bucket);
    if (entry == null) throw StateError("No entry '$key' in ${bucket.name}.");
    final HttpServer server = await _start();
    final String token = _token();
    _served[token] = _UServed(key: key, bucket: bucket, mimeType: mimeType ?? entry.mimeType ?? "application/octet-stream");
    final String name = Uri.encodeComponent(fileName ?? "media${_extensionFor(mimeType ?? entry.mimeType)}");
    return Uri.parse("http://127.0.0.1:${server.port}/$token/$name");
  }

  /// Stops serving [url]. The server shuts down when nothing is registered.
  static Future<void> revoke(Uri url) async {
    if (url.pathSegments.isNotEmpty) _served.remove(url.pathSegments.first);
    if (_served.isEmpty) await close();
  }

  /// Revokes everything and stops the server.
  static Future<void> close() async {
    _served.clear();
    final HttpServer? server = _server;
    _server = null;
    _starting = null;
    await server?.close(force: true);
  }

  static Future<HttpServer> _start() {
    final HttpServer? running = _server;
    if (running != null) return Future<HttpServer>.value(running);
    return _starting ??= HttpServer.bind(InternetAddress.loopbackIPv4, 0).then((HttpServer server) {
      server.listen(_handle, onError: (Object _) {});
      _server = server;
      return server;
    });
  }

  static String _token() => base64Url.encode(List<int>.generate(32, (int _) => _random.nextInt(256))).replaceAll("=", "");

  static String _extensionFor(String? mimeType) => switch (mimeType) {
    "video/mp4" => ".mp4",
    "video/x-matroska" => ".mkv",
    "video/webm" => ".webm",
    "video/quicktime" => ".mov",
    "audio/mpeg" => ".mp3",
    "audio/mp4" => ".m4a",
    "application/pdf" => ".pdf",
    _ => "",
  };

  static Future<void> _handle(HttpRequest request) async {
    final HttpResponse response = request.response;
    try {
      final _UServed? served = request.uri.pathSegments.isEmpty ? null : _served[request.uri.pathSegments.first];
      if (served == null || (request.method != "GET" && request.method != "HEAD")) {
        response.statusCode = served == null ? HttpStatus.notFound : HttpStatus.methodNotAllowed;
        await response.close();
        return;
      }
      final int length = UFileStorage.size(served.key, bucket: served.bucket);
      final (int, int)? range = _range(request.headers.value(HttpHeaders.rangeHeader), length);
      response.headers
        ..set(HttpHeaders.acceptRangesHeader, "bytes")
        ..set(HttpHeaders.contentTypeHeader, served.mimeType)
        ..set(HttpHeaders.cacheControlHeader, "no-store");
      if (range == null) {
        response
          ..statusCode = HttpStatus.requestedRangeNotSatisfiable
          ..headers.set(HttpHeaders.contentRangeHeader, "bytes */$length");
        await response.close();
        return;
      }
      final (int start, int end) = range;
      final bool partial = request.headers.value(HttpHeaders.rangeHeader) != null;
      response
        ..statusCode = partial ? HttpStatus.partialContent : HttpStatus.ok
        ..contentLength = end - start;
      if (partial) response.headers.set(HttpHeaders.contentRangeHeader, "bytes $start-${end - 1}/$length");
      if (request.method == "GET" && end > start) {
        await response.addStream(UFileStorage.read(served.key, bucket: served.bucket, start: start, end: end));
      }
      await response.close();
    } catch (_) {
      try {
        response.statusCode = HttpStatus.internalServerError;
        await response.close();
      } catch (_) {}
    }
  }

  /// `[start, end)` for a Range header, the whole file when absent, null when unsatisfiable.
  static (int, int)? _range(String? header, int length) {
    if (header == null || !header.startsWith("bytes=")) return (0, length);
    final String spec = header.substring(6).split(",").first.trim();
    final int dash = spec.indexOf("-");
    if (dash < 0) return (0, length);
    final String from = spec.substring(0, dash).trim();
    final String to = spec.substring(dash + 1).trim();
    if (from.isEmpty) {
      final int? suffix = int.tryParse(to);
      if (suffix == null || suffix <= 0) return null;
      return (max(0, length - suffix), length);
    }
    final int? start = int.tryParse(from);
    if (start == null || start >= length) return null;
    final int? last = to.isEmpty ? null : int.tryParse(to);
    final int end = last == null || last >= length ? length : last + 1;
    return end <= start ? null : (start, end);
  }
}

class _UServed {
  const _UServed({required this.key, required this.bucket, required this.mimeType});

  final String key;
  final UStorageBucket bucket;
  final String mimeType;
}
