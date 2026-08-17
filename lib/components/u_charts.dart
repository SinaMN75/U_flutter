import "dart:math" as math;
import "dart:ui" as ui;

import "package:u/utilities.dart";

// =============================================================================
// u_charts — pure-Dart, dependency-free chart library for the `u` plugin.
// Every chart is a CustomPainter driven by [UChartAnimator]; no native code and
// no third-party charting package. Colors default to the active [ColorScheme]
// so charts follow the app theme, and every visual is overridable.
// =============================================================================

// ----------------------------------------------------------------------------
// Data models
// ----------------------------------------------------------------------------

/// A named list of Y values sharing a single category (X) axis. Used by line,
/// area, bar, radar and histogram charts.
class UChartSeries {
  const UChartSeries({
    required this.values,
    this.name,
    this.color,
    this.gradient,
    this.pointColors,
    this.filled,
    this.dashed = false,
  });

  final List<double> values;
  final String? name;
  final Color? color;
  final List<Color>? gradient;

  /// Optional per-point colors (e.g. a distinctly colored bar per category).
  final List<Color>? pointColors;

  /// Per-series fill override for line charts; falls back to the widget's value.
  final bool? filled;
  final bool dashed;
}

/// A single free (x, y) sample with an optional bubble [size]. Used by scatter
/// and bubble charts.
class UChartPoint {
  const UChartPoint({required this.x, required this.y, this.size});

  final double x;
  final double y;
  final double? size;
}

/// A named collection of free points sharing color, for scatter/bubble charts.
class UPointSeries {
  const UPointSeries({required this.points, this.name, this.color});

  final List<UChartPoint> points;
  final String? name;
  final Color? color;
}

/// A single proportional slice for pie, donut, funnel and treemap charts.
class USlice {
  const USlice({required this.value, this.label, this.color});

  final double value;
  final String? label;
  final Color? color;
}

/// One open/high/low/close candle for financial charts.
class UCandle {
  const UCandle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.label,
  });

  final double open;
  final double high;
  final double low;
  final double close;
  final String? label;

  bool get bullish => close >= open;
}

/// One step of a waterfall chart. When [isTotal] is true the bar is drawn from
/// the baseline instead of stacking on the running total.
class UWaterfallItem {
  const UWaterfallItem({
    required this.value,
    this.label,
    this.isTotal = false,
    this.color,
  });

  final double value;
  final String? label;
  final bool isTotal;
  final Color? color;
}

// ----------------------------------------------------------------------------
// Styling
// ----------------------------------------------------------------------------

/// Shared, fully-optional styling for every chart. Any field left null is
/// resolved from the active [ColorScheme]/[TextTheme] at build time.
class UChartStyle {
  const UChartStyle({
    this.palette,
    this.backgroundColor,
    this.gridColor,
    this.axisColor,
    this.labelColor,
    this.labelFontSize = 11,
    this.showGrid = true,
    this.showAxis = true,
    this.showLabels = true,
    this.showLegend = true,
    this.showValues = false,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 900),
    this.animationCurve = Curves.easeOutCubic,
    this.padding = const EdgeInsets.all(12),
    this.gridDivisions = 5,
    this.cornerRadius = 6,
    this.valueFormatter,
  });

  final List<Color>? palette;
  final Color? backgroundColor;
  final Color? gridColor;
  final Color? axisColor;
  final Color? labelColor;
  final double labelFontSize;
  final bool showGrid;
  final bool showAxis;
  final bool showLabels;
  final bool showLegend;
  final bool showValues;
  final bool animate;
  final Duration animationDuration;
  final Curve animationCurve;
  final EdgeInsets padding;
  final int gridDivisions;
  final double cornerRadius;
  final String Function(double value)? valueFormatter;
}

/// Concrete, non-null styling resolved from a [UChartStyle] + the current theme.
class _Resolved {
  const _Resolved({
    required this.palette,
    required this.background,
    required this.grid,
    required this.axis,
    required this.labelStyle,
    required this.format,
  });

  final List<Color> palette;
  final Color background;
  final Color grid;
  final Color axis;
  final TextStyle labelStyle;
  final String Function(double value) format;

  Color colorAt(int index) => palette[index % palette.length];
}

_Resolved _resolve(BuildContext context, UChartStyle style, {int seriesCount = 8}) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final List<Color> palette = style.palette ?? _palette(scheme, math.max(seriesCount, 3));
  return _Resolved(
    palette: palette,
    background: style.backgroundColor ?? Colors.transparent,
    grid: style.gridColor ?? scheme.outlineVariant.withValues(alpha: 0.5),
    axis: style.axisColor ?? scheme.outline,
    labelStyle: TextStyle(
      color: style.labelColor ?? scheme.onSurfaceVariant,
      fontSize: style.labelFontSize,
      fontWeight: FontWeight.w500,
    ),
    format: style.valueFormatter ?? _formatAxis,
  );
}

/// Builds a visually-even categorical palette by rotating hue around the seed
/// [scheme.primary]. Keeps saturation/lightness constant so colors read as one
/// family and stay legible in light and dark themes.
List<Color> _palette(ColorScheme scheme, int count) {
  final HSLColor seed = HSLColor.fromColor(scheme.primary);
  final double baseHue = seed.hue;
  return List<Color>.generate(count, (int i) {
    final double hue = (baseHue + i * (360 / count)) % 360;
    final double lightness = scheme.brightness == Brightness.dark ? 0.62 : 0.5;
    return HSLColor.fromAHSL(1, hue, 0.6, lightness).toColor();
  });
}

String _formatAxis(double v) {
  final double a = v.abs();
  if (a >= 1000000000) return "${_trim(v / 1000000000)}B";
  if (a >= 1000000) return "${_trim(v / 1000000)}M";
  if (a >= 1000) return "${_trim(v / 1000)}K";
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return _trim(v);
}

String _trim(double v) {
  final String s = v.toStringAsFixed(1);
  return s.endsWith(".0") ? s.substring(0, s.length - 2) : s;
}

// ----------------------------------------------------------------------------
// Axis maths — "nice" rounded bounds and tick steps
// ----------------------------------------------------------------------------

class _Bounds {
  const _Bounds({required this.min, required this.max, required this.step});

  final double min;
  final double max;
  final double step;

  int get divisions => math.max(1, ((max - min) / step).round());
}

double _niceNum(double range, {required bool round}) {
  final double exponent = (math.log(range) / math.ln10).floorToDouble();
  final double fraction = range / math.pow(10, exponent);
  double nice;
  if (round) {
    if (fraction < 1.5) {
      nice = 1;
    } else if (fraction < 3) {
      nice = 2;
    } else if (fraction < 7) {
      nice = 5;
    } else {
      nice = 10;
    }
  } else {
    if (fraction <= 1) {
      nice = 1;
    } else if (fraction <= 2) {
      nice = 2;
    } else if (fraction <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
  }
  return nice * math.pow(10, exponent);
}

_Bounds _niceBounds(double dataMin, double dataMax, {int ticks = 5, bool includeZero = true}) {
  double lo = dataMin;
  double hi = dataMax;
  if (includeZero && lo > 0) lo = 0;
  if (includeZero && hi < 0) hi = 0;
  if (lo == hi) {
    lo -= 1;
    hi += 1;
  }
  final double range = _niceNum(hi - lo, round: false);
  final double step = _niceNum(range / (ticks - 1), round: true);
  final double niceMin = (lo / step).floorToDouble() * step;
  final double niceMax = (hi / step).ceilToDouble() * step;
  return _Bounds(min: niceMin, max: niceMax, step: step);
}

_Bounds _boundsForSeries(List<UChartSeries> series, {bool includeZero = true, int ticks = 5}) {
  double lo = double.infinity;
  double hi = double.negativeInfinity;
  for (final UChartSeries s in series) {
    for (final double v in s.values) {
      lo = math.min(lo, v);
      hi = math.max(hi, v);
    }
  }
  if (lo == double.infinity) {
    lo = 0;
    hi = 1;
  }
  return _niceBounds(lo, hi, ticks: ticks, includeZero: includeZero);
}

// ----------------------------------------------------------------------------
// Canvas text helper
// ----------------------------------------------------------------------------

TextPainter _measure(String text, TextStyle style, {double maxWidth = double.infinity}) {
  final TextPainter tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: "…",
  )..layout(maxWidth: maxWidth);
  return tp;
}

TextStyle _onColorLabel(TextStyle base, double opacity, {FontWeight weight = FontWeight.w600, double? size}) => base.copyWith(
  color: Colors.white.withValues(alpha: opacity.clamp(0, 1).toDouble()),
  fontWeight: weight,
  fontSize: size,
);

/// Paints [text] so that [anchor] (in Alignment space, -1..1) sits at [at].
void _paintText(Canvas canvas, String text, Offset at, TextStyle style, {Alignment anchor = Alignment.center, double maxWidth = double.infinity, double rotation = 0}) {
  final TextPainter tp = _measure(text, style, maxWidth: maxWidth);
  final double dx = at.dx - tp.width * (anchor.x + 1) / 2;
  final double dy = at.dy - tp.height * (anchor.y + 1) / 2;
  if (rotation == 0) {
    tp.paint(canvas, Offset(dx, dy));
    return;
  }
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.rotate(rotation);
  tp.paint(canvas, Offset(-tp.width * (anchor.x + 1) / 2, -tp.height * (anchor.y + 1) / 2));
  canvas.restore();
}

