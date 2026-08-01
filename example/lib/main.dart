import "package:u/utilities.dart";

import "home_page.dart";

void main() => runApp(const UGalleryApp());

/// Showcase app for the `u` plugin. A single import — `package:u/utilities.dart`
/// — brings in Flutter's material library plus every `u` component, utility,
/// extension, service, and native feature demonstrated here.
class UGalleryApp extends StatelessWidget {
  const UGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color seed = Color(0xFF3D5AFE);
    return MaterialApp(
      title: "u plugin gallery",
      debugShowCheckedModeBanner: false,
      // UToast / UNavigator / ULoading operate without a BuildContext by
      // reading this key, so the gallery must hand it to MaterialApp.
      navigatorKey: navigatorKey,
      // Many u widgets read localized strings via U.s, so register S.delegate.
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      ),
      home: const HomePage(),
    );
  }
}
