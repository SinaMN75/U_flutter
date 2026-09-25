import "package:u/utilities.dart";
import "package:u/utils/files/u_download_platform.dart";

// =============================================================================
// UDownloadManager — one engine for every kind of download, on all six platforms.
//
//   * Silent: fetchBytes / fetchToStorage, hidden from lists, no persistence.
//   * Managed: a persistent queue with priorities, per-host limits, scheduling,
//     wifi-only rules, pause/resume across restarts and IDM-style segmented
//     transfers (N parallel ranges, re-split whenever a connection frees up).
//   * Anywhere: memory, private storage, cache, the encrypted vault (encrypted
//     while downloading), the user's Downloads, a path, or "save as".
//   * Hidden sources: a request can carry a sourceId instead of a URL; the URL
//     is resolved per attempt by [urlResolver] and never stored or logged.
//   * OS-owned: useSystemDownloader hands the transfer to Android's
//     DownloadManager, Apple's background URLSession or Windows BITS so it
//     survives the app being killed.
//
// Transfers stream straight to storage; nothing larger than one 512 KiB write
// buffer per connection is ever held in memory.
// =============================================================================

class UDownloadConfig {
  UDownloadConfig({
    this.maxConcurrent = 3,
    this.maxPerHost = 2,
    this.connections = 4,
    this.minSegmentSize = 1024 * 1024,
    this.speedLimit = 0,
    this.stallTimeout = const Duration(seconds: 30),
    this.keepAwake = true,
    this.resumeOnStart = true,
    this.encryptQueue = false,
    this.transport = const UTransportOptions(),
    this.notificationIcon = "@mipmap/ic_launcher",
    this.foregroundTitle,
  });

  /// Tasks transferring at once.
  int maxConcurrent;

  /// Tasks transferring from one host at once.
  int maxPerHost;

  /// Default parallel connections per task (segments).
  int connections;

  /// Segments are never split below this many bytes.
  int minSegmentSize;

  /// Global bytes-per-second cap across all tasks; 0 means unlimited.
  int speedLimit;

  /// A connection that delivers nothing for this long is dropped and retried.
  Duration stallTimeout;

  /// Keep the process alive and the device awake while downloads run (an Android foreground
  /// service with a progress notification, a power assertion on desktop, a background-task
  /// grant on iOS).
  bool keepAwake;

  /// Continue interrupted downloads when [UDownloadManager.init] runs.
  bool resumeOnStart;

  /// Store the queue (URLs, headers) in the encrypted vault instead of plain storage.
  bool encryptQueue;
  UTransportOptions transport;

  /// Android small icon for completion notifications.
  String notificationIcon;

  /// Title of the Android foreground notification; defaults to the active task's name.
  String Function(List<UDownloadTask> active)? foregroundTitle;
}

enum _StopReason { pause, cancel, network }

class _Stopped implements Exception {
  const _Stopped(this.reason);

  final _StopReason reason;
}

/// The server's copy changed (or stopped honouring ranges) mid-download.
class _Restart implements Exception {
  const _Restart();
}

/// Byte offsets cannot be trusted: the browser decoded a Content-Encoding it would not let us
/// refuse, or CORS hides Content-Range so a partial response cannot be checked.
class _UnusableRanges extends _Restart {
  const _UnusableRanges();
}

class _RateLimiter {
  _RateLimiter(this.bytesPerSecond);

  int bytesPerSecond;
  double _allowance = 0;
  int _last = DateTime.now().microsecondsSinceEpoch;

  Future<void> take(int bytes) async {
    if (bytesPerSecond <= 0) return;
    final int now = DateTime.now().microsecondsSinceEpoch;
    _allowance = min(bytesPerSecond.toDouble(), _allowance + (now - _last) / 1e6 * bytesPerSecond);
    _last = now;
    _allowance -= bytes;
    if (_allowance < 0) await Future<void>.delayed(Duration(microseconds: (-_allowance / bytesPerSecond * 1e6).ceil()));
  }
}

class UDownloadManager extends ChangeNotifier {
  UDownloadManager._();

  static final UDownloadManager instance = UDownloadManager._();

  static const String _queueKey = "u.downloads.queue";
  static const int _writeBuffer = 512 * 1024;

  UDownloadConfig config = UDownloadConfig();

  /// Extra headers per attempt — e.g. a fresh bearer token. Called again after a 401/403.
  Future<Map<String, String>> Function(UDownloadTask task)? headersProvider;

  /// Turns [UDownloadRequest.sourceId] into a URL, per attempt. Lets you download by id from an
  /// authenticated endpoint or a short-lived signed URL without the URL ever being persisted.
  Future<String> Function(UDownloadTask task)? urlResolver;

  final List<UDownloadTask> _tasks = <UDownloadTask>[];
  final Map<String, _Runner> _runners = <String, _Runner>{};
  final Map<String, Timer> _scheduled = <String, Timer>{};
  final StreamController<UDownloadTask> _events = StreamController<UDownloadTask>.broadcast();
  final _RateLimiter _globalLimiter = _RateLimiter(0);
  UDownloadTransport? _transport;
  StreamSubscription<List<ConnectivityResult>>? _connectivity;
  Timer? _ticker;
  Timer? _saveTimer;
  Future<void>? _ready;
  bool _online = true;
  bool _wifi = true;
  bool _awake = false;
  bool _polling = false;
  FlutterLocalNotificationsPlugin? _notifications;

  /// Visible tasks, newest first.
  List<UDownloadTask> get tasks => List<UDownloadTask>.unmodifiable(_tasks.where((UDownloadTask t) => t.request.visible).toList().reversed);

  /// Every task, including silent ones.
  List<UDownloadTask> get allTasks => List<UDownloadTask>.unmodifiable(_tasks);

  List<UDownloadTask> get active => _tasks.where((UDownloadTask t) => t.isActive).toList(growable: false);

  /// Emits a task whenever its status changes.
  Stream<UDownloadTask> get events => _events.stream;

  /// Sum of the speeds of every running task, in bytes per second.
  double get totalSpeed => _tasks.fold(0, (double sum, UDownloadTask t) => sum + (t.isActive ? t.speed : 0));

  UDownloadTask? task(String id) => _tasks.cast<UDownloadTask?>().firstWhere((UDownloadTask? t) => t!.id == id, orElse: () => null);

  UDownloadTransport get _http => _transport ??= UDownloadTransport(config.transport);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> init({UDownloadConfig? config}) {
    if (config != null) this.config = config;
    return _ready ??= _init();
  }

  /// Name kept from the media download manager.
  Future<void> load() => init();

