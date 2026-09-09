import "package:u/utilities.dart";

class UVideo extends StatefulWidget {
  const UVideo({
    required this.controller,
    super.key,
    this.settings,
    this.title,
    this.markers = const <UVideoMarker>[],
    this.gestures = const UVideoGestureConfig(),
    this.accentColor,
    this.backgroundColor = const Color(0xFF000000),
    this.borderRadius = 12,
    this.showControls = true,
    this.showFullscreenButton = true,
    this.showQueueButton = false,
    this.autoHide = const Duration(seconds: 3),
    this.aspectRatio,
    this.placeholder,
    this.isFullscreen = false,
    this.onDismiss,
    this.thumbnailBuilder,
    this.controlsBuilder,
  });

  final UMediaController controller;
  final UVideoSettings? settings;
  final String? title;
  final List<UVideoMarker> markers;
  final UVideoGestureConfig gestures;
  final Color? accentColor;
  final Color backgroundColor;
  final double borderRadius;
  final bool showControls;
  final bool showFullscreenButton;
  final bool showQueueButton;
  final Duration autoHide;
  final double? aspectRatio;
  final Widget? placeholder;
  final bool isFullscreen;
  final VoidCallback? onDismiss;
  final Widget Function(BuildContext context, Duration position)? thumbnailBuilder;
  final Widget Function(BuildContext context, UMediaController controller, bool visible)? controlsBuilder;

  @override
  State<UVideo> createState() => _UVideoState();
}

class _UVideoState extends State<UVideo> {
  late final UVideoSettings _settings = widget.settings ?? UVideoSettings();
  late final bool _ownsSettings = widget.settings == null;
  final FocusNode _focusNode = FocusNode();

