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
