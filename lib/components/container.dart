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

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final List<Widget>? persistentFooterButtons;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final BoxDecoration? decoration;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  final bool primary;
  final Color? drawerScrimColor;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final BoxConstraints? constraints;
  final double? width;
  final double? height;
  final DrawerCallback? onDrawerChanged;
  final DrawerCallback? onEndDrawerChanged;
  final Alignment? alignment;
  final bool safeArea;
  final EdgeInsets safeAreaEdges;
  final bool? resizeToAvoidBottomInset;
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

  final List<Widget> children;
  final Widget tabBar;
  final double? width;
  final double? height;
  final int initialIndex;
  final TabController? controller;
  final ScrollPhysics? physics;
  final Color? indicatorColor;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final double indicatorWeight;
  final bool isScrollable;
  final DragStartBehavior dragStartBehavior;
  final double viewportFraction;
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

  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final DecorationImage? image;
  final BoxBorder? border;
  final double? radius;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final double? minWidth;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final BoxConstraints? constraints;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;
  final Matrix4? transform;
  final AlignmentGeometry? transformAlignment;
  final Decoration? foregroundDecoration;
  final BoxShape shape;
  final BlendMode? backgroundBlendMode;
  final GestureTapCallback? onTap;
  final GestureTapCallback? onDoubleTap;
  final GestureLongPressCallback? onLongPress;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final GestureTapCallback? onSecondaryTap;
  final HitTestBehavior? hitTestBehavior;
  final bool splash;
  final Color? splashColor;
  final Color? highlightColor;
  final Color? hoverColor;
  final double? pressedScale;
  final Duration pressDuration;
  final bool enableFeedback;
  final MouseCursor? cursor;
  final ValueChanged<bool>? onHover;
  final double? opacity;
  final String? tooltip;
  final String? semanticsLabel;
  final bool? semanticsButton;
  final bool visible;
  final String? heroTag;
  final VoidCallback? onPress;
  final BoxFit? fit;
  final AlignmentGeometry fitAlignment;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final Axis? scrollable;
  final ScrollController? scrollController;
  final TextDirection? textDirection;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
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

  final List<Widget> children;
  final double spacing;
  final double? width;
  final double? height;
  final double? minWidth;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double? radius;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BoxBorder? border;
  final Color? color;
  final Gradient? gradient;
  final DecorationImage? image;
  final List<BoxShadow>? boxShadow;
  final BoxConstraints? constraints;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;
  final Matrix4? transform;
  final AlignmentGeometry? transformAlignment;
  final Decoration? foregroundDecoration;
  final BoxShape shape;
  final BlendMode? backgroundBlendMode;
  final GestureTapCallback? onTap;
  final GestureTapCallback? onDoubleTap;
  final GestureLongPressCallback? onLongPress;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final GestureTapCallback? onSecondaryTap;
  final HitTestBehavior? hitTestBehavior;
  final bool splash;
  final Color? splashColor;
  final Color? highlightColor;
  final Color? hoverColor;
  final double? pressedScale;
  final MouseCursor? cursor;
  final ValueChanged<bool>? onHover;
  final double? opacity;
  final String? tooltip;
  final String? semanticsLabel;
  final bool? semanticsButton;
  final bool visible;
  final String? heroTag;

  final VoidCallback? onPress;
  final BoxFit? fit;
  final AlignmentGeometry fitAlignment;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final Axis? scrollable;
  final ScrollController? scrollController;
  final TextDirection? textDirection;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
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

  final List<Widget> children;
  final double spacing;
  final double? width;
  final double? height;
  final double? minWidth;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double? radius;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BoxBorder? border;
  final Color? color;
  final Gradient? gradient;
  final DecorationImage? image;
  final List<BoxShadow>? boxShadow;
  final BoxConstraints? constraints;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;
  final Matrix4? transform;
  final AlignmentGeometry? transformAlignment;
  final Decoration? foregroundDecoration;
  final BoxShape shape;
  final BlendMode? backgroundBlendMode;
  final GestureTapCallback? onTap;
  final GestureTapCallback? onDoubleTap;
  final GestureLongPressCallback? onLongPress;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final GestureTapCallback? onSecondaryTap;
  final HitTestBehavior? hitTestBehavior;
  final bool splash;
  final Color? splashColor;
  final Color? highlightColor;
  final Color? hoverColor;
  final double? pressedScale;
  final MouseCursor? cursor;
  final ValueChanged<bool>? onHover;
  final double? opacity;
  final String? tooltip;
  final String? semanticsLabel;
  final bool? semanticsButton;
  final bool visible;
  final String? heroTag;

  final VoidCallback? onPress;
  final BoxFit? fit;
  final AlignmentGeometry fitAlignment;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final Axis? scrollable;
  final ScrollController? scrollController;
  final TextDirection? textDirection;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
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

  final List<Widget> children;
  final AlignmentGeometry stackAlignment;
  final StackFit fit;
  final Clip stackClip;
  final TextDirection? textDirection;
  final double? width;
  final double? height;
  final double? minWidth;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Gradient? gradient;
  final DecorationImage? image;
  final BoxBorder? border;
  final double? radius;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final BoxConstraints? constraints;
  final BoxShape shape;
  final BlendMode? backgroundBlendMode;
  final Decoration? foregroundDecoration;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onDoubleTap;
  final bool splash;
  final double? pressedScale;
  final MouseCursor? cursor;
  final ValueChanged<bool>? onHover;
  final double? opacity;
  final String? tooltip;
  final String? semanticsLabel;
  final bool visible;
  final String? heroTag;

  final VoidCallback? onPress;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final Axis? scrollable;
  final ScrollController? scrollController;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
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

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final Axis direction;
  final WrapAlignment wrapAlignment;
  final WrapAlignment runAlignment;
  final WrapCrossAlignment crossAxisAlignment;
  final VerticalDirection verticalDirection;
  final TextDirection? textDirection;
  final Clip wrapClip;
  final double? width;
  final double? height;
  final double? minWidth;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Gradient? gradient;
  final DecorationImage? image;
  final BoxBorder? border;
  final double? radius;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final BoxConstraints? constraints;
  final AlignmentGeometry? alignment;
  final BoxShape shape;
  final BlendMode? backgroundBlendMode;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onDoubleTap;
  final bool splash;
  final double? pressedScale;
  final MouseCursor? cursor;
  final ValueChanged<bool>? onHover;
  final double? opacity;
  final String? tooltip;
  final String? semanticsLabel;
  final bool visible;
  final String? heroTag;

  final VoidCallback? onPress;
  final BoxFit? fit;
  final AlignmentGeometry fitAlignment;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final Axis? scrollable;
  final ScrollController? scrollController;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
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

  final Widget leading;
  final Widget trailing;
  final double spaceBetween;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onDoubleTap;
  final ValueChanged<bool>? onHover;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final Color? color;
  final Gradient? gradient;
  final BoxBorder? border;
  final double? radius;
  final List<BoxShadow>? boxShadow;
  final AlignmentGeometry? alignment;
  final double? opacity;
  final String? tooltip;
  final String? semanticsLabel;
  final MouseCursor? cursor;
  final bool splash;
  final double? pressedScale;
  final bool visible;

  final VoidCallback? onPress;
  final BoxFit? fit;
  final AlignmentGeometry fitAlignment;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final Axis? scrollable;
  final ScrollController? scrollController;
  final TextDirection? textDirection;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
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

  final Widget leading;
  final Widget trailing;
  final double spaceBetween;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onDoubleTap;
  final ValueChanged<bool>? onHover;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final Color? color;
  final Gradient? gradient;
  final BoxBorder? border;
  final double? radius;
  final List<BoxShadow>? boxShadow;
  final AlignmentGeometry? alignment;
  final double? opacity;
  final String? tooltip;
  final String? semanticsLabel;
  final MouseCursor? cursor;
  final bool splash;
  final double? pressedScale;
  final bool visible;

  final VoidCallback? onPress;
  final BoxFit? fit;
  final AlignmentGeometry fitAlignment;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final Axis? scrollable;
  final ScrollController? scrollController;
  final TextDirection? textDirection;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
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

  final Widget leading;
  final Widget trailing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final ValueChanged<bool>? onHover;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Gradient? gradient;
  final BoxBorder? border;
  final double? radius;
  final List<BoxShadow>? boxShadow;
  final double? opacity;
  final String? tooltip;
  final String? semanticsLabel;
  final bool splash;
  final bool visible;

  final VoidCallback? onPress;
  final BoxFit? fit;
  final AlignmentGeometry fitAlignment;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final Axis? scrollable;
  final ScrollController? scrollController;
  final TextDirection? textDirection;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
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

  final Widget child;
  final double elevation;
  final double? width;
  final double? height;
  final Color? color;
  final BorderRadius borderRadius;
  final EdgeInsets margin;
  final EdgeInsets? padding;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onDoubleTap;
  final ValueChanged<bool>? onHover;
  final Color? splashColor;
  final Color? highlightColor;
  final Color? hoverColor;
  final BorderSide? border;
  final String? semanticsLabel;
  final VoidCallback? onPress;
  final double? opacity;
  final bool visible;
  final String? tooltip;
  final String? heroTag;
  final MouseCursor? cursor;
  final BoxFit? fit;
  final AlignmentGeometry fitAlignment;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final Axis? scrollable;
  final ScrollController? scrollController;
  final TextDirection? textDirection;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
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

  final Widget? child;
  final Duration duration;
  final Curve curve;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Gradient? gradient;
  final DecorationImage? image;
  final BoxBorder? border;
  final double? radius;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final double? minWidth;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final BoxConstraints? constraints;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;
  final Matrix4? transform;
  final AlignmentGeometry? transformAlignment;
  final Decoration? foregroundDecoration;
  final BoxShape shape;
  final BlendMode? backgroundBlendMode;
  final GestureTapCallback? onTap;
  final GestureTapCallback? onDoubleTap;
  final GestureLongPressCallback? onLongPress;
  final bool splash;
  final Color? splashColor;
  final Color? highlightColor;
  final Color? hoverColor;
  final double? pressedScale;
  final MouseCursor? cursor;
  final ValueChanged<bool>? onHover;
  final double? opacity;
  final String? tooltip;
  final String? semanticsLabel;
  final bool visible;
  final String? heroTag;
  final VoidCallback? onEnd;
  final VoidCallback? onPress;
  final BoxFit? fit;
  final AlignmentGeometry fitAlignment;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final Axis? scrollable;
  final ScrollController? scrollController;
  final TextDirection? textDirection;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
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

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final Widget? header;
  final Widget? footer;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsets? padding;
  final ScrollController? scrollController;
  final bool? primary;
  final bool reverse;
  final Axis scrollDirection;
  final IndexedWidgetBuilder? separatorBuilder;
  final EdgeInsetsGeometry? margin;
  final double? opacity;
  final bool visible;
  final String? tooltip;
  final String? heroTag;
  final BoxFit? fit;
  final AlignmentGeometry fitAlignment;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
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

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final int? crossAxisCount;
  final double? maxCrossAxisExtent;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsets? padding;
  final ScrollController? scrollController;
  final bool? primary;
  final bool reverse;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? margin;
  final double? opacity;
  final bool visible;
  final String? tooltip;
  final String? heroTag;
  final BoxFit? fit;
  final AlignmentGeometry fitAlignment;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
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

