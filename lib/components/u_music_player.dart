import "package:u/utilities.dart";

class UMediaQueueSheet extends StatelessWidget {
  const UMediaQueueSheet({required this.controller, super.key});

  final UMediaController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UMediaValue>(
    valueListenable: controller,
    builder: (BuildContext context, UMediaValue value, Widget? child) {
      final List<UMediaSource> queue = controller.queue;
      return UColumn(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: URow(
              children: <Widget>[
                Expanded(child: UTextTitleMedium("${U.s.queue} (${queue.length})", fontWeight: FontWeight.w700)),
                IconButton(
                  tooltip: U.s.shuffle,
                  onPressed: () => unawaited(controller.toggleShuffle()),
                  icon: Icon(Icons.shuffle_rounded, color: value.shuffle ? Theme.of(context).colorScheme.primary : null),
                ),
                IconButton(
                  tooltip: _repeatLabel(value.repeat),
                  onPressed: () => unawaited(controller.setRepeat(_nextRepeat(value.repeat))),
                  icon: Icon(
                    value.repeat == URepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                    color: value.repeat == URepeatMode.off ? null : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              itemCount: queue.length,
              onReorder: (int from, int to) => unawaited(controller.moveInQueue(from, to > from ? to - 1 : to)),
              itemBuilder: (BuildContext context, int index) {
                final UMediaSource item = queue[index];
                final bool current = index == value.currentIndex;
                return ListTile(
                  key: ValueKey<String>("${item.id}-$index"),
                  leading: UArtwork(artwork: item.metadata?.artwork, size: 44),
                  title: UTextBodyMedium(item.metadata?.displayTitle.isNotEmpty == true ? item.metadata!.displayTitle : item.id, maxLines: 1),
                  subtitle: item.metadata?.displaySubtitle.isNotEmpty == true ? UTextLabelSmall(item.metadata!.displaySubtitle, maxLines: 1) : null,
                  selected: current,
                  trailing: IconButton(
                    tooltip: U.s.removeFromQueue,
                    onPressed: () => unawaited(controller.removeAt(index)),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                  onTap: () => unawaited(controller.jumpTo(index)),
                );
              },
            ),
          ),
        ],
      );
    },
  );

  String _repeatLabel(URepeatMode mode) {
    switch (mode) {
      case URepeatMode.off:
        return U.s.repeatOff;
      case URepeatMode.one:
        return U.s.repeatOne;
      case URepeatMode.all:
        return U.s.repeatAll;
    }
  }

  URepeatMode _nextRepeat(URepeatMode mode) {
    switch (mode) {
      case URepeatMode.off:
        return URepeatMode.all;
      case URepeatMode.all:
        return URepeatMode.one;
      case URepeatMode.one:
        return URepeatMode.off;
    }
  }
}

class UMiniPlayerBar extends StatelessWidget {
  const UMiniPlayerBar({required this.controller, super.key, this.onTap, this.onClose, this.height = 64, this.showProgress = true});

  final UMediaController controller;
  final VoidCallback? onTap;
  final VoidCallback? onClose;
  final double height;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<UMediaValue>(
      valueListenable: controller,
      builder: (BuildContext context, UMediaValue value, Widget? child) {
        final UMediaMetadata? metadata = value.metadata ?? controller.currentSource?.metadata;
        if (controller.currentSource == null) return const SizedBox.shrink();

        return Material(
          color: scheme.surfaceContainerHigh,
          child: InkWell(
            onTap: onTap,
            child: UColumn(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (showProgress)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: LinearProgressIndicator(
                      value: value.progress,
                      minHeight: 2,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                SizedBox(
                  height: height,
                  child: URow(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    spacing: 10,
                    children: <Widget>[
                      UArtwork(artwork: metadata?.artwork, size: height - 16),
                      Expanded(
                        child: UColumn(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            UTextBodyMedium(metadata?.displayTitle.isNotEmpty == true ? metadata!.displayTitle : U.s.unknownTitle, fontWeight: FontWeight.w600, maxLines: 1),
                            if (metadata?.displaySubtitle.isNotEmpty == true) UTextLabelSmall(metadata!.displaySubtitle, color: scheme.onSurfaceVariant, maxLines: 1),
                          ],
                        ),
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: URow(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              tooltip: U.s.previous,
                              onPressed: controller.hasPrevious ? () => unawaited(controller.previous()) : null,
                              icon: const Icon(Icons.skip_previous_rounded),
                            ),
                            IconButton(
                              tooltip: value.isPlaying ? U.s.pause : U.s.play,
                              onPressed: () => unawaited(controller.playPause()),
                              icon: Icon(value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30),
                            ),
                            IconButton(
                              tooltip: U.s.next,
                              onPressed: controller.hasNext ? () => unawaited(controller.next()) : null,
                              icon: const Icon(Icons.skip_next_rounded),
                            ),
                          ],
                        ),
                      ),
                      if (onClose != null)
                        IconButton(tooltip: U.s.close, onPressed: onClose, icon: const Icon(Icons.close_rounded, size: 18)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

abstract final class UArtworkCache {
  static const int _maxEntries = 30;
  static const int _maxBytes = 16 * 1024 * 1024;
  static const int _maxSingleArtwork = 8 * 1024 * 1024;

  static final Map<String, Uint8List> _memory = <String, Uint8List>{};
  static int _bytesHeld = 0;

  static int get bytesHeld => _bytesHeld;

  static void clear() {
    _memory.clear();
    _bytesHeld = 0;
  }

  static Uint8List? peek(UArtworkRef ref) {
    final Uint8List? cached = _memory.remove(ref.cacheKey);
    if (cached == null) return null;
    _memory[ref.cacheKey] = cached;
    return cached;
  }

  static Future<Uint8List?> load(UArtworkRef ref) async {
    if (ref.isEmpty) return null;
    final Uint8List? cached = peek(ref);
    if (cached != null) return cached;
    if (!ref.isEmbedded) return null;

    RandomAccessFile? handle;
    try {
      handle = await File(ref.filePath!).open();
      final int length = await handle.length();
      if (ref.offset < 0 || ref.offset >= length) return null;
      final int available = length - ref.offset;
      final int requested = ref.length > available ? available : ref.length;
      if (requested <= 0 || requested > _maxSingleArtwork) return null;
      await handle.setPosition(ref.offset);
      final Uint8List bytes = await handle.read(requested);
      _store(ref.cacheKey, bytes);
      return bytes;
    } on FileSystemException {
      return null;
    } finally {
      await handle?.close();
    }
  }

  static void _store(String key, Uint8List bytes) {
    _memory[key] = bytes;
    _bytesHeld += bytes.length;
    while (_memory.length > _maxEntries || _bytesHeld > _maxBytes) {
      if (_memory.isEmpty) break;
      final String oldest = _memory.keys.first;
      final Uint8List? removed = _memory.remove(oldest);
      _bytesHeld -= removed?.length ?? 0;
    }
    if (_bytesHeld < 0) _bytesHeld = 0;
  }
}

class UArtwork extends StatefulWidget {
  const UArtwork({super.key, this.artwork, this.size = 56, this.borderRadius = 8, this.placeholder, this.fit = BoxFit.cover});

  final UArtworkRef? artwork;
  final double size;
  final double borderRadius;
  final Widget? placeholder;
  final BoxFit fit;

  @override
  State<UArtwork> createState() => _UArtworkState();
}

class _UArtworkState extends State<UArtwork> {
  Uint8List? _bytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant UArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artwork?.cacheKey != widget.artwork?.cacheKey) {
      _bytes = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final UArtworkRef? ref = widget.artwork;
    if (ref == null || ref.isEmpty) return;
    final Uint8List? cached = UArtworkCache.peek(ref);
    if (cached != null) {
      setState(() => _bytes = cached);
      return;
    }
    if (!ref.isEmbedded || _loading) return;
    _loading = true;
    final Uint8List? loaded = await UArtworkCache.load(ref);
    _loading = false;
    if (!mounted) return;
    setState(() => _bytes = loaded);
  }

  @override
  Widget build(BuildContext context) {
    final double pixels = widget.size * MediaQuery.of(context).devicePixelRatio;
    final int cacheSize = pixels.round().clamp(32, 1024);
    final UArtworkRef? ref = widget.artwork;

    Widget child;
    if (_bytes != null) {
      child = Image.memory(_bytes!, width: widget.size, height: widget.size, fit: widget.fit, cacheWidth: cacheSize, cacheHeight: cacheSize, gaplessPlayback: true);
    } else if (ref != null && ref.uri != null && ref.uri!.isNotEmpty) {
      child = Image.network(ref.uri!, width: widget.size, height: widget.size, fit: widget.fit, cacheWidth: cacheSize, cacheHeight: cacheSize, errorBuilder: (BuildContext context, Object error, StackTrace? stack) => _fallback(context));
    } else {
      child = _fallback(context);
    }

    return ClipRRect(borderRadius: BorderRadius.circular(widget.borderRadius), child: SizedBox(width: widget.size, height: widget.size, child: child));
  }

  Widget _fallback(BuildContext context) =>
      widget.placeholder ??
      ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(Icons.music_note, size: widget.size * 0.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
}

class ULyrics {
  const ULyrics({required this.lines, this.synced = false, this.source});

  final List<USubtitleCue> lines;
  final bool synced;
  final String? source;

  static const ULyrics empty = ULyrics(lines: <USubtitleCue>[]);

  bool get isEmpty => lines.isEmpty;

  String get plainText => lines.map((USubtitleCue cue) => cue.text).join("\n");

  int indexAt(Duration position) {
    if (!synced || lines.isEmpty) return -1;
    int low = 0;
    int high = lines.length - 1;
    int found = -1;
    while (low <= high) {
      final int mid = (low + high) >> 1;
      if (lines[mid].start <= position) {
        found = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return found;
  }

  static ULyrics fromText(String text, {String? source}) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return empty;
    if (USubtitleParser.detectFormat(trimmed) == USubtitleFormat.lrc) {
      final USubtitleData data = USubtitleParser.parse(trimmed, format: USubtitleFormat.lrc);
      if (data.cues.isNotEmpty) return ULyrics(lines: data.cues, synced: true, source: source);
    }
    final List<USubtitleCue> lines = trimmed
        .split("\n")
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .map((String line) => USubtitleCue(start: Duration.zero, end: Duration.zero, spans: <USubtitleSpan>[USubtitleSpan(line)], text: line))
        .toList(growable: false);
    return ULyrics(lines: lines, source: source);
  }

  static Future<ULyrics> load(UMediaSource source) async {
    final String? embedded = source.metadata?.lyrics;
    if (embedded != null && embedded.trim().isNotEmpty) return fromText(embedded, source: "embedded");

    if (kIsWeb || source is! UFileSource) return empty;
    final String path = source.path;
    final int dot = path.lastIndexOf(".");
    if (dot <= 0) return empty;

    for (final String extension in <String>[".lrc", ".txt"]) {
      final File candidate = File(path.substring(0, dot) + extension);
      try {
        final Uint8List bytes = await candidate.readAsBytes();
        return fromText(UTextDecoder.decode(bytes).text, source: candidate.path);
      } on FileSystemException {
        continue;
      }
    }

    final UMediaMetadata tags = await UTagParser.readFile(path);
    final String? fromTags = tags.lyrics;
    return fromTags == null || fromTags.trim().isEmpty ? empty : fromText(fromTags, source: "tags");
  }
}

class ULyricsView extends StatefulWidget {
  const ULyricsView({required this.controller, required this.lyrics, super.key, this.textAlign = TextAlign.center, this.autoScroll = true, this.onSeek});

  final UMediaController controller;
  final ULyrics lyrics;
  final TextAlign textAlign;
  final bool autoScroll;
  final void Function(Duration position)? onSeek;

  @override
  State<ULyricsView> createState() => _ULyricsViewState();
}

class _ULyricsViewState extends State<ULyricsView> {
  final ScrollController _scrollController = ScrollController();
  int _activeIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(int index) {
    if (!widget.autoScroll || !_scrollController.hasClients || index < 0) return;
    final double target = (index * 46.0 - _scrollController.position.viewportDimension / 2 + 23).clamp(0, _scrollController.position.maxScrollExtent);
    unawaited(_scrollController.animateTo(target, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic));
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (widget.lyrics.isEmpty) {
      return Center(child: UTextBodyMedium(U.s.noLyricsFound, color: scheme.onSurfaceVariant));
    }

    return ValueListenableBuilder<UMediaValue>(
      valueListenable: widget.controller,
      builder: (BuildContext context, UMediaValue value, Widget? child) {
        final int index = widget.lyrics.indexAt(value.position);
        if (index != _activeIndex) {
          _activeIndex = index;
          WidgetsBinding.instance.addPostFrameCallback((Duration _) => _scrollTo(index));
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          itemCount: widget.lyrics.lines.length,
          itemBuilder: (BuildContext context, int i) {
            final USubtitleCue line = widget.lyrics.lines[i];
            final bool active = widget.lyrics.synced && i == index;
            return UContainer(
              onTap: widget.lyrics.synced ? () => widget.onSeek?.call(line.start) : null,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Directionality(
                textDirection: UBidi.directionOf(line.text),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    fontSize: active ? 20 : 17,
                    height: 1.35,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    color: active ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: widget.lyrics.synced ? 0.6 : 1),
                  ),
                  textAlign: widget.textAlign,
                  child: Text(line.text, textAlign: widget.textAlign),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class UEqualizerBand {
  const UEqualizerBand({required this.index, required this.centerFrequencyHz, required this.gainDb, required this.minDb, required this.maxDb});

  final int index;
  final int centerFrequencyHz;
  final double gainDb;
  final double minDb;
  final double maxDb;

  String get label => centerFrequencyHz >= 1000 ? "${(centerFrequencyHz / 1000).toStringAsFixed(centerFrequencyHz % 1000 == 0 ? 0 : 1)}k" : "$centerFrequencyHz";

  factory UEqualizerBand.fromMap(Map<Object?, Object?> map) => UEqualizerBand(
    index: (map["index"] as int?) ?? 0,
    centerFrequencyHz: (map["centerFrequencyHz"] as int?) ?? 0,
    gainDb: (map["gainDb"] as num?)?.toDouble() ?? 0,
    minDb: (map["minDb"] as num?)?.toDouble() ?? -15,
    maxDb: (map["maxDb"] as num?)?.toDouble() ?? 15,
  );

  UEqualizerBand copyWith({double? gainDb}) =>
      UEqualizerBand(index: index, centerFrequencyHz: centerFrequencyHz, gainDb: gainDb ?? this.gainDb, minDb: minDb, maxDb: maxDb);
}

class UEqualizerState {
  const UEqualizerState({this.available = false, this.enabled = false, this.bands = const <UEqualizerBand>[], this.presets = const <String>[], this.preset, this.bassBoost = 0, this.virtualizer = 0, this.loudness = 0});

  final bool available;
  final bool enabled;
  final List<UEqualizerBand> bands;
  final List<String> presets;
  final String? preset;
  final double bassBoost;
  final double virtualizer;
  final double loudness;

  factory UEqualizerState.fromMap(Map<Object?, Object?> map) => UEqualizerState(
    available: map["available"] == true,
    enabled: map["enabled"] == true,
    bands: ((map["bands"] as List<Object?>?) ?? const <Object?>[]).whereType<Map<Object?, Object?>>().map(UEqualizerBand.fromMap).toList(growable: false),
    presets: ((map["presets"] as List<Object?>?) ?? const <Object?>[]).whereType<String>().toList(growable: false),
    preset: map["preset"] as String?,
    bassBoost: (map["bassBoost"] as num?)?.toDouble() ?? 0,
    virtualizer: (map["virtualizer"] as num?)?.toDouble() ?? 0,
    loudness: (map["loudness"] as num?)?.toDouble() ?? 0,
  );

  UEqualizerState copyWith({bool? enabled, List<UEqualizerBand>? bands, String? preset, double? bassBoost, double? virtualizer, double? loudness}) => UEqualizerState(
    available: available,
    enabled: enabled ?? this.enabled,
    bands: bands ?? this.bands,
    presets: presets,
    preset: preset ?? this.preset,
    bassBoost: bassBoost ?? this.bassBoost,
    virtualizer: virtualizer ?? this.virtualizer,
    loudness: loudness ?? this.loudness,
  );
}

class UEqualizer {
  UEqualizer(this.controller);

  final UMediaController controller;

  Future<UEqualizerState> read() async {
    final int? id = controller.playerId;
    if (id == null) return const UEqualizerState();
    try {
      final Map<Object?, Object?>? map = await UMediaChannel.call<Map<Object?, Object?>>(id, "getEqualizer");
      return map == null ? const UEqualizerState() : UEqualizerState.fromMap(map);
    } on PlatformException {
      return const UEqualizerState();
    } on MissingPluginException {
      return const UEqualizerState();
    }
  }

  Future<void> setEnabled(bool enabled) => _call("setEqualizerEnabled", <String, Object?>{"enabled": enabled});

  Future<void> setBand(int index, double gainDb) => _call("setEqualizerBand", <String, Object?>{"index": index, "gainDb": gainDb});

  Future<void> setPreset(String preset) => _call("setEqualizerPreset", <String, Object?>{"preset": preset});

  Future<void> setBassBoost(double strength) => _call("setBassBoost", <String, Object?>{"strength": strength});

  Future<void> setVirtualizer(double strength) => _call("setVirtualizer", <String, Object?>{"strength": strength});

  Future<void> setLoudness(double gainDb) => _call("setLoudness", <String, Object?>{"gainDb": gainDb});

  Future<void> _call(String method, Map<String, Object?> arguments) async {
    final int? id = controller.playerId;
    if (id == null) return;
    try {
      await UMediaChannel.call<void>(id, method, arguments);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}

class UEqualizerSheet extends StatefulWidget {
  const UEqualizerSheet({required this.controller, super.key});

  final UMediaController controller;

  @override
  State<UEqualizerSheet> createState() => _UEqualizerSheetState();
}

class _UEqualizerSheetState extends State<UEqualizerSheet> {
  late final UEqualizer _equalizer = UEqualizer(widget.controller);
  UEqualizerState _state = const UEqualizerState();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final UEqualizerState state = await _equalizer.read();
    if (!mounted) return;
    setState(() {
      _state = state;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (_loading) return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
    if (!_state.available) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: UTextBodyMedium(U.s.equalizerUnavailable, color: scheme.onSurfaceVariant, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return UColumn(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        URow(
          children: <Widget>[
            Expanded(child: UTextTitleMedium(U.s.equalizer, fontWeight: FontWeight.w700)),
            Switch(
              value: _state.enabled,
              onChanged: (bool value) {
                unawaited(_equalizer.setEnabled(value));
                setState(() => _state = _state.copyWith(enabled: value));
              },
            ),
          ],
        ),
        if (_state.presets.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _state.presets
                  .map(
                    (String preset) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(preset),
                        selected: _state.preset == preset,
                        onSelected: (bool _) {
                          unawaited(_equalizer.setPreset(preset));
                          unawaited(_load());
                        },
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        SizedBox(
          height: 200,
          child: URow(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _state.bands
                .map(
                  (UEqualizerBand band) => UColumn(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Slider(
                            value: band.gainDb.clamp(band.minDb, band.maxDb),
                            min: band.minDb,
                            max: band.maxDb,
                            onChanged: (double value) {
                              setState(() {
                                _state = _state.copyWith(
                                  bands: _state.bands.map((UEqualizerBand b) => b.index == band.index ? b.copyWith(gainDb: value) : b).toList(growable: false),
                                );
                              });
                              unawaited(_equalizer.setBand(band.index, value));
                            },
                          ),
                        ),
                      ),
                      UTextLabelSmall(band.label, color: scheme.onSurfaceVariant),
                    ],
                  ),
                )
                .toList(growable: false),
          ),
        ),
        _effectSlider(U.s.bassBoost, _state.bassBoost, (double value) {
          setState(() => _state = _state.copyWith(bassBoost: value));
          unawaited(_equalizer.setBassBoost(value));
        }),
        _effectSlider(U.s.virtualizer, _state.virtualizer, (double value) {
          setState(() => _state = _state.copyWith(virtualizer: value));
          unawaited(_equalizer.setVirtualizer(value));
        }),
        _effectSlider(U.s.loudnessNormalization, _state.loudness, (double value) {
          setState(() => _state = _state.copyWith(loudness: value));
          unawaited(_equalizer.setLoudness(value));
        }),
      ],
    );
  }

  Widget _effectSlider(String label, double value, ValueChanged<double> onChanged) => UColumn(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      UTextLabelLarge(label),
      Slider(value: value.clamp(0, 1), onChanged: onChanged),
    ],
  );
}

enum UVisualizerStyle { bars, mirroredBars, wave, circle }

class UVisualizer extends StatefulWidget {
  const UVisualizer({
    required this.controller,
    super.key,
    this.style = UVisualizerStyle.bars,
    this.barCount = 48,
    this.color,
    this.gradient,
    this.height = 120,
    this.spacing = 2,
    this.borderRadius = 2,
    this.smoothing = 0.35,
  });

  final UMediaController controller;
  final UVisualizerStyle style;
  final int barCount;
  final Color? color;
  final List<Color>? gradient;
  final double height;
  final double spacing;
  final double borderRadius;
  final double smoothing;

  @override
  State<UVisualizer> createState() => _UVisualizerState();
}

class _UVisualizerState extends State<UVisualizer> {
  List<double> _smoothed = <double>[];

  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.startVisualizer(bands: widget.barCount));
  }

  @override
  void dispose() {
    unawaited(widget.controller.stopVisualizer());
    super.dispose();
  }

  List<double> _apply(List<double> input) {
    if (input.isEmpty) return _smoothed;
    if (_smoothed.length != input.length) {
      _smoothed = List<double>.of(input);
      return _smoothed;
    }
    for (int i = 0; i < input.length; i++) {
      _smoothed[i] = _smoothed[i] * widget.smoothing + input[i] * (1 - widget.smoothing);
    }
    return _smoothed;
  }

  @override
  Widget build(BuildContext context) {
    final Color base = widget.color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: widget.height,
      child: ValueListenableBuilder<List<double>>(
        valueListenable: widget.controller.audioSpectrum,
        builder: (BuildContext context, List<double> raw, Widget? child) => CustomPaint(
          painter: _VisualizerPainter(
            magnitudes: _apply(raw),
            style: widget.style,
            color: base,
            gradient: widget.gradient,
            spacing: widget.spacing,
            borderRadius: widget.borderRadius,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  _VisualizerPainter({
    required this.magnitudes,
    required this.style,
    required this.color,
    required this.spacing,
    required this.borderRadius,
    this.gradient,
  });

  final List<double> magnitudes;
  final UVisualizerStyle style;
  final Color color;
  final List<Color>? gradient;
  final double spacing;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (magnitudes.isEmpty) return;
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final List<Color>? colors = gradient;
    if (colors != null && colors.length >= 2) {
      paint.shader = LinearGradient(colors: colors, begin: Alignment.bottomCenter, end: Alignment.topCenter).createShader(Offset.zero & size);
    } else {
      paint.color = color;
    }

    switch (style) {
      case UVisualizerStyle.bars:
        _paintBars(canvas, size, paint, false);
        break;
      case UVisualizerStyle.mirroredBars:
        _paintBars(canvas, size, paint, true);
        break;
      case UVisualizerStyle.wave:
        _paintWave(canvas, size, paint);
        break;
      case UVisualizerStyle.circle:
        _paintCircle(canvas, size, paint);
        break;
    }
  }

  void _paintBars(Canvas canvas, Size size, Paint paint, bool mirrored) {
    final double barWidth = (size.width - spacing * (magnitudes.length - 1)) / magnitudes.length;
    if (barWidth <= 0) return;
    for (int i = 0; i < magnitudes.length; i++) {
      final double magnitude = magnitudes[i].clamp(0, 1).toDouble();
      final double barHeight = (mirrored ? size.height / 2 : size.height) * magnitude;
      final double left = i * (barWidth + spacing);
      final Rect rect = mirrored
          ? Rect.fromLTWH(left, size.height / 2 - barHeight, barWidth, barHeight * 2)
          : Rect.fromLTWH(left, size.height - barHeight, barWidth, barHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)), paint);
    }
  }

  void _paintWave(Canvas canvas, Size size, Paint paint) {
    final Path path = Path()..moveTo(0, size.height / 2);
    final double step = size.width / (magnitudes.length - 1).clamp(1, magnitudes.length);
    for (int i = 0; i < magnitudes.length; i++) {
      final double y = size.height / 2 - (magnitudes[i].clamp(0, 1) - 0.5) * size.height;
      path.lineTo(i * step, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _paintCircle(Canvas canvas, Size size, Paint paint) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.shortestSide / 4;
    final double sweep = 2 * pi / magnitudes.length;
    for (int i = 0; i < magnitudes.length; i++) {
      final double magnitude = magnitudes[i].clamp(0, 1).toDouble();
      final double angle = i * sweep - pi / 2;
      final Offset start = center + Offset(cos(angle) * radius, sin(angle) * radius);
      final Offset end = center + Offset(cos(angle) * (radius + magnitude * radius), sin(angle) * (radius + magnitude * radius));
      canvas.drawLine(start, end, Paint()
        ..color = paint.color
        ..shader = paint.shader
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) => true;
}

enum UMusicPlayerLayout { full, card, compact }

class UMusicPlayerTheme {
  const UMusicPlayerTheme({
    this.accentColor,
    this.backgroundColor,
    this.artworkSize,
    this.artworkRadius = 18,
    this.controlSize = 36,
    this.playButtonSize = 64,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.showArtwork = true,
    this.showTitle = true,
    this.showSeekBar = true,
    this.showTimes = true,
    this.showShuffle = true,
    this.showRepeat = true,
    this.showSkip = true,
    this.showQueue = true,
    this.showLyrics = true,
    this.showEqualizer = true,
    this.showVisualizer = false,
    this.showSpeed = true,
    this.showSleepTimer = true,
    this.showVolume = true,
    this.showFavorite = false,
    this.visualizerStyle = UVisualizerStyle.mirroredBars,
    this.visualizerHeight = 90,
  });

  final Color? accentColor;
  final Color? backgroundColor;
  final double? artworkSize;
  final double artworkRadius;
  final double controlSize;
  final double playButtonSize;
  final EdgeInsetsGeometry padding;
  final bool showArtwork;
  final bool showTitle;
  final bool showSeekBar;
  final bool showTimes;
  final bool showShuffle;
  final bool showRepeat;
  final bool showSkip;
  final bool showQueue;
  final bool showLyrics;
  final bool showEqualizer;
  final bool showVisualizer;
  final bool showSpeed;
  final bool showSleepTimer;
  final bool showVolume;
  final bool showFavorite;
  final UVisualizerStyle visualizerStyle;
  final double visualizerHeight;

  static const UMusicPlayerTheme minimal = UMusicPlayerTheme(
    showShuffle: false,
    showRepeat: false,
    showQueue: false,
    showLyrics: false,
    showEqualizer: false,
    showSpeed: false,
    showSleepTimer: false,
    showVolume: false,
  );
}

/// The music player component. Every region has a builder slot, so the default
/// layout can be replaced piece by piece without rewriting the widget.
class UMusicPlayer extends StatefulWidget {
  const UMusicPlayer({
    super.key,
    this.controller,
    this.layout = UMusicPlayerLayout.full,
    this.theme = const UMusicPlayerTheme(),
    this.header,
    this.footer,
    this.actions = const <Widget>[],
    this.onClose,
    this.onFavorite,
    this.isFavorite = false,
    this.artworkBuilder,
    this.titleBuilder,
    this.seekBarBuilder,
    this.controlsBuilder,
    this.extrasBuilder,
  });

  final UMediaController? controller;
  final UMusicPlayerLayout layout;
  final UMusicPlayerTheme theme;
  final Widget? header;
  final Widget? footer;
  final List<Widget> actions;
  final VoidCallback? onClose;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  final Widget Function(BuildContext context, UMediaMetadata? metadata, double size)? artworkBuilder;
  final Widget Function(BuildContext context, UMediaMetadata? metadata)? titleBuilder;
  final Widget Function(BuildContext context, UMediaValue value)? seekBarBuilder;
  final Widget Function(BuildContext context, UMediaValue value)? controlsBuilder;
  final Widget Function(BuildContext context, UMediaValue value)? extrasBuilder;

  @override
  State<UMusicPlayer> createState() => _UMusicPlayerState();
}

class _UMusicPlayerState extends State<UMusicPlayer> {
  UMediaController get _controller => widget.controller ?? UAudio.controller;

  UMusicPlayerTheme get _theme => widget.theme;

  ULyrics _lyrics = ULyrics.empty;
  String? _lyricsForId;
  bool _showingLyrics = false;
  double? _scrubValue;
  Timer? _sleepTimer;
  DateTime? _sleepAt;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    unawaited(_loadLyrics());
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (_controller.currentSource?.id != _lyricsForId) unawaited(_loadLyrics());
  }

  Future<void> _loadLyrics() async {
    if (!_theme.showLyrics) return;
    final UMediaSource? source = _controller.currentSource;
    if (source == null) return;
    _lyricsForId = source.id;
    final ULyrics loaded = await ULyrics.load(source);
    if (!mounted) return;
    setState(() => _lyrics = loaded);
  }

  Color _accent(BuildContext context) => _theme.accentColor ?? Theme.of(context).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    if (widget.layout == UMusicPlayerLayout.compact) {
      return UMiniPlayerBar(controller: _controller, onTap: widget.onClose);
    }

    return ValueListenableBuilder<UMediaValue>(
      valueListenable: _controller,
      builder: (BuildContext context, UMediaValue value, Widget? child) {
        final UMediaMetadata? metadata = value.metadata ?? _controller.currentSource?.metadata;
        final Widget content = widget.layout == UMusicPlayerLayout.card
            ? _cardBody(context, value, metadata)
            : _fullBody(context, value, metadata);
        final Color? background = _theme.backgroundColor;
        return background == null ? content : ColoredBox(color: background, child: content);
      },
    );
  }

  Widget _fullBody(BuildContext context, UMediaValue value, UMediaMetadata? metadata) {
    final double artwork = _theme.artworkSize ?? (MediaQuery.of(context).size.width - 96).clamp(120, 360).toDouble();
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        widget.header ?? _defaultHeader(context),
        Expanded(
          child: _showingLyrics
              ? ULyricsView(controller: _controller, lyrics: _lyrics, onSeek: (Duration p) => unawaited(_controller.seek(p)))
              : Center(child: _artwork(context, metadata, artwork)),
        ),
        if (_theme.showVisualizer)
          UVisualizer(controller: _controller, style: _theme.visualizerStyle, height: _theme.visualizerHeight, color: _accent(context)),
        if (_theme.showTitle) Padding(padding: _theme.padding, child: _title(context, metadata)),
        if (_theme.showSeekBar) Directionality(textDirection: TextDirection.ltr, child: _seekBar(context, value)),
        Directionality(textDirection: TextDirection.ltr, child: _controls(context, value)),
        Directionality(textDirection: TextDirection.ltr, child: _extras(context, value)),
        if (widget.footer != null) widget.footer!,
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _cardBody(BuildContext context, UMediaValue value, UMediaMetadata? metadata) {
    final double artwork = _theme.artworkSize ?? 72;
    return UCard(
      child: UColumn(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        padding: const EdgeInsets.all(12),
        spacing: 8,
        children: <Widget>[
          URow(
            spacing: 12,
            children: <Widget>[
              if (_theme.showArtwork) _artwork(context, metadata, artwork),
              Expanded(child: _title(context, metadata)),
              ...widget.actions,
            ],
          ),
          if (_theme.showSeekBar) Directionality(textDirection: TextDirection.ltr, child: _seekBar(context, value)),
          Directionality(textDirection: TextDirection.ltr, child: _controls(context, value)),
        ],
      ),
    );
  }

  Widget _defaultHeader(BuildContext context) => URow(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
    children: <Widget>[
      IconButton(
        tooltip: U.s.close,
        onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
      ),
      Expanded(child: Center(child: UTextLabelLarge(U.s.nowPlaying, fontWeight: FontWeight.w700))),
      ...widget.actions,
      if (_theme.showQueue)
        IconButton(
          tooltip: U.s.queue,
          onPressed: () => UNavigator.bottomSheet(UMediaQueueSheet(controller: _controller)),
          icon: const Icon(Icons.queue_music_rounded),
        ),
    ],
  );

  Widget _artwork(BuildContext context, UMediaMetadata? metadata, double size) {
    if (!_theme.showArtwork) return const SizedBox.shrink();
    final Widget Function(BuildContext, UMediaMetadata?, double)? builder = widget.artworkBuilder;
    if (builder != null) return builder(context, metadata, size);
    return UArtwork(artwork: metadata?.artwork, size: size, borderRadius: _theme.artworkRadius);
  }

  Widget _title(BuildContext context, UMediaMetadata? metadata) {
    final Widget Function(BuildContext, UMediaMetadata?)? builder = widget.titleBuilder;
    if (builder != null) return builder(context, metadata);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UColumn(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UTextTitleLarge(
          metadata?.displayTitle.isNotEmpty == true ? metadata!.displayTitle : U.s.unknownTitle,
          fontWeight: FontWeight.w800,
          maxLines: 1,
        ),
        UTextBodyMedium(
          metadata?.displaySubtitle.isNotEmpty == true ? metadata!.displaySubtitle : U.s.unknownArtist,
          color: scheme.onSurfaceVariant,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _seekBar(BuildContext context, UMediaValue value) {
    final Widget Function(BuildContext, UMediaValue)? builder = widget.seekBarBuilder;
    if (builder != null) return builder(context, value);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: UColumn(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              activeTrackColor: _accent(context),
              thumbColor: _accent(context),
            ),
            child: Slider(
              value: (_scrubValue ?? value.progress).clamp(0, 1),
              onChanged: (double next) => setState(() => _scrubValue = next),
              onChangeEnd: (double next) {
                setState(() => _scrubValue = null);
                unawaited(_controller.seekToProgress(next));
              },
            ),
          ),
          if (_theme.showTimes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: URow(
                children: <Widget>[
                  UTextLabelSmall(uFormatDuration(value.position), color: scheme.onSurfaceVariant),
                  const Spacer(),
                  UTextLabelSmall(uFormatDuration(value.duration), color: scheme.onSurfaceVariant),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _controls(BuildContext context, UMediaValue value) {
    final Widget Function(BuildContext, UMediaValue)? builder = widget.controlsBuilder;
    if (builder != null) return builder(context, value);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return URow(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        if (_theme.showShuffle)
          IconButton(
            tooltip: U.s.shuffle,
            onPressed: () => unawaited(_controller.toggleShuffle()),
            icon: Icon(Icons.shuffle_rounded, color: value.shuffle ? _accent(context) : scheme.onSurfaceVariant),
          ),
        if (_theme.showSkip)
          IconButton(
            tooltip: U.s.previous,
            onPressed: _controller.hasPrevious ? () => unawaited(_controller.previous()) : null,
            icon: Icon(Icons.skip_previous_rounded, size: _theme.controlSize),
          ),
        UContainer(
          onTap: () => unawaited(_controller.playPause()),
          shape: BoxShape.circle,
          color: _accent(context),
          padding: EdgeInsets.all(_theme.playButtonSize * 0.25),
          child: Icon(
            value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: _theme.playButtonSize * 0.56,
            color: scheme.onPrimary,
          ),
        ),
        if (_theme.showSkip)
          IconButton(
            tooltip: U.s.next,
            onPressed: _controller.hasNext ? () => unawaited(_controller.next()) : null,
            icon: Icon(Icons.skip_next_rounded, size: _theme.controlSize),
          ),
        if (_theme.showRepeat)
          IconButton(
            tooltip: _repeatLabel(value.repeat),
            onPressed: () => unawaited(_controller.setRepeat(_nextRepeat(value.repeat))),
            icon: Icon(
              value.repeat == URepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
              color: value.repeat == URepeatMode.off ? scheme.onSurfaceVariant : _accent(context),
            ),
          ),
      ],
    );
  }

  Widget _extras(BuildContext context, UMediaValue value) {
    final Widget Function(BuildContext, UMediaValue)? builder = widget.extrasBuilder;
    if (builder != null) return builder(context, value);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Widget> items = <Widget>[
      if (_theme.showFavorite)
        IconButton(
          tooltip: U.s.favorites,
          onPressed: widget.onFavorite,
          icon: Icon(widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: widget.isFavorite ? _accent(context) : scheme.onSurfaceVariant),
        ),
      if (_theme.showLyrics)
        IconButton(
          tooltip: U.s.lyrics,
          onPressed: () => setState(() => _showingLyrics = !_showingLyrics),
          icon: Icon(Icons.lyrics_rounded, color: _showingLyrics ? _accent(context) : scheme.onSurfaceVariant),
        ),
      if (_theme.showSpeed)
        IconButton(tooltip: U.s.playbackSpeed, onPressed: () => _speedSheet(context), icon: const Icon(Icons.speed_rounded)),
      if (_theme.showEqualizer)
        IconButton(
          tooltip: U.s.equalizer,
          onPressed: () => UNavigator.bottomSheet(UEqualizerSheet(controller: _controller)),
          icon: const Icon(Icons.tune_rounded),
        ),
      if (_theme.showSleepTimer)
        IconButton(
          tooltip: U.s.sleepTimer,
          onPressed: () => _sleepSheet(context),
          icon: Icon(Icons.bedtime_rounded, color: _sleepAt == null ? scheme.onSurfaceVariant : _accent(context)),
        ),
      if (_theme.showVolume)
        IconButton(
          tooltip: value.muted ? U.s.unmute : U.s.mute,
          onPressed: () => unawaited(_controller.toggleMute()),
          icon: Icon(value.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded),
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return URow(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: items);
  }

  void _speedSheet(BuildContext context) => UNavigator.bottomSheet(
    UColumn(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final double speed in uSpeedPresets)
          ListTile(
            title: UTextBodyMedium("${speed}x"),
            trailing: _controller.value.speed == speed ? const Icon(Icons.check_rounded) : null,
            onTap: () {
              unawaited(_controller.setSpeed(speed));
              Navigator.of(context).pop();
            },
          ),
      ],
    ),
  );

  void _sleepSheet(BuildContext context) => UNavigator.bottomSheet(
    UColumn(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final int minutes in <int>[5, 10, 15, 30, 45, 60, 90])
          ListTile(
            title: UTextBodyMedium("$minutes ${U.s.minutes}"),
            onTap: () {
              _sleepTimer?.cancel();
              setState(() => _sleepAt = DateTime.now().add(Duration(minutes: minutes)));
              _sleepTimer = Timer(Duration(minutes: minutes), () {
                unawaited(_controller.pause());
                if (mounted) setState(() => _sleepAt = null);
              });
              Navigator.of(context).pop();
            },
          ),
        if (_sleepAt != null)
          ListTile(
            leading: const Icon(Icons.close_rounded),
            title: UTextBodyMedium(U.s.cancel),
            onTap: () {
              _sleepTimer?.cancel();
              setState(() => _sleepAt = null);
              Navigator.of(context).pop();
            },
          ),
      ],
    ),
  );

  String _repeatLabel(URepeatMode mode) {
    switch (mode) {
      case URepeatMode.off:
        return U.s.repeatOff;
      case URepeatMode.one:
        return U.s.repeatOne;
      case URepeatMode.all:
        return U.s.repeatAll;
    }
  }

  URepeatMode _nextRepeat(URepeatMode mode) {
    switch (mode) {
      case URepeatMode.off:
        return URepeatMode.all;
      case URepeatMode.all:
        return URepeatMode.one;
      case URepeatMode.one:
        return URepeatMode.off;
    }
  }
}
