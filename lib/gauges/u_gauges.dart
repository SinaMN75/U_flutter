import "dart:math" as math;
import "dart:ui" as ui;

import "package:u/utilities.dart";

// =============================================================================
// u_gauges — pure-Dart, dependency-free gauge library for the `u` plugin.
// Radial, linear and specialised gauges rendered with CustomPainter and an
// animated needle/fill. Colors default to the active [ColorScheme].
// =============================================================================

/// A colored value band on any gauge (e.g. red/amber/green zones).
class UGaugeBand {
  const UGaugeBand({required this.start, required this.end, required this.color, this.label});

  final double start;
  final double end;
  final Color color;
  final String? label;
}

/// Shared, fully-optional styling for every gauge. Null fields resolve from the
/// active theme at build time.
class UGaugeStyle {
  const UGaugeStyle({
    this.trackColor,
    this.fillColor,
    this.needleColor,
    this.tickColor,
    this.labelColor,
    this.valueColor,
    this.thickness,
    this.showTicks = true,
    this.showLabels = true,
    this.showValue = true,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 1100),
    this.animationCurve = Curves.easeOutCubic,
  });

  final Color? trackColor;
  final Color? fillColor;
  final Color? needleColor;
  final Color? tickColor;
  final Color? labelColor;
  final Color? valueColor;
  final double? thickness;
  final bool showTicks;
  final bool showLabels;
  final bool showValue;
  final bool animate;
  final Duration animationDuration;
  final Curve animationCurve;
}

class _GaugeColors {
  const _GaugeColors({
    required this.track,
    required this.fill,
    required this.needle,
    required this.tick,
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  final Color track;
  final Color fill;
  final Color needle;
  final Color tick;
  final Color label;
  final Color value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
}

_GaugeColors _gaugeColors(BuildContext context, UGaugeStyle style) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final TextTheme text = Theme.of(context).textTheme;
  return _GaugeColors(
    track: style.trackColor ?? scheme.surfaceContainerHighest,
    fill: style.fillColor ?? scheme.primary,
    needle: style.needleColor ?? scheme.onSurface,
    tick: style.tickColor ?? scheme.outline,
    label: style.labelColor ?? scheme.onSurfaceVariant,
    value: style.valueColor ?? scheme.onSurface,
    labelStyle: TextStyle(color: style.labelColor ?? scheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500),
    valueStyle: (text.titleLarge ?? const TextStyle(fontSize: 22)).copyWith(color: style.valueColor ?? scheme.onSurface, fontWeight: FontWeight.w700),
  );
}

// ----------------------------------------------------------------------------
// Shared helpers (self-contained copies so the file stands alone)
// ----------------------------------------------------------------------------

TextPainter _measure(String text, TextStyle style, {double maxWidth = double.infinity}) {
  final TextPainter tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout(maxWidth: maxWidth);
  return tp;
}

void _paintText(Canvas canvas, String text, Offset at, TextStyle style, {Alignment anchor = Alignment.center, double maxWidth = double.infinity}) {
  final TextPainter tp = _measure(text, style, maxWidth: maxWidth);
  tp.paint(canvas, Offset(at.dx - tp.width * (anchor.x + 1) / 2, at.dy - tp.height * (anchor.y + 1) / 2));
}

String _fmtValue(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1);
}

/// Rebuilds [builder] with an animated 0..1 progress on mount.
class _GaugeAnimator extends StatefulWidget {
  const _GaugeAnimator({required this.builder, required this.duration, required this.curve, this.animate = true});

  final Widget Function(double t) builder;
  final Duration duration;
  final Curve curve;
  final bool animate;

  @override
  State<_GaugeAnimator> createState() => _GaugeAnimatorState();
}

class _GaugeAnimatorState extends State<_GaugeAnimator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _animation = CurvedAnimation(parent: _controller, curve: widget.curve);

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    builder: (BuildContext context, Widget? child) => widget.builder(_animation.value),
  );
}

double _norm(double value, double min, double max) => max == min ? 0 : ((value - min) / (max - min)).clamp(0, 1).toDouble();

// ----------------------------------------------------------------------------
// Radial family — radial, speedometer, semicircle, arc
// ----------------------------------------------------------------------------

void _drawArcTicks(
  Canvas canvas,
  Offset center,
  double radius,
  double start,
  double sweep,
  double min,
  double max,
  int majors,
  int minorsPer,
  _GaugeColors c, {
  required bool showLabels,
  required double tickLen,
}) {
  final int totalMinor = majors * minorsPer;
  for (int i = 0; i <= totalMinor; i++) {
    final double frac = i / totalMinor;
    final double a = start + sweep * frac;
    final bool major = i % minorsPer == 0;
    final double len = major ? tickLen : tickLen * 0.5;
    final Offset dir = Offset(math.cos(a), math.sin(a));
    canvas.drawLine(
      center + dir * (radius - len),
      center + dir * radius,
      Paint()
        ..color = c.tick
        ..strokeWidth = major ? 2 : 1,
    );
    if (major && showLabels) {
      _paintText(canvas, _fmtValue(min + (max - min) * frac), center + dir * (radius - len - 11), c.labelStyle);
    }
  }
}

