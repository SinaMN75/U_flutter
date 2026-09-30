import "package:u/utilities.dart";

/// Base State with theme and screen shortcuts; extend it instead of State. `class _PageState extends UState<Page> { … scheme.primary … }`
abstract class UState<T extends StatefulWidget> extends State<T> {
  /// The theme's colors.
  ColorScheme get scheme => Theme.of(context).colorScheme;

  /// Theme.of(context).
  ThemeData get theme => Theme.of(context);

  /// MediaQuery.of(context).
  MediaQueryData get mediaQuery => MediaQuery.of(context);

  /// Screen size.
  Size get screenSize => mediaQuery.size;

  /// Space taken by the status bar / notch / home bar.
  EdgeInsets get padding => mediaQuery.padding;

  /// Safe-area padding, ignoring the keyboard.
  EdgeInsets get viewPadding => mediaQuery.viewPadding;

  /// Space taken by the keyboard.
  EdgeInsets get viewInsets => mediaQuery.viewInsets;

  /// Screen width.
  double get width => screenSize.width;

  /// Screen height.
  double get height => screenSize.height;

  /// True when the app language is Persian.
  bool get isFa => Localizations.localeOf(context).languageCode == "fa";
}

/// Chainable wrappers for any widget: padding, taps, alignment, visibility, decoration. `Text("Hi").pAll(8).onTap(open)`
extension WidgetsExtension on Widget {
  /// Same padding on every side. `child.pAll(16)`
  Widget pAll(double padding) => Padding(padding: EdgeInsets.all(padding), child: this);

  /// Horizontal and/or vertical padding. `child.pSymmetric(horizontal: 16)`
  Widget pSymmetric({double horizontal = 0.0, double vertical = 0.0}) => Padding(
    padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
    child: this,
  );

  /// Padding on chosen sides. `child.pOnly(top: 8)`
  Widget pOnly({double left = 0.0, double top = 0.0, double right = 0.0, double bottom = 0.0}) => Padding(
    padding: EdgeInsets.only(top: top, left: left, right: right, bottom: bottom),
    child: this,
  );

  /// Padding left, top, right, bottom. `child.pLTRB(8, 4, 8, 4)`
  Widget pLTRB(double left, double top, double right, double bottom) => Padding(padding: EdgeInsets.fromLTRB(left, top, right, bottom), child: this);

  /// Shrinks to fit the space (never grows). `Text(long).fit()`
  Widget fit({Alignment alignment = Alignment.center}) => FittedBox(key: key, alignment: alignment, fit: BoxFit.scaleDown, child: this);

  /// Takes the remaining space in a Row/Column. `child.expanded()`
  Widget expanded({int flex = 1}) => Expanded(flex: flex, child: this);

  /// Can shrink in a Row/Column but does not have to fill. `child.flexible()`
  Widget flexible({int flex = 1}) => Flexible(flex: flex, child: this);

  /// Tap without ripple. `child.onTap(open)`
  Widget onTap(GestureTapCallback? onPressed) => GestureDetector(onTap: onPressed, child: this);

  /// Tap with a press-down shrink animation. `card.onPress(open)`
  Widget onPress(VoidCallback onTap, {double pressedScale = 0.9, Duration duration = const Duration(milliseconds: 120)}) =>
      UPressable(onTap: onTap, duration: duration, pressedScale: pressedScale, child: this);

  /// Tap with a Material ripple (needs a Material ancestor). `tile.onTapInk(open)`
  Widget onTapInk(GestureTapCallback? onPressed) => InkWell(onTap: onPressed, child: this);

  /// Shows a popup menu where the user taps; items return their int value. `child.showMenus([PopupMenuItem(value: 1, child: Text("Edit"))])`
  Widget showMenus(List<PopupMenuEntry<int>> items) => GestureDetector(
    onTapDown: (TapDownDetails details) async {
      final Size screenSize = MediaQuery.of(navigatorKey.currentContext!).size;
      final Offset p = details.globalPosition;
      await showMenu<int>(
        context: navigatorKey.currentContext!,
        position: RelativeRect.fromLTRB(p.dx, p.dy, screenSize.width - p.dx, screenSize.height - p.dy),
        items: items,
      );
    },
    child: this,
  );

  /// Long press. `child.onLongPress(showOptions)`
  Widget onLongPress(GestureTapCallback? onPressed) => GestureDetector(onLongPress: onPressed, child: this);

