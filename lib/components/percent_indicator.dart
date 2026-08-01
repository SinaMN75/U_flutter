import "dart:math";

import "package:flutter/material.dart";

enum ArcType { HALF, FULL }

enum CircularStrokeCap { butt, round, square }

extension CircularStrokeCapExtension on CircularStrokeCap {
  StrokeCap get strokeCap {
    switch (this) {
      case CircularStrokeCap.butt:
        return StrokeCap.butt;
      case CircularStrokeCap.round:
        return StrokeCap.round;
      case CircularStrokeCap.square:
        return StrokeCap.square;
    }
  }
}

num radians(num deg) => deg * (pi / 180.0);

class CircularPercentIndicator extends StatefulWidget {
  CircularPercentIndicator({
    required this.radius,
    super.key,
    this.percent = 0.0,
    this.lineWidth = 5.0,
    this.startAngle = 0.0,
    this.fillColor = Colors.transparent,
    this.backgroundColor = const Color(0xFFB8C7CB),
    this.progressColor,
    this.backgroundWidth = -1,
    this.linearGradient,
    this.animation = false,
    this.animationDuration = 500,
    this.header,
    this.footer,
    this.center,
    this.addAutomaticKeepAlive = true,
    this.circularStrokeCap = CircularStrokeCap.butt,
    this.arcBackgroundColor,
    this.arcType,
    this.animateFromLastPercent = false,
    this.reverse = false,
    this.curve = Curves.linear,
    this.maskFilter,
    this.restartAnimation = false,
    this.onAnimationEnd,
    this.widgetIndicator,
    this.rotateLinearGradient = false,
  }) {
    if (linearGradient != null && progressColor != null) {
      throw ArgumentError("Cannot provide both linearGradient and progressColor");
    }
    assert(startAngle >= 0.0);
    if (percent < 0.0 || percent > 1.0) {
      throw Exception("Percent value must be a double between 0.0 and 1.0, but it's $percent");
    }
    if (arcType == null && arcBackgroundColor != null) {
      throw ArgumentError("arcType is required when you arcBackgroundColor");
    }
  }

  final double percent;
  final double radius;
  final double lineWidth;
  final double backgroundWidth;
  final Color fillColor;
  final Color backgroundColor;
  final Color? progressColor;
  final bool animation;
  final int animationDuration;
  final Widget? header;
  final Widget? footer;
  final Widget? center;
  final LinearGradient? linearGradient;
  final CircularStrokeCap circularStrokeCap;
  final double startAngle;
  final bool animateFromLastPercent;
  final bool addAutomaticKeepAlive;
  final ArcType? arcType;
  final Color? arcBackgroundColor;
  final bool reverse;
  final MaskFilter? maskFilter;
  final Curve curve;
  final bool restartAnimation;
  final VoidCallback? onAnimationEnd;
  final Widget? widgetIndicator;
  final bool rotateLinearGradient;

  @override
  _CircularPercentIndicatorState createState() => _CircularPercentIndicatorState();
}

