import "package:u/utilities.dart";

enum BadgeAnimationType {
  slide,
  scale,
  fade,
}

class BadgeWidget extends StatefulWidget {
  const BadgeWidget({
    super.key,
    this.badgeContent,
    this.child,
    this.badgeColor = Colors.red,
    this.elevation = 2,
    this.toAnimate = true,
    this.position,
    this.shape = BadgeShape.circle,
    this.padding = const EdgeInsets.all(5),
    this.animationDuration = const Duration(milliseconds: 500),
    this.borderRadius = BorderRadius.zero,
    this.alignment = Alignment.center,
    this.animationType = BadgeAnimationType.slide,
    this.showBadge = true,
    this.ignorePointer = false,
    this.borderSide = BorderSide.none,
    this.stackFit = StackFit.loose,
    this.gradient,
  });

  final Widget? child;

  final AlignmentGeometry alignment;

  final BadgePosition? position;

  final Widget? badgeContent;

  final bool ignorePointer;

  final Color badgeColor;

  final Gradient? gradient;

  final double elevation;

  final bool toAnimate;

  final Duration animationDuration;

  final BadgeAnimationType animationType;

  final BadgeShape shape;

  final BorderSide borderSide;

  final StackFit stackFit;

  final BorderRadiusGeometry borderRadius;

  final EdgeInsetsGeometry padding;

  final bool showBadge;

  @override
  BadgeState createState() => BadgeState();
}

class BadgeState extends State<BadgeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  final Tween<Offset> _positionTween = Tween<Offset>(begin: const Offset(-0.5, 0.9), end: Offset.zero);
  final Tween<double> _scaleTween = Tween<double>(begin: 0.1, end: 1);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    if (widget.animationType == BadgeAnimationType.slide) {
      _animation = CurvedAnimation(parent: _animationController, curve: Curves.elasticOut);
    } else if (widget.animationType == BadgeAnimationType.scale) {
      _animation = _scaleTween.animate(_animationController);
    } else if (widget.animationType == BadgeAnimationType.fade) {
      _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    }

    _animationController.forward();
  }

  @override
  Widget build(final BuildContext context) {
    if (widget.child == null) {
      return _getBadge();
    } else {
      return Stack(
        fit: widget.stackFit,
        alignment: widget.alignment,
        clipBehavior: Clip.none,
        children: <Widget>[
          widget.child!,
          BadgePositioned(
            position: widget.position,
            child: widget.ignorePointer ? IgnorePointer(child: _getBadge()) : _getBadge(),
          ),
        ],
      );
    }
  }

  Widget _getBadge() {
    final OutlinedBorder border = widget.shape == BadgeShape.circle
        ? CircleBorder(side: widget.borderSide)
        : RoundedRectangleBorder(
            side: widget.borderSide,
            borderRadius: widget.borderRadius,
          );

    Widget badgeView() => AnimatedOpacity(
      opacity: widget.showBadge ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: Material(
        shape: border,
        elevation: widget.elevation,
        color: widget.badgeColor,
        child: Padding(padding: widget.padding, child: widget.badgeContent),
      ),
    );

    Widget badgeViewGradient() => AnimatedOpacity(
      opacity: widget.showBadge ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: Material(
        shape: border,
        elevation: widget.elevation,
        child: DecoratedBox(
          decoration: widget.shape == BadgeShape.circle
              ? BoxDecoration(gradient: widget.gradient, shape: BoxShape.circle)
              : BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: widget.borderRadius,
                ),
          child: Padding(padding: widget.padding, child: widget.badgeContent),
        ),
      ),
    );

    if (widget.toAnimate) {
      if (widget.animationType == BadgeAnimationType.slide) {
        return SlideTransition(
          position: _positionTween.animate(_animation),
          child: widget.gradient == null ? badgeView() : badgeViewGradient(),
        );
      } else if (widget.animationType == BadgeAnimationType.scale) {
        return ScaleTransition(
          scale: _animation,
          child: widget.gradient == null ? badgeView() : badgeViewGradient(),
        );
      } else if (widget.animationType == BadgeAnimationType.fade) {
        return FadeTransition(
          opacity: _animation,
          child: widget.gradient == null ? badgeView() : badgeViewGradient(),
        );
      }
    }

    return widget.gradient == null ? badgeView() : badgeViewGradient();
  }

  @override
  void didUpdateWidget(final BadgeWidget oldWidget) {
    if (widget.badgeContent is Text && oldWidget.badgeContent is Text) {
      final Text newText = widget.badgeContent! as Text;
      final Text oldText = oldWidget.badgeContent! as Text;
      if (newText.data != oldText.data) {
        _animationController.reset();
        _animationController.forward();
      }
    }

    if (widget.badgeContent is Icon && oldWidget.badgeContent is Icon) {
      final Icon newIcon = widget.badgeContent! as Icon;
      final Icon oldIcon = oldWidget.badgeContent! as Icon;
      if (newIcon.icon != oldIcon.icon) {
        _animationController.reset();
        _animationController.forward();
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class BadgePosition {
  const BadgePosition({this.top, this.end, this.bottom, this.start, this.isCenter = false});

  factory BadgePosition.center() => const BadgePosition(isCenter: true);

  factory BadgePosition.topStart({final double top = -5, final double start = -10}) => BadgePosition(top: top, start: start);

  factory BadgePosition.topEnd({final double top = -8, final double end = -10}) => BadgePosition(top: top, end: end);

  factory BadgePosition.bottomEnd({final double bottom = -8, final double end = -10}) => BadgePosition(bottom: bottom, end: end);

  factory BadgePosition.bottomStart({final double bottom = -8, final double start = -10}) => BadgePosition(bottom: bottom, start: start);
  final double? top;

  final double? end;

  final double? start;

  final double? bottom;

  final bool isCenter;
}

enum BadgeShape {
  circle,
  square,
}

class BadgePositioned extends StatelessWidget {
  const BadgePositioned({required this.child, super.key, this.position});

  final BadgePosition? position;

  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final BadgePosition? position = this.position;
    if (position == null) {
      final BadgePosition topRight = BadgePosition.topEnd();
      return PositionedDirectional(top: topRight.top, end: topRight.end, child: child);
    }

    if (position.isCenter) {
      return Positioned.fill(
        child: Align(child: child),
      );
    }

    return PositionedDirectional(
      top: position.top,
      end: position.end,
      bottom: position.bottom,
      start: position.start,
      child: child,
    );
  }
}