  /// Double tap. `image.onDoubleTap(like)`
  Widget onDoubleTap(GestureTapCallback? onPressed) => GestureDetector(onDoubleTap: onPressed, child: this);

  /// Forces left-to-right (numbers, phone numbers, code). `Text(phone).ltr()`
  Widget ltr() => Directionality(textDirection: TextDirection.ltr, child: this);

  /// Forces right-to-left. `child.rtl()`
  Widget rtl() => Directionality(textDirection: TextDirection.rtl, child: this);

  /// Scales the paint (layout size unchanged). `icon.scale(1.5)`
  Widget scale(double scale) => Transform.scale(scale: scale, child: this);

  /// Moves the paint by [offset] (layout unchanged). `child.translate(const Offset(0, -4))`
  Widget translate(Offset offset) => Transform.translate(offset: offset, child: this);

  /// Positioned inside a Stack. `badge.position(top: 0, right: 0)`
  Widget position({double? left, double? top, double? right, double? bottom, double? width, double? height}) =>
      Positioned(left: left, top: top, right: right, bottom: bottom, width: width, height: height, child: this);

  /// Rotates by [scale] radians. `arrow.rotate(pi / 2)`
  Widget rotate(double scale) => Transform.rotate(angle: scale, child: this);

  /// Keeps it out of the notch and system bars. `body.safeArea()`
  Widget safeArea() => SafeArea(child: this);

  /// Wraps in a Form with [key]. `column.form(formKey)`
  Widget form(GlobalKey<FormState> key) => Form(key: key, child: this);

  /// Makes it scroll when it does not fit. `column.scrollable()`
  Widget scrollable({Axis scrollDirection = Axis.vertical}) => SingleChildScrollView(scrollDirection: scrollDirection, child: this);

