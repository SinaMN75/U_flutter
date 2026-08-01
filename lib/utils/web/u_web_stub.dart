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