  Future<void> _init() async {
    await UFileStorage.init();
    _globalLimiter.bytesPerSecond = config.speedLimit;
    try {
      final dynamic saved = await UFileStorage.getJson(_queueKey, bucket: config.encryptQueue ? UStorageBucket.vault : UStorageBucket.support);
      if (saved is Map<String, dynamic>) {
        for (final dynamic item in (saved["tasks"] as List<dynamic>? ?? <dynamic>[])) {
          try {
            _tasks.add(UDownloadTask.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            debugPrint("UDownloadManager: skipped an unreadable saved task.");
          }
        }
      }
    } catch (e) {
      debugPrint("UDownloadManager: saved queue unavailable.");
    }
    for (final UDownloadTask task in _tasks) {
      if (task.system) continue;
      if (task.isActive || task.status == UDownloadStatus.waitingForNetwork) task.status = config.resumeOnStart ? UDownloadStatus.queued : UDownloadStatus.paused;
      if (task.status == UDownloadStatus.scheduled) _schedule(task);
    }
    try {
      _applyConnectivity(await Connectivity().checkConnectivity());
      _connectivity = Connectivity().onConnectivityChanged.listen(_applyConnectivity);
    } catch (_) {
      // No connectivity plugin (tests, unsupported platform): assume online.
    }
    notifyListeners();
    _ensureTicker();
    _pump();
  }

  void _applyConnectivity(List<ConnectivityResult> results) {
    final bool online = results.any((ConnectivityResult r) => r != ConnectivityResult.none);
    final bool wifi = results.any((ConnectivityResult r) => r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet);
    _online = online;
    _wifi = wifi;
    for (final UDownloadTask task in _tasks) {
      if (task.system) continue;
      final bool allowed = online && (!task.request.wifiOnly || wifi);
      if (task.isActive && !allowed) {
        _runners[task.id]?.stop(_StopReason.network);
      } else if (task.status == UDownloadStatus.waitingForNetwork && allowed) {
        task.status = UDownloadStatus.queued;
      }
    }
    _pump();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<UDownloadTask> enqueue(UDownloadRequest request) async {
    await init();
    if (request.url.isEmpty && request.sourceId == null) throw ArgumentError("A download needs a url or a sourceId.");
    if (request.destination.target == UDownloadTarget.file && UDownloadPlatform.isWeb) throw UnsupportedError("File destinations are native only.");

    // Same source to the same place while still running: reuse it instead of downloading twice.
    for (final UDownloadTask existing in _tasks) {
      if (!existing.isFinished &&
          existing.request.url == request.url &&
          existing.request.sourceId == request.sourceId &&
          jsonEncode(existing.request.destination.toJson()) == jsonEncode(request.destination.toJson())) {
        return existing;
      }
    }

    final UDownloadTask task = UDownloadTask(id: UUUID.uuidV4(), request: request);
    final UDownloadDestination destination = request.destination;
    if (request.conflict == UDownloadConflict.skip && destination.target == UDownloadTarget.storage && UFileStorage.contains(destination.key!, bucket: destination.bucket)) {
      task
        ..status = UDownloadStatus.completed
        ..result = destination.key
        ..completedAt = DateTime.now();
      task.complete();
      return task;
    }
    _tasks.add(task);
    if (request.startAt != null && request.startAt!.isAfter(DateTime.now())) {
      task.status = UDownloadStatus.scheduled;
      _schedule(task);
    }
    _changed(task);
    _pump();
    return task;
  }

  /// Convenience for the common case: download [url] to [destination] with default settings.
  Future<UDownloadTask> download(
    String url, {
    UDownloadDestination destination = const UDownloadDestination.downloads(),
    String? fileName,
    Map<String, String> headers = const <String, String>{},
    bool wifiOnly = false,
    int? connections,
    UChecksum? checksum,
  }) => enqueue(UDownloadRequest(url: url, destination: destination, fileName: fileName, headers: headers, wifiOnly: wifiOnly, connections: connections, checksum: checksum));

  /// Silent download into memory. Not listed, not persisted, not resumable across restarts.
  Future<Uint8List> fetchBytes(
    String url, {
    Map<String, String> headers = const <String, String>{},
    void Function(double progress)? onProgress,
    int connections = 1,
  }) async {
    final UDownloadTask task = await enqueue(
      UDownloadRequest(
        url: url,
        headers: headers,
        destination: const UDownloadDestination.memory(),
        visible: false,
        persistent: false,
        priority: UDownloadPriority.high,
        connections: connections,
      ),
    );
    return _await(task, onProgress, (UDownloadTask t) => t.bytes!);
  }

  /// Silent download into [UFileStorage]. Returns the key once the file is stored.
  Future<String> fetchToStorage(
    String url,
    String key, {
    UStorageBucket bucket = UStorageBucket.support,
    Map<String, String> headers = const <String, String>{},
    void Function(double progress)? onProgress,
    UChecksum? checksum,
    Duration? expireIn,
    bool persistent = true,
  }) async {
    final UDownloadTask task = await enqueue(
      UDownloadRequest(
        url: url,
        headers: headers,
        destination: UDownloadDestination.storage(key, bucket: bucket),
        visible: false,
        persistent: persistent,
        priority: UDownloadPriority.high,
        checksum: checksum,
        expireIn: expireIn,
        conflict: UDownloadConflict.overwrite,
      ),
    );
    return _await(task, onProgress, (UDownloadTask t) => key);
  }

  Future<T> _await<T>(UDownloadTask task, void Function(double progress)? onProgress, T Function(UDownloadTask task) value) async {
    void listener() => onProgress?.call(task.progress);
    if (onProgress != null) task.addListener(listener);
    try {
      final UDownloadTask done = await task.done;
      if (done.status != UDownloadStatus.completed) throw done.error ?? const UDownloadError(UDownloadErrorCode.unknown, message: "Canceled");
      return value(done);
    } finally {
      if (onProgress != null) task.removeListener(listener);
    }
  }

  Future<void> pause(String id) async {
    final UDownloadTask? task = this.task(id);
    if (task == null || !task.canPause || task.system) return;
    final _Runner? runner = _runners[id];
    if (runner != null) {
      runner.stop(_StopReason.pause);
    } else {
      _scheduled.remove(id)?.cancel();
      task.status = UDownloadStatus.paused;
      _changed(task);
    }
  }

  Future<void> resume(String id) async {
    final UDownloadTask? task = this.task(id);
    if (task == null || !task.canResume) return;
    task
      ..status = UDownloadStatus.queued
      ..error = null;
    _changed(task);
    _pump();
  }

  /// Starts a finished or failed task over from byte zero.
  Future<void> retry(String id) async {
    final UDownloadTask? task = this.task(id);
    if (task == null || task.isActive) return;
    await _deletePart(task);
    task
      ..segments.clear()
      ..received = 0
      ..total = -1
      ..error = null
      ..mirrorIndex = 0
      ..status = UDownloadStatus.queued;
    _changed(task);
    _pump();
  }

  Future<void> cancel(String id) async {
    final UDownloadTask? task = this.task(id);
    if (task == null || task.isFinished) return;
    _scheduled.remove(id)?.cancel();
    if (task.system) {
      await UFilesChannel.systemCancel(id);
      task.system = false;
    }
    final _Runner? runner = _runners[id];
    if (runner != null) {
      runner.stop(_StopReason.cancel);
      return;
    }
    await _deletePart(task);
    _finish(task, UDownloadStatus.canceled);
  }

  /// Removes a task from the list; with [deleteFile] also deletes what it downloaded.
  Future<void> remove(String id, {bool deleteFile = false}) async {
    final UDownloadTask? task = this.task(id);
    if (task == null) return;
    if (!task.isFinished) await cancel(id);
    await _runners[id]?.finished;
    if (deleteFile && task.status == UDownloadStatus.completed) await _deleteResult(task);
    _tasks.remove(task);
    _save();
    notifyListeners();
  }

  Future<void> pauseAll() async {
    for (final UDownloadTask task in _tasks.toList()) {
      await pause(task.id);
    }
  }

  Future<void> resumeAll() async {
    for (final UDownloadTask task in _tasks.toList()) {
      await resume(task.id);
    }
  }

  Future<void> clearFinished() async {
    _tasks.removeWhere((UDownloadTask t) => t.isFinished);
    _save();
    notifyListeners();
  }

  /// Name kept from the media download manager.
  Future<void> clearCompleted() => clearFinished();

  set maxConcurrent(int value) {
    config.maxConcurrent = max(1, value);
    _pump();
  }

  set speedLimit(int bytesPerSecond) {
    config.speedLimit = bytesPerSecond;
    _globalLimiter.bytesPerSecond = bytesPerSecond;
  }

  Future<bool> open(UDownloadTask task) async {
    final String? path = await _plainLocation(task);
    if (path == null) return false;
    return UDownloadPlatform.open(path, mimeType: task.mimeType);
  }

  Future<bool> reveal(UDownloadTask task) async {
    final String? path = await _plainLocation(task);
    if (path == null) return false;
    return UDownloadPlatform.reveal(path);
  }

  Future<void> share(UDownloadTask task) async {
    final String? path = await _plainLocation(task);
    if (path == null) return;
    await UShare.file(path: path, fileName: task.fileName);
  }

  /// A readable location for a finished task. Vault files are decrypted to a temp file first.
  Future<String?> _plainLocation(UDownloadTask task) async {
    if (task.status != UDownloadStatus.completed || task.result == null) return null;
    final UDownloadDestination destination = task.request.destination;
    if (destination.target != UDownloadTarget.storage) return task.result;
    if (!destination.isEncrypted) return UFileStorage.pathOf(destination.key!, bucket: destination.bucket);
    if (!UFileStorage.hasFileSystem) return null;
    final String path = uJoinPath(await UFileStorage.backend.root(UStorageBucket.temp), task.fileName ?? task.id);
    return await UFileStorage.exportFile(destination.key!, path, bucket: destination.bucket) ? path : null;
  }

  // ---------------------------------------------------------------------------
  // Scheduling
  // ---------------------------------------------------------------------------

  void _schedule(UDownloadTask task) {
    final DateTime? at = task.request.startAt;
    if (at == null) return;
    _scheduled.remove(task.id)?.cancel();
    final Duration wait = at.difference(DateTime.now());
    _scheduled[task.id] = Timer(wait.isNegative ? Duration.zero : wait, () {
      _scheduled.remove(task.id);
      if (task.status != UDownloadStatus.scheduled) return;
      task.status = UDownloadStatus.queued;
      _changed(task);
      _pump();
    });
  }

  String _hostOf(UDownloadTask task) => task.request.sourceId != null ? "source" : (Uri.tryParse(task.request.url)?.host ?? "");

  void _pump() {
    if (_ready == null) return;
    final List<UDownloadTask> running = _tasks.where((UDownloadTask t) => t.isActive && !t.system).toList();
    final List<UDownloadTask> queued = _tasks.where((UDownloadTask t) => t.status == UDownloadStatus.queued).toList()
      ..sort((UDownloadTask a, UDownloadTask b) {
        final int byPriority = b.request.priority.index.compareTo(a.request.priority.index);
        return byPriority != 0 ? byPriority : a.createdAt.compareTo(b.createdAt);
      });
    for (final UDownloadTask task in queued) {
      if (running.length >= config.maxConcurrent) break;
      if (!_online || (task.request.wifiOnly && !_wifi)) {
        task.status = UDownloadStatus.waitingForNetwork;
        _changed(task);
        continue;
      }
      final String host = _hostOf(task);
      if (running.where((UDownloadTask t) => _hostOf(t) == host).length >= config.maxPerHost) continue;
      running.add(task);
      unawaited(_start(task));
    }
    _ensureTicker();
  }

  // ---------------------------------------------------------------------------
  // Running a task
  // ---------------------------------------------------------------------------

  Future<void> _start(UDownloadTask task) async {
    task
      ..status = UDownloadStatus.connecting
      ..error = null;
    _changed(task);

    if (task.request.useSystemDownloader) {
      try {
        if (await _startSystem(task)) return;
      } catch (e) {
        debugPrint("UDownloadManager: system downloader unavailable, using the in-app engine.");
      }
    }

    final _Runner runner = _Runner(this, task);
    _runners[task.id] = runner;
    try {
      await runner.run();
      await _finalize(task);
    } catch (error) {
      final _StopReason? reason = runner.stopReason;
      if (reason == _StopReason.pause) {
        task.status = UDownloadStatus.paused;
        _changed(task);
      } else if (reason == _StopReason.network) {
        task.status = UDownloadStatus.waitingForNetwork;
        _changed(task);
      } else if (reason == _StopReason.cancel) {
        await _deletePart(task);
        _finish(task, UDownloadStatus.canceled);
      } else {
        final UDownloadError failure = error is UDownloadError ? error : UDownloadError(UDownloadErrorCode.unknown, message: error.runtimeType.toString());
        final bool fatalForMirror = failure.code == UDownloadErrorCode.insufficientSpace || failure.code == UDownloadErrorCode.storage;
        if (!fatalForMirror && task.mirrorIndex < task.request.mirrors.length) {
          // This source is unusable; start over on the next mirror.
          task.mirrorIndex++;
          await _deletePart(task);
          task
            ..segments.clear()
            ..received = 0
            ..total = -1
            ..status = UDownloadStatus.queued;
          _changed(task);
        } else {
          task.error = failure;
          _finish(task, UDownloadStatus.failed);
        }
      }
    } finally {
      _runners.remove(task.id);
      runner.dispose();
      _save();
      _pump();
    }
  }

  Future<Uri> _resolveUri(UDownloadTask task) async {
    final UDownloadRequest request = task.request;
    if (request.sourceId != null) {
      final Future<String> Function(UDownloadTask task)? resolver = urlResolver;
      if (resolver == null) throw const UDownloadError(UDownloadErrorCode.unsupported, message: "sourceId needs UDownloadManager.urlResolver");
      return Uri.parse(await resolver(task));
    }
    final String url = task.mirrorIndex == 0 ? request.url : request.mirrors[task.mirrorIndex - 1];
    return Uri.parse(url);
  }

  Future<Map<String, String>> _resolveHeaders(UDownloadTask task) async => <String, String>{
    ...task.request.headers,
    if (headersProvider != null) ...await headersProvider!(task),
  };

  Future<String> _partPath(UDownloadTask task) async {
    final UDownloadDestination destination = task.request.destination;
    final UStorageBucket bucket = destination.target == UDownloadTarget.storage ? destination.bucket : UStorageBucket.support;
    return uJoinPath(await UFileStorage.partsDirectory(bucket), "${task.id}.part");
  }

  Future<void> _deletePart(UDownloadTask task) async {
    final String? part = task.partPath;
    if (part != null) await UFileStorage.backend.delete(part);
    task.partPath = null;
  }

  Future<void> _deleteResult(UDownloadTask task) async {
    final UDownloadDestination destination = task.request.destination;
    final String? result = task.result;
    if (result == null) return;
    if (destination.target == UDownloadTarget.storage) {
      await UFileStorage.remove(destination.key!, bucket: destination.bucket);
    } else if (UFileStorage.hasFileSystem && !result.startsWith("content:")) {
      await UFileStorage.backend.delete(result);
    }
  }

  /// Moves a finished part file to its destination.
  Future<void> _finalize(UDownloadTask task) async {
    final UDownloadDestination destination = task.request.destination;
    final UStorageBackend backend = UFileStorage.backend;
    final String part = task.partPath!;
    final String fileName = task.fileName ?? "download";
    switch (destination.target) {
      case UDownloadTarget.memory:
        task
          ..bytes = await backend.readAll(part)
          ..result = null;
        await _deletePart(task);
      case UDownloadTarget.storage:
        await UFileStorage.adopt(
          part,
          destination.key!,
          bucket: destination.bucket,
          size: task.total,
          mimeType: task.mimeType,
          sha256: task.request.checksum?.algorithm == UHashAlgorithm.sha256 ? task.request.checksum!.value.toLowerCase() : null,
          expireIn: task.request.expireIn,
          tags: <String, String>{"fileName": fileName, ...task.request.metadata},
        );
        task
          ..partPath = null
          ..result = destination.key;
      case UDownloadTarget.downloads:
        task.result = await UDownloadPlatform.publishToDownloads(backend, part, fileName, mimeType: task.mimeType, subfolder: destination.subfolder);
        if (task.result == null) throw const UDownloadError(UDownloadErrorCode.storage, message: "The Downloads folder is not available.");
        task.partPath = null;
      case UDownloadTarget.file:
        String target = destination.path!;
        if (await backend.exists(target)) {
          switch (task.request.conflict) {
            case UDownloadConflict.fail:
              throw const UDownloadError(UDownloadErrorCode.storage, message: "The destination file already exists.");
            case UDownloadConflict.skip:
              await _deletePart(task);
              task.result = target;
              _finish(task, UDownloadStatus.completed);
              return;
            case UDownloadConflict.overwrite:
              await backend.delete(target);
            case UDownloadConflict.rename:
              target = _uniqueName(target, backend);
          }
        }
        await backend.move(part, target);
        task
          ..partPath = null
          ..result = target;
      case UDownloadTarget.saveAs:
        final String? saved = await UDownloadPlatform.saveAs(backend, part, fileName, mimeType: task.mimeType);
        if (saved == null) {
          await _deletePart(task);
          _finish(task, UDownloadStatus.canceled);
          return;
        }
        task
          ..partPath = null
          ..result = saved;
    }
    _finish(task, UDownloadStatus.completed);
    if (task.request.openWhenDone) unawaited(open(task));
    if (task.request.notifyWhenDone) unawaited(_notifyDone(task));
  }

  String _uniqueName(String path, UStorageBackend backend) {
    final int slash = max(path.lastIndexOf("/"), path.lastIndexOf(r"\"));
    final String directory = path.substring(0, slash + 1);
    final String name = path.substring(slash + 1);
    final int dot = name.lastIndexOf(".");
    final String stem = dot > 0 ? name.substring(0, dot) : name;
    final String extension = dot > 0 ? name.substring(dot) : "";
    for (int i = 1; i < 10000; i++) {
      final String candidate = "$directory$stem ($i)$extension";
      if (!File(candidate).existsSync()) return candidate;
    }
    return "$directory$stem ${DateTime.now().millisecondsSinceEpoch}$extension";
  }

  void _finish(UDownloadTask task, UDownloadStatus status) {
    task
      ..status = status
      ..speed = 0
      ..durable = null;
    if (status == UDownloadStatus.completed) {
      task
        ..completedAt = DateTime.now()
        ..error = null;
      if (task.total < 0) task.total = task.received;
    }
    _changed(task);
    task.complete();
    // Silent one-off tasks are only reachable through the reference the caller already holds.
    if (!task.request.persistent) _tasks.remove(task);
  }

  void _changed(UDownloadTask task) {
    task.changed();
    _events.add(task);
    notifyListeners();
    _save();
  }

  // ---------------------------------------------------------------------------
  // OS-owned downloads
  // ---------------------------------------------------------------------------

  Future<bool> _startSystem(UDownloadTask task) async {
    final UDownloadDestination destination = task.request.destination;
    if (destination.target == UDownloadTarget.memory || destination.target == UDownloadTarget.saveAs || destination.isEncrypted) return false;
    if (!await UFilesChannel.systemDownloadsSupported()) return false;
    final Uri uri = await _resolveUri(task);
    final String fileName = task.fileName ??= UDownloadFileNames.resolve(requested: task.request.fileName, uri: uri, mimeType: task.request.mimeType);
    final bool android = !UDownloadPlatform.isWeb && Platform.isAndroid;
    String? path;
    switch (destination.target) {
      case UDownloadTarget.storage:
        path = await _partPath(task);
      case UDownloadTarget.downloads:
        if (!android) {
          final Directory? base = Platform.isIOS ? await getApplicationDocumentsDirectory() : await getDownloadsDirectory();
          if (base == null) return false;
          path = _uniqueName(uJoinPath(destination.subfolder == null ? base.path : uJoinPath(base.path, destination.subfolder!), fileName), UFileStorage.backend);
        }
      case UDownloadTarget.file:
        path = destination.path;
      case UDownloadTarget.memory || UDownloadTarget.saveAs:
        return false;
    }
    final bool ok = await UFilesChannel.systemEnqueue(
      id: task.id,
      url: uri.toString(),
      headers: await _resolveHeaders(task),
      fileName: fileName,
      path: path,
      title: task.request.title ?? fileName,
      mimeType: task.request.mimeType,
      wifiOnly: task.request.wifiOnly,
      publicDownloads: android && destination.target == UDownloadTarget.downloads,
    );
    if (!ok) return false;
    task
      ..system = true
      ..partPath = destination.target == UDownloadTarget.storage ? path : null
      ..status = UDownloadStatus.downloading;
    _changed(task);
    _ensureTicker();
    return true;
  }

  Future<void> _pollSystem() async {
    if (_polling) return;
    final List<UDownloadTask> owned = _tasks.where((UDownloadTask t) => t.system && !t.isFinished).toList();
    if (owned.isEmpty) return;
    _polling = true;
    try {
      final Map<String, USystemDownloadStatus> statuses = <String, USystemDownloadStatus>{
        for (final USystemDownloadStatus s in await UFilesChannel.systemQuery()) s.id: s,
      };
      for (final UDownloadTask task in owned) {
        final USystemDownloadStatus? status = statuses[task.id];
        if (status == null) {
          task
            ..system = false
            ..error = const UDownloadError(UDownloadErrorCode.unknown, message: "The system download was lost.");
          _finish(task, UDownloadStatus.failed);
          continue;
        }
        final int previous = task.received;
        task
          ..received = status.received
          ..total = status.total;
        task.speed = task.speed * 0.6 + max(0, status.received - previous) * 0.4;
        switch (status.state) {
          case "completed":
            task.system = false;
            await _finalizeSystem(task, status);
          case "failed":
            task
              ..system = false
              ..error = UDownloadError(UDownloadErrorCode.network, message: status.error);
            _finish(task, UDownloadStatus.failed);
          case "paused":
            if (task.status != UDownloadStatus.waitingForNetwork) {
              task.status = UDownloadStatus.waitingForNetwork;
              _changed(task);
            }
          default:
            if (task.status != UDownloadStatus.downloading) {
              task.status = UDownloadStatus.downloading;
              _changed(task);
            }
            task.changed();
        }
      }
      notifyListeners();
    } finally {
      _polling = false;
    }
  }

  Future<void> _finalizeSystem(UDownloadTask task, USystemDownloadStatus status) async {
    final UDownloadDestination destination = task.request.destination;
    try {
      if (destination.target == UDownloadTarget.storage) {
        final String part = status.path ?? task.partPath!;
        await _verifyChecksum(task, UFileStorage.backend.read(part));
        await UFileStorage.adopt(part, destination.key!, bucket: destination.bucket, size: status.received, mimeType: task.request.mimeType, expireIn: task.request.expireIn);
        task
          ..partPath = null
          ..result = destination.key;
      } else {
        task.result = status.path;
        final String? path = status.path;
        if (path != null && !path.startsWith("content:")) await _verifyChecksum(task, UFileStorage.backend.read(path));
      }
      _finish(task, UDownloadStatus.completed);
      if (task.request.notifyWhenDone) unawaited(_notifyDone(task));
    } on UDownloadError catch (e) {
      task.error = e;
      _finish(task, UDownloadStatus.failed);
    }
  }

  Future<void> _verifyChecksum(UDownloadTask task, Stream<Uint8List> data) async {
    final UChecksum? checksum = task.request.checksum;
    if (checksum == null) return;
    final UHasher hasher = UHasher(checksum.algorithm);
    await for (final Uint8List chunk in data) {
      hasher.add(chunk);
    }
    if (hasher.closeHex() != checksum.value.toLowerCase()) throw const UDownloadError(UDownloadErrorCode.checksumMismatch);
  }

  // ---------------------------------------------------------------------------
  // Ticker: speed, persistence, stall detection, keep-awake, OS polling
  // ---------------------------------------------------------------------------

  void _ensureTicker() {
    final bool busy = _tasks.any((UDownloadTask t) => t.isActive || (t.system && !t.isFinished));
    if (busy && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else if (!busy && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
      unawaited(_setAwake(<UDownloadTask>[]));
    }
  }

  void _tick() {
    for (final _Runner runner in _runners.values) {
      runner.tick();
    }
    unawaited(_pollSystem());
    final List<UDownloadTask> running = _tasks.where((UDownloadTask t) => t.isActive && !t.system).toList();
    unawaited(_setAwake(running));
    if (running.isNotEmpty) {
      _save();
      notifyListeners();
    }
    _ensureTicker();
  }

  Future<void> _setAwake(List<UDownloadTask> running) async {
    if (!config.keepAwake || UDownloadPlatform.isWeb) return;
    if (running.isEmpty) {
      if (_awake) await UFilesChannel.keepAwake(enabled: false);
      _awake = false;
      return;
    }
    _awake = true;
    final int total = running.fold(0, (int sum, UDownloadTask t) => sum + max(0, t.total));
    final int received = running.fold(0, (int sum, UDownloadTask t) => sum + t.received);
    final bool known = running.every((UDownloadTask t) => t.total > 0);
    await UFilesChannel.keepAwake(
      enabled: true,
      title: config.foregroundTitle?.call(running) ?? (running.length == 1 ? running.first.displayName : "${running.length} ↓"),
      text: "${_formatBytes(received)}${known ? " / ${_formatBytes(total)}" : ""} · ${_formatBytes(totalSpeed.round())}/s",
      progress: known && total > 0 ? (received * 100 ~/ total) : -1,
    );
  }

  static String _formatBytes(int bytes) {
    const List<String> units = <String>["B", "KB", "MB", "GB", "TB"];
    double value = bytes.toDouble();
    int unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    return "${value.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}";
  }

  void _save() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), () => unawaited(_persist()));
  }

  Future<void> _persist() async {
    for (final _Runner runner in _runners.values) {
      await runner.flush();
    }
    try {
      await UFileStorage.setJson(_queueKey, <String, dynamic>{
        "v": 1,
        "tasks": _tasks.where((UDownloadTask t) => t.request.persistent).map((UDownloadTask t) => t.toJson()).toList(),
      }, bucket: config.encryptQueue ? UStorageBucket.vault : UStorageBucket.support);
    } catch (e) {
      debugPrint("UDownloadManager: could not save the queue.");
    }
  }

  Future<void> _notifyDone(UDownloadTask task) async {
    if (UDownloadPlatform.isWeb) return;
    try {
      FlutterLocalNotificationsPlugin? plugin = _notifications;
      if (plugin == null) {
        plugin = FlutterLocalNotificationsPlugin();
        await plugin.initialize(
          settings: InitializationSettings(
            android: AndroidInitializationSettings(config.notificationIcon),
            iOS: const DarwinInitializationSettings(),
            macOS: const DarwinInitializationSettings(),
            linux: const LinuxInitializationSettings(defaultActionName: "Open"),
          ),
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            final UDownloadTask? tapped = response.payload == null ? null : this.task(response.payload!);
            if (tapped != null) unawaited(open(tapped));
          },
        );
        _notifications = plugin;
      }
      await plugin.show(
        id: task.id.hashCode & 0x7FFFFFFF,
        title: task.displayName,
        body: _formatBytes(max(0, task.total)),
        payload: task.id,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails("u_downloads_done", "Downloads"),
        ),
      );
    } catch (e) {
      debugPrint("UDownloadManager: completion notification failed.");
    }
  }

