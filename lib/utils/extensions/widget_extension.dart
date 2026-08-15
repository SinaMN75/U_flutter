import "package:u/utilities.dart";

extension WidgetsExtension on Widget {
  Widget pAll(double padding) => Padding(padding: EdgeInsets.all(padding), child: this);

  Widget pSymmetric({double horizontal = 0.0, double vertical = 0.0}) => Padding(
    padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
    child: this,
  );

  Widget pOnly({
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) => Padding(
    padding: EdgeInsets.only(top: top, left: left, right: right, bottom: bottom),
    child: this,
  );

  Widget fit({Alignment alignment = Alignment.center}) => FittedBox(
    key: key,
    alignment: alignment,
    fit: BoxFit.scaleDown,
    child: this,
  );

  Widget expanded({int flex = 1}) => Expanded(flex: flex, child: this);

  Widget onTap(GestureTapCallback? onPressed) => GestureDetector(onTap: onPressed, child: this);

  Widget onPress(
    VoidCallback onTap, {
    double pressedScale = 0.9,
    Duration duration = const Duration(milliseconds: 120),
  }) => UPressable(onTap: onTap, duration: duration, pressedScale: pressedScale, child: this);

  Widget onTapInk(GestureTapCallback? onPressed) => InkWell(onTap: onPressed, child: this);

  Widget showMenus(List<PopupMenuEntry<int>> items) => GestureDetector(
    onTapDown: (TapDownDetails details) async {
      final Size screenSize = MediaQuery.of(navigatorKey.currentContext!).size;
      final double left = details.globalPosition.dx;
      final double top = details.globalPosition.dy;
      final double right = screenSize.width - details.globalPosition.dx;
      final double bottom = screenSize.height - details.globalPosition.dy;
      await showMenu<int>(
        context: navigatorKey.currentContext!,
        position: RelativeRect.fromLTRB(left, top, right, bottom),
        items: items,
      );
    },
    child: this,
  );

  Widget onLongPress(GestureTapCallback? onPressed) => GestureDetector(onLongPress: onPressed, child: this);

  Widget onDoubleTap(GestureTapCallback? onPressed) => GestureDetector(onDoubleTap: onPressed, child: this);

  Widget ltr() => Directionality(textDirection: TextDirection.ltr, child: this);

  Widget rtl() => Directionality(textDirection: TextDirection.rtl, child: this);

  Widget scale(double scale) => Transform.scale(scale: scale, child: this);

  Widget translate(Offset offset) => Transform.translate(offset: offset, child: this);

  Widget position({double? left, double? top, double? right, double? bottom, double? width, double? height}) => Positioned(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    width: width,
    height: height,
    child: this,
  );

  Widget rotate(double scale) => Transform.rotate(angle: scale, child: this);

  Widget safeArea() => SafeArea(child: this);

  Widget form(GlobalKey<FormState> key) => Form(key: key, child: this);

  Widget scrollable({Axis scrollDirection = Axis.vertical}) => SingleChildScrollView(
    scrollDirection: scrollDirection,
    child: this,
  );

  Widget fadeSlideIn({
    int milliseconds = 1000,
    double offset = 24,
  }) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: Duration(milliseconds: milliseconds),
    curve: Curves.easeOutCubic,
    builder: (BuildContext context, double value, Widget? child) => Opacity(
      opacity: value,
      child: Transform.translate(offset: Offset(0, offset * (1 - value)), child: child),
    ),
    child: this,
  );

  Widget container({
    double? width,
    double? height,
    Alignment? alignment,
    Color? backgroundColor,
    double borderWidth = 1,
    double radius = 1,
    Color borderColor = Colors.transparent,
    EdgeInsets? padding,
    EdgeInsets? margin,
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

  Widget card({
    Color? backgroundColor,
    double? elevation,
    EdgeInsets? margin,
  }) => Card(
    clipBehavior: Clip.hardEdge,
    margin: margin,
    elevation: elevation,
    color: backgroundColor,
    surfaceTintColor: backgroundColor,
    child: this,
  );

  Align alignAtBottomCenter({Key? key, double? heightFactor, double? widthFactor}) => Align(
    key: key,
    alignment: Alignment.bottomCenter,
    heightFactor: heightFactor,
    widthFactor: widthFactor,
    child: this,
  );

  Align alignAtTopLeft({Key? key, double? heightFactor, double? widthFactor}) => Align(
    key: key,
    alignment: Alignment.topLeft,
    heightFactor: heightFactor,
    widthFactor: widthFactor,
    child: this,
  );

  Align alignAtBottomLeft({Key? key, double? heightFactor, double? widthFactor}) => Align(
    key: key,
    alignment: Alignment.bottomLeft,
    heightFactor: heightFactor,
    widthFactor: widthFactor,
    child: this,
  );

  Align alignAtBottomRight({Key? key, double? heightFactor, double? widthFactor}) => Align(
    key: key,
    alignment: Alignment.bottomRight,
    heightFactor: heightFactor,
    widthFactor: widthFactor,
    child: this,
  );

  Align alignAtCenterLeft({Key? key, double? heightFactor, double? widthFactor}) => Align(
    key: key,
    alignment: Alignment.centerLeft,
    heightFactor: heightFactor,
    widthFactor: widthFactor,
    child: this,
  );

  Align alignAtCenter({Key? key, double? heightFactor, double? widthFactor}) => Align(
    key: key,
    heightFactor: heightFactor,
    widthFactor: widthFactor,
    child: this,
  );

  Align alignAtCenterRight({Key? key, double? heightFactor, double? widthFactor}) => Align(
    key: key,
    alignment: Alignment.centerRight,
    heightFactor: heightFactor,
    widthFactor: widthFactor,
    child: this,
  );

  Align alignAtLERP(Alignment a, Alignment b, double t, {Key? key, double? heightFactor, double? widthFactor}) => Align(
    key: key,
    alignment: Alignment.lerp(a, b, t)!,
    heightFactor: heightFactor,
    widthFactor: widthFactor,
    child: this,
  );

  Align alignXY(double x, double y, {Key? key, double? heightFactor, double? widthFactor}) => Align(
    key: key,
    alignment: Alignment(x, y),
    heightFactor: heightFactor,
    widthFactor: widthFactor,
    child: this,
  );

  Align alignAtTopCenter({Key? key, double? heightFactor, double? widthFactor}) => Align(
    key: key,
    alignment: Alignment.topCenter,
    heightFactor: heightFactor,
    widthFactor: widthFactor,
    child: this,
  );

  Align alignAtTopRight({Key? key, double? heightFactor, double? widthFactor}) => Align(
    key: key,
    alignment: Alignment.topRight,
    heightFactor: heightFactor,
    widthFactor: widthFactor,
    child: this,
  );
}
