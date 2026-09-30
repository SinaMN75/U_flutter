import "package:u/utilities.dart";

BorderRadius? _uRadius(BorderRadius? borderRadius, double? radius) => borderRadius ?? ((radius != null && radius != 0) ? BorderRadius.circular(radius) : null);

BoxDecoration? _uDecoration({
  Color? color,
  Gradient? gradient,
  DecorationImage? image,
  BoxBorder? border,
  BorderRadius? borderRadius,
  List<BoxShadow>? boxShadow,
  BoxShape shape = BoxShape.rectangle,
  BlendMode? backgroundBlendMode,
}) {
  final bool hasDecoration = gradient != null || image != null || border != null || boxShadow != null || borderRadius != null || backgroundBlendMode != null || shape != BoxShape.rectangle;
  if (!hasDecoration) return null;
  return BoxDecoration(
    color: color,
    gradient: gradient,
    image: image,
    border: border,
    borderRadius: shape == BoxShape.circle ? null : borderRadius,
    boxShadow: boxShadow,
    shape: shape,
    backgroundBlendMode: backgroundBlendMode,
  );
}

Widget _uInteractive(
  Widget child, {
  BorderRadius? radius,
  GestureTapCallback? onTap,
  GestureTapCallback? onDoubleTap,
  GestureLongPressCallback? onLongPress,
  GestureTapDownCallback? onTapDown,
  GestureTapUpCallback? onTapUp,
  GestureTapCancelCallback? onTapCancel,
  GestureTapCallback? onSecondaryTap,
  HitTestBehavior? hitTestBehavior,
  bool splash = false,
  Color? splashColor,
  Color? highlightColor,
  Color? hoverColor,
  double? pressedScale,
  Duration pressDuration = const Duration(milliseconds: 120),
  bool enableFeedback = true,
  MouseCursor? cursor,
  ValueChanged<bool>? onHover,
}) {
  final bool hasTap = onTap != null || onDoubleTap != null || onLongPress != null || onTapDown != null || onTapUp != null || onTapCancel != null || onSecondaryTap != null;

  Widget current = child;
  bool hoverHandledByInk = false;

  if (hasTap) {
    final bool onlyTap = onDoubleTap == null && onLongPress == null && onTapDown == null && onTapUp == null && onTapCancel == null && onSecondaryTap == null;
    if (pressedScale != null && onTap != null && onlyTap) {
      current = UPressable(onTap: onTap, pressedScale: pressedScale, duration: pressDuration, child: current);
    } else if (splash) {
      hoverHandledByInk = true;
      current = Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          onLongPress: onLongPress,
          onTapDown: onTapDown,
          onTapUp: onTapUp,
          onTapCancel: onTapCancel,
          onSecondaryTap: onSecondaryTap,
          onHover: onHover,
          borderRadius: radius,
          splashColor: splashColor,
          highlightColor: highlightColor,
          hoverColor: hoverColor,
          mouseCursor: cursor,
          enableFeedback: enableFeedback,
          child: current,
        ),
      );
    } else {
      current = GestureDetector(
        behavior: hitTestBehavior,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        onTapDown: onTapDown,
        onTapUp: onTapUp,
        onTapCancel: onTapCancel,
        onSecondaryTap: onSecondaryTap,
        child: current,
      );
    }
  }

  if (!hoverHandledByInk && onHover != null) {
    final ValueChanged<bool> hover = onHover;
    current = MouseRegion(
      cursor: cursor ?? MouseCursor.defer,
      onEnter: (PointerEnterEvent event) => hover(true),
      onExit: (PointerExitEvent event) => hover(false),
      child: current,
    );
  } else if (!hoverHandledByInk && cursor != null) {
    current = MouseRegion(cursor: cursor, child: current);
  }

  return current;
}

Widget _uEffects(
  Widget child, {
  double? opacity,
  String? tooltip,
  String? heroTag,
  EdgeInsetsGeometry? margin,
  String? semanticsLabel,
  bool? semanticsButton,
}) {
  Widget current = child;
  if (semanticsLabel != null || semanticsButton != null) current = Semantics(label: semanticsLabel, button: semanticsButton, child: current);
  if (opacity != null) current = Opacity(opacity: opacity, child: current);
  if (tooltip != null) current = Tooltip(message: tooltip, child: current);
  if (heroTag != null) current = Hero(tag: heroTag, child: current);
  if (margin != null) current = Padding(padding: margin, child: current);
  return current;
}

// Layout/structure modifiers — each wraps [child] only when requested, so an
// unused modifier costs nothing. Parent-data wrappers (positioned/expanded/
// flexible) are mutually exclusive and applied outermost.
Widget _uModifiers(
  Widget child, {
  BoxFit? fit,
  AlignmentGeometry fitAlignment = Alignment.center,
  double? scale,
  double? rotate,
  Offset? translate,
  bool center = false,
  bool safeArea = false,
  Axis? scrollable,
  ScrollController? scrollController,
  TextDirection? textDirection,
  int? expanded,
  int? flexible,
  bool positioned = false,
  double? left,
  double? top,
  double? right,
  double? bottom,
  double? positionedWidth,
  double? positionedHeight,
}) {
  Widget current = child;
  if (scrollable != null) current = SingleChildScrollView(scrollDirection: scrollable, controller: scrollController, child: current);
  if (fit != null) current = FittedBox(fit: fit, alignment: fitAlignment, child: current);
  if (translate != null) current = Transform.translate(offset: translate, child: current);
  if (rotate != null) current = Transform.rotate(angle: rotate, child: current);
  if (scale != null) current = Transform.scale(scale: scale, child: current);
  if (center) current = Center(child: current);
  if (safeArea) current = SafeArea(child: current);
  if (textDirection != null) current = Directionality(textDirection: textDirection, child: current);
  if (positioned) {
    current = Positioned(left: left, top: top, right: right, bottom: bottom, width: positionedWidth, height: positionedHeight, child: current);
  } else if (expanded != null) {
    current = Expanded(flex: expanded, child: current);
  } else if (flexible != null) {
    current = Flexible(flex: flexible, child: current);
  }
  return current;
}

/// Adds u's box, tap, hover, tooltip, hero, fit, transform and position options to any widget (what every U-widget uses). `uWrap(Text("Hi"), onTap: open, tooltip: "Open")`
Widget uWrap(
  Widget child, {
  BorderRadius? borderRadius,
  double? radius,
  GestureTapCallback? onTap,
  VoidCallback? onPress,
  GestureTapCallback? onDoubleTap,
  GestureLongPressCallback? onLongPress,
  GestureTapDownCallback? onTapDown,
  GestureTapUpCallback? onTapUp,
  GestureTapCancelCallback? onTapCancel,
  GestureTapCallback? onSecondaryTap,
  HitTestBehavior? hitTestBehavior,
  bool splash = false,
  Color? splashColor,
  Color? highlightColor,
  Color? hoverColor,
  double? pressedScale,
  Duration pressDuration = const Duration(milliseconds: 120),
  bool enableFeedback = true,
  MouseCursor? cursor,
  ValueChanged<bool>? onHover,
  double? opacity,
  String? tooltip,
  String? heroTag,
  EdgeInsetsGeometry? margin,
  String? semanticsLabel,
  bool? semanticsButton,
  bool visible = true,
  BoxFit? fit,
  AlignmentGeometry fitAlignment = Alignment.center,
  double? scale,
  double? rotate,
  Offset? translate,
  bool center = false,
  bool safeArea = false,
  Axis? scrollable,
  ScrollController? scrollController,
  TextDirection? textDirection,
  int? expanded,
  int? flexible,
  bool positioned = false,
  double? left,
  double? top,
  double? right,
  double? bottom,
  double? positionedWidth,
  double? positionedHeight,
}) {
  if (!visible) return const SizedBox.shrink();
  final GestureTapCallback? effectiveTap = onTap ?? onPress;
  final double? effectivePressedScale = pressedScale ?? (onPress != null ? 0.9 : null);
  Widget current = _uInteractive(
    child,
    radius: _uRadius(borderRadius, radius),
    onTap: effectiveTap,
    onDoubleTap: onDoubleTap,
    onLongPress: onLongPress,
    onTapDown: onTapDown,
    onTapUp: onTapUp,
    onTapCancel: onTapCancel,
    onSecondaryTap: onSecondaryTap,
    hitTestBehavior: hitTestBehavior,
    splash: splash,
    splashColor: splashColor,
    highlightColor: highlightColor,
    hoverColor: hoverColor,
    pressedScale: effectivePressedScale,
    pressDuration: pressDuration,
    enableFeedback: enableFeedback,
    cursor: cursor,
    onHover: onHover,
  );
  current = _uEffects(current, opacity: opacity, tooltip: tooltip, heroTag: heroTag, margin: margin, semanticsLabel: semanticsLabel, semanticsButton: semanticsButton);
  current = _uModifiers(
    current,
    fit: fit,
    fitAlignment: fitAlignment,
    scale: scale,
    rotate: rotate,
    translate: translate,
    center: center,
    safeArea: safeArea,
    scrollable: scrollable,
    scrollController: scrollController,
    textDirection: textDirection,
    expanded: expanded,
    flexible: flexible,
    positioned: positioned,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    positionedWidth: positionedWidth,
    positionedHeight: positionedHeight,
  );
  return current;
}

Widget _uBox({
  required Widget? child,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? margin,
  double? width,
  double? height,
  double? minWidth,
  double? maxWidth,
  double? minHeight,
  double? maxHeight,
  BoxConstraints? constraints,
  AlignmentGeometry? alignment,
  Matrix4? transform,
  AlignmentGeometry? transformAlignment,
  Clip clipBehavior = Clip.none,
  Decoration? foregroundDecoration,
  Color? color,
  Gradient? gradient,
  DecorationImage? image,
  BoxBorder? border,
  BorderRadius? borderRadius,
  double? radius,
  List<BoxShadow>? boxShadow,
  BoxShape shape = BoxShape.rectangle,
  BlendMode? backgroundBlendMode,
  GestureTapCallback? onTap,
  GestureTapCallback? onDoubleTap,
  GestureLongPressCallback? onLongPress,
  GestureTapDownCallback? onTapDown,
  GestureTapUpCallback? onTapUp,
  GestureTapCancelCallback? onTapCancel,
  GestureTapCallback? onSecondaryTap,
  HitTestBehavior? hitTestBehavior,
  bool splash = false,
  Color? splashColor,
  Color? highlightColor,
  Color? hoverColor,
  double? pressedScale,
  Duration pressDuration = const Duration(milliseconds: 120),
  bool enableFeedback = true,
  MouseCursor? cursor,
  ValueChanged<bool>? onHover,
  double? opacity,
  String? tooltip,
  String? heroTag,
  String? semanticsLabel,
  bool? semanticsButton,
  bool visible = true,
  VoidCallback? onPress,
  BoxFit? fit,
  AlignmentGeometry fitAlignment = Alignment.center,
  double? scale,
  double? rotate,
  Offset? translate,
  bool center = false,
  bool safeArea = false,
  Axis? scrollable,
  ScrollController? scrollController,
  TextDirection? textDirection,
  int? expanded,
  int? flexible,
  bool positioned = false,
  double? left,
  double? top,
  double? right,
  double? bottom,
  double? positionedWidth,
  double? positionedHeight,
}) {
  if (!visible) return const SizedBox.shrink();

  final BorderRadius? effectiveRadius = _uRadius(borderRadius, radius);
  final BoxDecoration? decoration = _uDecoration(
    color: color,
    gradient: gradient,
    image: image,
    border: border,
    borderRadius: effectiveRadius,
    boxShadow: boxShadow,
    shape: shape,
    backgroundBlendMode: backgroundBlendMode,
  );

  final BoxConstraints? sizeConstraints = (minWidth != null || maxWidth != null || minHeight != null || maxHeight != null)
      ? BoxConstraints(minWidth: minWidth ?? 0, maxWidth: maxWidth ?? double.infinity, minHeight: minHeight ?? 0, maxHeight: maxHeight ?? double.infinity)
      : null;
  final BoxConstraints? effectiveConstraints = constraints ?? sizeConstraints;

  Widget? current = child;

  final bool needsBox =
      padding != null ||
      color != null ||
      decoration != null ||
      foregroundDecoration != null ||
      width != null ||
      height != null ||
      effectiveConstraints != null ||
      alignment != null ||
      transform != null;

  if (needsBox) {
    current = Container(
      width: width,
      height: height,
      constraints: effectiveConstraints,
      alignment: alignment,
      padding: padding,
      transform: transform,
      transformAlignment: transformAlignment,
      clipBehavior: decoration != null ? clipBehavior : Clip.none,
      foregroundDecoration: foregroundDecoration,
      color: decoration == null ? color : null,
      decoration: decoration,
      child: current,
    );
  }

  current ??= const SizedBox.shrink();

  return uWrap(
    current,
    borderRadius: effectiveRadius,
    onTap: onTap,
    onPress: onPress,
    onDoubleTap: onDoubleTap,
    onLongPress: onLongPress,
    onTapDown: onTapDown,
    onTapUp: onTapUp,
    onTapCancel: onTapCancel,
    onSecondaryTap: onSecondaryTap,
    hitTestBehavior: hitTestBehavior,
    splash: splash,
    splashColor: splashColor,
    highlightColor: highlightColor,
    hoverColor: hoverColor,
    pressedScale: pressedScale,
    pressDuration: pressDuration,
    enableFeedback: enableFeedback,
    cursor: cursor,
    onHover: onHover,
    opacity: opacity,
    tooltip: tooltip,
    heroTag: heroTag,
    margin: margin,
    semanticsLabel: semanticsLabel,
    semanticsButton: semanticsButton,
    fit: fit,
    fitAlignment: fitAlignment,
    scale: scale,
    rotate: rotate,
    translate: translate,
    center: center,
    safeArea: safeArea,
    scrollable: scrollable,
    scrollController: scrollController,
    textDirection: textDirection,
    expanded: expanded,
    flexible: flexible,
    positioned: positioned,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    positionedWidth: positionedWidth,
    positionedHeight: positionedHeight,
  );
}