Path _dashPath(Path source, {double dash = 6, double gap = 4}) {
  final Path out = Path();
  for (final ui.PathMetric metric in source.computeMetrics()) {
    double distance = 0;
    while (distance < metric.length) {
      final double next = distance + dash;
      out.addPath(metric.extractPath(distance, math.min(next, metric.length)), Offset.zero);
      distance = next + gap;
    }
  }
  return out;
}

// ----------------------------------------------------------------------------
// Animator — drives a 0..1 progress into a painter builder
// ----------------------------------------------------------------------------

/// Rebuilds [builder] with an animated progress value from 0 to 1 on mount.
class UChartAnimator extends StatefulWidget {
  const UChartAnimator({
    required this.builder,
    required this.duration,
    required this.curve,
    this.animate = true,
    super.key,
  });

  final Widget Function(double t) builder;
  final Duration duration;
  final Curve curve;
  final bool animate;

  @override
  State<UChartAnimator> createState() => _UChartAnimatorState();
}

class _UChartAnimatorState extends State<UChartAnimator> with SingleTickerProviderStateMixin {
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

// ----------------------------------------------------------------------------
// Frame + legend widgets shared by all charts
// ----------------------------------------------------------------------------

class _LegendEntry {
  const _LegendEntry({required this.label, required this.color});

  final String label;
  final Color color;
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.entries});

  final List<_LegendEntry> entries;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 14,
    runSpacing: 6,
    alignment: WrapAlignment.center,
    children: entries
        .map(
          (_LegendEntry e) => Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(color: e.color, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 5),
              Text(e.label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        )
        .toList(),
  );
}

class _ChartFrame extends StatelessWidget {
  const _ChartFrame({
    required this.height,
    required this.padding,
    required this.background,
    required this.child,
    this.title,
    this.legend,
  });

  final double height;
  final EdgeInsets padding;
  final Color background;
  final Widget child;
  final String? title;
  final List<_LegendEntry>? legend;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: padding,
    color: background == Colors.transparent ? null : background,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(title!, style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center),
          ),
        Expanded(child: child),
        if (legend != null && legend!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _ChartLegend(entries: legend!),
          ),
      ],
    ),
  );
}

List<_LegendEntry> _seriesLegend(List<UChartSeries> series, _Resolved r) {
  final List<_LegendEntry> out = <_LegendEntry>[];
  for (int i = 0; i < series.length; i++) {
    final String? name = series[i].name;
    if (name == null) continue;
    out.add(_LegendEntry(label: name, color: series[i].color ?? r.colorAt(i)));
  }
  return out;
}

// ----------------------------------------------------------------------------
// Cartesian plotting primitives
// ----------------------------------------------------------------------------

class _Axes {
  const _Axes({required this.plot, required this.bounds});

  final Rect plot;
  final _Bounds bounds;

  double y(double value) => plot.bottom - (value - bounds.min) / (bounds.max - bounds.min) * plot.height;

  double xLine(int i, int n) => n <= 1 ? plot.center.dx : plot.left + i / (n - 1) * plot.width;

  double bandWidth(int n) => plot.width / n;

  double bandCenter(int i, int n) => plot.left + (i + 0.5) * plot.width / n;
}

_Axes _drawFrame(
  Canvas canvas,
  Size size,
  _Bounds bounds,
  List<String>? categories,
  int categoryCount,
  _Resolved r, {
  required bool showGrid,
  required bool showAxis,
  required bool showLabels,
  required bool bandMode,
}) {
  final int div = bounds.divisions;
  double leftPad = 6;
  if (showLabels) {
    double maxW = 0;
    for (int i = 0; i <= div; i++) {
      final double val = bounds.min + bounds.step * i;
      maxW = math.max(maxW, _measure(r.format(val), r.labelStyle).width);
    }
    leftPad = maxW + 10;
  }
  final double bottomPad = showLabels && categories != null ? r.labelStyle.fontSize! + 14 : 8;
  final Rect plot = Rect.fromLTRB(leftPad, 10, size.width - 12, size.height - bottomPad);
  final _Axes axes = _Axes(plot: plot, bounds: bounds);

  final Paint gridPaint = Paint()
    ..color = r.grid
    ..strokeWidth = 1;
  for (int i = 0; i <= div; i++) {
    final double val = bounds.min + bounds.step * i;
    final double gy = axes.y(val);
    if (showGrid) canvas.drawLine(Offset(plot.left, gy), Offset(plot.right, gy), gridPaint);
    if (showLabels) _paintText(canvas, r.format(val), Offset(plot.left - 6, gy), r.labelStyle, anchor: Alignment.centerRight);
  }

  if (bounds.min < 0 && bounds.max > 0) {
    final double zy = axes.y(0);
    canvas.drawLine(
      Offset(plot.left, zy),
      Offset(plot.right, zy),
      Paint()
        ..color = r.axis
        ..strokeWidth = 1.4,
    );
  }

  if (showAxis) {
    final Paint axisPaint = Paint()
      ..color = r.axis
      ..strokeWidth = 1.4;
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, axisPaint);
    canvas.drawLine(plot.topLeft, plot.bottomLeft, axisPaint);
  }

  if (showLabels && categories != null && categoryCount > 0) {
    final int n = categoryCount;
    final double slot = plot.width / n;
    double widest = 0;
    for (final String c in categories) {
      widest = math.max(widest, _measure(c, r.labelStyle).width);
    }
    final int every = widest + 6 > slot ? ((widest + 6) / slot).ceil() : 1;
    for (int i = 0; i < n; i++) {
      if (i % every != 0) continue;
      final String label = i < categories.length ? categories[i] : "";
      final double x = bandMode ? axes.bandCenter(i, n) : axes.xLine(i, n);
      _paintText(canvas, label, Offset(x, plot.bottom + 6), r.labelStyle, anchor: Alignment.topCenter, maxWidth: slot * every);
    }
  }
  return axes;
}

Path _polyPath(List<Offset> p) {
  final Path path = Path()..moveTo(p.first.dx, p.first.dy);
  for (int i = 1; i < p.length; i++) {
    path.lineTo(p[i].dx, p[i].dy);
  }
  return path;
}

Path _stepPath(List<Offset> p) {
  final Path path = Path()..moveTo(p.first.dx, p.first.dy);
  for (int i = 1; i < p.length; i++) {
    path.lineTo(p[i].dx, p[i - 1].dy);
    path.lineTo(p[i].dx, p[i].dy);
  }
  return path;
}

Path _smoothPath(List<Offset> p) {
  if (p.length < 3) return _polyPath(p);
  final Path path = Path()..moveTo(p.first.dx, p.first.dy);
  for (int i = 0; i < p.length - 1; i++) {
    final Offset c = p[i];
    final Offset nx = p[i + 1];
    final double midX = (c.dx + nx.dx) / 2;
    path.cubicTo(midX, c.dy, midX, nx.dy, nx.dx, nx.dy);
  }
  return path;
}

int _maxLen(List<UChartSeries> series) => series.isEmpty ? 0 : series.map((UChartSeries s) => s.values.length).reduce(math.max);

