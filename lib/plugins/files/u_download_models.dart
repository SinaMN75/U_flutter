import "package:u/utilities.dart";

enum UDownloadStatus { queued, scheduled, waitingForNetwork, connecting, downloading, paused, verifying, completed, failed, canceled }

enum UDownloadPriority { low, normal, high }

/// What to do when the destination file already exists.
enum UDownloadConflict { rename, overwrite, skip, fail }

enum UDownloadCategory { document, image, audio, video, archive, program, other }

enum UDownloadErrorCode {
  network,
  timeout,
  http,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  fileChanged,
  checksumMismatch,
  insufficientSpace,
  storage,
  certificate,
  unsupported,
  unknown,
}

/// A failure described without the URL, so it is safe to show and to log.
class UDownloadError implements Exception {
  const UDownloadError(this.code, {this.statusCode, this.message});

  factory UDownloadError.fromJson(Map<String, dynamic> json) => UDownloadError(
    UDownloadErrorCode.values.firstWhere((UDownloadErrorCode c) => c.name == json["code"], orElse: () => UDownloadErrorCode.unknown),
    statusCode: json["status"] as int?,
    message: json["message"] as String?,
  );

  final UDownloadErrorCode code;
  final int? statusCode;
  final String? message;

  bool get isRetryable => switch (code) {
    UDownloadErrorCode.network || UDownloadErrorCode.timeout || UDownloadErrorCode.serverError => true,
    UDownloadErrorCode.http => statusCode == 408 || statusCode == 429,
    _ => false,
  };

  Map<String, dynamic> toJson() => <String, dynamic>{"code": code.name, if (statusCode != null) "status": statusCode, if (message != null) "message": message};

  @override
  String toString() => "UDownloadError(${code.name}${statusCode == null ? "" : " $statusCode"}${message == null ? "" : ": $message"})";
}

enum UDownloadTarget { memory, storage, downloads, file, saveAs }

/// Where a download ends up.
class UDownloadDestination {
  const UDownloadDestination._(this.target, {this.key, this.bucket = UStorageBucket.support, this.path, this.subfolder});

  /// Keeps the bytes in [UDownloadTask.bytes]. For small files only.
  const UDownloadDestination.memory() : this._(UDownloadTarget.memory);

  /// Silent, private storage under [key] — read it back with [UFileStorage].
  const UDownloadDestination.storage(String key, {UStorageBucket bucket = UStorageBucket.support}) : this._(UDownloadTarget.storage, key: key, bucket: bucket);

  /// Re-creatable storage that is evicted under pressure.
  const UDownloadDestination.cache(String key) : this._(UDownloadTarget.storage, key: key, bucket: UStorageBucket.cache);

  /// Encrypted while downloading; plaintext never touches the disk.
  const UDownloadDestination.vault(String key) : this._(UDownloadTarget.storage, key: key, bucket: UStorageBucket.vault);

  /// The user's Downloads: MediaStore on Android, Documents (Files app) on iOS, ~/Downloads on
  /// desktop and the browser's download bar on the web.
  const UDownloadDestination.downloads({String? subfolder}) : this._(UDownloadTarget.downloads, subfolder: subfolder);

  /// An explicit file path (native only).
  const UDownloadDestination.file(String path) : this._(UDownloadTarget.file, path: path);

  /// Asks the user where to save once the download finishes.
  const UDownloadDestination.saveAs() : this._(UDownloadTarget.saveAs);

  factory UDownloadDestination.fromJson(Map<String, dynamic> json) => UDownloadDestination._(
    UDownloadTarget.values.firstWhere((UDownloadTarget t) => t.name == json["target"], orElse: () => UDownloadTarget.downloads),
    key: json["key"] as String?,
    bucket: UStorageBucket.values.firstWhere((UStorageBucket b) => b.name == json["bucket"], orElse: () => UStorageBucket.support),
    path: json["path"] as String?,
    subfolder: json["subfolder"] as String?,
  );

  final UDownloadTarget target;
  final String? key;
  final UStorageBucket bucket;
  final String? path;
  final String? subfolder;

  bool get isEncrypted => target == UDownloadTarget.storage && bucket == UStorageBucket.vault;

  Map<String, dynamic> toJson() => <String, dynamic>{
    "target": target.name,
    if (key != null) "key": key,
    "bucket": bucket.name,
    if (path != null) "path": path,
    if (subfolder != null) "subfolder": subfolder,
  };
}

