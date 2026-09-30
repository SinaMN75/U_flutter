import "package:u/src/notification/u_notification_types.dart";

// Off the web these are never called; UNotifyChannel checks kIsWeb first.
abstract final class UNotificationWeb {
  static void Function(UNotificationEvent event)? onEvent;

  static Future<UNotificationPermission> permission() async => const UNotificationPermission(status: UNotificationPermissionStatus.unsupported);

  static Future<UNotificationPermission> requestPermission() => permission();

  static Future<bool> show(Map<String, Object?> request) async => false;

  static Future<void> cancel(int id) async {}

  static Future<void> cancelAll() async {}

  static Future<bool> setBadge(int count) async => false;
}
