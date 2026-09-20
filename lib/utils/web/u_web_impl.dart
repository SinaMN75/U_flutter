import "dart:js_interop";

import "package:web/web.dart" as web;

// Real browser bindings, compiled only when `dart.library.html` is available.
// The matching no-ops live in `u_web_stub.dart`.

// Legacy iOS Safari flag exposed as `navigator.standalone` (undefined elsewhere).
@JS("navigator.standalone")
external JSBoolean? get _iosStandalone;

// ---------------------------------------------------------------------------
// Embed detection
// ---------------------------------------------------------------------------

// True when the page runs inside an iframe or a native WebView user-agent.
bool embedDetectFromDom() => _isInIframe() || _isWebViewUserAgent();

bool _isInIframe() {
  try {
    return web.window.self != web.window.top;
  } catch (_) {
    // Cross-origin access to window.top throws, which itself means we are framed.
    return true;
  }
}

bool _isWebViewUserAgent() {
  final String ua = web.window.navigator.userAgent.toLowerCase();
  final bool androidWebView = ua.contains("; wv") || ua.contains(" wv)");
  final bool iosWebView = ua.contains("applewebkit") && !ua.contains("safari") && (ua.contains("mobile") || ua.contains("iphone") || ua.contains("ipad"));
  return androidWebView || iosWebView;
}

// ---------------------------------------------------------------------------
// window "message" events
// ---------------------------------------------------------------------------

// Subscribes to browser window "message" events and returns a disposer that removes the listener.
void Function() listenWebMessage(void Function(String origin, Map<String, dynamic> data) onMessage) {
  void handle(web.Event event) {
    final web.MessageEvent e = event as web.MessageEvent;
    final Object? decoded = e.data.dartify();
    if (decoded is! Map) return;
    onMessage(e.origin, decoded.map((Object? k, Object? v) => MapEntry<String, dynamic>(k.toString(), v)));
  }

  final JSExportedDartFunction<void Function(web.Event event)> listener = handle.toJS;
  web.window.addEventListener("message", listener);
  return () => web.window.removeEventListener("message", listener);
}

// ---------------------------------------------------------------------------
// PWA / install state
// ---------------------------------------------------------------------------

// True when the site is running as an installed PWA (launched from the home screen).
bool uPwaIsStandalone() {
  final bool iosLegacy = _iosStandalone?.toDart ?? false;
  bool displayModeStandalone = false;
  try {
    displayModeStandalone = web.window.matchMedia("(display-mode: standalone)").matches || web.window.matchMedia("(display-mode: fullscreen)").matches;
  } catch (_) {}
  return iosLegacy || displayModeStandalone;
}

String uPwaUserAgent() => web.window.navigator.userAgent;

// ---------------------------------------------------------------------------
// Build freshness / cache control
// ---------------------------------------------------------------------------

// Absolute URL of the document currently shown, including query and fragment.
String uWebDocumentUrl() => web.window.location.href;

// Absolute URL the app is deployed under, always with a trailing slash.
String uWebBaseUrl() {
  final String base = web.document.baseURI;
  return base.endsWith("/") ? base : "$base/";
}

// Downloads [url] with the given HTTP cache mode ("no-store", "force-cache", "reload", ...).
// Null on any failure, so callers can treat "offline" and "missing" the same way.
Future<String?> uWebFetch(String url, String cacheMode) async {
  try {
    final web.Response response = await web.window.fetch(url.toJS, web.RequestInit(cache: cacheMode)).toDart;
    if (!response.ok) return null;
    return (await response.text().toDart).toDart;
  } catch (_) {
    return null;
  }
}

// Re-downloads [urls] and overwrites their HTTP cache entries, so the next
// navigation reads the server copy even for `Cache-Control: immutable` assets.
Future<void> uWebRevalidate(List<String> urls) async {
  await Future.wait(
    urls.map((String url) async {
      try {
        await web.window.fetch(url.toJS, web.RequestInit(cache: "reload")).toDart;
      } catch (_) {}
    }),
  );
}

// Script URL of the service worker serving this page, e.g. ".../flutter_service_worker.js?v=123".
String? uWebActiveServiceWorkerUrl() {
  try {
    return web.window.navigator.serviceWorker.controller?.scriptURL;
  } catch (_) {
    return null;
  }
}

// Asks every registration to re-check the server; true when a newer worker is installing or waiting.
Future<bool> uWebServiceWorkerHasPendingUpdate() async {
  try {
    final List<web.ServiceWorkerRegistration> registrations = (await web.window.navigator.serviceWorker.getRegistrations().toDart).toDart;
    bool pending = false;
    for (final web.ServiceWorkerRegistration registration in registrations) {
      try {
        await registration.update().toDart;
      } catch (_) {}
      if (registration.waiting != null || registration.installing != null) pending = true;
    }
    return pending;
  } catch (_) {
    return false;
  }
}

// Releases any waiting worker and unregisters every service worker of this origin.
Future<void> uWebUnregisterServiceWorkers() async {
  try {
    final List<web.ServiceWorkerRegistration> registrations = (await web.window.navigator.serviceWorker.getRegistrations().toDart).toDart;
    for (final web.ServiceWorkerRegistration registration in registrations) {
      try {
        // Flutter's generated service worker activates immediately on this message.
        registration.waiting?.postMessage("skipWaiting".toJS);
        await registration.unregister().toDart;
      } catch (_) {}
    }
  } catch (_) {}
}

// Deletes every CacheStorage bucket, including the ones the Flutter service worker fills.
Future<void> uWebClearCaches() async {
  try {
    final List<JSString> keys = (await web.window.caches.keys().toDart).toDart;
    for (final JSString key in keys) {
      try {
        await web.window.caches.delete(key.toDart).toDart;
      } catch (_) {}
    }
  } catch (_) {}
}

// Reloads the page, or navigates to [url] without adding a history entry.
void uWebReload(String? url) {
  if (url == null) {
    web.window.location.reload();
  } else {
    web.window.location.replace(url);
  }
}
