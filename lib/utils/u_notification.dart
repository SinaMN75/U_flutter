import "package:u/utilities.dart";

abstract class UNotification {
  static void showNotification({
    required final String title,
    required final String message,
    required final Function(NotificationResponse) onNotificationTap,
    final String channelId = "channelId",
    final String channelName = "channelName",
    final String channelDescription = "channelDescription",
    final String? payload,
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
