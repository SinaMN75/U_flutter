import "package:u/utilities.dart";

/// The app's navigator key; UMaterialApp uses it so UNavigator/UToast/ULoading work without a context.
GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// App-wide settings and data: base URL, localized strings (U.s), user, app settings, dynamic tabs. `U.s.save`, `U.baseUrl`
abstract class U {
  /// Vazir Persian font bundled with u. `Text("سلام", style: U.vazir)`
  static const TextStyle vazir = TextStyle(fontFamily: "Vazir", package: "u");

  /// API base URL set by initU(baseUrl:).
  static late String baseUrl;

  /// API key set by initU(apiKey:).
  static late String apiKey;

  /// Default snackbar duration in seconds.
  static int snackBarDuration = 6;

  /// ISO code of the default country for phone fields, e.g. "IR".
  static String defaultPhoneCountryCode = "IR";

  /// UCountry of [defaultPhoneCountryCode].
  static UCountry get defaultPhoneCountry => UCountries.byIsoCode(defaultPhoneCountryCode) ?? UCountries.byDialCode(defaultPhoneCountryCode) ?? UCountries.iran();

  /// Localized strings (fa/en) from u's l10n. `Text(U.s.save)`
  static AppLocalizations get s => AppLocalizations.of(navigatorKey.currentContext!)!;

  /// Logged-in user; set it after login.
  static late UUserResponse user;

  /// App settings loaded from the server; set it after loading.
  static late UAppSettingsResponse appSettings;

  /// Content items (about us, banners…) loaded from the server.
  static List<UContentResponse> contents = <UContentResponse>[];

  /// Categories loaded from the server.
  static List<UCategoryResponse> categories = <UCategoryResponse>[];

  /// Open tabs of a desktop/admin tab layout (UDefaultTabBar).
  static final URxList<UTabData> tabs = <UTabData>[].obs;

  /// Controller of [tabs].
  static TabController? tabController;

  /// Opens a new tab with [page].
  static void addTab(String title, Widget page) {
    tabs.value = <UTabData>[...tabs, UTabData(title: title, page: page)];
    updateTabController();
  }

  /// Closes the tab at [index].
  static void removeTab(int index) {
    if (index >= 0 && index < tabs.length) {
      tabs(<UTabData>[...tabs]..removeAt(index));
      if (tabController != null && tabController!.index >= tabs.length) {
        tabController!.animateTo(tabs.length - 1);
      }
      updateTabController();
    }
  }

  /// Rebuilds the tab controller after tabs change.
  static void updateTabController() {
    if (tabController != null) {
      tabController!.dispose();
      tabController = null;
    }
    if (tabs.isNotEmpty && navigatorKey.currentState != null) {
      tabController = TabController(length: tabs.length, vsync: navigatorKey.currentState!.overlay!);
    }
  }

  /// Switches to the tab named [title], or opens it. `U.addOrSwitchTab("Users", const UsersPage())`
  static void addOrSwitchTab(String title, Widget page) {
    final int existingIndex = tabs.indexWhere((UTabData tab) => tab.title == title);
    if (existingIndex != -1) {
      tabController?.animateTo(existingIndex);
    } else {
      addTab(title, page);
      tabController?.animateTo(tabs.length - 1);
    }
  }

  /// Replaces the tab named [title] with [page], or opens it.
  static void replaceTab(String title, Widget page) {
    final int existingIndex = tabs.indexWhere((UTabData tab) => tab.title == title);

    if (existingIndex != -1) {
      tabs.value = <UTabData>[...tabs]..removeAt(existingIndex);

      tabs.value = <UTabData>[
        ...tabs.sublist(0, existingIndex),
        UTabData(title: title, page: page),
        ...tabs.sublist(existingIndex),
      ];

      if (tabController != null) {
        delay(100, () => tabController!.animateTo(existingIndex));
      }
    } else {
      addTab(title, page);
      if (tabController != null) {
        delay(100, () => tabController!.animateTo(tabs.length - 1));
      }
    }
  }
}

