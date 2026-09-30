import "package:u/utilities.dart";

/// Per-player view settings: fit, zoom, rotation, mirror, color filters, subtitle style/delay, A-B repeat, sleep timer.
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

  /// How the video fills the screen (contain, cover, 16:9…).
  UMediaFit get fit => _fit;

  /// Zoom level (1 = none).
  double get zoom => _zoom;

  /// Rotation in quarter turns.
  int get rotation => _rotation;

  /// Mirrors the picture.
  bool get mirrored => _mirrored;

  /// Screen brightness override while playing (0-1).
  double get screenBrightness => _screenBrightness;

  /// Picture brightness filter (0 = normal).
  double get brightness => _brightness;

  /// Picture contrast filter (1 = normal).
  double get contrast => _contrast;

  /// Picture saturation filter (1 = normal).
  double get saturation => _saturation;

  /// Picture hue shift in degrees.
  double get hue => _hue;

  /// Shows the technical stats overlay.
  bool get showStats => _showStats;

  /// Subtitle font, colors and outline.
  USubtitleStyleConfig get subtitleStyle => _subtitleStyle;

  /// Subtitle size multiplier.
  double get subtitleScale => _subtitleScale;

  /// Subtitle timing shift.
  Duration get subtitleDelay => _subtitleDelay;

  /// A point of A-B repeat.
  Duration? get repeatStart => _repeatStart;

  /// B point of A-B repeat.
  Duration? get repeatEnd => _repeatEnd;

  /// When the sleep timer stops playback.
  DateTime? get sleepAt => _sleepAt;

  /// True when any color filter is changed.
  bool get hasFilters => _brightness != 0 || _contrast != 1 || _saturation != 1 || _hue != 0;

  /// True when A-B repeat is set.
  bool get hasAbRepeat => _repeatStart != null && _repeatEnd != null;

  /// How the video fills the screen (contain, cover, 16:9…).
  set fit(UMediaFit value) {
    _fit = value;
    notifyListeners();
  }

  /// Zoom level (1 = none).
  set zoom(double value) {
    _zoom = value.clamp(1, 4).toDouble();
    notifyListeners();
  }

  /// Rotation in quarter turns.
  set rotation(int value) {
    _rotation = value % 360;
    notifyListeners();
  }

  /// Mirrors the picture.
  set mirrored(bool value) {
    _mirrored = value;
    notifyListeners();
  }

  /// Screen brightness override while playing (0-1).
  set screenBrightness(double value) {
    _screenBrightness = value.clamp(0.05, 1).toDouble();
    notifyListeners();
  }

  /// Picture brightness filter (0 = normal).
  set brightness(double value) {
    _brightness = value.clamp(-1, 1).toDouble();
    notifyListeners();
  }

  /// Picture contrast filter (1 = normal).
  set contrast(double value) {
    _contrast = value.clamp(0, 3).toDouble();
    notifyListeners();
  }

  /// Picture saturation filter (1 = normal).
  set saturation(double value) {
    _saturation = value.clamp(0, 3).toDouble();
    notifyListeners();
  }

  /// Picture hue shift in degrees.
  set hue(double value) {
    _hue = value.clamp(-180, 180).toDouble();
    notifyListeners();
  }

  /// Shows the technical stats overlay.
  set showStats(bool value) {
    _showStats = value;
    notifyListeners();
  }

  /// Subtitle font, colors and outline.
  set subtitleStyle(USubtitleStyleConfig value) {
    _subtitleStyle = value;
    notifyListeners();
  }

  /// Subtitle size multiplier.
  set subtitleScale(double value) {
    _subtitleScale = value.clamp(0.5, 3).toDouble();
    notifyListeners();
  }

  /// Shifts subtitles on [controller] by [value].
  void setSubtitleDelay(UMediaController controller, Duration value) {
    _subtitleDelay = value;
    controller.setSubtitleDelay(value);
    notifyListeners();
  }

  /// Switches to the next fit mode.
  void cycleFit() {
    const List<UMediaFit> order = <UMediaFit>[UMediaFit.contain, UMediaFit.cover, UMediaFit.fill, UMediaFit.ratio16x9, UMediaFit.ratio4x3, UMediaFit.original];
    final int index = order.indexOf(_fit);
    fit = order[(index + 1) % order.length];
  }

  /// Rotates 90°.
  void rotateQuarter() => rotation = _rotation + 90;

  /// Resets brightness/contrast/saturation/hue.
  void resetFilters() {
    _brightness = 0;
    _contrast = 1;
    _saturation = 1;
    _hue = 0;
    notifyListeners();
  }

  /// Resets zoom, rotation and mirror.
  void resetView() {
    _zoom = 1;
    _rotation = 0;
    _mirrored = false;
    _fit = UMediaFit.contain;
    notifyListeners();
  }

  /// Sets the A point of A-B repeat.
  void markRepeatStart(Duration position) {
    _repeatStart = position;
    _repeatEnd = null;
    notifyListeners();
  }

  /// Sets the B point of A-B repeat.
  void markRepeatEnd(Duration position) {
    if (_repeatStart == null || position <= _repeatStart!) return;
    _repeatEnd = position;
    notifyListeners();
  }

  /// Turns A-B repeat off.
  void clearRepeat() {
    _repeatStart = null;
    _repeatEnd = null;
    notifyListeners();
  }

  /// Calls [onElapsed] after [duration] (e.g. pause).
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

  /// Cancels the sleep timer.
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

/// Color matrices for video brightness/contrast/saturation/hue filters.
abstract final class UVideoColorMatrix {
  /// The "no change" matrix.
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
      0.213 + cosine * 0.787 - sine * 0.213,
      0.715 - cosine * 0.715 - sine * 0.715,
      0.072 - cosine * 0.072 + sine * 0.928,
      0,
      0,
      0.213 - cosine * 0.213 + sine * 0.143,
      0.715 + cosine * 0.285 + sine * 0.140,
      0.072 - cosine * 0.072 - sine * 0.283,
      0,
      0,
      0.213 - cosine * 0.213 - sine * 0.787,
      0.715 - cosine * 0.715 + sine * 0.715,
      0.072 + cosine * 0.928 + sine * 0.072,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  /// Combines two color matrices.
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

/// Applies UVideoSettings color filters to a child.
class UVideoFilterLayer extends StatelessWidget {
  const UVideoFilterLayer({required this.settings, required this.child, super.key});

  /// Settings.
  final UVideoSettings settings;

  /// The widget inside.
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

/// The video surface of a UMediaController (fit, zoom, pan, rotation). `UVideoView(controller: c)`
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

  /// Controller to read or change it from code.
  final UMediaController controller;

  /// How the content fits its box (BoxFit).
  final UMediaFit fit;

  /// Zoom level.
  final double zoom;

  /// Pan offset while zoomed.
  final Offset pan;

  /// Rotation in degrees.
  final int rotationDegrees;

  /// Mirrors horizontally.
  final bool mirrored;

  /// Background color.
  final Color? backgroundColor;

  /// Shown while loading.
  final Widget? placeholder;

  /// Shown when loading fails.
  final Widget Function(BuildContext context, UMediaError error)? errorBuilder;

  /// Aspect ratio of a fit mode (null = the video's own).
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

  /// BoxFit of a fit mode.
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
    if (mirrored) content = Transform(alignment: Alignment.center, transform: Matrix4.identity()..scaleByDouble(-1, 1, 1, 1), child: content);
    if (zoom != 1 || pan != Offset.zero) {
      content = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..translateByDouble(pan.dx, pan.dy, 0, 1)
          ..scaleByDouble(zoom, zoom, 1, 1),
        child: content,
      );
    }

    // cover and fill are meant to take the whole box, so they must not be
    // boxed in by the video's own aspect ratio first.
    if (fit == UMediaFit.cover || fit == UMediaFit.fill) return ClipRect(child: content);

