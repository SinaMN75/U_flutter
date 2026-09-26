import "package:flutter/foundation.dart";
import "package:flutter/services.dart";

// =============================================================================
// u_files_channel — the native half of files & downloads ("u/files").
//
// Every method degrades gracefully: when a platform does not implement one it
// returns null / false, and the Dart side falls back to a pure-Dart path. So
// callers never need a platform check, and a missing native feature is a
// capability gap, never a crash.
// =============================================================================

/// Status of a download handed to the OS (Android DownloadManager, Apple
/// background URLSession, Windows BITS).
class USystemDownloadStatus {
  const USystemDownloadStatus({
    required this.id,
    required this.state,
    required this.received,
    required this.total,
    this.path,
    this.error,
  });

  factory USystemDownloadStatus.fromMap(Map<Object?, Object?> map) => USystemDownloadStatus(
    id: "${map["id"]}",
    state: "${map["state"] ?? "running"}",
    received: (map["received"] as num?)?.toInt() ?? 0,
    total: (map["total"] as num?)?.toInt() ?? -1,
    path: map["path"] as String?,
    error: map["error"] as String?,
  );

  final String id;

  /// One of queued, running, paused, completed, failed.
  final String state;
  final int received;
  final int total;
  final String? path;
  final String? error;
}

abstract final class UFilesChannel {
  static const MethodChannel _channel = MethodChannel("u/files");

  static Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint("u/files.$method failed: ${e.code}${e.message == null ? "" : " — ${e.message}"}");
      return null;
    }
  }

  static Future<Map<Object?, Object?>?> _callMap(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMapMethod<Object?, Object?>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint("u/files.$method failed: ${e.code}${e.message == null ? "" : " — ${e.message}"}");
      return null;
    }
  }

  /// Bytes available to the app on the volume holding [path].
  static Future<int?> freeSpace(String path) async => (await _call<num>("freeSpace", <String, Object?>{"path": path}))?.toInt();

  /// Android: copies [sourcePath] into the public Downloads collection through MediaStore
  /// (or the legacy public directory below API 29). Returns the resulting content URI.
  ///
  /// This copies a file that is already on the device. To download a URL into Downloads use
  /// `UDownloadManager.instance.download(url)`, which downloads and then calls this for you.
  static Future<String?> saveToDownloads({
    required String sourcePath,
    required String fileName,
    String? mimeType,
    String? subfolder,
  }) {
    if (sourcePath.startsWith("http://") || sourcePath.startsWith("https://")) {
      throw ArgumentError.value(
        sourcePath,
        "sourcePath",
        "must be a local file path, not a URL. Use UDownloadManager.instance.download(url) to download into Downloads",
      );
    }
    return _call<String>("saveToDownloads", <String, Object?>{
      "sourcePath": sourcePath,
      "fileName": fileName,
      "mimeType": _mime(mimeType),
      "subfolder": subfolder,
    });
  }

  // Accepts "application/pdf"; anything without a slash (e.g. "pdf") is dropped so the native
  // side derives the type from the file name instead of rejecting an invalid MIME type.
  static String? _mime(String? mimeType) => mimeType != null && mimeType.contains("/") ? mimeType : null;

  /// Shows the native "save as" UI and copies [sourcePath] to the chosen place.
  /// Returns the destination (path or URI), or null when the user cancelled.
  static Future<String?> saveAs({required String sourcePath, required String fileName, String? mimeType}) =>
      _call<String>("saveAs", <String, Object?>{"sourcePath": sourcePath, "fileName": fileName, "mimeType": _mime(mimeType)});

  /// Opens a file (path or content URI) with the default app.
  static Future<bool> open(String pathOrUri, {String? mimeType}) async =>
      await _call<bool>("open", <String, Object?>{"path": pathOrUri, "mimeType": _mime(mimeType)}) ?? false;

  /// Shows the file in Finder / Explorer / the Files app / the Downloads app.
  static Future<bool> reveal(String pathOrUri) async => await _call<bool>("reveal", <String, Object?>{"path": pathOrUri}) ?? false;

  /// Keeps the process alive and the machine awake while downloads run. On Android this is a
  /// dataSync foreground service whose notification shows [title], [text] and [progress] (0-100,
  /// or -1 for indeterminate); elsewhere it is a power assertion or a background-task grant.
  static Future<void> keepAwake({required bool enabled, String? title, String? text, int progress = -1}) async =>
      _call<void>("keepAwake", <String, Object?>{"enabled": enabled, "title": title, "text": text, "progress": progress});

  /// iOS/macOS: keeps [path] out of iCloud and device backups.
  static Future<void> excludeFromBackup(String path) async => _call<void>("excludeFromBackup", <String, Object?>{"path": path});

  static Future<bool> storeSecret(String alias, Uint8List secret) async =>
      await _call<bool>("storeSecret", <String, Object?>{"alias": alias, "secret": secret}) ?? false;

  /// Null means "no such secret". A locked or failing key store throws instead, so callers
  /// never mistake a temporarily unreadable key for a missing one and overwrite it.
  static Future<Uint8List?> loadSecret(String alias) async {
    try {
      return await _channel.invokeMethod<Uint8List>("loadSecret", <String, Object?>{"alias": alias});
    } on MissingPluginException {
      return null;
    }
  }

  static Future<void> deleteSecret(String alias) async => _call<void>("deleteSecret", <String, Object?>{"alias": alias});

  /// Whether this platform can hand downloads to an OS service that survives the app being killed.
  static Future<bool> systemDownloadsSupported() async => await _call<bool>("systemSupported") ?? false;

  /// Hands a download to the OS. [path] is the final file path; with [publicDownloads] on
  /// Android the file goes to the shared Downloads collection instead and [path] is ignored.
  static Future<bool> systemEnqueue({
    required String id,
    required String url,
    required Map<String, String> headers,
    required String fileName,
    String? path,
    String? title,
    String? mimeType,
    bool wifiOnly = false,
    bool publicDownloads = false,
    bool showNotification = true,
  }) async =>
      await _call<bool>("systemEnqueue", <String, Object?>{
        "id": id,
        "url": url,
        "headers": headers,
        "fileName": fileName,
        "path": path,
        "title": title,
        "mimeType": mimeType,
        "wifiOnly": wifiOnly,
        "publicDownloads": publicDownloads,
        "showNotification": showNotification,
      }) ??
      false;

  static Future<void> systemCancel(String id) async => _call<void>("systemCancel", <String, Object?>{"id": id});

  static Future<List<USystemDownloadStatus>> systemQuery() async {
    final Map<Object?, Object?>? result = await _callMap("systemQuery");
    final List<Object?> items = (result?["items"] as List<Object?>?) ?? <Object?>[];
    return items.whereType<Map<Object?, Object?>>().map(USystemDownloadStatus.fromMap).toList(growable: false);
  }
}
