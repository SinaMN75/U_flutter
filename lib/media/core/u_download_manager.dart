import "package:u/utilities.dart";

class UDownloadTask {
  UDownloadTask({
    required this.id,
    required this.url,
    required this.destination,
    this.headers = const <String, String>{},
    this.state = UDownloadState.queued,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.error,
    this.wifiOnly = false,
  });

  final String id;
  final String url;
  final String destination;
  final Map<String, String> headers;
  final bool wifiOnly;

  UDownloadState state;
  int receivedBytes;
  int totalBytes;
  String? error;

  double get progress => totalBytes <= 0 ? 0 : (receivedBytes / totalBytes).clamp(0, 1).toDouble();

  String get fileName => destination.split(Platform.pathSeparator).last;

  String get partPath => "$destination.part";

  Map<String, Object?> toJson() => <String, Object?>{
    "id": id,
    "url": url,
    "destination": destination,
    "headers": headers,
    "state": state.name,
    "receivedBytes": receivedBytes,
    "totalBytes": totalBytes,
    "wifiOnly": wifiOnly,
  };

  factory UDownloadTask.fromJson(Map<String, Object?> json) => UDownloadTask(
    id: (json["id"] as String?) ?? UUUID.uuidV4(),
    url: (json["url"] as String?) ?? "",
    destination: (json["destination"] as String?) ?? "",
    headers: <String, String>{...?(json["headers"] as Map<Object?, Object?>?)?.map((Object? k, Object? v) => MapEntry<String, String>("$k", "$v"))},
    state: UDownloadState.values.firstWhere((UDownloadState s) => s.name == json["state"], orElse: () => UDownloadState.queued),
    receivedBytes: (json["receivedBytes"] as int?) ?? 0,
    totalBytes: (json["totalBytes"] as int?) ?? 0,
    wifiOnly: json["wifiOnly"] == true,
  );
}

class UDownloadManager extends ChangeNotifier {
  UDownloadManager._();

  static final UDownloadManager instance = UDownloadManager._();

  static const String _fileName = "u_media_downloads.json";

  final List<UDownloadTask> _tasks = <UDownloadTask>[];
  final Map<String, StreamSubscription<List<int>>> _subscriptions = <String, StreamSubscription<List<int>>>{};
  final Set<String> _cancelling = <String>{};
  bool _loaded = false;
  int _maxConcurrent = 2;

  List<UDownloadTask> get tasks => List<UDownloadTask>.unmodifiable(_tasks);

  int get activeCount => _tasks.where((UDownloadTask t) => t.state == UDownloadState.running).length;

  set maxConcurrent(int value) => _maxConcurrent = value < 1 ? 1 : value;

  Future<File> _indexFile() async {
    final Directory directory = await getApplicationSupportDirectory();
    return File("${directory.path}${Platform.pathSeparator}$_fileName");
  }

  Future<Directory> defaultDirectory() async {
    final Directory base = await getApplicationSupportDirectory();
    final Directory directory = Directory("${base.path}${Platform.pathSeparator}downloads");
    if (!directory.existsSync()) await directory.create(recursive: true);
    return directory;
  }

