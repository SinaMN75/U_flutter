import "package:u/utilities.dart";

class RatingWidget {
  RatingWidget({
    required this.full,
    required this.half,
    required this.empty,
  });

  final Widget full;

  final Widget half;

  final Widget empty;
}

class RatingBar extends StatefulWidget {
  const RatingBar({
    required this.onRatingUpdate,
    required RatingWidget ratingWidget,
    super.key,
    this.glowColor,
    this.maxRating,
    this.textDirection,
    this.unratedColor,
    this.allowHalfRating = false,
    this.direction = Axis.horizontal,
    this.glow = true,
    this.glowRadius = 2,
    this.ignoreGestures = false,
    this.initialRating = 0.0,
    this.itemCount = 5,
    this.itemPadding = EdgeInsets.zero,
    this.itemSize = 40.0,
    this.minRating = 0,
    this.tapOnlyMode = false,
    this.updateOnDrag = false,
    this.wrapAlignment = WrapAlignment.start,
  }) : _itemBuilder = null,
       _ratingWidget = ratingWidget;

  const RatingBar.builder({
    required this.onRatingUpdate,
    required IndexedWidgetBuilder itemBuilder,
    super.key,
    this.glowColor,
    this.maxRating,
    this.textDirection,
    this.unratedColor,
    this.allowHalfRating = false,
    this.direction = Axis.horizontal,
    this.glow = true,
    this.glowRadius = 2,
    this.ignoreGestures = false,
    this.initialRating = 0.0,
    this.itemCount = 5,
    this.itemPadding = EdgeInsets.zero,
    this.itemSize = 40.0,
    this.minRating = 0,
    this.tapOnlyMode = false,
    this.updateOnDrag = false,
    this.wrapAlignment = WrapAlignment.start,
  }) : _itemBuilder = itemBuilder,
       _ratingWidget = null;

  final ValueChanged<double> onRatingUpdate;

  final Color? glowColor;

  final double? maxRating;

  final TextDirection? textDirection;

  final Color? unratedColor;

  final bool allowHalfRating;

  final Axis direction;

  final bool glow;

  final double glowRadius;

  final bool ignoreGestures;

  final double initialRating;

  final int itemCount;

  final EdgeInsetsGeometry itemPadding;

  final double itemSize;

  final double minRating;

  final bool tapOnlyMode;

  final bool updateOnDrag;

  final WrapAlignment wrapAlignment;

  final IndexedWidgetBuilder? _itemBuilder;
  final RatingWidget? _ratingWidget;

  @override
  _RatingBarState createState() => _RatingBarState();
}

class _RatingBarState extends State<RatingBar> {
  double _rating = 0;
  bool _isRTL = false;
  double iconRating = 0;

  late double _minRating;
  late double _maxRating;
  late final ValueNotifier<bool> _glow;

  @override
  void initState() {
    super.initState();
    _glow = ValueNotifier<bool>(false);
    _minRating = widget.minRating;
    _maxRating = widget.maxRating ?? widget.itemCount.toDouble();
    _rating = widget.initialRating;
  }

  @override
  void didUpdateWidget(RatingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      _rating = widget.initialRating;
    }
    _minRating = widget.minRating;
    _maxRating = widget.maxRating ?? widget.itemCount.toDouble();
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextDirection textDirection = widget.textDirection ?? Directionality.of(context);
    _isRTL = textDirection == TextDirection.rtl;
    iconRating = 0.0;

