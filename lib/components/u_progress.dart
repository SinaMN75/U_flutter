import "dart:math" as math;

import "package:flutter/material.dart";

typedef UProgressLabelBuilder = Widget? Function(BuildContext context, int? value);

class UProgressLinear extends StatefulWidget {
  const UProgressLinear({
    super.key,
    this.value,
    this.height = 8,
    this.width,
    this.borderRadius,
    this.backgroundColor,
    this.progressColor,
    this.gradient,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
    this.indeterminateDuration = const Duration(milliseconds: 1200),
    this.indeterminateSegmentFraction = 0.4,
    this.labelBuilder,
    this.axis = Axis.horizontal,
    this.reverse = false,
  });

  /// Progress from 0 to 100. Null shows an indeterminate animation.
  final int? value;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? progressColor;
  final Gradient? gradient;
  final Duration duration;
  final Curve curve;
  final Duration indeterminateDuration;
  final double indeterminateSegmentFraction;
  final UProgressLabelBuilder? labelBuilder;
  final Axis axis;
  final bool reverse;

  @override
  State<UProgressLinear> createState() => _UProgressLinearState();
}

class _UProgressLinearState extends State<UProgressLinear> with SingleTickerProviderStateMixin {
  late final AnimationController _indeterminateController = AnimationController(
    vsync: this,
    duration: widget.indeterminateDuration,
  )..repeat();

  @override
  void didUpdateWidget(covariant UProgressLinear oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.indeterminateDuration != widget.indeterminateDuration) {
      _indeterminateController.duration = widget.indeterminateDuration;
    }
  }

  @override
  void dispose() {
    _indeterminateController.dispose();
    super.dispose();
  }

  int? get _clampedValue => widget.value == null ? null : widget.value!.clamp(0, 100);

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color track = widget.backgroundColor ?? scheme.surfaceContainerHighest;
    final Color fill = widget.progressColor ?? scheme.primary;
    final BorderRadius radius = widget.borderRadius ?? BorderRadius.circular(widget.height / 2);
    final int? clamped = _clampedValue;
    final bool horizontal = widget.axis == Axis.horizontal;

    final Widget track$ = ClipRRect(
      borderRadius: radius,
      child: ColoredBox(
        color: track,
        child: clamped == null
            ? AnimatedBuilder(
                animation: _indeterminateController,
                builder: (BuildContext context, Widget? child) => CustomPaint(
                  painter: _IndeterminateLinearPainter(
                    progress: _indeterminateController.value,
                    segmentFraction: widget.indeterminateSegmentFraction,
                    color: fill,
                    gradient: widget.gradient,
                    axis: widget.axis,
                  ),
                  size: Size.infinite,
                ),
              )
            : TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: clamped / 100),
                duration: widget.duration,
                curve: widget.curve,
                builder: (BuildContext context, double fraction, Widget? child) => Align(
                  alignment: horizontal ? (widget.reverse ? Alignment.centerRight : Alignment.centerLeft) : (widget.reverse ? Alignment.bottomCenter : Alignment.topCenter),
                  child: FractionallySizedBox(
                    widthFactor: horizontal ? fraction : 1,
                    heightFactor: horizontal ? 1 : fraction,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.gradient == null ? fill : null,
                        gradient: widget.gradient,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );

    final Widget sized = SizedBox(
      height: horizontal ? widget.height : widget.width,
      width: horizontal ? widget.width : widget.height,
      child: track$,
    );

    final Widget? label = widget.labelBuilder?.call(context, clamped);
    return label == null ? sized : Stack(alignment: Alignment.center, children: <Widget>[sized, label]);
  }
}

class _IndeterminateLinearPainter extends CustomPainter {
  _IndeterminateLinearPainter({
    required this.progress,
    required this.segmentFraction,
    required this.color,
    required this.gradient,
    required this.axis,
  });

  final double progress;
  final double segmentFraction;
  final Color color;
  final Gradient? gradient;
  final Axis axis;

  @override
  void paint(Canvas canvas, Size size) {
    final double extent = axis == Axis.horizontal ? size.width : size.height;
    final double segment = extent * segmentFraction;
    // Slide the segment across the full track (plus its own length) so it enters and exits cleanly.
    final double travel = extent + segment;
    final double start = (progress * travel) - segment;
    final Rect rect = axis == Axis.horizontal ? Rect.fromLTWH(start, 0, segment, size.height) : Rect.fromLTWH(0, start, size.width, segment);
    final Paint paint = Paint();
    if (gradient != null) {
      paint.shader = gradient!.createShader(Offset.zero & size);
    } else {
      paint.color = color;
    }
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _IndeterminateLinearPainter oldDelegate) => oldDelegate.progress != progress;
}