class UChecksum {
  const UChecksum(this.algorithm, this.value);

  const UChecksum.sha256(String value) : this(UHashAlgorithm.sha256, value);

  const UChecksum.md5(String value) : this(UHashAlgorithm.md5, value);

  factory UChecksum.fromJson(Map<String, dynamic> json) =>
      UChecksum(UHashAlgorithm.values.firstWhere((UHashAlgorithm a) => a.name == json["algorithm"]), json["value"] as String);

  final UHashAlgorithm algorithm;

  /// Hex digest, case-insensitive.
  final String value;

  Map<String, dynamic> toJson() => <String, dynamic>{"algorithm": algorithm.name, "value": value};
}

class UDownloadRequest {
  const UDownloadRequest({
    this.url = "",
    this.sourceId,
    this.mirrors = const <String>[],
    this.headers = const <String, String>{},
    this.fileName,
    this.title,
    this.mimeType,
    this.destination = const UDownloadDestination.downloads(),
    this.priority = UDownloadPriority.normal,
    this.connections,
    this.speedLimit = 0,
    this.checksum,
    this.wifiOnly = false,
    this.startAt,
    this.conflict = UDownloadConflict.rename,
    this.maxRetries = 8,
    this.useSystemDownloader = false,
    this.openWhenDone = false,
    this.notifyWhenDone = false,
    this.visible = true,
    this.persistent = true,
    this.expireIn,
    this.tag,
    this.metadata = const <String, String>{},
  });

  factory UDownloadRequest.fromJson(Map<String, dynamic> json) => UDownloadRequest(
    url: json["url"] as String? ?? "",
    sourceId: json["sourceId"] as String?,
    mirrors: (json["mirrors"] as List<dynamic>?)?.cast<String>() ?? const <String>[],
    headers: (json["headers"] as Map<String, dynamic>?)?.map((String k, dynamic v) => MapEntry<String, String>(k, "$v")) ?? const <String, String>{},
    fileName: json["fileName"] as String?,
    title: json["title"] as String?,
    mimeType: json["mimeType"] as String?,
    destination: UDownloadDestination.fromJson(json["destination"] as Map<String, dynamic>),
    priority: UDownloadPriority.values.firstWhere((UDownloadPriority p) => p.name == json["priority"], orElse: () => UDownloadPriority.normal),
    connections: json["connections"] as int?,
    speedLimit: json["speedLimit"] as int? ?? 0,
    checksum: json["checksum"] == null ? null : UChecksum.fromJson(json["checksum"] as Map<String, dynamic>),
    wifiOnly: json["wifiOnly"] == true,
    startAt: json["startAt"] == null ? null : DateTime.fromMillisecondsSinceEpoch(json["startAt"] as int),
    conflict: UDownloadConflict.values.firstWhere((UDownloadConflict c) => c.name == json["conflict"], orElse: () => UDownloadConflict.rename),
    maxRetries: json["maxRetries"] as int? ?? 8,
    useSystemDownloader: json["system"] == true,
    openWhenDone: json["openWhenDone"] == true,
    notifyWhenDone: json["notifyWhenDone"] == true,
    visible: json["visible"] != false,
    expireIn: json["expireIn"] == null ? null : Duration(seconds: json["expireIn"] as int),
    tag: json["tag"] as String?,
    metadata: (json["metadata"] as Map<String, dynamic>?)?.map((String k, dynamic v) => MapEntry<String, String>(k, "$v")) ?? const <String, String>{},
  );

  /// Where to download from. May be empty when [sourceId] is set.
  final String url;

  /// An opaque id (e.g. a file id on your server) that [UDownloadManager.urlResolver] turns into a
  /// URL on every attempt. The real URL is then never stored, shown or logged, and short-lived
  /// signed URLs are refreshed automatically.
  final String? sourceId;

  /// Alternative URLs tried in order when the primary one fails for good.
  final List<String> mirrors;
  final Map<String, String> headers;

  /// Overrides the name from Content-Disposition or the URL.
  final String? fileName;

  /// Shown in lists and notifications instead of the file name.
  final String? title;
  final String? mimeType;
  final UDownloadDestination destination;
  final UDownloadPriority priority;

  /// Parallel connections (segments). Null uses [UDownloadConfig.connections].
  final int? connections;

  /// Bytes per second for this task; 0 means unlimited.
  final int speedLimit;
  final UChecksum? checksum;
  final bool wifiOnly;
  final DateTime? startAt;
  final UDownloadConflict conflict;
  final int maxRetries;

