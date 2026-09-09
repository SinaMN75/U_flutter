import "package:u/utilities.dart";

class UMediaController extends ValueNotifier<UMediaValue> {
  UMediaController({this.kind = UMediaKind.video, this._config = const UMediaConfig()})
    : super(const UMediaValue());

  final UMediaKind kind;
  UMediaConfig _config;

  int? _playerId;
  int? _textureId;
  StreamSubscription<Map<Object?, Object?>>? _events;
  final StreamController<UMediaValue> _stateController = StreamController<UMediaValue>.broadcast();
  final ValueNotifier<List<USubtitleCue>> activeCues = ValueNotifier<List<USubtitleCue>>(const <USubtitleCue>[]);
  final ValueNotifier<List<double>> audioSpectrum = ValueNotifier<List<double>>(const <double>[]);

  final List<UMediaSource> _queue = <UMediaSource>[];
  List<int> _shuffleOrder = <int>[];
  int _index = 0;
  int _retries = 0;
  bool _disposed = false;
  bool _pausedByInterruption = false;
  double _volumeBeforeDuck = 1;

  USubtitleData? _subtitles;
  Duration _subtitleDelay = Duration.zero;
  double _subtitleScale = 1;

  UMediaConfig get config => _config;

  int? get textureId => _textureId;

  int? get playerId => _playerId;

  bool get isCreated => _playerId != null;

  Stream<UMediaValue> get stateStream => _stateController.stream;

  Stream<Duration> get positionStream => _stateController.stream.map((UMediaValue v) => v.position).distinct();

  List<UMediaSource> get queue => List<UMediaSource>.unmodifiable(_queue);

  int get currentIndex => _index;

  UMediaSource? get currentSource => _index >= 0 && _index < _queue.length ? _queue[_index] : null;

  USubtitleData? get subtitles => _subtitles;

  Duration get subtitleDelay => _subtitleDelay;

  bool get hasNext => _config.repeat == URepeatMode.all || _index < _queue.length - 1;

  bool get hasPrevious => _config.repeat == URepeatMode.all || _index > 0;

  Future<void> _ensureCreated() async {
    if (_playerId != null || _disposed) return;
    final int id = await UMediaChannel.create(kind: kind, config: _config);
    if (_disposed) {
      await UMediaChannel.call<void>(id, "dispose");
      return;
    }
    _playerId = id;
    _events = UMediaChannel.events(id).listen(_onEvent, onError: _onStreamError);
    UMediaSession.register(this);
  }

  void _emit(UMediaValue next) {
    if (_disposed) return;
    value = next;
    if (!_stateController.isClosed) _stateController.add(next);
  }

  void _onStreamError(Object error) {
    if (error is PlatformException) {
      _emit(value.copyWith(state: UMediaState.error, error: UMediaChannel.toError(error, sourceId: currentSource?.id)));
    }
  }

  void _onEvent(Map<Object?, Object?> event) {
    if (_disposed) return;
    final String type = (event["event"] as String?) ?? "";
    switch (type) {
      case "initialized":
        _textureId = event["textureId"] as int?;
        _retries = 0;
        _emit(
          value.copyWith(
            state: UMediaState.ready,
            duration: Duration(milliseconds: (event["durationMs"] as int?) ?? 0),
            width: (event["width"] as int?) ?? 0,
            height: (event["height"] as int?) ?? 0,
            rotationDegrees: (event["rotation"] as int?) ?? 0,
            isLive: event["isLive"] == true,
            tracks: _tracksFrom(event["tracks"]),
            clearError: true,
          ),
        );
        break;
      case "position":
        final Duration position = Duration(milliseconds: (event["positionMs"] as int?) ?? 0);
        _emit(
          value.copyWith(
            position: position,
            bufferedPosition: Duration(milliseconds: (event["bufferedMs"] as int?) ?? value.bufferedPosition.inMilliseconds),
          ),
        );
        _updateCues(position);
        break;
      case "state":
        _emit(value.copyWith(state: _stateFrom(event["state"] as String?)));
        break;
      case "tracks":
        _emit(value.copyWith(tracks: _tracksFrom(event["tracks"])));
        break;
      case "size":
        _emit(value.copyWith(width: (event["width"] as int?) ?? 0, height: (event["height"] as int?) ?? 0, rotationDegrees: (event["rotation"] as int?) ?? 0));
        break;
      case "buffered":
        _emit(value.copyWith(buffered: _rangesFrom(event["ranges"]), bufferedPosition: Duration(milliseconds: (event["bufferedMs"] as int?) ?? 0)));
        break;
      case "completed":
        _onCompleted();
        break;
      case "pip":
        _emit(value.copyWith(pip: _pipFrom(event["state"] as String?)));
        break;
      case "spectrum":
        final Object? raw = event["magnitudes"];
        if (raw is List<Object?>) audioSpectrum.value = raw.map((Object? v) => (v as num?)?.toDouble() ?? 0).toList(growable: false);
        break;
      case "error":
        _onNativeError(event);
        break;
    }
  }