  Future<void> load() async {
    if (_loaded || kIsWeb) return;
    _loaded = true;
    try {
      final String raw = await (await _indexFile()).readAsString();
      final List<Object?> decoded = jsonDecode(raw) as List<Object?>;
      _tasks
        ..clear()
        ..addAll(decoded.whereType<Map<String, Object?>>().map(UDownloadTask.fromJson));
      for (final UDownloadTask task in _tasks) {
        if (task.state == UDownloadState.running) task.state = UDownloadState.paused;
      }
    } on FileSystemException {
      _tasks.clear();
    } on FormatException {
      _tasks.clear();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    if (kIsWeb) return;
    await (await _indexFile()).writeAsString(jsonEncode(_tasks.map((UDownloadTask t) => t.toJson()).toList(growable: false)), flush: true);
    notifyListeners();
  }

  Future<UDownloadTask?> enqueue(String url, {String? fileName, String? directoryPath, Map<String, String> headers = const <String, String>{}, bool wifiOnly = false, bool startNow = true}) async {
    if (kIsWeb) return null;
    final Directory directory = directoryPath == null ? await defaultDirectory() : Directory(directoryPath);
    final String name = fileName ?? Uri.parse(url).pathSegments.last;
    final UDownloadTask task = UDownloadTask(
      id: UUUID.uuidV4(),
      url: url,
      destination: "${directory.path}${Platform.pathSeparator}$name",
      headers: headers,
      wifiOnly: wifiOnly,
    );
    _tasks.add(task);
    await _persist();
    if (startNow) unawaited(_pump());
    return task;
  }

  Future<void> _pump() async {
    while (activeCount < _maxConcurrent) {
      final UDownloadTask? next = _tasks.cast<UDownloadTask?>().firstWhere(
        (UDownloadTask? t) => t != null && t.state == UDownloadState.queued,
        orElse: () => null,
      );
      if (next == null) return;
      unawaited(_run(next));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _run(UDownloadTask task) async {
    if (task.wifiOnly && !await UNetwork.hasWifi()) {
      task.state = UDownloadState.paused;
      task.error = U.s.waitingForWifi;
      await _persist();
      return;
    }

    task.state = UDownloadState.running;
    task.error = null;
    notifyListeners();

    final HttpClient client = HttpClient();
    IOSink? sink;
    try {
      final File partFile = File(task.partPath);
      final int existing = partFile.existsSync() ? await partFile.length() : 0;
      task.receivedBytes = existing;

      final HttpClientRequest request = await client.getUrl(Uri.parse(task.url));
      task.headers.forEach(request.headers.set);
      if (existing > 0) request.headers.set(HttpHeaders.rangeHeader, "bytes=$existing-");

      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok && response.statusCode != HttpStatus.partialContent) {
        throw HttpException("HTTP ${response.statusCode}");
      }

      final bool resuming = response.statusCode == HttpStatus.partialContent;
      task.totalBytes = (resuming ? existing : 0) + (response.contentLength > 0 ? response.contentLength : 0);
      sink = partFile.openWrite(mode: resuming ? FileMode.append : FileMode.write);
      if (!resuming) task.receivedBytes = 0;

      final Completer<void> completer = Completer<void>();
      int sinceNotify = 0;
      _subscriptions[task.id] = response.listen(
        (List<int> chunk) {
          sink!.add(chunk);
          task.receivedBytes += chunk.length;
          sinceNotify += chunk.length;
          if (sinceNotify > 262144) {
            sinceNotify = 0;
            notifyListeners();
          }
        },
        onDone: completer.complete,
        onError: completer.completeError,
        cancelOnError: true,
      );

      await completer.future;
      await sink.flush();
      await sink.close();
      sink = null;
      await _subscriptions.remove(task.id)?.cancel();

      if (_cancelling.remove(task.id)) {
        task.state = UDownloadState.removed;
      } else {
        await partFile.rename(task.destination);
        task.state = UDownloadState.completed;
        task.totalBytes = task.receivedBytes;
      }
    } on Object catch (error) {
      task.error = error.toString();
      task.state = _cancelling.remove(task.id) ? UDownloadState.removed : (task.state == UDownloadState.paused ? UDownloadState.paused : UDownloadState.failed);
    } finally {
      await sink?.close();
      client.close(force: true);
      await _subscriptions.remove(task.id)?.cancel();
      await _persist();
      unawaited(_pump());
    }
  }

  Future<void> pause(String id) async {
    final UDownloadTask? task = _find(id);
    if (task == null || task.state != UDownloadState.running) return;
    task.state = UDownloadState.paused;
    await _subscriptions.remove(id)?.cancel();
    await _persist();
  }

  Future<void> resume(String id) async {
    final UDownloadTask? task = _find(id);
    if (task == null || task.state == UDownloadState.running || task.state == UDownloadState.completed) return;
    task.state = UDownloadState.queued;
    await _persist();
    unawaited(_pump());
  }

  Future<void> cancel(String id, {bool deleteFile = true}) async {
    final UDownloadTask? task = _find(id);
    if (task == null) return;
    _cancelling.add(id);
    await _subscriptions.remove(id)?.cancel();
    if (deleteFile) {
      final File part = File(task.partPath);
      if (part.existsSync()) await part.delete();
    }
    _tasks.remove(task);
    await _persist();
  }

  Future<void> clearCompleted() async {
    _tasks.removeWhere((UDownloadTask t) => t.state == UDownloadState.completed);
    await _persist();
  }

  UDownloadTask? _find(String id) {
    for (final UDownloadTask task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  @override
  void dispose() {
    for (final String id in _subscriptions.keys.toList()) {
      unawaited(_subscriptions.remove(id)?.cancel());
    }
    _subscriptions.clear();
    super.dispose();
  }
}
