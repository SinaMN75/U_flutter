import "package:flutter/material.dart";

abstract class UAppState {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
  static final ValueNotifier<Locale> locale = ValueNotifier<Locale>(const Locale("en"));

  static bool get isDarkMode {
    if (themeMode.value == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return themeMode.value == ThemeMode.dark;
  }

  static void changeThemeMode(ThemeMode mode) => themeMode.value = mode;

  static void updateLocale(Locale value) => locale.value = value;
}