  /// Fades and slides up once when first shown. `card.fadeSlideIn()`
  Widget fadeSlideIn({int milliseconds = 1000, double offset = 24}) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: Duration(milliseconds: milliseconds),
    curve: Curves.easeOutCubic,
    builder: (BuildContext context, double value, Widget? child) => Opacity(
      opacity: value,
      child: Transform.translate(offset: Offset(0, offset * (1 - value)), child: child),
    ),
    child: this,
  );

  /// Box with background, border and rounded corners. `child.container(backgroundColor: Colors.white, radius: 12)`
  Widget container({
    double? width,
    double? height,
    Alignment? alignment,
    Color? backgroundColor,
    double borderWidth = 1,
    double radius = 1,
    Color borderColor = Colors.transparent,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BoxConstraints? constraints,
  }) => Container(
    clipBehavior: Clip.hardEdge,
    constraints: constraints,
    width: width,
    height: height,
    padding: padding,
    margin: margin,
    alignment: alignment,
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
    ),
    child: this,
  );

  /// Pill-shaped colored box, e.g. for tags. `Text("New").chip(backgroundColor: Colors.green.shade100)`
  Widget chip({
    required Color backgroundColor,
    double? width,
    double? height,
    Alignment? alignment,
    double borderWidth = 1,
    double radius = 12,
    Color borderColor = Colors.transparent,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    EdgeInsetsGeometry? margin,
    BoxConstraints? constraints,
  }) => container(
    width: width,
    height: height,
    alignment: alignment,
    backgroundColor: backgroundColor,
    borderWidth: borderWidth,
    radius: radius,
    borderColor: borderColor,
    padding: padding,
    margin: margin,
    constraints: constraints,
  );

  /// Material Card around it. `child.card(elevation: 2)`
  Widget card({Color? backgroundColor, double? elevation, EdgeInsetsGeometry? margin}) =>
      Card(clipBehavior: Clip.hardEdge, margin: margin, elevation: elevation, color: backgroundColor, surfaceTintColor: backgroundColor, child: this);

  /// Aligned to the bottom center.
  Align alignAtBottomCenter({Key? key, double? heightFactor, double? widthFactor}) =>
      Align(key: key, alignment: Alignment.bottomCenter, heightFactor: heightFactor, widthFactor: widthFactor, child: this);

  /// Aligned to the top left.
  Align alignAtTopLeft({Key? key, double? heightFactor, double? widthFactor}) => Align(key: key, alignment: Alignment.topLeft, heightFactor: heightFactor, widthFactor: widthFactor, child: this);

  /// Aligned to the bottom left.
  Align alignAtBottomLeft({Key? key, double? heightFactor, double? widthFactor}) => Align(key: key, alignment: Alignment.bottomLeft, heightFactor: heightFactor, widthFactor: widthFactor, child: this);

  /// Aligned to the bottom right.
  Align alignAtBottomRight({Key? key, double? heightFactor, double? widthFactor}) =>
      Align(key: key, alignment: Alignment.bottomRight, heightFactor: heightFactor, widthFactor: widthFactor, child: this);

  /// Aligned to the center left.
  Align alignAtCenterLeft({Key? key, double? heightFactor, double? widthFactor}) => Align(key: key, alignment: Alignment.centerLeft, heightFactor: heightFactor, widthFactor: widthFactor, child: this);

  /// Centered.
  Align alignAtCenter({Key? key, double? heightFactor, double? widthFactor}) => Align(key: key, heightFactor: heightFactor, widthFactor: widthFactor, child: this);

  /// Aligned to the center right.
  Align alignAtCenterRight({Key? key, double? heightFactor, double? widthFactor}) =>
      Align(key: key, alignment: Alignment.centerRight, heightFactor: heightFactor, widthFactor: widthFactor, child: this);

  /// Aligned between [a] and [b] at [t] (0 = a, 1 = b).
  Align alignAtLERP(Alignment a, Alignment b, double t, {Key? key, double? heightFactor, double? widthFactor}) =>
      Align(key: key, alignment: Alignment.lerp(a, b, t)!, heightFactor: heightFactor, widthFactor: widthFactor, child: this);

  /// Aligned at x, y from -1 to 1. `child.alignXY(0, -0.5)`
  Align alignXY(double x, double y, {Key? key, double? heightFactor, double? widthFactor}) =>
      Align(key: key, alignment: Alignment(x, y), heightFactor: heightFactor, widthFactor: widthFactor, child: this);

  /// Aligned to the top center.
  Align alignAtTopCenter({Key? key, double? heightFactor, double? widthFactor}) => Align(key: key, alignment: Alignment.topCenter, heightFactor: heightFactor, widthFactor: widthFactor, child: this);

  /// Aligned to the top right.
  Align alignAtTopRight({Key? key, double? heightFactor, double? widthFactor}) => Align(key: key, alignment: Alignment.topRight, heightFactor: heightFactor, widthFactor: widthFactor, child: this);

  /// Centered in the available space. `child.center()`
  Widget center() => Center(child: this);

  /// Fixed width and/or height. `logo.sized(width: 48, height: 48)`
  Widget sized({double? width, double? height}) => SizedBox(width: width, height: height, child: this);

  /// Shows it only when [visible]; with [maintainSize] it keeps its space. `saveButton.visible(isDirty)`
  Widget visible(bool visible, {bool maintainSize = false}) => Visibility(visible: visible, maintainSize: maintainSize, maintainAnimation: maintainSize, maintainState: maintainSize, child: this);

  /// Makes it see-through (0 = invisible, 1 = solid). `child.opacity(0.5)`
  Widget opacity(double opacity) => Opacity(opacity: opacity, child: this);

  /// Rounds the corners by clipping. `image.clipRadius(12)`
  Widget clipRadius(double radius) => ClipRRect(borderRadius: BorderRadius.circular(radius), child: this);

  /// Clips to a circle. `avatar.clipCircle()`
  Widget clipCircle() => ClipOval(child: this);

  /// Shows [message] on long press / mouse hover. `icon.tooltip("Delete")`
  Widget tooltip(String message) => Tooltip(message: message, child: this);

  /// Hero animation between pages with the same [tag]. `image.hero("product-$id")`
  Widget hero(Object tag) => Hero(tag: tag, child: this);

  /// Lets a normal widget sit inside a CustomScrollView. `header.sliver()`
  Widget sliver() => SliverToBoxAdapter(child: this);

  /// Greys out and blocks taps when [disabled]. `form.disabled(isSaving)`
  Widget disabled(bool disabled, {double opacity = 0.5}) => disabled
      ? IgnorePointer(
          child: Opacity(opacity: opacity, child: this),
        )
      : this;

  /// Draws a shimmering loading placeholder in its shape while [loading]. `Text("Name").skeleton(isLoading)`
  Widget skeleton(bool loading) => loading ? USkeleton.wrap(child: this) : this;
}