// ----------------------------------------------------------------------------
// Line / spline / step / area family
// ----------------------------------------------------------------------------

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.series,
    required this.bounds,
    required this.categories,
    required this.r,
    required this.style,
    required this.smooth,
    required this.step,
    required this.filled,
    required this.showDots,
    required this.strokeWidth,
    required this.progress,
  });

  final List<UChartSeries> series;
  final _Bounds bounds;
  final List<String>? categories;
  final _Resolved r;
  final UChartStyle style;
  final bool smooth;
  final bool step;
  final bool filled;
  final bool showDots;
  final double strokeWidth;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final int n = _maxLen(series);
    final _Axes axes = _drawFrame(canvas, size, bounds, categories, n, r, showGrid: style.showGrid, showAxis: style.showAxis, showLabels: style.showLabels, bandMode: false);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(axes.plot.left - strokeWidth, 0, axes.plot.width * progress + strokeWidth, size.height));
    for (int si = 0; si < series.length; si++) {
      final UChartSeries s = series[si];
      if (s.values.isEmpty) continue;
      final Color color = s.color ?? r.colorAt(si);
      final List<Offset> pts = <Offset>[];
      for (int i = 0; i < s.values.length; i++) {
        pts.add(Offset(axes.xLine(i, s.values.length), axes.y(s.values[i])));
      }
      final Path line = step ? _stepPath(pts) : (smooth ? _smoothPath(pts) : _polyPath(pts));
      if (s.filled ?? filled) {
        final Path fill = Path.from(line)
          ..lineTo(pts.last.dx, axes.plot.bottom)
          ..lineTo(pts.first.dx, axes.plot.bottom)
          ..close();
        canvas.drawPath(
          fill,
          Paint()
            ..style = PaintingStyle.fill
            ..shader = ui.Gradient.linear(
              Offset(0, axes.plot.top),
              Offset(0, axes.plot.bottom),
              <Color>[color.withValues(alpha: 0.3), color.withValues(alpha: 0.02)],
            ),
        );
      }
      final Paint lp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color;
      if (s.gradient != null) lp.shader = ui.Gradient.linear(axes.plot.topLeft, axes.plot.topRight, s.gradient!);
      canvas.drawPath(s.dashed ? _dashPath(line) : line, lp);
    }
    canvas.restore();

    if (showDots) {
      for (int si = 0; si < series.length; si++) {
        final UChartSeries s = series[si];
        final Color color = s.color ?? r.colorAt(si);
        final int shown = (s.values.length * progress).ceil();
        for (int i = 0; i < s.values.length && i < shown; i++) {
          canvas.drawCircle(Offset(axes.xLine(i, s.values.length), axes.y(s.values[i])), strokeWidth + 1, Paint()..color = color);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => old.progress != progress || old.series != series || old.bounds != bounds;
}

/// A multi-series line chart. Set [smooth] for spline curves and [filled] to
/// shade the area under each line.
class ULineChart extends StatelessWidget {
  const ULineChart({
    required this.series,
    super.key,
    this.categories,
    this.title,
    this.style = const UChartStyle(),
    this.height = 260,
    this.smooth = false,
    this.filled = false,
    this.showDots = true,
    this.strokeWidth = 3,
  });

  final List<UChartSeries> series;
  final List<String>? categories;
  final String? title;
  final UChartStyle style;
  final double height;
  final bool smooth;
  final bool filled;
  final bool showDots;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final _Resolved r = _resolve(context, style, seriesCount: series.length);
    final _Bounds bounds = _boundsForSeries(series, includeZero: false, ticks: style.gridDivisions + 1);
    return _frameWith(
      style: style,
      height: height,
      background: r.background,
      title: title,
      legend: _seriesLegend(series, r),
      painterBuilder: (double t) => _LinePainter(
        series: series,
        bounds: bounds,
        categories: categories,
        r: r,
        style: style,
        smooth: smooth,
        step: false,
        filled: filled,
        showDots: showDots,
        strokeWidth: strokeWidth,
        progress: t,
      ),
    );
  }
}

/// A smooth-curve line chart (spline interpolation).
class USplineChart extends StatelessWidget {
  const USplineChart({
    required this.series,
    super.key,
    this.categories,
    this.title,
    this.style = const UChartStyle(),
    this.height = 260,
    this.filled = false,
    this.showDots = true,
    this.strokeWidth = 3,
  });

  final List<UChartSeries> series;
  final List<String>? categories;
  final String? title;
  final UChartStyle style;
  final double height;
  final bool filled;
  final bool showDots;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => ULineChart(
    series: series,
    categories: categories,
    title: title,
    style: style,
    height: height,
    smooth: true,
    filled: filled,
    showDots: showDots,
    strokeWidth: strokeWidth,
  );
}

/// A step-interpolated line chart, ideal for discrete state over time.
class UStepLineChart extends StatelessWidget {
  const UStepLineChart({
    required this.series,
    super.key,
    this.categories,
    this.title,
    this.style = const UChartStyle(),
    this.height = 260,
    this.filled = false,
    this.showDots = false,
    this.strokeWidth = 3,
  });

  final List<UChartSeries> series;
  final List<String>? categories;
  final String? title;
  final UChartStyle style;
  final double height;
  final bool filled;
  final bool showDots;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final _Resolved r = _resolve(context, style, seriesCount: series.length);
    final _Bounds bounds = _boundsForSeries(series, includeZero: false, ticks: style.gridDivisions + 1);
    return _frameWith(
      style: style,
      height: height,
      background: r.background,
      title: title,
      legend: _seriesLegend(series, r),
      painterBuilder: (double t) => _LinePainter(
        series: series,
        bounds: bounds,
        categories: categories,
        r: r,
        style: style,
        smooth: false,
        step: true,
        filled: filled,
        showDots: showDots,
        strokeWidth: strokeWidth,
        progress: t,
      ),
    );
  }
}

/// A filled area chart (line with a gradient fill to the baseline).
class UAreaChart extends StatelessWidget {
  const UAreaChart({
    required this.series,
    super.key,
    this.categories,
    this.title,
    this.style = const UChartStyle(),
    this.height = 260,
    this.smooth = true,
    this.showDots = false,
    this.strokeWidth = 3,
  });

  final List<UChartSeries> series;
  final List<String>? categories;
  final String? title;
  final UChartStyle style;
  final double height;
  final bool smooth;
  final bool showDots;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => ULineChart(
    series: series,
    categories: categories,
    title: title,
    style: style,
    height: height,
    smooth: smooth,
    filled: true,
    showDots: showDots,
    strokeWidth: strokeWidth,
  );
}

Widget _frameWith({
  required UChartStyle style,
  required double height,
  required Color background,
  required String? title,
  required List<_LegendEntry>? legend,
  required CustomPainter Function(double t) painterBuilder,
}) => _ChartFrame(
  height: height,
  padding: style.padding,
  background: background,
  title: title,
  legend: style.showLegend ? legend : null,
  child: UChartAnimator(
    animate: style.animate,
    duration: style.animationDuration,
    curve: style.animationCurve,
    builder: (double t) => CustomPaint(painter: painterBuilder(t), size: Size.infinite),
  ),
);

// ----------------------------------------------------------------------------
// Bar / column family
// ----------------------------------------------------------------------------

enum _BarMode { grouped, stacked, percent }

_Bounds _stackedBounds(List<UChartSeries> series, int ticks) {
  final int n = _maxLen(series);
  double maxSum = 0;
  for (int i = 0; i < n; i++) {
    double sum = 0;
    for (final UChartSeries s in series) {
      if (i < s.values.length) sum += math.max(0, s.values[i]);
    }
    maxSum = math.max(maxSum, sum);
  }
  return _niceBounds(0, maxSum, ticks: ticks);
}

Color _seriesColorAt(UChartSeries s, int pointIndex, int seriesIndex, _Resolved r) {
  final List<Color>? pc = s.pointColors;
  if (pc != null && pointIndex < pc.length) return pc[pointIndex];
  return s.color ?? r.colorAt(seriesIndex);
}