    return Material(
      color: Colors.transparent,
      child: Wrap(
        textDirection: textDirection,
        direction: widget.direction,
        children: List<Widget>.generate(
          widget.itemCount,
          (int index) => _buildRating(context, index),
        ),
      ),
    );
  }

  Widget _buildRating(BuildContext context, int index) {
    final RatingWidget? ratingWidget = widget._ratingWidget;
    final Widget? item = widget._itemBuilder?.call(context, index);
    final double ratingOffset = widget.allowHalfRating ? 0.5 : 1.0;

    Widget ratingWidget0;

    if (index >= _rating) {
      ratingWidget0 = _NoRatingWidget(
        size: widget.itemSize,
        enableMask: ratingWidget == null,
        unratedColor: widget.unratedColor ?? Theme.of(context).disabledColor,
        child: ratingWidget?.empty ?? item!,
      );
    } else if (index >= _rating - ratingOffset && widget.allowHalfRating) {
      if (ratingWidget?.half == null) {
        ratingWidget0 = _HalfRatingWidget(
          size: widget.itemSize,
          enableMask: ratingWidget == null,
          rtlMode: _isRTL,
          unratedColor: widget.unratedColor ?? Theme.of(context).disabledColor,
          child: item!,
        );
      } else {
        ratingWidget0 = SizedBox(
          width: widget.itemSize,
          height: widget.itemSize,
          child: FittedBox(
            child: _isRTL
                ? Transform(
                    transform: Matrix4.identity()..scale(-1.0, 1, 1),
                    alignment: Alignment.center,
                    transformHitTests: false,
                    child: ratingWidget!.half,
                  )
                : ratingWidget!.half,
          ),
        );
      }
      iconRating += 0.5;
    } else {
      ratingWidget0 = SizedBox(
        width: widget.itemSize,
        height: widget.itemSize,
        child: FittedBox(
          child: ratingWidget?.full ?? item,
        ),
      );
      iconRating += 1.0;
    }

    return IgnorePointer(
      ignoring: widget.ignoreGestures,
      child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          double value;
          if (index == 0 && (_rating == 1 || _rating == 0.5)) {
            value = 0;
          } else {
            final double tappedPosition = details.localPosition.dx;
            final bool tappedOnFirstHalf = tappedPosition <= widget.itemSize / 2;
            value = index + (tappedOnFirstHalf && widget.allowHalfRating ? 0.5 : 1.0);
          }

          value = max(value, widget.minRating);
          widget.onRatingUpdate(value);
          _rating = value;
          setState(() {});
        },
        onHorizontalDragStart: _isHorizontal ? _onDragStart : null,
        onHorizontalDragEnd: _isHorizontal ? _onDragEnd : null,
        onHorizontalDragUpdate: _isHorizontal ? _onDragUpdate : null,
        onVerticalDragStart: _isHorizontal ? null : _onDragStart,
        onVerticalDragEnd: _isHorizontal ? null : _onDragEnd,
        onVerticalDragUpdate: _isHorizontal ? null : _onDragUpdate,
        child: Padding(
          padding: widget.itemPadding,
          child: ValueListenableBuilder<bool>(
            valueListenable: _glow,
            builder: (BuildContext context, bool glow, Widget? child) {
              if (glow && widget.glow) {
                final Color glowColor = widget.glowColor ?? Theme.of(context).colorScheme.secondary;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: glowColor.withAlpha(30),
                        blurRadius: 10,
                        spreadRadius: widget.glowRadius,
                      ),
                      BoxShadow(
                        color: glowColor.withAlpha(20),
                        blurRadius: 10,
                        spreadRadius: widget.glowRadius,
                      ),
                    ],
                  ),
                  child: child,
                );
              }
              return child!;
            },
            child: ratingWidget0,
          ),
        ),
      ),
    );
  }

  bool get _isHorizontal => widget.direction == Axis.horizontal;

  void _onDragUpdate(DragUpdateDetails dragDetails) {
    if (!widget.tapOnlyMode) {
      final RenderBox? box = navigatorKey.currentContext!.findRenderObject() as RenderBox?;
      if (box == null) return;

      final Offset pos = box.globalToLocal(dragDetails.globalPosition);
      double i;
      if (widget.direction == Axis.horizontal) {
        i = pos.dx / (widget.itemSize + widget.itemPadding.horizontal);
      } else {
        i = pos.dy / (widget.itemSize + widget.itemPadding.vertical);
      }
      double currentRating = widget.allowHalfRating ? i : i.round().toDouble();
      if (currentRating > widget.itemCount) {
        currentRating = widget.itemCount.toDouble();
      }
      if (currentRating < 0) {
        currentRating = 0.0;
      }
      if (_isRTL && widget.direction == Axis.horizontal) {
        currentRating = widget.itemCount - currentRating;
      }

      _rating = currentRating.clamp(_minRating, _maxRating);
      if (widget.updateOnDrag) widget.onRatingUpdate(iconRating);
      setState(() {});
    }
  }

  void _onDragStart(DragStartDetails details) {
    _glow.value = true;
  }

  void _onDragEnd(DragEndDetails details) {
    _glow.value = false;
    widget.onRatingUpdate(iconRating);
    iconRating = 0.0;
  }
}

class _HalfRatingWidget extends StatelessWidget {
  const _HalfRatingWidget({
    required this.size,
    required this.child,
    required this.enableMask,
    required this.rtlMode,
    required this.unratedColor,
  });

  final Widget child;
  final double size;
  final bool enableMask;
  final bool rtlMode;
  final Color unratedColor;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: size,
    width: size,
    child: enableMask
        ? Stack(
            fit: StackFit.expand,
            children: <Widget>[
              FittedBox(
                child: _NoRatingWidget(
                  size: size,
                  unratedColor: unratedColor,
                  enableMask: enableMask,
                  child: child,
                ),
              ),
              FittedBox(
                child: ClipRect(
                  clipper: _HalfClipper(
                    rtlMode: rtlMode,
                  ),
                  child: child,
                ),
              ),
            ],
          )
        : FittedBox(
            child: child,
          ),
  );
}

class _HalfClipper extends CustomClipper<Rect> {
  _HalfClipper({required this.rtlMode});

  final bool rtlMode;