    final double ratio = ratioOf(fit) ?? value.aspectRatio;
    return ClipRect(
      child: Center(
        child: AspectRatio(aspectRatio: ratio <= 0 ? 16 / 9 : ratio, child: content),
      ),
    );
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

/// Subtitle look: size, color, outline, background, fonts (separate RTL font), padding, max lines.
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

  /// Font size.
  final double fontSize;

  /// Main color (defaults to the theme).
  final Color color;

  /// Text outline color.
  final Color outlineColor;

  /// Text outline width.
  final double outlineWidth;

  /// Background color.
  final Color backgroundColor;

  /// Font weight.
  final FontWeight fontWeight;

  /// Font for left-to-right text.
  final String? fontFamily;

  /// Font for Persian/Arabic text.
  final String? rtlFontFamily;

  /// Distance from the bottom.
  final double bottomPadding;

  /// Side padding.
  final double horizontalPadding;

  /// Line height.
  final double lineHeight;

  /// Adds a drop shadow.
  final bool shadow;

  /// Uses colors/positions from ASS/SSA files.
  final bool honorAssStyling;

  /// Most lines shown at once.
  final int maxLines;

  /// Copy with some fields changed.
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

/// Draws the current subtitle cue of a controller.
class USubtitleView extends StatelessWidget {
  const USubtitleView({required this.controller, super.key, this.style = const USubtitleStyleConfig(), this.scale = 1});

  /// Controller to read or change it from code.
  final UMediaController controller;

  /// Text style (defaults to the theme).
  final USubtitleStyleConfig style;

  /// Scales the painted widget (1 = normal size).
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
    shadows: style.shadow ? <Shadow>[Shadow(color: style.outlineColor.withValues(alpha: 0.6), blurRadius: 4 * scale, offset: Offset(0, 1 * scale))] : null,
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
                      decoration: span.underline ? TextDecoration.underline : (span.strikethrough ? TextDecoration.lineThrough : null),
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

/// Which player gestures are on: tap, double-tap seek, horizontal scrub, vertical volume/brightness, long-press 2×, pinch zoom, swipe-down close.
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

  /// Tap shows/hides the controls.
  final bool tapToToggleControls;

  /// Double tap left/right seeks back/forward.
  final bool doubleTapSeek;

  /// How far a double tap seeks.
  final Duration doubleTapStep;

  /// Horizontal drag seeks.
  final bool horizontalScrub;

  /// Vertical drag on the right changes volume.
  final bool verticalVolume;

  /// Vertical drag on the left changes brightness.
  final bool verticalBrightness;

  /// Long press plays faster while held.
  final bool longPressSpeed;

  /// Speed while long-pressing.
  final double longPressSpeedValue;

  /// Pinch zooms the picture.
  final bool pinchZoom;

  /// Swipe down closes (full screen/sheets).
  final bool swipeDownToDismiss;

  /// Swipe speed needed to close.
  final double dismissVelocity;

  /// Light vibration on gesture steps.
  final bool haptics;

  /// True when any vertical gesture is on.
  bool get hasVertical => verticalVolume || verticalBrightness;

  /// Every gesture off.
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

/// Gesture layer over a video (see UVideoGestureConfig).
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
    this.onMouseDoubleTap,
    this.onMouseTap,
    this.enabled = true,
  });

  /// Controller to read or change it from code.
  final UMediaController controller;

  /// The widget inside.
  final Widget child;

  /// Settings.
  final UVideoGestureConfig config;

  /// Called on tap to show/hide controls.
  final VoidCallback? onToggleControls;

  /// Double click with a mouse (desktop/web); typically toggles fullscreen.
  final VoidCallback? onMouseDoubleTap;

  /// Single click with a mouse; typically play/pause.
  final VoidCallback? onMouseTap;

  /// Called with the new zoom.
  final void Function(double zoom)? onZoomChanged;

  /// Called with the new brightness.
  final void Function(double brightness)? onBrightnessChanged;

  /// Called when the user swipes down to close.
  final VoidCallback? onDismiss;

  /// False disables interaction and greys it out.
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
          onTapUp: widget.config.tapToToggleControls || widget.onMouseTap != null
              ? (TapUpDetails d) {
                  if (d.kind == PointerDeviceKind.mouse && widget.onMouseTap != null) {
                    widget.onMouseTap!();
                  } else if (widget.config.tapToToggleControls) {
                    widget.onToggleControls?.call();
                  }
                }
              : null,
          onDoubleTapDown: widget.config.doubleTapSeek || widget.onMouseDoubleTap != null
              ? (TapDownDetails d) {
                  if (d.kind == PointerDeviceKind.mouse && widget.onMouseDoubleTap != null) {
                    widget.onMouseDoubleTap!();
                  } else if (widget.config.doubleTapSeek) {
                    _handleDoubleTap(d.localPosition, size);
                  }
                }
              : null,
          onDoubleTap: widget.config.doubleTapSeek || widget.onMouseDoubleTap != null ? () {} : null,
          onLongPressStart: widget.config.longPressSpeed ? (LongPressStartDetails _) => unawaited(_onLongPressStart()) : null,
          onLongPressEnd: widget.config.longPressSpeed ? (LongPressEndDetails _) => unawaited(_onLongPressEnd()) : null,
          onScaleStart: wantsPan ? (ScaleStartDetails d) => _onScaleStart(d, size) : null,
          onScaleUpdate: wantsPan ? (ScaleUpdateDetails d) => _onScaleUpdate(d, size) : null,
          onScaleEnd: wantsPan ? (ScaleEndDetails d) => unawaited(_onScaleEnd(d)) : null,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              widget.child,
              if (_brightness < 1)
                IgnorePointer(
                  child: ColoredBox(color: const Color(0xFF000000).withValues(alpha: 1 - _brightness)),
                ),
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

/// A labelled range on the seek bar (chapter, intro to skip).
class UVideoMarker {
  const UVideoMarker({required this.start, this.end, this.label, this.color, this.skippable = false});

  /// Start time.
  final Duration start;

  /// End time (null = a single point).
  final Duration? end;

  /// Label text.
  final String? label;

  /// Main color (defaults to the theme).
  final Color? color;

  /// Shows a "Skip" button while inside it.
  final bool skippable;

  /// True when [position] is inside the marker.
  bool contains(Duration position) {
    final Duration? finish = end;
    if (finish == null) return false;
    return position >= start && position < finish;
  }
}

/// Duration → "1:02:03" / "02:03". `uFormatDuration(95.seconds)` → "01:35"
String uFormatDuration(Duration value) {
  String two(int n) => n.toString().padLeft(2, "0");
  final String minutes = two(value.inMinutes.remainder(60));
  final String seconds = two(value.inSeconds.remainder(60));
  return value.inHours > 0 ? "${two(value.inHours)}:$minutes:$seconds" : "$minutes:$seconds";
}

/// Seek bar with buffer, markers and scrub preview.
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
    this.trackColor = const Color(0x40FFFFFF),
    this.bufferColor = const Color(0x66FFFFFF),
  });

  /// Controller to read or change it from code.
  final UMediaController controller;

  /// Track colours; the defaults suit the dark video overlay.
  final Color trackColor;

  /// Color of the buffered part.
  final Color bufferColor;

  /// Chapter/intro markers drawn on the seek bar (skippable ones show a "Skip" button).
  final List<UVideoMarker> markers;

  /// Highlight color (defaults to the theme's primary).
  final Color? accentColor;

  /// Height in logical pixels (null = size to content).
  final double height;

  /// Thumb size.
  final double thumbRadius;

  /// Called when the user starts dragging the seek bar.
  final VoidCallback? onScrubStart;

  /// Called when the user releases the seek bar.
  final VoidCallback? onScrubEnd;

  /// Preview shown above the seek bar while scrubbing.
  final Widget Function(BuildContext context, Duration position)? thumbnailBuilder;

  @override
  State<UVideoSeekBar> createState() => _UVideoSeekBarState();
}