void _paintBar(Canvas canvas, Rect rect, Color color, double cornerRadius, {required bool up, bool rounded = true}) {
  if (rect.height <= 0 || rect.width <= 0) return;
  final Radius rad = Radius.circular(math.min(cornerRadius, rect.width / 2));
  final RRect rr = rounded
      ? RRect.fromRectAndCorners(
          rect,
          topLeft: up ? rad : Radius.zero,
          topRight: up ? rad : Radius.zero,
          bottomLeft: up ? Radius.zero : rad,
          bottomRight: up ? Radius.zero : rad,
        )
      : RRect.fromRectAndRadius(rect, Radius.zero);
  canvas.drawRRect(
    rr,
    Paint()..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, <Color>[color, color.withValues(alpha: 0.7)]),
  );
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.series,
    required this.bounds,
    required this.categories,
    required this.r,
    required this.style,
    required this.mode,
    required this.cornerRadius,
    required this.progress,
  });

  final List<UChartSeries> series;
  final _Bounds bounds;
  final List<String>? categories;
  final _Resolved r;
  final UChartStyle style;
  final _BarMode mode;
  final double cornerRadius;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final int n = _maxLen(series);
    final _Axes axes = _drawFrame(canvas, size, bounds, categories, n, r, showGrid: style.showGrid, showAxis: style.showAxis, showLabels: style.showLabels, bandMode: true);
    final double baseline = axes.y(bounds.min < 0 ? 0 : bounds.min);
    final double slot = axes.bandWidth(n);

    if (mode == _BarMode.grouped) {
      final int m = series.length;
      final double groupW = slot * 0.72;
      final double barW = groupW / m;
      for (int i = 0; i < n; i++) {
        for (int si = 0; si < m; si++) {
          if (i >= series[si].values.length) continue;
          final double v = series[si].values[i];
          final double top = ui.lerpDouble(baseline, axes.y(v), progress)!;
          final double left = axes.bandCenter(i, n) - groupW / 2 + si * barW;
          final Rect rect = Rect.fromLTRB(left + barW * 0.12, math.min(top, baseline), left + barW * 0.88, math.max(top, baseline));
          _paintBar(canvas, rect, _seriesColorAt(series[si], i, si, r), cornerRadius, up: v >= 0);
        }
      }
      return;
    }

    for (int i = 0; i < n; i++) {
      double total = 0;
      if (mode == _BarMode.percent) {
        for (final UChartSeries s in series) {
          if (i < s.values.length) total += math.max(0, s.values[i]);
        }
        if (total == 0) total = 1;
      }
      double cum = 0;
      final double left = axes.bandCenter(i, n) - slot * 0.34;
      final double right = axes.bandCenter(i, n) + slot * 0.34;
      for (int si = 0; si < series.length; si++) {
        if (i >= series[si].values.length) continue;
        final double raw = math.max(0, series[si].values[i]);
        final double v = mode == _BarMode.percent ? raw / total * 100 : raw;
        if (v <= 0) continue;
        final double yBottom = ui.lerpDouble(baseline, axes.y(cum), progress)!;
        final double yTop = ui.lerpDouble(baseline, axes.y(cum + v), progress)!;
        _paintBar(canvas, Rect.fromLTRB(left, yTop, right, yBottom), series[si].color ?? r.colorAt(si), cornerRadius, up: true, rounded: si == series.length - 1);
        cum += v;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => old.progress != progress || old.series != series || old.mode != mode;
}

class _HBarPainter extends CustomPainter {
  _HBarPainter({
    required this.series,
    required this.bounds,
    required this.categories,
    required this.r,
    required this.style,
    required this.cornerRadius,
    required this.progress,
  });

  final List<UChartSeries> series;
  final _Bounds bounds;
  final List<String>? categories;
  final _Resolved r;
  final UChartStyle style;
  final double cornerRadius;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final int n = _maxLen(series);
    final int m = series.length;
    double leftPad = 6;
    if (style.showLabels && categories != null) {
      for (final String c in categories!) {
        leftPad = math.max(leftPad, _measure(c, r.labelStyle).width + 12);
      }
    }
    final double bottomPad = style.showLabels ? r.labelStyle.fontSize! + 14 : 8;
    final Rect plot = Rect.fromLTRB(leftPad, 10, size.width - 14, size.height - bottomPad);
    double vx(double value) => plot.left + (value - bounds.min) / (bounds.max - bounds.min) * plot.width;

    final int div = bounds.divisions;
    for (int i = 0; i <= div; i++) {
      final double val = bounds.min + bounds.step * i;
      final double x = vx(val);
      if (style.showGrid) {
        canvas.drawLine(
          Offset(x, plot.top),
          Offset(x, plot.bottom),
          Paint()..color = r.grid,
        );
      }
      if (style.showLabels) _paintText(canvas, r.format(val), Offset(x, plot.bottom + 6), r.labelStyle, anchor: Alignment.topCenter);
    }
    if (style.showAxis) {
      canvas.drawLine(
        plot.topLeft,
        plot.bottomLeft,
        Paint()
          ..color = r.axis
          ..strokeWidth = 1.4,
      );
      canvas.drawLine(
        plot.bottomLeft,
        plot.bottomRight,
        Paint()
          ..color = r.axis
          ..strokeWidth = 1.4,
      );
    }

    final double bandH = plot.height / n;
    final double barH = bandH * 0.72 / m;
    final double baseX = vx(bounds.min < 0 ? 0 : bounds.min);
    for (int i = 0; i < n; i++) {
      final double bandTop = plot.top + i * bandH;
      if (style.showLabels && categories != null && i < categories!.length) {
        _paintText(canvas, categories![i], Offset(plot.left - 8, bandTop + bandH / 2), r.labelStyle, anchor: Alignment.centerRight, maxWidth: leftPad);
      }
      for (int si = 0; si < m; si++) {
        if (i >= series[si].values.length) continue;
        final double v = series[si].values[i];
        final double end = ui.lerpDouble(baseX, vx(v), progress)!;
        final double top = bandTop + bandH * 0.14 + si * barH;
        final Rect rect = Rect.fromLTRB(math.min(baseX, end), top, math.max(baseX, end), top + barH * 0.9);
        final Color color = _seriesColorAt(series[si], i, si, r);
        if (rect.width <= 0) continue;
        final Radius rad = Radius.circular(math.min(cornerRadius, rect.height / 2));
        canvas.drawRRect(
          RRect.fromRectAndCorners(rect, topRight: rad, bottomRight: rad),
          Paint()..shader = ui.Gradient.linear(rect.centerLeft, rect.centerRight, <Color>[color.withValues(alpha: 0.75), color]),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HBarPainter old) => old.progress != progress || old.series != series;
}

class _StackedAreaPainter extends CustomPainter {
  _StackedAreaPainter({
    required this.series,
    required this.bounds,
    required this.categories,
    required this.r,
    required this.style,
    required this.progress,
  });

  final List<UChartSeries> series;
  final _Bounds bounds;
  final List<String>? categories;
  final _Resolved r;
  final UChartStyle style;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final int n = _maxLen(series);
    final _Axes axes = _drawFrame(canvas, size, bounds, categories, n, r, showGrid: style.showGrid, showAxis: style.showAxis, showLabels: style.showLabels, bandMode: false);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(axes.plot.left, 0, axes.plot.width * progress + 1, size.height));
    final List<double> cum = List<double>.filled(n, 0);
    for (int si = 0; si < series.length; si++) {
      final UChartSeries s = series[si];
      final List<Offset> upper = <Offset>[];
      final List<Offset> lower = <Offset>[];
      for (int i = 0; i < n; i++) {
        final double v = i < s.values.length ? math.max(0, s.values[i]) : 0;
        lower.add(Offset(axes.xLine(i, n), axes.y(cum[i])));
        cum[i] += v;
        upper.add(Offset(axes.xLine(i, n), axes.y(cum[i])));
      }
      final Path path = _smoothPath(upper);
      for (int i = lower.length - 1; i >= 0; i--) {
        path.lineTo(lower[i].dx, lower[i].dy);
      }
      path.close();
      final Color color = s.color ?? r.colorAt(si);
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.82));
      canvas.drawPath(
        _smoothPath(upper),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StackedAreaPainter old) => old.progress != progress || old.series != series;
}

/// A vertical bar/column chart. Multiple series are drawn side-by-side (grouped).
class UBarChart extends StatelessWidget {
  const UBarChart({
    required this.series,
    super.key,
    this.categories,
    this.title,
    this.style = const UChartStyle(),
    this.height = 260,
  });

  final List<UChartSeries> series;
  final List<String>? categories;
  final String? title;
  final UChartStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final _Resolved r = _resolve(context, style, seriesCount: series.length);
    final _Bounds bounds = _boundsForSeries(series, ticks: style.gridDivisions + 1);
    return _frameWith(
      style: style,
      height: height,
      background: r.background,
      title: title,
      legend: _seriesLegend(series, r),
      painterBuilder: (double t) => _BarPainter(series: series, bounds: bounds, categories: categories, r: r, style: style, mode: _BarMode.grouped, cornerRadius: style.cornerRadius, progress: t),
    );
  }
}

/// Explicit grouped (clustered) bar chart. Identical to [UBarChart] with
/// multiple series.
class UGroupedBarChart extends StatelessWidget {
  const UGroupedBarChart({
    required this.series,
    super.key,
    this.categories,
    this.title,
    this.style = const UChartStyle(),
    this.height = 260,
  });

  final List<UChartSeries> series;
  final List<String>? categories;
  final String? title;
  final UChartStyle style;
  final double height;

  @override
  Widget build(BuildContext context) => UBarChart(series: series, categories: categories, title: title, style: style, height: height);
}

/// A horizontal bar chart. Multiple series are grouped within each category row.
class UHorizontalBarChart extends StatelessWidget {
  const UHorizontalBarChart({
    required this.series,
    super.key,
    this.categories,
    this.title,
    this.style = const UChartStyle(),
    this.height = 260,
  });

  final List<UChartSeries> series;
  final List<String>? categories;
  final String? title;
  final UChartStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final _Resolved r = _resolve(context, style, seriesCount: series.length);
    final _Bounds bounds = _boundsForSeries(series, ticks: style.gridDivisions + 1);
    return _frameWith(
      style: style,
      height: height,
      background: r.background,
      title: title,
      legend: _seriesLegend(series, r),
      painterBuilder: (double t) => _HBarPainter(series: series, bounds: bounds, categories: categories, r: r, style: style, cornerRadius: style.cornerRadius, progress: t),
    );
  }
}

/// A stacked bar chart (series stacked on top of one another per category).
class UStackedBarChart extends StatelessWidget {
  const UStackedBarChart({
    required this.series,
    super.key,
    this.categories,
    this.title,
    this.style = const UChartStyle(),
    this.height = 260,
  });

  final List<UChartSeries> series;
  final List<String>? categories;
  final String? title;
  final UChartStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final _Resolved r = _resolve(context, style, seriesCount: series.length);
    final _Bounds bounds = _stackedBounds(series, style.gridDivisions + 1);
    return _frameWith(
      style: style,
      height: height,
      background: r.background,
      title: title,
      legend: _seriesLegend(series, r),
      painterBuilder: (double t) => _BarPainter(series: series, bounds: bounds, categories: categories, r: r, style: style, mode: _BarMode.stacked, cornerRadius: style.cornerRadius, progress: t),
    );
  }
}

/// A 100%-stacked bar chart: each category fills the full height, showing each
/// series' share as a percentage.
class UStacked100BarChart extends StatelessWidget {
  const UStacked100BarChart({
    required this.series,
    super.key,
    this.categories,
    this.title,
    this.style = const UChartStyle(),
    this.height = 260,
  });

  final List<UChartSeries> series;
  final List<String>? categories;
  final String? title;
  final UChartStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final _Resolved r0 = _resolve(context, style, seriesCount: series.length);
    final _Resolved r = _Resolved(
      palette: r0.palette,
      background: r0.background,
      grid: r0.grid,
      axis: r0.axis,
      labelStyle: r0.labelStyle,
      format: (double v) => "${v.toStringAsFixed(0)}%",
    );
    const _Bounds bounds = _Bounds(min: 0, max: 100, step: 20);
    return _frameWith(
      style: style,
      height: height,
      background: r.background,
      title: title,
      legend: _seriesLegend(series, r),
      painterBuilder: (double t) => _BarPainter(series: series, bounds: bounds, categories: categories, r: r, style: style, mode: _BarMode.percent, cornerRadius: style.cornerRadius, progress: t),
    );
  }
}

