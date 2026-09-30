import "package:u/utilities.dart";

/// Local notifications: show, schedule (Gregorian or Jalali repeats), buttons, replies, progress,
/// badges and channels on every platform. Wraps [UNotifyChannel] (lib/plugins/notification).
abstract final class UNotification {
  /// Sets up notifications (initU() already does this); [androidIcon] is a drawable name for the status bar.
  static Future<void> init({String? androidIcon, String? windowsIconPath, bool showInForeground = true}) => UNotifyChannel.init(
    appId: UPackage.isReady ? UPackage.packageName : null,
    appName: UPackage.isReady ? UPackage.appName : null,
    androidIcon: androidIcon,
    windowsIconPath: windowsIconPath,
    showInForeground: showInForeground,
  );

  /// Shows a notification now; the same [id] replaces an existing one.
  static Future<bool> show(int id, {String? title, String? body, Map<String, Object?>? payload, String? image, List<UNotificationAction> actions = const <UNotificationAction>[]}) =>
      UNotifyChannel.show(UNotificationRequest(id: id, title: title, body: body, payload: payload, image: image, actions: actions));

  /// Shows a notification with every option (style, channel, group, sound, full screen, …).
  static Future<bool> showRequest(UNotificationRequest request) => UNotifyChannel.show(request);

  /// Shows or updates a progress notification (downloads, uploads, exports).
  static Future<bool> progress(int id, {required String title, required int value, int max = 100, String? body, bool indeterminate = false}) => UNotifyChannel.show(
    UNotificationRequest(
      id: id,
      title: title,
      body: body,
      progress: UNotificationProgress(value: value, max: max, indeterminate: indeterminate),
      ongoing: value < max,
      silent: true,
      importance: UNotificationImportance.low,
      category: "progress",
    ),
  );

  /// Shows [request] at [at]; [repeat] makes it recur (monthly/yearly follow [calendar], e.g. Jalali).
  static Future<bool> schedule(UNotificationRequest request, DateTime at, {URepeat repeat = URepeat.none, URepeatCalendar calendar = URepeatCalendar.gregorian, bool exact = true}) =>
      UNotifyChannel.schedule(request, at, repeat: repeat, calendar: calendar, exact: exact);

  /// Shows a notification after [delay].
  static Future<bool> after(Duration delay, UNotificationRequest request) => UNotifyChannel.schedule(request, DateTime.now().add(delay));

  /// Shows a notification every day at [hour]:[minute].
  static Future<bool> daily(UNotificationRequest request, {required int hour, int minute = 0}) {
    final DateTime now = DateTime.now();
    return UNotifyChannel.schedule(request, DateTime(now.year, now.month, now.day, hour, minute), repeat: URepeat.daily);
  }

  /// Shows a notification every week on [weekday] (DateTime.monday … sunday) at [hour]:[minute].
  static Future<bool> weekly(UNotificationRequest request, {required int weekday, required int hour, int minute = 0}) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day, hour, minute);
    return UNotifyChannel.schedule(request, today.add(Duration(days: (weekday - now.weekday) % 7)), repeat: URepeat.weekly);
  }

  /// Shows a notification every Jalali month on [day] at [hour]:[minute] (e.g. rent on the 1st).
  static Future<bool> monthlyJalali(UNotificationRequest request, {required int day, required int hour, int minute = 0}) {
    final UJalali now = UJalali.now();
    return UNotifyChannel.schedule(request, UJalali(now.year, now.month, day, hour, minute).toDateTime(), repeat: URepeat.monthly, calendar: URepeatCalendar.persian);
  }

  /// Cancels a shown or scheduled notification.
  static Future<void> cancel(int id) => UNotifyChannel.cancel(id);

  /// Cancels every shown and scheduled notification.
  static Future<void> cancelAll() => UNotifyChannel.cancelAll();

  /// Removes every shown notification of a group.
  static Future<void> cancelGroup(String group) => UNotifyChannel.cancelGroup(group);

  /// Scheduled notifications that have not fired yet.
  static Future<List<UNotificationInfo>> pending() => UNotifyChannel.pending();

  /// Notifications currently in the notification centre.
  static Future<List<UNotificationInfo>> active() => UNotifyChannel.active();

  /// Taps, button presses, replies and dismissals (including the tap that launched the app).
  static Stream<UNotificationEvent> get events => UNotifyChannel.events;

  /// Calls [onEvent] for every tap, button, reply and dismissal.
  static StreamSubscription<UNotificationEvent> listen(void Function(UNotificationEvent event) onEvent) => UNotifyChannel.events.listen(onEvent);

  /// The notification tap that launched the app (null if it was opened normally).
  static Future<UNotificationEvent?> launchEvent() => UNotifyChannel.launchEvent();

  /// Current permission (and exact-alarm / full-screen access on Android).
  static Future<UNotificationPermission> permission() => UNotifyChannel.permission();

  /// Asks for permission ([provisional]: iOS delivers quietly without a prompt).
  static Future<UNotificationPermission> requestPermission({bool provisional = false, bool critical = false}) =>
      UNotifyChannel.requestPermission(provisional: provisional, critical: critical);

  /// True when notifications can be shown.
  static Future<bool> isAllowed() async => (await permission()).isGranted;

  /// Opens this app's notification settings.
  static Future<bool> openSettings() => ULaunch.settings(USettingsPage.notifications);

  /// Android 12+: opens the "Alarms & reminders" page so schedules can fire to the minute.
  static Future<bool> requestExactAlarms() => ULaunch.settings(USettingsPage.exactAlarms);

  /// Creates an Android channel (sound, vibration, importance).
  static Future<void> createChannel(UNotificationChannel channel) => UNotifyChannel.createChannel(channel);

  /// Deletes an Android channel.
  static Future<void> deleteChannel(String id) => UNotifyChannel.deleteChannel(id);

  /// Creates an Android channel group (a heading in the app's notification settings).
  static Future<void> createChannelGroup(String id, String name) => UNotifyChannel.createChannelGroup(id, name);

  /// Ids of the app's Android channels.
  static Future<List<String>> channels() => UNotifyChannel.channels();

  /// Sets the app icon badge number (0 clears it).
  static Future<bool> setBadge(int count) => UNotifyChannel.setBadge(count);

  /// Clears the app icon badge.
  static Future<bool> clearBadge() => UNotifyChannel.setBadge(0);
}