class _UVideoSeekBarState extends State<UVideoSeekBar> {
  double? _dragValue;
  double? _hoverValue;

  UVideoMarker? _markerAt(Duration position, int total) {
    final int slop = max(1500, total ~/ 120);
    UVideoMarker? best;
    int bestDistance = 1 << 30;
    for (final UVideoMarker marker in widget.markers) {
      if (marker.contains(position)) return marker;
      final int distance = (marker.start.inMilliseconds - position.inMilliseconds).abs();
      if (distance <= slop && distance < bestDistance) {
        best = marker;
        bestDistance = distance;
      }
    }
    return best;
  }

  Widget _bubble(BuildContext context, double fraction, int total, double width, Color accent) {
    final Duration position = Duration(milliseconds: (total * fraction).round());
    final UVideoMarker? marker = _markerAt(position, total);
    final String label = marker?.label ?? "";
    const double bubbleWidth = 180;
    final double left = (width * fraction - bubbleWidth / 2).clamp(0, max(0, width - bubbleWidth)).toDouble();
    return Positioned(
      left: left,
      bottom: 28,
      width: bubbleWidth,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xE6000000),
              borderRadius: BorderRadius.circular(8),
              border: marker == null ? null : Border.all(color: marker.color ?? accent),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.thumbnailBuilder != null) Padding(padding: const EdgeInsets.only(bottom: 4), child: widget.thumbnailBuilder!(context, position)),
                Text(
                  uFormatDuration(position),
                  style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12, fontWeight: FontWeight.w700),
                ),
                if (label.isNotEmpty)
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    textDirection: UDocText.isRtl(label) ? TextDirection.rtl : TextDirection.ltr,
                    style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 11),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
          final double? preview = _dragValue ?? _hoverValue;
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) => MouseRegion(
              onHover: (PointerHoverEvent event) => setState(() => _hoverValue = (event.localPosition.dx / max(1, constraints.maxWidth)).clamp(0, 1).toDouble()),
              onExit: (PointerExitEvent event) => setState(() => _hoverValue = null),
              child: SizedBox(
                height: 24,
                child: Stack(
                  clipBehavior: Clip.none,
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
                        onChangeStart: total <= 0
                            ? null
                            : (double _) {
                                widget.onScrubStart?.call();
                                setState(() => _dragValue = position);
                              },
                        onChanged: total <= 0 ? null : (double next) => setState(() => _dragValue = next),
                        onChangeEnd: total <= 0
                            ? null
                            : (double next) {
                                setState(() => _dragValue = null);
                                widget.onScrubEnd?.call();
                                unawaited(widget.controller.seekToProgress(next));
                              },
                      ),
                    ),
                    if (preview != null && total > 0) _bubble(context, preview, total, constraints.maxWidth, accent),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _track(BuildContext context, Color accent, double position, double buffered, int total) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) => Stack(
      alignment: Alignment.centerLeft,
      children: <Widget>[
        Container(
          height: widget.height,
          decoration: BoxDecoration(color: widget.trackColor, borderRadius: BorderRadius.circular(widget.height)),
        ),
        Container(
          height: widget.height,
          width: constraints.maxWidth * buffered,
          decoration: BoxDecoration(color: widget.bufferColor, borderRadius: BorderRadius.circular(widget.height)),
        ),
        Container(
          height: widget.height,
          width: constraints.maxWidth * position.clamp(0, 1),
          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(widget.height)),
        ),
        if (total > 0)
          for (final UVideoMarker marker in widget.markers)
            Positioned(
              left: (constraints.maxWidth * (marker.start.inMilliseconds / total)).clamp(0, max(0, constraints.maxWidth - 3)).toDouble(),
              child: Container(
                width: marker.end == null ? 3 : (constraints.maxWidth * ((marker.end!.inMilliseconds - marker.start.inMilliseconds) / total)).clamp(3, constraints.maxWidth).toDouble(),
                height: widget.height + 4,
                decoration: BoxDecoration(color: marker.color ?? const Color(0xFFFFD54F), borderRadius: BorderRadius.circular(1.5)),
              ),
            ),
      ],
    ),
  );
}