  @override
  Rect getClip(Size size) => rtlMode
      ? Rect.fromLTRB(
          size.width / 2,
          0,
          size.width,
          size.height,
        )
      : Rect.fromLTRB(
          0,
          0,
          size.width / 2,
          size.height,
        );

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => true;
}

class _NoRatingWidget extends StatelessWidget {
  const _NoRatingWidget({
    required this.size,
    required this.child,
    required this.enableMask,
    required this.unratedColor,
  });

  final double size;
  final Widget child;
  final bool enableMask;
  final Color unratedColor;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: size,
    width: size,
    child: FittedBox(
      child: enableMask
          ? ColorFiltered(
              colorFilter: ColorFilter.mode(
                unratedColor,
                BlendMode.srcIn,
              ),
              child: child,
            )
          : child,
    ),
  );
}

class RatingBarIndicator extends StatefulWidget {
  const RatingBarIndicator({
    required this.itemBuilder,
    super.key,
    this.textDirection,
    this.unratedColor,
    this.direction = Axis.horizontal,
    this.itemCount = 5,
    this.itemPadding = EdgeInsets.zero,
    this.itemSize = 40.0,
    this.physics = const NeverScrollableScrollPhysics(),
    this.rating = 0.0,
  });

  final IndexedWidgetBuilder itemBuilder;

  final TextDirection? textDirection;

  final Color? unratedColor;

  final Axis direction;

  final int itemCount;

  final EdgeInsets itemPadding;

  final double itemSize;

  final ScrollPhysics physics;

  final double rating;

  @override
  _RatingBarIndicatorState createState() => _RatingBarIndicatorState();
}

class _RatingBarIndicatorState extends State<RatingBarIndicator> {
  double _ratingFraction = 0;
  int _ratingNumber = 0;
  bool _isRTL = false;

  @override
  void initState() {
    super.initState();
    _ratingNumber = widget.rating.truncate() + 1;
    _ratingFraction = widget.rating - _ratingNumber + 1;
  }

  @override
  Widget build(BuildContext context) {
    final TextDirection textDirection = widget.textDirection ?? Directionality.of(context);
    _isRTL = textDirection == TextDirection.rtl;
    _ratingNumber = widget.rating.truncate() + 1;
    _ratingFraction = widget.rating - _ratingNumber + 1;
    return SingleChildScrollView(
      scrollDirection: widget.direction,
      physics: widget.physics,
      child: widget.direction == Axis.horizontal
          ? Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: textDirection,
              children: _children,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              textDirection: textDirection,
              children: _children,
            ),
    );
  }

  List<Widget> get _children => List<Widget>.generate(
    widget.itemCount,
    (int index) {
      if (widget.textDirection != null) {
        if (widget.textDirection == TextDirection.rtl && Directionality.of(navigatorKey.currentContext!) != TextDirection.rtl) {
          return Transform(
            transform: Matrix4.identity()..scale(-1.0, 1, 1),
            alignment: Alignment.center,
            transformHitTests: false,
            child: _buildItems(index),
          );
        }
      }
      return _buildItems(index);
    },
  );

  Widget _buildItems(int index) => Padding(
    padding: widget.itemPadding,
    child: SizedBox(
      width: widget.itemSize,
      height: widget.itemSize,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          FittedBox(
            child: index + 1 < _ratingNumber
                ? widget.itemBuilder(navigatorKey.currentContext!, index)
                : ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      widget.unratedColor ?? Theme.of(navigatorKey.currentContext!).disabledColor,
                      BlendMode.srcIn,
                    ),
                    child: widget.itemBuilder(navigatorKey.currentContext!, index),
                  ),
          ),
          if (index + 1 == _ratingNumber)
            if (_isRTL)
              FittedBox(
                child: ClipRect(
                  clipper: _IndicatorClipper(
                    ratingFraction: _ratingFraction,
                    rtlMode: _isRTL,
                  ),
                  child: widget.itemBuilder(navigatorKey.currentContext!, index),
                ),
              )
            else
              FittedBox(
                child: ClipRect(
                  clipper: _IndicatorClipper(
                    ratingFraction: _ratingFraction,
                  ),
                  child: widget.itemBuilder(navigatorKey.currentContext!, index),
                ),
              ),
        ],
      ),
    ),
  );
}

class _IndicatorClipper extends CustomClipper<Rect> {
  _IndicatorClipper({
    required this.ratingFraction,
    this.rtlMode = false,
  });

  final double ratingFraction;
  final bool rtlMode;

  @override
  Rect getClip(Size size) => rtlMode
      ? Rect.fromLTRB(
          size.width - size.width * ratingFraction,
          0,
          size.width,
          size.height,
        )
      : Rect.fromLTRB(
          0,
          0,
          size.width * ratingFraction,
          size.height,
        );

  @override
  bool shouldReclip(_IndicatorClipper oldClipper) => ratingFraction != oldClipper.ratingFraction || rtlMode != oldClipper.rtlMode;
}
