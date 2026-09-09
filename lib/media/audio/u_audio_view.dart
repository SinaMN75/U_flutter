import "package:u/utilities.dart";

class UAudioPlayerView extends StatefulWidget {
  const UAudioPlayerView({
    super.key,
    this.controller,
    this.showLyrics = true,
    this.showEqualizer = true,
    this.showVisualizer = false,
    this.artworkSize,
    this.onClose,
  });

  final UMediaController? controller;
  final bool showLyrics;
  final bool showEqualizer;
  final bool showVisualizer;
  final double? artworkSize;
  final VoidCallback? onClose;

  @override
  State<UAudioPlayerView> createState() => _UAudioPlayerViewState();
}

class _UAudioPlayerViewState extends State<UAudioPlayerView> {
  UMediaController get _controller => widget.controller ?? UAudio.controller;

  ULyrics _lyrics = ULyrics.empty;
  String? _lyricsForId;
  bool _showingLyrics = false;
  Timer? _sleepTimer;
  DateTime? _sleepAt;
  double? _scrubValue;

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
    final UMediaSource? source = _controller.currentSource;
    if (source == null) return;
    _lyricsForId = source.id;
    final ULyrics loaded = await ULyrics.load(source);
    if (!mounted) return;
    setState(() => _lyrics = loaded);
  }

  void _startSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    setState(() => _sleepAt = DateTime.now().add(duration));
    _sleepTimer = Timer(duration, () {
      unawaited(_controller.pause());
      if (mounted) setState(() => _sleepAt = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<UMediaValue>(
      valueListenable: _controller,
      builder: (BuildContext context, UMediaValue value, Widget? child) {
        final UMediaMetadata? metadata = value.metadata ?? _controller.currentSource?.metadata;
        final double artwork = widget.artworkSize ?? (MediaQuery.of(context).size.width - 96).clamp(120, 360).toDouble();

        return UColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _header(context, metadata),
            Expanded(
              child: _showingLyrics && widget.showLyrics
                  ? ULyricsView(controller: _controller, lyrics: _lyrics, onSeek: (Duration position) => unawaited(_controller.seek(position)))
                  : Center(
                      child: Hero(
                        tag: "u-audio-artwork",
                        child: UArtwork(artwork: metadata?.artwork, size: artwork, borderRadius: 18),
                      ),
                    ),
            ),
            _titleBlock(context, metadata, scheme),
            Directionality(textDirection: TextDirection.ltr, child: _seekBar(context, value, scheme)),
            Directionality(textDirection: TextDirection.ltr, child: _mainControls(context, value, scheme)),
            Directionality(textDirection: TextDirection.ltr, child: _secondaryControls(context, value, scheme)),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context, UMediaMetadata? metadata) => URow(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
    children: <Widget>[
      IconButton(
        tooltip: U.s.close,
        onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
      ),
      Expanded(child: Center(child: UTextLabelLarge(U.s.nowPlaying, fontWeight: FontWeight.w700))),
      IconButton(
        tooltip: U.s.queue,
        onPressed: () => UNavigator.bottomSheet(UMediaQueueSheet(controller: _controller)),
        icon: const Icon(Icons.queue_music_rounded),
      ),
    ],
  );

  Widget _titleBlock(BuildContext context, UMediaMetadata? metadata, ColorScheme scheme) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
    child: UColumn(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UTextHeadlineSmall(
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
    ),
  );

  Widget _seekBar(BuildContext context, UMediaValue value, ColorScheme scheme) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: UColumn(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SliderTheme(
          data: SliderTheme.of(context).copyWith(trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7)),
          child: Slider(
            value: (_scrubValue ?? value.progress).clamp(0, 1),
            onChanged: (double next) => setState(() => _scrubValue = next),
            onChangeEnd: (double next) {
              setState(() => _scrubValue = null);
              unawaited(_controller.seekToProgress(next));
            },
          ),
        ),
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

  Widget _mainControls(BuildContext context, UMediaValue value, ColorScheme scheme) => URow(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: <Widget>[
      IconButton(
        tooltip: U.s.shuffle,
        onPressed: () => unawaited(_controller.toggleShuffle()),
        icon: Icon(Icons.shuffle_rounded, color: value.shuffle ? scheme.primary : scheme.onSurfaceVariant),
      ),
      IconButton(
        tooltip: U.s.previous,
        onPressed: _controller.hasPrevious ? () => unawaited(_controller.previous()) : null,
        icon: const Icon(Icons.skip_previous_rounded, size: 38),
      ),
      UContainer(
        onTap: () => unawaited(_controller.playPause()),
        shape: BoxShape.circle,
        color: scheme.primary,
        padding: const EdgeInsets.all(16),
        child: Icon(value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 36, color: scheme.onPrimary),
      ),
      IconButton(
        tooltip: U.s.next,
        onPressed: _controller.hasNext ? () => unawaited(_controller.next()) : null,
        icon: const Icon(Icons.skip_next_rounded, size: 38),
      ),
      IconButton(
        tooltip: _repeatLabel(value.repeat),
        onPressed: () => unawaited(_controller.setRepeat(_nextRepeat(value.repeat))),
        icon: Icon(
          value.repeat == URepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
          color: value.repeat == URepeatMode.off ? scheme.onSurfaceVariant : scheme.primary,
        ),
      ),
    ],
  );

  Widget _secondaryControls(BuildContext context, UMediaValue value, ColorScheme scheme) => URow(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: <Widget>[
      if (widget.showLyrics)
        IconButton(
          tooltip: U.s.lyrics,
          onPressed: () => setState(() => _showingLyrics = !_showingLyrics),
          icon: Icon(Icons.lyrics_rounded, color: _showingLyrics ? scheme.primary : scheme.onSurfaceVariant),
        ),
      IconButton(
        tooltip: U.s.playbackSpeed,
        onPressed: () => _speedSheet(context),
        icon: const Icon(Icons.speed_rounded),
      ),
      if (widget.showEqualizer)
        IconButton(
          tooltip: U.s.equalizer,
          onPressed: () => UNavigator.bottomSheet(UEqualizerSheet(controller: _controller)),
          icon: const Icon(Icons.tune_rounded),
        ),
      IconButton(
        tooltip: U.s.sleepTimer,
        onPressed: () => _sleepSheet(context),
        icon: Icon(Icons.bedtime_rounded, color: _sleepAt == null ? scheme.onSurfaceVariant : scheme.primary),
      ),
      IconButton(
        tooltip: value.muted ? U.s.unmute : U.s.mute,
        onPressed: () => unawaited(_controller.toggleMute()),
        icon: Icon(value.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded),
      ),
    ],
  );

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
              _startSleepTimer(Duration(minutes: minutes));
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