/// A stacked area chart.
class UStackedAreaChart extends StatelessWidget {
  const UStackedAreaChart({
    required this.series,
    super.key,
    this.categories,
    this.title,
    this.style = const UChartStyle(),
    this.height = 260,
  });

  final List<UChartSeries> series;
  final List<String>? categories;
  final String? title;
  final UChartStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final _Resolved r = _resolve(context, style, seriesCount: series.length);
    final _Bounds bounds = _stackedBounds(series, style.gridDivisions + 1);
    return _frameWith(
      style: style,
      height: height,
      background: r.background,
      title: title,
      legend: _seriesLegend(series, r),
      painterBuilder: (double t) => _StackedAreaPainter(series: series, bounds: bounds, categories: categories, r: r, style: style, progress: t),
    );
  }
}

// ----------------------------------------------------------------------------
// Circular / proportional family — pie, donut, funnel, treemap
// ----------------------------------------------------------------------------

List<_LegendEntry> _sliceLegend(List<USlice> slices, _Resolved r) {
  final List<_LegendEntry> out = <_LegendEntry>[];
  for (int i = 0; i < slices.length; i++) {
    final String? label = slices[i].label;
    if (label == null) continue;
    out.add(_LegendEntry(label: label, color: slices[i].color ?? r.colorAt(i)));
  }
  return out;
}

class _PiePainter extends CustomPainter {
  _PiePainter({
    required this.slices,
    required this.r,
    required this.innerFactor,
    required this.showLabels,
    required this.centerText,
    required this.progress,
  });

  final List<USlice> slices;
  final _Resolved r;
  final double innerFactor;
  final bool showLabels;
  final String? centerText;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final double total = slices.fold<double>(0, (double a, USlice s) => a + math.max(0, s.value));
    if (total <= 0) return;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 - 6;
    final double inner = radius * innerFactor;
    final double gap = slices.length > 1 ? 0.015 : 0;
    final double revealed = 2 * math.pi * progress;

    double drawn = 0;
    for (int i = 0; i < slices.length; i++) {
      final double value = math.max(0, slices[i].value);
      final double sweep = value / total * 2 * math.pi;
      final double shown = math.min(sweep, math.max(0, revealed - drawn));
      if (shown > 0) {
        final Color color = slices[i].color ?? r.colorAt(i);
        final double start = -math.pi / 2 + drawn + gap / 2;
        final double s = math.max(0, shown - gap);
        if (innerFactor > 0) {
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: (radius + inner) / 2),
            start,
            s,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = radius - inner
              ..color = color,
          );
        } else {
          final Path wedge = Path()
            ..moveTo(center.dx, center.dy)
            ..arcTo(Rect.fromCircle(center: center, radius: radius), start, s, false)
            ..close();
          canvas.drawPath(wedge, Paint()..color = color);
        }
      }
      if (showLabels && sweep / (2 * math.pi) > 0.04) {
        final double mid = -math.pi / 2 + drawn + sweep / 2;
        final double lr = innerFactor > 0 ? (radius + inner) / 2 : radius * 0.62;
        _paintText(
          canvas,
          "${(value / total * 100).toStringAsFixed(0)}%",
          center + Offset(math.cos(mid) * lr, math.sin(mid) * lr),
          _onColorLabel(r.labelStyle, progress, weight: FontWeight.w700),
        );
      }
      drawn += sweep;
    }

    if (centerText != null && innerFactor > 0) {
      _paintText(
        canvas,
        centerText!,
        center,
        r.labelStyle.copyWith(fontSize: inner * 0.34, fontWeight: FontWeight.w700),
        maxWidth: inner * 1.8,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) => old.progress != progress || old.slices != slices;
}

class _FunnelPainter extends CustomPainter {
  _FunnelPainter({required this.slices, required this.r, required this.showLabels, required this.progress});

  final List<USlice> slices;
  final _Resolved r;
  final bool showLabels;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;
    final double maxV = slices.fold<double>(0, (double a, USlice s) => math.max(a, s.value));
    if (maxV <= 0) return;
    final double cx = size.width / 2;
    const double gap = 3;
    final double segH = (size.height - gap * (slices.length - 1)) / slices.length;
    for (int i = 0; i < slices.length; i++) {
      final double top = i * (segH + gap);
      final double wTop = slices[i].value / maxV * size.width * progress;
      final double nextV = i + 1 < slices.length ? slices[i + 1].value : slices[i].value;
      final double wBot = nextV / maxV * size.width * progress;
      final Path path = Path()
        ..moveTo(cx - wTop / 2, top)
        ..lineTo(cx + wTop / 2, top)
        ..lineTo(cx + wBot / 2, top + segH)
        ..lineTo(cx - wBot / 2, top + segH)
        ..close();
      final Color color = slices[i].color ?? r.colorAt(i);
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.9));
      if (showLabels && slices[i].label != null) {
        _paintText(canvas, slices[i].label!, Offset(cx, top + segH / 2), _onColorLabel(r.labelStyle, progress));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FunnelPainter old) => old.progress != progress || old.slices != slices;
}

class _TItem {
  const _TItem({required this.slice, required this.color});

  final USlice slice;
  final Color color;

  double get value => math.max(0, slice.value);
}

void _layoutTreemap(List<_TItem> items, Rect rect, List<MapEntry<_TItem, Rect>> out) {
  if (items.isEmpty) return;
  if (items.length == 1) {
    out.add(MapEntry<_TItem, Rect>(items.first, rect));
    return;
  }
  final double total = items.fold<double>(0, (double a, _TItem b) => a + b.value);
  double acc = 0;
  int split = 1;
  for (int i = 0; i < items.length; i++) {
    if (acc + items[i].value > total / 2 && i > 0) {
      split = i;
      break;
    }
    acc += items[i].value;
    split = i + 1;
  }
  final List<_TItem> a = items.sublist(0, split);
  final List<_TItem> b = items.sublist(split);
  final double aSum = a.fold<double>(0, (double x, _TItem y) => x + y.value);
  final double frac = total == 0 ? 0.5 : aSum / total;
  if (rect.width >= rect.height) {
    final double w = rect.width * frac;
    _layoutTreemap(a, Rect.fromLTWH(rect.left, rect.top, w, rect.height), out);
    _layoutTreemap(b, Rect.fromLTWH(rect.left + w, rect.top, rect.width - w, rect.height), out);
  } else {
    final double h = rect.height * frac;
    _layoutTreemap(a, Rect.fromLTWH(rect.left, rect.top, rect.width, h), out);
    _layoutTreemap(b, Rect.fromLTWH(rect.left, rect.top + h, rect.width, rect.height - h), out);
  }
}

class _TreemapPainter extends CustomPainter {
  _TreemapPainter({required this.items, required this.r, required this.showLabels, required this.progress});

  final List<_TItem> items;
  final _Resolved r;
  final bool showLabels;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final List<MapEntry<_TItem, Rect>> tiles = <MapEntry<_TItem, Rect>>[];
    _layoutTreemap(items, Offset.zero & size, tiles);
    for (final MapEntry<_TItem, Rect> tile in tiles) {
      final Rect full = tile.value.deflate(1.5);
      final Rect rect = Rect.fromCenter(center: full.center, width: full.width * progress, height: full.height * progress);
      if (rect.width <= 0 || rect.height <= 0) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = tile.key.color,
      );
      if (showLabels && tile.key.slice.label != null && rect.width > 40 && rect.height > 24) {
        _paintText(
          canvas,
          tile.key.slice.label!,
          rect.center,
          _onColorLabel(r.labelStyle, progress),
          maxWidth: rect.width - 8,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TreemapPainter old) => old.progress != progress || old.items != items;
}

/// A pie chart.
class UPieChart extends StatelessWidget {
  const UPieChart({
    required this.slices,
    super.key,
    this.title,
    this.style = const UChartStyle(),
    this.height = 260,
  });

  final List<USlice> slices;
  final String? title;
  final UChartStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final _Resolved r = _resolve(context, style, seriesCount: slices.length);
    return _frameWith(
      style: style,
      height: height,
      background: r.background,
      title: title,
      legend: _sliceLegend(slices, r),
      painterBuilder: (double t) => _PiePainter(slices: slices, r: r, innerFactor: 0, showLabels: style.showLabels, centerText: null, progress: t),
    );
  }
}

/// A donut chart. Provide [centerText] to label the hole (e.g. a total).
class UDonutChart extends StatelessWidget {
  const UDonutChart({
    required this.slices,
    super.key,
    this.title,
    this.centerText,
    this.holeFactor = 0.6,
    this.style = const UChartStyle(),
    this.height = 260,
  });

  final List<USlice> slices;
  final String? title;
  final String? centerText;
  final double holeFactor;
  final UChartStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final _Resolved r = _resolve(context, style, seriesCount: slices.length);
    return _frameWith(
      style: style,
      height: height,
      background: r.background,
      title: title,
      legend: _sliceLegend(slices, r),
      painterBuilder: (double t) => _PiePainter(slices: slices, r: r, innerFactor: holeFactor, showLabels: style.showLabels, centerText: centerText, progress: t),
    );
  }
}

