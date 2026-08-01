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

  final JSFunction listener = handle.toJS;
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