/// A fully customizable circular progress ring.
///
/// Pass [value] between 0 and 100 for a determinate ring, or leave it null for
/// a spinning indeterminate arc. No percentage text is drawn unless you supply
/// [labelBuilder].
class UProgressCircular extends StatefulWidget {
  const UProgressCircular({
    super.key,
    this.value,
    this.size = 56,
    this.strokeWidth = 6,
    this.backgroundColor,
    this.progressColor,
    this.gradient,
    this.strokeCap = StrokeCap.round,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
    this.indeterminateDuration = const Duration(milliseconds: 1000),
    this.indeterminateSweep = 0.75,
    this.startAngle = -math.pi / 2,
    this.clockwise = true,
    this.labelBuilder,
  });

  /// Progress from 0 to 100. Null shows a spinning indeterminate arc.
  final int? value;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final Gradient? gradient;
  final StrokeCap strokeCap;
  final Duration duration;
  final Curve curve;
  final Duration indeterminateDuration;
  final double indeterminateSweep;
  final double startAngle;
  final bool clockwise;
  final UProgressLabelBuilder? labelBuilder;

  @override
  State<UProgressCircular> createState() => _UProgressCircularState();
}

class _UProgressCircularState extends State<UProgressCircular> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.indeterminateDuration,
  )..repeat();

  @override
  void didUpdateWidget(covariant UProgressCircular oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.indeterminateDuration != widget.indeterminateDuration) {
      _controller.duration = widget.indeterminateDuration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _clampedValue => widget.value == null ? null : widget.value!.clamp(0, 100);

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color track = widget.backgroundColor ?? scheme.surfaceContainerHighest;
    final Color fill = widget.progressColor ?? scheme.primary;
    final int? clamped = _clampedValue;

    final Widget painterWidget = clamped == null
        ? AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) => CustomPaint(
              painter: _CircularPainter(
                fraction: widget.indeterminateSweep,
                rotation: _controller.value * 2 * math.pi,
                trackColor: track,
                progressColor: fill,
                gradient: widget.gradient,
                strokeWidth: widget.strokeWidth,
                strokeCap: widget.strokeCap,
                startAngle: widget.startAngle,
                clockwise: widget.clockwise,
                drawTrack: false,
              ),
              size: Size.square(widget.size),
            ),
          )
        : TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: clamped / 100),
            duration: widget.duration,
            curve: widget.curve,
            builder: (BuildContext context, double fraction, Widget? child) => CustomPaint(
              painter: _CircularPainter(
                fraction: fraction,
                rotation: 0,
                trackColor: track,
                progressColor: fill,
                gradient: widget.gradient,
                strokeWidth: widget.strokeWidth,
                strokeCap: widget.strokeCap,
                startAngle: widget.startAngle,
                clockwise: widget.clockwise,
                drawTrack: true,
              ),
              size: Size.square(widget.size),
            ),
          );

    final Widget? label = widget.labelBuilder?.call(context, clamped);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: label == null ? painterWidget : Stack(alignment: Alignment.center, children: <Widget>[painterWidget, label]),
    );
  }
}

class _CircularPainter extends CustomPainter {
  _CircularPainter({
    required this.fraction,
    required this.rotation,
    required this.trackColor,
    required this.progressColor,
    required this.gradient,
    required this.strokeWidth,
    required this.strokeCap,
    required this.startAngle,
    required this.clockwise,
    required this.drawTrack,
  });

  final double fraction;
  final double rotation;
  final Color trackColor;
  final Color progressColor;
  final Gradient? gradient;
  final double strokeWidth;
  final StrokeCap strokeCap;
  final double startAngle;
  final bool clockwise;
  final bool drawTrack;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    if (drawTrack) {
      final Paint trackPaint = Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);
    }

    final Paint progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = strokeCap;
    if (gradient != null) {
      progressPaint.shader = gradient!.createShader(rect);
    } else {
      progressPaint.color = progressColor;
    }

    final double sweep = 2 * math.pi * fraction * (clockwise ? 1 : -1);
    canvas.drawArc(rect, startAngle + rotation, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.rotation != rotation ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.strokeCap != strokeCap;
}
