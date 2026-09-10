import "package:u/utilities.dart";

class UVideoSettings extends ChangeNotifier {
  UVideoSettings({this._fit = UMediaFit.contain, this._subtitleStyle = const USubtitleStyleConfig()});

  UMediaFit _fit;
  double _zoom = 1;
  int _rotation = 0;
  bool _mirrored = false;
  double _screenBrightness = 1;
  double _brightness = 0;
  double _contrast = 1;
  double _saturation = 1;
  double _hue = 0;
  bool _showStats = false;
  USubtitleStyleConfig _subtitleStyle;
  double _subtitleScale = 1;
  Duration _subtitleDelay = Duration.zero;
  Duration? _repeatStart;
  Duration? _repeatEnd;
  Timer? _sleepTimer;
  DateTime? _sleepAt;

  UMediaFit get fit => _fit;

  double get zoom => _zoom;

  int get rotation => _rotation;

  bool get mirrored => _mirrored;

  double get screenBrightness => _screenBrightness;

  double get brightness => _brightness;

  double get contrast => _contrast;

  double get saturation => _saturation;

  double get hue => _hue;

  bool get showStats => _showStats;

  USubtitleStyleConfig get subtitleStyle => _subtitleStyle;

  double get subtitleScale => _subtitleScale;

  Duration get subtitleDelay => _subtitleDelay;

  Duration? get repeatStart => _repeatStart;

  Duration? get repeatEnd => _repeatEnd;

  DateTime? get sleepAt => _sleepAt;

  bool get hasFilters => _brightness != 0 || _contrast != 1 || _saturation != 1 || _hue != 0;

  bool get hasAbRepeat => _repeatStart != null && _repeatEnd != null;

  set fit(UMediaFit value) {
    _fit = value;
    notifyListeners();
  }

  set zoom(double value) {
    _zoom = value.clamp(1, 4).toDouble();
    notifyListeners();
  }

  set rotation(int value) {
    _rotation = value % 360;
    notifyListeners();
  }

  set mirrored(bool value) {
    _mirrored = value;
    notifyListeners();
  }

  set screenBrightness(double value) {
    _screenBrightness = value.clamp(0.05, 1).toDouble();
    notifyListeners();
  }

  set brightness(double value) {
    _brightness = value.clamp(-1, 1).toDouble();
    notifyListeners();
  }

  set contrast(double value) {
    _contrast = value.clamp(0, 3).toDouble();
    notifyListeners();
  }

  set saturation(double value) {
    _saturation = value.clamp(0, 3).toDouble();
    notifyListeners();
  }

  set hue(double value) {
    _hue = value.clamp(-180, 180).toDouble();
    notifyListeners();
  }

  set showStats(bool value) {
    _showStats = value;
    notifyListeners();
  }

  set subtitleStyle(USubtitleStyleConfig value) {
    _subtitleStyle = value;
    notifyListeners();
  }

  set subtitleScale(double value) {
    _subtitleScale = value.clamp(0.5, 3).toDouble();
    notifyListeners();
  }

  void setSubtitleDelay(UMediaController controller, Duration value) {
    _subtitleDelay = value;
    controller.setSubtitleDelay(value);
    notifyListeners();
  }

  void cycleFit() {
    const List<UMediaFit> order = <UMediaFit>[UMediaFit.contain, UMediaFit.cover, UMediaFit.fill, UMediaFit.ratio16x9, UMediaFit.ratio4x3, UMediaFit.original];
    final int index = order.indexOf(_fit);
    fit = order[(index + 1) % order.length];
  }

  void rotateQuarter() => rotation = _rotation + 90;

  void resetFilters() {
    _brightness = 0;
    _contrast = 1;
    _saturation = 1;
    _hue = 0;
    notifyListeners();
  }

  void resetView() {
    _zoom = 1;
    _rotation = 0;
    _mirrored = false;
    _fit = UMediaFit.contain;
    notifyListeners();
  }

  void markRepeatStart(Duration position) {
    _repeatStart = position;
    _repeatEnd = null;
    notifyListeners();
  }

  void markRepeatEnd(Duration position) {
    if (_repeatStart == null || position <= _repeatStart!) return;
    _repeatEnd = position;
    notifyListeners();
  }

  void clearRepeat() {
    _repeatStart = null;
    _repeatEnd = null;
    notifyListeners();
  }

  void startSleepTimer(Duration duration, VoidCallback onElapsed) {
    _sleepTimer?.cancel();
    _sleepAt = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () {
      _sleepAt = null;
      onElapsed();
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepAt = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    super.dispose();
  }
}

abstract final class UVideoColorMatrix {
  static List<double> identity() => <double>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];

