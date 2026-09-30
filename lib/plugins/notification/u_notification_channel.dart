import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;
import "package:path_provider/path_provider.dart";
import "package:u/plugins/device/u_package.dart";
import "package:u/plugins/device/u_storage.dart";
import "package:u/plugins/notification/u_notification_types.dart";
import "package:u/plugins/notification/u_notification_web_stub.dart" if (dart.library.js_interop) "package:u/plugins/notification/u_notification_web.dart";
import "package:u/utils/u_shamsi.dart";
import "package:uuid/uuid.dart";

export "package:u/plugins/notification/u_notification_types.dart";

// =============================================================================
// u_notification_channel — local notifications ("u/notify" + "u/notify/events").
//
//   Android  NotificationCompat (androidx.core, already in the app), exact / inexact alarms,
//            reboot + time-zone rescheduling, background actions and replies, channels
//   iOS      UserNotifications: categories, text replies, attachments, interruption levels,
//            calendar triggers (Gregorian or Persian), provisional / critical permission
//   macOS    UserNotifications (same as iOS), Dock badge
//   Windows  Toast notifications with a COM activator (clicks work after the app closed),
//            scheduled toasts, progress bars, taskbar badge
//   Linux    org.freedesktop.Notifications (actions, inline reply where supported), launcher badge
//   Web      Notification API, app badge
//
// Where the OS has no scheduler (Linux, web) and for repeats on Windows, Dart computes the
// fire times; the schedule is kept in UStorage and re-armed by init().
// =============================================================================

abstract final class UNotifyChannel {
  static const MethodChannel _channel = MethodChannel("u/notify");
  static const EventChannel _events = EventChannel("u/notify/events");
  static const String _storeKey = "__u.notify.schedules";
  static const int _windowsBatch = 32;

  static final StreamController<UNotificationEvent> _controller = StreamController<UNotificationEvent>.broadcast();
  static final List<UNotificationEvent> _early = <UNotificationEvent>[];
  static StreamSubscription<dynamic>? _subscription;
  static final Map<int, Timer> _timers = <int, Timer>{};
  static bool _initialized = false;

  static bool get _softScheduler => kIsWeb || Platform.isLinux;

  static bool get _windows => !kIsWeb && Platform.isWindows;