  @override
  void dispose() {
    for (final _Runner runner in _runners.values) {
      runner.stop(_StopReason.pause);
    }
    unawaited(_connectivity?.cancel());
    _ticker?.cancel();
    _saveTimer?.cancel();
    for (final Timer timer in _scheduled.values) {
      timer.cancel();
    }
    _transport?.close();
    super.dispose();
  }
}

// =============================================================================
// The transfer engine for one task.
// =============================================================================

class _Runner {
  _Runner(this.manager, this.task) : _limiter = _RateLimiter(task.request.speedLimit);

  final UDownloadManager manager;
  final UDownloadTask task;
  final _RateLimiter _limiter;
  final Set<_Worker> _workers = <_Worker>{};
  final Completer<void> _finished = Completer<void>();
  UStorageSink? _sink;
  Uri? _uri;
  Map<String, String> _headers = <String, String>{};
  _StopReason? stopReason;
  bool _authRefreshed = false;

  /// Set once ranges proved unreliable (compressed transfer on the web); later attempts use one
  /// connection and no resume.
  bool _rangesBroken = false;
  int _alignment = 64 * 1024;
  int _lastReceived = 0;
  int _lastTick = DateTime.now().millisecondsSinceEpoch;

  Future<void> get finished => _finished.future;

  UStorageBackend get _backend => UFileStorage.backend;