void _drawNeedle(Canvas canvas, Offset center, double radius, double angle, Color color) {
  final Offset dir = Offset(math.cos(angle), math.sin(angle));
  final Offset perp = Offset(math.cos(angle + math.pi / 2), math.sin(angle + math.pi / 2));
  final Path path = Path()
    ..moveTo((center + perp * 5).dx, (center + perp * 5).dy)
    ..lineTo((center + dir * radius).dx, (center + dir * radius).dy)
    ..lineTo((center - perp * 5).dx, (center - perp * 5).dy)
    ..lineTo((center - dir * radius * 0.16).dx, (center - dir * radius * 0.16).dy)
    ..close();
  canvas.drawPath(path, Paint()..color = color);
  canvas.drawCircle(center, 8, Paint()..color = color);
  canvas.drawCircle(center, 3.5, Paint()..color = Colors.white);
}

class _RadialPainter extends CustomPainter {
  _RadialPainter({
    required this.min,
    required this.max,
    required this.value,
    required this.bands,
    required this.c,
    required this.startAngle,
    required this.sweepAngle,
    required this.thickness,
    required this.majors,
    required this.needle,
    required this.fillProgress,
    required this.showTicks,
    required this.showLabels,
    required this.showValue,
    required this.valueLabel,
    required this.anchorBottom,
  });

  final double min;
  final double max;
  final double value;
  final List<UGaugeBand> bands;
  final _GaugeColors c;
  final double startAngle;
  final double sweepAngle;
  final double thickness;
  final int majors;
  final bool needle;
  final bool fillProgress;
  final bool showTicks;
  final bool showLabels;
  final bool showValue;
  final String? valueLabel;
  final bool anchorBottom;

  double _angle(double v) => startAngle + sweepAngle * _norm(v, min, max);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = anchorBottom ? Offset(size.width / 2, size.height - thickness) : Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width / 2, anchorBottom ? size.height - thickness : size.height / 2) - thickness / 2 - (showLabels ? 14 : 2);
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      arcRect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..color = c.track,
    );

    if (bands.isEmpty && fillProgress) {
      canvas.drawArc(
        arcRect,
        startAngle,
        sweepAngle * _norm(value, min, max),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.sweep(center, <Color>[c.fill.withValues(alpha: 0.65), c.fill], <double>[0, 1], TileMode.clamp, startAngle, startAngle + sweepAngle),
      );
    }
    for (final UGaugeBand band in bands) {
      canvas.drawArc(
        arcRect,
        _angle(band.start),
        sweepAngle * (_norm(band.end, min, max) - _norm(band.start, min, max)),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..color = band.color,
      );
    }

    if (showTicks) {
      _drawArcTicks(canvas, center, radius - thickness / 2 - 4, startAngle, sweepAngle, min, max, majors, 5, c, showLabels: showLabels, tickLen: 8);
    }

    if (needle) _drawNeedle(canvas, center, radius - thickness / 2, _angle(value), c.needle);

    if (showValue) {
      final Offset at = anchorBottom ? Offset(center.dx, center.dy - radius * 0.34) : center;
      _paintText(canvas, valueLabel ?? _fmtValue(value), at, c.valueStyle);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialPainter old) => old.value != value || old.bands != bands;
}

Widget _radialFrame({
  required BuildContext context,
  required double size,
  required double aspect,
  required UGaugeStyle style,
  required double min,
  required double max,
  required double value,
  required List<UGaugeBand> bands,
  required double startAngle,
  required double sweepAngle,
  required int majors,
  required bool needle,
  required bool fillProgress,
  required bool anchorBottom,
  required String? valueLabel,
}) {
  final _GaugeColors c = _gaugeColors(context, style);
  final double thickness = style.thickness ?? size * 0.09;
  return SizedBox(
    width: size,
    height: size * aspect,
    child: _GaugeAnimator(
      animate: style.animate,
      duration: style.animationDuration,
      curve: style.animationCurve,
      builder: (double t) => CustomPaint(
        size: Size.infinite,
        painter: _RadialPainter(
          min: min,
          max: max,
          value: min + (value.clamp(min, max) - min) * t,
          bands: bands,
          c: c,
          startAngle: startAngle,
          sweepAngle: sweepAngle,
          thickness: thickness,
          majors: majors,
          needle: needle,
          fillProgress: fillProgress,
          showTicks: style.showTicks,
          showLabels: style.showLabels,
          showValue: style.showValue,
          valueLabel: valueLabel,
          anchorBottom: anchorBottom,
        ),
      ),
    ),
  );
}

