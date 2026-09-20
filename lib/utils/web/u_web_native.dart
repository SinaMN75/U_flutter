// =============================================================================
// u_web_native — the non-web half of the browser bridge. Nothing to maintain.
//
// Every member is a no-op, so code that talks to the browser compiles and runs
// unchanged on Android, iOS, macOS, Windows and Linux. The real bindings live in
// `u_web_browser.dart`; `u_web.dart` swaps the two with a conditional import on
// `dart.library.js_interop`, which is only true when compiling for the web.
//
// Both files must declare the exact same members — add one here whenever you
// add one there, or the native build stops compiling.
// =============================================================================

abstract class UWebBridge {
  // Native apps are never inside a browser iframe or WebView.
  static bool isEmbedded() => false;

  // Nothing posts messages off the web; returns a no-op disposer.
  static void Function() listenMessage(void Function(String origin, Map<String, dynamic> data) onMessage) => () {};

  // Native apps are never a browser PWA.
  static bool isStandalone() => false;

  // No browser user-agent available.
  static String userAgent() => "";

  // No document to read off the web.
  static String documentUrl() => "";

  // No deployment base off the web.
  static String baseUrl() => "";

  // Nothing to download off the web.
  static Future<String?> fetch(String url, String cacheMode) async => null;

  // No HTTP cache to refresh off the web.
  static Future<void> revalidate(List<String> urls) async {}

  // Native apps never run behind a service worker.
  static String? activeServiceWorkerUrl() => null;

  static Future<bool> serviceWorkerHasPendingUpdate() async => false;

  static Future<void> unregisterServiceWorkers() async {}

  static Future<void> clearCaches() async {}

  // Nothing to reload off the web.
  static void reload(String? url) {}

  // Nothing gets hidden and shown off the web; returns a no-op disposer.
  static void Function() listenVisible(void Function() onVisible) => () {};
}