// ===========================================================================
// Widgets
// ===========================================================================

/// Scaffold that also closes the keyboard on outside taps, adds SafeArea and pads/decorates the body. `UScaffold(appBar: AppBar(title: const Text("Home")), body: content)`
class UScaffold extends StatelessWidget {
  const UScaffold({
    required this.body,
    super.key,
    this.appBar,
    this.drawer,
    this.endDrawer,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.persistentFooterButtons,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    this.constraints,
    this.width,
    this.height,
    this.onDrawerChanged,
    this.onEndDrawerChanged,
    this.resizeToAvoidBottomInset,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
    this.primary = true,
    this.drawerScrimColor,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.alignment,
    this.safeArea = true,
    this.safeAreaEdges = EdgeInsets.zero,
    this.dismissKeyboardOnTap = true,
  });

  /// Page content.
  final Widget body;

  /// Top app bar.
  final PreferredSizeWidget? appBar;

  /// Left side menu (right side in RTL).
  final Widget? drawer;

  /// Right side menu (left side in RTL).
  final Widget? endDrawer;

  /// Floating button; a FloatingActionButton goes bottom-end, anything else bottom-center.
  final Widget? floatingActionButton;

  /// Bottom navigation bar.
  final Widget? bottomNavigationBar;

  /// Persistent bottom sheet.
  final Widget? bottomSheet;

  /// Buttons fixed at the bottom.
  final List<Widget>? persistentFooterButtons;

  /// Space inside, around the content.
  final EdgeInsetsGeometry? padding;

  /// Space outside, around the widget.
  final EdgeInsetsGeometry? margin;

  /// Main color (defaults to the theme).
  final Color? color;

  /// Decoration of the body box (e.g. a gradient background).
  final BoxDecoration? decoration;

  /// Lets the body go under a transparent app bar.
  final bool extendBodyBehindAppBar;

  /// Lets the body go under the bottom bar.
  final bool extendBody;

  /// Primary color.
  final bool primary;

  /// Dim color behind an open drawer.
  final Color? drawerScrimColor;

  /// Where the floating button sits.
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// How the floating button animates between locations.
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;

  /// Extra size limits.
  final BoxConstraints? constraints;

  /// Width in logical pixels (null = size to content).
  final double? width;

  /// Height in logical pixels (null = size to content).
  final double? height;

  /// Called when the drawer opens/closes.
  final DrawerCallback? onDrawerChanged;

  /// Called when the end drawer opens/closes.
  final DrawerCallback? onEndDrawerChanged;

  /// Alignment of the content.
  final Alignment? alignment;

  /// Keeps it out of the notch and system bars.
  final bool safeArea;

  /// Extra padding added around the SafeArea when [safeArea] is on.
  final EdgeInsets safeAreaEdges;

  /// Shrinks the body when the keyboard opens.
  final bool? resizeToAvoidBottomInset;

  /// Closes the keyboard when tapping outside a field (default true).
  final bool dismissKeyboardOnTap;

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: width,
      height: height,
      constraints: constraints,
      decoration: decoration,
      padding: padding,
      margin: margin,
      alignment: alignment,
      child: body,
    );

    if (dismissKeyboardOnTap) {
      content = GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: content,
      );
    }

    if (safeArea) {
      content = Padding(
        padding: safeAreaEdges,
        child: SafeArea(child: content),
      );
    }

    return Scaffold(
      key: key,
      backgroundColor: color,
      appBar: appBar,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      persistentFooterButtons: persistentFooterButtons,
      onDrawerChanged: onDrawerChanged,
      onEndDrawerChanged: onEndDrawerChanged,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      extendBody: extendBody,
      primary: primary,
      drawerScrimColor: drawerScrimColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation ?? (floatingActionButton is FloatingActionButton ? FloatingActionButtonLocation.endFloat : FloatingActionButtonLocation.centerFloat),
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      body: content,
    );
  }
}

/// Tab bar + swipeable pages in one widget. `UDefaultTabBar(tabBar: const TabBar(tabs: [Tab(text: "A"), Tab(text: "B")]), children: [PageA(), PageB()])`
class UDefaultTabBar extends StatelessWidget {
  const UDefaultTabBar({
    required this.children,
    required this.tabBar,
    super.key,
    this.width,
    this.height,
    this.controller,
    this.physics,
    this.initialIndex = 0,
    this.indicatorColor,
    this.labelStyle,
    this.unselectedLabelStyle,
    this.indicatorWeight = 2.0,
    this.isScrollable = false,
    this.dragStartBehavior = DragStartBehavior.start,
    this.viewportFraction = 1.0,
    this.constraints,
  });

  /// Child widgets.
  final List<Widget> children;

  /// The tab bar shown above the pages.
  final Widget tabBar;

  /// Width in logical pixels (null = size to content).
  final double? width;

  /// Height in logical pixels (null = size to content).
  final double? height;

  /// Index selected at start.
  final int initialIndex;

  /// Controller to read or change it from code.
  final TabController? controller;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Indicator color.
  final Color? indicatorColor;

  /// Selected tab text style.
  final TextStyle? labelStyle;

  /// Unselected tab text style.
  final TextStyle? unselectedLabelStyle;

  /// Indicator thickness.
  final double indicatorWeight;

  /// Lets many tabs scroll sideways.
  final bool isScrollable;

  /// When a swipe starts.
  final DragStartBehavior dragStartBehavior;

  /// Part of the width each page takes (1 = full).
  final double viewportFraction;