  UDownloadConfig get _config => manager.config;

  void stop(_StopReason reason) {
    stopReason ??= reason;
    for (final _Worker worker in _workers.toList()) {
      worker.abort();
    }
  }

  void _throwIfStopped() {
    final _StopReason? reason = stopReason;
    if (reason != null) throw _Stopped(reason);
  }

  Future<void> run() async {
    try {
      _uri = await manager._resolveUri(task);
      _headers = await manager._resolveHeaders(task);
      for (int restart = 0;; restart++) {
        try {
          final List<_Worker> workers = task.segments.isEmpty || !task.acceptsRanges || task.partPath == null ? await _fresh() : await _resume();
          task
            ..status = UDownloadStatus.downloading
            ..changed();
          manager._events.add(task);
          await _runWorkers(workers);
          break;
        } on _Restart catch (reason) {
          _throwIfStopped();
          if (reason is _UnusableRanges) _rangesBroken = true;
          if (restart >= 2) throw const UDownloadError(UDownloadErrorCode.fileChanged);
          await _closeSink();
          await manager._deletePart(task);
          task.segments.clear();
        }
      }
      _throwIfStopped();
      await _complete();
    } catch (e) {
      await _closeSink();
      rethrow;
    }
  }

  // --- Setup -----------------------------------------------------------------

