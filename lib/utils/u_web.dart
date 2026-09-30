import "package:u/utilities.dart";
import "package:u/src/web/u_web_native.dart" if (dart.library.js_interop) "package:u/src/web/u_web_browser.dart";

// =============================================================================
// u_web — everything web-specific you are meant to call, read and change.
//
// The raw browser calls live behind [UWebBridge], which resolves to real
// bindings (`u_web_browser.dart`) on the web and to no-ops (`u_web_native.dart`)
// everywhere else. That is why nothing here needs a `kIsWeb` guard to be safe —
// the guards that are here exist to skip work, not to avoid crashes.
// =============================================================================

/// Callback for window.postMessage: the sender's origin and its JSON data.
typedef UWebMessageHandler = void Function(String origin, Map<String, dynamic> data);

/// Web only: listens to window.postMessage (IPG checkout pages, OAuth popups, parent iframes). Does nothing elsewhere.
abstract class UWebMessage {
  /// Calls [onMessage] for every postMessage; call the returned function to stop. `final stop = UWebMessage.listen((origin, data) => print(data));`
  static void Function() listen(UWebMessageHandler onMessage) => UWebBridge.listenMessage(onMessage);
}

// -----------------------------------------------------------------------------
// PWA
// -----------------------------------------------------------------------------

/// Web only: install state and the iOS "Add to Home Screen" guide; every getter is false off the web. `if (UPwa.canPromptIosInstall) UPwa.promptIosInstall()`
abstract class UPwa {
  static String get _ua => UWebBridge.userAgent().toLowerCase();

  /// True when opened from the home screen as an installed PWA.
  static bool get isStandalone => UApp.isWeb && UWebBridge.isStandalone();

  /// True in a browser on an iPhone.
  static bool get isIphoneBrowser => UApp.isWeb && _ua.contains("iphone");

  /// True in a browser on iPhone/iPad/iPod.
  static bool get isIosBrowser => UApp.isWeb && (_ua.contains("iphone") || _ua.contains("ipad") || _ua.contains("ipod"));

  /// True in a browser on Android.
  static bool get isAndroidBrowser => UApp.isWeb && _ua.contains("android");

  /// True only in real Safari on iOS (the only iOS browser that installs PWAs).
  static bool get isIosSafari {
    if (!isIosBrowser) return false;
    const List<String> nonSafari = <String>["crios", "fxios", "edgios", "opios", "mercury", "gsa"];
    if (nonSafari.any(_ua.contains)) return false;
    return _ua.contains("safari");
  }

  /// True when showing the "Add to Home Screen" guide makes sense (iOS browser, not installed yet).
  static bool get canPromptIosInstall => isIosBrowser && !isStandalone;

  /// Shows a sheet explaining Share → Add to Home Screen; [force] shows it even when it would not. `UPwa.promptIosInstall()`
  static Future<void> promptIosInstall({
    bool force = false,
    String? title,
    String? step1,
    String? step2,
    String? step3,
    String? safariHint,
    String? doneLabel,
  }) async {
    if (!force && !canPromptIosInstall) return;

    await UNavigator.bottomSheet<void>(
      _IosInstallSheet(
        title: title ?? U.s.openThisPageInSafariThenAddItToYourHomeScreen,
        safari: force || isIosSafari,
        step1: step1 ?? U.s.tapTheShareButtonInSafarisToolbar,
        step2: step2 ?? U.s.scrollDownAndTapAddToHomeScreen,
        step3: step3 ?? U.s.tapAddInTheTopRightCorner,
        safariHint: safariHint ?? U.s.openThisPageInSafariThenAddItToYourHomeScreen,
        doneLabel: doneLabel ?? U.s.gotIt,
      ),
      showDragHandle: true,
    );
  }
}

class _IosInstallSheet extends StatelessWidget {
  const _IosInstallSheet({
    required this.title,
    required this.safari,
    required this.step1,
    required this.step2,
    required this.step3,
    required this.safariHint,
    required this.doneLabel,
  });