/// A classic 270° radial gauge with needle, ticks, labels and optional colored
/// [bands].
class URadialGauge extends StatelessWidget {
  const URadialGauge({
    required this.value,
    super.key,
    this.min = 0,
    this.max = 100,
    this.bands = const <UGaugeBand>[],
    this.size = 220,
    this.majorTicks = 6,
    this.valueLabel,
    this.style = const UGaugeStyle(),
  });

  final double value;
  final double min;
  final double max;
  final List<UGaugeBand> bands;
  final double size;
  final int majorTicks;
  final String? valueLabel;
  final UGaugeStyle style;

  @override
  Widget build(BuildContext context) => _radialFrame(
    context: context,
    size: size,
    aspect: 1,
    style: style,
    min: min,
    max: max,
    value: value,
    bands: bands,
    startAngle: math.pi * 0.75,
    sweepAngle: math.pi * 1.5,
    majors: majorTicks,
    needle: true,
    fillProgress: false,
    anchorBottom: false,
    valueLabel: valueLabel,
  );
}

/// A 240° speedometer with colored zones and a needle.
class USpeedometerGauge extends StatelessWidget {
  const USpeedometerGauge({
    required this.value,
    super.key,
    this.min = 0,
    this.max = 100,
    this.bands = const <UGaugeBand>[],
    this.size = 220,
    this.majorTicks = 6,
    this.valueLabel,
    this.style = const UGaugeStyle(),
  });

  final double value;
  final double min;
  final double max;
  final List<UGaugeBand> bands;
  final double size;
  final int majorTicks;
  final String? valueLabel;
  final UGaugeStyle style;

  @override
  Widget build(BuildContext context) => _radialFrame(
    context: context,
    size: size,
    aspect: 0.86,
    style: style,
    min: min,
    max: max,
    value: value,
    bands: bands,
    startAngle: math.pi * (5 / 6),
    sweepAngle: math.pi * (4 / 3),
    majors: majorTicks,
    needle: true,
    fillProgress: bands.isEmpty,
    anchorBottom: false,
    valueLabel: valueLabel,
  );
}

/// A 180° semicircular gauge that sits on its flat edge.
class USemiCircleGauge extends StatelessWidget {
  const USemiCircleGauge({
    required this.value,
    super.key,
    this.min = 0,
    this.max = 100,
    this.bands = const <UGaugeBand>[],
    this.size = 240,
    this.majorTicks = 5,
    this.needle = true,
    this.valueLabel,
    this.style = const UGaugeStyle(),
  });

  final double value;
  final double min;
  final double max;
  final List<UGaugeBand> bands;
  final double size;
  final int majorTicks;
  final bool needle;
  final String? valueLabel;
  final UGaugeStyle style;

  @override
  Widget build(BuildContext context) => _radialFrame(
    context: context,
    size: size,
    aspect: 0.62,
    style: style,
    min: min,
    max: max,
    value: value,
    bands: bands,
    startAngle: math.pi,
    sweepAngle: math.pi,
    majors: majorTicks,
    needle: needle,
    fillProgress: bands.isEmpty,
    anchorBottom: true,
    valueLabel: valueLabel,
  );
}

/// A modern gradient progress arc (no needle) with a large centered value.
class UArcGauge extends StatelessWidget {
  const UArcGauge({
    required this.value,
    super.key,
    this.min = 0,
    this.max = 100,
    this.bands = const <UGaugeBand>[],
    this.size = 200,
    this.valueLabel,
    this.style = const UGaugeStyle(showTicks: false, showLabels: false),
  });

  final double value;
  final double min;
  final double max;
  final List<UGaugeBand> bands;
  final double size;
  final String? valueLabel;
  final UGaugeStyle style;

  @override
  Widget build(BuildContext context) => _radialFrame(
    context: context,
    size: size,
    aspect: 0.72,
    style: style,
    min: min,
    max: max,
    value: value,
    bands: bands,
    startAngle: math.pi * (5 / 6),
    sweepAngle: math.pi * (4 / 3),
    majors: 5,
    needle: false,
    fillProgress: true,
    anchorBottom: false,
    valueLabel: valueLabel,
  );
}