  Future<List<_Worker>> _fresh() async {
    task
      ..segments.clear()
      ..received = 0
      ..total = -1
      ..etag = null
      ..lastModified = null
      ..acceptsRanges = false;

    final UHttpResponse probe = await _probe();
    final int status = probe.statusCode;
    if (status == 416) {
      // An empty resource: nothing to fetch.
      probe.abort();
      task.total = 0;
    } else if (status == 206) {
      final String? contentRange = probe.headers["content-range"];
      // Without a visible Content-Range, later partial responses could not be verified.
      task.acceptsRanges = contentRange != null;
      final RegExpMatch? match = RegExp(r"/(\d+)\s*$").firstMatch(contentRange ?? "");
      task.total = match == null ? (probe.contentLength ?? -1) : int.parse(match.group(1)!);
    } else if (status == 200) {
      task.total = probe.contentLength ?? -1;
    } else {
      probe.abort();
      throw _statusError(status, probe.headers);
    }
    // Browsers decode Content-Encoding on their own and forbid asking for identity, so lengths and
    // offsets would describe compressed bytes. Such a file is fetched as one stream of unknown length.
    final String encoding = probe.headers["content-encoding"]?.toLowerCase() ?? "identity";
    if (_rangesBroken || (UDownloadPlatform.isWeb && encoding != "identity")) {
      task
        ..acceptsRanges = false
        ..total = -1;
    }
    final String? etag = probe.headers["etag"];
    // Weak validators cannot be used with If-Range.
    task
      ..etag = etag != null && !etag.startsWith("W/") ? etag : null
      ..lastModified = probe.headers["last-modified"]
      ..mimeType = task.request.mimeType ?? probe.headers["content-type"]?.split(";").first.trim()
      ..fileName = UDownloadFileNames.resolve(
        requested: task.request.fileName,
        contentDisposition: probe.headers["content-disposition"],
        uri: _uri,
        mimeType: task.request.mimeType ?? probe.headers["content-type"],
      );

    task.partPath = await manager._partPath(task);
    final UStorageSink sink = await _openSink(fresh: true);
    await _checkSpace();

    if (task.total == 0) return <_Worker>[];
    final int connections = max(1, task.request.connections ?? _config.connections);
    if (!task.acceptsRanges || task.total < 0 || connections == 1 || task.total < 2 * _config.minSegmentSize) {
      task.segments.add(UDownloadSegment(0, task.total));
      return <_Worker>[_Worker(this, task.segments.first, initial: probe)];
    }
    final int count = min(connections, task.total ~/ _config.minSegmentSize);
    final int size = _alignUp((task.total + count - 1) ~/ count);
    for (int start = 0; start < task.total; start += size) {
      task.segments.add(UDownloadSegment(start, min(start + size, task.total)));
    }
    if (sink is UVaultWriter) sink.expectedLength = task.total;
    return <_Worker>[
      _Worker(this, task.segments.first, initial: probe),
      for (final UDownloadSegment segment in task.segments.skip(1)) _Worker(this, segment),
    ];
  }

