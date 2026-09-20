import "package:u/utilities.dart";
import "package:u/utils/web/u_web_native.dart" if (dart.library.js_interop) "package:u/utils/web/u_web_browser.dart";

// =============================================================================
// u_web — everything web-specific you are meant to call, read and change.
//
// The raw browser calls live behind [UWebBridge], which resolves to real
// bindings (`u_web_browser.dart`) on the web and to no-ops (`u_web_native.dart`)
// everywhere else. That is why nothing here needs a `kIsWeb` guard to be safe —
// the guards that are here exist to skip work, not to avoid crashes.
// =============================================================================

typedef UWebMessageHandler = void Function(String origin, Map<String, dynamic> data);

/// `window.postMessage` traffic, used by flows that hand control to a page we do not own
/// (an IPG checkout, an OAuth popup) and wait for it to report back.
abstract class UWebMessage {
  /// Starts listening and returns a disposer. Call the disposer from `dispose()`;
  /// off the web it is a no-op, so callers need no platform check.
  static void Function() listen(UWebMessageHandler onMessage) => UWebBridge.listenMessage(onMessage);
}

// -----------------------------------------------------------------------------
// PWA
// -----------------------------------------------------------------------------

/// Browser and install-state questions, plus the iOS "Add to Home Screen" walkthrough.
///
/// iOS has no `beforeinstallprompt`, so the only way to get a PWA onto an iPhone home
/// screen is to tell the user which buttons to press — that is what [promptIosInstall] does.
/// Every getter is false off the web.
///
/// ```dart
/// // Show the install hint once when an iPhone user opens the web app in a browser.
/// if (UPwa.canPromptIosInstall) UPwa.promptIosInstall();
///
/// // Only iPhone Safari (the one that can actually install):
/// if (UPwa.isIphoneBrowser && UPwa.isIosSafari) UPwa.promptIosInstall();
///
/// // Force-show the instructions, e.g. behind a "How to install" button:
/// UPwa.promptIosInstall(force: true);
///
/// // Skip in-app install UI when it is already installed:
/// if (!UPwa.isStandalone) showInstallBanner();
/// ```
abstract class UPwa {
  static String get _ua => UWebBridge.userAgent().toLowerCase();

  /// True when the app was launched from the home screen rather than a browser tab.
  static bool get isStandalone => UApp.isWeb && UWebBridge.isStandalone();

  static bool get isIphoneBrowser => UApp.isWeb && _ua.contains("iphone");

  static bool get isIosBrowser => UApp.isWeb && (_ua.contains("iphone") || _ua.contains("ipad") || _ua.contains("ipod"));

  static bool get isAndroidBrowser => UApp.isWeb && _ua.contains("android");

  /// True only for real Safari. Chrome, Firefox, Edge and Opera on iOS are WebKit too but
  /// cannot install to the home screen, so they get the "open this in Safari" hint instead.
  static bool get isIosSafari {
    if (!isIosBrowser) return false;
    const List<String> nonSafari = <String>["crios", "fxios", "edgios", "opios", "mercury", "gsa"];
    if (nonSafari.any(_ua.contains)) return false;
    return _ua.contains("safari");
  }

  /// True when showing the install walkthrough would make sense: an iOS browser, not yet installed.
  static bool get canPromptIosInstall => isIosBrowser && !isStandalone;

  /// Opens a bottom sheet walking the user through "Share → Add to Home Screen".
  ///
  /// Does nothing unless [canPromptIosInstall], which [force] overrides so the sheet can also
  /// sit behind a help button. Every string falls back to the localized default.
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

/// Fingerprint of a Flutter web build — either the one a browser holds or the one the server serves.
class UWebBuild {
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

  /// pubspec-style id of this build, e.g. `0.2.0+20`. Empty when `version.json` was unreadable.
  String get id => version == null ? "" : "$version+${buildNumber ?? ""}";