/// A funnel chart, useful for conversion/pipeline stages.
class UFunnelChart extends StatelessWidget {
  const UFunnelChart({
    required this.slices,
    super.key,
    this.title,
    this.style = const UChartStyle(),
    this.height = 260,
  });

  final List<USlice> slices;
  final String? title;
  final UChartStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final _Resolved r = _resolve(context, style, seriesCount: slices.length);
    return _frameWith(
      style: style,
      height: height,
      background: r.background,
      title: title,
      legend: _sliceLegend(slices, r),
      painterBuilder: (double t) => _FunnelPainter(slices: slices, r: r, showLabels: style.showLabels, progress: t),
    );
  }
}

/// A treemap chart — nested rectangles sized by value.
class UTreemapChart extends StatelessWidget {
  const UTreemapChart({
    required this.slices,
    super.key,
    this.title,
    this.style = const UChartStyle(),
    this.height = 260,
  });

  final List<USlice> slices;
  final String? title;
  final UChartStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final _Resolved r = _resolve(context, style, seriesCount: slices.length);
    final List<USlice> sorted = List<USlice>.of(slices)..sort((USlice a, USlice b) => b.value.compareTo(a.value));
    final List<_TItem> items = <_TItem>[];
    for (int i = 0; i < sorted.length; i++) {
      items.add(_TItem(slice: sorted[i], color: sorted[i].color ?? r.colorAt(slices.indexOf(sorted[i]))));
    }
    return _frameWith(
      style: style,
      height: height,
      background: r.background,
      title: title,
      legend: _sliceLegend(slices, r),
      painterBuilder: (double t) => _TreemapPainter(items: items, r: r, showLabels: style.showLabels, progress: t),
    );
  }
}

// ----------------------------------------------------------------------------
// Scatter / bubble (numeric X and Y) + radar (polar)
// ----------------------------------------------------------------------------

class _XY {
  const _XY({required this.plot, required this.xb, required this.yb});

  final Rect plot;
  final _Bounds xb;
  final _Bounds yb;

  double px(double x) => plot.left + (x - xb.min) / (xb.max - xb.min) * plot.width;

  double py(double y) => plot.bottom - (y - yb.min) / (yb.max - yb.min) * plot.height;
}

_XY _drawXYFrame(Canvas canvas, Size size, _Bounds xb, _Bounds yb, _Resolved r, UChartStyle style) {
  double leftPad = 6;
  if (style.showLabels) {
    double mw = 0;
    for (int i = 0; i <= yb.divisions; i++) {
      mw = math.max(mw, _measure(r.format(yb.min + yb.step * i), r.labelStyle).width);
    }
    leftPad = mw + 10;
  }
  final double bottomPad = style.showLabels ? r.labelStyle.fontSize! + 16 : 8;
  final Rect plot = Rect.fromLTRB(leftPad, 10, size.width - 14, size.height - bottomPad);
  final _XY xy = _XY(plot: plot, xb: xb, yb: yb);
  for (int i = 0; i <= yb.divisions; i++) {
    final double v = yb.min + yb.step * i;
    final double y = xy.py(v);
    if (style.showGrid) canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), Paint()..color = r.grid);
    if (style.showLabels) _paintText(canvas, r.format(v), Offset(plot.left - 6, y), r.labelStyle, anchor: Alignment.centerRight);
  }
  for (int i = 0; i <= xb.divisions; i++) {
    final double v = xb.min + xb.step * i;
    final double x = xy.px(v);
    if (style.showGrid) canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), Paint()..color = r.grid);
    if (style.showLabels) _paintText(canvas, r.format(v), Offset(x, plot.bottom + 6), r.labelStyle, anchor: Alignment.topCenter);
  }
  if (style.showAxis) {
    final Paint ap = Paint()
      ..color = r.axis
      ..strokeWidth = 1.4;
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, ap);
    canvas.drawLine(plot.topLeft, plot.bottomLeft, ap);
  }
  return xy;
}

List<_LegendEntry> _pointLegend(List<UPointSeries> data, _Resolved r) {
  final List<_LegendEntry> out = <_LegendEntry>[];
  for (int i = 0; i < data.length; i++) {
    final String? name = data[i].name;
    if (name == null) continue;
    out.add(_LegendEntry(label: name, color: data[i].color ?? r.colorAt(i)));
  }
  return out;
}

class _ScatterPainter extends CustomPainter {
  _ScatterPainter({
    required this.data,
    required this.xb,
    required this.yb,
    required this.r,
    required this.style,
    required this.bubble,
    required this.maxSize,
    required this.dotRadius,
    required this.progress,
  });

  final List<UPointSeries> data;
  final _Bounds xb;
  final _Bounds yb;
  final _Resolved r;
  final UChartStyle style;
  final bool bubble;
  final double maxSize;
  final double dotRadius;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final _XY xy = _drawXYFrame(canvas, size, xb, yb, r, style);
    for (int si = 0; si < data.length; si++) {
      final Color color = data[si].color ?? r.colorAt(si);
      for (final UChartPoint p in data[si].points) {
        final double baseR = bubble && p.size != null && maxSize > 0 ? 6 + math.sqrt(p.size! / maxSize) * 26 : dotRadius;
        final Offset c = Offset(xy.px(p.x), xy.py(p.y));
        canvas.drawCircle(c, baseR * progress, Paint()..color = color.withValues(alpha: bubble ? 0.55 : 0.85));
        canvas.drawCircle(
          c,
          baseR * progress,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScatterPainter old) => old.progress != progress || old.data != data;
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.series,
    required this.axesLabels,
    required this.maxValue,
    required this.rings,
    required this.r,
    required this.filled,
    required this.progress,
  });

  final List<UChartSeries> series;
  final List<String> axesLabels;
  final double maxValue;
  final int rings;
  final _Resolved r;
  final bool filled;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final int k = axesLabels.length;
    if (k < 3) return;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 - r.labelStyle.fontSize! * 2 - 8;
    double angleAt(int i) => -math.pi / 2 + i * 2 * math.pi / k;

    final Paint gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = r.grid;
    for (int ring = 1; ring <= rings; ring++) {
      final double rr = radius * ring / rings;
      final Path poly = Path();
      for (int i = 0; i <= k; i++) {
        final double a = angleAt(i % k);
        final Offset o = center + Offset(math.cos(a) * rr, math.sin(a) * rr);
        if (i == 0) {
          poly.moveTo(o.dx, o.dy);
        } else {
          poly.lineTo(o.dx, o.dy);
        }
      }
      canvas.drawPath(poly, gridPaint);
    }
    for (int i = 0; i < k; i++) {
      final double a = angleAt(i);
      final Offset edge = center + Offset(math.cos(a) * radius, math.sin(a) * radius);
      canvas.drawLine(center, edge, gridPaint);
      final Offset lp = center + Offset(math.cos(a) * (radius + 14), math.sin(a) * (radius + 12));
      _paintText(canvas, axesLabels[i], lp, r.labelStyle);
    }

    for (int si = 0; si < series.length; si++) {
      final Color color = series[si].color ?? r.colorAt(si);
      final Path path = Path();
      for (int i = 0; i < k; i++) {
        final double v = i < series[si].values.length ? series[si].values[i] : 0;
        final double rr = maxValue == 0 ? 0 : (v / maxValue).clamp(0, 1).toDouble() * radius * progress;
        final double a = angleAt(i);
        final Offset o = center + Offset(math.cos(a) * rr, math.sin(a) * rr);
        if (i == 0) {
          path.moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      path.close();
      if (filled) canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.22));
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.progress != progress || old.series != series;
}

/// A scatter chart plotting free (x, y) points.
class UScatterChart extends StatelessWidget {
  const UScatterChart({
    required this.data,
    super.key,
    this.title,
    this.style = const UChartStyle(),
    this.height = 260,
    this.dotRadius = 5,
  });

  final List<UPointSeries> data;
  final String? title;
  final UChartStyle style;
  final double height;
  final double dotRadius;

  @override
  Widget build(BuildContext context) {
    final _Resolved r = _resolve(context, style, seriesCount: data.length);
    final _Bounds xb = _pointBounds(data, axisX: true, ticks: style.gridDivisions + 1);
    final _Bounds yb = _pointBounds(data, axisX: false, ticks: style.gridDivisions + 1);
    return _frameWith(
      style: style,
      height: height,
      background: r.background,
      title: title,
      legend: _pointLegend(data, r),
      painterBuilder: (double t) => _ScatterPainter(data: data, xb: xb, yb: yb, r: r, style: style, bubble: false, maxSize: 0, dotRadius: dotRadius, progress: t),
    );
  }
}

/// A bubble chart — a scatter chart where each point's [UChartPoint.size]
/// controls the bubble radius (by area).
class UBubbleChart extends StatelessWidget {
  const UBubbleChart({
    required this.data,
    super.key,
    this.title,
    this.style = const UChartStyle(),
    this.height = 260,
  });

