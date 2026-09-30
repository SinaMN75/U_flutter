import "package:u/utilities.dart";

/// Local notifications on all 6 platforms: show, schedule (Gregorian or Jalali repeats), buttons, replies, progress, badges, channels. Needs `dart run u:app permission add notifications`. `UNotification.show(1, title: "Done")`
abstract final class UNotification {
  /// Sets up notifications; initU() already calls it. [androidIcon] is a drawable name (default: the app icon). `UNotification.init(androidIcon: "ic_notification")`
  static Future<void> init({String? androidIcon, String? windowsIconPath, bool showInForeground = true}) => UNotifyChannel.init(
    appId: UPackage.isReady ? UPackage.packageName : null,
    appName: UPackage.isReady ? UPackage.appName : null,
    androidIcon: androidIcon,
    windowsIconPath: windowsIconPath,
    showInForeground: showInForeground,
  );

  /// Shows a notification now; the same [id] replaces the old one. Web: only while the tab is open. `UNotification.show(1, title: "Order shipped", body: "Arrives tomorrow")`
  static Future<bool> show(int id, {String? title, String? body, Map<String, Object?>? payload, String? image, List<UNotificationAction> actions = const <UNotificationAction>[]}) =>
      UNotifyChannel.show(UNotificationRequest(id: id, title: title, body: body, payload: payload, image: image, actions: actions));

  /// Shows a notification with every option (big picture, buttons, reply, channel, group, sound, full screen…). `UNotification.showRequest(UNotificationRequest(id: 2, title: "Hi", actions: [...]))`
  static Future<bool> showRequest(UNotificationRequest request) => UNotifyChannel.show(request);

  /// Shows or updates a progress notification (Android, Windows, Linux bar; others show the percent in text). `UNotification.progress(5, title: "Downloading", value: 40)`
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

  /// Shows [request] at [at], optionally repeating; monthly/yearly follow [calendar] (Jalali supported). Exact time on Android: `permission add alarm`. `UNotification.schedule(req, DateTime.now().add(1.hours))`
  static Future<bool> schedule(UNotificationRequest request, DateTime at, {URepeat repeat = URepeat.none, URepeatCalendar calendar = URepeatCalendar.gregorian, bool exact = true}) =>
      UNotifyChannel.schedule(request, at, repeat: repeat, calendar: calendar, exact: exact);

  /// Shows a notification after [delay]. `UNotification.after(30.minutes, req)`
  static Future<bool> after(Duration delay, UNotificationRequest request) => UNotifyChannel.schedule(request, DateTime.now().add(delay));

  /// Every day at [hour]:[minute]. `UNotification.daily(req, hour: 9)`
  static Future<bool> daily(UNotificationRequest request, {required int hour, int minute = 0}) {
    final DateTime now = DateTime.now();
    return UNotifyChannel.schedule(request, DateTime(now.year, now.month, now.day, hour, minute), repeat: URepeat.daily);
  }

