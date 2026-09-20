// No-op web bindings used on every non-web platform. The matching real
// implementations live in `u_web_impl.dart` and are swapped in via conditional
// imports when `dart.library.html` is available.

// Non-web platforms are never embedded in a browser iframe/WebView.
bool embedDetectFromDom() => false;

// Nothing to listen to off the web; returns a no-op disposer.
void Function() listenWebMessage(void Function(String origin, Map<String, dynamic> data) onMessage) => () {};

// Native apps are never a browser PWA.
bool uPwaIsStandalone() => false;

// No browser user-agent available.
String uPwaUserAgent() => "";

// No document to read off the web.
String uWebDocumentUrl() => "";

// No deployment base off the web.
String uWebBaseUrl() => "";

// Nothing to download off the web.
Future<String?> uWebFetch(String url, String cacheMode) async => null;

// No HTTP cache to refresh off the web.
Future<void> uWebRevalidate(List<String> urls) async {}

// Native apps never run behind a service worker.
String? uWebActiveServiceWorkerUrl() => null;

Future<bool> uWebServiceWorkerHasPendingUpdate() async => false;

Future<void> uWebUnregisterServiceWorkers() async {}

Future<void> uWebClearCaches() async {}

// Nothing to reload off the web.
void uWebReload(String? url) {}

// Nothing gets hidden and shown off the web; returns a no-op disposer.
void Function() uWebOnVisible(void Function() onVisible) => () {};