class _CircularPercentIndicatorState extends State<CircularPercentIndicator> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  AnimationController? _animationController;
  late Animation<double> _animation;
  double _percent = 0;
  double _diameter = 0;

  @override
  void dispose() {
    if (_animationController != null) {
      _animationController!.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    if (widget.animation) {
      _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.animationDuration),
      );
      _animation =
          Tween<double>(begin: 0, end: widget.percent).animate(
            CurvedAnimation(parent: _animationController!, curve: widget.curve),
          )..addListener(() {
            setState(() {
              _percent = _animation.value;
            });
            if (widget.restartAnimation && _percent == 1.0) {
              _animationController!.repeat(min: 0, max: 1);
            }
          });
      _animationController!.addStatusListener((AnimationStatus status) {
        if (widget.onAnimationEnd != null && status == AnimationStatus.completed) {
          widget.onAnimationEnd!();
        }
      });
      _animationController!.forward();
    } else {
      _updateProgress();
    }
    _diameter = widget.radius * 2;
    super.initState();
  }

  void _checkIfNeedCancelAnimation(CircularPercentIndicator oldWidget) {
    if (oldWidget.animation && !widget.animation && _animationController != null) {
      _animationController!.stop();
    }
  }

  @override
  void didUpdateWidget(CircularPercentIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent || oldWidget.startAngle != widget.startAngle) {
      if (_animationController != null) {
        _animationController!.duration = Duration(milliseconds: widget.animationDuration);
        _animation =
            Tween<double>(
              begin: widget.animateFromLastPercent ? oldWidget.percent : 0.0,
              end: widget.percent,
            ).animate(
              CurvedAnimation(parent: _animationController!, curve: widget.curve),
            );
        _animationController!.forward(from: 0);
      } else {
        _updateProgress();
      }
    }
    _checkIfNeedCancelAnimation(oldWidget);
  }

  void _updateProgress() {
    setState(() => _percent = widget.percent);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final List<Widget> items = List<Widget>.empty(growable: true);
    if (widget.header != null) {
      items.add(widget.header!);
    }
    items.add(
      SizedBox(
        height: _diameter,
        width: _diameter,
        child: Stack(
          children: <Widget>[
            CustomPaint(
              painter: _CirclePainter(
                progress: _percent * 360,
                progressColor: widget.progressColor ?? Theme.of(context).colorScheme.primary,
                backgroundColor: widget.backgroundColor,
                startAngle: widget.startAngle,
                circularStrokeCap: widget.circularStrokeCap,
                radius: widget.radius - widget.lineWidth / 2,
                lineWidth: widget.lineWidth,
                backgroundWidth: widget.backgroundWidth >= 0.0 ? (widget.backgroundWidth) : widget.lineWidth,
                arcBackgroundColor: widget.arcBackgroundColor,
                arcType: widget.arcType,
                reverse: widget.reverse,
                linearGradient: widget.linearGradient,
                maskFilter: widget.maskFilter,
                rotateLinearGradient: widget.rotateLinearGradient,
              ),
              child: (widget.center != null) ? Center(child: widget.center) : const SizedBox.expand(),
            ),
            if (widget.widgetIndicator != null && widget.animation)
              Positioned.fill(
                child: Transform.rotate(
                  angle: radians((widget.circularStrokeCap != CircularStrokeCap.butt && widget.reverse) ? -15 : 0).toDouble(),
                  child: Transform.rotate(
                    angle: getCurrentPercent(_percent),
                    child: Transform.translate(
                      offset: Offset(
                        (widget.circularStrokeCap != CircularStrokeCap.butt) ? widget.lineWidth / 2 : 0,
                        (-widget.radius + widget.lineWidth / 2),
                      ),
                      child: widget.widgetIndicator,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (widget.footer != null) {
      items.add(widget.footer!);
    }
    return Material(
      color: widget.fillColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: items,
      ),
    );
  }

  double getCurrentPercent(double percent) {
    if (widget.arcType != null) {
      final double angle = _getStartAngleFixedMargin(widget.arcType!).fixedStartAngle;
      final double fixedPercent = 1.0 / widget.percent * _percent;
      late double margin;
      if (widget.arcType == ArcType.HALF) {
        margin = 180 * widget.percent;
      } else {
        margin = 270 * widget.percent;
      }
      return radians(angle + margin * fixedPercent).toDouble();
    } else {
      const int angle = 360;
      return radians((widget.reverse ? -angle : angle) * _percent).toDouble();
    }
  }

  @override
  bool get wantKeepAlive => widget.addAutomaticKeepAlive;
}

_ArcAngles _getStartAngleFixedMargin(ArcType arcType) {
  double fixedStartAngle;
  double startAngleFixedMargin;
  if (arcType == ArcType.FULL) {
    fixedStartAngle = 220;
    startAngleFixedMargin = 172 / fixedStartAngle;
  } else {
    fixedStartAngle = 270;
    startAngleFixedMargin = 135 / fixedStartAngle;
  }
  return _ArcAngles(
    fixedStartAngle: fixedStartAngle,
    startAngleFixedMargin: startAngleFixedMargin,
  );
}

class _ArcAngles {
  const _ArcAngles({required this.fixedStartAngle, required this.startAngleFixedMargin});

  final double fixedStartAngle;
  final double startAngleFixedMargin;
}

class _CirclePainter extends CustomPainter {
  _CirclePainter({
    required this.lineWidth,
    required this.backgroundWidth,
    required this.progress,
    required this.radius,
    required this.progressColor,
    required this.backgroundColor,
    required this.reverse,
    required this.rotateLinearGradient,
    this.startAngle = 0.0,
    this.circularStrokeCap = CircularStrokeCap.butt,
    this.linearGradient,
    this.arcBackgroundColor,
    this.arcType,
    this.maskFilter,
  }) {
    _paintBackground.color = backgroundColor;
    _paintBackground.style = PaintingStyle.stroke;
    _paintBackground.strokeWidth = backgroundWidth;
    _paintBackground.strokeCap = circularStrokeCap.strokeCap;
    if (arcBackgroundColor != null) {
      _paintBackgroundStartAngle.color = arcBackgroundColor!;
      _paintBackgroundStartAngle.style = PaintingStyle.stroke;
      _paintBackgroundStartAngle.strokeWidth = lineWidth;
      _paintBackgroundStartAngle.strokeCap = circularStrokeCap.strokeCap;
    }
    _paintLine.color = progressColor;
    _paintLine.style = PaintingStyle.stroke;
    _paintLine.strokeWidth = lineWidth;
    _paintLine.strokeCap = circularStrokeCap.strokeCap;
  }

  final Paint _paintBackground = Paint();
  final Paint _paintLine = Paint();
  final Paint _paintBackgroundStartAngle = Paint();
  final double lineWidth;
  final double backgroundWidth;
  final double progress;
  final double radius;
  final Color progressColor;
  final Color backgroundColor;
  final CircularStrokeCap circularStrokeCap;
  final double startAngle;
  final LinearGradient? linearGradient;
  final Color? arcBackgroundColor;
  final ArcType? arcType;
  final bool reverse;
  final MaskFilter? maskFilter;
  final bool rotateLinearGradient;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    double fixedStartAngle = startAngle;
    double startAngleFixedMargin = 1;
    if (arcType != null) {
      final _ArcAngles arcAngles = _getStartAngleFixedMargin(arcType!);
      fixedStartAngle = arcAngles.fixedStartAngle;
      startAngleFixedMargin = arcAngles.startAngleFixedMargin;
    }
    if (arcType == null) {
      canvas.drawCircle(center, radius, _paintBackground);
    }
    if (maskFilter != null) {
      _paintLine.maskFilter = maskFilter;
    }
    if (linearGradient != null) {
      if (rotateLinearGradient && progress > 0) {
        double correction = 0;
        if (_paintLine.strokeCap != StrokeCap.butt) {
          correction = atan(_paintLine.strokeWidth / 2 / radius);
        }
        _paintLine.shader =
            SweepGradient(
              transform: reverse ? GradientRotation(radians(-90 - progress + startAngle) - correction) : GradientRotation(radians(-90.0 + startAngle) - correction),
              startAngle: radians(0).toDouble(),
              endAngle: radians(progress).toDouble(),
              colors: reverse ? linearGradient!.colors.reversed.toList() : linearGradient!.colors,
            ).createShader(
              Rect.fromCircle(center: center, radius: radius),
            );
      } else if (!rotateLinearGradient) {
        _paintLine.shader = linearGradient!.createShader(
          Rect.fromCircle(center: center, radius: radius),
        );
      }
    }
    if (arcBackgroundColor != null) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        radians(-90.0 + fixedStartAngle).toDouble(),
        radians(360 * startAngleFixedMargin).toDouble(),
        false,
        _paintBackgroundStartAngle,
      );
    }
    if (reverse) {
      final double start = radians(360 * startAngleFixedMargin - 90.0 + fixedStartAngle).toDouble();
      final double end = radians(-progress * startAngleFixedMargin).toDouble();
      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        start,
        end,
        false,
        _paintLine,
      );
    } else {
      final double start = radians(-90.0 + fixedStartAngle).toDouble();
      final double end = radians(progress * startAngleFixedMargin).toDouble();
      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        start,
        end,
        false,
        _paintLine,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class LinearPercentIndicator extends StatefulWidget {
  LinearPercentIndicator({
    super.key,
    this.fillColor = Colors.transparent,
    this.percent = 0.0,
    this.lineHeight = 5.0,
    this.width,
    this.backgroundColor = Colors.transparent,
    this.linearGradientBackgroundColor,
    this.linearGradient,
    this.progressColor = Colors.blue,
    this.animation = false,
    this.animationDuration = 500,
    this.animateFromLastPercent = false,
    this.isRTL = false,
    this.leading,
    this.trailing,
    this.center,
    this.addAutomaticKeepAlive = true,
    this.barRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
    this.alignment = MainAxisAlignment.start,
    this.maskFilter,
    this.clipLinearGradient = false,
    this.curve = Curves.linear,
    this.restartAnimation = false,
    this.onAnimationEnd,
    this.widgetIndicator,
  }) {
    if (linearGradient != null) {
      throw ArgumentError("Cannot provide both linearGradient and progressColor");
    }
    if (linearGradientBackgroundColor != null) {
      throw ArgumentError("Cannot provide both linearGradientBackgroundColor and backgroundColor");
    }
    if (percent < 0.0 || percent > 1.0) {
      throw Exception("Percent value must be a double between 0.0 and 1.0, but it's $percent");
    }
  }

  final double percent;
  final double? width;
  final double lineHeight;
  final Color fillColor;
  final Color backgroundColor;
  final LinearGradient? linearGradientBackgroundColor;
  final Color progressColor;
  final bool animation;
  final int animationDuration;
  final Widget? leading;
  final Widget? trailing;
  final Widget? center;
  final Radius? barRadius;
  final MainAxisAlignment alignment;
  final EdgeInsets padding;
  final bool animateFromLastPercent;
  final LinearGradient? linearGradient;
  final bool addAutomaticKeepAlive;
  final bool isRTL;
  final MaskFilter? maskFilter;
  final bool clipLinearGradient;
  final Curve curve;
  final bool restartAnimation;
  final VoidCallback? onAnimationEnd;
  final Widget? widgetIndicator;

  @override
  _LinearPercentIndicatorState createState() => _LinearPercentIndicatorState();
}

class _LinearPercentIndicatorState extends State<LinearPercentIndicator> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  AnimationController? _animationController;
  late Animation<double> _animation;
  double _percent = 0;
  final GlobalKey<State<StatefulWidget>> _containerKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _keyIndicator = GlobalKey();
  double _containerWidth = 0;
  double _containerHeight = 0;
  double _indicatorWidth = 0;
  double _indicatorHeight = 0;

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _containerWidth = _containerKey.currentContext?.size?.width ?? 0.0;
          _containerHeight = _containerKey.currentContext?.size?.height ?? 0.0;
          if (_keyIndicator.currentContext != null) {
            _indicatorWidth = _keyIndicator.currentContext?.size?.width ?? 0.0;
            _indicatorHeight = _keyIndicator.currentContext?.size?.height ?? 0.0;
          }
        });
      }
    });
    if (widget.animation) {
      _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.animationDuration),
      );
      _animation =
          Tween<double>(begin: 0, end: widget.percent).animate(
            CurvedAnimation(parent: _animationController!, curve: widget.curve),
          )..addListener(() {
            setState(() {
              _percent = _animation.value;
            });
            if (widget.restartAnimation && _percent == 1.0) {
              _animationController!.repeat(min: 0, max: 1);
            }
          });
      _animationController!.addStatusListener((AnimationStatus status) {
        if (widget.onAnimationEnd != null && status == AnimationStatus.completed) {
          widget.onAnimationEnd!();
        }
      });
      _animationController!.forward();
    } else {
      _updateProgress();
    }
    super.initState();
  }

  void _checkIfNeedCancelAnimation(LinearPercentIndicator oldWidget) {
    if (oldWidget.animation && !widget.animation && _animationController != null) {
      _animationController!.stop();
    }
  }

  @override
  void didUpdateWidget(LinearPercentIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent) {
      if (_animationController != null) {
        _animationController!.duration = Duration(milliseconds: widget.animationDuration);
        _animation = Tween<double>(begin: widget.animateFromLastPercent ? oldWidget.percent : 0.0, end: widget.percent).animate(
          CurvedAnimation(parent: _animationController!, curve: widget.curve),
        );
        _animationController!.forward(from: 0);
      } else {
        _updateProgress();
      }
    }
    _checkIfNeedCancelAnimation(oldWidget);
  }

  void _updateProgress() {
    setState(() {
      _percent = widget.percent;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final List<Widget> items = List<Widget>.empty(growable: true);
    if (widget.leading != null) {
      items.add(widget.leading!);
    }
    final bool hasSetWidth = widget.width != null;
    final double percentPositionedHorizontal = _containerWidth * _percent - _indicatorWidth / 3;
    final Container containerWidget = Container(
      width: hasSetWidth ? widget.width : double.infinity,
      height: widget.lineHeight,
      padding: widget.padding,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          CustomPaint(
            key: _containerKey,
            painter: _LinearPainter(
              isRTL: widget.isRTL,
              progress: _percent,
              progressColor: widget.progressColor,
              linearGradient: widget.linearGradient,
              backgroundColor: widget.backgroundColor,
              barRadius: widget.barRadius ?? Radius.zero,
              linearGradientBackgroundColor: widget.linearGradientBackgroundColor,
              maskFilter: widget.maskFilter,
              clipLinearGradient: widget.clipLinearGradient,
            ),
            child: (widget.center != null) ? Center(child: widget.center) : Container(),
          ),
          if (widget.widgetIndicator != null && _indicatorWidth == 0)
            Opacity(
              opacity: 0,
              key: _keyIndicator,
              child: widget.widgetIndicator,
            ),
          if (widget.widgetIndicator != null && _containerWidth > 0 && _indicatorWidth > 0)
            Positioned(
              right: widget.isRTL ? percentPositionedHorizontal : null,
              left: !widget.isRTL ? percentPositionedHorizontal : null,
              top: _containerHeight / 2 - _indicatorHeight,
              child: widget.widgetIndicator!,
            ),
        ],
      ),
    );
    if (hasSetWidth) {
      items.add(containerWidget);
    } else {
      items.add(
        Expanded(
          child: containerWidget,
        ),
      );
    }
    if (widget.trailing != null) {
      items.add(widget.trailing!);
    }
    return Material(
      color: Colors.transparent,
      child: Container(
        color: widget.fillColor,
        child: Row(
          mainAxisAlignment: widget.alignment,
          children: items,
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => widget.addAutomaticKeepAlive;
}

class _LinearPainter extends CustomPainter {
  _LinearPainter({
    required this.progress,
    required this.isRTL,
    required this.progressColor,
    required this.backgroundColor,
    required this.barRadius,
    required this.clipLinearGradient,
    this.linearGradient,
    this.maskFilter,
    this.linearGradientBackgroundColor,
  }) {
    _paintBackground.color = backgroundColor;
    _paintLine.color = progress.toString() == "0.0" ? progressColor.withValues(alpha: 0) : progressColor;
  }

  final Paint _paintBackground = Paint();
  final Paint _paintLine = Paint();
  final double progress;
  final bool isRTL;
  final Color progressColor;
  final Color backgroundColor;
  final Radius barRadius;
  final LinearGradient? linearGradient;
  final LinearGradient? linearGradientBackgroundColor;
  final MaskFilter? maskFilter;
  final bool clipLinearGradient;

  @override
  void paint(Canvas canvas, Size size) {
    final Path backgroundPath = Path();
    backgroundPath.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), barRadius));
    canvas.drawPath(backgroundPath, _paintBackground);
    if (maskFilter != null) {
      _paintLine.maskFilter = maskFilter;
    }
    if (linearGradientBackgroundColor != null) {
      final Offset shaderEndPoint = clipLinearGradient ? Offset.zero : Offset(size.width, size.height);
      _paintBackground.shader = linearGradientBackgroundColor?.createShader(Rect.fromPoints(Offset.zero, shaderEndPoint));
    }
    final double xProgress = size.width * progress;
    final Path linePath = Path();
    if (isRTL) {
      if (linearGradient != null) {
        _paintLine.shader = _createGradientShaderRightToLeft(size, xProgress);
      }
      linePath.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width - size.width * progress, 0, xProgress, size.height), barRadius));
    } else {
      if (linearGradient != null) {
        _paintLine.shader = _createGradientShaderLeftToRight(size, xProgress);
      }
      linePath.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, xProgress, size.height), barRadius));
    }
    canvas.drawPath(linePath, _paintLine);
  }

  Shader _createGradientShaderRightToLeft(Size size, double xProgress) {
    final Offset shaderEndPoint = clipLinearGradient ? Offset.zero : Offset(xProgress, size.height);
    return linearGradient!.createShader(
      Rect.fromPoints(
        Offset(size.width, size.height),
        shaderEndPoint,
      ),
    );
  }

  Shader _createGradientShaderLeftToRight(Size size, double xProgress) {
    final Offset shaderEndPoint = clipLinearGradient ? Offset(size.width, size.height) : Offset(xProgress, size.height);
    return linearGradient!.createShader(
      Rect.fromPoints(
        Offset.zero,
        shaderEndPoint,
      ),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
