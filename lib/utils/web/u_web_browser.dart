import "dart:js_interop";
import "dart:js_interop_unsafe";

import "package:flutter_web_plugins/flutter_web_plugins.dart";
import "package:u/components/media/u_media_web.dart";
import "package:u/plugins/camera/u_camera_web.dart";
import "package:web/web.dart" as web;

// =============================================================================
// u_web_browser — the browser half of the `u` plugin. Nothing to maintain.
//
// Compiled only when `dart.library.js_interop` is available, i.e. for dart2js,
// DDC and dart2wasm. It holds two things that never need touching:
//
//   * [UWeb]        — the plugin's web entry point. `pubspec.yaml` points
//                     `plugin.platforms.web.fileName` at this file and Flutter's
//                     generated registrant calls `UWeb.registerWith` before main().
//   * [UWebBridge]  — raw browser bindings behind the same member names as the
//                     no-ops in `u_web_native.dart`. Keep the two in lockstep.
//
// Everything a caller should ever touch lives in `u_web.dart` instead.
// =============================================================================

/// Registers every web implementation of the `u` plugin with the Flutter engine.
/// `pubspec.yaml` points `plugin.platforms.web.fileName` here and Flutter's
/// generated registrant calls [registerWith] before `main()`.
abstract class UWeb {
  static void registerWith(Registrar registrar) {
    UMediaWeb.registerWith(registrar);
    UCameraWeb.registerWith(registrar);
  }
}

/// Thin, dependency-free wrappers over the browser APIs the rest of `u` needs.
abstract class UWebBridge {
  // ---------------------------------------------------------------------------
  // Embed detection
  // ---------------------------------------------------------------------------

  /// True when the page runs inside an iframe or a native WebView user-agent.
  static bool isEmbedded() => _isInIframe() || _isWebViewUserAgent();

  static bool _isInIframe() {
    try {
      return web.window.self != web.window.top;
    } catch (_) {
      // Cross-origin access to window.top throws, which itself means we are framed.
      return true;
    }
  }

  static bool _isWebViewUserAgent() {
    final String ua = web.window.navigator.userAgent.toLowerCase();
    final bool androidWebView = ua.contains("; wv") || ua.contains(" wv)");
    final bool iosWebView = ua.contains("applewebkit") && !ua.contains("safari") && (ua.contains("mobile") || ua.contains("iphone") || ua.contains("ipad"));
    return androidWebView || iosWebView;
  }

  // ---------------------------------------------------------------------------
  // window "message" events
  // ---------------------------------------------------------------------------

  /// Subscribes to browser window "message" events; returns a disposer that removes the listener.
  static void Function() listenMessage(void Function(String origin, Map<String, dynamic> data) onMessage) {
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

  /// True when the site is running as an installed PWA (launched from the home screen).
  static bool isStandalone() => _iosLegacyStandalone() || _displayModeStandalone();

  // Legacy iOS Safari flag exposed as `navigator.standalone`, undefined everywhere else.
  static bool _iosLegacyStandalone() {
    try {
      final JSObject navigator = web.window.navigator as JSObject;
      if (!navigator.has("standalone")) return false;
      return navigator.getProperty<JSBoolean>("standalone".toJS).toDart;
    } catch (_) {
      return false;
    }
  }

  static bool _displayModeStandalone() {
    try {
      return web.window.matchMedia("(display-mode: standalone)").matches || web.window.matchMedia("(display-mode: fullscreen)").matches;
    } catch (_) {
      return false;
    }
  }

  static String userAgent() => web.window.navigator.userAgent;

  // ---------------------------------------------------------------------------
  // Build freshness / cache control
  // ---------------------------------------------------------------------------

  /// Absolute URL of the document currently shown, including query and fragment.
  static String documentUrl() => web.window.location.href;

  /// Absolute URL the app is deployed under, always with a trailing slash.
  static String baseUrl() {
    final String base = web.document.baseURI;
    return base.endsWith("/") ? base : "$base/";
  }

  /// Downloads [url] with the given HTTP cache mode ("no-store", "force-cache", "reload", ...).
  /// Null on any failure, so callers can treat "offline" and "missing" the same way.
  static Future<String?> fetch(String url, String cacheMode) async {
    try {
      final web.Response response = await web.window.fetch(url.toJS, web.RequestInit(cache: cacheMode)).toDart;
      if (!response.ok) return null;
      return (await response.text().toDart).toDart;
    } catch (_) {
      return null;
    }
  }

  /// Re-downloads [urls] and overwrites their HTTP cache entries, so the next
  /// navigation reads the server copy even for `Cache-Control: immutable` assets.
  static Future<void> revalidate(List<String> urls) async {
    await Future.wait(
      urls.map((String url) async {
        try {
          await web.window.fetch(url.toJS, web.RequestInit(cache: "reload")).toDart;
        } catch (_) {}
      }),
    );
  }

  /// Script URL of the service worker serving this page, e.g. ".../flutter_service_worker.js?v=123".
  static String? activeServiceWorkerUrl() {
    try {
      return web.window.navigator.serviceWorker.controller?.scriptURL;
    } catch (_) {
      return null;
    }
  }

  /// Asks every registration to re-check the server; true when a newer worker is installing or waiting.
  static Future<bool> serviceWorkerHasPendingUpdate() async {
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

  /// Releases any waiting worker and unregisters every service worker of this origin.
  static Future<void> unregisterServiceWorkers() async {
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

  /// Deletes every CacheStorage bucket, including the ones the Flutter service worker fills.
  static Future<void> clearCaches() async {
    try {
      final List<JSString> keys = (await web.window.caches.keys().toDart).toDart;
      for (final JSString key in keys) {
        try {
          await web.window.caches.delete(key.toDart).toDart;
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Reloads the page, or navigates to [url] without adding a history entry.
  static void reload(String? url) {
    if (url == null) {
      web.window.location.reload();
    } else {
      web.window.location.replace(url);
    }
  }

  /// Runs [onVisible] every time the tab comes back to the foreground; returns a disposer.
  static void Function() listenVisible(void Function() onVisible) {
    void handle(web.Event event) {
      if (!web.document.hidden) onVisible();
    }

    final JSExportedDartFunction<void Function(web.Event event)> listener = handle.toJS;
    web.document.addEventListener("visibilitychange", listener);
    return () => web.document.removeEventListener("visibilitychange", listener);
  }
}