/// Starts u (storage, device/app/network info, notifications, loading overlay, web updates); locks portrait unless you pass [deviceOrientations]. Call once before runApp. `await initU(baseUrl: "https://api.x.com");`
Future<void> initU({
  String? baseUrl,
  String? apiKey,
  String defaultPhoneCountryCode = "IR",
  int snackBarDuration = 4,
  ULoadingSettings loadingSettings = const ULoadingSettings(blurAmount: 1, overlayColor: Colors.black12),
  List<DeviceOrientation> deviceOrientations = const <DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ],
}) async {
  U.baseUrl = baseUrl ?? "";
  U.apiKey = apiKey ?? "";
  U.defaultPhoneCountryCode = defaultPhoneCountryCode;
  U.snackBarDuration = snackBarDuration;
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait(<Future<void>>[
    if (!kIsWeb) SystemChrome.setPreferredOrientations(deviceOrientations),
    UStorage.init(),
    UFileStorage.init(),
    // One native round trip fills all three.
    UDevice.init(),
    UPackage.init(),
    UConnectivity.init(),
  ]);
  // Needs the package name (Windows app id), so after UPackage.
  await UNotification.init();
  ULoading.initialize(key: navigatorKey, settings: loadingSettings);
  UWebUpdate.startWatching(silent: true);
}

/// MaterialApp wired for u: navigatorKey, fa/en localizations, saved theme and language that switch live. `UMaterialApp(locale: const Locale("fa"), home: const HomePage(), lightThemeData: light, darkThemeData: dark)`
class UMaterialApp extends StatefulWidget {
  /// [locale] is used on first launch; later the saved language wins.
  const UMaterialApp({
    required this.locale,
    required this.home,
    required this.lightThemeData,
    required this.darkThemeData,
    super.key,
    this.title = "",
    this.builder,
    this.navigatorObservers = const <NavigatorObserver>[],
    this.routes = const <String, WidgetBuilder>{},
    this.onGenerateRoute,
    this.localizationsDelegates = const <LocalizationsDelegate<dynamic>>[],
  });

  /// Language for the first launch.
  final Locale locale;

  /// First page.
  final Widget home;

  /// Light theme.
  final ThemeData lightThemeData;

  /// Dark theme.
  final ThemeData darkThemeData;

  /// App title (task switcher, browser tab).
  final String title;

  /// Wraps every page, e.g. for a global banner or text scaling.
  final TransitionBuilder? builder;

  /// Route observers (analytics, logging).
  final List<NavigatorObserver> navigatorObservers;

  /// Named routes.
  final Map<String, WidgetBuilder> routes;

  /// Builds routes by name (deep links).
  final RouteFactory? onGenerateRoute;

  /// Your own localization delegates, added before u's.
  final List<LocalizationsDelegate<dynamic>> localizationsDelegates;

  @override
  State<UMaterialApp> createState() => _UMaterialAppState();
}

class _UMaterialAppState extends State<UMaterialApp> {
  @override
  void initState() {
    super.initState();
    UAppState.themeMode.value = (ULocalStorage.getBool(UConstants.isDarkMode) ?? false) ? ThemeMode.dark : ThemeMode.light;
    UAppState.locale.value = Locale(ULocalStorage.getString(UConstants.locale) ?? widget.locale.languageCode);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge(<Listenable>[UAppState.themeMode, UAppState.locale]),
    builder: (BuildContext context, Widget? child) => MaterialApp(
      navigatorKey: navigatorKey,
      title: widget.title,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        ...widget.localizationsDelegates,
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: widget.home,
      routes: widget.routes,
      onGenerateRoute: widget.onGenerateRoute,
      navigatorObservers: widget.navigatorObservers,
      builder: widget.builder,
      locale: UAppState.locale.value,
      themeMode: UAppState.themeMode.value,
      theme: widget.lightThemeData,
      darkTheme: widget.darkThemeData,
    ),
  );
}

/// One tab of U.tabs: a title and its page.
class UTabData {
  /// Tab title (also its id).
  final String title;

  /// Tab content.
  final Widget page;

  /// A tab.
  UTabData({required this.title, required this.page});
}