  final String title;
  final bool safari;
  final String step1;
  final String step2;
  final String step3;
  final String safariHint;
  final String doneLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: UColumn(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: <Widget>[
          Icon(Icons.add_to_home_screen_rounded, size: 40, color: scheme.primary),
          UTextTitleMedium(title, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          if (safari) ...<Widget>[
            _step(context, 1, Icons.ios_share_rounded, step1),
            _step(context, 2, Icons.add_box_outlined, step2),
            _step(context, 3, Icons.check_circle_outline_rounded, step3),
          ] else
            URow(
              spacing: 8,
              children: <Widget>[
                Icon(Icons.info_outline_rounded, color: scheme.primary),
                UTextBodyMedium(safariHint, expanded: 1),
              ],
            ),
          const SizedBox(height: 12),
          UButton(title: doneLabel, onTap: UNavigator.back),
        ],
      ),
    );
  }

  Widget _step(BuildContext context, int number, IconData icon, String text) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return URow(
      spacing: 8,
      children: <Widget>[
        UContainer(
          width: 28,
          height: 28,
          radius: 100,
          color: scheme.primaryContainer,
          alignment: Alignment.center,
          child: UTextLabelLarge("$number", color: scheme.onPrimaryContainer),
        ),
        Icon(icon, color: scheme.primary),
        UTextBodyMedium(text, expanded: 1),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Build freshness
// -----------------------------------------------------------------------------

/// Fingerprint of a Flutter web build (the one a tab runs or the one the server has).
class UWebBuild {
  /// Makes a build fingerprint.
  const UWebBuild({
    required this.signature,
    this.serviceWorkerVersion,
    this.version,
    this.buildNumber,
  });

  /// Value that changes on every `flutter build web`; used to tell two builds apart.
  final String signature;

  /// `serviceWorkerVersion` that `flutter build web` bakes into `flutter_bootstrap.js`.
  final String? serviceWorkerVersion;

  /// `version` field of `version.json`, i.e. the `version:` line of pubspec.yaml without the build number.
  final String? version;

  /// `build_number` field of `version.json`, i.e. the `+n` suffix in pubspec.yaml.
  final String? buildNumber;

  /// pubspec-style id, e.g. "0.2.0+20"; empty when version.json could not be read.
  String get id => version == null ? "" : "$version+${buildNumber ?? ""}";

  @override
  String toString() => "UWebBuild(signature: $signature, id: $id, serviceWorkerVersion: $serviceWorkerVersion)";
}

/// Web only: keeps every open tab on the latest deployed build (clears stale caches/service workers); initU() already starts it. Build with `--dart-define=U_BUILD_ID=<version>` for exact checks. `UWebUpdate.checkAndRefresh()`
abstract class UWebUpdate {
  /// Build id from --dart-define=U_BUILD_ID (empty when not given).
  static const String buildId = String.fromEnvironment("U_BUILD_ID");

  // A build we already reloaded for. Persisted so a host that keeps serving the old files cannot
  // put the app in a reload loop.
  static const String _refreshedBuildKey = "u_web_refreshed_build";

  // A build the user answered "later" to. Only silences the prompt, never a silent refresh, so
  // declining once does not pin the browser to an old build forever.
  static const String _declinedBuildKey = "u_web_declined_build";

  /// Files re-downloaded by refresh().
  static const List<String> defaultAssets = <String>[
    "index.html",
    "flutter_bootstrap.js",
    "flutter.js",
    "flutter_service_worker.js",
    "main.dart.js",
    "version.json",
    "manifest.json",
    "assets/AssetManifest.bin.json",
    "assets/FontManifest.json",
    "assets/NOTICES",
  ];

  /// How long a build check may take.
  static Duration timeout = const Duration(seconds: 10);

  static final RegExp _serviceWorkerVersionPattern = RegExp("serviceWorkerVersion[\"']?\\s*:\\s*[\"']([0-9]+)");

  static Timer? _timer;
  static void Function()? _visibilityDisposer;
  static bool _checking = false;

  /// Clears service workers and caches and reloads into the newest build; always works. `UButton(title: "Update", onTap: UWebUpdate.refresh)`
  static Future<void> refresh({
    List<String> assets = defaultAssets,
    bool bustUrl = false,
  }) async {
    if (!UApp.isWeb) return;
    final String base = UWebBridge.baseUrl();
    await UWebBridge.unregisterServiceWorkers();
    await UWebBridge.clearCaches();
    await UWebBridge.revalidate(<String>[UWebBridge.documentUrl(), for (final String asset in assets) "$base$asset"]);
    UWebBridge.reload(bustUrl ? _bustedUrl() : null);
  }

  /// The build the server serves now; null off the web or offline.
  static Future<UWebBuild?> serverBuild() => _build("no-store");

  /// The build this tab is running.
  static Future<UWebBuild?> cachedBuild() => _build("force-cache");

  /// Version of the service worker serving this page.
  static String? runningServiceWorkerVersion() {
    final String? url = UWebBridge.activeServiceWorkerUrl();
    if (url == null) return null;
    return Uri.tryParse(url)?.queryParameters["v"];
  }

  /// True when a newer build is deployed. `if (await UWebUpdate.hasUpdate()) …`
  static Future<bool> hasUpdate() async {
    if (!UApp.isWeb) return false;
    if (await UWebBridge.serviceWorkerHasPendingUpdate().timeout(timeout, onTimeout: () => false)) return true;

    final UWebBuild? server = await serverBuild();
    if (server == null) return false;

    // Compiled-in id versus the deployed one: exact, and blind to how anything is cached.
    if (buildId.isNotEmpty && server.id.isNotEmpty) return buildId != server.id;

    // A service worker still caching assets pins the tab to its own generation.
    final String? running = runningServiceWorkerVersion();
    if (running != null && server.serviceWorkerVersion != null) return running != server.serviceWorkerVersion;

    // Last resort: the entry point the browser has on disk versus the one on the server.
    final UWebBuild? cached = await cachedBuild();
    return cached != null && cached.signature != server.signature;
  }

  /// Reloads into a newer build when there is one; asks first unless [silent]. `await UWebUpdate.checkAndRefresh()`
  static Future<bool> checkAndRefresh({
    bool silent = false,
    bool once = true,
    bool bustUrl = false,
    String? title,
    String? message,
    String? confirmText,
    String? cancelText,
  }) async {
    if (!UApp.isWeb || _checking) return false;
    _checking = true;
    try {
      if (!await hasUpdate()) return false;
      final String signature = (await serverBuild())?.signature ?? "";
      final bool guarded = once && signature.isNotEmpty;
      if (guarded && ULocalStorage.getString(_refreshedBuildKey) == signature) return false;

      if (!silent) {
        if (guarded && ULocalStorage.getString(_declinedBuildKey) == signature) return false;
        // No navigator yet, so there is nobody to ask; leave the build untouched and retry later.
        if (navigatorKey.currentContext == null) return false;
        final bool accepted = await UNavigator.confirmAsync(
          title: title ?? U.s.updateAvailable,
          message: message ?? U.s.aNewVersionIsAvailableReloadToGetIt,
          confirmText: confirmText ?? U.s.refresh,
          cancelText: cancelText ?? U.s.later,
          icon: Icons.system_update_alt_rounded,
        );
        if (!accepted) {
          if (signature.isNotEmpty) ULocalStorage.set(_declinedBuildKey, signature);
          return false;
        }
      }

      if (signature.isNotEmpty) ULocalStorage.set(_refreshedBuildKey, signature);
      await refresh(bustUrl: bustUrl);
      return true;
    } finally {
      _checking = false;
    }
  }

  /// Checks at startup, every [interval] and when the tab comes back (initU() calls it silently).
  static void startWatching({
    Duration interval = const Duration(minutes: 15),
    bool silent = false,
    bool checkNow = true,
    bool silentOnStart = true,
    bool onVisible = true,
    bool bustUrl = false,
  }) {
    if (!UApp.isWeb) return;
    stopWatching();
    _timer = Timer.periodic(interval, (_) => unawaited(checkAndRefresh(silent: silent, bustUrl: bustUrl)));
    if (onVisible) _visibilityDisposer = UWebBridge.listenVisible(() => unawaited(checkAndRefresh(silent: silent, bustUrl: bustUrl)));
    if (checkNow) unawaited(checkAndRefresh(silent: silentOnStart, bustUrl: bustUrl));
  }

  /// Stops checking for new builds.
  static void stopWatching() {
    _timer?.cancel();
    _timer = null;
    _visibilityDisposer?.call();
    _visibilityDisposer = null;
  }

  static Future<UWebBuild?> _build(String cacheMode) async {
    if (!UApp.isWeb) return null;
    final String base = UWebBridge.baseUrl();
    // `_u` rather than `v`: service workers that Flutter generated before 3.47 strip a `?v=`
    // query before looking a request up in their resource manifest, so only some other
    // parameter is guaranteed to reach the network.
    final String suffix = cacheMode == "no-store" ? "?_u=${DateTime.now().millisecondsSinceEpoch}" : "";
    final List<String?> files = await Future.wait(<Future<String?>>[
      UWebBridge.fetch("${base}flutter_bootstrap.js$suffix", cacheMode).timeout(timeout, onTimeout: () => null),
      UWebBridge.fetch("${base}version.json$suffix", cacheMode).timeout(timeout, onTimeout: () => null),
    ]);
    final String? bootstrap = files[0];
    final String? versionJson = files[1];
    if (bootstrap == null && versionJson == null) return null;

    final String? serviceWorkerVersion = bootstrap == null ? null : _serviceWorkerVersionPattern.firstMatch(bootstrap)?.group(1);
    String? version;
    String? buildNumber;
    if (versionJson != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(versionJson);
        version = map["version"]?.toString();
        buildNumber = map["build_number"]?.toString();
      } catch (_) {}
    }

    return UWebBuild(
      signature: serviceWorkerVersion ?? (bootstrap != null ? UEncryption.md5Hash(bootstrap) : "$version+$buildNumber"),
      serviceWorkerVersion: serviceWorkerVersion,
      version: version,
      buildNumber: buildNumber,
    );
  }

  static String _bustedUrl() {
    final Uri uri = Uri.parse(UWebBridge.documentUrl());
    final Map<String, String> query = Map<String, String>.of(uri.queryParameters)..["_u"] = DateTime.now().millisecondsSinceEpoch.toString();
    return uri.replace(queryParameters: query).toString();
  }
}