  static Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint("u/notify.$method failed: ${e.code} ${e.message ?? ""}");
      return null;
    }
  }

  // --- Setup -------------------------------------------------------------------

  /// Registers with the OS, starts receiving taps and re-arms Dart-side schedules. Idempotent.
  static Future<void> init({String? appId, String? appName, String? androidIcon, String? windowsIconPath, bool showInForeground = true}) async {
    _listen();
    if (_initialized) return;
    _initialized = true;
    final String id = appId ?? (UPackage.isReady ? UPackage.packageName : "u.app");
    if (kIsWeb) {
      UNotificationWeb.onEvent = _controller.add;
    } else {
      await _call<void>("init", <String, Object?>{
        "appId": id,
        "appName": appName ?? (UPackage.isReady && UPackage.appName.isNotEmpty ? UPackage.appName : id),
        // Windows toast activation needs a stable CLSID per app.
        "guid": const Uuid().v5(Namespace.url.value, "u.notify.$id"),
        "icon": androidIcon,
        "iconPath": windowsIconPath,
        "foreground": showInForeground,
      });
    }
    await _rearm();
  }

  static void _listen() {
    if (_subscription != null || kIsWeb) return;
    _subscription = _events.receiveBroadcastStream().listen(
      (dynamic e) {
        if (e is! Map) return;
        Map<Object?, Object?> map = e;
        // Windows toast activations carry the event as the JSON arguments string we put in the XML.
        if (map["json"] is String) {
          try {
            map = <Object?, Object?>{...(jsonDecode(map["json"]! as String) as Map<Object?, Object?>), if (map["input"] != null) "input": map["input"]};
          } catch (_) {
            return;
          }
        }
        final UNotificationEvent event = UNotificationEvent.fromMap(map);
        if (_controller.hasListener) {
          _controller.add(event);
        } else {
          _early.add(event);
        }
      },
      onError: (Object e) => debugPrint("u/notify events failed: $e"),
    );
  }

  /// Taps, button presses, replies and dismissals. Ones that arrived before anyone listened
  /// (including the tap that launched the app) are delivered first.
  static Stream<UNotificationEvent> get events {
    _listen();
    return Stream<UNotificationEvent>.multi((MultiStreamController<UNotificationEvent> sink) {
      for (final UNotificationEvent e in _early) {
        sink.add(e);
      }
      _early.clear();
      final StreamSubscription<UNotificationEvent> sub = _controller.stream.listen(sink.add, onError: sink.addError);
      sink.onCancel = sub.cancel;
    }, isBroadcast: true);
  }

  /// The notification tap that launched the app, if any.
  static Future<UNotificationEvent?> launchEvent() async {
    if (kIsWeb) return null;
    final Map<Object?, Object?>? raw = await _call<Map<Object?, Object?>>("launchEvent");
    return raw == null ? null : UNotificationEvent.fromMap(raw);
  }

  // --- Permission ----------------------------------------------------------------

  static Future<UNotificationPermission> permission() async {
    await init();
    if (kIsWeb) return UNotificationWeb.permission();
    final Map<Object?, Object?>? raw = await _call<Map<Object?, Object?>>("permission");
    return raw == null ? const UNotificationPermission(status: UNotificationPermissionStatus.unsupported) : UNotificationPermission.fromMap(raw);
  }

  /// Asks for permission. [provisional] (iOS) delivers quietly without asking; [critical] needs Apple's entitlement.
  static Future<UNotificationPermission> requestPermission({bool provisional = false, bool critical = false}) async {
    await init();
    if (kIsWeb) return UNotificationWeb.requestPermission();
    final Map<Object?, Object?>? raw = await _call<Map<Object?, Object?>>("requestPermission", <String, Object?>{"provisional": provisional, "critical": critical});
    return raw == null ? await permission() : UNotificationPermission.fromMap(raw);
  }

  // --- Showing -------------------------------------------------------------------

  // Remote images become temp files: native notifications only take local files.
  static Future<UNotificationRequest> _prepare(UNotificationRequest request) async {
    if (kIsWeb) return request;
    Future<String?> local(String? source) async {
      if (source == null || !source.startsWith("http")) return source;
      try {
        final http.Response response = await http.get(Uri.parse(source)).timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) return null;
        final String name = Uri.parse(source).pathSegments.lastOrNull ?? "image";
        final File file = File("${(await getTemporaryDirectory()).path}${Platform.pathSeparator}u_notify_${source.hashCode.abs()}_$name");
        await file.writeAsBytes(response.bodyBytes, flush: true);
        return file.path;
      } catch (_) {
        return null;
      }
    }

    return request.copyWith(image: await local(request.image), largeIcon: await local(request.largeIcon));
  }

  static Future<bool> show(UNotificationRequest request) async {
    await init();
    final UNotificationRequest ready = await _prepare(request);
    if (kIsWeb) return UNotificationWeb.show(ready.toMap());
    return await _call<bool>("show", ready.toMap()) ?? false;
  }

  /// Shows [request] at [at], optionally repeating. Survives restarts (and reboots on Android).
  static Future<bool> schedule(
    UNotificationRequest request,
    DateTime at, {
    URepeat repeat = URepeat.none,
    URepeatCalendar calendar = URepeatCalendar.gregorian,
    bool exact = true,
  }) async {
    await init();
    final UNotificationRequest ready = await _prepare(request);
    final Map<String, Object?> record = <String, Object?>{
      "request": ready.toMap(),
      "at": at.millisecondsSinceEpoch,
      "repeat": repeat.name,
      "calendar": calendar.name,
    };
    if (_softScheduler) {
      await _store(ready.id, record);
      _arm(ready.id, record);
      return true;
    }
    if (_needsBatch(record)) {
      await _store(ready.id, record);
      return _scheduleBatch(ready.id, record);
    }
    return await _call<bool>("schedule", <String, Object?>{...record, "exact": exact}) ?? false;
  }

  // --- Dart-side schedules ---------------------------------------------------------

  static Map<String, Object?> _records() => (UStorage.isReady ? UStorage.get<Map<String, dynamic>>(_storeKey) : null) ?? <String, Object?>{};

  static Future<void> _store(int id, Map<String, Object?>? record) async {
    if (!UStorage.isReady) await UStorage.init();
    final Map<String, Object?> all = Map<String, Object?>.of(_records());
    if (record == null) {
      all.remove("$id");
    } else {
      all["$id"] = record;
    }
    await UStorage.set(_storeKey, all);
  }

  static Future<void> _rearm() async {
    if (!UStorage.isReady) await UStorage.init();
    for (final MapEntry<String, Object?> e in _records().entries) {
      final Map<String, Object?> record = Map<String, Object?>.from(e.value! as Map<dynamic, dynamic>);
      final int id = int.parse(e.key);
      if (_softScheduler) {
        _arm(id, record);
      } else if (_needsBatch(record)) {
        await _scheduleBatch(id, record);
      }
    }
  }

  static URepeat _repeatOf(Map<String, Object?> r) => URepeat.values.firstWhere((URepeat x) => x.name == r["repeat"], orElse: () => URepeat.none);

  static URepeatCalendar _calendarOf(Map<String, Object?> r) => r["calendar"] == "persian" ? URepeatCalendar.persian : URepeatCalendar.gregorian;

  /// Next fire times after now (at most [count]). Every occurrence is computed from [at] itself,
  /// so "the 31st" stays the 31st (or the month's last day) instead of drifting to the 28th.
  static List<DateTime> upcoming(DateTime at, URepeat repeat, URepeatCalendar calendar, int count) {
    final DateTime now = DateTime.now();
    if (repeat == URepeat.none) return at.isAfter(now) ? <DateTime>[at] : <DateTime>[];
    int k = _estimate(at, now, repeat);
    while (k > 0 && occurrence(at, repeat, calendar, k - 1).isAfter(now)) {
      k--;
    }
    while (!occurrence(at, repeat, calendar, k).isAfter(now)) {
      k++;
    }
    return <DateTime>[for (int i = 0; i < count; i++) occurrence(at, repeat, calendar, k + i)];
  }

  // A close lower bound for the first index after now, so long-running repeats need few steps.
  static int _estimate(DateTime at, DateTime now, URepeat repeat) {
    if (!now.isAfter(at)) return 0;
    final Duration gap = now.difference(at);
    final int k = switch (repeat) {
      URepeat.none => 0,
      URepeat.minute => gap.inMinutes,
      URepeat.hourly => gap.inHours,
      URepeat.daily => gap.inDays - 1,
      URepeat.weekly => gap.inDays ~/ 7 - 1,
      URepeat.monthly => gap.inDays ~/ 31 - 1,
      URepeat.yearly => gap.inDays ~/ 366 - 1,
    };
    return k < 0 ? 0 : k;
  }

  /// The [k]-th occurrence counted from [anchor]; days past a month's end clamp to its last day.
  static DateTime occurrence(DateTime anchor, URepeat repeat, URepeatCalendar calendar, int k) {
    switch (repeat) {
      case URepeat.none:
        return anchor;
      case URepeat.minute:
        return anchor.add(Duration(minutes: k));
      case URepeat.hourly:
        return anchor.add(Duration(hours: k));
      case URepeat.daily:
        return DateTime(anchor.year, anchor.month, anchor.day + k, anchor.hour, anchor.minute, anchor.second);
      case URepeat.weekly:
        return DateTime(anchor.year, anchor.month, anchor.day + 7 * k, anchor.hour, anchor.minute, anchor.second);
      case URepeat.monthly:
      case URepeat.yearly:
        final int months = repeat == URepeat.monthly ? k : 12 * k;
        if (calendar == URepeatCalendar.persian) {
          final UJalali j = UJalali.fromDateTime(anchor);
          final int index = j.year * 12 + (j.month - 1) + months;
          final int year = index ~/ 12;
          final int month = index % 12 + 1;
          final int last = month <= 6 ? 31 : (month <= 11 ? 30 : (UJalali(year).isLeapYear() ? 30 : 29));
          return UJalali(year, month, j.day > last ? last : j.day, anchor.hour, anchor.minute, anchor.second).toDateTime();
        }
        final int index = anchor.year * 12 + (anchor.month - 1) + months;
        final int year = index ~/ 12;
        final int month = index % 12 + 1;
        final int last = DateTime(year, month + 1, 0).day;
        return DateTime(year, month, anchor.day > last ? last : anchor.day, anchor.hour, anchor.minute, anchor.second);
    }
  }

  // Monthly / yearly repeats on days some months lack: Apple's repeating calendar trigger would
  // skip those months, so Apple gets a batch of concrete dates too (refilled by init()).
  static bool _needsBatch(Map<String, Object?> record) {
    if (_windows) return true;
    if (kIsWeb || !(Platform.isIOS || Platform.isMacOS)) return false;
    final URepeat repeat = _repeatOf(record);
    if (repeat != URepeat.monthly && repeat != URepeat.yearly) return false;
    final DateTime at = DateTime.fromMillisecondsSinceEpoch((record["at"]! as num).toInt());
    return _calendarOf(record) == URepeatCalendar.persian ? UJalali.fromDateTime(at).day > 29 : at.day > 28;
  }

  static void _arm(int id, Map<String, Object?> record) {
    _timers.remove(id)?.cancel();
    final List<DateTime> next = upcoming(DateTime.fromMillisecondsSinceEpoch((record["at"]! as num).toInt()), _repeatOf(record), _calendarOf(record), 1);
    if (next.isEmpty) {
      unawaited(_store(id, null));
      return;
    }
    _timers[id] = Timer(next.first.difference(DateTime.now()), () async {
      final Map<String, Object?> request = Map<String, Object?>.from(record["request"]! as Map<dynamic, dynamic>);
      if (kIsWeb) {
        await UNotificationWeb.show(request);
      } else {
        await _call<bool>("show", request);
      }
      if (_repeatOf(record) == URepeat.none) {
        _timers.remove(id);
        await _store(id, null);
      } else {
        // The anchor stays; upcoming() finds the next occurrence from it.
        _arm(id, record);
      }
    });
  }

  // Windows (always) and Apple (month-end repeats) get the next batch of concrete dates, refilled
  // on every init().
  static Future<bool> _scheduleBatch(int id, Map<String, Object?> record) async {
    final List<DateTime> times = upcoming(DateTime.fromMillisecondsSinceEpoch((record["at"]! as num).toInt()), _repeatOf(record), _calendarOf(record), _windows ? _windowsBatch : 12);
    if (times.isEmpty) {
      await _store(id, null);
      return false;
    }
    return await _call<bool>("schedule", <String, Object?>{
          "request": record["request"],
          "times": times.map((DateTime t) => t.millisecondsSinceEpoch).toList(),
        }) ??
        false;
  }

  // --- Managing --------------------------------------------------------------------

  static Future<void> cancel(int id) async {
    _timers.remove(id)?.cancel();
    await _store(id, null);
    if (kIsWeb) return UNotificationWeb.cancel(id);
    await _call<void>("cancel", <String, Object?>{"id": id});
  }

  static Future<void> cancelAll() async {
    for (final Timer t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    if (UStorage.isReady) await UStorage.remove(_storeKey);
    if (kIsWeb) return UNotificationWeb.cancelAll();
    await _call<void>("cancelAll");
  }

  static Future<void> cancelGroup(String group) async {
    if (kIsWeb) return;
    await _call<void>("cancelGroup", <String, Object?>{"group": group});
  }

  /// Scheduled notifications that have not fired yet.
  static Future<List<UNotificationInfo>> pending() async {
    if (_softScheduler || _windows) {
      if (!UStorage.isReady) await UStorage.init();
      return <UNotificationInfo>[
        for (final MapEntry<String, Object?> e in _records().entries)
          () {
            final Map<String, Object?> record = Map<String, Object?>.from(e.value! as Map<dynamic, dynamic>);
            final Map<String, Object?> request = Map<String, Object?>.from(record["request"]! as Map<dynamic, dynamic>);
            final List<DateTime> next = upcoming(DateTime.fromMillisecondsSinceEpoch((record["at"]! as num).toInt()), _repeatOf(record), _calendarOf(record), 1);
            return UNotificationInfo(id: int.parse(e.key), title: request["title"] as String?, body: request["body"] as String?, next: next.isEmpty ? null : next.first);
          }(),
      ];
    }
    final List<Object?>? raw = await _call<List<Object?>>("pending");
    return (raw ?? <Object?>[]).whereType<Map<Object?, Object?>>().map(UNotificationInfo.fromMap).toList();
  }

  /// Notifications currently shown in the notification centre.
  static Future<List<UNotificationInfo>> active() async {
    if (kIsWeb) return const <UNotificationInfo>[];
    final List<Object?>? raw = await _call<List<Object?>>("active");
    return (raw ?? <Object?>[]).whereType<Map<Object?, Object?>>().map(UNotificationInfo.fromMap).toList();
  }

  // --- Channels (Android) ------------------------------------------------------------

  static Future<void> createChannel(UNotificationChannel channel) async {
    if (!kIsWeb) await _call<void>("createChannel", channel.toMap());
  }

  static Future<void> deleteChannel(String id) async {
    if (!kIsWeb) await _call<void>("deleteChannel", <String, Object?>{"id": id});
  }

  static Future<void> createChannelGroup(String id, String name) async {
    if (!kIsWeb) await _call<void>("createChannelGroup", <String, Object?>{"id": id, "name": name});
  }

  static Future<List<String>> channels() async {
    if (kIsWeb) return const <String>[];
    return ((await _call<List<Object?>>("channels")) ?? <Object?>[]).map((Object? e) => "$e").toList();
  }

  // --- Badge ---------------------------------------------------------------------------

  /// App icon badge (iOS, macOS Dock, Windows taskbar, Linux launchers, installed PWAs). 0 clears it.
  static Future<bool> setBadge(int count) async {
    if (kIsWeb) return UNotificationWeb.setBadge(count);
    return await _call<bool>("setBadge", <String, Object?>{"count": count}) ?? false;
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