  static List<double> build({double brightness = 0, double contrast = 1, double saturation = 1, double hue = 0}) {
    List<double> matrix = identity();
    if (hue != 0) matrix = multiply(_hue(hue), matrix);
    if (saturation != 1) matrix = multiply(_saturation(saturation), matrix);
    if (contrast != 1) matrix = multiply(_contrast(contrast), matrix);
    if (brightness != 0) matrix = multiply(_brightness(brightness), matrix);
    return matrix;
  }

  static List<double> _brightness(double value) {
    final double offset = value * 255;
    return <double>[1, 0, 0, 0, offset, 0, 1, 0, 0, offset, 0, 0, 1, 0, offset, 0, 0, 0, 1, 0];
  }

  static List<double> _contrast(double value) {
    final double translate = (1 - value) * 127.5;
    return <double>[value, 0, 0, 0, translate, 0, value, 0, 0, translate, 0, 0, value, 0, translate, 0, 0, 0, 1, 0];
  }

  static List<double> _saturation(double value) {
    const double lumR = 0.2126;
    const double lumG = 0.7152;
    const double lumB = 0.0722;
    final double inverse = 1 - value;
    final double r = lumR * inverse;
    final double g = lumG * inverse;
    final double b = lumB * inverse;
    return <double>[r + value, g, b, 0, 0, r, g + value, b, 0, 0, r, g, b + value, 0, 0, 0, 0, 0, 1, 0];
  }

  static List<double> _hue(double degrees) {
    final double radians = degrees * pi / 180;
    final double cosine = cos(radians);
    final double sine = sin(radians);
    return <double>[
      0.213 + cosine * 0.787 - sine * 0.213, 0.715 - cosine * 0.715 - sine * 0.715, 0.072 - cosine * 0.072 + sine * 0.928, 0, 0,
      0.213 - cosine * 0.213 + sine * 0.143, 0.715 + cosine * 0.285 + sine * 0.140, 0.072 - cosine * 0.072 - sine * 0.283, 0, 0,
      0.213 - cosine * 0.213 - sine * 0.787, 0.715 - cosine * 0.715 + sine * 0.715, 0.072 + cosine * 0.928 + sine * 0.072, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  static List<double> multiply(List<double> a, List<double> b) {
    final List<double> result = List<double>.filled(20, 0);
    for (int row = 0; row < 4; row++) {
      for (int column = 0; column < 5; column++) {
        double sum = 0;
        for (int k = 0; k < 4; k++) {
          sum += a[row * 5 + k] * b[k * 5 + column];
        }
        if (column == 4) sum += a[row * 5 + 4];
        result[row * 5 + column] = sum;
      }
    }
    return result;
  }
}

class UVideoFilterLayer extends StatelessWidget {
  const UVideoFilterLayer({required this.settings, required this.child, super.key});

  final UVideoSettings settings;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: settings,
    builder: (BuildContext context, Widget? built) {
      if (!settings.hasFilters) return built ?? child;
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(
          UVideoColorMatrix.build(
            brightness: settings.brightness,
            contrast: settings.contrast,
            saturation: settings.saturation,
            hue: settings.hue,
          ),
        ),
        child: built ?? child,
      );
    },
    child: child,
  );
}

class UVideoView extends StatelessWidget {
  const UVideoView({
    required this.controller,
    super.key,
    this.fit = UMediaFit.contain,
    this.zoom = 1,
    this.pan = Offset.zero,
    this.rotationDegrees = 0,
    this.mirrored = false,
    this.backgroundColor,
    this.placeholder,
    this.errorBuilder,
  });

  final UMediaController controller;
  final UMediaFit fit;
  final double zoom;
  final Offset pan;
  final int rotationDegrees;
  final bool mirrored;
  final Color? backgroundColor;
  final Widget? placeholder;
  final Widget Function(BuildContext context, UMediaError error)? errorBuilder;

  static double? ratioOf(UMediaFit fit) {
    switch (fit) {
      case UMediaFit.ratio16x9:
        return 16 / 9;
      case UMediaFit.ratio4x3:
        return 4 / 3;
      case UMediaFit.ratio21x9:
        return 21 / 9;
      case UMediaFit.ratio1x1:
        return 1;
      case UMediaFit.contain:
      case UMediaFit.cover:
      case UMediaFit.fill:
      case UMediaFit.fitWidth:
      case UMediaFit.fitHeight:
      case UMediaFit.none:
      case UMediaFit.original:
        return null;
    }
  }