  Future<List<_Worker>> _resume() async {
    if (!await _backend.exists(task.partPath!)) throw const _Restart();
    try {
      await _openSink(fresh: false);
    } on FormatException {
      throw const _Restart();
    }
    final UStorageSink? sink = _sink;
    if (sink is UVaultWriter) {
      if (task.total >= 0) sink.expectedLength = task.total;
      // A half-filled vault chunk died with the previous writer; refetch it from its start.
      for (final UDownloadSegment segment in task.segments) {
        segment.position = max(segment.start, sink.durableOffset(segment.position));
      }
    }
    await _checkSpace();
    task.received = task.segments.fold(0, (int sum, UDownloadSegment s) => sum + s.position - s.start);
    final List<_Worker> workers = task.segments.where((UDownloadSegment s) => !s.isDone).map((UDownloadSegment s) => _Worker(this, s)).toList();
    // Fewer segments left than connections: split the big ones so every connection has work.
    final int connections = max(1, task.request.connections ?? _config.connections);
    while (workers.length < connections) {
      final UDownloadSegment? extra = _split();
      if (extra == null) break;
      workers.add(_Worker(this, extra));
    }
    return workers;
  }

  Future<UStorageSink> _openSink({required bool fresh}) async {
    final String path = task.partPath!;
    final UStorageSink sink;
    if (task.request.destination.isEncrypted) {
      final UVaultKeys keys = await UFileStorage.vaultKeys;
      final UVaultWriter writer = fresh ? await keys.create(path) : await keys.resume(path);
      _alignment = writer.chunkSize;
      task.durable = writer.durableOffset;
      sink = writer;
    } else {
      sink = await _backend.open(path, truncate: fresh);
      task.durable = null;
    }
    return _sink = sink;
  }

