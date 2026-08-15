import "package:u/utilities.dart";

abstract class UNotification {
  static void showNotification({
    required String title,
    required String message,
    required Function(NotificationResponse) onNotificationTap,
    String channelId = "channelId",
    String channelName = "channelName",
    String channelDescription = "channelDescription",
    String? payload,
  }) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings("@mipmap/launcher_icon"),
      iOS: DarwinInitializationSettings(),
      linux: LinuxInitializationSettings(defaultActionName: ""),
      macOS: DarwinInitializationSettings(),
    );
    flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onNotificationTap,
    );
    flutterLocalNotificationsPlugin.show(
      id: 0,
      title: title,
      body: message,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          ticker: "ticker",
          enableLights: true,
          colorized: true,
        ),
      ),
    );
  }
}
