import "package:u/utilities.dart";

class UVideoMarker {
  const UVideoMarker({required this.start, this.end, this.label, this.color, this.skippable = false});

  final Duration start;
  final Duration? end;
  final String? label;
  final Color? color;
  final bool skippable;

  bool contains(Duration position) {
    final Duration? finish = end;
    if (finish == null) return false;
    return position >= start && position < finish;
  }
}

String uFormatDuration(Duration value) {
  String two(int n) => n.toString().padLeft(2, "0");
  final String minutes = two(value.inMinutes.remainder(60));
  final String seconds = two(value.inSeconds.remainder(60));
  return value.inHours > 0 ? "${two(value.inHours)}:$minutes:$seconds" : "$minutes:$seconds";
}

class UVideoSeekBar extends StatefulWidget {
  const UVideoSeekBar({
    required this.controller,
    super.key,
    this.markers = const <UVideoMarker>[],
    this.accentColor,
    this.height = 3,
    this.thumbRadius = 6,
    this.onScrubStart,
    this.onScrubEnd,
    this.thumbnailBuilder,
  });

  final UMediaController controller;
  final List<UVideoMarker> markers;
  final Color? accentColor;
  final double height;
  final double thumbRadius;
  final VoidCallback? onScrubStart;
  final VoidCallback? onScrubEnd;
  final Widget Function(BuildContext context, Duration position)? thumbnailBuilder;

  @override
  State<UVideoSeekBar> createState() => _UVideoSeekBarState();
}

class _UVideoSeekBarState extends State<UVideoSeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.accentColor ?? Theme.of(context).colorScheme.primary;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<UMediaValue>(
      valueListenable: widget.controller,
      builder: (BuildContext context, UMediaValue value, Widget? child) {
        final int total = value.duration.inMilliseconds;
        final double position = _dragValue ?? (total <= 0 ? 0 : value.position.inMilliseconds / total);
        final double buffered = total <= 0 ? 0 : (value.bufferedPosition.inMilliseconds / total).clamp(0, 1).toDouble();

        return UColumn(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_dragValue != null && widget.thumbnailBuilder != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: widget.thumbnailBuilder!(context, Duration(milliseconds: (total * _dragValue!).round())),
              ),
            SizedBox(
              height: 24,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  _track(context, accent, position, buffered, total),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: widget.height,
                      activeTrackColor: const Color(0x00000000),
                      inactiveTrackColor: const Color(0x00000000),
                      thumbColor: accent,
                      overlayColor: accent.withValues(alpha: 0.2),
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: widget.thumbRadius),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: widget.thumbRadius * 2),
                      trackShape: const RectangularSliderTrackShape(),
                    ),
                    child: Slider(
                      value: position.clamp(0, 1),
                      onChangeStart: (double _) {
                        widget.onScrubStart?.call();
                        setState(() => _dragValue = position);
                      },
                      onChanged: (double next) => setState(() => _dragValue = next),
                      onChangeEnd: (double next) {
                        setState(() => _dragValue = null);
                        widget.onScrubEnd?.call();
                        unawaited(widget.controller.seekToProgress(next));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      ),
    );
  }

  Widget _track(BuildContext context, Color accent, double position, double buffered, int total) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) => Stack(
      alignment: Alignment.centerLeft,
      children: <Widget>[
        Container(height: widget.height, decoration: BoxDecoration(color: const Color(0x40FFFFFF), borderRadius: BorderRadius.circular(widget.height))),
        Container(
          height: widget.height,
          width: constraints.maxWidth * buffered,
          decoration: BoxDecoration(color: const Color(0x66FFFFFF), borderRadius: BorderRadius.circular(widget.height)),
        ),
        Container(
          height: widget.height,
          width: constraints.maxWidth * position.clamp(0, 1),
          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(widget.height)),
        ),
        if (total > 0)
          for (final UVideoMarker marker in widget.markers)
            Positioned(
              left: (constraints.maxWidth * (marker.start.inMilliseconds / total)).clamp(0, constraints.maxWidth - 2),
              child: Container(
                width: marker.end == null ? 2 : ((constraints.maxWidth * ((marker.end!.inMilliseconds - marker.start.inMilliseconds) / total)).clamp(2, constraints.maxWidth)),
                height: widget.height + 2,
                color: marker.color ?? const Color(0xFFFFD54F),
              ),
            ),
      ],
    ),
  );
}

class UVideoControls extends StatelessWidget {
  const UVideoControls({
    required this.controller,
    super.key,
    this.visible = true,
    this.title,
    this.markers = const <UVideoMarker>[],
    this.accentColor,
    this.showBack = false,
    this.showFullscreen = true,
    this.showPip = true,
    this.showSpeed = true,
    this.showQuality = true,
    this.showSubtitles = true,
    this.showQueue = false,
    this.showLock = true,
    this.isFullscreen = false,
    this.locked = false,
    this.onBack,
    this.onToggleFullscreen,
    this.onToggleLock,
    this.onOpenSettings,
    this.onOpenQueue,
    this.onScrubStart,
    this.onScrubEnd,
    this.thumbnailBuilder,
  });

  final UMediaController controller;
  final bool visible;
  final String? title;
  final List<UVideoMarker> markers;
  final Color? accentColor;
  final bool showBack;
  final bool showFullscreen;
  final bool showPip;
  final bool showSpeed;
  final bool showQuality;
  final bool showSubtitles;
  final bool showQueue;
  final bool showLock;
  final bool isFullscreen;
  final bool locked;
  final VoidCallback? onBack;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onToggleLock;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenQueue;
  final VoidCallback? onScrubStart;
  final VoidCallback? onScrubEnd;
  final Widget Function(BuildContext context, Duration position)? thumbnailBuilder;