// ----------------------------------------------------------------------------
// Progress ring (full circle)
// ----------------------------------------------------------------------------

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.value,
    required this.c,
    required this.thickness,
    required this.valueLabel,
    required this.label,
    required this.showValue,
  });

  final double progress;
  final double value;
  final _GaugeColors c;
  final double thickness;
  final String? valueLabel;
  final String? label;
  final bool showValue;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 - thickness / 2 - 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..color = c.track,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.sweep(center, <Color>[c.fill.withValues(alpha: 0.55), c.fill], <double>[0, 1], TileMode.clamp, -math.pi / 2, -math.pi / 2 + 2 * math.pi),
    );
    if (showValue) {
      _paintText(canvas, valueLabel ?? "${value.toStringAsFixed(0)}%", center + Offset(0, label != null ? -8 : 0), c.valueStyle);
      if (label != null) _paintText(canvas, label!, center + const Offset(0, 14), c.labelStyle);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

/// A circular progress ring with a centered value, ideal for KPIs and loaders.
class UProgressRingGauge extends StatelessWidget {
  const UProgressRingGauge({
    required this.value,
    super.key,
    this.min = 0,
    this.max = 100,
    this.size = 160,
    this.label,
    this.valueLabel,
    this.style = const UGaugeStyle(),
  });

  final double value;
  final double min;
  final double max;
  final double size;
  final String? label;
  final String? valueLabel;
  final UGaugeStyle style;

  @override
  Widget build(BuildContext context) {
    final _GaugeColors c = _gaugeColors(context, style);
    final double thickness = style.thickness ?? size * 0.11;
    final double target = _norm(value, min, max);
    return SizedBox(
      width: size,
      height: size,
      child: _GaugeAnimator(
        animate: style.animate,
        duration: style.animationDuration,
        curve: style.animationCurve,
        builder: (double t) => CustomPaint(
          size: Size.infinite,
          painter: _RingPainter(progress: target * t, value: min + (value.clamp(min, max) - min) * t, c: c, thickness: thickness, valueLabel: valueLabel, label: label, showValue: style.showValue),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Linear gauges (horizontal + vertical)
// ----------------------------------------------------------------------------

class _LinearPainter extends CustomPainter {
  _LinearPainter({
    required this.min,
    required this.max,
    required this.value,
    required this.bands,
    required this.c,
    required this.thickness,
    required this.vertical,
    required this.majors,
    required this.showTicks,
    required this.showLabels,
    required this.showValue,
    required this.valueLabel,
  });

  final double min;
  final double max;
  final double value;
  final List<UGaugeBand> bands;
  final _GaugeColors c;
  final double thickness;
  final bool vertical;
  final int majors;
  final bool showTicks;
  final bool showLabels;
  final bool showValue;
  final String? valueLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final double labelSpace = showLabels ? 26 : 6;
    final double valueSpace = showValue ? 22 : 6;
    if (vertical) {
      final double cx = size.width - labelSpace - thickness / 2 - 4;
      final double top = valueSpace;
      final double bottom = size.height - 6;
      final Rect track = Rect.fromLTWH(cx - thickness / 2, top, thickness, bottom - top);
      final RRect rr = RRect.fromRectAndRadius(track, Radius.circular(thickness / 2));
      canvas.drawRRect(rr, Paint()..color = c.track);
      double posOf(double v) => bottom - _norm(v, min, max) * (bottom - top);
      for (final UGaugeBand band in bands) {
        canvas.drawRect(Rect.fromLTRB(track.left, posOf(band.end), track.right, posOf(band.start)), Paint()..color = band.color);
      }
      if (bands.isEmpty) {
        canvas.save();
        canvas.clipRRect(rr);
        canvas.drawRect(
          Rect.fromLTRB(track.left, posOf(value), track.right, bottom),
          Paint()..shader = ui.Gradient.linear(track.bottomCenter, track.topCenter, <Color>[c.fill.withValues(alpha: 0.7), c.fill]),
        );
        canvas.restore();
      }
      if (showTicks) {
        for (int i = 0; i <= majors; i++) {
          final double v = min + (max - min) * i / majors;
          final double y = posOf(v);
          canvas.drawLine(Offset(track.left - 4, y), Offset(track.left, y), Paint()..color = c.tick);
          if (showLabels) _paintText(canvas, _fmtValue(v), Offset(track.right + 6, y), c.labelStyle, anchor: Alignment.centerLeft);
        }
      }
      if (showValue) _paintText(canvas, valueLabel ?? _fmtValue(value), Offset(cx, 2), c.valueStyle.copyWith(fontSize: 14), anchor: Alignment.topCenter);
      return;
    }

    final double cy = size.height - labelSpace - thickness / 2 - 2;
    const double left = 6;
    final double right = size.width - 6;
    final Rect track = Rect.fromLTWH(left, cy - thickness / 2, right - left, thickness);
    final RRect rr = RRect.fromRectAndRadius(track, Radius.circular(thickness / 2));
    canvas.drawRRect(rr, Paint()..color = c.track);
    double posOf(double v) => left + _norm(v, min, max) * (right - left);
    for (final UGaugeBand band in bands) {
      canvas.drawRect(Rect.fromLTRB(posOf(band.start), track.top, posOf(band.end), track.bottom), Paint()..color = band.color);
    }
    if (bands.isEmpty) {
      canvas.save();
      canvas.clipRRect(rr);
      canvas.drawRect(
        Rect.fromLTRB(left, track.top, posOf(value), track.bottom),
        Paint()..shader = ui.Gradient.linear(track.centerLeft, track.centerRight, <Color>[c.fill.withValues(alpha: 0.7), c.fill]),
      );
      canvas.restore();
    }
    final double px = posOf(value);
    final Path pointer = Path()
      ..moveTo(px, track.top - 3)
      ..lineTo(px - 6, track.top - 12)
      ..lineTo(px + 6, track.top - 12)
      ..close();
    canvas.drawPath(pointer, Paint()..color = c.needle);
    if (showTicks) {
      for (int i = 0; i <= majors; i++) {
        final double v = min + (max - min) * i / majors;
        final double x = posOf(v);
        canvas.drawLine(Offset(x, track.bottom + 2), Offset(x, track.bottom + 6), Paint()..color = c.tick);
        if (showLabels) _paintText(canvas, _fmtValue(v), Offset(x, track.bottom + 9), c.labelStyle, anchor: Alignment.topCenter);
      }
    }
    if (showValue) _paintText(canvas, valueLabel ?? _fmtValue(value), Offset(px, track.top - 14), c.valueStyle.copyWith(fontSize: 13), anchor: Alignment.bottomCenter);
  }

  @override
  bool shouldRepaint(covariant _LinearPainter old) => old.value != value || old.bands != bands;
}

/// A horizontal linear gauge with a pointer, ticks and optional [bands].
class ULinearGauge extends StatelessWidget {
  const ULinearGauge({
    required this.value,
    super.key,
    this.min = 0,
    this.max = 100,
    this.bands = const <UGaugeBand>[],
    this.width = 300,
    this.height = 70,
    this.majorTicks = 5,
    this.valueLabel,
    this.style = const UGaugeStyle(),
  });

  final double value;
  final double min;
  final double max;
  final List<UGaugeBand> bands;
  final double width;
  final double height;
  final int majorTicks;
  final String? valueLabel;
  final UGaugeStyle style;

  @override
  Widget build(BuildContext context) => _linearFrame(context, style, width, height, min, max, value, bands, majorTicks, valueLabel, vertical: false);
}

/// A vertical linear gauge (column style).
class UVerticalLinearGauge extends StatelessWidget {
  const UVerticalLinearGauge({
    required this.value,
    super.key,
    this.min = 0,
    this.max = 100,
    this.bands = const <UGaugeBand>[],
    this.width = 90,
    this.height = 240,
    this.majorTicks = 5,
    this.valueLabel,
    this.style = const UGaugeStyle(),
  });

  final double value;
  final double min;
  final double max;
  final List<UGaugeBand> bands;
  final double width;
  final double height;
  final int majorTicks;
  final String? valueLabel;
  final UGaugeStyle style;

  @override
  Widget build(BuildContext context) => _linearFrame(context, style, width, height, min, max, value, bands, majorTicks, valueLabel, vertical: true);
}

Widget _linearFrame(
  BuildContext context,
  UGaugeStyle style,
  double width,
  double height,
  double min,
  double max,
  double value,
  List<UGaugeBand> bands,
  int majors,
  String? valueLabel, {
  required bool vertical,
}) {
  final _GaugeColors c = _gaugeColors(context, style);
  final double thickness = style.thickness ?? (vertical ? width * 0.28 : height * 0.32);
  return SizedBox(
    width: width,
    height: height,
    child: _GaugeAnimator(
      animate: style.animate,
      duration: style.animationDuration,
      curve: style.animationCurve,
      builder: (double t) => CustomPaint(
        size: Size.infinite,
        painter: _LinearPainter(
          min: min,
          max: max,
          value: min + (value.clamp(min, max) - min) * t,
          bands: bands,
          c: c,
          thickness: thickness,
          vertical: vertical,
          majors: majors,
          showTicks: style.showTicks,
          showLabels: style.showLabels,
          showValue: style.showValue,
          valueLabel: valueLabel,
        ),
      ),
    ),
  );
}

// ----------------------------------------------------------------------------
// Battery / tank
// ----------------------------------------------------------------------------

class _BatteryPainter extends CustomPainter {
  _BatteryPainter({required this.level, required this.c, required this.fill, required this.showValue, required this.valueLabel});

  final double level;
  final _GaugeColors c;
  final Color fill;
  final bool showValue;
  final String? valueLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final double capW = size.width * 0.05;
    final Rect body = Rect.fromLTWH(2, size.height * 0.12, size.width - capW - 6, size.height * 0.76);
    final RRect bodyR = RRect.fromRectAndRadius(body, const Radius.circular(8));
    canvas.drawRRect(bodyR, Paint()..color = c.track);
    final Rect cap = Rect.fromLTWH(body.right + 2, size.height * 0.34, capW, size.height * 0.32);
    canvas.drawRRect(RRect.fromRectAndRadius(cap, const Radius.circular(3)), Paint()..color = c.track);
    final Rect inner = body.deflate(4);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(inner, const Radius.circular(5)));
    canvas.drawRect(
      Rect.fromLTWH(inner.left, inner.top, inner.width * level.clamp(0, 1), inner.height),
      Paint()..shader = ui.Gradient.linear(inner.centerLeft, inner.centerRight, <Color>[fill.withValues(alpha: 0.75), fill]),
    );
    canvas.restore();
    if (showValue) _paintText(canvas, valueLabel ?? "${(level * 100).toStringAsFixed(0)}%", body.center, c.valueStyle.copyWith(color: level > 0.5 ? Colors.white : c.value));
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter old) => old.level != level;
}

/// A battery / tank fill gauge. Turns [lowColor] below [lowThreshold].
class UBatteryGauge extends StatelessWidget {
  const UBatteryGauge({
    required this.value,
    super.key,
    this.min = 0,
    this.max = 100,
    this.width = 200,
    this.height = 90,
    this.lowThreshold = 0.2,
    this.lowColor,
    this.valueLabel,
    this.style = const UGaugeStyle(),
  });

  final double value;
  final double min;
  final double max;
  final double width;
  final double height;
  final double lowThreshold;
  final Color? lowColor;
  final String? valueLabel;
  final UGaugeStyle style;

  @override
  Widget build(BuildContext context) {
    final _GaugeColors c = _gaugeColors(context, style);
    final double target = _norm(value, min, max);
    final Color low = lowColor ?? Theme.of(context).colorScheme.error;
    final Color fill = target <= lowThreshold ? low : (style.fillColor ?? const Color(0xFF22C55E));
    return SizedBox(
      width: width,
      height: height,
      child: _GaugeAnimator(
        animate: style.animate,
        duration: style.animationDuration,
        curve: style.animationCurve,
        builder: (double t) => CustomPaint(
          size: Size.infinite,
          painter: _BatteryPainter(level: target * t, c: c, fill: fill, showValue: style.showValue, valueLabel: valueLabel),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Thermometer
// ----------------------------------------------------------------------------

class _ThermometerPainter extends CustomPainter {
  _ThermometerPainter({
    required this.min,
    required this.max,
    required this.value,
    required this.c,
    required this.fill,
    required this.majors,
    required this.showLabels,
    required this.showValue,
    required this.valueLabel,
  });

  final double min;
  final double max;
  final double value;
  final _GaugeColors c;
  final Color fill;
  final int majors;
  final bool showLabels;
  final bool showValue;
  final String? valueLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final double bulbR = size.width * 0.2;
    final double cx = bulbR + 4;
    final double tubeW = bulbR * 0.9;
    final double top = 8 + (showValue ? 14 : 0);
    final double bulbCy = size.height - bulbR - 4;
    final double tubeTop = top;
    final double tubeBottom = bulbCy;
    final RRect tube = RRect.fromRectAndRadius(Rect.fromLTWH(cx - tubeW / 2, tubeTop, tubeW, tubeBottom - tubeTop + tubeW), Radius.circular(tubeW / 2));
    canvas.drawRRect(tube, Paint()..color = c.track);
    canvas.drawCircle(Offset(cx, bulbCy), bulbR, Paint()..color = c.track);

    final double norm = _norm(value, min, max);
    final double fillTop = tubeBottom - norm * (tubeBottom - tubeTop);
    canvas.save();
    canvas.clipRRect(tube);
    canvas.drawRect(Rect.fromLTRB(cx - tubeW / 2, fillTop, cx + tubeW / 2, tubeBottom + tubeW), Paint()..color = fill);
    canvas.restore();
    canvas.drawCircle(Offset(cx, bulbCy), bulbR - 2, Paint()..color = fill);

    if (showLabels) {
      for (int i = 0; i <= majors; i++) {
        final double v = min + (max - min) * i / majors;
        final double y = tubeBottom - i / majors * (tubeBottom - tubeTop);
        canvas.drawLine(Offset(cx + tubeW / 2 + 2, y), Offset(cx + tubeW / 2 + 7, y), Paint()..color = c.tick);
        _paintText(canvas, _fmtValue(v), Offset(cx + tubeW / 2 + 10, y), c.labelStyle, anchor: Alignment.centerLeft);
      }
    }
    if (showValue) _paintText(canvas, valueLabel ?? _fmtValue(value), Offset(cx, 0), c.valueStyle.copyWith(fontSize: 14), anchor: Alignment.topCenter);
  }

  @override
  bool shouldRepaint(covariant _ThermometerPainter old) => old.value != value;
}

/// A thermometer gauge with a bulb, rising column and side scale.
class UThermometerGauge extends StatelessWidget {
  const UThermometerGauge({
    required this.value,
    super.key,
    this.min = 0,
    this.max = 100,
    this.width = 110,
    this.height = 260,
    this.majorTicks = 5,
    this.fillColor,
    this.valueLabel,
    this.style = const UGaugeStyle(),
  });

  final double value;
  final double min;
  final double max;
  final double width;
  final double height;
  final int majorTicks;
  final Color? fillColor;
  final String? valueLabel;
  final UGaugeStyle style;

  @override
  Widget build(BuildContext context) {
    final _GaugeColors c = _gaugeColors(context, style);
    final Color fill = fillColor ?? Theme.of(context).colorScheme.error;
    return SizedBox(
      width: width,
      height: height,
      child: _GaugeAnimator(
        animate: style.animate,
        duration: style.animationDuration,
        curve: style.animationCurve,
        builder: (double t) => CustomPaint(
          size: Size.infinite,
          painter: _ThermometerPainter(
            min: min,
            max: max,
            value: min + (value.clamp(min, max) - min) * t,
            c: c,
            fill: fill,
            majors: majorTicks,
            showLabels: style.showLabels,
            showValue: style.showValue,
            valueLabel: valueLabel,
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Compass
// ----------------------------------------------------------------------------

class _CompassPainter extends CustomPainter {
  _CompassPainter({required this.heading, required this.c, required this.northColor, required this.showValue});

  final double heading;
  final _GaugeColors c;
  final Color northColor;
  final bool showValue;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 - 14;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = c.tick,
    );
    for (int deg = 0; deg < 360; deg += 15) {
      final double a = deg * math.pi / 180 - math.pi / 2;
      final bool major = deg % 90 == 0;
      final Offset dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * (radius - (major ? 10 : 5)),
        center + dir * radius,
        Paint()
          ..color = c.tick
          ..strokeWidth = major ? 2 : 1,
      );
    }
    const List<String> cards = <String>["N", "E", "S", "W"];
    for (int i = 0; i < 4; i++) {
      final double a = i * math.pi / 2 - math.pi / 2;
      final Offset dir = Offset(math.cos(a), math.sin(a));
      _paintText(canvas, cards[i], center + dir * (radius - 22), c.labelStyle.copyWith(fontWeight: FontWeight.w700, color: i == 0 ? northColor : c.label));
    }
    final double a = heading * math.pi / 180 - math.pi / 2;
    final Offset dir = Offset(math.cos(a), math.sin(a));
    final Offset perp = Offset(math.cos(a + math.pi / 2), math.sin(a + math.pi / 2));
    final Path north = Path()
      ..moveTo((center + dir * (radius - 26)).dx, (center + dir * (radius - 26)).dy)
      ..lineTo((center + perp * 7).dx, (center + perp * 7).dy)
      ..lineTo((center - perp * 7).dx, (center - perp * 7).dy)
      ..close();
    canvas.drawPath(north, Paint()..color = northColor);
    final Path south = Path()
      ..moveTo((center - dir * (radius - 26)).dx, (center - dir * (radius - 26)).dy)
      ..lineTo((center + perp * 7).dx, (center + perp * 7).dy)
      ..lineTo((center - perp * 7).dx, (center - perp * 7).dy)
      ..close();
    canvas.drawPath(south, Paint()..color = c.needle.withValues(alpha: 0.65));
    canvas.drawCircle(center, 5, Paint()..color = c.needle);
    if (showValue) _paintText(canvas, "${heading.toStringAsFixed(0)}°", center + Offset(0, radius * 0.45), c.valueStyle.copyWith(fontSize: 16));
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) => old.heading != heading;
}

/// A compass gauge. [value] is a heading in degrees (0 = North, clockwise).
class UCompassGauge extends StatelessWidget {
  const UCompassGauge({
    required this.value,
    super.key,
    this.size = 200,
    this.northColor,
    this.style = const UGaugeStyle(),
  });

  final double value;
  final double size;
  final Color? northColor;
  final UGaugeStyle style;

  @override
  Widget build(BuildContext context) {
    final _GaugeColors c = _gaugeColors(context, style);
    final Color north = northColor ?? Theme.of(context).colorScheme.error;
    return SizedBox(
      width: size,
      height: size,
      child: _GaugeAnimator(
        animate: style.animate,
        duration: style.animationDuration,
        curve: style.animationCurve,
        builder: (double t) => CustomPaint(
          size: Size.infinite,
          painter: _CompassPainter(heading: value * t, c: c, northColor: north, showValue: style.showValue),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Segmented arc
// ----------------------------------------------------------------------------

class _SegmentedPainter extends CustomPainter {
  _SegmentedPainter({
    required this.progress,
    required this.segments,
    required this.c,
    required this.fill,
    required this.thickness,
    required this.value,
    required this.showValue,
    required this.valueLabel,
  });

  final double progress;
  final int segments;
  final _GaugeColors c;
  final Color fill;
  final double thickness;
  final double value;
  final bool showValue;
  final String? valueLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width / 2, size.height / 2) - thickness / 2 - 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    const double start = math.pi * 0.75;
    const double sweep = math.pi * 1.5;
    const double gap = 0.06;
    final double segSweep = (sweep - gap * (segments - 1)) / segments;
    final double litExact = progress * segments;
    for (int i = 0; i < segments; i++) {
      final double a = start + i * (segSweep + gap);
      final double fillAmount = (litExact - i).clamp(0, 1).toDouble();
      canvas.drawArc(
        rect,
        a,
        segSweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round
          ..color = c.track,
      );
      if (fillAmount > 0) {
        canvas.drawArc(
          rect,
          a,
          segSweep * fillAmount,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = thickness
            ..strokeCap = StrokeCap.round
            ..color = fill,
        );
      }
    }
    if (showValue) _paintText(canvas, valueLabel ?? _fmtValue(value), center, c.valueStyle);
  }

  @override
  bool shouldRepaint(covariant _SegmentedPainter old) => old.progress != progress;
}

/// A segmented arc gauge — discrete blocks light up to the value.
class USegmentedGauge extends StatelessWidget {
  const USegmentedGauge({
    required this.value,
    super.key,
    this.min = 0,
    this.max = 100,
    this.segments = 10,
    this.size = 200,
    this.fillColor,
    this.valueLabel,
    this.style = const UGaugeStyle(),
  });

  final double value;
  final double min;
  final double max;
  final int segments;
  final double size;
  final Color? fillColor;
  final String? valueLabel;
  final UGaugeStyle style;

  @override
  Widget build(BuildContext context) {
    final _GaugeColors c = _gaugeColors(context, style);
    final Color fill = fillColor ?? c.fill;
    final double thickness = style.thickness ?? size * 0.1;
    final double target = _norm(value, min, max);
    return SizedBox(
      width: size,
      height: size * 0.9,
      child: _GaugeAnimator(
        animate: style.animate,
        duration: style.animationDuration,
        curve: style.animationCurve,
        builder: (double t) => CustomPaint(
          size: Size.infinite,
          painter: _SegmentedPainter(
            progress: target * t,
            segments: segments,
            c: c,
            fill: fill,
            thickness: thickness,
            value: min + (value.clamp(min, max) - min) * t,
            showValue: style.showValue,
            valueLabel: valueLabel,
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Bullet (KPI) gauge
// ----------------------------------------------------------------------------

class _BulletPainter extends CustomPainter {
  _BulletPainter({required this.min, required this.max, required this.value, required this.target, required this.bands, required this.c, required this.measureColor, required this.showLabels});

  final double min;
  final double max;
  final double value;
  final double? target;
  final List<UGaugeBand> bands;
  final _GaugeColors c;
  final Color measureColor;
  final bool showLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final double labelH = showLabels ? 16 : 2;
    final Rect track = Rect.fromLTWH(2, 2, size.width - 4, size.height - labelH - 4);
    double posOf(double v) => track.left + _norm(v, min, max) * track.width;
    if (bands.isEmpty) {
      canvas.drawRRect(RRect.fromRectAndRadius(track, const Radius.circular(4)), Paint()..color = c.track);
    } else {
      for (final UGaugeBand band in bands) {
        canvas.drawRect(Rect.fromLTRB(posOf(band.start), track.top, posOf(band.end), track.bottom), Paint()..color = band.color);
      }
    }
    final Rect measure = Rect.fromLTRB(track.left, track.center.dy - track.height * 0.18, posOf(value), track.center.dy + track.height * 0.18);
    canvas.drawRRect(RRect.fromRectAndRadius(measure, const Radius.circular(3)), Paint()..color = measureColor);
    if (target != null) {
      final double tx = posOf(target!);
      canvas.drawRect(Rect.fromLTWH(tx - 1.5, track.top + 2, 3, track.height - 4), Paint()..color = c.needle);
    }
    if (showLabels) {
      _paintText(canvas, _fmtValue(min), Offset(track.left, size.height - 2), c.labelStyle, anchor: Alignment.bottomLeft);
      _paintText(canvas, _fmtValue(max), Offset(track.right, size.height - 2), c.labelStyle, anchor: Alignment.bottomRight);
    }
  }

  @override
  bool shouldRepaint(covariant _BulletPainter old) => old.value != value || old.target != target;
}

/// A bullet graph — a compact KPI gauge with qualitative [bands], a measure bar
/// and an optional [target] marker.
class UBulletGauge extends StatelessWidget {
  const UBulletGauge({
    required this.value,
    super.key,
    this.min = 0,
    this.max = 100,
    this.target,
    this.bands = const <UGaugeBand>[],
    this.width = 300,
    this.height = 48,
    this.measureColor,
    this.style = const UGaugeStyle(),
  });

  final double value;
  final double min;
  final double max;
  final double? target;
  final List<UGaugeBand> bands;
  final double width;
  final double height;
  final Color? measureColor;
  final UGaugeStyle style;

  @override
  Widget build(BuildContext context) {
    final _GaugeColors c = _gaugeColors(context, style);
    final Color measure = measureColor ?? Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: width,
      height: height,
      child: _GaugeAnimator(
        animate: style.animate,
        duration: style.animationDuration,
        curve: style.animationCurve,
        builder: (double t) => CustomPaint(
          size: Size.infinite,
          painter: _BulletPainter(min: min, max: max, value: min + (value.clamp(min, max) - min) * t, target: target, bands: bands, c: c, measureColor: measure, showLabels: style.showLabels),
        ),
      ),
    );
  }
}

// __GAUGES_END__