  static BoxFit boxFitOf(UMediaFit fit) {
    switch (fit) {
      case UMediaFit.cover:
        return BoxFit.cover;
      case UMediaFit.fill:
        return BoxFit.fill;
      case UMediaFit.fitWidth:
        return BoxFit.fitWidth;
      case UMediaFit.fitHeight:
        return BoxFit.fitHeight;
      case UMediaFit.none:
      case UMediaFit.original:
        return BoxFit.none;
      case UMediaFit.contain:
      case UMediaFit.ratio16x9:
      case UMediaFit.ratio4x3:
      case UMediaFit.ratio21x9:
      case UMediaFit.ratio1x1:
        return BoxFit.contain;
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UMediaValue>(
    valueListenable: controller,
    builder: (BuildContext context, UMediaValue value, Widget? child) => ColoredBox(
      color: backgroundColor ?? const Color(0xFF000000),
      child: _buildContent(context, value),
    ),
  );

  Widget _buildContent(BuildContext context, UMediaValue value) {
    final UMediaError? error = value.error;
    if (error != null) return errorBuilder?.call(context, error) ?? const SizedBox.shrink();
    if (!value.hasVideo && value.state == UMediaState.idle) return placeholder ?? const SizedBox.shrink();

    final Widget surface = _surface();
    if (surface is SizedBox) return placeholder ?? const SizedBox.shrink();

    final double ratio = ratioOf(fit) ?? value.aspectRatio;
    final int rotation = rotationDegrees == 0 ? value.rotationDegrees : rotationDegrees;

    Widget content = FittedBox(
      fit: boxFitOf(fit),
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: value.width > 0 ? value.width.toDouble() : 1920,
        height: value.height > 0 ? value.height.toDouble() : 1080,
        child: surface,
      ),
    );

    if (rotation != 0) content = RotatedBox(quarterTurns: (rotation ~/ 90) % 4, child: content);
    if (mirrored) content = Transform(alignment: Alignment.center, transform: Matrix4.identity()..scale(-1.0, 1, 1), child: content);
    if (zoom != 1 || pan != Offset.zero) {
      content = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..translateByDouble(pan.dx, pan.dy, 0, 1)
          ..scaleByDouble(zoom, zoom, 1, 1),
        child: content,
      );
    }

    return ClipRect(child: Center(child: AspectRatio(aspectRatio: ratio <= 0 ? 16 / 9 : ratio, child: content)));
  }

  Widget _surface() {
    if (kIsWeb) {
      final int? id = controller.playerId;
      return id == null ? const SizedBox.shrink() : HtmlElementView(viewType: "u-media-$id");
    }
    final int? texture = controller.textureId;
    return texture == null ? const SizedBox.shrink() : Texture(textureId: texture);
  }
}

class USubtitleStyleConfig {
  const USubtitleStyleConfig({
    this.fontSize = 18,
    this.color = const Color(0xFFFFFFFF),
    this.outlineColor = const Color(0xFF000000),
    this.outlineWidth = 2.5,
    this.backgroundColor = const Color(0x00000000),
    this.fontWeight = FontWeight.w600,
    this.fontFamily,
    this.rtlFontFamily = "Vazir",
    this.bottomPadding = 24,
    this.horizontalPadding = 24,
    this.lineHeight = 1.3,
    this.shadow = true,
    this.honorAssStyling = true,
    this.maxLines = 4,
  });

  final double fontSize;
  final Color color;
  final Color outlineColor;
  final double outlineWidth;
  final Color backgroundColor;
  final FontWeight fontWeight;
  final String? fontFamily;
  final String? rtlFontFamily;
  final double bottomPadding;
  final double horizontalPadding;
  final double lineHeight;
  final bool shadow;
  final bool honorAssStyling;
  final int maxLines;

  USubtitleStyleConfig copyWith({double? fontSize, Color? color, double? outlineWidth, double? bottomPadding, Color? backgroundColor}) => USubtitleStyleConfig(
    fontSize: fontSize ?? this.fontSize,
    color: color ?? this.color,
    outlineColor: outlineColor,
    outlineWidth: outlineWidth ?? this.outlineWidth,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    fontWeight: fontWeight,
    fontFamily: fontFamily,
    rtlFontFamily: rtlFontFamily,
    bottomPadding: bottomPadding ?? this.bottomPadding,
    horizontalPadding: horizontalPadding,
    lineHeight: lineHeight,
    shadow: shadow,
    honorAssStyling: honorAssStyling,
    maxLines: maxLines,
  );
}

class USubtitleView extends StatelessWidget {
  const USubtitleView({required this.controller, super.key, this.style = const USubtitleStyleConfig(), this.scale = 1});

