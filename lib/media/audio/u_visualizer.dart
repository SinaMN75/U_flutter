import "package:u/utilities.dart";

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
