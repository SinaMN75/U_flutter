import "package:u/utilities.dart";

class UVideoGestureConfig {
  const UVideoGestureConfig({
    this.tapToToggleControls = true,
    this.doubleTapSeek = true,
    this.doubleTapStep = const Duration(seconds: 10),
    this.horizontalScrub = true,
    this.verticalVolume = true,
    this.verticalBrightness = true,
    this.longPressSpeed = true,
    this.longPressSpeedValue = 2,
    this.pinchZoom = true,
    this.swipeDownToDismiss = true,
    this.dismissVelocity = 1200,
    this.haptics = true,
  });

  final bool tapToToggleControls;
  final bool doubleTapSeek;
  final Duration doubleTapStep;
  final bool horizontalScrub;
  final bool verticalVolume;
  final bool verticalBrightness;
  final bool longPressSpeed;
  final double longPressSpeedValue;
  final bool pinchZoom;
  final bool swipeDownToDismiss;
  final double dismissVelocity;
  final bool haptics;

  bool get hasVertical => verticalVolume || verticalBrightness;

  static const UVideoGestureConfig none = UVideoGestureConfig(
    tapToToggleControls: false,
    doubleTapSeek: false,
    horizontalScrub: false,
    verticalVolume: false,
    verticalBrightness: false,
    longPressSpeed: false,
    pinchZoom: false,
    swipeDownToDismiss: false,
  );
}

enum _UDragAxis { none, undecided, horizontal, vertical, zoom }

class UVideoGestures extends StatefulWidget {
  const UVideoGestures({
    required this.controller,
    required this.child,
    super.key,
    this.config = const UVideoGestureConfig(),
    this.onToggleControls,
    this.onZoomChanged,
    this.onBrightnessChanged,
    this.onDismiss,
    this.enabled = true,
  });

  final UMediaController controller;
  final Widget child;
  final UVideoGestureConfig config;
  final VoidCallback? onToggleControls;
  final void Function(double zoom)? onZoomChanged;
  final void Function(double brightness)? onBrightnessChanged;
  final VoidCallback? onDismiss;
  final bool enabled;

  @override
  State<UVideoGestures> createState() => _UVideoGesturesState();
}

class _UVideoGesturesState extends State<UVideoGestures> {
  int _tapStreak = 0;
  bool _seekingForward = true;
  Timer? _streakTimer;
  Timer? _feedbackTimer;
  String? _feedback;
  IconData? _feedbackIcon;

  double _brightness = 1;
  double _volumeAtDragStart = 1;
  double _brightnessAtDragStart = 1;
  double _zoom = 1;
  double _zoomAtScaleStart = 1;
  double _speedBeforeLongPress = 1;
  bool _longPressActive = false;

  _UDragAxis _axis = _UDragAxis.none;
  Offset _dragStart = Offset.zero;
  bool _verticalOnRight = false;
  bool _adjustedValue = false;
  Duration? _scrubTarget;