  UMediaState _stateFrom(String? raw) {
    for (final UMediaState state in UMediaState.values) {
      if (state.name == raw) return state;
    }
    return value.state;
  }

  UPipState _pipFrom(String? raw) {
    for (final UPipState state in UPipState.values) {
      if (state.name == raw) return state;
    }
    return value.pip;
  }

  List<UMediaTrack> _tracksFrom(Object? raw) {
    if (raw is! List<Object?>) return value.tracks;
    return raw.whereType<Map<Object?, Object?>>().map(UMediaTrack.fromMap).toList(growable: false);
  }

  List<UBufferedRange> _rangesFrom(Object? raw) {
    if (raw is! List<Object?>) return const <UBufferedRange>[];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map((Map<Object?, Object?> m) => UBufferedRange(Duration(milliseconds: (m["startMs"] as int?) ?? 0), Duration(milliseconds: (m["endMs"] as int?) ?? 0)))
        .toList(growable: false);
  }

  Future<void> _onNativeError(Map<Object?, Object?> event) async {
    final UMediaError error = UMediaError.fromMap(event);
    if (error.isRecoverable && _retries < _config.retryLimit) {
      _retries++;
      await Future<void>.delayed(_config.retryDelay);
      if (_disposed) return;
      final UMediaSource? source = currentSource;
      if (source != null) await _load(source, resumeAt: value.position);
      return;
    }
    _emit(value.copyWith(state: UMediaState.error, error: error));
  }

  Future<void> _onCompleted() async {
    if (_config.repeat == URepeatMode.one) {
      await seek(Duration.zero);
      await play();
      return;
    }
    if (_index < _queue.length - 1) {
      await next();
      return;
    }
    if (_config.repeat == URepeatMode.all && _queue.isNotEmpty) {
      await jumpTo(0);
      return;
    }
    _emit(value.copyWith(state: UMediaState.completed, position: value.duration));
    await UMediaSession.abandonFocus(this);
  }

  void _updateCues(Duration position) {
    final USubtitleData? data = _subtitles;
    if (data == null || data.isEmpty || !_config.subtitlesEnabled) {
      if (activeCues.value.isNotEmpty) activeCues.value = const <USubtitleCue>[];
      return;
    }
    final List<USubtitleCue> next = data.activeAt(position, delay: _subtitleDelay, scale: _subtitleScale);
    final List<USubtitleCue> current = activeCues.value;
    if (next.length == current.length && (next.isEmpty || identical(next.first, current.first))) return;
    activeCues.value = next;
  }

  Future<void> open(UMediaSource source, {bool autoPlay = false}) async {
    _queue
      ..clear()
      ..add(source);
    _index = 0;
    _rebuildShuffle();
    await _load(source, autoPlay: autoPlay || _config.autoPlay);
  }

  Future<void> openQueue(List<UMediaSource> sources, {int startIndex = 0, bool autoPlay = false}) async {
    if (sources.isEmpty) return;
    _queue
      ..clear()
      ..addAll(sources);
    _index = startIndex.clamp(0, sources.length - 1);
    _rebuildShuffle();
    await _load(_queue[_index], autoPlay: autoPlay || _config.autoPlay);
  }