/// Full control layer: play/pause, seek bar, speed, quality, subtitles, PiP, lock, fullscreen, queue, notes.
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
    this.showSeekButtons = true,
    this.showVolumeSlider = false,
    this.seekStep = const Duration(seconds: 10),
    this.isFullscreen = false,
    this.locked = false,
    this.notesCount = 0,
    this.topActions = const <Widget>[],
    this.onBack,
    this.onToggleFullscreen,
    this.onToggleLock,
    this.onOpenSettings,
    this.onOpenQueue,
    this.onAddNote,
    this.onOpenNotes,
    this.onDraw,
    this.onScrubStart,
    this.onScrubEnd,
    this.thumbnailBuilder,
  });

  /// Controller to read or change it from code.
  final UMediaController controller;

  /// False hides it completely (takes no space).
  final bool visible;

  /// Title text.
  final String? title;

  /// Chapter/intro markers drawn on the seek bar (skippable ones show a "Skip" button).
  final List<UVideoMarker> markers;

  /// Highlight color (defaults to the theme's primary).
  final Color? accentColor;

  /// Shows a back button.
  final bool showBack;

  /// Shows the fullscreen button.
  final bool showFullscreen;

  /// Shows the picture-in-picture button (Android, iOS, macOS, web).
  final bool showPip;

  /// Shows the speed button.
  final bool showSpeed;

  /// Shows the quality button (HLS/DASH).
  final bool showQuality;

  /// Shows the subtitle/audio track button.
  final bool showSubtitles;

  /// Shows the playlist button.
  final bool showQueue;

  /// Shows the screen lock button.
  final bool showLock;

  /// Shows the jump back/forward buttons.
  final bool showSeekButtons;

  /// Shows a volume slider (desktop, web).
  final bool showVolumeSlider;

  /// How far the seek buttons / double tap jump.
  final Duration seekStep;

  /// True when shown full screen (changes the fullscreen icon).
  final bool isFullscreen;

  /// True while the screen lock is on.
  final bool locked;

  /// Number of notes (badge on the notes button).
  final int notesCount;

  /// Extra buttons in the top bar.
  final List<Widget> topActions;

  /// Called when the back button is pressed.
  final VoidCallback? onBack;

  /// Called by the fullscreen button.
  final VoidCallback? onToggleFullscreen;

  /// Called by the lock button.
  final VoidCallback? onToggleLock;

  /// Called by the settings button.
  final VoidCallback? onOpenSettings;

  /// Called by the playlist button.
  final VoidCallback? onOpenQueue;

  /// Called by the add-note button.
  final VoidCallback? onAddNote;

  /// Called by the notes button.
  final VoidCallback? onOpenNotes;

  /// Opens the drawing tools (pen, shapes, text) over the paused frame.
  final VoidCallback? onDraw;

  /// Called when the user starts dragging the seek bar.
  final VoidCallback? onScrubStart;

  /// Called when the user releases the seek bar.
  final VoidCallback? onScrubEnd;

  /// Preview shown above the seek bar while scrubbing.
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
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 420 || constraints.maxHeight < 220;
        return UColumn(
          children: <Widget>[
            _topBar(context, compact),
            const Spacer(),
            _centerRow(context, compact),
            const Spacer(),
            _bottomBar(context, compact),
          ],
        );
      },
    ),
  );

  Widget _topBar(BuildContext context, bool compact) => Padding(
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
        ...topActions,
        if (onDraw != null) _iconButton(Icons.draw_rounded, U.s.drawOnVideo, onDraw),
        if (onAddNote != null) _iconButton(Icons.add_comment_rounded, U.s.addTimestampNote, onAddNote),
        if (onOpenNotes != null)
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              _iconButton(Icons.sticky_note_2_outlined, U.s.videoNotes, onOpenNotes),
              if (notesCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: accentColor ?? Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      "$notesCount",
                      style: const TextStyle(color: _onDark, fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        if (showLock && isFullscreen) _iconButton(Icons.lock_open_rounded, U.s.lockControls, onToggleLock),
        if (showPip && !compact) _iconButton(Icons.picture_in_picture_alt_rounded, U.s.pictureInPicture, () => unawaited(controller.enterPip())),
        if (showQueue) _iconButton(Icons.queue_music_rounded, U.s.queue, onOpenQueue),
        _iconButton(Icons.settings_rounded, U.s.settings, onOpenSettings),
      ],
    ),
  );

  Widget _centerRow(BuildContext context, bool compact) => ValueListenableBuilder<UMediaValue>(
    valueListenable: controller,
    builder: (BuildContext context, UMediaValue value, Widget? child) {
      final bool queue = controller.queue.length > 1;
      final int seconds = seekStep.inSeconds;
      return URow(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: compact ? 14 : 24,
        children: <Widget>[
          if (queue) _circleButton(Icons.skip_previous_rounded, U.s.previous, controller.hasPrevious ? () => unawaited(controller.previous()) : null, compact ? 24 : 28),
          if (showSeekButtons && !value.isLive)
            _circleButton(
              seconds == 10 ? Icons.replay_10_rounded : (seconds == 5 ? Icons.replay_5_rounded : (seconds == 30 ? Icons.replay_30_rounded : Icons.replay_rounded)),
              U.s.seekBackward,
              () => unawaited(controller.seekBy(-seekStep)),
              compact ? 24 : 30,
            ),
          if (value.isBuffering)
            SizedBox(
              width: compact ? 52 : 64,
              height: compact ? 52 : 64,
              child: const Center(child: CircularProgressIndicator(color: _onDark, strokeWidth: 3)),
            )
          else
            _circleButton(
              value.state == UMediaState.completed ? Icons.replay_rounded : (value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
              value.isPlaying ? U.s.pause : U.s.play,
              () => unawaited(controller.playPause()),
              compact ? 34 : 44,
            ),
          if (showSeekButtons && !value.isLive)
            _circleButton(
              seconds == 10 ? Icons.forward_10_rounded : (seconds == 5 ? Icons.forward_5_rounded : (seconds == 30 ? Icons.forward_30_rounded : Icons.forward_rounded)),
              U.s.seekForward,
              () => unawaited(controller.seekBy(seekStep)),
              compact ? 24 : 30,
            ),
          if (queue) _circleButton(Icons.skip_next_rounded, U.s.next, controller.hasNext ? () => unawaited(controller.next()) : null, compact ? 24 : 28),
        ],
      );
    },
  );

  Widget _bottomBar(BuildContext context, bool compact) => ValueListenableBuilder<UMediaValue>(
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
              if (value.isLive) _liveBadge(context, value) else UTextBodySmall("${uFormatDuration(value.position)} / ${uFormatDuration(value.duration)}", color: _onDark),
              const Spacer(),
              _iconButton(value.muted || value.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded, value.muted ? U.s.unmute : U.s.mute, () => unawaited(controller.toggleMute())),
              if (showVolumeSlider && !compact)
                SizedBox(
                  width: 90,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                      activeTrackColor: _onDark,
                      inactiveTrackColor: const Color(0x55FFFFFF),
                      thumbColor: _onDark,
                    ),
                    child: Slider(value: value.muted ? 0 : value.volume.clamp(0, 1).toDouble(), onChanged: (double next) => unawaited(controller.setVolume(next))),
                  ),
                ),
              if (showSubtitles && !compact) _iconButton(controller.subtitles == null ? Icons.closed_caption_off_rounded : Icons.closed_caption_rounded, U.s.subtitles, onOpenSettings),
              if (showQuality && !compact) _textButton(_qualityLabel(value), U.s.quality, onOpenSettings),
              if (showSpeed) _speedButton(value),
              if (showFullscreen) _iconButton(isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, isFullscreen ? U.s.exitFullscreen : U.s.fullscreen, onToggleFullscreen),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _speedButton(UMediaValue value) => PopupMenuButton<double>(
    tooltip: U.s.playbackSpeed,
    initialValue: value.speed,
    onSelected: (double speed) => unawaited(controller.setSpeed(speed)),
    itemBuilder: (BuildContext context) => uSpeedPresets
        .map(
          (double speed) => PopupMenuItem<double>(
            value: speed,
            child: Text("${speed}x", style: TextStyle(fontWeight: speed == value.speed ? FontWeight.w800 : FontWeight.w400)),
          ),
        )
        .toList(),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: UTextBodySmall("${_trim(value.speed)}x", color: _onDark, fontWeight: FontWeight.w700),
    ),
  );

  static String _trim(double speed) => speed == speed.roundToDouble() ? speed.toStringAsFixed(0) : speed.toStringAsFixed(2).replaceAll(RegExp(r"0$"), "");

  String _qualityLabel(UMediaValue value) {
    final UMediaTrack? selected = value.selectedTrack(UMediaTrackType.video);
    final String label = selected?.qualityLabel ?? "";
    return label.isEmpty ? U.s.auto : label;
  }

  Widget _liveBadge(BuildContext context, UMediaValue value) => URow(
    mainAxisSize: MainAxisSize.min,
    spacing: 6,
    children: <Widget>[
      Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
      ),
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

/// Playback speeds offered in the speed menu.
const List<double> uSpeedPresets = <double>[0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 3, 4];

/// Technical stats over the video (resolution, bitrate, buffer, dropped frames).
class UVideoStatsOverlay extends StatelessWidget {
  const UVideoStatsOverlay({required this.controller, super.key});

  /// Controller to read or change it from code.
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

/// Bottom sheet to pick a video quality, audio track or subtitle.
class UMediaTrackSheet extends StatelessWidget {
  const UMediaTrackSheet({required this.controller, required this.type, super.key, this.allowOff = false});

  /// Controller to read or change it from code.
  final UMediaController controller;

  /// Style variant.
  final UMediaTrackType type;

  /// Adds an "Off" option (subtitles).
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: UTextTitleMedium(_title, fontWeight: FontWeight.w700),
          ),
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

/// The player settings sheet (fit, filters, subtitles, A-B repeat, sleep timer).
class UVideoSettingsSheet extends StatefulWidget {
  const UVideoSettingsSheet({required this.controller, required this.settings, super.key});

  /// Controller to read or change it from code.
  final UMediaController controller;

  /// Settings.
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
      ValueListenableBuilder<UMediaValue>(
        valueListenable: widget.controller,
        builder: (BuildContext context, UMediaValue value, Widget? child) =>
            _slider(U.s.fineSpeed, value.speed, 0.25, 4, (double next) => unawaited(widget.controller.setSpeed((next * 20).round() / 20)), suffix: "x"),
      ),
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
        trailing: widget.settings.repeatStart == null ? null : IconButton(onPressed: widget.settings.clearRepeat, icon: const Icon(Icons.close_rounded)),
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
    final UFileData? picked = await UFile.pickFile(fileType: FileType.custom, allowedExtensions: <String>["srt", "vtt", "ass", "ssa", "sub", "lrc"]);
    final Uint8List? bytes = picked?.bytes;
    if (bytes == null) return;
    await widget.controller.loadSubtitleData(USubtitleParser.parseBytes(bytes, label: picked?.name));
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

/// Complete video player for a UMediaController: gestures, controls, subtitles, markers, notes. `UVideo(controller: UMedia.video()..open(UMedia.network(url)))`
class UVideo extends StatefulWidget {
  const UVideo({
    required this.controller,
    super.key,
    this.settings,
    this.title,
    this.markers = const <UVideoMarker>[],
    this.notes,
    this.gestures = const UVideoGestureConfig(),
    this.accentColor,
    this.backgroundColor = const Color(0xFF000000),
    this.borderRadius = 12,
    this.showControls = true,
    this.showFullscreenButton = true,
    this.showQueueButton = false,
    this.showSeekButtons = true,
    this.showNoteOverlays = true,
    this.enableDrawing = true,
    this.drawController,
    this.seekStep = const Duration(seconds: 10),
    this.autoHide = const Duration(seconds: 3),
    this.aspectRatio,
    this.placeholder,
    this.isFullscreen = false,
    this.watermark,
    this.secure = false,
    this.resumeKey,
    this.autoPip = false,
    this.topActions = const <Widget>[],
    this.onDismiss,
    this.onOpenNotes,
    this.thumbnailBuilder,
    this.controlsBuilder,
  });

  /// Controller to read or change it from code.
  final UMediaController controller;

  /// Settings.
  final UVideoSettings? settings;

  /// Title text.
  final String? title;

  /// Chapter/intro markers drawn on the seek bar (skippable ones show a "Skip" button).
  final List<UVideoMarker> markers;

  /// Time-stamped notes: shown on the seek bar, as overlays and via the add-note button.
  final UMediaNotesController? notes;

  /// Which touch gestures are on (tap, double-tap seek, swipes, pinch…).
  final UVideoGestureConfig gestures;

  /// Highlight color (defaults to the theme's primary).
  final Color? accentColor;

  /// Background color.
  final Color backgroundColor;

  /// Corner radius.
  final double borderRadius;

  /// Shows the torch/switch/gallery/zoom controls.
  final bool showControls;

  /// Shows the fullscreen button.
  final bool showFullscreenButton;

  /// Shows the playlist button.
  final bool showQueueButton;

  /// Shows the jump back/forward buttons.
  final bool showSeekButtons;

  /// Shows note drawings over the video.
  final bool showNoteOverlays;

  /// Pen, shapes, highlights and text boxes over the frame (needs [notes]).
  /// Each drawing shows for a chosen time range and is saved with the notes.
  final bool enableDrawing;

  /// Controller for drawing notes on the video.
  final UDocDrawController? drawController;

  /// How far the seek buttons / double tap jump.
  final Duration seekStep;

  /// Hides the controls after this long without touch.
  final Duration autoHide;

  /// Width / height ratio.
  final double? aspectRatio;

  /// Shown while loading.
  final Widget? placeholder;

  /// True when shown full screen (changes the fullscreen icon).
  final bool isFullscreen;

  /// Watermark text painted over the content.
  final UDocWatermark? watermark;

  /// Blocks screenshots and screen recording while visible.
  final bool secure;

  /// Remembers and offers to resume the playback position under this key.
  final String? resumeKey;

  /// Enter picture-in-picture automatically when leaving the app while playing (Android).
  final bool autoPip;

  /// Extra buttons in the top bar.
  final List<Widget> topActions;

  /// Called when the user swipes down to close.
  final VoidCallback? onDismiss;

  /// Opens a notes list; when null and [notes] is set, a bottom sheet is used.
  final VoidCallback? onOpenNotes;

  /// Preview shown above the seek bar while scrubbing.
  final Widget Function(BuildContext context, Duration position)? thumbnailBuilder;

  /// Your own controls instead of UVideoControls.
  final Widget Function(BuildContext context, UMediaController controller, bool visible)? controlsBuilder;

  @override
  State<UVideo> createState() => _UVideoState();
}

class _UVideoState extends State<UVideo> {
  late final UVideoSettings _settings = widget.settings ?? UVideoSettings();
  late final bool _ownsSettings = widget.settings == null;
  final FocusNode _focusNode = FocusNode(debugLabel: "UVideo");

  bool _controlsVisible = true;
  bool _locked = false;
  bool _drawing = false;
  late final UDocDrawController _draw = widget.drawController ?? UDocDrawController();
  late final bool _ownsDraw = widget.drawController == null;
  bool _hovering = false;
  bool _resumeChecked = false;
  Duration? _resumeOffer;
  Timer? _hideTimer;
  Timer? _resumeTimer;
  DateTime _lastResumeSave = DateTime.fromMillisecondsSinceEpoch(0);
  bool _wasPlaying = false;

  bool get _desktop => kIsWeb || UApp.isDesktop;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onValueChanged);
    widget.notes?.addListener(_onNotesChanged);
    _restartHideTimer();
    if (widget.autoPip) unawaited(widget.controller.setAutoPip(true));
  }

  @override
  void didUpdateWidget(UVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onValueChanged);
      widget.controller.addListener(_onValueChanged);
    }
    if (oldWidget.notes != widget.notes) {
      oldWidget.notes?.removeListener(_onNotesChanged);
      widget.notes?.addListener(_onNotesChanged);
    }
    if (oldWidget.autoPip != widget.autoPip) unawaited(widget.controller.setAutoPip(widget.autoPip));
  }

  @override
  void dispose() {
    _saveResume(force: true);
    _hideTimer?.cancel();
    _resumeTimer?.cancel();
    widget.controller.removeListener(_onValueChanged);
    widget.notes?.removeListener(_onNotesChanged);
    if (widget.autoPip && !widget.isFullscreen) unawaited(widget.controller.setAutoPip(false));
    if (_ownsDraw) _draw.dispose();
    _focusNode.dispose();
    if (_ownsSettings) _settings.dispose();
    super.dispose();
  }

  void _onNotesChanged() {
    if (mounted) setState(() {});
  }

  void _onValueChanged() {
    final UMediaValue value = widget.controller.value;
    if (_settings.hasAbRepeat && value.position >= _settings.repeatEnd!) unawaited(widget.controller.seek(_settings.repeatStart!));
    _checkResume(value);
    _saveResume();
    if (value.isPlaying != _wasPlaying) {
      _wasPlaying = value.isPlaying;
      if (value.isPlaying) {
        _restartHideTimer();
      } else if (mounted && !_controlsVisible) {
        setState(() => _controlsVisible = true);
      }
    }
  }

  void _checkResume(UMediaValue value) {
    final String? key = widget.resumeKey;
    if (key == null || _resumeChecked || widget.isFullscreen || value.duration <= Duration.zero) return;
    _resumeChecked = true;
    final Duration? saved = UMediaResume.get(key);
    if (saved == null || saved >= value.duration - const Duration(seconds: 8)) return;
    unawaited(widget.controller.seek(saved));
    setState(() => _resumeOffer = saved);
    _resumeTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _resumeOffer = null);
    });
  }

  void _saveResume({bool force = false}) {
    final String? key = widget.resumeKey;
    if (key == null || widget.isFullscreen || !_resumeChecked) return;
    final DateTime now = DateTime.now();
    if (!force && now.difference(_lastResumeSave) < const Duration(seconds: 4)) return;
    _lastResumeSave = now;
    final UMediaValue value = widget.controller.value;
    if (value.duration > Duration.zero) UMediaResume.save(key, value.position, value.duration);
  }

  bool get _drawingEnabled => widget.enableDrawing && widget.notes != null;

  /// Pauses on the current frame and shows the drawing tools (or hides them).
  void _toggleDrawing([bool? open]) {
    final bool next = open ?? !_drawing;
    if (next) {
      unawaited(widget.controller.pause());
      _hideTimer?.cancel();
      if (!_draw.isActive) _draw.tool = UDocDrawTool.pen;
    } else {
      _draw.tool = UDocDrawTool.none;
    }
    setState(() {
      _drawing = next;
      _controlsVisible = !next;
    });
    if (!next) _restartHideTimer();
  }

  /// New drawings appear from the paused moment for [UDocDrawController.videoDuration] (0 = until the end).
  UDocShape _stampTime(UDocShape shape) {
    final int start = widget.controller.value.position.inMilliseconds;
    final int length = _draw.videoDuration.inMilliseconds;
    return length <= 0 ? shape.placed(startMs: start) : shape.placed(startMs: start, endMs: start + length);
  }

  /// Where the picture actually is inside the player (letterboxing excluded).
  Rect _frameRect(Size box, UMediaValue value) {
    final UMediaFit fit = _settings.fit;
    if (fit == UMediaFit.cover || fit == UMediaFit.fill || box.height <= 0) return Offset.zero & box;
    double ratio = UVideoView.ratioOf(fit) ?? value.aspectRatio;
    if (ratio <= 0 || !ratio.isFinite) ratio = 16 / 9;
    final Size size = box.width / box.height > ratio ? Size(box.height * ratio, box.height) : Size(box.width, box.width / ratio);
    return Rect.fromCenter(center: box.center(Offset.zero), width: size.width, height: size.height);
  }

  Widget _drawOverlay() => ValueListenableBuilder<UMediaValue>(
    valueListenable: widget.controller,
    builder: (BuildContext context, UMediaValue value, Widget? child) {
      final UMediaNotesController notes = widget.notes!;
      final List<UDocShape> shapes = notes.shapesAt(value.position);
      if (shapes.isEmpty && !_drawing) return const SizedBox.shrink();
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          Widget layer = UDocShapeLayer(
            shapes: shapes,
            tools: _draw,
            enabled: _drawing,
            prepare: _stampTime,
            onAdd: notes.addShape,
            onUpdate: notes.updateShape,
            onRemove: notes.removeShape,
          );
          if (_settings.zoom != 1) layer = Transform.scale(scale: _settings.zoom, child: layer);
          return Stack(
            children: <Widget>[Positioned.fromRect(rect: _frameRect(constraints.biggest, value), child: layer)],
          );
        },
      );
    },
  );

  Widget _drawToolbar() => Positioned(
    left: 0,
    right: 0,
    top: 0,
    child: Material(
      color: const Color(0xD9000000),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52,
          child: UDocDrawToolbar(
            tools: _draw,
            dark: true,
            showVideoDuration: true,
            onUndo: widget.notes!.canUndo ? widget.notes!.undo : null,
            onRedo: widget.notes!.canRedo ? widget.notes!.redo : null,
            onDone: () => _toggleDrawing(false),
          ),
        ),
      ),
    ),
  );

  void _restartHideTimer() {
    _hideTimer?.cancel();
    if (widget.autoHide <= Duration.zero) return;
    _hideTimer = Timer(widget.autoHide, () {
      if (mounted && widget.controller.value.isPlaying && !_hovering) setState(() => _controlsVisible = false);
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
      notes: widget.notes,
      gestures: widget.gestures,
      accentColor: widget.accentColor,
      thumbnailBuilder: widget.thumbnailBuilder,
      watermark: widget.watermark,
      seekStep: widget.seekStep,
      forceLandscape: !_desktop && widget.controller.value.aspectRatio >= 1,
    );
  }

  Future<void> _addNote() async {
    final UMediaNotesController? notes = widget.notes;
    if (notes == null) return;
    _hideTimer?.cancel();
    await UMediaNotes.addAtCurrentTime(notes, widget.controller);
    _restartHideTimer();
  }

  void _openNotes() {
    final UMediaNotesController? notes = widget.notes;
    if (widget.onOpenNotes != null) {
      widget.onOpenNotes!();
    } else if (notes != null) {
      unawaited(UMediaNotes.showPanel(notes, widget.controller));
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final UMediaController controller = widget.controller;
    final bool shift = HardwareKeyboard.instance.isShiftPressed;
    final LogicalKeyboardKey key = event.logicalKey;
    if (UDocDrawController.isTyping) return KeyEventResult.ignored;
    if (_drawing) {
      final String? selected = _draw.selectedId;
      final bool command = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
      if (key == LogicalKeyboardKey.escape) {
        selected != null ? _draw.selectedId = null : _toggleDrawing(false);
      } else if (selected != null && (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.backspace)) {
        _draw.selectedId = null;
        widget.notes!.removeShape(selected);
      } else if (command && key == LogicalKeyboardKey.keyZ) {
        shift ? widget.notes!.redo() : widget.notes!.undo();
      } else {
        return KeyEventResult.ignored;
      }
      return KeyEventResult.handled;
    }
    _keepVisible();
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.keyK || key == LogicalKeyboardKey.mediaPlayPause) {
      unawaited(controller.playPause());
    } else if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyL) {
      unawaited(controller.seekBy(key == LogicalKeyboardKey.arrowRight && !shift ? const Duration(seconds: 5) : widget.seekStep));
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyJ) {
      unawaited(controller.seekBy(key == LogicalKeyboardKey.arrowLeft && !shift ? const Duration(seconds: -5) : -widget.seekStep));
    } else if (key == LogicalKeyboardKey.arrowUp) {
      unawaited(controller.setVolume((controller.value.volume + 0.05).clamp(0, 1).toDouble()));
    } else if (key == LogicalKeyboardKey.arrowDown) {
      unawaited(controller.setVolume((controller.value.volume - 0.05).clamp(0, 1).toDouble()));
    } else if (key == LogicalKeyboardKey.keyF) {
      unawaited(_toggleFullscreen());
    } else if (key == LogicalKeyboardKey.keyM) {
      unawaited(controller.toggleMute());
    } else if (key == LogicalKeyboardKey.keyN && widget.notes != null) {
      unawaited(_addNote());
    } else if (key == LogicalKeyboardKey.keyP && !kIsWeb) {
      unawaited(controller.enterPip());
    } else if (key == LogicalKeyboardKey.escape && widget.isFullscreen) {
      Navigator.of(context).pop();
    } else if (key == LogicalKeyboardKey.bracketRight || (shift && key == LogicalKeyboardKey.period)) {
      unawaited(controller.setSpeed((controller.value.speed + 0.25).clamp(0.25, 4).toDouble()));
    } else if (key == LogicalKeyboardKey.bracketLeft || (shift && key == LogicalKeyboardKey.comma)) {
      unawaited(controller.setSpeed((controller.value.speed - 0.25).clamp(0.25, 4).toDouble()));
    } else if (key == LogicalKeyboardKey.period && !controller.value.isPlaying) {
      unawaited(controller.stepFrame());
    } else if (key == LogicalKeyboardKey.home) {
      unawaited(controller.seek(Duration.zero));
    } else if (key == LogicalKeyboardKey.end) {
      unawaited(controller.seek(controller.value.duration));
    } else {
      final int? digit = _digitOf(key);
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

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_hovering) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (PointerSignalEvent resolved) {
      final double delta = (resolved as PointerScrollEvent).scrollDelta.dy;
      final double volume = (widget.controller.value.volume + (delta < 0 ? 0.05 : -0.05)).clamp(0, 1).toDouble();
      unawaited(widget.controller.setVolume(volume));
      _keepVisible();
    });
  }

  void _openSettings() {
    _keepVisible();
    UNavigator.bottomSheet(UVideoSettingsSheet(controller: widget.controller, settings: _settings));
  }

  List<UVideoMarker> get _markers => <UVideoMarker>[...widget.markers, ...?widget.notes?.markers];

  @override
  Widget build(BuildContext context) {
    final UDocWatermark? watermark = widget.watermark;
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
          if (watermark != null) Positioned.fill(child: UMovingWatermark(watermark: watermark)),
          if (_settings.showStats) Positioned(top: 12, left: 12, child: UVideoStatsOverlay(controller: widget.controller)),
        ],
      ),
    );

    final Widget gestured = UVideoGestures(
      controller: widget.controller,
      config: widget.gestures,
      onToggleControls: _toggleControls,
      onMouseTap: () {
        unawaited(widget.controller.playPause());
        _keepVisible();
      },
      onMouseDoubleTap: widget.showFullscreenButton ? () => unawaited(_toggleFullscreen()) : null,
      onZoomChanged: (double zoom) => _settings.zoom = zoom,
      onBrightnessChanged: (double value) => _settings.screenBrightness = value,
      onDismiss: widget.onDismiss,
      enabled: !_locked,
      child: player,
    );

    final bool inPip = widget.controller.value.pip == UPipState.active && !kIsWeb;
    final Widget stacked = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        gestured,
        if (_drawingEnabled && !inPip) _drawOverlay(),
        if (widget.showNoteOverlays && widget.notes != null && !inPip && !_drawing) _noteOverlay(),
        if (_resumeOffer != null && !inPip) _resumeBanner(_resumeOffer!),
        if (_drawing && !inPip) _drawToolbar(),
        if (widget.showControls && !inPip && !_drawing)
          widget.controlsBuilder?.call(context, widget.controller, _controlsVisible) ??
              UVideoControls(
                controller: widget.controller,
                visible: _controlsVisible,
                title: widget.title,
                markers: _markers,
                accentColor: widget.accentColor,
                showBack: widget.isFullscreen,
                showFullscreen: widget.showFullscreenButton,
                showQueue: widget.showQueueButton,
                showSeekButtons: widget.showSeekButtons,
                showVolumeSlider: _desktop,
                showPip: !kIsWeb || widget.isFullscreen,
                seekStep: widget.seekStep,
                isFullscreen: widget.isFullscreen,
                locked: _locked,
                notesCount: widget.notes?.length ?? 0,
                topActions: widget.topActions,
                onBack: () => Navigator.of(context).pop(),
                onToggleFullscreen: () => unawaited(_toggleFullscreen()),
                onToggleLock: () => setState(() => _locked = !_locked),
                onOpenSettings: _openSettings,
                onOpenQueue: () => UNavigator.bottomSheet(UMediaQueueSheet(controller: widget.controller)),
                onAddNote: widget.notes == null ? null : () => unawaited(_addNote()),
                onOpenNotes: widget.notes == null && widget.onOpenNotes == null ? null : _openNotes,
                onDraw: _drawingEnabled ? _toggleDrawing : null,
                onScrubStart: () => _hideTimer?.cancel(),
                onScrubEnd: _restartHideTimer,
                thumbnailBuilder: widget.thumbnailBuilder,
              ),
      ],
    );

    final Widget interactive = MouseRegion(
      cursor: _desktop && !_controlsVisible && widget.controller.value.isPlaying ? SystemMouseCursors.none : MouseCursor.defer,
      onEnter: (PointerEnterEvent event) => _hovering = true,
      onHover: (PointerHoverEvent event) {
        _hovering = true;
        if (_desktop) _keepVisible();
      },
      onExit: (PointerExitEvent event) {
        _hovering = false;
        _restartHideTimer();
      },
      child: Listener(
        onPointerDown: (PointerDownEvent event) => _focusNode.requestFocus(),
        onPointerSignal: _onPointerSignal,
        child: stacked,
      ),
    );

    final Widget focused = USecureArea(
      enabled: widget.secure,
      child: Focus(focusNode: _focusNode, autofocus: widget.isFullscreen || _desktop, onKeyEvent: _onKey, child: interactive),
    );

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

  Widget _noteOverlay() => ValueListenableBuilder<UMediaValue>(
    valueListenable: widget.controller,
    builder: (BuildContext context, UMediaValue value, Widget? child) {
      final List<UMediaNote> active = widget.notes!.activeAt(value.position).where((UMediaNote note) => note.text.trim().isNotEmpty).toList();
      return Positioned(
        top: 56,
        left: 12,
        right: 12,
        child: IgnorePointer(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: active.isEmpty
                ? const SizedBox.shrink()
                : Align(
                    key: ValueKey<String>(active.first.id),
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xCC000000),
                          borderRadius: BorderRadius.circular(10),
                          border: BorderDirectional(start: BorderSide(color: active.first.color, width: 4)),
                        ),
                        child: Text(
                          active.first.text,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          textDirection: UDocText.isRtl(active.first.text) ? TextDirection.rtl : TextDirection.ltr,
                          style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 13, height: 1.35, fontFamily: "Vazir", package: "u"),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      );
    },
  );

  Widget _resumeBanner(Duration position) => Positioned(
    left: 12,
    bottom: 72,
    child: Material(
      color: const Color(0xE6000000),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.history_rounded, color: Color(0xFFFFFFFF), size: 18),
            const SizedBox(width: 8),
            UTextBodySmall(U.s.resumeFrom(uFormatDuration(position)), color: const Color(0xFFFFFFFF)),
            TextButton(
              onPressed: () {
                unawaited(widget.controller.seek(Duration.zero));
                setState(() => _resumeOffer = null);
              },
              child: UTextBodySmall(U.s.startOver, color: widget.accentColor ?? Theme.of(context).colorScheme.inversePrimary, fontWeight: FontWeight.w700),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _resumeOffer = null),
              icon: const Icon(Icons.close_rounded, color: Color(0xB3FFFFFF), size: 18),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _errorBuilder(BuildContext context, UMediaError error) => Center(
    child: UColumn(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        const Icon(Icons.error_outline_rounded, color: Color(0xB3FFFFFF), size: 40),
        UTextBodySmall(error.message.isEmpty ? U.s.errorLoadingVideo : error.message, color: const Color(0xB3FFFFFF), textAlign: TextAlign.center),
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

/// Opens a controller full screen (landscape, hides system bars).
abstract final class UVideoFullscreen {
  /// Opens [controller] full screen. `UVideoFullscreen.open(context, controller: c)`
  static Future<void> open(
    BuildContext context, {
    required UMediaController controller,
    UVideoSettings? settings,
    String? title,
    List<UVideoMarker> markers = const <UVideoMarker>[],
    UMediaNotesController? notes,
    UVideoGestureConfig gestures = const UVideoGestureConfig(),
    Color? accentColor,
    Widget Function(BuildContext context, Duration position)? thumbnailBuilder,
    UDocWatermark? watermark,
    Duration seekStep = const Duration(seconds: 10),
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
            notes: notes,
            gestures: gestures,
            accentColor: accentColor,
            borderRadius: 0,
            isFullscreen: true,
            watermark: watermark,
            seekStep: seekStep,
            thumbnailBuilder: thumbnailBuilder,
            onDismiss: () => Navigator.of(context).pop(),
          ),
        ),
        transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondary, Widget child) => FadeTransition(opacity: animation, child: child),
      ),
    );

    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}

