import "package:u/utilities.dart";

import "home_page.dart";

Future<void> main() async {
  await initU();
  String? locale = ULocalStorage.getString(UConstants.locale);
  if (locale == null) {
    ULocalStorage.setLocale("fa");
    locale = "fa";
  }
  runApp(
    UMaterialApp(
      locale: Locale(locale),
      lightThemeData: Core.lightThemeData,
      darkThemeData: Core.darkThemeData,
      home: const HomePage(),
    ),
  );
}

abstract class AppColors {
  static const Color brand = Color(0xFF3B39E5);
  static const Color info = Color(0xFF38EBFF);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color onGradient = Colors.white;
  static const List<Color> gradient = <Color>[Color(0xFF3B39E5), Color(0xFF38EBFF)];
}

abstract class Core {
  static final ThemeData lightThemeData = _buildTheme(
    background: Colors.grey.shade100,
    scheme: ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      primary: AppColors.brand,
      surface: Colors.white,
    ).copyWith(onSurface: Colors.grey.shade900, onSurfaceVariant: Colors.grey.shade600, outlineVariant: Colors.grey.shade300, onPrimary: Colors.white, error: AppColors.danger),
  );
  static final ThemeData darkThemeData = _buildTheme(
    background: Colors.black,
    scheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: AppColors.brand,
      primary: const Color(0xFFA5B4FC),
      surface: Colors.grey.shade900,
    ).copyWith(onSurface: Colors.grey.shade100, onSurfaceVariant: Colors.grey.shade400, outlineVariant: Colors.grey.shade700, onPrimary: Colors.grey.shade900, error: AppColors.danger),
  );

  static ThemeData _buildTheme({required ColorScheme scheme, required Color background}) => ThemeData(
    brightness: scheme.brightness,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: scheme.onSurface),
      titleTextStyle: TextStyle(fontFamily: UFonts.vazir.fontFamily, color: scheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 0, thickness: 1),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      surfaceTintColor: scheme.surface,
      clipBehavior: Clip.hardEdge,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    colorScheme: scheme,
    fontFamily: UFonts.vazir.fontFamily,
    // Compact, uniform-weight type scale so titles are smaller and consistent across every screen.
    textTheme: TextTheme(
      displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: scheme.onSurface),
      displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: scheme.onSurface),
      displaySmall: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: scheme.onSurface),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: scheme.onSurface),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: scheme.onSurface),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scheme.onSurface),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: scheme.onSurface),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: scheme.onSurface),
      titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onSurface),
      bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: scheme.onSurface),
      bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: scheme.onSurface),
      bodySmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
      labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: scheme.onSurface),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.grey, width: 0.3),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.grey, width: 0.3),
      ),
      // Thin (1px) selected/error strokes so focused fields don't show Material's default thick border.
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 0.7),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error, width: 0.7),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error, width: 0.7),
      ),
      outlineBorder: const BorderSide(color: Colors.transparent, width: 0.7),
      labelStyle: TextStyle(fontFamily: UFonts.vazir.fontFamily, color: scheme.onSurfaceVariant, fontSize: 12),
      filled: true,
      fillColor: scheme.surface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: scheme.onPrimary,
        textStyle: TextStyle(fontFamily: UFonts.vazir.fontFamily, color: scheme.primary, fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: scheme.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actionsPadding: EdgeInsets.zero,
    ),
  );
}