  /// Hand the transfer to the OS (Android DownloadManager, Apple background URLSession,
  /// Windows BITS) so it continues after the app is killed. Ignored for memory, vault and
  /// save-as destinations, and where the OS has no such service.
  final bool useSystemDownloader;
  final bool openWhenDone;
  final bool notifyWhenDone;

  /// False hides the task from [UDownloadManager.tasks] — for silent, in-app downloads.
  final bool visible;

  /// False keeps the task out of the saved queue, so it does not survive a restart.
  final bool persistent;

  /// Expiry for storage destinations.
  final Duration? expireIn;
  final String? tag;
  final Map<String, String> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
    // A sourceId request never stores its resolved URL.
    if (url.isNotEmpty) "url": url,
    if (sourceId != null) "sourceId": sourceId,
    if (mirrors.isNotEmpty) "mirrors": mirrors,
    if (headers.isNotEmpty) "headers": headers,
    if (fileName != null) "fileName": fileName,
    if (title != null) "title": title,
    if (mimeType != null) "mimeType": mimeType,
    "destination": destination.toJson(),
    "priority": priority.name,
    if (connections != null) "connections": connections,
    if (speedLimit > 0) "speedLimit": speedLimit,
    if (checksum != null) "checksum": checksum!.toJson(),
    if (wifiOnly) "wifiOnly": true,
    if (startAt != null) "startAt": startAt!.millisecondsSinceEpoch,
    "conflict": conflict.name,
    "maxRetries": maxRetries,
    if (useSystemDownloader) "system": true,
    if (openWhenDone) "openWhenDone": true,
    if (notifyWhenDone) "notifyWhenDone": true,
    if (!visible) "visible": false,
    if (expireIn != null) "expireIn": expireIn!.inSeconds,
    if (tag != null) "tag": tag,
    if (metadata.isNotEmpty) "metadata": metadata,
  };
}

/// A byte range fetched by one connection. [end] is exclusive; -1 when the size is unknown.
class UDownloadSegment {
  UDownloadSegment(this.start, this.end, [int? position]) : position = position ?? start;

  factory UDownloadSegment.fromJson(List<dynamic> json) => UDownloadSegment(json[0] as int, json[1] as int, json[2] as int);

  final int start;
  int end;
  int position;

  bool get isDone => end >= 0 && position >= end;

  int get remaining => end < 0 ? -1 : end - position;

  List<int> toJson() => <int>[start, end, position];
}

class UDownloadTask extends ChangeNotifier {
  UDownloadTask({required this.id, required this.request, DateTime? createdAt, this.status = UDownloadStatus.queued}) : createdAt = createdAt ?? DateTime.now();

