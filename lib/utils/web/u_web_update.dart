import "package:u/utilities.dart";
import "package:u/utils/web/u_web_stub.dart" if (dart.library.html) "package:u/utils/web/u_web_impl.dart";

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
abstract class UWebUpdate {
  /// Build id compiled into this bundle by `--dart-define=U_BUILD_ID=...`, empty when not passed.
  static const String buildId = String.fromEnvironment("U_BUILD_ID");

  static const String _handledBuildKey = "u_web_handled_build";

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

  static final RegExp _serviceWorkerVersionPattern = RegExp("serviceWorkerVersion[\"']?\\s*:\\s*[\"']([0-9]+)");

  static Timer? _timer;
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
    final String base = uWebBaseUrl();
    await uWebUnregisterServiceWorkers();
    await uWebClearCaches();
    await uWebRevalidate(<String>[uWebDocumentUrl(), for (final String asset in assets) "$base$asset"]);
    uWebReload(bustUrl ? _bustedUrl() : null);
  }

  /// The build the server is serving right now, read past every cache. Null off the web or when offline.
  static Future<UWebBuild?> serverBuild() => _build("no-store");

  /// The build the browser would serve from its own HTTP cache, which is what this tab is running.
  static Future<UWebBuild?> cachedBuild() => _build("force-cache");

  /// Service worker version serving this page, or null when no service worker controls it.
  static String? runningServiceWorkerVersion() {
    final String? url = uWebActiveServiceWorkerUrl();
    if (url == null) return null;
    return Uri.tryParse(url)?.queryParameters["v"];
  }

  /// Whether the server holds a build other than the one this tab is running.
  static Future<bool> hasUpdate() async {
    if (!UApp.isWeb) return false;
    if (await uWebServiceWorkerHasPendingUpdate()) return true;

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
  /// [silent] refreshes without asking, otherwise the user confirms first. [once] keeps the same
  /// build from being offered twice, which also stops an endless auto-refresh when a misconfigured
  /// host keeps handing out the old files.
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
      if (once && signature.isNotEmpty && ULocalStorage.getString(_handledBuildKey) == signature) return false;
      if (signature.isNotEmpty) ULocalStorage.set(_handledBuildKey, signature);

      if (!silent) {
        final bool accepted = await UNavigator.confirmAsync(
          title: title ?? U.s.updateAvailable,
          message: message ?? U.s.aNewVersionIsAvailableReloadToGetIt,
          confirmText: confirmText ?? U.s.refresh,
          cancelText: cancelText ?? U.s.later,
          icon: Icons.system_update_alt_rounded,
        );
        if (!accepted) return false;
      }

      await refresh(bustUrl: bustUrl);
      return true;
    } finally {
      _checking = false;
    }
  }

  /// Polls the server every [interval] and refreshes when a new build appears. End it with [stopWatching].
  static void startWatching({
    Duration interval = const Duration(minutes: 15),
    bool silent = false,
    bool checkNow = true,
    bool bustUrl = false,
  }) {
    if (!UApp.isWeb) return;
    stopWatching();
    _timer = Timer.periodic(interval, (_) => unawaited(checkAndRefresh(silent: silent, bustUrl: bustUrl)));
    if (checkNow) unawaited(checkAndRefresh(silent: silent, bustUrl: bustUrl));
  }

  static void stopWatching() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<UWebBuild?> _build(String cacheMode) async {
    if (!UApp.isWeb) return null;
    final String base = uWebBaseUrl();
    // `_u` rather than `v`: service workers that Flutter generated before 3.47 strip a `?v=`
    // query before looking a request up in their resource manifest, so only some other
    // parameter is guaranteed to reach the network.
    final String suffix = cacheMode == "no-store" ? "?_u=${DateTime.now().millisecondsSinceEpoch}" : "";
    final List<String?> files = await Future.wait(<Future<String?>>[
      uWebFetch("${base}flutter_bootstrap.js$suffix", cacheMode),
      uWebFetch("${base}version.json$suffix", cacheMode),
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
    final Uri uri = Uri.parse(uWebDocumentUrl());
    final Map<String, String> query = Map<String, String>.of(uri.queryParameters)..["_u"] = DateTime.now().millisecondsSinceEpoch.toString();
    return uri.replace(queryParameters: query).toString();
  }
}

// -----------------------------------------------------------------------------
// USAGE EXAMPLES
// -----------------------------------------------------------------------------
//
//   // The blunt one: a button that always lands on whatever is deployed.
//   UButton(title: U.s.refresh, onTap: UWebUpdate.refresh);
//
//   // Ask the user once, right after the app starts.
//   await initU(...);
//   unawaited(UWebUpdate.checkAndRefresh());
//
//   // Keep every open tab current without asking.
//   UWebUpdate.startWatching(interval: const Duration(minutes: 10), silent: true);
//
//   // Read what is deployed, e.g. to show it next to the running version.
//   final UWebBuild? deployed = await UWebUpdate.serverBuild();
// -----------------------------------------------------------------------------