  bool _controlsVisible = true;
  bool _locked = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onValueChanged);
    _restartHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onValueChanged);
    _focusNode.dispose();
    if (_ownsSettings) _settings.dispose();
    super.dispose();
  }

  void _onValueChanged() {
    if (!_settings.hasAbRepeat) return;
    final UMediaValue value = widget.controller.value;
    if (value.position >= _settings.repeatEnd!) unawaited(widget.controller.seek(_settings.repeatStart!));
  }

  void _restartHideTimer() {
    _hideTimer?.cancel();
    if (widget.autoHide <= Duration.zero) return;
    _hideTimer = Timer(widget.autoHide, () {
      if (mounted && widget.controller.value.isPlaying) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _restartHideTimer();
  }

  void _keepVisible() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _restartHideTimer();
  }

  Future<void> _toggleFullscreen() async {
    if (widget.isFullscreen) {
      Navigator.of(context).pop();
      return;
    }
    await UVideoFullscreen.open(
      context,
      controller: widget.controller,
      settings: _settings,
      title: widget.title,
      markers: widget.markers,
      gestures: widget.gestures,
      accentColor: widget.accentColor,
      thumbnailBuilder: widget.thumbnailBuilder,
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final UMediaController controller = widget.controller;
    _keepVisible();

    if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.keyK) {
      unawaited(controller.playPause());
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.keyL) {
      unawaited(controller.seekBy(const Duration(seconds: 10)));
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.keyJ) {
      unawaited(controller.seekBy(const Duration(seconds: -10)));
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      unawaited(controller.setVolume((controller.value.volume + 0.1).clamp(0, 1).toDouble()));
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      unawaited(controller.setVolume((controller.value.volume - 0.1).clamp(0, 1).toDouble()));
    } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
      unawaited(_toggleFullscreen());
    } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
      unawaited(controller.toggleMute());
    } else if (event.logicalKey == LogicalKeyboardKey.escape && widget.isFullscreen) {
      Navigator.of(context).pop();
    } else if (event.logicalKey == LogicalKeyboardKey.bracketRight) {
      unawaited(controller.setSpeed((controller.value.speed + 0.25).clamp(0.25, 4).toDouble()));
    } else if (event.logicalKey == LogicalKeyboardKey.bracketLeft) {
      unawaited(controller.setSpeed((controller.value.speed - 0.25).clamp(0.25, 4).toDouble()));
    } else {
      final int? digit = _digitOf(event.logicalKey);
      if (digit == null) return KeyEventResult.ignored;
      unawaited(controller.seekToProgress(digit / 10));
    }
    return KeyEventResult.handled;
  }

  int? _digitOf(LogicalKeyboardKey key) {
    const List<LogicalKeyboardKey> digits = <LogicalKeyboardKey>[
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    final int index = digits.indexOf(key);
    return index < 0 ? null : index;
  }

  void _openSettings() {
    _keepVisible();
    UNavigator.bottomSheet(UVideoSettingsSheet(controller: widget.controller, settings: _settings));
  }

  @override
  Widget build(BuildContext context) {
    final Widget player = AnimatedBuilder(
      animation: _settings,
      builder: (BuildContext context, Widget? child) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          UVideoFilterLayer(
            settings: _settings,
            child: UVideoView(
              controller: widget.controller,
              fit: _settings.fit,
              zoom: _settings.zoom,
              rotationDegrees: _settings.rotation,
              mirrored: _settings.mirrored,
              backgroundColor: widget.backgroundColor,
              placeholder: widget.placeholder,
              errorBuilder: _errorBuilder,
            ),
          ),
          USubtitleView(controller: widget.controller, style: _settings.subtitleStyle, scale: _settings.subtitleScale),
          if (_settings.showStats) Positioned(top: 12, left: 12, child: UVideoStatsOverlay(controller: widget.controller)),
        ],
      ),
    );

    final Widget gestured = UVideoGestures(
      controller: widget.controller,
      config: widget.gestures,
      onToggleControls: _toggleControls,
      onZoomChanged: (double zoom) => _settings.zoom = zoom,
      onBrightnessChanged: (double value) => _settings.screenBrightness = value,
      onDismiss: widget.onDismiss,
      enabled: !_locked,
      child: player,
    );

    final Widget stacked = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        gestured,
        if (widget.showControls)
          widget.controlsBuilder?.call(context, widget.controller, _controlsVisible) ??
              UVideoControls(
                controller: widget.controller,
                visible: _controlsVisible,
                title: widget.title,
                markers: widget.markers,
                accentColor: widget.accentColor,
                showBack: widget.isFullscreen,
                showFullscreen: widget.showFullscreenButton,
                showQueue: widget.showQueueButton,
                isFullscreen: widget.isFullscreen,
                locked: _locked,
                onBack: () => Navigator.of(context).pop(),
                onToggleFullscreen: () => unawaited(_toggleFullscreen()),
                onToggleLock: () => setState(() => _locked = !_locked),
                onOpenSettings: _openSettings,
                onOpenQueue: () => UNavigator.bottomSheet(UMediaQueueSheet(controller: widget.controller)),
                onScrubStart: () => _hideTimer?.cancel(),
                onScrubEnd: _restartHideTimer,
                thumbnailBuilder: widget.thumbnailBuilder,
              ),
      ],
    );

    final Widget focused = Focus(focusNode: _focusNode, autofocus: widget.isFullscreen, onKeyEvent: _onKey, child: stacked);

    if (widget.isFullscreen) return ColoredBox(color: widget.backgroundColor, child: focused);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: ColoredBox(
        color: widget.backgroundColor,
        child: ValueListenableBuilder<UMediaValue>(
          valueListenable: widget.controller,
          builder: (BuildContext context, UMediaValue value, Widget? child) => AspectRatio(
            aspectRatio: widget.aspectRatio ?? (value.hasVideo ? value.aspectRatio : 16 / 9),
            child: child,
          ),
          child: focused,
        ),
      ),
    );
  }

  Widget _errorBuilder(BuildContext context, UMediaError error) => Center(
    child: UColumn(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        const Icon(Icons.error_outline_rounded, color: Color(0xB3FFFFFF), size: 40),
        UTextBodySmall(error.message.isEmpty ? U.s.errorLoadingVideo : error.message, color: const Color(0xB3FFFFFF)),
        UButton(
          type: UButtonType.text,
          title: U.s.tryAgain,
          onTap: () {
            final UMediaSource? source = widget.controller.currentSource;
            if (source != null) unawaited(widget.controller.open(source, autoPlay: true));
          },
        ),
      ],
    ),
  );
}

abstract final class UVideoFullscreen {
  static Future<void> open(
    BuildContext context, {
    required UMediaController controller,
    UVideoSettings? settings,
    String? title,
    List<UVideoMarker> markers = const <UVideoMarker>[],
    UVideoGestureConfig gestures = const UVideoGestureConfig(),
    Color? accentColor,
    Widget Function(BuildContext context, Duration position)? thumbnailBuilder,
    bool forceLandscape = true,
  }) async {
    if (forceLandscape) {
      await SystemChrome.setPreferredOrientations(<DeviceOrientation>[DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondary) => Scaffold(
          backgroundColor: const Color(0xFF000000),
          body: UVideo(
            controller: controller,
            settings: settings,
            title: title,
            markers: markers,
            gestures: gestures,
            accentColor: accentColor,
            borderRadius: 0,
            isFullscreen: true,
            thumbnailBuilder: thumbnailBuilder,
            onDismiss: () => Navigator.of(context).pop(),
          ),
        ),
        transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondary, Widget child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );

    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