  factory UDownloadTask.fromJson(Map<String, dynamic> json) {
    final UDownloadTask task = UDownloadTask(
      id: json["id"] as String,
      request: UDownloadRequest.fromJson(json["request"] as Map<String, dynamic>),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json["created"] as int),
      status: UDownloadStatus.values.firstWhere((UDownloadStatus s) => s.name == json["status"], orElse: () => UDownloadStatus.paused),
    )
      ..received = json["received"] as int? ?? 0
      ..total = json["total"] as int? ?? -1
      ..fileName = json["fileName"] as String?
      ..mimeType = json["mimeType"] as String?
      ..result = json["result"] as String?
      ..partPath = json["partPath"] as String?
      ..etag = json["etag"] as String?
      ..lastModified = json["lastModified"] as String?
      ..acceptsRanges = json["ranges"] == true
      ..system = json["system"] == true
      ..mirrorIndex = json["mirror"] as int? ?? 0
      ..completedAt = json["completed"] == null ? null : DateTime.fromMillisecondsSinceEpoch(json["completed"] as int)
      ..error = json["error"] == null ? null : UDownloadError.fromJson(json["error"] as Map<String, dynamic>);
    task.segments.addAll(((json["segments"] as List<dynamic>?) ?? <dynamic>[]).map((dynamic s) => UDownloadSegment.fromJson(s as List<dynamic>)));
    return task;
  }

  final String id;
  final UDownloadRequest request;
  final DateTime createdAt;

  UDownloadStatus status;
  int received = 0;

  /// Total bytes, or -1 while unknown.
  int total = -1;

  /// Bytes per second, smoothed.
  double speed = 0;
  String? fileName;
  String? mimeType;
  UDownloadError? error;
  DateTime? completedAt;

  /// The finished file: a path, a content URI, a storage key, or a browser file name.
  String? result;

  /// The downloaded bytes for [UDownloadDestination.memory].
  Uint8List? bytes;

  final List<UDownloadSegment> segments = <UDownloadSegment>[];
  String? partPath;
  String? etag;
  String? lastModified;
  bool acceptsRanges = false;

  /// Maps an in-memory offset to the offset that is safely on disk (vault chunks are only
  /// durable once sealed). Set by the engine while the task runs.
  int Function(int position)? durable;

  /// True while the OS (not this process) owns the transfer.
  bool system = false;
  int mirrorIndex = 0;
  int attempts = 0;

  final Completer<UDownloadTask> _done = Completer<UDownloadTask>();

  /// Completes once the task reaches completed, failed or canceled.
  Future<UDownloadTask> get done => _done.future;

  double get progress => total <= 0 ? (status == UDownloadStatus.completed ? 1 : 0) : (received / total).clamp(0, 1).toDouble();

  Duration? get eta => speed <= 0 || total <= 0 ? null : Duration(seconds: ((total - received) / speed).ceil());

  bool get isActive => status == UDownloadStatus.connecting || status == UDownloadStatus.downloading || status == UDownloadStatus.verifying;

  bool get isFinished => status == UDownloadStatus.completed || status == UDownloadStatus.failed || status == UDownloadStatus.canceled;

  bool get canPause => isActive || status == UDownloadStatus.queued || status == UDownloadStatus.waitingForNetwork || status == UDownloadStatus.scheduled;

  bool get canResume => status == UDownloadStatus.paused || status == UDownloadStatus.failed;

  /// Resuming continues from the saved offset instead of starting over.
  bool get isResumable => acceptsRanges && received > 0;

  String get displayName => request.title ?? fileName ?? request.fileName ?? "…";

  UDownloadCategory get category => UDownloadFileNames.categoryOf(fileName ?? request.fileName ?? "");

  /// Kept for code written against the media download manager.
  UDownloadStatus get state => status;

  void changed() => notifyListeners();

  void complete() {
    if (!_done.isCompleted) _done.complete(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    "id": id,
    "request": request.toJson(),
    "created": createdAt.millisecondsSinceEpoch,
    "status": status.name,
    "received": received,
    "total": total,
    if (fileName != null) "fileName": fileName,
    if (mimeType != null) "mimeType": mimeType,
    if (result != null) "result": result,
    if (partPath != null) "partPath": partPath,
    if (etag != null) "etag": etag,
    if (lastModified != null) "lastModified": lastModified,
    if (acceptsRanges) "ranges": true,
    if (system) "system": true,
    if (mirrorIndex > 0) "mirror": mirrorIndex,
    if (completedAt != null) "completed": completedAt!.millisecondsSinceEpoch,
    if (error != null) "error": error!.toJson(),
    if (segments.isNotEmpty)
      "segments": segments.map((UDownloadSegment s) => <int>[s.start, s.end, max(s.start, durable?.call(s.position) ?? s.position)]).toList(),
  };
}

/// File-name helpers: Content-Disposition parsing, sanitising, extensions and categories.
abstract final class UDownloadFileNames {
  static const Map<String, String> _extensionByMime = <String, String>{
    "application/pdf": "pdf",
    "application/zip": "zip",
    "application/x-zip-compressed": "zip",
    "application/x-7z-compressed": "7z",
    "application/x-rar-compressed": "rar",
    "application/vnd.rar": "rar",
    "application/gzip": "gz",
    "application/json": "json",
    "application/xml": "xml",
    "application/epub+zip": "epub",
    "application/msword": "doc",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
    "application/vnd.ms-excel": "xls",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": "xlsx",
    "application/vnd.ms-powerpoint": "ppt",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation": "pptx",
    "application/vnd.android.package-archive": "apk",
    "application/x-msdownload": "exe",
    "application/x-apple-diskimage": "dmg",
    "text/plain": "txt",
    "text/html": "html",
    "text/csv": "csv",
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/gif": "gif",
    "image/webp": "webp",
    "image/svg+xml": "svg",
    "image/heic": "heic",
    "audio/mpeg": "mp3",
    "audio/mp4": "m4a",
    "audio/aac": "aac",
    "audio/ogg": "ogg",
    "audio/wav": "wav",
    "audio/flac": "flac",
    "video/mp4": "mp4",
    "video/webm": "webm",
    "video/quicktime": "mov",
    "video/x-matroska": "mkv",
  };

