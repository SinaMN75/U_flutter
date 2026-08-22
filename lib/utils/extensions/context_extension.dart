import "package:flutter/material.dart";

extension UContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Size get size => MediaQuery.sizeOf(this);

  double get width => MediaQuery.sizeOf(this).width;

  double get height => MediaQuery.sizeOf(this).height;

  EdgeInsets get padding => MediaQuery.paddingOf(this);

  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  double get keyboardHeight => MediaQuery.viewInsetsOf(this).bottom;

  Orientation get orientation => MediaQuery.orientationOf(this);

  bool get isLandscape => MediaQuery.orientationOf(this) == Orientation.landscape;

  bool get isPortrait => MediaQuery.orientationOf(this) == Orientation.portrait;

  double get devicePixelRatio => MediaQuery.devicePixelRatioOf(this);

  double get textScale => MediaQuery.textScalerOf(this).scale(1);

  bool get isMobileSize => MediaQuery.sizeOf(this).width < 850;

  bool get isTabletSize => MediaQuery.sizeOf(this).width >= 850 && MediaQuery.sizeOf(this).width < 1100;

  bool get isDesktopSize => MediaQuery.sizeOf(this).width >= 1100;
}
