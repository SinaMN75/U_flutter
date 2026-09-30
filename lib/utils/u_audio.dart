import "package:u/utilities.dart";

/// One app-wide music player with a queue and a lock-screen/notification control; all 6 platforms. Background play: `dart run u:app permission add background-audio`. `UAudio.play("https://x.com/song.mp3")`
abstract final class UAudio {
  static UMediaController? _instance;

  /// The shared player behind UAudio (listen to it for UI).
  static UMediaController get controller => _instance ??= UMediaController(kind: UMediaKind.audio, config: UMediaConfig.music);

  /// Player state for ValueListenableBuilder. `ValueListenableBuilder(valueListenable: UAudio.state, builder: (c, v, _) => Text(v.position.toClock()))`
  static ValueListenable<UMediaValue> get state => controller;

  /// Current state: playing, position, duration, buffering…
  static UMediaValue get value => controller.value;

  /// Position ticks while playing.
  static Stream<Duration> get positionStream => controller.positionStream;

  /// Every state change.
  static Stream<UMediaValue> get stateStream => controller.stateStream;

  /// Title/artist/artwork of the current track, or null.
  static UMediaMetadata? get nowPlaying => controller.value.metadata ?? controller.currentSource?.metadata;

  /// Tracks in the queue.
  static List<UMediaSource> get queue => controller.queue;

  /// Index of the current track in the queue.
  static int get currentIndex => controller.currentIndex;

  /// True while playing.
  static bool get isPlaying => controller.value.isPlaying;

  /// Current position.
  static Duration get position => controller.value.position;

  /// Length of the current track.
  static Duration get duration => controller.value.duration;

  /// Turns a URL, file path, "assets/…" or content:// string into a source.
  static UMediaSource source(Object input) {
    if (input is UMediaSource) return input;
    final String value = input.toString();
    if (value.startsWith("http://") || value.startsWith("https://") || value.startsWith("rtsp://") || value.startsWith("rtmp://")) return UMediaSource.network(value);
    if (value.startsWith("content://") || value.startsWith("file://")) return UMediaSource.content(value);
    if (value.startsWith("assets/") || value.startsWith("asset:")) return UMediaSource.asset(value.replaceFirst("asset:", ""));
    return UMediaSource.file(value);
  }

  /// Plays one URL, path or asset; [metadata] shows on the lock screen. `UAudio.play(url, metadata: const UMediaMetadata(title: "Song"))`
  static Future<void> play(Object input, {UMediaMetadata? metadata}) async {
    final UMediaSource resolved = source(input);
    await controller.open(resolved, autoPlay: true);
    if (metadata != null) await controller.setNotification(metadata: metadata);
  }

  /// Plays a list, starting at [startAt]. `UAudio.playQueue([a, b, c])`
  static Future<void> playQueue(List<Object> inputs, {int startAt = 0}) => controller.openQueue(inputs.map(source).toList(growable: false), startIndex: startAt, autoPlay: true);

  /// Continues playback.
  static Future<void> resume() => controller.play();

  /// Pauses.
  static Future<void> pause() => controller.pause();

  /// Play/pause.
  static Future<void> toggle() => controller.playPause();

  /// Stops and releases the current track.
  static Future<void> stop() => controller.stop();

  /// Next track in the queue.
  static Future<void> next() => controller.next();

  /// Previous track (or restart the current one).
  static Future<void> previous() => controller.previous();

  /// Plays the queue item at [index].
  static Future<void> jumpTo(int index) => controller.jumpTo(index);

  /// Jumps to a position. `UAudio.seek(30.seconds)`
  static Future<void> seek(Duration position) => controller.seek(position);

  /// Moves forward/back by [delta]. `UAudio.seekBy(-10.seconds)`
  static Future<void> seekBy(Duration delta) => controller.seekBy(delta);

  /// Adds a track to the end of the queue.
  static Future<void> add(Object input) => controller.addToQueue(source(input));

  /// Inserts a track right after the current one.
  static Future<void> playNext(Object input) => controller.insertNext(source(input));

  /// Removes a queue item.
  static Future<void> removeAt(int index) => controller.removeAt(index);

  /// Reorders the queue.
  static Future<void> move(int from, int to) => controller.moveInQueue(from, to);

  /// Playback speed, e.g. 1.5.
  static Future<void> setSpeed(double speed) => controller.setSpeed(speed);

  /// Volume 0-1.
  static Future<void> setVolume(double volume) => controller.setVolume(volume);

  /// Mutes or unmutes.
  static Future<void> setMuted(bool muted) => controller.setMuted(muted);

  /// Repeat off / one / all.
  static Future<void> setRepeat(URepeatMode mode) => controller.setRepeat(mode);

  /// Shuffle on or off.
  static Future<void> setShuffle(bool enabled) => controller.setShuffle(enabled);

  /// Flips shuffle.
  static Future<void> toggleShuffle() => controller.toggleShuffle();

  /// Shows/updates the lock-screen and notification controls for the current track.
  static Future<void> notification({required UMediaMetadata metadata, bool showSeekBar = true}) => controller.setNotification(metadata: metadata, showSeekBar: showSeekBar);

  /// Plays every audio file in a folder (not on web). `UAudio.playFolder("/storage/emulated/0/Music")`
  static Future<void> playFolder(String directoryPath, {bool recursive = true, int startAt = 0}) async {
    final List<UMediaSource> sources = await scanFolder(directoryPath, recursive: recursive);
    if (sources.isEmpty) return;
    await controller.openQueue(sources, startIndex: startAt, autoPlay: true);
  }

  /// File extensions treated as audio.
  static const Set<String> audioExtensions = <String>{".mp3", ".m4a", ".aac", ".flac", ".wav", ".ogg", ".opus", ".oga", ".wma", ".aiff", ".alac", ".mka", ".m4b"};

  /// Audio files in a folder as sources (not on web).
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

  /// Title/artist/album/artwork of an audio file.
  static Future<UMediaMetadata> readTags(String path) => UTagParser.readFile(path);

  static Future<void> dispose() async {
    _instance?.dispose();
    _instance = null;
  }
}

/// Fire-and-forget sound effects (clicks, dings) that mix with the user's music instead of pausing it. `USound.play("assets/sounds/tap.mp3")`
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

  /// Turns every sound effect on/off (e.g. from a settings switch).
  static bool enabled = true;

  /// Volume multiplier for every effect, 0-1.
  static double masterVolume = 1;

  /// How many effects can play at the same time.
  static int poolSize = 4;

  /// Turns a URL/path/asset string into a cached source.
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

  /// Warms up assets so the first play has no delay. `USound.preload(["assets/sounds/tap.mp3"])`
  static Future<void> preload(List<Object> sources) async {
    if (sources.isEmpty) return;
    for (final Object input in sources) {
      final UMediaSource source = resolve(input);
      final UMediaController controller = _acquire();
      await controller.open(source);
      await controller.pause();
    }
  }

  /// Plays an effect; [interrupt] stops the previous one on that player. `USound.play("assets/sounds/success.mp3", volume: 0.6)`
  static Future<void> play(Object input, {double volume = 1, bool interrupt = false}) async {
    if (!enabled) return;
    final UMediaController controller = _acquire();
    if (interrupt) await controller.stop();
    await controller.setVolume((volume * masterVolume).clamp(0, 1).toDouble());
    await controller.open(resolve(input), autoPlay: true);
  }

  /// Stops every effect.
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
