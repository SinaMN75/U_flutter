import "package:u/utilities.dart";

/// Resumable, multi-connection downloads with a queue, notifications and restart recovery, on all 6 platforms (web: browser download). `final task = await UDownloads.download(url);`
abstract final class UDownloads {
  static UDownloadManager get _m => UDownloadManager.instance;

  /// The download manager itself, for listeners and advanced options.
  static UDownloadManager get manager => _m;

  /// Loads saved downloads and starts the queue (runs on first use by itself).
  static Future<void> init({UDownloadConfig? config}) => _m.init(config: config);

  /// Downloads [url] into Downloads (or [destination]) with progress, pause and resume; shows a notification. `await UDownloads.download("https://x.com/a.zip")`
  static Future<UDownloadTask> download(
    String url, {
    UDownloadDestination destination = const UDownloadDestination.downloads(),
    String? fileName,
    Map<String, String> headers = const <String, String>{},
    bool wifiOnly = false,
    int? connections,
    UChecksum? checksum,
  }) => _m.download(url, destination: destination, fileName: fileName, headers: headers, wifiOnly: wifiOnly, connections: connections, checksum: checksum);

  /// Downloads to an exact file path (not on web). `await UDownloads.toFile(url, "/tmp/a.zip")`
  static Future<UDownloadTask> toFile(String url, String path, {Map<String, String> headers = const <String, String>{}, bool wifiOnly = false}) =>
      download(url, destination: UDownloadDestination.file(path), headers: headers, wifiOnly: wifiOnly);

  /// Downloads into app storage under [key]; read it with UFile.readBytes(key). `await UDownloads.toStorage(url, "pdfs/book.pdf")`
  static Future<UDownloadTask> toStorage(String url, String key, {UStorageBucket bucket = UStorageBucket.support, Map<String, String> headers = const <String, String>{}}) => download(
    url,
    destination: UDownloadDestination.storage(key, bucket: bucket),
    headers: headers,
  );

  /// Downloads encrypted into the vault under [key]; read with UFile.readSecure(key).
  static Future<UDownloadTask> toVault(String url, String key, {Map<String, String> headers = const <String, String>{}}) =>
      download(url, destination: UDownloadDestination.vault(key), headers: headers);

  /// Downloads and asks the user where to save it.
  static Future<UDownloadTask> saveAs(String url, {String? fileName, Map<String, String> headers = const <String, String>{}}) =>
      download(url, destination: const UDownloadDestination.saveAs(), fileName: fileName, headers: headers);

  /// Queues a fully custom request (headers, checksum, priority, connections…). `await UDownloads.enqueue(UDownloadRequest(url: url, priority: 10))`
  static Future<UDownloadTask> enqueue(UDownloadRequest request) => _m.enqueue(request);

  /// Downloads into memory silently (no list entry, no notification). `final Uint8List data = await UDownloads.bytes(url)`
  static Future<Uint8List> bytes(String url, {Map<String, String> headers = const <String, String>{}, void Function(double progress)? onProgress, int connections = 1}) =>
      _m.fetchBytes(url, headers: headers, onProgress: onProgress, connections: connections);

  /// Downloads text silently. `final String json = await UDownloads.text(url)`
  static Future<String> text(String url, {Map<String, String> headers = const <String, String>{}}) async => utf8.decode(await bytes(url, headers: headers));

  /// Downloads silently into app storage and returns [key] when done.
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

  /// Visible downloads, newest first (for your own list UI).
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

  /// Emits a task every time its status or progress changes. `UDownloads.events.listen((t) => print(t.progress))`
  static Stream<UDownloadTask> get events => _m.events;

  /// Combined speed of running downloads in bytes/second. `UDownloads.totalSpeed.toBKMG()`
  static double get totalSpeed => _m.totalSpeed;

  /// True while anything is downloading.
  static bool get isDownloading => _m.active.isNotEmpty;

  /// Pauses a download (resumes later from the same byte).
  static Future<void> pause(String id) => _m.pause(id);

  /// Resumes a paused download.
  static Future<void> resume(String id) => _m.resume(id);

  /// Starts a failed download again.
  static Future<void> retry(String id) => _m.retry(id);

  /// Stops a download and deletes its partial data.
  static Future<void> cancel(String id) => _m.cancel(id);

  /// Removes a download from the list; [deleteFile] deletes the file too.
  static Future<void> remove(String id, {bool deleteFile = false}) => _m.remove(id, deleteFile: deleteFile);

  /// Pauses every download.
  static Future<void> pauseAll() => _m.pauseAll();

  /// Resumes every paused download.
  static Future<void> resumeAll() => _m.resumeAll();

  /// Removes finished and failed downloads from the list.
  static Future<void> clearFinished() => _m.clearFinished();

  /// Opens a finished download with its default app.
  static Future<bool> open(UDownloadTask task) => _m.open(task);

  /// Shows a finished download in the file manager.
  static Future<bool> reveal(UDownloadTask task) => _m.reveal(task);

  /// Opens the share sheet for a finished download.
  static Future<void> share(UDownloadTask task) => _m.share(task);

  /// Current settings (connections, concurrency, speed limit, Wi-Fi only…).
  static UDownloadConfig get config => _m.config;

  /// How many downloads run at once. `UDownloads.maxConcurrent = 2`
  static set maxConcurrent(int value) => _m.maxConcurrent = value;

  /// Speed limit in bytes/second, 0 = unlimited. `UDownloads.speedLimit = 500 * 1024`
  static set speedLimit(int bytesPerSecond) => _m.speedLimit = bytesPerSecond;

  /// Adds headers (e.g. auth) to each download right before it starts. `UDownloads.headersProvider = (t) async => {"Authorization": "Bearer ${ULocalStorage.getToken()}"}`
  static set headersProvider(Future<Map<String, String>> Function(UDownloadTask task)? provider) => _m.headersProvider = provider;

  /// Rewrites a download URL right before it starts (e.g. fresh signed URLs).
  static set urlResolver(Future<String> Function(UDownloadTask task)? resolver) => _m.urlResolver = resolver;

  /// Opens the built-in download manager screen. `UDownloads.openPage()`
  static Future<void> openPage() => UNavigator.push<void>(const UDownloadManagerPage());
}