  Future<void> _load(UMediaSource source, {bool autoPlay = false, Duration? resumeAt}) async {
    await _ensureCreated();
    final int? id = _playerId;
    if (id == null) return;

    _emit(value.copyWith(state: UMediaState.loading, position: Duration.zero, duration: Duration.zero, currentIndex: _index, queueLength: _queue.length, clearError: true));
    _subtitles = null;
    activeCues.value = const <USubtitleCue>[];

    try {
      await UMediaChannel.call<void>(id, "open", <String, Object?>{
        "source": source.toMap(),
        "autoPlay": autoPlay,
        "resumeMs": (resumeAt ?? source.startPosition)?.inMilliseconds,
      });
      final UExternalSubtitle? preferred = _preferredSubtitle(source);
      if (preferred != null) await loadSubtitle(preferred);
      if (autoPlay) await play();
    } on PlatformException catch (exception) {
      _emit(value.copyWith(state: UMediaState.error, error: UMediaChannel.toError(exception, sourceId: source.id)));
    }
  }

  UExternalSubtitle? _preferredSubtitle(UMediaSource source) {
    if (source.externalSubtitles.isEmpty) return null;
    final String? language = _config.preferredSubtitleLanguage;
    for (final UExternalSubtitle subtitle in source.externalSubtitles) {
      if (language != null && subtitle.language == language) return subtitle;
    }
    for (final UExternalSubtitle subtitle in source.externalSubtitles) {
      if (subtitle.isDefault) return subtitle;
    }
    return null;
  }

  Future<void> play() async {
    final int? id = _playerId;
    if (id == null) return;
    final bool granted = await UMediaSession.requestFocus(this);
    if (!granted) return;
    _pausedByInterruption = false;
    await UMediaChannel.call<void>(id, "play");
    _emit(value.copyWith(state: UMediaState.playing, clearError: true));
  }