  /// Extra size limits.
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    initialIndex: initialIndex,
    length: children.length,
    child: Column(
      children: <Widget>[
        tabBar,
        Expanded(
          child: ConstrainedBox(
            constraints: constraints ?? const BoxConstraints(),
            child: SizedBox(
              width: width ?? MediaQuery.of(context).size.width,
              height: height ?? MediaQuery.of(context).size.height,
              child: TabBarView(
                physics: physics,
                controller: controller,
                dragStartBehavior: dragStartBehavior,
                viewportFraction: viewportFraction,
                children: children,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Container with everything built in: radius, border, gradient, shadow, tap/press/hover, tooltip, hero, fit, flex, position. `UContainer(radius: 12, color: Colors.white, padding: const EdgeInsets.all(16), onTap: open, child: Text("Card"))`
class UContainer extends StatelessWidget {
  const UContainer({
    this.child,
    super.key,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.image,
    this.border,
    this.radius,
    this.borderRadius,
    this.boxShadow,
    this.width,
    this.height,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.constraints,
    this.alignment,
    this.clipBehavior = Clip.none,
    this.transform,
    this.transformAlignment,
    this.foregroundDecoration,
    this.shape = BoxShape.rectangle,
    this.backgroundBlendMode,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onSecondaryTap,
    this.hitTestBehavior,
    this.splash = false,
    this.splashColor,
    this.highlightColor,
    this.hoverColor,
    this.pressedScale,
    this.pressDuration = const Duration(milliseconds: 120),
    this.enableFeedback = true,
    this.cursor,
    this.onHover,
    this.opacity,
    this.tooltip,
    this.semanticsLabel,
    this.semanticsButton,
    this.visible = true,
    this.heroTag,
    this.onPress,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.scrollable,
    this.scrollController,
    this.textDirection,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  /// The widget inside.
  final Widget? child;

  /// Space inside, around the content.
  final EdgeInsetsGeometry? padding;

  /// Space outside, around the widget.
  final EdgeInsetsGeometry? margin;

  /// Main color (defaults to the theme).
  final Color? color;

  /// Background gradient (overrides the color).
  final Gradient? gradient;

  /// Image to show.
  final DecorationImage? image;

  /// Border around it.
  final BoxBorder? border;

  /// Corner radius.
  final double? radius;

  /// Corner radius.
  final BorderRadius? borderRadius;

  /// Shadows under it.
  final List<BoxShadow>? boxShadow;

  /// Width in logical pixels (null = size to content).
  final double? width;

  /// Height in logical pixels (null = size to content).
  final double? height;

  /// Minimum width.
  final double? minWidth;

  /// Maximum width.
  final double? maxWidth;

  /// Minimum height.
  final double? minHeight;

  /// Maximum height.
  final double? maxHeight;

  /// Extra size limits.
  final BoxConstraints? constraints;

  /// Alignment of the content.
  final AlignmentGeometry? alignment;

  /// How content outside the bounds is clipped.
  final Clip clipBehavior;

  /// Matrix transform applied when painting.
  final Matrix4? transform;

  /// Origin of [transform].
  final AlignmentGeometry? transformAlignment;

  /// Decoration painted on top of the child.
  final Decoration? foregroundDecoration;

  /// Shape of the widget.
  final BoxShape shape;

  /// Blend mode of the background with what is behind.
  final BlendMode? backgroundBlendMode;

  /// Called when tapped.
  final GestureTapCallback? onTap;

  /// Called on double tap.
  final GestureTapCallback? onDoubleTap;

  /// Called on long press.
  final GestureLongPressCallback? onLongPress;

  /// Called when a finger touches down.
  final GestureTapDownCallback? onTapDown;

  /// Called when the finger lifts after a tap.
  final GestureTapUpCallback? onTapUp;

  /// Called when a tap is cancelled.
  final GestureTapCancelCallback? onTapCancel;

  /// Called on right-click / secondary tap.
  final GestureTapCallback? onSecondaryTap;

  /// How taps on transparent areas are handled.
  final HitTestBehavior? hitTestBehavior;

  /// Shows a Material ripple on tap.
  final bool splash;

  /// Ripple color.
  final Color? splashColor;

  /// Pressed highlight color.
  final Color? highlightColor;

  /// Color while a mouse hovers (desktop, web).
  final Color? hoverColor;

  /// Scale while pressed, e.g. 0.95 for a subtle shrink.
  final double? pressedScale;

  /// Length of the press-shrink animation.
  final Duration pressDuration;

  /// Plays the platform click sound/haptic on tap.
  final bool enableFeedback;

  /// Mouse cursor on hover (desktop, web).
  final MouseCursor? cursor;

  /// Called with true/false when a mouse enters/leaves (desktop, web).
  final ValueChanged<bool>? onHover;

  /// See-through amount, 0 (invisible) to 1 (solid).
  final double? opacity;

  /// Text shown on long press / mouse hover.
  final String? tooltip;

  /// Label read by screen readers.
  final String? semanticsLabel;

  /// Tells screen readers this is a button.
  final bool? semanticsButton;

  /// False hides it completely (takes no space).
  final bool visible;

  /// Hero tag for a shared-element animation between pages.
  final String? heroTag;

  /// Called when tapped, with a press-down shrink effect.
  final VoidCallback? onPress;

  /// How the content fits its box (BoxFit).
  final BoxFit? fit;

  /// Alignment inside the box when it does not fill it.
  final AlignmentGeometry fitAlignment;

  /// Scales the painted widget (1 = normal size).
  final double? scale;

  /// Rotation in radians.
  final double? rotate;

  /// Moves the painted widget by this offset (layout unchanged).
  final Offset? translate;

  /// Centers it in the available space.
  final bool center;

  /// Keeps it out of the notch and system bars.
  final bool safeArea;

  /// Makes the content scroll when it does not fit.
  final Axis? scrollable;

  /// Scroll controller.
  final ScrollController? scrollController;

  /// Text direction (RTL/LTR); defaults to the app's.
  final TextDirection? textDirection;

  /// Flex value to fill the remaining space in a Row/Column (null = off).
  final int? expanded;

  /// Flex value to shrink in a Row/Column when space is tight (null = off).
  final int? flexible;

  /// Wraps it in a Positioned (use inside a Stack) with top/left/right/bottom.
  final bool positioned;

  /// Distance from the left when [positioned] in a Stack.
  final double? left;

  /// Distance from the top when [positioned] in a Stack.
  final double? top;

  /// Distance from the right when [positioned] in a Stack.
  final double? right;

  /// Distance from the bottom when [positioned] in a Stack.
  final double? bottom;

  /// Width when [positioned].
  final double? positionedWidth;

  /// Height when [positioned].
  final double? positionedHeight;

  @override
  Widget build(BuildContext context) => _uBox(
    padding: padding,
    margin: margin,
    width: width,
    height: height,
    minWidth: minWidth,
    maxWidth: maxWidth,
    minHeight: minHeight,
    maxHeight: maxHeight,
    constraints: constraints,
    alignment: alignment,
    transform: transform,
    transformAlignment: transformAlignment,
    clipBehavior: clipBehavior,
    foregroundDecoration: foregroundDecoration,
    color: color,
    gradient: gradient,
    image: image,
    border: border,
    borderRadius: borderRadius,
    radius: radius,
    boxShadow: boxShadow,
    shape: shape,
    backgroundBlendMode: backgroundBlendMode,
    onTap: onTap,
    onDoubleTap: onDoubleTap,
    onLongPress: onLongPress,
    onTapDown: onTapDown,
    onTapUp: onTapUp,
    onTapCancel: onTapCancel,
    onSecondaryTap: onSecondaryTap,
    hitTestBehavior: hitTestBehavior,
    splash: splash,
    splashColor: splashColor,
    highlightColor: highlightColor,
    hoverColor: hoverColor,
    pressedScale: pressedScale,
    pressDuration: pressDuration,
    enableFeedback: enableFeedback,
    cursor: cursor,
    onHover: onHover,
    opacity: opacity,
    tooltip: tooltip,
    heroTag: heroTag,
    semanticsLabel: semanticsLabel,
    semanticsButton: semanticsButton,
    visible: visible,
    onPress: onPress,
    fit: fit,
    fitAlignment: fitAlignment,
    scale: scale,
    rotate: rotate,
    translate: translate,
    center: center,
    safeArea: safeArea,
    scrollable: scrollable,
    scrollController: scrollController,
    textDirection: textDirection,
    expanded: expanded,
    flexible: flexible,
    positioned: positioned,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    positionedWidth: positionedWidth,
    positionedHeight: positionedHeight,
    child: child,
  );
}

/// Column with gap [spacing], box decoration, tap and flex options. `UColumn(spacing: 8, children: [a, b, c])`
class UColumn extends StatelessWidget {
  const UColumn({
    required this.children,
    super.key,
    this.spacing = 0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.width,
    this.height,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.padding,
    this.margin,
    this.radius,
    this.borderRadius,
    this.border,
    this.color,
    this.gradient,
    this.image,
    this.boxShadow,
    this.constraints,
    this.alignment,
    this.clipBehavior = Clip.hardEdge,
    this.transform,
    this.transformAlignment,
    this.foregroundDecoration,
    this.shape = BoxShape.rectangle,
    this.backgroundBlendMode,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onSecondaryTap,
    this.hitTestBehavior,
    this.splash = false,
    this.splashColor,
    this.highlightColor,
    this.hoverColor,
    this.pressedScale,
    this.cursor,
    this.onHover,
    this.opacity,
    this.tooltip,
    this.semanticsLabel,
    this.semanticsButton,
    this.visible = true,
    this.heroTag,
    this.onPress,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.scrollable,
    this.scrollController,
    this.textDirection,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  /// Child widgets.
  final List<Widget> children;

  /// Gap between items.
  final double spacing;

  /// Width in logical pixels (null = size to content).
  final double? width;

  /// Height in logical pixels (null = size to content).
  final double? height;

  /// Minimum width.
  final double? minWidth;

  /// Maximum width.
  final double? maxWidth;

  /// Minimum height.
  final double? minHeight;

  /// Maximum height.
  final double? maxHeight;

  /// How children are placed along the main axis.
  final MainAxisAlignment mainAxisAlignment;

  /// How children are placed across the main axis.
  final CrossAxisAlignment crossAxisAlignment;

  /// Whether it takes all space on the main axis or only what children need.
  final MainAxisSize mainAxisSize;

  /// Corner radius.
  final double? radius;

  /// Corner radius.
  final BorderRadius? borderRadius;

  /// Space inside, around the content.
  final EdgeInsetsGeometry? padding;

  /// Space outside, around the widget.
  final EdgeInsetsGeometry? margin;

  /// Border around it.
  final BoxBorder? border;

  /// Main color (defaults to the theme).
  final Color? color;

  /// Background gradient (overrides the color).
  final Gradient? gradient;

  /// Image to show.
  final DecorationImage? image;

  /// Shadows under it.
  final List<BoxShadow>? boxShadow;

  /// Extra size limits.
  final BoxConstraints? constraints;

  /// Alignment of the content.
  final AlignmentGeometry? alignment;

  /// How content outside the bounds is clipped.
  final Clip clipBehavior;

  /// Matrix transform applied when painting.
  final Matrix4? transform;

  /// Origin of [transform].
  final AlignmentGeometry? transformAlignment;

  /// Decoration painted on top of the child.
  final Decoration? foregroundDecoration;

  /// Shape of the widget.
  final BoxShape shape;

  /// Blend mode of the background with what is behind.
  final BlendMode? backgroundBlendMode;

  /// Called when tapped.
  final GestureTapCallback? onTap;

  /// Called on double tap.
  final GestureTapCallback? onDoubleTap;

  /// Called on long press.
  final GestureLongPressCallback? onLongPress;

  /// Called when a finger touches down.
  final GestureTapDownCallback? onTapDown;

  /// Called when the finger lifts after a tap.
  final GestureTapUpCallback? onTapUp;

  /// Called when a tap is cancelled.
  final GestureTapCancelCallback? onTapCancel;

  /// Called on right-click / secondary tap.
  final GestureTapCallback? onSecondaryTap;

  /// How taps on transparent areas are handled.
  final HitTestBehavior? hitTestBehavior;

  /// Shows a Material ripple on tap.
  final bool splash;

  /// Ripple color.
  final Color? splashColor;

  /// Pressed highlight color.
  final Color? highlightColor;

  /// Color while a mouse hovers (desktop, web).
  final Color? hoverColor;

  /// Scale while pressed, e.g. 0.95 for a subtle shrink.
  final double? pressedScale;

  /// Mouse cursor on hover (desktop, web).
  final MouseCursor? cursor;

  /// Called with true/false when a mouse enters/leaves (desktop, web).
  final ValueChanged<bool>? onHover;

  /// See-through amount, 0 (invisible) to 1 (solid).
  final double? opacity;

  /// Text shown on long press / mouse hover.
  final String? tooltip;

  /// Label read by screen readers.
  final String? semanticsLabel;

  /// Tells screen readers this is a button.
  final bool? semanticsButton;

  /// False hides it completely (takes no space).
  final bool visible;

  /// Hero tag for a shared-element animation between pages.
  final String? heroTag;

  /// Called when tapped, with a press-down shrink effect.
  final VoidCallback? onPress;

  /// How the content fits its box (BoxFit).
  final BoxFit? fit;

  /// Alignment inside the box when it does not fill it.
  final AlignmentGeometry fitAlignment;

  /// Scales the painted widget (1 = normal size).
  final double? scale;

  /// Rotation in radians.
  final double? rotate;

  /// Moves the painted widget by this offset (layout unchanged).
  final Offset? translate;

  /// Centers it in the available space.
  final bool center;

  /// Keeps it out of the notch and system bars.
  final bool safeArea;

  /// Makes the content scroll when it does not fit.
  final Axis? scrollable;

  /// Scroll controller.
  final ScrollController? scrollController;

  /// Text direction (RTL/LTR); defaults to the app's.
  final TextDirection? textDirection;

  /// Flex value to fill the remaining space in a Row/Column (null = off).
  final int? expanded;

  /// Flex value to shrink in a Row/Column when space is tight (null = off).
  final int? flexible;

  /// Wraps it in a Positioned (use inside a Stack) with top/left/right/bottom.
  final bool positioned;

  /// Distance from the left when [positioned] in a Stack.
  final double? left;

  /// Distance from the top when [positioned] in a Stack.
  final double? top;

  /// Distance from the right when [positioned] in a Stack.
  final double? right;

  /// Distance from the bottom when [positioned] in a Stack.
  final double? bottom;

  /// Width when [positioned].
  final double? positionedWidth;

  /// Height when [positioned].
  final double? positionedHeight;

  @override
  Widget build(BuildContext context) => _uBox(
    color: color,
    width: width,
    height: height,
    minWidth: minWidth,
    maxWidth: maxWidth,
    minHeight: minHeight,
    maxHeight: maxHeight,
    padding: padding,
    margin: margin,
    radius: radius,
    borderRadius: borderRadius,
    border: border,
    constraints: constraints,
    alignment: alignment,
    transform: transform,
    transformAlignment: transformAlignment,
    clipBehavior: clipBehavior,
    foregroundDecoration: foregroundDecoration,
    gradient: gradient,
    image: image,
    boxShadow: boxShadow,
    shape: shape,
    backgroundBlendMode: backgroundBlendMode,
    onTap: onTap,
    onDoubleTap: onDoubleTap,
    onLongPress: onLongPress,
    onTapDown: onTapDown,
    onTapUp: onTapUp,
    onTapCancel: onTapCancel,
    onSecondaryTap: onSecondaryTap,
    hitTestBehavior: hitTestBehavior,
    splash: splash,
    splashColor: splashColor,
    highlightColor: highlightColor,
    hoverColor: hoverColor,
    pressedScale: pressedScale,
    cursor: cursor,
    onHover: onHover,
    opacity: opacity,
    tooltip: tooltip,
    heroTag: heroTag,
    semanticsLabel: semanticsLabel,
    semanticsButton: semanticsButton,
    visible: visible,
    onPress: onPress,
    fit: fit,
    fitAlignment: fitAlignment,
    scale: scale,
    rotate: rotate,
    translate: translate,
    center: center,
    safeArea: safeArea,
    scrollable: scrollable,
    scrollController: scrollController,
    textDirection: textDirection,
    expanded: expanded,
    flexible: flexible,
    positioned: positioned,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    positionedWidth: positionedWidth,
    positionedHeight: positionedHeight,
    child: Column(
      spacing: spacing,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    ),
  );
}

/// Row with gap [spacing], box decoration, tap and flex options. `URow(spacing: 8, children: [icon, text])`
class URow extends StatelessWidget {
  const URow({
    required this.children,
    super.key,
    this.spacing = 0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.width,
    this.height,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.padding,
    this.margin,
    this.radius,
    this.borderRadius,
    this.border,
    this.color,
    this.gradient,
    this.image,
    this.boxShadow,
    this.constraints,
    this.alignment,
    this.clipBehavior = Clip.hardEdge,
    this.transform,
    this.transformAlignment,
    this.foregroundDecoration,
    this.shape = BoxShape.rectangle,
    this.backgroundBlendMode,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onSecondaryTap,
    this.hitTestBehavior,
    this.splash = false,
    this.splashColor,
    this.highlightColor,
    this.hoverColor,
    this.pressedScale,
    this.cursor,
    this.onHover,
    this.opacity,
    this.tooltip,
    this.semanticsLabel,
    this.semanticsButton,
    this.visible = true,
    this.heroTag,
    this.onPress,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.scrollable,
    this.scrollController,
    this.textDirection,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  /// Child widgets.
  final List<Widget> children;

  /// Gap between items.
  final double spacing;

  /// Width in logical pixels (null = size to content).
  final double? width;

  /// Height in logical pixels (null = size to content).
  final double? height;

  /// Minimum width.
  final double? minWidth;

  /// Maximum width.
  final double? maxWidth;

  /// Minimum height.
  final double? minHeight;

  /// Maximum height.
  final double? maxHeight;

  /// How children are placed along the main axis.
  final MainAxisAlignment mainAxisAlignment;

  /// How children are placed across the main axis.
  final CrossAxisAlignment crossAxisAlignment;

  /// Whether it takes all space on the main axis or only what children need.
  final MainAxisSize mainAxisSize;

  /// Corner radius.
  final double? radius;

  /// Corner radius.
  final BorderRadius? borderRadius;

  /// Space inside, around the content.
  final EdgeInsetsGeometry? padding;

  /// Space outside, around the widget.
  final EdgeInsetsGeometry? margin;

  /// Border around it.
  final BoxBorder? border;

  /// Main color (defaults to the theme).
  final Color? color;

  /// Background gradient (overrides the color).
  final Gradient? gradient;

  /// Image to show.
  final DecorationImage? image;

  /// Shadows under it.
  final List<BoxShadow>? boxShadow;

  /// Extra size limits.
  final BoxConstraints? constraints;

  /// Alignment of the content.
  final AlignmentGeometry? alignment;

  /// How content outside the bounds is clipped.
  final Clip clipBehavior;

  /// Matrix transform applied when painting.
  final Matrix4? transform;

  /// Origin of [transform].
  final AlignmentGeometry? transformAlignment;

  /// Decoration painted on top of the child.
  final Decoration? foregroundDecoration;

  /// Shape of the widget.
  final BoxShape shape;

  /// Blend mode of the background with what is behind.
  final BlendMode? backgroundBlendMode;

  /// Called when tapped.
  final GestureTapCallback? onTap;

  /// Called on double tap.
  final GestureTapCallback? onDoubleTap;

  /// Called on long press.
  final GestureLongPressCallback? onLongPress;

  /// Called when a finger touches down.
  final GestureTapDownCallback? onTapDown;

  /// Called when the finger lifts after a tap.
  final GestureTapUpCallback? onTapUp;

  /// Called when a tap is cancelled.
  final GestureTapCancelCallback? onTapCancel;

  /// Called on right-click / secondary tap.
  final GestureTapCallback? onSecondaryTap;

  /// How taps on transparent areas are handled.
  final HitTestBehavior? hitTestBehavior;

  /// Shows a Material ripple on tap.
  final bool splash;

  /// Ripple color.
  final Color? splashColor;

  /// Pressed highlight color.
  final Color? highlightColor;

  /// Color while a mouse hovers (desktop, web).
  final Color? hoverColor;

  /// Scale while pressed, e.g. 0.95 for a subtle shrink.
  final double? pressedScale;

  /// Mouse cursor on hover (desktop, web).
  final MouseCursor? cursor;

  /// Called with true/false when a mouse enters/leaves (desktop, web).
  final ValueChanged<bool>? onHover;

  /// See-through amount, 0 (invisible) to 1 (solid).
  final double? opacity;

  /// Text shown on long press / mouse hover.
  final String? tooltip;

  /// Label read by screen readers.
  final String? semanticsLabel;

  /// Tells screen readers this is a button.
  final bool? semanticsButton;

  /// False hides it completely (takes no space).
  final bool visible;

  /// Hero tag for a shared-element animation between pages.
  final String? heroTag;

  /// Called when tapped, with a press-down shrink effect.
  final VoidCallback? onPress;

  /// How the content fits its box (BoxFit).
  final BoxFit? fit;

  /// Alignment inside the box when it does not fill it.
  final AlignmentGeometry fitAlignment;

  /// Scales the painted widget (1 = normal size).
  final double? scale;

  /// Rotation in radians.
  final double? rotate;

  /// Moves the painted widget by this offset (layout unchanged).
  final Offset? translate;

  /// Centers it in the available space.
  final bool center;

  /// Keeps it out of the notch and system bars.
  final bool safeArea;

  /// Makes the content scroll when it does not fit.
  final Axis? scrollable;

  /// Scroll controller.
  final ScrollController? scrollController;

  /// Text direction (RTL/LTR); defaults to the app's.
  final TextDirection? textDirection;

  /// Flex value to fill the remaining space in a Row/Column (null = off).
  final int? expanded;

  /// Flex value to shrink in a Row/Column when space is tight (null = off).
  final int? flexible;

  /// Wraps it in a Positioned (use inside a Stack) with top/left/right/bottom.
  final bool positioned;

  /// Distance from the left when [positioned] in a Stack.
  final double? left;

  /// Distance from the top when [positioned] in a Stack.
  final double? top;

  /// Distance from the right when [positioned] in a Stack.
  final double? right;

  /// Distance from the bottom when [positioned] in a Stack.
  final double? bottom;

  /// Width when [positioned].
  final double? positionedWidth;

  /// Height when [positioned].
  final double? positionedHeight;

  @override
  Widget build(BuildContext context) => _uBox(
    color: color,
    width: width,
    height: height,
    minWidth: minWidth,
    maxWidth: maxWidth,
    minHeight: minHeight,
    maxHeight: maxHeight,
    padding: padding,
    margin: margin,
    radius: radius,
    borderRadius: borderRadius,
    border: border,
    constraints: constraints,
    alignment: alignment,
    transform: transform,
    transformAlignment: transformAlignment,
    clipBehavior: clipBehavior,
    foregroundDecoration: foregroundDecoration,
    gradient: gradient,
    image: image,
    boxShadow: boxShadow,
    shape: shape,
    backgroundBlendMode: backgroundBlendMode,
    onTap: onTap,
    onDoubleTap: onDoubleTap,
    onLongPress: onLongPress,
    onTapDown: onTapDown,
    onTapUp: onTapUp,
    onTapCancel: onTapCancel,
    onSecondaryTap: onSecondaryTap,
    hitTestBehavior: hitTestBehavior,
    splash: splash,
    splashColor: splashColor,
    highlightColor: highlightColor,
    hoverColor: hoverColor,
    pressedScale: pressedScale,
    cursor: cursor,
    onHover: onHover,
    opacity: opacity,
    tooltip: tooltip,
    heroTag: heroTag,
    semanticsLabel: semanticsLabel,
    semanticsButton: semanticsButton,
    visible: visible,
    onPress: onPress,
    fit: fit,
    fitAlignment: fitAlignment,
    scale: scale,
    rotate: rotate,
    translate: translate,
    center: center,
    safeArea: safeArea,
    scrollable: scrollable,
    scrollController: scrollController,
    textDirection: textDirection,
    expanded: expanded,
    flexible: flexible,
    positioned: positioned,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    positionedWidth: positionedWidth,
    positionedHeight: positionedHeight,
    child: Row(
      spacing: spacing,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    ),
  );
}

/// Stack with box decoration, tap and flex options. `UStack(children: [image, badge.position(top: 4, right: 4)])`
class UStack extends StatelessWidget {
  const UStack({
    required this.children,
    super.key,
    this.stackAlignment = AlignmentDirectional.topStart,
    this.fit = StackFit.loose,
    this.stackClip = Clip.hardEdge,
    this.textDirection,
    this.width,
    this.height,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.image,
    this.border,
    this.radius,
    this.borderRadius,
    this.boxShadow,
    this.constraints,
    this.shape = BoxShape.rectangle,
    this.backgroundBlendMode,
    this.foregroundDecoration,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.splash = false,
    this.pressedScale,
    this.cursor,
    this.onHover,
    this.opacity,
    this.tooltip,
    this.semanticsLabel,
    this.visible = true,
    this.heroTag,
    this.onPress,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.scrollable,
    this.scrollController,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  /// Child widgets.
  final List<Widget> children;

  /// How non-positioned children are aligned.
  final AlignmentGeometry stackAlignment;

  /// How the content fits its box (BoxFit).
  final StackFit fit;

  /// Clips children that go outside.
  final Clip stackClip;

  /// Text direction (RTL/LTR); defaults to the app's.
  final TextDirection? textDirection;

  /// Width in logical pixels (null = size to content).
  final double? width;

  /// Height in logical pixels (null = size to content).
  final double? height;

  /// Minimum width.
  final double? minWidth;

  /// Maximum width.
  final double? maxWidth;

  /// Minimum height.
  final double? minHeight;

  /// Maximum height.
  final double? maxHeight;

  /// Space inside, around the content.
  final EdgeInsetsGeometry? padding;

  /// Space outside, around the widget.
  final EdgeInsetsGeometry? margin;

  /// Main color (defaults to the theme).
  final Color? color;

  /// Background gradient (overrides the color).
  final Gradient? gradient;

  /// Image to show.
  final DecorationImage? image;

  /// Border around it.
  final BoxBorder? border;

  /// Corner radius.
  final double? radius;

  /// Corner radius.
  final BorderRadius? borderRadius;

  /// Shadows under it.
  final List<BoxShadow>? boxShadow;

  /// Extra size limits.
  final BoxConstraints? constraints;

  /// Shape of the widget.
  final BoxShape shape;

  /// Blend mode of the background with what is behind.
  final BlendMode? backgroundBlendMode;

  /// Decoration painted on top of the child.
  final Decoration? foregroundDecoration;

  /// Called when tapped.
  final GestureTapCallback? onTap;

  /// Called on long press.
  final GestureLongPressCallback? onLongPress;

  /// Called on double tap.
  final GestureTapCallback? onDoubleTap;

  /// Shows a Material ripple on tap.
  final bool splash;

  /// Scale while pressed, e.g. 0.95 for a subtle shrink.
  final double? pressedScale;

  /// Mouse cursor on hover (desktop, web).
  final MouseCursor? cursor;

  /// Called with true/false when a mouse enters/leaves (desktop, web).
  final ValueChanged<bool>? onHover;

  /// See-through amount, 0 (invisible) to 1 (solid).
  final double? opacity;

  /// Text shown on long press / mouse hover.
  final String? tooltip;

  /// Label read by screen readers.
  final String? semanticsLabel;

  /// False hides it completely (takes no space).
  final bool visible;

  /// Hero tag for a shared-element animation between pages.
  final String? heroTag;

  /// Called when tapped, with a press-down shrink effect.
  final VoidCallback? onPress;

  /// Scales the painted widget (1 = normal size).
  final double? scale;

  /// Rotation in radians.
  final double? rotate;

  /// Moves the painted widget by this offset (layout unchanged).
  final Offset? translate;

  /// Centers it in the available space.
  final bool center;

  /// Keeps it out of the notch and system bars.
  final bool safeArea;

  /// Makes the content scroll when it does not fit.
  final Axis? scrollable;

  /// Scroll controller.
  final ScrollController? scrollController;

  /// Flex value to fill the remaining space in a Row/Column (null = off).
  final int? expanded;

  /// Flex value to shrink in a Row/Column when space is tight (null = off).
  final int? flexible;

  /// Wraps it in a Positioned (use inside a Stack) with top/left/right/bottom.
  final bool positioned;

  /// Distance from the left when [positioned] in a Stack.
  final double? left;

  /// Distance from the top when [positioned] in a Stack.
  final double? top;

  /// Distance from the right when [positioned] in a Stack.
  final double? right;

  /// Distance from the bottom when [positioned] in a Stack.
  final double? bottom;

  /// Width when [positioned].
  final double? positionedWidth;

  /// Height when [positioned].
  final double? positionedHeight;

  @override
  Widget build(BuildContext context) => _uBox(
    width: width,
    height: height,
    minWidth: minWidth,
    maxWidth: maxWidth,
    minHeight: minHeight,
    maxHeight: maxHeight,
    padding: padding,
    margin: margin,
    color: color,
    gradient: gradient,
    image: image,
    border: border,
    radius: radius,
    borderRadius: borderRadius,
    boxShadow: boxShadow,
    constraints: constraints,
    shape: shape,
    backgroundBlendMode: backgroundBlendMode,
    foregroundDecoration: foregroundDecoration,
    clipBehavior: Clip.hardEdge,
    onTap: onTap,
    onLongPress: onLongPress,
    onDoubleTap: onDoubleTap,
    splash: splash,
    pressedScale: pressedScale,
    cursor: cursor,
    onHover: onHover,
    opacity: opacity,
    tooltip: tooltip,
    semanticsLabel: semanticsLabel,
    visible: visible,
    heroTag: heroTag,
    onPress: onPress,
    scale: scale,
    rotate: rotate,
    translate: translate,
    center: center,
    safeArea: safeArea,
    scrollable: scrollable,
    scrollController: scrollController,
    expanded: expanded,
    flexible: flexible,
    positioned: positioned,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    positionedWidth: positionedWidth,
    positionedHeight: positionedHeight,
    child: Stack(
      alignment: stackAlignment,
      fit: fit,
      clipBehavior: stackClip,
      textDirection: textDirection,
      children: children,
    ),
  );
}

/// Wrap (flows children onto new lines) with decoration and tap options. `UWrap(spacing: 8, runSpacing: 8, children: chips)`
class UWrap extends StatelessWidget {
  const UWrap({
    required this.children,
    super.key,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.direction = Axis.horizontal,
    this.wrapAlignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.verticalDirection = VerticalDirection.down,
    this.textDirection,
    this.wrapClip = Clip.none,
    this.width,
    this.height,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.image,
    this.border,
    this.radius,
    this.borderRadius,
    this.boxShadow,
    this.constraints,
    this.alignment,
    this.shape = BoxShape.rectangle,
    this.backgroundBlendMode,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.splash = false,
    this.pressedScale,
    this.cursor,
    this.onHover,
    this.opacity,
    this.tooltip,
    this.semanticsLabel,
    this.visible = true,
    this.heroTag,
    this.onPress,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.scrollable,
    this.scrollController,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  /// Child widgets.
  final List<Widget> children;

  /// Gap between items.
  final double spacing;

  /// Gap between lines.
  final double runSpacing;

  /// Layout direction.
  final Axis direction;

  /// How items are placed in a line.
  final WrapAlignment wrapAlignment;

  /// How lines are placed.
  final WrapAlignment runAlignment;

  /// How children are placed across the main axis.
  final WrapCrossAlignment crossAxisAlignment;

  /// Top-down or bottom-up lines.
  final VerticalDirection verticalDirection;

  /// Text direction (RTL/LTR); defaults to the app's.
  final TextDirection? textDirection;

  /// Clips children that go outside.
  final Clip wrapClip;

  /// Width in logical pixels (null = size to content).
  final double? width;

  /// Height in logical pixels (null = size to content).
  final double? height;

  /// Minimum width.
  final double? minWidth;

  /// Maximum width.
  final double? maxWidth;

  /// Minimum height.
  final double? minHeight;

  /// Maximum height.
  final double? maxHeight;

  /// Space inside, around the content.
  final EdgeInsetsGeometry? padding;

  /// Space outside, around the widget.
  final EdgeInsetsGeometry? margin;

  /// Main color (defaults to the theme).
  final Color? color;

  /// Background gradient (overrides the color).
  final Gradient? gradient;

  /// Image to show.
  final DecorationImage? image;

  /// Border around it.
  final BoxBorder? border;

  /// Corner radius.
  final double? radius;

  /// Corner radius.
  final BorderRadius? borderRadius;

  /// Shadows under it.
  final List<BoxShadow>? boxShadow;

  /// Extra size limits.
  final BoxConstraints? constraints;

  /// Alignment of the content.
  final AlignmentGeometry? alignment;

  /// Shape of the widget.
  final BoxShape shape;

  /// Blend mode of the background with what is behind.
  final BlendMode? backgroundBlendMode;

  /// Called when tapped.
  final GestureTapCallback? onTap;

  /// Called on long press.
  final GestureLongPressCallback? onLongPress;

  /// Called on double tap.
  final GestureTapCallback? onDoubleTap;

  /// Shows a Material ripple on tap.
  final bool splash;

  /// Scale while pressed, e.g. 0.95 for a subtle shrink.
  final double? pressedScale;

  /// Mouse cursor on hover (desktop, web).
  final MouseCursor? cursor;

  /// Called with true/false when a mouse enters/leaves (desktop, web).
  final ValueChanged<bool>? onHover;

  /// See-through amount, 0 (invisible) to 1 (solid).
  final double? opacity;

  /// Text shown on long press / mouse hover.
  final String? tooltip;

  /// Label read by screen readers.
  final String? semanticsLabel;

  /// False hides it completely (takes no space).
  final bool visible;

  /// Hero tag for a shared-element animation between pages.
  final String? heroTag;

  /// Called when tapped, with a press-down shrink effect.
  final VoidCallback? onPress;

  /// How the content fits its box (BoxFit).
  final BoxFit? fit;

  /// Alignment inside the box when it does not fill it.
  final AlignmentGeometry fitAlignment;

  /// Scales the painted widget (1 = normal size).
  final double? scale;

  /// Rotation in radians.
  final double? rotate;

  /// Moves the painted widget by this offset (layout unchanged).
  final Offset? translate;

  /// Centers it in the available space.
  final bool center;

  /// Keeps it out of the notch and system bars.
  final bool safeArea;

  /// Makes the content scroll when it does not fit.
  final Axis? scrollable;

  /// Scroll controller.
  final ScrollController? scrollController;

  /// Flex value to fill the remaining space in a Row/Column (null = off).
  final int? expanded;

  /// Flex value to shrink in a Row/Column when space is tight (null = off).
  final int? flexible;

  /// Wraps it in a Positioned (use inside a Stack) with top/left/right/bottom.
  final bool positioned;

  /// Distance from the left when [positioned] in a Stack.
  final double? left;

  /// Distance from the top when [positioned] in a Stack.
  final double? top;

  /// Distance from the right when [positioned] in a Stack.
  final double? right;

  /// Distance from the bottom when [positioned] in a Stack.
  final double? bottom;

  /// Width when [positioned].
  final double? positionedWidth;

  /// Height when [positioned].
  final double? positionedHeight;

  @override
  Widget build(BuildContext context) => _uBox(
    width: width,
    height: height,
    minWidth: minWidth,
    maxWidth: maxWidth,
    minHeight: minHeight,
    maxHeight: maxHeight,
    padding: padding,
    margin: margin,
    color: color,
    gradient: gradient,
    image: image,
    border: border,
    radius: radius,
    borderRadius: borderRadius,
    boxShadow: boxShadow,
    constraints: constraints,
    alignment: alignment,
    shape: shape,
    backgroundBlendMode: backgroundBlendMode,
    clipBehavior: Clip.hardEdge,
    onTap: onTap,
    onLongPress: onLongPress,
    onDoubleTap: onDoubleTap,
    splash: splash,
    pressedScale: pressedScale,
    cursor: cursor,
    onHover: onHover,
    opacity: opacity,
    tooltip: tooltip,
    semanticsLabel: semanticsLabel,
    visible: visible,
    heroTag: heroTag,
    onPress: onPress,
    fit: fit,
    fitAlignment: fitAlignment,
    scale: scale,
    rotate: rotate,
    translate: translate,
    center: center,
    safeArea: safeArea,
    scrollable: scrollable,
    scrollController: scrollController,
    expanded: expanded,
    flexible: flexible,
    positioned: positioned,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    positionedWidth: positionedWidth,
    positionedHeight: positionedHeight,
    child: Wrap(
      direction: direction,
      alignment: wrapAlignment,
      runAlignment: runAlignment,
      crossAxisAlignment: crossAxisAlignment,
      spacing: spacing,
      runSpacing: runSpacing,
      verticalDirection: verticalDirection,
      textDirection: textDirection,
      clipBehavior: wrapClip,
      children: children,
    ),
  );
}

/// Icon/leading widget next to text/trailing widget, with spacing and box options. `UIconTextHorizontal(leading: const Icon(Icons.phone), trailing: const Text("0912…"))`
class UIconTextHorizontal extends StatelessWidget {
  const UIconTextHorizontal({
    required this.leading,
    required this.trailing,
    super.key,
    this.spaceBetween = 8.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.min,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.onHover,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.color,
    this.gradient,
    this.border,
    this.radius,
    this.boxShadow,
    this.alignment,
    this.opacity,
    this.tooltip,
    this.semanticsLabel,
    this.cursor,
    this.splash = false,
    this.pressedScale,
    this.visible = true,
    this.onPress,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.scrollable,
    this.scrollController,
    this.textDirection,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  /// Widget at the start.
  final Widget leading;

  /// Widget at the end.
  final Widget trailing;

  /// Gap between the two parts.
  final double spaceBetween;

  /// How children are placed along the main axis.
  final MainAxisAlignment mainAxisAlignment;

  /// How children are placed across the main axis.
  final CrossAxisAlignment crossAxisAlignment;

  /// Whether it takes all space on the main axis or only what children need.
  final MainAxisSize mainAxisSize;

  /// Called when tapped.
  final GestureTapCallback? onTap;

  /// Called on long press.
  final GestureLongPressCallback? onLongPress;

  /// Called on double tap.
  final GestureTapCallback? onDoubleTap;

  /// Called with true/false when a mouse enters/leaves (desktop, web).
  final ValueChanged<bool>? onHover;

  /// Space inside, around the content.
  final EdgeInsetsGeometry? padding;

  /// Space outside, around the widget.
  final EdgeInsetsGeometry? margin;

  /// Width in logical pixels (null = size to content).
  final double? width;

  /// Height in logical pixels (null = size to content).
  final double? height;

  /// Main color (defaults to the theme).
  final Color? color;

  /// Background gradient (overrides the color).
  final Gradient? gradient;

  /// Border around it.
  final BoxBorder? border;

  /// Corner radius.
  final double? radius;

  /// Shadows under it.
  final List<BoxShadow>? boxShadow;

  /// Alignment of the content.
  final AlignmentGeometry? alignment;

  /// See-through amount, 0 (invisible) to 1 (solid).
  final double? opacity;

  /// Text shown on long press / mouse hover.
  final String? tooltip;

  /// Label read by screen readers.
  final String? semanticsLabel;

  /// Mouse cursor on hover (desktop, web).
  final MouseCursor? cursor;

  /// Shows a Material ripple on tap.
  final bool splash;

  /// Scale while pressed, e.g. 0.95 for a subtle shrink.
  final double? pressedScale;

  /// False hides it completely (takes no space).
  final bool visible;

  /// Called when tapped, with a press-down shrink effect.
  final VoidCallback? onPress;

  /// How the content fits its box (BoxFit).
  final BoxFit? fit;

  /// Alignment inside the box when it does not fill it.
  final AlignmentGeometry fitAlignment;

  /// Scales the painted widget (1 = normal size).
  final double? scale;

  /// Rotation in radians.
  final double? rotate;

  /// Moves the painted widget by this offset (layout unchanged).
  final Offset? translate;

  /// Centers it in the available space.
  final bool center;

  /// Keeps it out of the notch and system bars.
  final bool safeArea;

  /// Makes the content scroll when it does not fit.
  final Axis? scrollable;

  /// Scroll controller.
  final ScrollController? scrollController;

  /// Text direction (RTL/LTR); defaults to the app's.
  final TextDirection? textDirection;

  /// Flex value to fill the remaining space in a Row/Column (null = off).
  final int? expanded;

  /// Flex value to shrink in a Row/Column when space is tight (null = off).
  final int? flexible;

  /// Wraps it in a Positioned (use inside a Stack) with top/left/right/bottom.
  final bool positioned;

  /// Distance from the left when [positioned] in a Stack.
  final double? left;

  /// Distance from the top when [positioned] in a Stack.
  final double? top;

  /// Distance from the right when [positioned] in a Stack.
  final double? right;

  /// Distance from the bottom when [positioned] in a Stack.
  final double? bottom;

  /// Width when [positioned].
  final double? positionedWidth;

  /// Height when [positioned].
  final double? positionedHeight;

  @override
  Widget build(BuildContext context) => _uBox(
    padding: padding,
    margin: margin,
    width: width,
    height: height,
    color: color,
    gradient: gradient,
    border: border,
    radius: radius,
    boxShadow: boxShadow,
    alignment: alignment,
    opacity: opacity,
    tooltip: tooltip,
    semanticsLabel: semanticsLabel,
    cursor: cursor,
    splash: splash,
    pressedScale: pressedScale,
    visible: visible,
    onTap: onTap,
    onLongPress: onLongPress,
    onDoubleTap: onDoubleTap,
    onHover: onHover,
    onPress: onPress,
    fit: fit,
    fitAlignment: fitAlignment,
    scale: scale,
    rotate: rotate,
    translate: translate,
    center: center,
    safeArea: safeArea,
    scrollable: scrollable,
    scrollController: scrollController,
    textDirection: textDirection,
    expanded: expanded,
    flexible: flexible,
    positioned: positioned,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    positionedWidth: positionedWidth,
    positionedHeight: positionedHeight,
    child: Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: <Widget>[
        leading,
        SizedBox(width: spaceBetween),
        trailing,
      ],
    ),
  );
}

/// Leading widget above trailing widget, with spacing and box options.
class UIconTextVertical extends StatelessWidget {
  const UIconTextVertical({
    required this.leading,
    required this.trailing,
    super.key,
    this.spaceBetween = 8.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.min,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.onHover,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.color,
    this.gradient,
    this.border,
    this.radius,
    this.boxShadow,
    this.alignment,
    this.opacity,
    this.tooltip,
    this.semanticsLabel,
    this.cursor,
    this.splash = false,
    this.pressedScale,
    this.visible = true,
    this.onPress,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.scrollable,
    this.scrollController,
    this.textDirection,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  /// Widget at the start.
  final Widget leading;

  /// Widget at the end.
  final Widget trailing;

  /// Gap between the two parts.
  final double spaceBetween;

  /// How children are placed along the main axis.
  final MainAxisAlignment mainAxisAlignment;

  /// How children are placed across the main axis.
  final CrossAxisAlignment crossAxisAlignment;

  /// Whether it takes all space on the main axis or only what children need.
  final MainAxisSize mainAxisSize;

  /// Called when tapped.
  final GestureTapCallback? onTap;

  /// Called on long press.
  final GestureLongPressCallback? onLongPress;

  /// Called on double tap.
  final GestureTapCallback? onDoubleTap;

  /// Called with true/false when a mouse enters/leaves (desktop, web).
  final ValueChanged<bool>? onHover;

  /// Space inside, around the content.
  final EdgeInsetsGeometry? padding;

  /// Space outside, around the widget.
  final EdgeInsetsGeometry? margin;

  /// Width in logical pixels (null = size to content).
  final double? width;

  /// Height in logical pixels (null = size to content).
  final double? height;

  /// Main color (defaults to the theme).
  final Color? color;

  /// Background gradient (overrides the color).
  final Gradient? gradient;

  /// Border around it.
  final BoxBorder? border;

  /// Corner radius.
  final double? radius;

  /// Shadows under it.
  final List<BoxShadow>? boxShadow;

  /// Alignment of the content.
  final AlignmentGeometry? alignment;

  /// See-through amount, 0 (invisible) to 1 (solid).
  final double? opacity;

  /// Text shown on long press / mouse hover.
  final String? tooltip;

  /// Label read by screen readers.
  final String? semanticsLabel;

  /// Mouse cursor on hover (desktop, web).
  final MouseCursor? cursor;

  /// Shows a Material ripple on tap.
  final bool splash;

  /// Scale while pressed, e.g. 0.95 for a subtle shrink.
  final double? pressedScale;

  /// False hides it completely (takes no space).
  final bool visible;

  /// Called when tapped, with a press-down shrink effect.
  final VoidCallback? onPress;

  /// How the content fits its box (BoxFit).
  final BoxFit? fit;

  /// Alignment inside the box when it does not fill it.
  final AlignmentGeometry fitAlignment;

  /// Scales the painted widget (1 = normal size).
  final double? scale;

  /// Rotation in radians.
  final double? rotate;

  /// Moves the painted widget by this offset (layout unchanged).
  final Offset? translate;

  /// Centers it in the available space.
  final bool center;

  /// Keeps it out of the notch and system bars.
  final bool safeArea;

  /// Makes the content scroll when it does not fit.
  final Axis? scrollable;

  /// Scroll controller.
  final ScrollController? scrollController;

  /// Text direction (RTL/LTR); defaults to the app's.
  final TextDirection? textDirection;

  /// Flex value to fill the remaining space in a Row/Column (null = off).
  final int? expanded;

  /// Flex value to shrink in a Row/Column when space is tight (null = off).
  final int? flexible;

  /// Wraps it in a Positioned (use inside a Stack) with top/left/right/bottom.
  final bool positioned;

  /// Distance from the left when [positioned] in a Stack.
  final double? left;

  /// Distance from the top when [positioned] in a Stack.
  final double? top;

  /// Distance from the right when [positioned] in a Stack.
  final double? right;

  /// Distance from the bottom when [positioned] in a Stack.
  final double? bottom;

  /// Width when [positioned].
  final double? positionedWidth;

  /// Height when [positioned].
  final double? positionedHeight;

  @override
  Widget build(BuildContext context) => _uBox(
    padding: padding,
    margin: margin,
    width: width,
    height: height,
    color: color,
    gradient: gradient,
    border: border,
    radius: radius,
    boxShadow: boxShadow,
    alignment: alignment,
    opacity: opacity,
    tooltip: tooltip,
    semanticsLabel: semanticsLabel,
    cursor: cursor,
    splash: splash,
    pressedScale: pressedScale,
    visible: visible,
    onTap: onTap,
    onLongPress: onLongPress,
    onDoubleTap: onDoubleTap,
    onHover: onHover,
    onPress: onPress,
    fit: fit,
    fitAlignment: fitAlignment,
    scale: scale,
    rotate: rotate,
    translate: translate,
    center: center,
    safeArea: safeArea,
    scrollable: scrollable,
    scrollController: scrollController,
    textDirection: textDirection,
    expanded: expanded,
    flexible: flexible,
    positioned: positioned,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    positionedWidth: positionedWidth,
    positionedHeight: positionedHeight,
    child: Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: <Widget>[
        leading,
        SizedBox(height: spaceBetween),
        trailing,
      ],
    ),
  );
}

/// Key on one side, value on the other (spaceBetween), with box options. `UKeyValue(leading: const Text("Price"), trailing: Text(price.toman()))`
class UKeyValue extends StatelessWidget {
  const UKeyValue({
    required this.leading,
    required this.trailing,
    super.key,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.onTap,
    this.onLongPress,
    this.onHover,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.border,
    this.radius,
    this.boxShadow,
    this.opacity,
    this.tooltip,
    this.semanticsLabel,
    this.splash = false,
    this.visible = true,
    this.onPress,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.scrollable,
    this.scrollController,
    this.textDirection,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  /// Widget at the start.
  final Widget leading;

  /// Widget at the end.
  final Widget trailing;

  /// How children are placed along the main axis.
  final MainAxisAlignment mainAxisAlignment;

  /// How children are placed across the main axis.
  final CrossAxisAlignment crossAxisAlignment;

  /// Called when tapped.
  final GestureTapCallback? onTap;

  /// Called on long press.
  final GestureLongPressCallback? onLongPress;

  /// Called with true/false when a mouse enters/leaves (desktop, web).
  final ValueChanged<bool>? onHover;

  /// Space inside, around the content.
  final EdgeInsetsGeometry? padding;

  /// Space outside, around the widget.
  final EdgeInsetsGeometry? margin;

  /// Main color (defaults to the theme).
  final Color? color;

  /// Background gradient (overrides the color).
  final Gradient? gradient;

  /// Border around it.
  final BoxBorder? border;

  /// Corner radius.
  final double? radius;

  /// Shadows under it.
  final List<BoxShadow>? boxShadow;

  /// See-through amount, 0 (invisible) to 1 (solid).
  final double? opacity;

  /// Text shown on long press / mouse hover.
  final String? tooltip;

  /// Label read by screen readers.
  final String? semanticsLabel;

  /// Shows a Material ripple on tap.
  final bool splash;

  /// False hides it completely (takes no space).
  final bool visible;

  /// Called when tapped, with a press-down shrink effect.
  final VoidCallback? onPress;

  /// How the content fits its box (BoxFit).
  final BoxFit? fit;

  /// Alignment inside the box when it does not fill it.
  final AlignmentGeometry fitAlignment;

  /// Scales the painted widget (1 = normal size).
  final double? scale;

  /// Rotation in radians.
  final double? rotate;

  /// Moves the painted widget by this offset (layout unchanged).
  final Offset? translate;

  /// Centers it in the available space.
  final bool center;

  /// Keeps it out of the notch and system bars.
  final bool safeArea;

  /// Makes the content scroll when it does not fit.
  final Axis? scrollable;

  /// Scroll controller.
  final ScrollController? scrollController;

  /// Text direction (RTL/LTR); defaults to the app's.
  final TextDirection? textDirection;

  /// Flex value to fill the remaining space in a Row/Column (null = off).
  final int? expanded;

  /// Flex value to shrink in a Row/Column when space is tight (null = off).
  final int? flexible;

  /// Wraps it in a Positioned (use inside a Stack) with top/left/right/bottom.
  final bool positioned;

  /// Distance from the left when [positioned] in a Stack.
  final double? left;

  /// Distance from the top when [positioned] in a Stack.
  final double? top;

  /// Distance from the right when [positioned] in a Stack.
  final double? right;

  /// Distance from the bottom when [positioned] in a Stack.
  final double? bottom;

  /// Width when [positioned].
  final double? positionedWidth;

  /// Height when [positioned].
  final double? positionedHeight;

  @override
  Widget build(BuildContext context) => _uBox(
    padding: padding,
    margin: margin,
    color: color,
    gradient: gradient,
    border: border,
    radius: radius,
    boxShadow: boxShadow,
    opacity: opacity,
    tooltip: tooltip,
    semanticsLabel: semanticsLabel,
    splash: splash,
    visible: visible,
    onTap: onTap,
    onLongPress: onLongPress,
    onHover: onHover,
    onPress: onPress,
    fit: fit,
    fitAlignment: fitAlignment,
    scale: scale,
    rotate: rotate,
    translate: translate,
    center: center,
    safeArea: safeArea,
    scrollable: scrollable,
    scrollController: scrollController,
    textDirection: textDirection,
    expanded: expanded,
    flexible: flexible,
    positioned: positioned,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    positionedWidth: positionedWidth,
    positionedHeight: positionedHeight,
    child: Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: <Widget>[
        leading,
        trailing,
      ],
    ),
  );
}

/// Material card with u's box, tap and flex options. `UCard(onTap: open, child: content)`
class UCard extends StatelessWidget {
  const UCard({
    required this.child,
    super.key,
    this.elevation = 2.0,
    this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.margin = EdgeInsets.zero,
    this.padding,
    this.shadowColor,
    this.surfaceTintColor,
    this.width,
    this.height,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.onHover,
    this.splashColor,
    this.highlightColor,
    this.hoverColor,
    this.border,
    this.semanticsLabel,
    this.onPress,
    this.opacity,
    this.visible = true,
    this.tooltip,
    this.heroTag,
    this.cursor,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.scrollable,
    this.scrollController,
    this.textDirection,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  /// The widget inside.
  final Widget child;

  /// Shadow depth.
  final double elevation;

  /// Width in logical pixels (null = size to content).
  final double? width;

  /// Height in logical pixels (null = size to content).
  final double? height;

  /// Main color (defaults to the theme).
  final Color? color;

  /// Corner radius.
  final BorderRadius borderRadius;

  /// Space outside, around the widget.
  final EdgeInsets margin;

  /// Space inside, around the content.
  final EdgeInsetsGeometry? padding;

  /// Shadow color.
  final Color? shadowColor;

  /// Material 3 tint over the surface.
  final Color? surfaceTintColor;

  /// Called when tapped.
  final GestureTapCallback? onTap;

  /// Called on long press.
  final GestureLongPressCallback? onLongPress;

  /// Called on double tap.
  final GestureTapCallback? onDoubleTap;

  /// Called with true/false when a mouse enters/leaves (desktop, web).
  final ValueChanged<bool>? onHover;

  /// Ripple color.
  final Color? splashColor;

  /// Pressed highlight color.
  final Color? highlightColor;

  /// Color while a mouse hovers (desktop, web).
  final Color? hoverColor;

  /// Border around it.
  final BorderSide? border;

  /// Label read by screen readers.
  final String? semanticsLabel;

  /// Called when tapped, with a press-down shrink effect.
  final VoidCallback? onPress;

  /// See-through amount, 0 (invisible) to 1 (solid).
  final double? opacity;

  /// False hides it completely (takes no space).
  final bool visible;

  /// Text shown on long press / mouse hover.
  final String? tooltip;

  /// Hero tag for a shared-element animation between pages.
  final String? heroTag;

  /// Mouse cursor on hover (desktop, web).
  final MouseCursor? cursor;

  /// How the content fits its box (BoxFit).
  final BoxFit? fit;

  /// Alignment inside the box when it does not fill it.
  final AlignmentGeometry fitAlignment;

  /// Scales the painted widget (1 = normal size).
  final double? scale;

  /// Rotation in radians.
  final double? rotate;

  /// Moves the painted widget by this offset (layout unchanged).
  final Offset? translate;

  /// Centers it in the available space.
  final bool center;

  /// Keeps it out of the notch and system bars.
  final bool safeArea;

  /// Makes the content scroll when it does not fit.
  final Axis? scrollable;

  /// Scroll controller.
  final ScrollController? scrollController;

  /// Text direction (RTL/LTR); defaults to the app's.
  final TextDirection? textDirection;

  /// Flex value to fill the remaining space in a Row/Column (null = off).
  final int? expanded;

  /// Flex value to shrink in a Row/Column when space is tight (null = off).
  final int? flexible;

  /// Wraps it in a Positioned (use inside a Stack) with top/left/right/bottom.
  final bool positioned;

  /// Distance from the left when [positioned] in a Stack.
  final double? left;

  /// Distance from the top when [positioned] in a Stack.
  final double? top;

  /// Distance from the right when [positioned] in a Stack.
  final double? right;

  /// Distance from the bottom when [positioned] in a Stack.
  final double? bottom;

  /// Width when [positioned].
  final double? positionedWidth;

  /// Height when [positioned].
  final double? positionedHeight;

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (padding != null) content = Padding(padding: padding!, child: content);
    if (width != null || height != null) content = SizedBox(width: width, height: height, child: content);

    final bool hasTap = onTap != null || onLongPress != null || onDoubleTap != null;
    if (hasTap) {
      content = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        onDoubleTap: onDoubleTap,
        onHover: onHover,
        borderRadius: borderRadius,
        splashColor: splashColor,
        highlightColor: highlightColor,
        hoverColor: hoverColor,
        child: content,
      );
    }

    final Widget card = Card(
      elevation: elevation,
      color: color,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: border ?? BorderSide.none,
      ),
      margin: margin,
      clipBehavior: hasTap ? Clip.antiAlias : Clip.none,
      child: content,
    );

    final Widget result = semanticsLabel != null ? Semantics(label: semanticsLabel, button: hasTap, child: card) : card;
    return uWrap(
      result,
      onPress: onPress,
      opacity: opacity,
      visible: visible,
      tooltip: tooltip,
      heroTag: heroTag,
      cursor: cursor,
      fit: fit,
      fitAlignment: fitAlignment,
      scale: scale,
      rotate: rotate,
      translate: translate,
      center: center,
      safeArea: safeArea,
      scrollable: scrollable,
      scrollController: scrollController,
      textDirection: textDirection,
      expanded: expanded,
      flexible: flexible,
      positioned: positioned,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      positionedWidth: positionedWidth,
      positionedHeight: positionedHeight,
    );
  }
}

/// UContainer that animates size, color, radius and padding changes. `UAnimatedContainer(duration: 300.ms, width: open ? 200 : 60, child: icon)`
class UAnimatedContainer extends StatelessWidget {
  const UAnimatedContainer({
    this.child,
    super.key,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.image,
    this.border,
    this.radius,
    this.borderRadius,
    this.boxShadow,
    this.width,
    this.height,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.constraints,
    this.alignment,
    this.clipBehavior = Clip.none,
    this.transform,
    this.transformAlignment,
    this.foregroundDecoration,
    this.shape = BoxShape.rectangle,
    this.backgroundBlendMode,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.splash = false,
    this.splashColor,
    this.highlightColor,
    this.hoverColor,
    this.pressedScale,
    this.cursor,
    this.onHover,
    this.opacity,
    this.tooltip,
    this.semanticsLabel,
    this.visible = true,
    this.heroTag,
    this.onEnd,
    this.onPress,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.scrollable,
    this.scrollController,
    this.textDirection,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  /// The widget inside.
  final Widget? child;

  /// How long it lasts.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  /// Space inside, around the content.
  final EdgeInsetsGeometry? padding;

  /// Space outside, around the widget.
  final EdgeInsetsGeometry? margin;

  /// Main color (defaults to the theme).
  final Color? color;

  /// Background gradient (overrides the color).
  final Gradient? gradient;

  /// Image to show.
  final DecorationImage? image;

  /// Border around it.
  final BoxBorder? border;

  /// Corner radius.
  final double? radius;

  /// Corner radius.
  final BorderRadius? borderRadius;

  /// Shadows under it.
  final List<BoxShadow>? boxShadow;

  /// Width in logical pixels (null = size to content).
  final double? width;

  /// Height in logical pixels (null = size to content).
  final double? height;

  /// Minimum width.
  final double? minWidth;

  /// Maximum width.
  final double? maxWidth;

  /// Minimum height.
  final double? minHeight;

  /// Maximum height.
  final double? maxHeight;

  /// Extra size limits.
  final BoxConstraints? constraints;

  /// Alignment of the content.
  final AlignmentGeometry? alignment;

  /// How content outside the bounds is clipped.
  final Clip clipBehavior;

  /// Matrix transform applied when painting.
  final Matrix4? transform;

  /// Origin of [transform].
  final AlignmentGeometry? transformAlignment;

  /// Decoration painted on top of the child.
  final Decoration? foregroundDecoration;

  /// Shape of the widget.
  final BoxShape shape;

  /// Blend mode of the background with what is behind.
  final BlendMode? backgroundBlendMode;

  /// Called when tapped.
  final GestureTapCallback? onTap;

  /// Called on double tap.
  final GestureTapCallback? onDoubleTap;

  /// Called on long press.
  final GestureLongPressCallback? onLongPress;

  /// Shows a Material ripple on tap.
  final bool splash;

  /// Ripple color.
  final Color? splashColor;

  /// Pressed highlight color.
  final Color? highlightColor;

  /// Color while a mouse hovers (desktop, web).
  final Color? hoverColor;

  /// Scale while pressed, e.g. 0.95 for a subtle shrink.
  final double? pressedScale;

  /// Mouse cursor on hover (desktop, web).
  final MouseCursor? cursor;

  /// Called with true/false when a mouse enters/leaves (desktop, web).
  final ValueChanged<bool>? onHover;

  /// See-through amount, 0 (invisible) to 1 (solid).
  final double? opacity;

  /// Text shown on long press / mouse hover.
  final String? tooltip;

  /// Label read by screen readers.
  final String? semanticsLabel;

  /// False hides it completely (takes no space).
  final bool visible;

  /// Hero tag for a shared-element animation between pages.
  final String? heroTag;

  /// Called when an animation finishes.
  final VoidCallback? onEnd;

  /// Called when tapped, with a press-down shrink effect.
  final VoidCallback? onPress;

  /// How the content fits its box (BoxFit).
  final BoxFit? fit;

  /// Alignment inside the box when it does not fill it.
  final AlignmentGeometry fitAlignment;

  /// Scales the painted widget (1 = normal size).
  final double? scale;

  /// Rotation in radians.
  final double? rotate;

  /// Moves the painted widget by this offset (layout unchanged).
  final Offset? translate;

  /// Centers it in the available space.
  final bool center;

  /// Keeps it out of the notch and system bars.
  final bool safeArea;

  /// Makes the content scroll when it does not fit.
  final Axis? scrollable;

  /// Scroll controller.
  final ScrollController? scrollController;

  /// Text direction (RTL/LTR); defaults to the app's.
  final TextDirection? textDirection;

  /// Flex value to fill the remaining space in a Row/Column (null = off).
  final int? expanded;

  /// Flex value to shrink in a Row/Column when space is tight (null = off).
  final int? flexible;

  /// Wraps it in a Positioned (use inside a Stack) with top/left/right/bottom.
  final bool positioned;

  /// Distance from the left when [positioned] in a Stack.
  final double? left;

  /// Distance from the top when [positioned] in a Stack.
  final double? top;

  /// Distance from the right when [positioned] in a Stack.
  final double? right;

  /// Distance from the bottom when [positioned] in a Stack.
  final double? bottom;

  /// Width when [positioned].
  final double? positionedWidth;

  /// Height when [positioned].
  final double? positionedHeight;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final BorderRadius? effectiveRadius = _uRadius(borderRadius, radius);
    final BoxDecoration? decoration = _uDecoration(
      color: color,
      gradient: gradient,
      image: image,
      border: border,
      borderRadius: effectiveRadius,
      boxShadow: boxShadow,
      shape: shape,
      backgroundBlendMode: backgroundBlendMode,
    );

    final BoxConstraints? sizeConstraints = (minWidth != null || maxWidth != null || minHeight != null || maxHeight != null)
        ? BoxConstraints(minWidth: minWidth ?? 0, maxWidth: maxWidth ?? double.infinity, minHeight: minHeight ?? 0, maxHeight: maxHeight ?? double.infinity)
        : null;

    final Widget current = AnimatedContainer(
      duration: duration,
      curve: curve,
      onEnd: onEnd,
      width: width,
      height: height,
      constraints: constraints ?? sizeConstraints,
      alignment: alignment,
      padding: padding,
      transform: transform,
      transformAlignment: transformAlignment,
      clipBehavior: decoration != null ? clipBehavior : Clip.none,
      foregroundDecoration: foregroundDecoration,
      color: decoration == null ? color : null,
      decoration: decoration,
      child: child,
    );

    return uWrap(
      current,
      borderRadius: effectiveRadius,
      onTap: onTap,
      onPress: onPress,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      splash: splash,
      splashColor: splashColor,
      highlightColor: highlightColor,
      hoverColor: hoverColor,
      pressedScale: pressedScale,
      cursor: cursor,
      onHover: onHover,
      opacity: opacity,
      tooltip: tooltip,
      heroTag: heroTag,
      margin: margin,
      semanticsLabel: semanticsLabel,
      fit: fit,
      fitAlignment: fitAlignment,
      scale: scale,
      rotate: rotate,
      translate: translate,
      center: center,
      safeArea: safeArea,
      scrollable: scrollable,
      scrollController: scrollController,
      textDirection: textDirection,
      expanded: expanded,
      flexible: flexible,
      positioned: positioned,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      positionedWidth: positionedWidth,
      positionedHeight: positionedHeight,
    );
  }
}

/// ListView with separators, box options and shrinkWrap. `UListView(itemCount: items.length, itemBuilder: (c, i) => Text(items[i]))`
class UListView extends StatelessWidget {
  const UListView({
    required this.itemBuilder,
    required this.itemCount,
    super.key,
    this.header,
    this.footer,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.scrollController,
    this.primary,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.separatorBuilder,
    this.margin,
    this.opacity,
    this.visible = true,
    this.tooltip,
    this.heroTag,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  /// Builds one item.
  final IndexedWidgetBuilder itemBuilder;

  /// Number of items.
  final int itemCount;

  /// Widget at the top.
  final Widget? header;

  /// Widget at the bottom.
  final Widget? footer;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Sizes to its content (inside another scrollable).
  final bool shrinkWrap;

  /// Space inside, around the content.
  final EdgeInsetsGeometry? padding;

  /// Scroll controller.
  final ScrollController? scrollController;

  /// Primary color.
  final bool? primary;

  /// Reverses the order.
  final bool reverse;

  /// Scroll axis.
  final Axis scrollDirection;

  /// Widget between items.
  final IndexedWidgetBuilder? separatorBuilder;

  /// Space outside, around the widget.
  final EdgeInsetsGeometry? margin;

  /// See-through amount, 0 (invisible) to 1 (solid).
  final double? opacity;

  /// False hides it completely (takes no space).
  final bool visible;

  /// Text shown on long press / mouse hover.
  final String? tooltip;

  /// Hero tag for a shared-element animation between pages.
  final String? heroTag;

  /// How the content fits its box (BoxFit).
  final BoxFit? fit;

  /// Alignment inside the box when it does not fill it.
  final AlignmentGeometry fitAlignment;

  /// Scales the painted widget (1 = normal size).
  final double? scale;

  /// Rotation in radians.
  final double? rotate;

  /// Moves the painted widget by this offset (layout unchanged).
  final Offset? translate;

  /// Centers it in the available space.
  final bool center;

  /// Keeps it out of the notch and system bars.
  final bool safeArea;

  /// Flex value to fill the remaining space in a Row/Column (null = off).
  final int? expanded;

  /// Flex value to shrink in a Row/Column when space is tight (null = off).
  final int? flexible;

  /// Wraps it in a Positioned (use inside a Stack) with top/left/right/bottom.
  final bool positioned;

  /// Distance from the left when [positioned] in a Stack.
  final double? left;

  /// Distance from the top when [positioned] in a Stack.
  final double? top;

  /// Distance from the right when [positioned] in a Stack.
  final double? right;

  /// Distance from the bottom when [positioned] in a Stack.
  final double? bottom;

  /// Width when [positioned].
  final double? positionedWidth;

  /// Height when [positioned].
  final double? positionedHeight;

  Widget _wrap(Widget child) => uWrap(
    child,
    margin: margin,
    opacity: opacity,
    visible: visible,
    tooltip: tooltip,
    heroTag: heroTag,
    fit: fit,
    fitAlignment: fitAlignment,
    scale: scale,
    rotate: rotate,
    translate: translate,
    center: center,
    safeArea: safeArea,
    expanded: expanded,
    flexible: flexible,
    positioned: positioned,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    positionedWidth: positionedWidth,
    positionedHeight: positionedHeight,
  );

  @override
  Widget build(BuildContext context) {
    final int headerOffset = header != null ? 1 : 0;
    final int totalCount = itemCount + headerOffset + (footer != null ? 1 : 0);

    Widget resolve(BuildContext context, int index) {
      if (header != null && index == 0) return header!;
      if (footer != null && index == totalCount - 1) return footer!;
      return itemBuilder(context, index - headerOffset);
    }

    if (separatorBuilder != null) {
      return _wrap(
        ListView.separated(
          itemCount: totalCount,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: padding,
          controller: scrollController,
          primary: primary,
          reverse: reverse,
          scrollDirection: scrollDirection,
          itemBuilder: resolve,
          separatorBuilder: separatorBuilder!,
        ),
      );
    }

    return _wrap(
      ListView.builder(
        itemCount: totalCount,
        physics: physics,
        shrinkWrap: shrinkWrap,
        padding: padding,
        controller: scrollController,
        primary: primary,
        reverse: reverse,
        scrollDirection: scrollDirection,
        itemBuilder: resolve,
      ),
    );
  }
}

/// GridView by column count or max tile width. `UGridView(crossAxisCount: 2, itemCount: items.length, itemBuilder: (c, i) => Tile(items[i]))`
class UGridView extends StatelessWidget {
  const UGridView({
    required this.itemBuilder,
    required this.itemCount,
    super.key,
    this.crossAxisCount,
    this.maxCrossAxisExtent,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.scrollController,
    this.primary,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.margin,
    this.opacity,
    this.visible = true,
    this.tooltip,
    this.heroTag,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  /// Builds one item.
  final IndexedWidgetBuilder itemBuilder;

  /// Number of items.
  final int itemCount;

  /// Number of columns.
  final int? crossAxisCount;

  /// Max tile width (columns adapt to screen width).
  final double? maxCrossAxisExtent;

  /// Gap between rows.
  final double mainAxisSpacing;

  /// Gap between columns.
  final double crossAxisSpacing;

  /// Tile width / height.
  final double childAspectRatio;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Sizes to its content (inside another scrollable).
  final bool shrinkWrap;

  /// Space inside, around the content.
  final EdgeInsetsGeometry? padding;

  /// Scroll controller.
  final ScrollController? scrollController;

  /// Primary color.
  final bool? primary;

  /// Reverses the order.
  final bool reverse;

  /// Scroll axis.
  final Axis scrollDirection;

  /// Space outside, around the widget.
  final EdgeInsetsGeometry? margin;

  /// See-through amount, 0 (invisible) to 1 (solid).
  final double? opacity;

  /// False hides it completely (takes no space).
  final bool visible;

  /// Text shown on long press / mouse hover.
  final String? tooltip;

  /// Hero tag for a shared-element animation between pages.
  final String? heroTag;

  /// How the content fits its box (BoxFit).
  final BoxFit? fit;

  /// Alignment inside the box when it does not fill it.
  final AlignmentGeometry fitAlignment;

  /// Scales the painted widget (1 = normal size).
  final double? scale;

  /// Rotation in radians.
  final double? rotate;

  /// Moves the painted widget by this offset (layout unchanged).
  final Offset? translate;

  /// Centers it in the available space.
  final bool center;

  /// Keeps it out of the notch and system bars.
  final bool safeArea;

  /// Flex value to fill the remaining space in a Row/Column (null = off).
  final int? expanded;

  /// Flex value to shrink in a Row/Column when space is tight (null = off).
  final int? flexible;

  /// Wraps it in a Positioned (use inside a Stack) with top/left/right/bottom.
  final bool positioned;

  /// Distance from the left when [positioned] in a Stack.
  final double? left;

  /// Distance from the top when [positioned] in a Stack.
  final double? top;

  /// Distance from the right when [positioned] in a Stack.
  final double? right;

  /// Distance from the bottom when [positioned] in a Stack.
  final double? bottom;

  /// Width when [positioned].
  final double? positionedWidth;

  /// Height when [positioned].
  final double? positionedHeight;

  Widget _wrap(Widget child) => uWrap(
    child,
    margin: margin,
    opacity: opacity,
    visible: visible,
    tooltip: tooltip,
    heroTag: heroTag,
    fit: fit,
    fitAlignment: fitAlignment,
    scale: scale,
    rotate: rotate,
    translate: translate,
    center: center,
    safeArea: safeArea,
    expanded: expanded,
    flexible: flexible,
    positioned: positioned,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    positionedWidth: positionedWidth,
    positionedHeight: positionedHeight,
  );

  @override
  Widget build(BuildContext context) {
    final SliverGridDelegate delegate = maxCrossAxisExtent != null
        ? SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxCrossAxisExtent!,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: childAspectRatio,
          )
        : SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount ?? 2,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: childAspectRatio,
          );

    return _wrap(
      GridView.builder(
        itemCount: itemCount,
        gridDelegate: delegate,
        physics: physics,
        shrinkWrap: shrinkWrap,
        padding: padding,
        controller: scrollController,
        primary: primary,
        reverse: reverse,
        scrollDirection: scrollDirection,
        itemBuilder: itemBuilder,
      ),
    );
  }
}

/// Sliver list for CustomScrollView.
class USliverList extends StatelessWidget {
  const USliverList({
    required this.itemBuilder,
    required this.itemCount,
    super.key,
    this.padding,
  });

  /// Builds one item.
  final IndexedWidgetBuilder itemBuilder;

  /// Number of items.
  final int itemCount;

  /// Space inside, around the content.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final Widget sliver = SliverList(
      delegate: SliverChildBuilderDelegate(itemBuilder, childCount: itemCount),
    );
    if (padding != null) return SliverPadding(padding: padding!, sliver: sliver);
    return sliver;
  }
}

/// Sliver grid for CustomScrollView.
class USliverGrid extends StatelessWidget {
  const USliverGrid({
    required this.itemBuilder,
    required this.itemCount,
    super.key,
    this.crossAxisCount,
    this.maxCrossAxisExtent,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.padding,
  });

  /// Builds one item.
  final IndexedWidgetBuilder itemBuilder;

  /// Number of items.
  final int itemCount;

  /// Number of columns.
  final int? crossAxisCount;

  /// Max tile width (columns adapt to screen width).
  final double? maxCrossAxisExtent;

  /// Gap between rows.
  final double mainAxisSpacing;

  /// Gap between columns.
  final double crossAxisSpacing;

  /// Tile width / height.
  final double childAspectRatio;

  /// Space inside, around the content.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final SliverGridDelegate delegate = maxCrossAxisExtent != null
        ? SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxCrossAxisExtent!,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: childAspectRatio,
          )
        : SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount ?? 2,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: childAspectRatio,
          );

    final Widget sliver = SliverGrid(
      delegate: SliverChildBuilderDelegate(itemBuilder, childCount: itemCount),
      gridDelegate: delegate,
    );
    if (padding != null) return SliverPadding(padding: padding!, sliver: sliver);
    return sliver;
  }
}

/// Center with size factors. `UCenter(child: logo)`
class UCenter extends StatelessWidget {
  const UCenter({
    required this.child,
    super.key,
    this.widthFactor,
    this.heightFactor,
  });

  /// The widget inside.
  final Widget child;

  /// Own width = child width × this (null = fill).
  final double? widthFactor;

  /// Own height = child height × this (null = fill).
  final double? heightFactor;

  @override
  Widget build(BuildContext context) => Center(
    widthFactor: widthFactor,
    heightFactor: heightFactor,
    child: child,
  );
}

/// Keeps a width/height ratio. `UAspectRatio(aspectRatio: 16 / 9, child: video)`
class UAspectRatio extends StatelessWidget {
  const UAspectRatio({
    required this.aspectRatio,
    required this.child,
    super.key,
  });

  /// Width / height ratio.
  final double aspectRatio;

  /// The widget inside.
  final Widget child;

  @override
  Widget build(BuildContext context) => AspectRatio(aspectRatio: aspectRatio, child: child);
}

/// Applies min/max width and height. `UConstrained(maxWidth: 600, child: form)`
class UConstrained extends StatelessWidget {
  const UConstrained({
    required this.child,
    super.key,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
  });

  /// The widget inside.
  final Widget child;

  /// Minimum width.
  final double? minWidth;

  /// Maximum width.
  final double? maxWidth;

  /// Minimum height.
  final double? minHeight;

  /// Maximum height.
  final double? maxHeight;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      minWidth: minWidth ?? 0,
      maxWidth: maxWidth ?? double.infinity,
      minHeight: minHeight ?? 0,
      maxHeight: maxHeight ?? double.infinity,
    ),
    child: child,
  );
}

/// Horizontal or vertical line. `const UDivider()`, `const UDivider(axis: Axis.vertical)`
class UDivider extends StatelessWidget {
  const UDivider({
    super.key,
    this.axis = Axis.horizontal,
    this.thickness,
    this.color,
    this.indent,
    this.endIndent,
    this.space,
  });

  /// Horizontal (default) or vertical.
  final Axis axis;

  /// Line thickness.
  final double? thickness;

  /// Main color (defaults to the theme).
  final Color? color;

  /// Empty space before the line.
  final double? indent;

  /// Empty space after the line.
  final double? endIndent;

  /// Total space the divider takes across its axis.
  final double? space;

  @override
  Widget build(BuildContext context) => axis == Axis.horizontal
      ? Divider(thickness: thickness, color: color, indent: indent, endIndent: endIndent, height: space)
      : VerticalDivider(thickness: thickness, color: color, indent: indent, endIndent: endIndent, width: space);
}

/// Shows a different widget on phone (<850), tablet (850-1100) and desktop (1100+) widths. `UResponsive(mobile: const ListLayout(), desktop: const GridLayout())`
class UResponsive extends StatelessWidget {
  const UResponsive({
    required this.mobile,
    super.key,
    this.tablet,
    this.desktop,
  });

  /// Widget under 850 wide.
  final Widget mobile;

  /// Widget from 850 to 1100 wide (falls back to mobile).
  final Widget? tablet;

  /// Widget at 1100+ (falls back to tablet, then mobile).
  final Widget? desktop;

  @override
  Widget build(BuildContext context) => context.isDesktopSize
      ? (desktop ?? tablet ?? mobile)
      : context.isTabletSize
      ? (tablet ?? mobile)
      : mobile;
}