/// Small draggable floating player (keeps playing while browsing).
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

  /// Controller to read or change it from code.
  final UMediaController controller;

  /// Width in logical pixels (null = size to content).
  final double width;

  /// Space outside, around the widget.
  final double margin;

  /// Corner radius.
  final double borderRadius;

  /// Called when the mini player is tapped to expand.
  final VoidCallback? onExpand;

  /// Called when it closes.
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

/// Drop-in player from a URL/file/asset/base64 with every feature; all 6 platforms (Linux needs GStreamer). `UVideoPlayer(url: "https://x.com/v.m3u8", resumeKey: "movie-1")`
class UVideoPlayer extends StatefulWidget {
  const UVideoPlayer({
    super.key,
    this.url,
    this.base64,
    this.bytes,
    this.filePath,
    this.assetPath,
    this.headers = const <String, String>{},
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
    this.notes,
    this.notesData,
    this.notesStorageKey,
    this.onNotesChanged,
    this.markers = const <UVideoMarker>[],
    this.subtitles = const <UExternalSubtitle>[],
    this.watermark,
    this.secure = false,
    this.resumeKey,
    this.autoPip = false,
    this.seekStep = const Duration(seconds: 10),
    this.onControllerReady,
  }) : assert(
         url != null || base64 != null || bytes != null || filePath != null || assetPath != null,
         "Provide one video source",
       );

