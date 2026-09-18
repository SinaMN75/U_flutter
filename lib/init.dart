import "package:u/utilities.dart";

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

abstract class U {
  static const TextStyle vazir = TextStyle(fontFamily: "Vazir", package: "u");

  static late String baseUrl;
  static late String apiKey;

  static AppLocalizations get s => AppLocalizations.of(navigatorKey.currentContext!)!;
  static late UUserResponse user;
  static late UAppSettingsResponse appSettings;
  static List<UContentResponse> contents = <UContentResponse>[];
  static List<UCategoryResponse> categories = <UCategoryResponse>[];
  static final RxList<TabData> tabs = <TabData>[].obs;
  static TabController? tabController;

  static void addTab(String title, Widget page) {
    tabs.value = <TabData>[...tabs, TabData(title: title, page: page)];
    updateTabController();
  }

  static void removeTab(int index) {
    if (index >= 0 && index < tabs.length) {
      tabs(<TabData>[...tabs]..removeAt(index));
      if (tabController != null && tabController!.index >= tabs.length) {
        tabController!.animateTo(tabs.length - 1);
      }
      updateTabController();
    }
  }

  static void updateTabController() {
    if (tabController != null) {
      tabController!.dispose();
      tabController = null;
    }
    if (tabs.isNotEmpty && navigatorKey.currentState != null) {
      tabController = TabController(length: tabs.length, vsync: navigatorKey.currentState!.overlay!);
    }
  }

  static void addOrSwitchTab(String title, Widget page) {
    final int existingIndex = tabs.indexWhere((TabData tab) => tab.title == title);
    if (existingIndex != -1) {
      tabController?.animateTo(existingIndex);
    } else {
      addTab(title, page);
      tabController?.animateTo(tabs.length - 1);
    }
  }

  static void replaceTab(String title, Widget page) {
    final int existingIndex = tabs.indexWhere((TabData tab) => tab.title == title);

    if (existingIndex != -1) {
      tabs.value = <TabData>[...tabs]..removeAt(existingIndex);

      tabs.value = <TabData>[
        ...tabs.sublist(0, existingIndex),
        TabData(title: title, page: page),
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

Future<void> initU({
  String? baseUrl,
  String? apiKey,
  ULoadingSettings loadingSettings = const ULoadingSettings(blurAmount: 1, overlayColor: Colors.black12),
  List<DeviceOrientation> deviceOrientations = const <DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ],
}) async {
  U.baseUrl = baseUrl ?? "";
  U.apiKey = apiKey ?? "";
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait(<Future<void>>[
    if (!kIsWeb) SystemChrome.setPreferredOrientations(deviceOrientations),
    ULocalStorage.init(),
    UFileStorage.init(),
    PackageInfo.fromPlatform().then((PackageInfo info) => UApp.packageInfo = info),
    UApp.initDeviceInfo(),
  ]);
  ULoading.initialize(key: navigatorKey, settings: loadingSettings);
}

class UMaterialApp extends StatefulWidget {
  const UMaterialApp({
    required this.locale,
    required this.home,
    required this.lightThemeData,
    required this.darkThemeData,
    super.key,
  });

  final Locale locale;
  final Widget home;
  final ThemeData lightThemeData;
  final ThemeData darkThemeData;

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
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: widget.home,
      locale: UAppState.locale.value,
      themeMode: UAppState.themeMode.value,
      theme: widget.lightThemeData,
      darkTheme: widget.darkThemeData,
    ),
  );
}

class TabData {
  final String title;
  final Widget page;

  TabData({required this.title, required this.page});
}
