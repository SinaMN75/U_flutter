import "dart:async";

import "package:web/web.dart" as web;

// Browser half of ULaunchChannel.
abstract final class ULaunchWeb {
  static Future<bool> open(String url, String target) async {
    try {
      // noopener keeps the new tab from controlling this one (reverse tabnabbing).
      final web.Window? opened = web.window.open(url, target, target == "_blank" ? "noopener,noreferrer" : "");
      return opened != null || target != "_blank";
    } catch (_) {
      return false;
    }
  }

  static Future<bool> canOpen(String url) async {
    final String scheme = Uri.tryParse(url)?.scheme ?? "";
    return const <String>{"http", "https", "mailto", "tel", "sms"}.contains(scheme);
  }

  /// Popup OAuth: the provider must redirect back to this site ([callbackScheme] is a URL prefix
  /// on this origin, e.g. "https://myapp.com/auth/callback"). Polls the popup until it lands there.
  static Future<Uri?> authenticate(String url, String callbackScheme, Duration timeout) async {
    final web.Window? popup = web.window.open(url, "u_auth", "popup,width=520,height=720");
    if (popup == null) return null;
    final Completer<Uri?> done = Completer<Uri?>();
    final DateTime deadline = DateTime.now().add(timeout);
    Timer.periodic(const Duration(milliseconds: 300), (Timer timer) {
      if (done.isCompleted) return timer.cancel();
      if (popup.closed || DateTime.now().isAfter(deadline)) {
        timer.cancel();
        if (!popup.closed) popup.close();
        done.complete(null);
        return;
      }
      try {
        // Throws while the popup is on the provider's (cross-origin) page.
        final String href = popup.location.href;
        if (href.startsWith(callbackScheme)) {
          timer.cancel();
          popup.close();
          done.complete(Uri.parse(href));
        }
      } catch (_) {}
    });
    return done.future;
  }
}