  /// Web address of the content.
  final String? url;

  /// Video as base64 text.
  final String? base64;

  /// Content as bytes in memory.
  final Uint8List? bytes;

  /// Local file path.
  final String? filePath;

  /// Flutter asset path.
  final String? assetPath;

  /// HTTP headers for the video URL (e.g. auth).
  final Map<String, String> headers;

  /// Starts playing as soon as it is ready.
  final bool autoPlay;

  /// Starts again at the end.
  final bool looping;

  /// Starts muted.
  final bool muted;

  /// Shows the torch/switch/gallery/zoom controls.
  final bool showControls;

  /// Shows the fullscreen button.
  final bool allowFullScreen;

  /// Shows the speed button.
  final bool allowPlaybackSpeed;

  /// Hides controls after a few seconds.
  final bool autoHideControls;

  /// Width / height ratio.
  final double? aspectRatio;

  /// How the content fits its box (BoxFit).
  final BoxFit fit;

  /// Highlight color (defaults to the theme's primary).
  final Color? accentColor;

  /// Background color.
  final Color backgroundColor;

  /// Corner radius.
  final double borderRadius;

  /// Shown while loading.
  final Widget? placeholder;

  /// Title text.
  final String? title;

  /// Which touch gestures are on (tap, double-tap seek, swipes, pinch…).
  final UVideoGestureConfig gestures;

