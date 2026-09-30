import "package:flutter/material.dart";

/// Theme, screen size, keyboard and locale shortcuts on BuildContext. `context.colorScheme.primary`, `context.width`
extension UContextExtension on BuildContext {
  /// Theme.of(context).
  ThemeData get theme => Theme.of(this);

  /// The theme's colors. `context.colorScheme.primary`
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// The theme's text styles. `context.textTheme.titleLarge`
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// True when the theme is dark.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Screen (window) size; `context.size` is the widget's own size, so this has another name.
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Screen width.
  double get width => MediaQuery.sizeOf(this).width;

  /// Screen height.
  double get height => MediaQuery.sizeOf(this).height;

  /// Space taken by the status bar / notch / home bar.
  EdgeInsets get padding => MediaQuery.paddingOf(this);

  /// Space taken by the keyboard and other system UI.
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  /// Safe-area padding, ignoring the keyboard.
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  /// Keyboard height (0 when hidden).
  double get keyboardHeight => MediaQuery.viewInsetsOf(this).bottom;

  /// True while the on-screen keyboard is up.
  bool get isKeyboardOpen => MediaQuery.viewInsetsOf(this).bottom > 0;

  /// Portrait or landscape.
  Orientation get orientation => MediaQuery.orientationOf(this);

  /// True when wider than tall.
  bool get isLandscape => MediaQuery.orientationOf(this) == Orientation.landscape;

  /// True when taller than wide.
  bool get isPortrait => MediaQuery.orientationOf(this) == Orientation.portrait;

  /// Physical pixels per logical pixel.
  double get devicePixelRatio => MediaQuery.devicePixelRatioOf(this);

  /// The user's text size setting (1 = default).
  double get textScale => MediaQuery.textScalerOf(this).scale(1);

  /// True under 850 wide (phone layout).
  bool get isMobileSize => MediaQuery.sizeOf(this).width < 850;

  /// True from 850 to 1100 wide (tablet layout).
  bool get isTabletSize => MediaQuery.sizeOf(this).width >= 850 && MediaQuery.sizeOf(this).width < 1100;

  /// True at 1100 wide or more (desktop layout).
  bool get isDesktopSize => MediaQuery.sizeOf(this).width >= 1100;

  /// The app's current locale. `context.locale.languageCode`
  Locale get locale => Localizations.localeOf(this);

  /// True when text runs right-to-left (Persian, Arabic).
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  /// Closes the keyboard by removing focus. `context.hideKeyboard()`
  void hideKeyboard() => FocusScope.of(this).unfocus();

  /// Picks a value by screen width: [mobile], [tablet] (falls back to mobile), [desktop] (falls back to tablet). `context.responsive(1, tablet: 2, desktop: 4)`
  T responsive<T>(T mobile, {T? tablet, T? desktop}) {
    if (isDesktopSize) return desktop ?? tablet ?? mobile;
    if (isTabletSize) return tablet ?? mobile;
    return mobile;
  }
}