  static const Color _onDark = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: visible ? 1 : 0,
    duration: const Duration(milliseconds: 200),
    child: IgnorePointer(
      ignoring: !visible,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0x8C000000), Color(0x00000000), Color(0x00000000), Color(0xA6000000)],
            stops: <double>[0, 0.28, 0.62, 1],
          ),
        ),
          child: locked ? _lockedLayer(context) : _fullLayer(context),
        ),
      ),
    ),
  );

  Widget _lockedLayer(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: _iconButton(Icons.lock_rounded, U.s.unlockControls, onToggleLock),
    ),
  );

  Widget _fullLayer(BuildContext context) => SafeArea(
    child: UColumn(
      children: <Widget>[
        _topBar(context),
        const Spacer(),
        _centerRow(context),
        const Spacer(),
        _bottomBar(context),
      ],
    ),
  );

  Widget _topBar(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
    child: URow(
      children: <Widget>[
        if (showBack) _iconButton(Icons.arrow_back_rounded, U.s.back, onBack),
        if (title != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Directionality(
                textDirection: UBidi.directionOf(title!),
                child: UTextTitleSmall(title!, color: _onDark, fontWeight: FontWeight.w600, maxLines: 1),
              ),
            ),
          )
        else
          const Spacer(),
        if (showLock && isFullscreen) _iconButton(Icons.lock_open_rounded, U.s.lockControls, onToggleLock),
        if (showPip && !kIsWeb) _iconButton(Icons.picture_in_picture_alt_rounded, U.s.pictureInPicture, () => unawaited(controller.enterPip())),
        if (showQueue) _iconButton(Icons.queue_music_rounded, U.s.queue, onOpenQueue),
        _iconButton(Icons.settings_rounded, U.s.settings, onOpenSettings),
      ],
    ),
  );

  Widget _centerRow(BuildContext context) => ValueListenableBuilder<UMediaValue>(
    valueListenable: controller,
    builder: (BuildContext context, UMediaValue value, Widget? child) => URow(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 28,
      children: <Widget>[
        _circleButton(Icons.skip_previous_rounded, U.s.previous, controller.hasPrevious ? () => unawaited(controller.previous()) : null, 30),
        if (value.isBuffering)
          const SizedBox(width: 64, height: 64, child: Center(child: CircularProgressIndicator(color: _onDark, strokeWidth: 3)))
        else
          _circleButton(
            value.state == UMediaState.completed ? Icons.replay_rounded : (value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            value.isPlaying ? U.s.pause : U.s.play,
            () => unawaited(value.state == UMediaState.completed ? controller.seek(Duration.zero).then((_) => controller.play()) : controller.playPause()),
            44,
          ),
        _circleButton(Icons.skip_next_rounded, U.s.next, controller.hasNext ? () => unawaited(controller.next()) : null, 30),
      ],
    ),
  );

  Widget _bottomBar(BuildContext context) => ValueListenableBuilder<UMediaValue>(
    valueListenable: controller,
    builder: (BuildContext context, UMediaValue value, Widget? child) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: UColumn(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!value.isLive)
            UVideoSeekBar(
              controller: controller,
              markers: markers,
              accentColor: accentColor,
              onScrubStart: onScrubStart,
              onScrubEnd: onScrubEnd,
              thumbnailBuilder: thumbnailBuilder,
            ),
          URow(
            children: <Widget>[
              if (value.isLive)
                _liveBadge(context, value)
              else
                UTextBodySmall("${uFormatDuration(value.position)} / ${uFormatDuration(value.duration)}", color: _onDark),
              const Spacer(),
              if (showSubtitles) _iconButton(controller.subtitles == null ? Icons.closed_caption_off_rounded : Icons.closed_caption_rounded, U.s.subtitles, onOpenSettings),
              if (showQuality) _textButton(_qualityLabel(value), U.s.quality, onOpenSettings),
              if (showSpeed) _textButton("${value.speed}x", U.s.playbackSpeed, onOpenSettings),
              _iconButton(value.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, value.muted ? U.s.unmute : U.s.mute, () => unawaited(controller.toggleMute())),
              if (showFullscreen) _iconButton(isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, isFullscreen ? U.s.exitFullscreen : U.s.fullscreen, onToggleFullscreen),
            ],
          ),
        ],
      ),
    ),
  );

  String _qualityLabel(UMediaValue value) {
    final UMediaTrack? selected = value.selectedTrack(UMediaTrackType.video);
    final String label = selected?.qualityLabel ?? "";
    return label.isEmpty ? U.s.auto : label;
  }

  Widget _liveBadge(BuildContext context, UMediaValue value) => URow(
    mainAxisSize: MainAxisSize.min,
    spacing: 6,
    children: <Widget>[
      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle)),
      UTextBodySmall(U.s.live, color: _onDark, fontWeight: FontWeight.w700),
    ],
  );

  Widget _iconButton(IconData icon, String tooltip, VoidCallback? onPressed) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, color: _onDark, size: 22),
    visualDensity: VisualDensity.compact,
  );

  Widget _textButton(String label, String tooltip, VoidCallback? onPressed) => Tooltip(
    message: tooltip,
    child: UContainer(
      onTap: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: UTextBodySmall(label, color: _onDark, fontWeight: FontWeight.w700),
    ),
  );

  Widget _circleButton(IconData icon, String tooltip, VoidCallback? onPressed, double size) => Tooltip(
    message: tooltip,
    child: UContainer(
      onTap: onPressed,
      shape: BoxShape.circle,
      color: const Color(0x66000000),
      padding: EdgeInsets.all(size * 0.22),
      child: Icon(icon, color: onPressed == null ? const Color(0x66FFFFFF) : _onDark, size: size),
    ),
  );
}
