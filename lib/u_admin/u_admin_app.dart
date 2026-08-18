part of "u_admin.dart";

Future<void> runUAdminApp(UAdminConfig config) async {
  UAdmin.config = config;
  await initU(baseUrl: config.baseUrl, apiKey: config.apiKey);
  UHttpClient.onAuthFailed = () async {
    await ULocalStorage.clear();
    UToast.error(message: U.s.yourSessionHasExpiredPleaseSignInAgain);
    await UNavigator.offAll(const UAdminLoginPage());
  };
  runApp(
    UMaterialApp(
      locale: Locale(ULocalStorage.getString(UConstants.locale) ?? config.defaultLocale.languageCode),
      home: UAdminSplashPage(
        logo: config.logo,
        onError: () => UNavigator.offAll(const UAdminLoginPage()),
        onFinish: () => UNavigator.offAll(const UAdminShell()),
      ),
      lightThemeData: UAdminTheme.light(primary: config.primaryColor, font: config.font),
      darkThemeData: UAdminTheme.dark(primary: config.primaryColor, font: config.font),
    ),
  );
}

abstract class UAdminTheme {
  static const Color primary = Colors.blue;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;
  static const Color white24 = Colors.white24;
  static const MaterialColor pink = Colors.pink;
  static const MaterialColor blue = Colors.blue;
  static const MaterialColor green = Colors.green;
  static const MaterialColor red = Colors.red;
  static const MaterialColor orange = Colors.orange;
  static const MaterialColor grey = Colors.grey;
  static const MaterialColor indigo = Colors.indigo;
  static const MaterialColor yellow = Colors.yellow;
  static const MaterialColor blueGrey = Colors.blueGrey;
  static const List<MaterialColor> primaries = Colors.primaries;

  static ThemeData light({required Color primary, String? font}) => _build(primary: primary, font: font, brightness: Brightness.light, surface: white);

  static ThemeData dark({required Color primary, String? font}) => _build(primary: primary, font: font, brightness: Brightness.dark, surface: black);

  static ThemeData _build({required Color primary, required Brightness brightness, required Color surface, String? font, double baseRadius = 8}) {
    final String family = font ?? UFonts.vazir.fontFamily!;
    final Color disabled = grey.shade400;
    return ThemeData(
      dividerTheme: DividerThemeData(color: disabled, space: 0),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 4,
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      colorScheme: ColorScheme.fromSeed(seedColor: primary, shadow: primary, brightness: brightness),
      fontFamily: family,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(baseRadius),
          borderSide: const BorderSide(color: grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(baseRadius),
          borderSide: const BorderSide(color: grey),
        ),
        outlineBorder: const BorderSide(color: transparent),
        labelStyle: TextStyle(fontFamily: family, color: grey, fontSize: 12),
        filled: true,
        fillColor: surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: surface,
          textStyle: TextStyle(fontFamily: family, color: primary, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(baseRadius)),
          backgroundColor: primary,
        ),
      ),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 8)),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actionsPadding: EdgeInsets.zero,
      ),
    );
  }
}
