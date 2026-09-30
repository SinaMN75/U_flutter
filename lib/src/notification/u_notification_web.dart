import "dart:js_interop";
import "dart:js_interop_unsafe";

import "package:u/src/notification/u_notification_types.dart";
import "package:web/web.dart" as web;

// Browser half of UNotifyChannel: page notifications (clicks come back while the tab is open).
abstract final class UNotificationWeb {
  static void Function(UNotificationEvent event)? onEvent;
  static final Map<int, web.Notification> _shown = <int, web.Notification>{};

  static bool get _supported => (web.window as JSObject).has("Notification");

  static UNotificationPermissionStatus _status(String value) => switch (value) {
    "granted" => UNotificationPermissionStatus.granted,
    "denied" => UNotificationPermissionStatus.denied,
    _ => UNotificationPermissionStatus.notDetermined,
  };

  static Future<UNotificationPermission> permission() async {
    if (!_supported) return const UNotificationPermission(status: UNotificationPermissionStatus.unsupported);
    return UNotificationPermission(status: _status(web.Notification.permission));
  }

  static Future<UNotificationPermission> requestPermission() async {
    if (!_supported) return const UNotificationPermission(status: UNotificationPermissionStatus.unsupported);
    try {
      return UNotificationPermission(status: _status((await web.Notification.requestPermission().toDart).toDart));
    } catch (_) {
      return permission();
    }
  }

  static Future<bool> show(Map<String, Object?> request) async {
    if (!_supported || web.Notification.permission != "granted") return false;
    final int id = (request["id"] as num?)?.toInt() ?? 0;
    final String? payload = request["payload"] as String?;
    try {
      _shown.remove(id)?.close();
      final web.NotificationOptions options = web.NotificationOptions(
        body: <String?>[request["subtitle"] as String?, request["body"] as String?].whereType<String>().join("\n"),
        tag: "u_$id",
        silent: request["silent"] == true,
        requireInteraction: request["ongoing"] == true,
      );
      final String? icon = (request["largeIcon"] ?? request["image"]) as String?;
      if (icon != null) options.icon = icon;
      final web.Notification notification = web.Notification((request["title"] as String?) ?? "", options);
      notification.onclick = ((web.Event _) {
        web.window.focus();
        notification.close();
        onEvent?.call(UNotificationEvent.fromMap(<String, Object?>{"type": "tap", "id": id, "payload": payload}));
      }).toJS;
      notification.onclose = ((web.Event _) => _shown.remove(id)).toJS;
      _shown[id] = notification;
      final int? timeout = (request["timeoutMs"] as num?)?.toInt();
      // A closure on purpose: tear-offs of JS interop members do not compile for the web.
      // ignore: unnecessary_lambdas
      if (timeout != null) Future<void>.delayed(Duration(milliseconds: timeout), () => notification.close());
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> cancel(int id) async => _shown.remove(id)?.close();

  static Future<void> cancelAll() async {
    for (final web.Notification n in _shown.values) {
      n.close();
    }
    _shown.clear();
  }

  // Badging API: installed PWAs on Chromium and Safari 17+.
  static Future<bool> setBadge(int count) async {
    final JSObject navigator = web.window.navigator as JSObject;
    if (!navigator.has("setAppBadge")) return false;
    try {
      if (count <= 0) {
        await navigator.callMethod<JSPromise<JSAny?>>("clearAppBadge".toJS).toDart;
      } else {
        await navigator.callMethod<JSPromise<JSAny?>>("setAppBadge".toJS, count.toJS).toDart;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