  Future<void> pause() async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "pause");
    _emit(value.copyWith(state: UMediaState.paused));
  }

  Future<void> playPause() => value.isPlaying ? pause() : play();

  Future<void> stop() async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "stop");
    await UMediaSession.abandonFocus(this);
    _emit(value.copyWith(state: UMediaState.idle, position: Duration.zero));
    activeCues.value = const <USubtitleCue>[];
  }

  Future<void> seek(Duration position, {bool precise = true}) async {
    final int? id = _playerId;
    if (id == null) return;
    final Duration clamped = position < Duration.zero ? Duration.zero : (value.duration > Duration.zero && position > value.duration ? value.duration : position);
    await UMediaChannel.call<void>(id, "seek", <String, Object?>{"positionMs": clamped.inMilliseconds, "precise": precise});
    _emit(value.copyWith(position: clamped));
    _updateCues(clamped);
  }

  Future<void> seekBy(Duration delta, {bool precise = true}) => seek(value.position + delta, precise: precise);

  Future<void> seekToProgress(double progress) => seek(Duration(milliseconds: (value.duration.inMilliseconds * progress.clamp(0, 1)).round()));

  Future<void> stepFrame({int frames = 1}) async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "stepFrame", <String, Object?>{"frames": frames});
  }

  Future<void> setSpeed(double speed, {bool preservePitch = true}) async {
    final int? id = _playerId;
    if (id == null) return;
    final double clamped = speed.clamp(0.0625, 8).toDouble();
    await UMediaChannel.call<void>(id, "setSpeed", <String, Object?>{"speed": clamped, "preservePitch": preservePitch});
    _emit(value.copyWith(speed: clamped));
  }

  Future<void> setVolume(double volume) async {
    final int? id = _playerId;
    if (id == null) return;
    final double clamped = volume.clamp(0, 2).toDouble();
    await UMediaChannel.call<void>(id, "setVolume", <String, Object?>{"volume": clamped});
    _emit(value.copyWith(volume: clamped, muted: clamped == 0));
  }

  Future<void> setMuted(bool muted) async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "setMuted", <String, Object?>{"muted": muted});
    _emit(value.copyWith(muted: muted));
  }

  Future<void> toggleMute() => setMuted(!value.muted);

  Future<void> setRepeat(URepeatMode mode) async {
    _config = _config.copyWith(repeat: mode);
    final int? id = _playerId;
    if (id != null) await UMediaChannel.call<void>(id, "setRepeat", <String, Object?>{"mode": mode.name});
    _emit(value.copyWith(repeat: mode));
  }

  Future<void> setShuffle(bool enabled) async {
    _config = _config.copyWith(shuffle: enabled);
    _rebuildShuffle();
    _emit(value.copyWith(shuffle: enabled));
  }

  Future<void> toggleShuffle() => setShuffle(!_config.shuffle);

  void _rebuildShuffle() {
    if (!_config.shuffle || _queue.length < 2) {
      _shuffleOrder = <int>[];
      return;
    }
    final List<int> order = List<int>.generate(_queue.length, (int i) => i);
    final Random random = Random();
    for (int i = order.length - 1; i > 0; i--) {
      final int j = random.nextInt(i + 1);
      final int temp = order[i];
      order[i] = order[j];
      order[j] = temp;
    }
    final int currentPosition = order.indexOf(_index);
    if (currentPosition > 0) {
      order[currentPosition] = order[0];
      order[0] = _index;
    }
    _shuffleOrder = order;
  }

  int _nextIndex() {
    if (_queue.isEmpty) return _index;
    if (!_config.shuffle || _shuffleOrder.isEmpty) {
      final int candidate = _index + 1;
      return candidate < _queue.length ? candidate : (_config.repeat == URepeatMode.all ? 0 : _index);
    }
    final int position = _shuffleOrder.indexOf(_index);
    final int nextPosition = position + 1;
    if (nextPosition < _shuffleOrder.length) return _shuffleOrder[nextPosition];
    return _config.repeat == URepeatMode.all ? _shuffleOrder.first : _index;
  }

  int _previousIndex() {
    if (_queue.isEmpty) return _index;
    if (!_config.shuffle || _shuffleOrder.isEmpty) {
      final int candidate = _index - 1;
      return candidate >= 0 ? candidate : (_config.repeat == URepeatMode.all ? _queue.length - 1 : 0);
    }
    final int position = _shuffleOrder.indexOf(_index);
    final int previousPosition = position - 1;
    if (previousPosition >= 0) return _shuffleOrder[previousPosition];
    return _config.repeat == URepeatMode.all ? _shuffleOrder.last : _index;
  }

  Future<void> next() async {
    final int target = _nextIndex();
    if (target == _index && _config.repeat != URepeatMode.all) return;
    await jumpTo(target);
  }

  Future<void> previous({Duration restartThreshold = const Duration(seconds: 3)}) async {
    if (value.position > restartThreshold) {
      await seek(Duration.zero);
      return;
    }
    await jumpTo(_previousIndex());
  }

  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _index = index;
    await _load(_queue[index], autoPlay: true);
  }

  Future<void> addToQueue(UMediaSource source) async {
    _queue.add(source);
    _rebuildShuffle();
    _emit(value.copyWith(queueLength: _queue.length));
  }

  Future<void> insertNext(UMediaSource source) async {
    _queue.insert((_index + 1).clamp(0, _queue.length), source);
    _rebuildShuffle();
    _emit(value.copyWith(queueLength: _queue.length));
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (index < _index) _index--;
    _rebuildShuffle();
    _emit(value.copyWith(queueLength: _queue.length, currentIndex: _index));
  }

  Future<void> moveInQueue(int from, int to) async {
    if (from < 0 || from >= _queue.length || to < 0 || to >= _queue.length) return;
    final UMediaSource source = _queue.removeAt(from);
    _queue.insert(to, source);
    if (_index == from) {
      _index = to;
    } else if (from < _index && to >= _index) {
      _index--;
    } else if (from > _index && to <= _index) {
      _index++;
    }
    _rebuildShuffle();
    _emit(value.copyWith(currentIndex: _index));
  }

  Future<void> selectTrack(UMediaTrack track) async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "selectTrack", <String, Object?>{"trackId": track.id, "type": track.type.name});
    _emit(value.copyWith(tracks: value.tracks.map((UMediaTrack t) => t.type == track.type ? t.copyWith(isSelected: t.id == track.id) : t).toList(growable: false)));
  }

  Future<void> setAutoQuality() async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "setAutoQuality");
  }

  Future<void> setMaxHeight(int height) async {
    _config = _config.copyWith(maxHeight: height);
    final int? id = _playerId;
    if (id != null) await UMediaChannel.call<void>(id, "setMaxHeight", <String, Object?>{"height": height});
  }

  Future<void> setAudioDelay(Duration delay) async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "setAudioDelay", <String, Object?>{"delayMs": delay.inMilliseconds});
  }

  Future<void> loadSubtitle(UExternalSubtitle subtitle) async {
    try {
      final Uint8List bytes = await _fetchBytes(subtitle.uri);
      if (bytes.isEmpty || _disposed) return;
      final USubtitleData data = await compute(_parseSubtitleJob, _SubtitleJob(bytes, subtitle.format, subtitle.encoding, subtitle.language, subtitle.label));
      if (_disposed) return;
      _subtitles = data;
      _updateCues(value.position);
    } on FileSystemException {
      return;
    } on ClientException {
      return;
    }
  }

  Future<void> loadSubtitleData(USubtitleData data) async {
    _subtitles = data;
    _updateCues(value.position);
  }

  Future<Uint8List> _fetchBytes(String uri) async {
    if (uri.startsWith("http://") || uri.startsWith("https://")) {
      final Client client = Client();
      try {
        final Response response = await client.get(Uri.parse(uri)).timeout(_config.connectTimeout);
        return response.statusCode >= 200 && response.statusCode < 300 ? response.bodyBytes : Uint8List(0);
      } on TimeoutException {
        return Uint8List(0);
      } finally {
        client.close();
      }
    }
    if (kIsWeb) return Uint8List(0);
    return File(uri).readAsBytes();
  }

  void clearSubtitles() {
    _subtitles = null;
    activeCues.value = const <USubtitleCue>[];
  }

  void setSubtitleDelay(Duration delay) {
    _subtitleDelay = delay;
    _updateCues(value.position);
  }

  void setSubtitleScale(double scale) {
    _subtitleScale = scale <= 0 ? 1 : scale;
    _updateCues(value.position);
  }

  void setSubtitlesEnabled(bool enabled) {
    _config = _config.copyWith(subtitlesEnabled: enabled);
    _updateCues(value.position);
  }

  Future<void> enterPip({double? aspectRatio}) async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "enterPip", <String, Object?>{"aspectRatio": aspectRatio ?? value.aspectRatio});
  }

  Future<void> exitPip() async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "exitPip");
  }

  Future<void> startVisualizer({int bands = 48}) async {
    final int? id = _playerId;
    if (id == null) return;
    try {
      await UMediaChannel.call<void>(id, "startVisualizer", <String, Object?>{"bands": bands});
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  Future<void> stopVisualizer() async {
    final int? id = _playerId;
    if (id == null) return;
    audioSpectrum.value = const <double>[];
    try {
      await UMediaChannel.call<void>(id, "stopVisualizer");
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  Future<Uint8List?> screenshot() async {
    final int? id = _playerId;
    if (id == null) return null;
    return UMediaChannel.call<Uint8List>(id, "screenshot");
  }

  Future<void> setNotification({required UMediaMetadata metadata, bool showSeekBar = true}) async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "setNotification", <String, Object?>{"metadata": metadata.toMap(), "showSeekBar": showSeekBar});
    _emit(value.copyWith(metadata: metadata));
  }

  Future<void> pauseForInterruption() async {
    if (!value.isPlaying) return;
    _pausedByInterruption = true;
    await pause();
  }

  Future<void> resumeAfterInterruption() async {
    if (!_pausedByInterruption) return;
    _pausedByInterruption = false;
    await play();
  }

  Future<void> applyDuck(bool ducking) async {
    if (ducking) {
      _volumeBeforeDuck = value.volume;
      await setVolume(_volumeBeforeDuck * 0.3);
      return;
    }
    await setVolume(_volumeBeforeDuck);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final int? id = _playerId;
    _playerId = null;
    unawaited(_events?.cancel());
    _events = null;
    UMediaSession.unregister(this);
    if (id != null) unawaited(UMediaChannel.call<void>(id, "dispose"));
    unawaited(_stateController.close());
    activeCues.dispose();
    audioSpectrum.dispose();
    super.dispose();
  }
}

class _SubtitleJob {
  const _SubtitleJob(this.bytes, this.format, this.encoding, this.language, this.label);

  final Uint8List bytes;
  final USubtitleFormat? format;
  final String? encoding;
  final String? language;
  final String? label;
}

USubtitleData _parseSubtitleJob(_SubtitleJob job) => USubtitleParser.parseBytes(job.bytes, format: job.format, encoding: job.encoding, language: job.language, label: job.label);