  @override
  String toString() => "UWebBuild(signature: $signature, id: $id, serviceWorkerVersion: $serviceWorkerVersion)";
}

/// Keeps a Flutter web app on the build that is actually deployed.
///
/// A browser can keep serving a superseded app from three independent places: the HTTP disk cache
/// (a `Cache-Control: immutable` asset is not even revalidated on a normal reload), the CacheStorage
/// buckets that older Flutter service workers filled, and a service worker that stays `waiting`
/// until every tab of the site is closed. [refresh] clears all three and reloads into the deployed
/// build; [hasUpdate] says whether that is worth doing. Every member is a no-op off the web.
///
/// Detection is only as good as the signal the build carries. Build with
/// `--dart-define=U_BUILD_ID=<pubspec version>` to get an exact answer:
///
/// ```bash
/// flutter build web --dart-define=U_BUILD_ID=$(grep "^version:" pubspec.yaml | cut -d " " -f2)
/// ```
///
/// Without it, [hasUpdate] falls back to comparing the browser's cached `flutter_bootstrap.js`
/// against the server's, which misses the case where only `main.dart.js` is stale. [refresh]
/// itself never depends on any of this and always works.
///
/// ```dart
/// // The blunt one: a button that always lands on whatever is deployed.
/// UButton(title: U.s.refresh, onTap: UWebUpdate.refresh);
///
/// // Ask the user once, right after the app starts.
/// unawaited(UWebUpdate.checkAndRefresh());
///
/// // The solid default, already wired into initU: silent at startup, ask for anything found later.
/// UWebUpdate.startWatching();
///
/// // Keep every open tab current without ever asking.
/// UWebUpdate.startWatching(silent: true);
///
/// // Read what is deployed, e.g. to show it next to the running version.
/// final UWebBuild? deployed = await UWebUpdate.serverBuild();
/// ```
abstract class UWebUpdate {
  /// Build id compiled into this bundle by `--dart-define=U_BUILD_ID=...`, empty when not passed.
  static const String buildId = String.fromEnvironment("U_BUILD_ID");

  // A build we already reloaded for. Persisted so a host that keeps serving the old files cannot
  // put the app in a reload loop.
  static const String _refreshedBuildKey = "u_web_refreshed_build";

  // A build the user answered "later" to. Only silences the prompt, never a silent refresh, so
  // declining once does not pin the browser to an old build forever.
  static const String _declinedBuildKey = "u_web_declined_build";

  /// Files re-downloaded before reloading, relative to the deployment base. Missing ones are ignored.
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

  /// How long a probe of the server may take before it is treated as "nothing new".
  static Duration timeout = const Duration(seconds: 10);

  static final RegExp _serviceWorkerVersionPattern = RegExp("serviceWorkerVersion[\"']?\\s*:\\s*[\"']([0-9]+)");

  static Timer? _timer;
  static void Function()? _visibilityDisposer;
  static bool _checking = false;

  /// Throws away every browser-side copy of the app and reloads into the deployed build.
  ///
  /// Unregisters the service workers, empties CacheStorage, re-downloads [assets] with a
  /// cache-bypassing fetch so the HTTP cache ends up holding the server copy, then reloads.
  /// Pass [bustUrl] when the host serves `index.html` itself under an `immutable` policy — it
  /// appends a `_u` query parameter, which changes the URL the user sees.
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

  /// The build the server is serving right now, read past every cache. Null off the web or when offline.
  static Future<UWebBuild?> serverBuild() => _build("no-store");

  /// The build the browser would serve from its own HTTP cache, which is what this tab is running.
  static Future<UWebBuild?> cachedBuild() => _build("force-cache");

  /// Service worker version serving this page, or null when no service worker controls it.
  static String? runningServiceWorkerVersion() {
    final String? url = UWebBridge.activeServiceWorkerUrl();
    if (url == null) return null;
    return Uri.tryParse(url)?.queryParameters["v"];
  }

  /// Whether the server holds a build other than the one this tab is running.
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

  /// Checks the server and, when a newer build is deployed, reloads into it. Returns whether a refresh started.
  ///
  /// [silent] refreshes without asking, otherwise the user confirms first. [once] keeps a build
  /// the user declined from being offered again, and keeps a build that was already reloaded for
  /// from being reloaded for a second time, which is what stops an endless auto-refresh when a
  /// misconfigured host keeps handing out the old files.
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

  /// Watches for new builds: once at startup, every [interval], and whenever the tab is brought
  /// back to the foreground. Safe to call before `runApp`. End it with [stopWatching].
  ///
  /// The startup check is [silentOnStart] because nothing is in flight yet, so reloading costs the
  /// user nothing and needs no navigator. Later checks use [silent], which defaults to asking
  /// first — a reload in the middle of a half-filled form would throw that input away.
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
