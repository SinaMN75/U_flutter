import "package:u/utilities.dart";

abstract final class UAudio {
  static UMediaController? _instance;

  static UMediaController get controller => _instance ??= UMediaController(kind: UMediaKind.audio, config: UMediaConfig.music);

  static ValueListenable<UMediaValue> get state => controller;

  static UMediaValue get value => controller.value;

  static Stream<Duration> get positionStream => controller.positionStream;

  static Stream<UMediaValue> get stateStream => controller.stateStream;

  static UMediaMetadata? get nowPlaying => controller.value.metadata ?? controller.currentSource?.metadata;

  static List<UMediaSource> get queue => controller.queue;

  static int get currentIndex => controller.currentIndex;

  static bool get isPlaying => controller.value.isPlaying;

  static Duration get position => controller.value.position;

  static Duration get duration => controller.value.duration;

  static UMediaSource source(Object input) {
    if (input is UMediaSource) return input;
    final String value = input.toString();
    if (value.startsWith("http://") || value.startsWith("https://") || value.startsWith("rtsp://") || value.startsWith("rtmp://")) return UMediaSource.network(value);
    if (value.startsWith("content://") || value.startsWith("file://")) return UMediaSource.content(value);
    if (value.startsWith("assets/") || value.startsWith("asset:")) return UMediaSource.asset(value.replaceFirst("asset:", ""));
    return UMediaSource.file(value);
  }

  static Future<void> play(Object input, {UMediaMetadata? metadata}) async {
    final UMediaSource resolved = source(input);
    await controller.open(resolved, autoPlay: true);
    if (metadata != null) await controller.setNotification(metadata: metadata);
  }

  static Future<void> playQueue(List<Object> inputs, {int startAt = 0}) => controller.openQueue(inputs.map(source).toList(growable: false), startIndex: startAt, autoPlay: true);

  static Future<void> resume() => controller.play();

  static Future<void> pause() => controller.pause();

  static Future<void> toggle() => controller.playPause();

  static Future<void> stop() => controller.stop();

  static Future<void> next() => controller.next();

  static Future<void> previous() => controller.previous();

  static Future<void> jumpTo(int index) => controller.jumpTo(index);

  static Future<void> seek(Duration position) => controller.seek(position);

  static Future<void> seekBy(Duration delta) => controller.seekBy(delta);

  static Future<void> add(Object input) => controller.addToQueue(source(input));

  static Future<void> playNext(Object input) => controller.insertNext(source(input));

  static Future<void> removeAt(int index) => controller.removeAt(index);

  static Future<void> move(int from, int to) => controller.moveInQueue(from, to);

  static Future<void> setSpeed(double speed) => controller.setSpeed(speed);

  static Future<void> setVolume(double volume) => controller.setVolume(volume);

  static Future<void> setMuted(bool muted) => controller.setMuted(muted);

  static Future<void> setRepeat(URepeatMode mode) => controller.setRepeat(mode);

  static Future<void> setShuffle(bool enabled) => controller.setShuffle(enabled);

  static Future<void> toggleShuffle() => controller.toggleShuffle();

  static Future<void> notification({required UMediaMetadata metadata, bool showSeekBar = true}) => controller.setNotification(metadata: metadata, showSeekBar: showSeekBar);

  static Future<void> playFolder(String directoryPath, {bool recursive = true, int startAt = 0}) async {
    final List<UMediaSource> sources = await scanFolder(directoryPath, recursive: recursive);
    if (sources.isEmpty) return;
    await controller.openQueue(sources, startIndex: startAt, autoPlay: true);
  }

  static const Set<String> audioExtensions = <String>{".mp3", ".m4a", ".aac", ".flac", ".wav", ".ogg", ".opus", ".oga", ".wma", ".aiff", ".alac", ".mka", ".m4b"};

  static Future<List<UMediaSource>> scanFolder(String directoryPath, {bool recursive = true, int limit = 20000}) async {
    if (kIsWeb) return const <UMediaSource>[];
    final Directory directory = Directory(directoryPath);
    final List<UMediaSource> result = <UMediaSource>[];
    try {
      await for (final FileSystemEntity entity in directory.list(recursive: recursive, followLinks: false)) {
        if (entity is! File) continue;
        final String lower = entity.path.toLowerCase();
        final int dot = lower.lastIndexOf(".");
        if (dot < 0 || !audioExtensions.contains(lower.substring(dot))) continue;
        result.add(UMediaSource.file(entity.path));
        if (result.length >= limit) break;
      }
    } on FileSystemException {
      return result;
    }
    result.sort((UMediaSource a, UMediaSource b) => a.id.compareTo(b.id));
    return result;
  }

  static Future<UMediaMetadata> readTags(String path) => UTagParser.readFile(path);

  static Future<void> dispose() async {
    _instance?.dispose();
    _instance = null;
  }
}

/// Fire-and-forget sound effects. Runs on a small pool of headless players that
/// mix with other audio, so playing a click never pauses the user's music.
abstract final class USound {
  static const UMediaConfig _config = UMediaConfig(
    focusPolicy: UAudioFocusPolicy.mixWithOthers,
    wakeLock: false,
    minBufferMs: 500,
    maxBufferMs: 4000,
    bufferForPlaybackMs: 200,
    bufferForPlaybackAfterRebufferMs: 400,
    positionUpdateInterval: Duration(seconds: 1),
  );

  static final List<UMediaController> _pool = <UMediaController>[];
  static final Map<String, UMediaSource> _cache = <String, UMediaSource>{};
  static int _cursor = 0;

  static bool enabled = true;
  static double masterVolume = 1;
  static int poolSize = 4;

  static UMediaSource resolve(Object input) {
    if (input is UMediaSource) return input;
    final String value = input.toString();
    final UMediaSource? cached = _cache[value];
    if (cached != null) return cached;
    final UMediaSource source = UAudio.source(value);
    _cache[value] = source;
    return source;
  }

  static UMediaController _acquire() {
    if (_pool.length < poolSize) {
      final UMediaController controller = UMediaController(kind: UMediaKind.audio, config: _config);
      _pool.add(controller);
      return controller;
    }
    final UMediaController controller = _pool[_cursor % _pool.length];
    _cursor++;
    return controller;
  }

  /// Warms up the decoder for each asset so the first play has no latency.
  static Future<void> preload(List<Object> sources) async {
    if (sources.isEmpty) return;
    for (final Object input in sources) {
      final UMediaSource source = resolve(input);
      final UMediaController controller = _acquire();
      await controller.open(source);
      await controller.pause();
    }
  }

  static Future<void> play(Object input, {double volume = 1, bool interrupt = false}) async {
    if (!enabled) return;
    final UMediaController controller = _acquire();
    if (interrupt) await controller.stop();
    await controller.setVolume((volume * masterVolume).clamp(0, 1).toDouble());
    await controller.open(resolve(input), autoPlay: true);
  }

  static Future<void> stopAll() async {
    for (final UMediaController controller in _pool) {
      await controller.stop();
    }
  }

  static Future<void> dispose() async {
    for (final UMediaController controller in _pool) {
      controller.dispose();
    }
    _pool.clear();
    _cache.clear();
    _cursor = 0;
  }
}