  /// External notes controller; when null and [notesStorageKey]/[notesData]/[onNotesChanged] is given, one is created.
  final UMediaNotesController? notes;

  /// Saved notes JSON to show.
  final String? notesData;

  /// Saves notes automatically under this key.
  final String? notesStorageKey;

  /// Called with the notes JSON after each change.
  final void Function(String data)? onNotesChanged;

  /// Chapter/intro markers drawn on the seek bar (skippable ones show a "Skip" button).
  final List<UVideoMarker> markers;

  /// External subtitle files (SRT/VTT/ASS URLs or text).
  final List<UExternalSubtitle> subtitles;

  /// Watermark text painted over the content.
  final UDocWatermark? watermark;

  /// Blocks screenshots and screen recording while playing (see UScreenGuard).
  final bool secure;

  /// Saves and restores the position under this id ("continue watching").
  final String? resumeKey;

  /// Goes picture-in-picture when the user leaves the app (Android, iOS).
  final bool autoPip;

  /// How far the seek buttons / double tap jump.
  final Duration seekStep;

  /// Gives you the controller once it is created.
  final void Function(UMediaController controller)? onControllerReady;

  /// Converts a BoxFit to the player's fit mode.
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
  UMediaNotesController? _ownedNotes;

  UMediaNotesController? get _notes => widget.notes ?? _ownedNotes;

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
    if (widget.notes == null && (widget.notesStorageKey != null || widget.notesData != null || widget.onNotesChanged != null)) {
      _ownedNotes = UMediaNotesController(
        storageKey: widget.notesStorageKey,
        initialData: widget.notesData,
        onChanged: (UMediaNotesController notes) => widget.onNotesChanged?.call(notes.export()),
      );
      unawaited(_ownedNotes!.load());
    }
    unawaited(_controller.open(_source(), autoPlay: widget.autoPlay));
    widget.onControllerReady?.call(_controller);
  }

  @override
  void didUpdateWidget(covariant UVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.filePath != widget.filePath || oldWidget.assetPath != widget.assetPath || oldWidget.bytes != widget.bytes || oldWidget.base64 != widget.base64) {
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
    if (path != null) return UMediaSource.file(path, externalSubtitles: widget.subtitles);

    final String? asset = widget.assetPath;
    if (asset != null) return UMediaSource.asset(asset);

    return UMediaSource.network(widget.url ?? "", headers: widget.headers, externalSubtitles: widget.subtitles);
  }

  @override
  void dispose() {
    _controller.dispose();
    _settings.dispose();
    _ownedNotes?.dispose();
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
    markers: widget.markers,
    notes: _notes,
    watermark: widget.watermark,
    secure: widget.secure,
    resumeKey: widget.resumeKey,
    autoPip: widget.autoPip,
    seekStep: widget.seekStep,
  );
}