  final UMediaController controller;
  final USubtitleStyleConfig style;
  final double scale;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<List<USubtitleCue>>(
    valueListenable: controller.activeCues,
    builder: (BuildContext context, List<USubtitleCue> cues, Widget? child) {
      if (cues.isEmpty) return const SizedBox.shrink();
      return IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: cues.map(_positioned).toList(growable: false),
        ),
      );
    },
  );

  Widget _positioned(USubtitleCue cue) {
    final Alignment alignment = _alignmentOf(cue.alignment);
    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.only(
          left: style.horizontalPadding,
          right: style.horizontalPadding,
          bottom: alignment.y > 0 ? style.bottomPadding : 0,
          top: alignment.y < 0 ? style.bottomPadding : 0,
        ),
        child: _cueBody(cue),
      ),
    );
  }

  Alignment _alignmentOf(int code) {
    switch (code) {
      case 1:
        return Alignment.bottomLeft;
      case 3:
        return Alignment.bottomRight;
      case 4:
        return Alignment.centerLeft;
      case 5:
        return Alignment.center;
      case 6:
        return Alignment.centerRight;
      case 7:
        return Alignment.topLeft;
      case 8:
        return Alignment.topCenter;
      case 9:
        return Alignment.topRight;
      default:
        return Alignment.bottomCenter;
    }
  }

  Widget _cueBody(USubtitleCue cue) {
    final bool rtl = cue.isRtl;
    final double size = style.fontSize * scale;
    final TextAlign align = cue.alignment == 1 || cue.alignment == 4 || cue.alignment == 7
        ? TextAlign.start
        : (cue.alignment == 3 || cue.alignment == 6 || cue.alignment == 9 ? TextAlign.end : TextAlign.center);

    final Widget text = Stack(
      children: <Widget>[
        if (style.outlineWidth > 0) _richText(cue, size, align, rtl, _strokeStyle(size, rtl), true),
        _richText(cue, size, align, rtl, _baseStyle(size, rtl), false),
      ],
    );

    if (style.backgroundColor.a == 0) return Directionality(textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, child: text);

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: DecoratedBox(
        decoration: BoxDecoration(color: style.backgroundColor, borderRadius: BorderRadius.circular(6)),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: text),
      ),
    );
  }

  TextStyle _baseStyle(double size, bool rtl) => TextStyle(
    fontSize: size,
    fontWeight: style.fontWeight,
    color: style.color,
    height: style.lineHeight,
    fontFamily: rtl ? style.rtlFontFamily : style.fontFamily,
    package: rtl && style.rtlFontFamily == "Vazir" ? "u" : null,
    shadows: style.shadow
        ? <Shadow>[Shadow(color: style.outlineColor.withValues(alpha: 0.6), blurRadius: 4 * scale, offset: Offset(0, 1 * scale))]
        : null,
  );

  TextStyle _strokeStyle(double size, bool rtl) => TextStyle(
    fontSize: size,
    fontWeight: style.fontWeight,
    height: style.lineHeight,
    fontFamily: rtl ? style.rtlFontFamily : style.fontFamily,
    package: rtl && style.rtlFontFamily == "Vazir" ? "u" : null,
    foreground: Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.outlineWidth * scale
      ..strokeJoin = StrokeJoin.round
      ..color = style.outlineColor,
  );

  Widget _richText(USubtitleCue cue, double size, TextAlign align, bool rtl, TextStyle base, bool isStroke) => Text.rich(
    TextSpan(
      children: cue.spans
          .map(
            (USubtitleSpan span) => TextSpan(
              text: span.text,
              style: !style.honorAssStyling
                  ? null
                  : base.copyWith(
                      fontWeight: span.bold ? FontWeight.w800 : null,
                      fontStyle: span.italic ? FontStyle.italic : null,
                      decoration: span.underline
                          ? TextDecoration.underline
                          : (span.strikethrough ? TextDecoration.lineThrough : null),
                      color: isStroke ? null : span.color,
                      fontSize: span.fontScale == null ? null : size * span.fontScale!,
                    ),
            ),
          )
          .toList(growable: false),
    ),
    style: base,
    textAlign: align,
    maxLines: style.maxLines,
    overflow: TextOverflow.ellipsis,
    textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
  );
}

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

const List<double> uSpeedPresets = <double>[0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 3, 4];

class UVideoStatsOverlay extends StatelessWidget {
  const UVideoStatsOverlay({required this.controller, super.key});

  final UMediaController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UMediaValue>(
    valueListenable: controller,
    builder: (BuildContext context, UMediaValue value, Widget? child) {
      final UMediaTrack? video = value.selectedTrack(UMediaTrackType.video);
      final UMediaTrack? audio = value.selectedTrack(UMediaTrackType.audio);
      final Duration buffer = value.bufferedPosition - value.position;
      return UContainer(
        color: const Color(0xB3000000),
        radius: 8,
        padding: const EdgeInsets.all(10),
        child: UColumn(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _line(U.s.resolution, value.hasVideo ? "${value.width}x${value.height}" : "-"),
            _line(U.s.codec, video?.codec ?? "-"),
            _line(U.s.bitrate, video?.bitrateLabel ?? "-"),
            _line(U.s.frameRate, video?.frameRate == null ? "-" : "${video!.frameRate!.toStringAsFixed(2)} fps"),
            _line(U.s.audioTrack, audio == null ? "-" : "${audio.codec ?? ""} ${audio.channelLabel}".trim()),
            _line(U.s.bufferHealth, "${(buffer.inMilliseconds / 1000).clamp(0, 999).toStringAsFixed(1)}s"),
            _line(U.s.playbackSpeed, "${value.speed}x"),
            _line(U.s.state, value.state.name),
          ],
        ),
      );
    },
  );

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: URow(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(width: 110, child: UTextLabelSmall(label, color: const Color(0x99FFFFFF))),
        UTextLabelSmall(value, color: const Color(0xFFFFFFFF), fontWeight: FontWeight.w700),
      ],
    ),
  );
}