  @override
  void dispose() {
    _streakTimer?.cancel();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _showFeedback(String text, IconData icon) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedback = text;
      _feedbackIcon = icon;
    });
    _feedbackTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _feedback = null);
    });
  }

  void _pulse() {
    if (widget.config.haptics) HapticFeedback.selectionClick();
  }

  void _handleDoubleTap(Offset position, Size size) {
    final bool forward = position.dx > size.width / 2;
    if (forward != _seekingForward) _tapStreak = 0;
    _seekingForward = forward;
    _tapStreak++;

    final Duration delta = widget.config.doubleTapStep * _tapStreak;
    unawaited(widget.controller.seekBy(forward ? delta : -delta));
    _pulse();
    _showFeedback(
      "${forward ? "+" : "-"}${delta.inSeconds}s",
      forward ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
    );

    _streakTimer?.cancel();
    _streakTimer = Timer(const Duration(milliseconds: 900), () => _tapStreak = 0);
  }

  void _onScaleStart(ScaleStartDetails details, Size size) {
    _zoomAtScaleStart = _zoom;
    _axis = _UDragAxis.undecided;
    _dragStart = details.localFocalPoint;
    _verticalOnRight = details.localFocalPoint.dx > size.width / 2;
    _volumeAtDragStart = widget.controller.value.volume;
    _brightnessAtDragStart = _brightness;
    _adjustedValue = false;
    _scrubTarget = null;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size size) {
    if (details.pointerCount >= 2) {
      if (!widget.config.pinchZoom) return;
      _axis = _UDragAxis.zoom;
      final double next = (_zoomAtScaleStart * details.scale).clamp(1, 3).toDouble();
      setState(() => _zoom = next);
      widget.onZoomChanged?.call(next);
      return;
    }
    if (_axis == _UDragAxis.zoom) return;

    if (_axis == _UDragAxis.undecided) {
      final Offset total = details.localFocalPoint - _dragStart;
      if (total.distance < 12) return;
      _axis = total.dx.abs() > total.dy.abs() ? _UDragAxis.horizontal : _UDragAxis.vertical;
    }

    if (_axis == _UDragAxis.horizontal) {
      if (!widget.config.horizontalScrub) return;
      _applyScrub(details.focalPointDelta.dx, size);
      return;
    }
    if (!widget.config.hasVertical) return;
    _applyVertical(details.focalPointDelta.dy, size);
  }

  void _applyScrub(double deltaX, Size size) {
    final UMediaValue value = widget.controller.value;
    if (value.duration <= Duration.zero) return;
    final Duration base = _scrubTarget ?? value.position;
    final double ratio = deltaX / size.width;
    final Duration next = base + Duration(milliseconds: (value.duration.inMilliseconds * ratio * 1.5).round());
    final Duration clamped = next < Duration.zero ? Duration.zero : (next > value.duration ? value.duration : next);
    setState(() => _scrubTarget = clamped);
    _showFeedback(_format(clamped), Icons.timeline_rounded);
  }

  void _applyVertical(double deltaY, Size size) {
    final double delta = -deltaY / (size.height * 0.6) * 2;
    if (_verticalOnRight && widget.config.verticalVolume) {
      final double next = (_volumeAtDragStart + delta).clamp(0, 1).toDouble();
      _volumeAtDragStart = next;
      _adjustedValue = true;
      unawaited(widget.controller.setVolume(next));
      _showFeedback("${(next * 100).round()}%", next == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded);
      return;
    }
    if (!_verticalOnRight && widget.config.verticalBrightness) {
      final double next = (_brightnessAtDragStart + delta).clamp(0.1, 1).toDouble();
      _brightnessAtDragStart = next;
      _adjustedValue = true;
      setState(() => _brightness = next);
      widget.onBrightnessChanged?.call(next);
      _showFeedback("${(next * 100).round()}%", Icons.brightness_6_rounded);
    }
  }

  Future<void> _onScaleEnd(ScaleEndDetails details) async {
    final _UDragAxis axis = _axis;
    _axis = _UDragAxis.none;

    if (axis == _UDragAxis.horizontal) {
      final Duration? target = _scrubTarget;
      if (target != null) {
        setState(() => _scrubTarget = null);
        await widget.controller.seek(target);
      }
      return;
    }

    final bool flickedDown = details.velocity.pixelsPerSecond.dy > widget.config.dismissVelocity;
    if (widget.config.swipeDownToDismiss && flickedDown && !_adjustedValue) widget.onDismiss?.call();
  }

  Future<void> _onLongPressStart() async {
    if (!widget.controller.value.isPlaying) return;
    _longPressActive = true;
    _speedBeforeLongPress = widget.controller.value.speed;
    _pulse();
    await widget.controller.setSpeed(widget.config.longPressSpeedValue);
    _showFeedback("${widget.config.longPressSpeedValue}x", Icons.speed_rounded);
  }

  Future<void> _onLongPressEnd() async {
    if (!_longPressActive) return;
    _longPressActive = false;
    await widget.controller.setSpeed(_speedBeforeLongPress);
  }

  static String _format(Duration value) {
    String two(int n) => n.toString().padLeft(2, "0");
    final String minutes = two(value.inMinutes.remainder(60));
    final String seconds = two(value.inSeconds.remainder(60));
    return value.inHours > 0 ? "${two(value.inHours)}:$minutes:$seconds" : "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final bool wantsPan = widget.config.horizontalScrub || widget.config.hasVertical || widget.config.pinchZoom || widget.config.swipeDownToDismiss;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.config.tapToToggleControls ? widget.onToggleControls : null,
          onDoubleTapDown: widget.config.doubleTapSeek ? (TapDownDetails d) => _handleDoubleTap(d.localPosition, size) : null,
          onDoubleTap: widget.config.doubleTapSeek ? () {} : null,
          onLongPressStart: widget.config.longPressSpeed ? (LongPressStartDetails _) => unawaited(_onLongPressStart()) : null,
          onLongPressEnd: widget.config.longPressSpeed ? (LongPressEndDetails _) => unawaited(_onLongPressEnd()) : null,
          onScaleStart: wantsPan ? (ScaleStartDetails d) => _onScaleStart(d, size) : null,
          onScaleUpdate: wantsPan ? (ScaleUpdateDetails d) => _onScaleUpdate(d, size) : null,
          onScaleEnd: wantsPan ? (ScaleEndDetails d) => unawaited(_onScaleEnd(d)) : null,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              widget.child,
              if (_brightness < 1) IgnorePointer(child: ColoredBox(color: const Color(0xFF000000).withValues(alpha: 1 - _brightness))),
              if (_feedback != null) IgnorePointer(child: Center(child: _feedbackChip(context))),
            ],
          ),
        );
      },
    );
  }

  Widget _feedbackChip(BuildContext context) => UContainer(
    color: const Color(0xFF000000).withValues(alpha: 0.65),
    radius: 12,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: URow(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        Icon(_feedbackIcon, color: const Color(0xFFFFFFFF), size: 22),
        UTextTitleSmall(_feedback ?? "", color: const Color(0xFFFFFFFF), fontWeight: FontWeight.w700),
      ],
    ),
  );
}
