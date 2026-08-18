import "package:u/utilities.dart";

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

  @override
  Widget build(BuildContext context) {
    Widget content = GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        width: width,
        height: height,
        constraints: constraints,
        decoration: decoration,
        padding: padding,
        margin: margin,
        alignment: alignment,
        child: body,
      ),
    );

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
    this.backgroundColor,
    this.borderRadius,
    this.elevation = 0.0,
    this.padding = EdgeInsets.zero,
  });

  final Widget leading;
  final Widget trailing;
  final double spaceBetween;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final double elevation;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: <Widget>[
        leading,
        SizedBox(width: spaceBetween),
        trailing,
      ],
    );

    content = Padding(padding: padding, child: content);

    if (onTap != null || elevation > 0 || backgroundColor != null || borderRadius != null) {
      content = Card(
        elevation: elevation,
        color: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: borderRadius ?? BorderRadius.circular(8)),
        child: InkWell(onTap: onTap, child: content),
      );
    }

    return content;
  }
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
  });

  final Widget leading;
  final Widget trailing;
  final double spaceBetween;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    mainAxisSize: mainAxisSize,
    children: <Widget>[
      leading,
      SizedBox(height: spaceBetween),
      trailing,
    ],
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
    this.boxShadow,
    this.width,
    this.height,
    this.constraints,
    this.alignment,
    this.clipBehavior = Clip.none,
    this.transform,
    this.foregroundDecoration,
  });

  final Widget? child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Gradient? gradient;
  final DecorationImage? image;
  final BoxBorder? border;
  final double? radius;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;
  final Matrix4? transform;
  final Decoration? foregroundDecoration;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    margin: margin,
    width: width,
    height: height,
    constraints: constraints,
    alignment: alignment,
    transform: transform,
    foregroundDecoration: foregroundDecoration,
    decoration: BoxDecoration(
      color: color,
      gradient: gradient,
      image: image,
      border: border,
      borderRadius: BorderRadius.circular(radius ?? 0),
      boxShadow: boxShadow,
    ),
    clipBehavior: clipBehavior,
    child: child,
  );
}

class UColumn extends StatelessWidget {
  const UColumn({
    required this.children,
    super.key,
    this.spacing = 8.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.radius,
    this.border,
    this.color,
    this.gradient,
    this.image,
    this.boxShadow,
    this.constraints,
    this.alignment,
    this.clipBehavior = Clip.hardEdge,
    this.transform,
    this.foregroundDecoration,
  });

  final List<Widget> children;
  final double spacing;
  final double? width;
  final double? height;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double? radius;
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
  final Decoration? foregroundDecoration;

  @override
  Widget build(BuildContext context) => UContainer(
    color: color,
    width: width,
    height: height,
    padding: padding,
    margin: margin,
    radius: radius,
    border: border,
    constraints: constraints,
    alignment: alignment,
    transform: transform,
    foregroundDecoration: foregroundDecoration,
    gradient: gradient,
    image: image,
    boxShadow: boxShadow,
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
    this.spacing = 8.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.radius,
    this.border,
    this.color,
    this.gradient,
    this.image,
    this.boxShadow,
    this.constraints,
    this.alignment,
    this.clipBehavior = Clip.hardEdge,
    this.transform,
    this.foregroundDecoration,
  });

  final List<Widget> children;
  final double spacing;
  final double? width;
  final double? height;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double? radius;
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
  final Decoration? foregroundDecoration;

  @override
  Widget build(BuildContext context) => UContainer(
    color: color,
    width: width,
    height: height,
    padding: padding,
    margin: margin,
    radius: radius,
    border: border,
    constraints: constraints,
    alignment: alignment,
    transform: transform,
    foregroundDecoration: foregroundDecoration,
    gradient: gradient,
    image: image,
    boxShadow: boxShadow,
    child: Row(
      spacing: spacing,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
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
    this.shadowColor,
    this.width,
    this.height,
  });

  final Widget child;
  final double elevation;
  final double? width;
  final double? height;
  final Color? color;
  final BorderRadius borderRadius;
  final EdgeInsets margin;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) => Card(
    elevation: elevation,
    color: color,
    shape: RoundedRectangleBorder(borderRadius: borderRadius),
    margin: margin,
    shadowColor: shadowColor,
    child: SizedBox(
      width: width,
      height: height,
      child: child,
    ),
  );
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
  });

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount; // number of main items
  final Widget? header;
  final Widget? footer;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsets? padding;
  final ScrollController? scrollController;
  final bool? primary;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final int totalCount = itemCount + (header != null ? 1 : 0) + (footer != null ? 1 : 0);

    return ListView.builder(
      itemCount: totalCount,
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding,
      controller: scrollController,
      primary: primary,
      reverse: reverse,
      itemBuilder: (BuildContext context, int index) {
        if (header != null && index == 0) return header!;
        final int headerOffset = header != null ? 1 : 0;
        if (footer != null && index == totalCount - 1) return footer!;
        final int adjustedIndex = index - headerOffset;
        return itemBuilder(context, adjustedIndex);
      },
    );
  }
}