  /// Every week on [weekday] (DateTime.monday…sunday) at [hour]:[minute]. `UNotification.weekly(req, weekday: DateTime.saturday, hour: 10)`
  static Future<bool> weekly(UNotificationRequest request, {required int weekday, required int hour, int minute = 0}) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day, hour, minute);
    return UNotifyChannel.schedule(request, today.add(Duration(days: (weekday - now.weekday) % 7)), repeat: URepeat.weekly);
  }

  /// Every Jalali month on [day] at [hour]:[minute]; short months fall back to their last day. `UNotification.monthlyJalali(req, day: 1, hour: 9)`
  static Future<bool> monthlyJalali(UNotificationRequest request, {required int day, required int hour, int minute = 0}) {
    if (day < 1 || day > 31) throw ArgumentError.value(day, "day", "must be 1-31");
    // Anchor on the latest month that has [day]; later, shorter months clamp to their last day.
    final UJalali now = UJalali.now();
    int year = now.year;
    int month = now.month;
    while (UJalali(year, month).monthLength < day) {
      month--;
      if (month == 0) {
        month = 12;
        year--;
      }
    }
    return UNotifyChannel.schedule(request, UJalali(year, month, day, hour, minute).toDateTime(), repeat: URepeat.monthly, calendar: URepeatCalendar.persian);
  }

  /// Removes a shown or scheduled notification. `UNotification.cancel(1)`
  static Future<void> cancel(int id) => UNotifyChannel.cancel(id);

  /// Removes every shown and scheduled notification.
  static Future<void> cancelAll() => UNotifyChannel.cancelAll();

  /// Removes every shown notification in [group]. `UNotification.cancelGroup("chat_42")`
  static Future<void> cancelGroup(String group) => UNotifyChannel.cancelGroup(group);

  /// Scheduled notifications that have not fired yet. `(await UNotification.pending()).length`
  static Future<List<UNotificationInfo>> pending() => UNotifyChannel.pending();

  /// Notifications currently in the notification centre (web: those shown by this tab).
  static Future<List<UNotificationInfo>> active() => UNotifyChannel.active();

  /// Taps, button presses, replies and dismissals, including the tap that launched the app. `UNotification.events.listen(handle)`
  static Stream<UNotificationEvent> get events => UNotifyChannel.events;

  /// Calls [onEvent] for every tap, button, reply and dismissal. `UNotification.listen((e) => UNavigator.push(OrderPage(e.payload)))`
  static StreamSubscription<UNotificationEvent> listen(void Function(UNotificationEvent event) onEvent) => UNotifyChannel.events.listen(onEvent);

  /// The tap that opened the app, or null when it was opened normally. `final e = await UNotification.launchEvent();`
  static Future<UNotificationEvent?> launchEvent() => UNotifyChannel.launchEvent();

  /// Current permission, plus exact-alarm and full-screen access on Android.
  static Future<UNotificationPermission> permission() => UNotifyChannel.permission();

  /// Asks for permission (Android 13+, Apple, web); [provisional] delivers quietly on iOS without asking. `await UNotification.requestPermission()`
  static Future<UNotificationPermission> requestPermission({bool provisional = false, bool critical = false}) => UNotifyChannel.requestPermission(provisional: provisional, critical: critical);

  /// True when notifications can be shown. `if (!await UNotification.isAllowed()) UNotification.openSettings()`
  static Future<bool> isAllowed() async => (await permission()).isGranted;

  /// Opens this app's notification settings (web: false).
  static Future<bool> openSettings() => ULaunch.settings(USettingsPage.notifications);

  /// Android 12+: opens "Alarms & reminders" so schedules fire to the minute; true elsewhere. Needs `permission add alarm`.
  static Future<bool> requestExactAlarms() => ULaunch.settings(USettingsPage.exactAlarms);

  /// Android only: creates a channel with its own sound, vibration and importance (users can mute each). `UNotification.createChannel(const UNotificationChannel(id: "orders", name: "Orders"))`
  static Future<void> createChannel(UNotificationChannel channel) => UNotifyChannel.createChannel(channel);

  /// Android only: deletes a channel.
  static Future<void> deleteChannel(String id) => UNotifyChannel.deleteChannel(id);

  /// Android only: a heading that groups channels in the app's notification settings.
  static Future<void> createChannelGroup(String id, String name) => UNotifyChannel.createChannelGroup(id, name);

  /// Android only: ids of the app's channels (empty elsewhere).
  static Future<List<String>> channels() => UNotifyChannel.channels();

  /// Sets the app-icon badge number, 0 clears it (iOS, macOS, Windows, Linux Unity launchers, installed PWAs, some Android launchers). `UNotification.setBadge(3)`
  static Future<bool> setBadge(int count) => UNotifyChannel.setBadge(count);

  /// Clears the app-icon badge.
  static Future<bool> clearBadge() => UNotifyChannel.setBadge(0);
}