class USliverList extends StatelessWidget {
  const USliverList({
    required this.itemBuilder,
    required this.itemCount,
    super.key,
    this.padding,
  });

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final Widget sliver = SliverList(
      delegate: SliverChildBuilderDelegate(itemBuilder, childCount: itemCount),
    );
    if (padding != null) return SliverPadding(padding: padding!, sliver: sliver);
    return sliver;
  }
}

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

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final int? crossAxisCount;
  final double? maxCrossAxisExtent;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets? padding;

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

class UCenter extends StatelessWidget {
  const UCenter({
    required this.child,
    super.key,
    this.widthFactor,
    this.heightFactor,
  });

  final Widget child;
  final double? widthFactor;
  final double? heightFactor;

  @override
  Widget build(BuildContext context) => Center(
    widthFactor: widthFactor,
    heightFactor: heightFactor,
    child: child,
  );
}

class UAspectRatio extends StatelessWidget {
  const UAspectRatio({
    required this.aspectRatio,
    required this.child,
    super.key,
  });

  final double aspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) => AspectRatio(aspectRatio: aspectRatio, child: child);
}

class UConstrained extends StatelessWidget {
  const UConstrained({
    required this.child,
    super.key,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
  });

  final Widget child;
  final double? minWidth;
  final double? maxWidth;
  final double? minHeight;
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

  final Axis axis;
  final double? thickness;
  final Color? color;
  final double? indent;
  final double? endIndent;
  final double? space;

  @override
  Widget build(BuildContext context) => axis == Axis.horizontal
      ? Divider(thickness: thickness, color: color, indent: indent, endIndent: endIndent, height: space)
      : VerticalDivider(thickness: thickness, color: color, indent: indent, endIndent: endIndent, width: space);
}

class UResponsive extends StatelessWidget {
  const UResponsive({
    required this.mobile,
    super.key,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) => context.isDesktopSize
      ? (desktop ?? tablet ?? mobile)
      : context.isTabletSize
      ? (tablet ?? mobile)
      : mobile;
}
