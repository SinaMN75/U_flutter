import "package:flutter/material.dart";

/// App-wide theme and language notifiers that UMaterialApp listens to; use UApp.toDarkMode()/updateLocale() to change and save them.
abstract class UAppState {
  /// Current ThemeMode; listen to rebuild on theme changes.
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

  /// Current app Locale; listen to rebuild on language changes.
  static final ValueNotifier<Locale> locale = ValueNotifier<Locale>(const Locale("en"));

  /// True when the dark theme is active.
  static bool get isDarkMode {
    if (themeMode.value == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return themeMode.value == ThemeMode.dark;
  }

  /// Switches the theme without saving it. `UAppState.changeThemeMode(ThemeMode.system)`
  static void changeThemeMode(ThemeMode mode) => themeMode.value = mode;

  /// Switches the language without saving it.
  static void updateLocale(Locale value) => locale.value = value;
}