  final List<UPointSeries> data;
  final String? title;
  final UChartStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final _Resolved r = _resolve(context, style, seriesCount: data.length);
    final _Bounds xb = _pointBounds(data, axisX: true, ticks: style.gridDivisions + 1);
    final _Bounds yb = _pointBounds(data, axisX: false, ticks: style.gridDivisions + 1);
    double maxSize = 0;
    for (final UPointSeries s in data) {
      for (final UChartPoint p in s.points) {
        maxSize = math.max(maxSize, p.size ?? 0);
      }
    }
    return _frameWith(
      style: style,
      height: height,
      background: r.background,
      title: title,
      legend: _pointLegend(data, r),
      painterBuilder: (double t) => _ScatterPainter(data: data, xb: xb, yb: yb, r: r, style: style, bubble: true, maxSize: maxSize, dotRadius: 6, progress: t),
    );
  }
}

/// A radar (spider) chart comparing several series across shared axes.
class URadarChart extends StatelessWidget {
  const URadarChart({
    required this.series,
    required this.axes,
    super.key,
    this.title,
    this.filled = true,
    this.style = const UChartStyle(),
    this.height = 280,
  });

  final List<UChartSeries> series;
  final List<String> axes;
  final String? title;
  final bool filled;
  final UChartStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final _Resolved r = _resolve(context, style, seriesCount: series.length);
    double maxVal = 0;
    for (final UChartSeries s in series) {
      for (final double v in s.values) {
        maxVal = math.max(maxVal, v);
      }
    }
    final _Bounds nice = _niceBounds(0, maxVal, ticks: style.gridDivisions + 1);
    return _frameWith(
      style: style,
      height: height,
      background: r.background,
      title: title,
      legend: _seriesLegend(series, r),
      painterBuilder: (double t) => _RadarPainter(series: series, axesLabels: axes, maxValue: nice.max, rings: style.gridDivisions, r: r, filled: filled, progress: t),
    );
  }
}

_Bounds _pointBounds(List<UPointSeries> data, {required bool axisX, int ticks = 5}) {
  double lo = double.infinity;
  double hi = double.negativeInfinity;
  for (final UPointSeries s in data) {
    for (final UChartPoint p in s.points) {
      final double v = axisX ? p.x : p.y;
      lo = math.min(lo, v);
      hi = math.max(hi, v);
    }
  }
  if (lo == double.infinity) {
    lo = 0;
    hi = 1;
  }
  return _niceBounds(lo, hi, ticks: ticks, includeZero: false);
}

// ----------------------------------------------------------------------------
// Candlestick / OHLC / histogram / heatmap / waterfall / sparkline
// ----------------------------------------------------------------------------

class _CandlePainter extends CustomPainter {
  _CandlePainter({
    required this.candles,
    required this.bounds,
    required this.labels,
    required this.r,
    required this.style,
    required this.up,
    required this.down,
    required this.ohlc,
    required this.progress,
  });

  final List<UCandle> candles;
  final _Bounds bounds;
  final List<String>? labels;
  final _Resolved r;
  final UChartStyle style;
  final Color up;
  final Color down;
  final bool ohlc;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final int n = candles.length;
    final _Axes axes = _drawFrame(canvas, size, bounds, labels, n, r, showGrid: style.showGrid, showAxis: style.showAxis, showLabels: style.showLabels, bandMode: true);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(axes.plot.left, 0, axes.plot.width * progress + 1, size.height));
    final double w = axes.bandWidth(n) * 0.5;
    for (int i = 0; i < n; i++) {
      final UCandle c = candles[i];
      final double cx = axes.bandCenter(i, n);
      final Color color = c.bullish ? up : down;
      final Paint stroke = Paint()
        ..color = color
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(cx, axes.y(c.high)), Offset(cx, axes.y(c.low)), stroke);
      if (ohlc) {
        canvas.drawLine(Offset(cx - w / 2, axes.y(c.open)), Offset(cx, axes.y(c.open)), stroke);
        canvas.drawLine(Offset(cx, axes.y(c.close)), Offset(cx + w / 2, axes.y(c.close)), stroke);
      } else {
        final double top = math.min(axes.y(c.open), axes.y(c.close));
        final double bot = math.max(axes.y(c.open), axes.y(c.close));
        final Rect body = Rect.fromLTRB(cx - w / 2, top, cx + w / 2, math.max(bot, top + 1));
        canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(2)), Paint()..color = color);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CandlePainter old) => old.progress != progress || old.candles != candles;
}

class _HistogramPainter extends CustomPainter {
  _HistogramPainter({
    required this.counts,
    required this.labels,
    required this.bounds,
    required this.r,
    required this.style,
    required this.color,
    required this.cornerRadius,
    required this.progress,
  });

  final List<double> counts;
  final List<String> labels;
  final _Bounds bounds;
  final _Resolved r;
  final UChartStyle style;
  final Color color;
  final double cornerRadius;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final int n = counts.length;
    final _Axes axes = _drawFrame(canvas, size, bounds, labels, n, r, showGrid: style.showGrid, showAxis: style.showAxis, showLabels: style.showLabels, bandMode: true);
    final double baseline = axes.y(0);
    final double slot = axes.bandWidth(n);
    for (int i = 0; i < n; i++) {
      final double top = ui.lerpDouble(baseline, axes.y(counts[i]), progress)!;
      final double left = axes.bandCenter(i, n) - slot / 2 + 1;
      final double right = axes.bandCenter(i, n) + slot / 2 - 1;
      _paintBar(canvas, Rect.fromLTRB(left, top, right, baseline), color, cornerRadius, up: true);
    }
  }

  @override
  bool shouldRepaint(covariant _HistogramPainter old) => old.progress != progress || old.counts != counts;
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.matrix,
    required this.rowLabels,
    required this.colLabels,
    required this.base,
    required this.r,
    required this.showValues,
    required this.progress,
  });

  final List<List<double>> matrix;
  final List<String>? rowLabels;
  final List<String>? colLabels;
  final Color base;
  final _Resolved r;
  final bool showValues;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final int rows = matrix.length;
    if (rows == 0) return;
    final int cols = matrix.first.length;
    double lo = double.infinity;
    double hi = double.negativeInfinity;
    for (final List<double> row in matrix) {
      for (final double v in row) {
        lo = math.min(lo, v);
        hi = math.max(hi, v);
      }
    }
    double leftPad = 0;
    if (rowLabels != null) {
      for (final String s in rowLabels!) {
        leftPad = math.max(leftPad, _measure(s, r.labelStyle).width + 8);
      }
    }
    final double topPad = colLabels != null ? r.labelStyle.fontSize! + 8 : 0;
    final double cellW = (size.width - leftPad) / cols;
    final double cellH = (size.height - topPad) / rows;
    for (int rr = 0; rr < rows; rr++) {
      if (rowLabels != null && rr < rowLabels!.length) {
        _paintText(canvas, rowLabels![rr], Offset(leftPad - 6, topPad + rr * cellH + cellH / 2), r.labelStyle, anchor: Alignment.centerRight);
      }
      for (int cc = 0; cc < matrix[rr].length; cc++) {
        final double v = matrix[rr][cc];
        final double t = hi == lo ? 0.5 : (v - lo) / (hi - lo);
        final Rect cell = Rect.fromLTWH(leftPad + cc * cellW, topPad + rr * cellH, cellW, cellH).deflate(1.5);
        canvas.drawRRect(
          RRect.fromRectAndRadius(cell, const Radius.circular(3)),
          Paint()..color = base.withValues(alpha: (0.12 + 0.85 * t) * progress),
        );
        if (showValues && cellW > 26 && cellH > 18) {
          _paintText(canvas, _trim(v), cell.center, r.labelStyle.copyWith(color: t > 0.55 ? Colors.white : r.labelStyle.color, fontSize: r.labelStyle.fontSize! - 1));
        }
      }
    }
    if (colLabels != null) {
      for (int cc = 0; cc < cols; cc++) {
        if (cc < colLabels!.length) _paintText(canvas, colLabels![cc], Offset(leftPad + cc * cellW + cellW / 2, topPad - 4), r.labelStyle, anchor: Alignment.bottomCenter);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) => old.progress != progress || old.matrix != matrix;
}

class _WaterfallPainter extends CustomPainter {
  _WaterfallPainter({
    required this.items,
    required this.bounds,
    required this.labels,
    required this.r,
    required this.style,
    required this.up,
    required this.down,
    required this.totalColor,
    required this.cornerRadius,
    required this.progress,
  });