  Future<void> _checkSpace() async {
    if (task.total <= 0 || !_backend.hasFileSystem) return;
    final int? free = await _backend.freeSpace(task.partPath!);
    final int needed = task.total - task.received + 16 * 1024 * 1024;
    if (free != null && free < needed) throw const UDownloadError(UDownloadErrorCode.insufficientSpace);
  }

  int _alignUp(int value) => ((value + _alignment - 1) ~/ _alignment) * _alignment;

  // --- Requests --------------------------------------------------------------

  /// The first request doubles as feature detection: `Range: bytes=0-` answers "ranges or not"
  /// and starts the transfer in one round trip. Browsers send `Accept-Encoding: identity` with a
  /// Range header and reject servers that compress anyway, so on the web a failed ranged probe is
  /// retried as a plain GET and the file is then fetched as a single stream.
  Future<UHttpResponse> _probe() async {
    if (_rangesBroken) return _request(_headers);
    try {
      return await _request(<String, String>{..._headers, "range": "bytes=0-"});
    } on UDownloadError catch (e) {
      if (!UDownloadPlatform.isWeb || e.code != UDownloadErrorCode.network) rethrow;
      _rangesBroken = true;
      return _request(_headers);
    }
  }

  Future<UHttpResponse> _request(Map<String, String> headers) async {
    try {
      return await manager._http.get(_uri!, headers);
    } on UTransportException catch (e) {
      _throwIfStopped();
      throw switch (e.kind) {
        "timeout" => const UDownloadError(UDownloadErrorCode.timeout),
        "certificate" => UDownloadError(UDownloadErrorCode.certificate, message: e.message),
        _ => UDownloadError(UDownloadErrorCode.network, message: e.message),
      };
    }
  }

  UDownloadError _statusError(int status, Map<String, String> headers) {
    if (status == 401) return const UDownloadError(UDownloadErrorCode.unauthorized, statusCode: 401);
    if (status == 403) return const UDownloadError(UDownloadErrorCode.forbidden, statusCode: 403);
    if (status == 404 || status == 410) return UDownloadError(UDownloadErrorCode.notFound, statusCode: status);
    if (status >= 500) return UDownloadError(UDownloadErrorCode.serverError, statusCode: status, message: headers["retry-after"]);
    return UDownloadError(UDownloadErrorCode.http, statusCode: status, message: headers["retry-after"]);
  }

  /// After a 401/403, fetch fresh headers (and a fresh URL for sourceId tasks) once.
  Future<bool> _refreshAuth() async {
    if (_authRefreshed || (manager.headersProvider == null && task.request.sourceId == null)) return false;
    _authRefreshed = true;
    _uri = await manager._resolveUri(task);
    _headers = await manager._resolveHeaders(task);
    return true;
  }

  // --- Workers ---------------------------------------------------------------

  Future<void> _runWorkers(List<_Worker> initial) async {
    if (initial.isEmpty) return;
    final Completer<void> done = Completer<void>();
    Object? failure;

    void launch(_Worker worker) {
      _workers.add(worker);
      worker.run().then(
        (_) {
          _workers.remove(worker);
          if (failure == null && stopReason == null) {
            final UDownloadSegment? next = _split();
            if (next != null) launch(_Worker(this, next));
          }
          if (_workers.isEmpty && !done.isCompleted) done.complete();
        },
        onError: (Object error) {
          _workers.remove(worker);
          if (failure == null) {
            failure = error;
            for (final _Worker other in _workers.toList()) {
              other.abort();
            }
          }
          if (_workers.isEmpty && !done.isCompleted) done.complete();
        },
      );
    }

    initial.forEach(launch);
    await done.future;
    _throwIfStopped();
    if (failure != null) throw failure!;
    if (task.segments.any((UDownloadSegment s) => !s.isDone)) throw const UDownloadError(UDownloadErrorCode.network, message: "Incomplete transfer.");
  }

  /// IDM's dynamic segmentation: halve the largest remaining range for a free connection.
  UDownloadSegment? _split() {
    if (!task.acceptsRanges || task.total < 0) return null;
    final int connections = max(1, task.request.connections ?? _config.connections);
    if (_workers.length >= connections) return null;
    UDownloadSegment? largest;
    for (final UDownloadSegment s in task.segments) {
      if (!s.isDone && (largest == null || s.remaining > largest.remaining)) largest = s;
    }
    if (largest == null || largest.remaining < 2 * _config.minSegmentSize) return null;
    final _Worker? owner = _workers.cast<_Worker?>().firstWhere((_Worker? w) => w!.segment == largest, orElse: () => null);
    final int floor = largest.position + (owner?.buffered ?? 0) + 1;
    final int middle = _alignUp(max(largest.position + largest.remaining ~/ 2, floor));
    if (middle >= largest.end) return null;
    final UDownloadSegment next = UDownloadSegment(middle, largest.end);
    largest.end = middle;
    task.segments
      ..add(next)
      ..sort((UDownloadSegment a, UDownloadSegment b) => a.start.compareTo(b.start));
    return next;
  }

  Future<void> throttle(int bytes) async {
    await manager._globalLimiter.take(bytes);
    await _limiter.take(bytes);
  }

  // --- Completion -------------------------------------------------------------

  Future<void> _complete() async {
    task
      ..status = UDownloadStatus.verifying
      ..changed();
    final UStorageSink? sink = _sink;
    final int length = task.segments.isEmpty ? 0 : task.segments.fold(0, (int m, UDownloadSegment s) => max(m, s.end));
    if (task.total < 0) task.total = length;
    if (sink is UVaultWriter) await sink.finish(task.total);
    await _closeSink();
    final String part = task.partPath!;
    if (!task.request.destination.isEncrypted) {
      final int? onDisk = await _backend.length(part);
      if (onDisk != task.total) throw UDownloadError(UDownloadErrorCode.network, message: "Size mismatch ($onDisk/${task.total}).");
    }
    task.received = task.total;
    final Stream<Uint8List> data = task.request.destination.isEncrypted ? (await UFileStorage.vaultKeys).read(part) : _backend.read(part);
    await manager._verifyChecksum(task, data);
  }

  Future<void> _closeSink() async {
    final UStorageSink? sink = _sink;
    _sink = null;
    if (sink == null) return;
    try {
      await sink.close();
    } catch (_) {
      // Already closed or the disk went away; the part file is re-validated on resume.
    }
  }

  Future<void> flush() async => _sink?.flush();

  UStorageSink get sink => _sink!;