class UMediaTrackSheet extends StatelessWidget {
  const UMediaTrackSheet({required this.controller, required this.type, super.key, this.allowOff = false});

  final UMediaController controller;
  final UMediaTrackType type;
  final bool allowOff;

  String get _title {
    switch (type) {
      case UMediaTrackType.video:
        return U.s.quality;
      case UMediaTrackType.audio:
        return U.s.audioTrack;
      case UMediaTrackType.subtitle:
        return U.s.subtitles;
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UMediaValue>(
    valueListenable: controller,
    builder: (BuildContext context, UMediaValue value, Widget? child) {
      final List<UMediaTrack> tracks = value.tracksOf(type);
      return UColumn(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: <Widget>[
          Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 8), child: UTextTitleMedium(_title, fontWeight: FontWeight.w700)),
          if (type == UMediaTrackType.video)
            ListTile(
              leading: const Icon(Icons.hd_rounded),
              title: UTextBodyMedium(U.s.auto),
              trailing: value.selectedTrack(type) == null ? const Icon(Icons.check_rounded) : null,
              onTap: () {
                unawaited(controller.setAutoQuality());
                Navigator.of(context).pop();
              },
            ),
          if (allowOff)
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: UTextBodyMedium(U.s.off),
              trailing: controller.subtitles == null ? const Icon(Icons.check_rounded) : null,
              onTap: () {
                controller.clearSubtitles();
                Navigator.of(context).pop();
              },
            ),
          if (tracks.isEmpty && !allowOff)
            Padding(
              padding: const EdgeInsets.all(20),
              child: UTextBodySmall(U.s.noTracksAvailable, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ...tracks.map(
            (UMediaTrack track) => ListTile(
              leading: Icon(_iconFor(track)),
              title: UTextBodyMedium(_labelFor(track)),
              subtitle: _subtitleFor(track) == null ? null : UTextLabelSmall(_subtitleFor(track)!),
              trailing: track.isSelected ? const Icon(Icons.check_rounded) : null,
              onTap: () {
                unawaited(controller.selectTrack(track));
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      );
    },
  );

  IconData _iconFor(UMediaTrack track) {
    switch (track.type) {
      case UMediaTrackType.video:
        return Icons.high_quality_rounded;
      case UMediaTrackType.audio:
        return Icons.graphic_eq_rounded;
      case UMediaTrackType.subtitle:
        return Icons.subtitles_rounded;
    }
  }

  String _labelFor(UMediaTrack track) {
    if (track.label != null && track.label!.isNotEmpty) return track.label!;
    if (track.type == UMediaTrackType.video) return track.qualityLabel.isEmpty ? track.id : track.qualityLabel;
    return track.language ?? track.id;
  }

  String? _subtitleFor(UMediaTrack track) {
    final List<String> parts = <String>[
      if (track.language != null && track.label != null) track.language!,
      if (track.bitrateLabel.isNotEmpty) track.bitrateLabel,
      if (track.channelLabel.isNotEmpty) track.channelLabel,
      if (track.codec != null) track.codec!,
    ];
    return parts.isEmpty ? null : parts.join(" · ");
  }
}

class UVideoSettingsSheet extends StatefulWidget {
  const UVideoSettingsSheet({required this.controller, required this.settings, super.key});

  final UMediaController controller;
  final UVideoSettings settings;

  @override
  State<UVideoSettingsSheet> createState() => _UVideoSettingsSheetState();
}

class _UVideoSettingsSheetState extends State<UVideoSettingsSheet> {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.settings,
    builder: (BuildContext context, Widget? child) => DefaultTabController(
      length: 4,
      child: UColumn(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TabBar(
            isScrollable: true,
            tabs: <Widget>[
              Tab(text: U.s.playback),
              Tab(text: U.s.subtitles),
              Tab(text: U.s.videoFilters),
              Tab(text: U.s.advanced),
            ],
          ),
          SizedBox(
            height: 340,
            child: TabBarView(
              children: <Widget>[_playbackTab(context), _subtitleTab(context), _filterTab(context), _advancedTab(context)],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _playbackTab(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: <Widget>[
      _sectionLabel(U.s.playbackSpeed),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: uSpeedPresets
            .map(
              (double speed) => ChoiceChip(
                label: Text("${speed}x"),
                selected: widget.controller.value.speed == speed,
                onSelected: (bool _) => unawaited(widget.controller.setSpeed(speed)),
              ),
            )
            .toList(growable: false),
      ).pSymmetric(horizontal: 16),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.high_quality_rounded),
        title: UTextBodyMedium(U.s.quality),
        onTap: () => UNavigator.bottomSheet(UMediaTrackSheet(controller: widget.controller, type: UMediaTrackType.video)),
      ),
      ListTile(
        leading: const Icon(Icons.graphic_eq_rounded),
        title: UTextBodyMedium(U.s.audioTrack),
        onTap: () => UNavigator.bottomSheet(UMediaTrackSheet(controller: widget.controller, type: UMediaTrackType.audio)),
      ),
      _sectionLabel(U.s.aspectRatio),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: UMediaFit.values
            .map(
              (UMediaFit fit) => ChoiceChip(
                label: Text(_fitLabel(fit)),
                selected: widget.settings.fit == fit,
                onSelected: (bool _) => widget.settings.fit = fit,
              ),
            )
            .toList(growable: false),
      ).pSymmetric(horizontal: 16),
    ],
  );

  Widget _subtitleTab(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: <Widget>[
      ListTile(
        leading: const Icon(Icons.subtitles_rounded),
        title: UTextBodyMedium(U.s.subtitleTrack),
        onTap: () => UNavigator.bottomSheet(UMediaTrackSheet(controller: widget.controller, type: UMediaTrackType.subtitle, allowOff: true)),
      ),
      ListTile(
        leading: const Icon(Icons.folder_open_rounded),
        title: UTextBodyMedium(U.s.loadSubtitleFile),
        onTap: () => unawaited(_pickSubtitle()),
      ),
      _slider(U.s.subtitleSize, widget.settings.subtitleScale, 0.5, 3, (double v) => widget.settings.subtitleScale = v),
      _slider(
        U.s.subtitleDelay,
        widget.settings.subtitleDelay.inMilliseconds / 1000,
        -10,
        10,
        (double v) => widget.settings.setSubtitleDelay(widget.controller, Duration(milliseconds: (v * 1000).round())),
        suffix: "s",
      ),
    ],
  );

  Widget _filterTab(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: <Widget>[
      _slider(U.s.brightness, widget.settings.brightness, -1, 1, (double v) => widget.settings.brightness = v),
      _slider(U.s.contrast, widget.settings.contrast, 0, 3, (double v) => widget.settings.contrast = v),
      _slider(U.s.saturation, widget.settings.saturation, 0, 3, (double v) => widget.settings.saturation = v),
      _slider(U.s.hue, widget.settings.hue, -180, 180, (double v) => widget.settings.hue = v),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: UButton(type: UButtonType.outlined, title: U.s.resetFilters, onTap: widget.settings.resetFilters),
      ),
    ],
  );

  Widget _advancedTab(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: <Widget>[
      SwitchListTile(
        secondary: const Icon(Icons.analytics_rounded),
        title: UTextBodyMedium(U.s.statistics),
        value: widget.settings.showStats,
        onChanged: (bool value) => widget.settings.showStats = value,
      ),
      ListTile(
        leading: const Icon(Icons.rotate_90_degrees_cw_rounded),
        title: UTextBodyMedium(U.s.rotate),
        onTap: widget.settings.rotateQuarter,
      ),
      SwitchListTile(
        secondary: const Icon(Icons.flip_rounded),
        title: UTextBodyMedium(U.s.mirror),
        value: widget.settings.mirrored,
        onChanged: (bool value) => widget.settings.mirrored = value,
      ),
      ListTile(
        leading: const Icon(Icons.repeat_on_rounded),
        title: UTextBodyMedium(U.s.abRepeat),
        subtitle: UTextLabelSmall(
          widget.settings.hasAbRepeat
              ? "${uFormatDuration(widget.settings.repeatStart!)} — ${uFormatDuration(widget.settings.repeatEnd!)}"
              : (widget.settings.repeatStart == null ? U.s.setPointA : U.s.setPointB),
        ),
        trailing: widget.settings.repeatStart == null
            ? null
            : IconButton(onPressed: widget.settings.clearRepeat, icon: const Icon(Icons.close_rounded)),
        onTap: () {
          if (widget.settings.repeatStart == null) {
            widget.settings.markRepeatStart(widget.controller.value.position);
          } else if (widget.settings.repeatEnd == null) {
            widget.settings.markRepeatEnd(widget.controller.value.position);
          } else {
            widget.settings.clearRepeat();
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.bedtime_rounded),
        title: UTextBodyMedium(U.s.sleepTimer),
        subtitle: widget.settings.sleepAt == null ? null : UTextLabelSmall(uFormatDuration(widget.settings.sleepAt!.difference(DateTime.now()))),
        onTap: () => _sleepTimerDialog(context),
      ),
      ListTile(
        leading: const Icon(Icons.camera_alt_rounded),
        title: UTextBodyMedium(U.s.screenshot),
        onTap: () => unawaited(_takeScreenshot()),
      ),
    ],
  );

  Future<void> _pickSubtitle() async {
    final FileData? picked = await UFile.pickFile(fileType: FileType.custom, allowedExtensions: <String>["srt", "vtt", "ass", "ssa", "sub", "lrc"]);
    final String? path = picked?.path;
    if (path == null) return;
    await widget.controller.loadSubtitle(UExternalSubtitle(uri: path, label: picked?.name));
  }

  Future<void> _takeScreenshot() async {
    final Uint8List? bytes = await widget.controller.screenshot();
    if (bytes == null) {
      UToast.error(message: U.s.thisFieldIsInvalid);
      return;
    }
    UToast.success(message: U.s.screenshotSaved);
  }

  void _sleepTimerDialog(BuildContext context) {
    UNavigator.bottomSheet(
      UColumn(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final int minutes in <int>[5, 10, 15, 30, 45, 60, 90])
            ListTile(
              title: UTextBodyMedium("$minutes ${U.s.minutes}"),
              onTap: () {
                widget.settings.startSleepTimer(Duration(minutes: minutes), () => unawaited(widget.controller.pause()));
                Navigator.of(context).pop();
              },
            ),
          if (widget.settings.sleepAt != null)
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: UTextBodyMedium(U.s.cancel),
              onTap: () {
                widget.settings.cancelSleepTimer();
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
    child: UTextLabelLarge(text, fontWeight: FontWeight.w700),
  );

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged, {String suffix = ""}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: UColumn(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          children: <Widget>[
            Expanded(child: UTextLabelLarge(label)),
            UTextLabelSmall("${value.toStringAsFixed(2)}$suffix"),
          ],
        ),
        Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
      ],
    ),
  );

  String _fitLabel(UMediaFit fit) {
    switch (fit) {
      case UMediaFit.contain:
        return U.s.fit;
      case UMediaFit.cover:
        return U.s.cover;
      case UMediaFit.fill:
        return U.s.stretch;
      case UMediaFit.fitWidth:
        return U.s.fitWidth;
      case UMediaFit.fitHeight:
        return U.s.fitHeight;
      case UMediaFit.none:
      case UMediaFit.original:
        return U.s.original;
      case UMediaFit.ratio16x9:
        return "16:9";
      case UMediaFit.ratio4x3:
        return "4:3";
      case UMediaFit.ratio21x9:
        return "21:9";
      case UMediaFit.ratio1x1:
        return "1:1";
    }
  }
}

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

class UFloatingMiniPlayer extends StatefulWidget {
  const UFloatingMiniPlayer({
    required this.controller,
    super.key,
    this.width = 190,
    this.margin = 12,
    this.borderRadius = 12,
    this.onExpand,
    this.onClose,
  });

  final UMediaController controller;
  final double width;
  final double margin;
  final double borderRadius;
  final VoidCallback? onExpand;
  final VoidCallback? onClose;

  @override
  State<UFloatingMiniPlayer> createState() => _UFloatingMiniPlayerState();
}

class _UFloatingMiniPlayerState extends State<UFloatingMiniPlayer> {
  Offset _position = Offset.zero;
  bool _initialised = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final UMediaValue value = widget.controller.value;
      final double height = widget.width / (value.hasVideo ? value.aspectRatio : 16 / 9);
      if (!_initialised) {
        _position = Offset(constraints.maxWidth - widget.width - widget.margin, constraints.maxHeight - height - widget.margin);
        _initialised = true;
      }

      return Stack(
        children: <Widget>[
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: GestureDetector(
              onPanUpdate: (DragUpdateDetails details) => setState(() => _position += details.delta),
              onPanEnd: (DragEndDetails _) => setState(() {
                final bool right = _position.dx + widget.width / 2 > constraints.maxWidth / 2;
                _position = Offset(
                  right ? constraints.maxWidth - widget.width - widget.margin : widget.margin,
                  _position.dy.clamp(widget.margin, constraints.maxHeight - height - widget.margin),
                );
              }),
              onTap: widget.onExpand,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                clipBehavior: Clip.antiAlias,
                color: const Color(0xFF000000),
                child: SizedBox(
                  width: widget.width,
                  height: height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      UVideoView(controller: widget.controller),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.close_rounded, color: Color(0xFFFFFFFF), size: 18),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      Align(
                        child: ValueListenableBuilder<UMediaValue>(
                          valueListenable: widget.controller,
                          builder: (BuildContext context, UMediaValue state, Widget? child) => IconButton(
                            onPressed: () => unawaited(widget.controller.playPause()),
                            icon: Icon(state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: const Color(0xFFFFFFFF), size: 28),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class UVideoPlayer extends StatefulWidget {
  const UVideoPlayer({
    super.key,
    this.url,
    this.base64,
    this.bytes,
    this.filePath,
    this.assetPath,
    this.autoPlay = false,
    this.looping = false,
    this.muted = false,
    this.showControls = true,
    this.allowFullScreen = true,
    this.allowPlaybackSpeed = true,
    this.autoHideControls = true,
    this.aspectRatio,
    this.fit = BoxFit.contain,
    this.accentColor,
    this.backgroundColor = const Color(0xFF000000),
    this.borderRadius = 12,
    this.placeholder,
    this.title,
    this.gestures = const UVideoGestureConfig(),
  }) : assert(
         url != null || base64 != null || bytes != null || filePath != null || assetPath != null,
         "Provide one video source",
       );

  final String? url;
  final String? base64;
  final Uint8List? bytes;
  final String? filePath;
  final String? assetPath;
  final bool autoPlay;
  final bool looping;
  final bool muted;
  final bool showControls;
  final bool allowFullScreen;
  final bool allowPlaybackSpeed;
  final bool autoHideControls;
  final double? aspectRatio;
  final BoxFit fit;
  final Color? accentColor;
  final Color backgroundColor;
  final double borderRadius;
  final Widget? placeholder;
  final String? title;
  final UVideoGestureConfig gestures;

  static UMediaFit fitOf(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:
        return UMediaFit.cover;
      case BoxFit.fill:
        return UMediaFit.fill;
      case BoxFit.fitWidth:
        return UMediaFit.fitWidth;
      case BoxFit.fitHeight:
        return UMediaFit.fitHeight;
      case BoxFit.none:
        return UMediaFit.none;
      case BoxFit.contain:
      case BoxFit.scaleDown:
        return UMediaFit.contain;
    }
  }

  @override
  State<UVideoPlayer> createState() => _UVideoPlayerState();
}

class _UVideoPlayerState extends State<UVideoPlayer> {
  late final UMediaController _controller;
  late final UVideoSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = UVideoSettings(fit: UVideoPlayer.fitOf(widget.fit));
    _controller = UMediaController(
      config: UMediaConfig(
        autoPlay: widget.autoPlay,
        muted: widget.muted,
        repeat: widget.looping ? URepeatMode.one : URepeatMode.off,
      ),
    );
    unawaited(_controller.open(_source(), autoPlay: widget.autoPlay));
  }

  @override
  void didUpdateWidget(covariant UVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.filePath != widget.filePath || oldWidget.assetPath != widget.assetPath) {
      unawaited(_controller.open(_source(), autoPlay: widget.autoPlay));
    }
    if (oldWidget.fit != widget.fit) _settings.fit = UVideoPlayer.fitOf(widget.fit);
  }

  UMediaSource _source() {
    final Uint8List? raw = widget.bytes;
    if (raw != null) return UMediaSource.bytes(raw);

    final String? encoded = widget.base64;
    if (encoded != null) {
      final String payload = encoded.contains(",") ? encoded.split(",").last : encoded;
      return UMediaSource.bytes(base64Decode(payload));
    }

    final String? path = widget.filePath;
    if (path != null) return UMediaSource.file(path);

    final String? asset = widget.assetPath;
    if (asset != null) return UMediaSource.asset(asset);

    return UMediaSource.network(widget.url ?? "");
  }

  @override
  void dispose() {
    _controller.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UVideo(
    controller: _controller,
    settings: _settings,
    title: widget.title,
    gestures: widget.gestures,
    accentColor: widget.accentColor,
    backgroundColor: widget.backgroundColor,
    borderRadius: widget.borderRadius,
    showControls: widget.showControls,
    showFullscreenButton: widget.allowFullScreen,
    autoHide: widget.autoHideControls ? const Duration(seconds: 3) : Duration.zero,
    aspectRatio: widget.aspectRatio,
    placeholder: widget.placeholder,
  );
}

/// Opens a player full-width inside a bottom sheet. Accepts the same sources as
/// [UVideoPlayer].

abstract final class UVideoSheet {
  static Future<void> show({
    String? url,
    String? base64,
    Uint8List? bytes,
    String? filePath,
    String? assetPath,
    String? title,
    bool autoPlay = true,
  }) => UNavigator.bottomSheet(
    UScaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF000000), iconTheme: const IconThemeData(color: Color(0xFFFFFFFF))),
      color: const Color(0xFF000000),
      body: Center(
        child: UVideoPlayer(
          url: url,
          base64: base64,
          bytes: bytes,
          filePath: filePath,
          assetPath: assetPath,
          title: title,
          autoPlay: autoPlay,
          borderRadius: 0,
        ),
      ),
    ),
  );
}