  final List<UWaterfallItem> items;
  final _Bounds bounds;
  final List<String>? labels;
  final _Resolved r;
  final UChartStyle style;
  final Color up;
  final Color down;
  final Color totalColor;
  final double cornerRadius;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final int n = items.length;
    final _Axes axes = _drawFrame(canvas, size, bounds, labels, n, r, showGrid: style.showGrid, showAxis: style.showAxis, showLabels: style.showLabels, bandMode: true);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(axes.plot.left, 0, axes.plot.width * progress + 1, size.height));
    final double slot = axes.bandWidth(n);
    double run = 0;
    double? prevRightY;
    double? prevRightX;
    for (int i = 0; i < n; i++) {
      final UWaterfallItem it = items[i];
      final double start = it.isTotal ? 0 : run;
      final double end = it.isTotal ? run : run + it.value;
      if (!it.isTotal) run += it.value;
      final double yStart = axes.y(start);
      final double yEnd = axes.y(end);
      final Color color = it.color ?? (it.isTotal ? totalColor : (it.value >= 0 ? up : down));
      final double left = axes.bandCenter(i, n) - slot * 0.3;
      final double right = axes.bandCenter(i, n) + slot * 0.3;
      _paintBar(canvas, Rect.fromLTRB(left, math.min(yStart, yEnd), right, math.max(yStart, yEnd)), color, cornerRadius, up: end >= start);
      if (prevRightY != null && prevRightX != null) {
        canvas.drawLine(
          Offset(prevRightX, prevRightY),
          Offset(left, yStart),
          Paint()
            ..color = r.axis.withValues(alpha: 0.6)
            ..strokeWidth = 1,
        );
      }
      prevRightY = yEnd;
      prevRightX = right;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaterfallPainter old) => old.progress != progress || old.items != items;
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color, required this.fill, required this.strokeWidth, required this.progress});

  final List<double> values;
  final Color color;
  final bool fill;
  final double strokeWidth;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    double lo = values.reduce(math.min);
    double hi = values.reduce(math.max);
    if (lo == hi) {
      lo -= 1;
      hi += 1;
    }
    final double pad = strokeWidth + 1;
    final List<Offset> pts = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final double x = pad + i / (values.length - 1) * (size.width - pad * 2);
      final double y = size.height - pad - (values[i] - lo) / (hi - lo) * (size.height - pad * 2);
      pts.add(Offset(x, y));
    }
    final Path line = _smoothPath(pts);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    if (fill) {
      final Path area = Path.from(line)
        ..lineTo(pts.last.dx, size.height)
        ..lineTo(pts.first.dx, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), <Color>[color.withValues(alpha: 0.35), color.withValues(alpha: 0.02)]),
      );
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.restore();
    final int last = (pts.length * progress).clamp(1, pts.length).toInt() - 1;
    canvas.drawCircle(pts[last], strokeWidth + 1, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.progress != progress || old.values != values;
}

/// A candlestick (OHLC body) chart for financial data.
class UCandlestickChart extends StatelessWidget {
  const UCandlestickChart({
    required this.candles,
    super.key,
    this.title,
    this.upColor,
    this.downColor,
    this.style = const UChartStyle(),
    this.height = 280,
  });

  final List<UCandle> candles;
  final String? title;
  final Color? upColor;
  final Color? downColor;
  final UChartStyle style;
  final double height;

  @override
  Widget build(BuildContext context) => _buildCandles(context, candles, title, upColor, downColor, style, height, ohlc: false);
}

/// An OHLC bar chart (open tick left, close tick right) for financial data.
class UOhlcChart extends StatelessWidget {
  const UOhlcChart({
    required this.candles,
    super.key,
    this.title,
    this.upColor,
    this.downColor,
    this.style = const UChartStyle(),
    this.height = 280,
  });

  final List<UCandle> candles;
  final String? title;
  final Color? upColor;
  final Color? downColor;
  final UChartStyle style;
  final double height;

  @override
  Widget build(BuildContext context) => _buildCandles(context, candles, title, upColor, downColor, style, height, ohlc: true);
}

Widget _buildCandles(BuildContext context, List<UCandle> candles, String? title, Color? upColor, Color? downColor, UChartStyle style, double height, {required bool ohlc}) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final _Resolved r = _resolve(context, style);
  final Color up = upColor ?? const Color(0xFF26A69A);
  final Color down = downColor ?? scheme.error;
  double lo = double.infinity;
  double hi = double.negativeInfinity;
  for (final UCandle c in candles) {
    lo = math.min(lo, c.low);
    hi = math.max(hi, c.high);
  }
  if (lo == double.infinity) {
    lo = 0;
    hi = 1;
  }
  final _Bounds bounds = _niceBounds(lo, hi, ticks: style.gridDivisions + 1, includeZero: false);
  final List<String>? labels = candles.any((UCandle c) => c.label != null) ? candles.map((UCandle c) => c.label ?? "").toList() : null;
  return _frameWith(
    style: style,
    height: height,
    background: r.background,
    title: title,
    legend: null,
    painterBuilder: (double t) => _CandlePainter(candles: candles, bounds: bounds, labels: labels, r: r, style: style, up: up, down: down, ohlc: ohlc, progress: t),
  );
}

/// A histogram of raw samples, bucketed into [bins] equal-width bars.
class UHistogramChart extends StatelessWidget {
  const UHistogramChart({
    required this.data,
    super.key,
    this.bins = 10,
    this.title,
    this.color,
    this.style = const UChartStyle(),
    this.height = 260,
  });

  final List<double> data;
  final int bins;
  final String? title;
  final Color? color;
  final UChartStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final _Resolved r = _resolve(context, style);
    final Color barColor = color ?? r.colorAt(0);
    final List<double> counts = List<double>.filled(bins, 0);
    final List<String> labels = List<String>.filled(bins, "");
    if (data.isNotEmpty) {
      double lo = data.reduce(math.min);
      double hi = data.reduce(math.max);
      if (lo == hi) {
        lo -= 1;
        hi += 1;
      }
      final double w = (hi - lo) / bins;
      for (final double v in data) {
        final int idx = ((v - lo) / w).floor().clamp(0, bins - 1);
        counts[idx] += 1;
      }
      for (int i = 0; i < bins; i++) {
        labels[i] = _trim(lo + w * i);
      }
    }
    final _Bounds bounds = _niceBounds(0, counts.isEmpty ? 1 : counts.reduce(math.max), ticks: style.gridDivisions + 1);
    return _frameWith(
      style: style,
      height: height,
      background: r.background,
      title: title,
      legend: null,
      painterBuilder: (double t) => _HistogramPainter(counts: counts, labels: labels, bounds: bounds, r: r, style: style, color: barColor, cornerRadius: style.cornerRadius, progress: t),
    );
  }
}

/// A heatmap of a 2-D matrix; cell color intensity encodes the value.
class UHeatmapChart extends StatelessWidget {
  const UHeatmapChart({
    required this.matrix,
    super.key,
    this.rowLabels,
    this.colLabels,
    this.title,
    this.color,
    this.style = const UChartStyle(),
    this.height = 280,
  });

  final List<List<double>> matrix;
  final List<String>? rowLabels;
  final List<String>? colLabels;
  final String? title;
  final Color? color;
  final UChartStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final _Resolved r = _resolve(context, style);
    final Color base = color ?? r.colorAt(0);
    return _frameWith(
      style: style,
      height: height,
      background: r.background,
      title: title,
      legend: null,
      painterBuilder: (double t) => _HeatmapPainter(matrix: matrix, rowLabels: rowLabels, colLabels: colLabels, base: base, r: r, showValues: style.showValues, progress: t),
    );
  }
}

/// A waterfall chart showing how sequential positive/negative changes build to
/// a total. Mark cumulative bars with [UWaterfallItem.isTotal].
class UWaterfallChart extends StatelessWidget {
  const UWaterfallChart({
    required this.items,
    super.key,
    this.title,
    this.upColor,
    this.downColor,
    this.totalColor,
    this.style = const UChartStyle(),
    this.height = 260,
  });

  final List<UWaterfallItem> items;
  final String? title;
  final Color? upColor;
  final Color? downColor;
  final Color? totalColor;
  final UChartStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final _Resolved r = _resolve(context, style);
    final Color up = upColor ?? const Color(0xFF26A69A);
    final Color down = downColor ?? scheme.error;
    final Color total = totalColor ?? scheme.primary;
    double run = 0;
    double lo = 0;
    double hi = 0;
    for (final UWaterfallItem it in items) {
      if (it.isTotal) {
        lo = math.min(lo, 0);
        hi = math.max(hi, run);
      } else {
        final double start = run;
        run += it.value;
        lo = math.min(lo, math.min(start, run));
        hi = math.max(hi, math.max(start, run));
      }
    }
    final _Bounds bounds = _niceBounds(lo, hi, ticks: style.gridDivisions + 1);
    final List<String>? labels = items.any((UWaterfallItem it) => it.label != null) ? items.map((UWaterfallItem it) => it.label ?? "").toList() : null;
    return _frameWith(
      style: style,
      height: height,
      background: r.background,
      title: title,
      legend: null,
      painterBuilder: (double t) =>
          _WaterfallPainter(items: items, bounds: bounds, labels: labels, r: r, style: style, up: up, down: down, totalColor: total, cornerRadius: style.cornerRadius, progress: t),
    );
  }
}

/// A tiny, axis-free trend line — perfect inside list tiles and stat cards.
class USparkline extends StatelessWidget {
  const USparkline({
    required this.values,
    super.key,
    this.color,
    this.fill = true,
    this.strokeWidth = 2,
    this.width = 120,
    this.height = 40,
    this.animate = true,
  });

  final List<double> values;
  final Color? color;
  final bool fill;
  final double strokeWidth;
  final double width;
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: width,
      height: height,
      child: UChartAnimator(
        animate: animate,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (double t) => CustomPaint(
          painter: _SparklinePainter(values: values, color: c, fill: fill, strokeWidth: strokeWidth, progress: t),
          size: Size.infinite,
        ),
      ),
    );
  }
}

// __CHARTS_END__