  void tick() {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int buffered = _workers.fold(0, (int sum, _Worker w) => sum + w.buffered);
    task.received = task.segments.fold(0, (int sum, UDownloadSegment s) => sum + s.position - s.start) + buffered;
    final double seconds = max(1, now - _lastTick) / 1000;
    final double instant = max(0, task.received - _lastReceived) / seconds;
    task.speed = task.speed == 0 ? instant : task.speed * 0.7 + instant * 0.3;
    _lastReceived = task.received;
    _lastTick = now;
    for (final _Worker worker in _workers) {
      if (DateTime.now().difference(worker.lastByte) > _config.stallTimeout) worker.abort();
    }
    task.changed();
  }

  void dispose() {
    if (!_finished.isCompleted) _finished.complete();
  }
}

class _Worker {
  _Worker(this.runner, this.segment, {this.initial});

  final _Runner runner;
  final UDownloadSegment segment;

  /// The probe response, reused as this worker's first connection.
  UHttpResponse? initial;
  UHttpResponse? _live;
  DateTime lastByte = DateTime.now();

  /// Bytes received but not yet written.
  int buffered = 0;

  UDownloadTask get task => runner.task;

  void abort() {
    _live?.abort();
    initial?.abort();
  }

  Future<void> run() async {
    int failures = 0;
    while (!segment.isDone) {
      runner._throwIfStopped();
      final int before = segment.position;
      try {
        await _transfer();
        if (segment.end < 0 || segment.isDone) return;
        // The connection closed early; reconnect from where it stopped.
        if (segment.position == before && ++failures > task.request.maxRetries) {
          throw const UDownloadError(UDownloadErrorCode.network, message: "Connection keeps closing.");
        }
      } on UDownloadError catch (error) {
        runner._throwIfStopped();
        if ((error.code == UDownloadErrorCode.unauthorized || error.code == UDownloadErrorCode.forbidden) && await runner._refreshAuth()) continue;
        if (!error.isRetryable) rethrow;
        failures = segment.position > before ? 1 : failures + 1;
        if (failures > task.request.maxRetries) rethrow;
        await Future<void>.delayed(_backoff(failures, error.message));
      }
    }
  }

  Duration _backoff(int attempt, String? retryAfter) {
    final int? seconds = int.tryParse(retryAfter ?? "");
    if (seconds != null) return Duration(seconds: min(seconds, 300));
    final int base = min(30000, 1000 * pow(2, attempt - 1).toInt());
    return Duration(milliseconds: base ~/ 2 + Random().nextInt(base ~/ 2 + 1));
  }

  Future<void> _transfer() async {
    UHttpResponse? response = initial;
    initial = null;
    if (response == null) {
      final Map<String, String> headers = <String, String>{...runner._headers};
      if (task.acceptsRanges) {
        headers["range"] = segment.end < 0 ? "bytes=${segment.position}-" : "bytes=${segment.position}-${segment.end - 1}";
        final String? validator = task.etag ?? task.lastModified;
        if (validator != null) headers["if-range"] = validator;
      } else if (segment.position > 0) {
        throw const _Restart();
      }
      response = await runner._request(headers);
    }
    _live = response;
    buffered = 0;
    lastByte = DateTime.now();
    try {
      final int status = response.statusCode;
      if (status == 416) {
        response.abort();
        if (segment.end >= 0 && segment.position >= segment.end) return;
        throw const _Restart();
      }
      if (status != 200 && status != 206) {
        response.abort();
        throw runner._statusError(status, response.headers);
      }
      if (status == 200 && segment.position > 0) {
        // If-Range failed (the file changed) or ranges were dropped: the bytes on disk are stale.
        response.abort();
        throw const _Restart();
      }
      // What this response says it carries, to catch bodies the browser silently decompressed.
      int? declared = status == 200 ? response.contentLength : null;
      if (status == 206) {
        final String? contentRange = response.headers["content-range"];
        if (contentRange == null) {
          // Not exposed to this page (CORS): a body from offset 0 is still the file, anything
          // else cannot be placed safely.
          if (segment.position != 0) {
            response.abort();
            throw const _UnusableRanges();
          }
          declared = response.contentLength;
        } else {
          final RegExpMatch? match = RegExp(r"bytes\s+(\d+)-(\d+)").firstMatch(contentRange);
          if (match == null || int.parse(match.group(1)!) != segment.position) {
            response.abort();
            throw const _Restart();
          }
          declared = int.parse(match.group(2)!) - int.parse(match.group(1)!) + 1;
        }
      }
      if (runner._rangesBroken) declared = null;

      final BytesBuilder buffer = BytesBuilder(copy: false);
      bool reachedEnd = false;
      int got = 0;
      try {
        await for (final Uint8List chunk in response.body) {
          runner._throwIfStopped();
          lastByte = DateTime.now();
          got += chunk.length;
          if (declared != null && got > declared) {
            response.abort();
            throw const _UnusableRanges();
          }
          Uint8List data = chunk;
          if (segment.end >= 0) {
            final int room = segment.end - segment.position - buffered;
            if (room <= 0) {
              reachedEnd = true;
              break;
            }
            if (data.length > room) data = Uint8List.sublistView(data, 0, room);
          }
          await runner.throttle(data.length);
          buffer.add(data);
          buffered += data.length;
          if (buffered >= UDownloadManager._writeBuffer) await _flush(buffer);
          if (segment.end >= 0 && segment.position + buffered >= segment.end) {
            reachedEnd = true;
            break;
          }
        }
      } on UTransportException catch (e) {
        runner._throwIfStopped();
        await _flush(buffer);
        throw UDownloadError(UDownloadErrorCode.network, message: e.message);
      }
      // On native a short body is a dropped connection and is retried; in a browser a clean but
      // short body means a compressed range that decoded to fewer bytes.
      if (UDownloadPlatform.isWeb && !reachedEnd && declared != null && got < declared) {
        buffer.clear();
        buffered = 0;
        throw const _UnusableRanges();
      }
      await _flush(buffer);
      if (reachedEnd) response.abort();
      if (segment.end < 0) {
        // Unknown length: a clean end of stream is the end of the file.
        runner._throwIfStopped();
        segment.end = segment.position;
        task.total = segment.position;
      }
    } finally {
      _live = null;
    }
  }

  Future<void> _flush(BytesBuilder buffer) async {
    if (buffer.isEmpty) return;
    Uint8List bytes = buffer.takeBytes();
    buffered = 0;
    // A split may have moved this segment's end since the bytes were buffered.
    if (segment.end >= 0 && segment.position + bytes.length > segment.end) bytes = Uint8List.sublistView(bytes, 0, max(0, segment.end - segment.position));
    if (bytes.isEmpty) return;
    try {
      await runner.sink.writeAt(segment.position, bytes);
    } on FileSystemException catch (e) {
      throw UDownloadError(UDownloadErrorCode.storage, message: e.osError?.message);
    }
    segment.position += bytes.length;
  }
}