/// Video with a side panel of time-stamped notes and drawing.
class UVideoWithNotes extends StatelessWidget {
  const UVideoWithNotes({
    required this.controller,
    required this.notes,
    this.settings,
    this.title,
    this.markers = const <UVideoMarker>[],
    this.watermark,
    this.secure = false,
    this.resumeKey,
    this.autoPip = true,
    this.showNotes = true,
    this.enableDrawing = true,
    this.drawController,
    this.accentColor,
    this.panelWidth = 340,
    super.key,
  });

  /// Controller to read or change it from code.
  final UMediaController controller;

  /// Notes controller.
  final UMediaNotesController notes;

  /// Settings.
  final UVideoSettings? settings;

  /// Title text.
  final String? title;

  /// Chapter/intro markers drawn on the seek bar (skippable ones show a "Skip" button).
  final List<UVideoMarker> markers;

  /// Watermark text painted over the content.
  final UDocWatermark? watermark;

  /// Blocks screenshots and screen recording while playing (see UScreenGuard).
  final bool secure;

  /// Saves and restores the position under this id ("continue watching").
  final String? resumeKey;

  /// Goes picture-in-picture when the user leaves the app (Android, iOS).
  final bool autoPip;

  /// Shows the notes panel.
  final bool showNotes;

  /// Allows drawing on frames.
  final bool enableDrawing;

  /// Controller for drawing notes on the video.
  final UDocDrawController? drawController;

  /// Highlight color (defaults to the theme's primary).
  final Color? accentColor;

  /// Width of the notes panel.
  final double panelWidth;

  @override
  Widget build(BuildContext context) {
    final Widget video = UVideo(
      controller: controller,
      settings: settings,
      title: title,
      markers: markers,
      notes: notes,
      watermark: watermark,
      secure: secure,
      resumeKey: resumeKey,
      autoPip: autoPip,
      enableDrawing: enableDrawing,
      drawController: drawController,
      accentColor: accentColor,
      borderRadius: 0,
    );
    return UMediaPipSwitcher(
      controller: controller,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 860;
          final Widget panel = UMediaNotesPanel(notes: notes, controller: controller);
          if (!showNotes) return Center(child: video);
          if (wide) {
            return Row(
              children: <Widget>[
                Expanded(
                  child: ColoredBox(
                    color: const Color(0xFF000000),
                    child: Center(child: video),
                  ),
                ),
                SizedBox(
                  width: panelWidth,
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BorderDirectional(start: BorderSide(color: Theme.of(context).dividerColor)),
                    child: panel,
                  ),
                ),
              ],
            );
          }
          return Column(
            children: <Widget>[
              ColoredBox(color: const Color(0xFF000000), child: video),
              Expanded(
                child: Material(color: Theme.of(context).colorScheme.surface, child: panel),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Opens a player full-width inside a bottom sheet. Accepts the same sources as
/// [UVideoPlayer].

abstract final class UVideoSheet {
  /// Plays a video in a bottom sheet; give one of url/bytes/base64/filePath/assetPath. `UVideoSheet.show(url: url)`
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
      ),
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
