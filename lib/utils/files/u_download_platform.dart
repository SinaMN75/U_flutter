import "dart:typed_data";

import "package:u/utils/files/u_download_platform_io.dart" if (dart.library.js_interop) "package:u/utils/files/u_download_platform_web.dart" as impl;
import "package:u/utils/files/u_storage_backend.dart";

// =============================================================================
// u_download_platform — what differs between native and the browser when
// downloading: the HTTP client (dart:io HttpClient vs fetch + ReadableStream)
// and how a finished file reaches the user (Downloads folder, "save as",
// open, reveal). The engine in u_download_manager.dart is shared.
// =============================================================================

class UHttpResponse {
  UHttpResponse({required this.statusCode, required this.headers, required this.body, required this.abort});

  final int statusCode;

  /// Lower-cased header names.
  final Map<String, String> headers;
  final Stream<Uint8List> body;

  /// Tears down the connection immediately; the [body] stream then ends with an error or closes.
  final void Function() abort;

  int? get contentLength => int.tryParse(headers["content-length"] ?? "");
}

class UTransportOptions {
  const UTransportOptions({
    this.userAgent,
    this.proxy,
    this.pinnedCertificateSha256 = const <String>{},
    this.connectTimeout = const Duration(seconds: 20),
    this.withCredentials = false,
    this.maxConnectionsPerHost = 16,
  });

  final String? userAgent;

  /// "host:port" of an HTTP proxy (native only).
  final String? proxy;

  /// Hex SHA-256 of accepted leaf certificates (DER). Empty disables pinning (native only).
  final Set<String> pinnedCertificateSha256;
  final Duration connectTimeout;

  /// Send cookies on cross-origin requests (web only).
  final bool withCredentials;
  final int maxConnectionsPerHost;
}

/// Raised by a transport for failures that are not HTTP statuses.
class UTransportException implements Exception {
  const UTransportException(this.kind, [this.message]);

  /// "network", "timeout", "certificate", "aborted".
  final String kind;
  final String? message;

  @override
  String toString() => "UTransportException($kind${message == null ? "" : ": $message"})";
}

abstract class UDownloadTransport {
  factory UDownloadTransport(UTransportOptions options) => impl.createTransport(options);

  Future<UHttpResponse> get(Uri uri, Map<String, String> headers);

  void close();
}

/// Where a finished download is handed to the user.
abstract final class UDownloadPlatform {
  /// Publishes [sourcePath] (a file in [backend]) into the user-visible Downloads location.
  /// Returns the resulting path or URI; the source is consumed.
  static Future<String?> publishToDownloads(UStorageBackend backend, String sourcePath, String fileName, {String? mimeType, String? subfolder}) =>
      impl.publishToDownloads(backend, sourcePath, fileName, mimeType: mimeType, subfolder: subfolder);

  /// Lets the user choose where to save. Returns the destination, or null if cancelled.
  static Future<String?> saveAs(UStorageBackend backend, String sourcePath, String fileName, {String? mimeType}) =>
      impl.saveAs(backend, sourcePath, fileName, mimeType: mimeType);

  static Future<bool> open(String pathOrUri, {String? mimeType}) => impl.open(pathOrUri, mimeType: mimeType);

  static Future<bool> reveal(String pathOrUri) => impl.reveal(pathOrUri);

  /// True when running in a browser, where finished files go through the browser's own
  /// download UI instead of a file path.
  static bool get isWeb => impl.isWeb;
}
