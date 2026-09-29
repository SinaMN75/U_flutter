import "package:u/utilities.dart";

/// Downloads: resumable, multi-connection, survives restarts, with a queue and notifications.
/// Wraps [UDownloadManager.instance].
abstract final class UDownloads {
  static UDownloadManager get _m => UDownloadManager.instance;

  /// The download manager itself (for listeners and advanced options).
  static UDownloadManager get manager => _m;

  /// Loads saved downloads and starts the queue (called automatically on first use).
  static Future<void> init({UDownloadConfig? config}) => _m.init(config: config);

  /// Downloads [url] into the device's Downloads folder (or [destination]).
  static Future<UDownloadTask> download(
    String url, {
    UDownloadDestination destination = const UDownloadDestination.downloads(),
    String? fileName,
    Map<String, String> headers = const <String, String>{},
    bool wifiOnly = false,
    int? connections,
    UChecksum? checksum,
  }) => _m.download(url, destination: destination, fileName: fileName, headers: headers, wifiOnly: wifiOnly, connections: connections, checksum: checksum);

  /// Downloads [url] to an exact file path.
  static Future<UDownloadTask> toFile(String url, String path, {Map<String, String> headers = const <String, String>{}, bool wifiOnly = false}) =>
      download(url, destination: UDownloadDestination.file(path), headers: headers, wifiOnly: wifiOnly);

  /// Downloads [url] into app storage under [key] (read it back with UFile.readBytes).
  static Future<UDownloadTask> toStorage(String url, String key, {UStorageBucket bucket = UStorageBucket.support, Map<String, String> headers = const <String, String>{}}) =>
      download(url, destination: UDownloadDestination.storage(key, bucket: bucket), headers: headers);

  /// Downloads [url] encrypted into the vault under [key].
  static Future<UDownloadTask> toVault(String url, String key, {Map<String, String> headers = const <String, String>{}}) =>
      download(url, destination: UDownloadDestination.vault(key), headers: headers);

  /// Downloads [url] and asks the user where to save it.
  static Future<UDownloadTask> saveAs(String url, {String? fileName, Map<String, String> headers = const <String, String>{}}) =>
      download(url, destination: const UDownloadDestination.saveAs(), fileName: fileName, headers: headers);

  /// Queues a fully customised download request.
  static Future<UDownloadTask> enqueue(UDownloadRequest request) => _m.enqueue(request);

  /// Downloads [url] into memory silently and returns the bytes.
  static Future<Uint8List> bytes(String url, {Map<String, String> headers = const <String, String>{}, void Function(double progress)? onProgress, int connections = 1}) =>
      _m.fetchBytes(url, headers: headers, onProgress: onProgress, connections: connections);

  /// Downloads [url] as text silently.
  static Future<String> text(String url, {Map<String, String> headers = const <String, String>{}}) async => utf8.decode(await bytes(url, headers: headers));

  /// Downloads [url] silently into app storage under [key] and returns the key when done.
  static Future<String> fetchToStorage(
    String url,
    String key, {
    UStorageBucket bucket = UStorageBucket.support,
    Map<String, String> headers = const <String, String>{},
    void Function(double progress)? onProgress,
    UChecksum? checksum,
    Duration? expireIn,
    bool persistent = true,
  }) => _m.fetchToStorage(url, key, bucket: bucket, headers: headers, onProgress: onProgress, checksum: checksum, expireIn: expireIn, persistent: persistent);

  /// Visible downloads, newest first.
  static List<UDownloadTask> get tasks => _m.tasks;

  /// Every download, including silent ones.
  static List<UDownloadTask> get allTasks => _m.allTasks;

  /// Downloads running right now.
  static List<UDownloadTask> get active => _m.active;

  /// Finished downloads.
  static List<UDownloadTask> get completed => _m.tasks.where((UDownloadTask t) => t.status == UDownloadStatus.completed).toList();

  /// Failed downloads.
  static List<UDownloadTask> get failed => _m.tasks.where((UDownloadTask t) => t.status == UDownloadStatus.failed).toList();

  /// Finds a download by id.
  static UDownloadTask? task(String id) => _m.task(id);

  /// Emits a download every time its status changes.
  static Stream<UDownloadTask> get events => _m.events;

  /// Combined speed of all running downloads in bytes per second.
  static double get totalSpeed => _m.totalSpeed;

  /// True while anything is downloading.
  static bool get isDownloading => _m.active.isNotEmpty;

  /// Pauses a download.
  static Future<void> pause(String id) => _m.pause(id);

  /// Resumes a paused download.
  static Future<void> resume(String id) => _m.resume(id);

  /// Starts a failed download again.
  static Future<void> retry(String id) => _m.retry(id);

  /// Stops a download and deletes its partial data.
  static Future<void> cancel(String id) => _m.cancel(id);

  /// Removes a download from the list (and its file when [deleteFile]).
  static Future<void> remove(String id, {bool deleteFile = false}) => _m.remove(id, deleteFile: deleteFile);

  /// Pauses every download.
  static Future<void> pauseAll() => _m.pauseAll();

  /// Resumes every paused download.
  static Future<void> resumeAll() => _m.resumeAll();

  /// Removes finished and failed downloads from the list.
  static Future<void> clearFinished() => _m.clearFinished();

  /// Opens a finished download with the default app.
  static Future<bool> open(UDownloadTask task) => _m.open(task);

  /// Shows a finished download in the file manager.
  static Future<bool> reveal(UDownloadTask task) => _m.reveal(task);

  /// Opens the share sheet for a finished download.
  static Future<void> share(UDownloadTask task) => _m.share(task);

  /// Settings (connections, concurrency, speed limit, …).
  static UDownloadConfig get config => _m.config;

  /// How many downloads run at the same time.
  static set maxConcurrent(int value) => _m.maxConcurrent = value;

  /// Speed limit in bytes per second (0 = unlimited).
  static set speedLimit(int bytesPerSecond) => _m.speedLimit = bytesPerSecond;

  /// Adds headers (e.g. auth) to every download right before it starts.
  static set headersProvider(Future<Map<String, String>> Function(UDownloadTask task)? provider) => _m.headersProvider = provider;

  /// Rewrites a download's URL right before it starts (e.g. signed URLs).
  static set urlResolver(Future<String> Function(UDownloadTask task)? resolver) => _m.urlResolver = resolver;

  /// Opens the built-in download manager screen.
  static Future<void> openPage() => UNavigator.push<void>(const UDownloadManagerPage());
}
