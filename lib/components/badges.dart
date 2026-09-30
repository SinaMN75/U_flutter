import "package:u/utilities.dart";

/// Small rounded square with the first letter of [label] (avatars, steps). `ULetterBadge("Sina", background: Colors.teal, foreground: Colors.white)`
class ULetterBadge extends StatelessWidget {
  const ULetterBadge(
    this.label, {
    required this.background,
    required this.foreground,
    this.size = 34,
    this.radius = 11,
    super.key,
  });

  /// Label text.
  final String label;

  /// Box color.
  final Color background;

  /// Letter color.
  final Color foreground;

  /// Size in logical pixels.
  final double size;

  /// Corner radius.
  final double radius;

  @override
  Widget build(BuildContext context) => UContainer(
    width: size,
    height: size,
    radius: radius,
    color: background,
    alignment: Alignment.center,
    child: UTextLabelLarge(label.isEmpty ? "" : label.characters.first, color: foreground, fontWeight: FontWeight.bold),
  );
}

/// Badge appear animation: slide, fade, scale or none.
enum UBadgeAnimationType {
  slide,
  scale,
  fade,
}

/// Puts a badge (count, dot) on a corner of any widget. `UBadgeWidget(badgeContent: const Text("3"), child: const Icon(Icons.shopping_cart))`
class UBadgeWidget extends StatefulWidget {
  const UBadgeWidget({
    super.key,
    this.badgeContent,
    this.child,
    this.badgeColor = Colors.red,
    this.elevation = 2,
    this.toAnimate = true,
    this.position,
    this.shape = UBadgeShape.circle,
    this.padding = const EdgeInsets.all(5),
    this.animationDuration = const Duration(milliseconds: 500),
    this.borderRadius = BorderRadius.zero,
    this.alignment = Alignment.center,
    this.animationType = UBadgeAnimationType.slide,
    this.showBadge = true,
    this.ignorePointer = false,
    this.borderSide = BorderSide.none,
    this.stackFit = StackFit.loose,
    this.gradient,
  });

  /// The widget inside.
  final Widget? child;

  /// Alignment of the content.
  final AlignmentGeometry alignment;

  /// Where it is placed.
  final UBadgePosition? position;

  /// Inside the badge (text or icon); null = a dot.
  final Widget? badgeContent;

  /// Lets taps pass through the badge.
  final bool ignorePointer;

  /// Badge color.
  final Color badgeColor;

  /// Background gradient (overrides the color).
  final Gradient? gradient;

  /// Shadow depth.
  final double elevation;

  /// Animates when content changes.
  final bool toAnimate;

  /// Length of the animation.
  final Duration animationDuration;

  /// Animation type.
  final UBadgeAnimationType animationType;

  /// Shape of the widget.
  final UBadgeShape shape;

  /// Badge border.
  final BorderSide borderSide;

  /// How the child fills the stack.
  final StackFit stackFit;

  /// Corner radius.
  final BorderRadiusGeometry borderRadius;

  /// Space inside, around the content.
  final EdgeInsetsGeometry padding;

  /// False hides the badge.
  final bool showBadge;

  @override
  UBadgeState createState() => UBadgeState();
}

/// State of UBadgeWidget.
class UBadgeState extends State<UBadgeWidget> with SingleTickerProviderStateMixin {
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

    if (widget.animationType == UBadgeAnimationType.slide) {
      _animation = CurvedAnimation(parent: _animationController, curve: Curves.elasticOut);
    } else if (widget.animationType == UBadgeAnimationType.scale) {
      _animation = _scaleTween.animate(_animationController);
    } else if (widget.animationType == UBadgeAnimationType.fade) {
      _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    }

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child == null) {
      return _getBadge();
    } else {
      return Stack(
        fit: widget.stackFit,
        alignment: widget.alignment,
        clipBehavior: Clip.none,
        children: <Widget>[
          widget.child!,
          UBadgePositioned(
            position: widget.position,
            child: widget.ignorePointer ? IgnorePointer(child: _getBadge()) : _getBadge(),
          ),
        ],
      );
    }
  }

  Widget _getBadge() {
    final OutlinedBorder border = widget.shape == UBadgeShape.circle
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
          decoration: widget.shape == UBadgeShape.circle
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
      if (widget.animationType == UBadgeAnimationType.slide) {
        return SlideTransition(
          position: _positionTween.animate(_animation),
          child: widget.gradient == null ? badgeView() : badgeViewGradient(),
        );
      } else if (widget.animationType == UBadgeAnimationType.scale) {
        return ScaleTransition(
          scale: _animation,
          child: widget.gradient == null ? badgeView() : badgeViewGradient(),
        );
      } else if (widget.animationType == UBadgeAnimationType.fade) {
        return FadeTransition(
          opacity: _animation,
          child: widget.gradient == null ? badgeView() : badgeViewGradient(),
        );
      }
    }

    return widget.gradient == null ? badgeView() : badgeViewGradient();
  }

  @override
  void didUpdateWidget(UBadgeWidget oldWidget) {
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

/// Where the badge sits on the child.
class UBadgePosition {
  const UBadgePosition({this.top, this.end, this.bottom, this.start, this.isCenter = false});

  /// In the middle.
  factory UBadgePosition.center() => const UBadgePosition(isCenter: true);

  /// Top-start corner.
  factory UBadgePosition.topStart({double top = -5, double start = -10}) => UBadgePosition(top: top, start: start);

  /// Top-end corner (default).
  factory UBadgePosition.topEnd({double top = -8, double end = -10}) => UBadgePosition(top: top, end: end);

  /// Bottom-end corner.
  factory UBadgePosition.bottomEnd({double bottom = -8, double end = -10}) => UBadgePosition(bottom: bottom, end: end);

  /// Bottom-start corner.
  factory UBadgePosition.bottomStart({double bottom = -8, double start = -10}) => UBadgePosition(bottom: bottom, start: start);

  /// Distance from the top when [positioned] in a Stack.
  final double? top;

  /// Distance from the end edge.
  final double? end;

  /// Distance from the start edge.
  final double? start;

  /// Distance from the bottom when [positioned] in a Stack.
  final double? bottom;

  /// True when centered.
  final bool isCenter;
}

/// Badge shape: circle, square or pill.
enum UBadgeShape {
  circle,
  square,
}

/// Positions a badge inside UBadgeWidget.
class UBadgePositioned extends StatelessWidget {
  const UBadgePositioned({required this.child, super.key, this.position});

  /// Where it is placed.
  final UBadgePosition? position;

  /// The widget inside.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final UBadgePosition? position = this.position;
    if (position == null) {
      final UBadgePosition topRight = UBadgePosition.topEnd();
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