  static const Map<UDownloadCategory, Set<String>> _categories = <UDownloadCategory, Set<String>>{
    UDownloadCategory.document: <String>{"pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "csv", "rtf", "odt", "ods", "epub", "md", "json", "xml", "html"},
    UDownloadCategory.image: <String>{"jpg", "jpeg", "png", "gif", "webp", "bmp", "svg", "heic", "heif", "tiff", "ico"},
    UDownloadCategory.audio: <String>{"mp3", "m4a", "aac", "ogg", "opus", "wav", "flac", "wma", "amr"},
    UDownloadCategory.video: <String>{"mp4", "mkv", "webm", "mov", "avi", "wmv", "flv", "m4v", "3gp", "ts", "m3u8"},
    UDownloadCategory.archive: <String>{"zip", "rar", "7z", "tar", "gz", "bz2", "xz", "tgz", "iso"},
    UDownloadCategory.program: <String>{"apk", "aab", "exe", "msi", "dmg", "pkg", "deb", "rpm", "appimage", "ipa"},
  };

  static String extensionOf(String name) {
    final int dot = name.lastIndexOf(".");
    return dot <= 0 || dot == name.length - 1 ? "" : name.substring(dot + 1).toLowerCase();
  }

  static UDownloadCategory categoryOf(String name) {
    final String extension = extensionOf(name);
    for (final MapEntry<UDownloadCategory, Set<String>> entry in _categories.entries) {
      if (entry.value.contains(extension)) return entry.key;
    }
    return UDownloadCategory.other;
  }

  static String? extensionForMime(String? mimeType) => mimeType == null ? null : _extensionByMime[mimeType.split(";").first.trim().toLowerCase()];

  static String? mimeForExtension(String extension) {
    for (final MapEntry<String, String> entry in _extensionByMime.entries) {
      if (entry.value == extension) return entry.key;
    }
    return null;
  }

  /// RFC 6266: prefers `filename*=UTF-8''…` over `filename="…"`.
  static String? fromContentDisposition(String? header) {
    if (header == null) return null;
    final RegExpMatch? extended = RegExp(r"filename\*\s*=\s*([^']*)'[^']*'([^;]+)", caseSensitive: false).firstMatch(header);
    if (extended != null) {
      try {
        return Uri.decodeComponent(extended.group(2)!.trim().replaceAll('"', ""));
      } on ArgumentError {
        // Fall through to the plain parameter.
      }
    }
    final RegExpMatch? plain = RegExp(r'filename\s*=\s*(?:"((?:[^"\\]|\\.)*)"|([^;]+))', caseSensitive: false).firstMatch(header);
    final String? value = plain?.group(1) ?? plain?.group(2)?.trim();
    return value == null || value.isEmpty ? null : value.replaceAll(r'\"', '"');
  }

  static const Set<String> _reserved = <String>{
    "CON", "PRN", "AUX", "NUL", //
    "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
    "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9",
  };

  /// Makes [name] safe on every file system: no separators or reserved characters, no
  /// Windows device names, no leading dots, and at most 180 characters.
  static String sanitize(String name) {
    String result = name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), "_").trim();
    result = result.replaceAll(RegExp(r"^[.\s]+|[.\s]+$"), "");
    if (result.isEmpty) result = "download";
    final String stem = result.split(".").first.toUpperCase();
    if (_reserved.contains(stem)) result = "_$result";
    if (result.length > 180) {
      final String extension = extensionOf(result);
      result = "${result.substring(0, 180 - extension.length - 1)}.$extension";
    }
    return result;
  }

  static String resolve({String? requested, String? contentDisposition, Uri? uri, String? mimeType}) {
    String? name = requested ?? fromContentDisposition(contentDisposition);
    if (name == null && uri != null && uri.pathSegments.isNotEmpty && uri.pathSegments.last.isNotEmpty) {
      try {
        name = Uri.decodeComponent(uri.pathSegments.last);
      } on ArgumentError {
        name = uri.pathSegments.last;
      }
    }
    name = sanitize(name ?? "download");
    if (extensionOf(name).isEmpty) {
      final String? extension = extensionForMime(mimeType);
      if (extension != null) name = "$name.$extension";
    }
    return name;
  }
}
