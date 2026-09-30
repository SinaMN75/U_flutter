import "dart:convert";

import "package:flutter/foundation.dart";

// Models shared by the notification engine and its web implementation.

/// How loud a notification is: min, low, normal, high (heads-up), max.
enum UNotificationImportance { min, low, normal, high, max }

/// Lock-screen visibility (Android).
enum UNotificationVisibility { public, private, secret }

/// iOS 15+ interruption level: timeSensitive breaks through Focus; critical needs an Apple entitlement.
enum UNotificationInterruption { passive, active, timeSensitive, critical }

/// Repeat: none, minutely, hourly, daily, weekly, monthly, yearly.
enum URepeat { none, minute, hourly, daily, weekly, monthly, yearly }

/// Calendar for monthly / yearly repeats: "every 1st of the month" in Jalali or Gregorian.
enum URepeatCalendar { gregorian, persian }

/// Event kind: tap, action (button), reply, dismissed.
enum UNotificationEventType { tap, action, reply, dismiss }

/// granted, provisional, denied, notDetermined, unsupported.
enum UNotificationPermissionStatus { granted, provisional, ephemeral, denied, notDetermined, unsupported }

/// A button on a notification.
@immutable
class UNotificationAction {
  const UNotificationAction({
    required this.id,
    required this.title,
    this.input = false,
    this.inputPlaceholder,
    this.inputButton,
    this.destructive = false,
    this.foreground = false,
    this.authenticationRequired = false,
  });

  /// Id sent back in the event.
  final String id;

  /// Button text.
  final String title;

  /// Shows a text field (reply from the notification).
  final bool input;

  /// Hint of the reply field when [input] is true (reply works on Android, Apple, Windows, some Linux).
  final String? inputPlaceholder;

  /// iOS: title of the send button next to the text field.
  final String? inputButton;

  /// Shown in red (iOS / macOS).
  final bool destructive;

  /// Opens the app; otherwise handled in the background without opening it.
  final bool foreground;

  /// iOS: requires unlocking the device first.
  final bool authenticationRequired;

  /// As a map.
  Map<String, Object?> toMap() => <String, Object?>{
    "id": id,
    "title": title,
    "input": input,
    "inputPlaceholder": inputPlaceholder,
    "inputButton": inputButton,
    "destructive": destructive,
    "foreground": foreground,
    "authenticationRequired": authenticationRequired,
  };
}

/// An Android notification channel (sound, vibration and importance are fixed per channel).
@immutable
class UNotificationChannel {
  const UNotificationChannel({
    required this.id,
    required this.name,
    this.description,
    this.importance = UNotificationImportance.normal,
    this.sound,
    this.vibration = true,
    this.vibrationPattern,
    this.lightColor,
    this.showBadge = true,
    this.bypassDnd = false,
    this.visibility = UNotificationVisibility.private,
    this.group,
  });

  /// Channel id (use in requests).
  final String id;

  /// Name shown in system settings.
  final String name;

  /// Description shown in system settings.
  final String? description;

  /// How loud it is.
  final UNotificationImportance importance;

  /// res/raw sound name without extension; "none" for silent.
  final String? sound;

  /// Vibrates.
  final bool vibration;

  /// Milliseconds: off, on, off, on, …
  final List<int>? vibrationPattern;

  /// LED color.
  final int? lightColor;

  /// Adds to the icon badge.
  final bool showBadge;

  /// Rings in Do Not Disturb (needs user permission).
  final bool bypassDnd;

  /// What shows on the lock screen.
  final UNotificationVisibility visibility;

  /// Channel group id (see [UNotificationChannelGroup]).
  final String? group;

  /// As a map.
  Map<String, Object?> toMap() => <String, Object?>{
    "id": id,
    "name": name,
    "description": description,
    "importance": importance.name,
    "sound": sound,
    "vibration": vibration,
    "vibrationPattern": vibrationPattern,
    "lightColor": lightColor,
    "showBadge": showBadge,
    "bypassDnd": bypassDnd,
    "visibility": visibility.name,
    "group": group,
  };
}

/// Progress bar of a notification. `UNotificationProgress(value: 40)`
@immutable
class UNotificationProgress {
  const UNotificationProgress({this.value = 0, this.max = 100, this.indeterminate = false, this.label});

  /// Current value.
  final int value;

  /// Maximum value.
  final int max;

  /// Shows a moving bar without a value.
  final bool indeterminate;

  /// Text next to the bar (Windows) / subtitle.
  final String? label;

  /// Value as 0-1.
  double get fraction => max <= 0 ? 0 : (value / max).clamp(0, 1).toDouble();

  /// As a map.
  Map<String, Object?> toMap() => <String, Object?>{"value": value, "max": max, "indeterminate": indeterminate, "label": label};
}

/// Everything a notification can carry. Platforms ignore what they cannot show.
@immutable
class UNotificationRequest {
  const UNotificationRequest({
    required this.id,
    this.title,
    this.body,
    this.subtitle,
    this.payload,
    this.image,
    this.largeIcon,
    this.channelId,
    this.importance = UNotificationImportance.high,
    this.group,
    this.groupSummary = false,
    this.actions = const <UNotificationAction>[],
    this.progress,
    this.ongoing = false,
    this.autoCancel = true,
    this.silent = false,
    this.sound,
    this.badge,
    this.color,
    this.timeout,
    this.fullScreen = false,
    this.visibility = UNotificationVisibility.private,
    this.lines = const <String>[],
    this.chronometer = false,
    this.when,
    this.interruption = UNotificationInterruption.active,
    this.relevance,
    this.category,
  });

  /// Same id replaces / updates an existing notification.
  final int id;

  /// Title.
  final String? title;

  /// Main text.
  final String? body;

  /// Second line (Apple subtitle, Android sub-text).
  final String? subtitle;

  /// Returned in taps and actions.
  final Map<String, Object?>? payload;

  /// Big picture (local file path; URLs are downloaded first).
  final String? image;

  /// Round image next to the text (local file path or URL).
  final String? largeIcon;

  /// Android channel; created from [importance] when omitted.
  final String? channelId;

  /// How loud it is.
  final UNotificationImportance importance;

  /// Groups related notifications (Android group, iOS thread, Windows group).
  final String? group;

  /// Makes this the summary of its group (Android).
  final bool groupSummary;

  /// Buttons and reply fields.
  final List<UNotificationAction> actions;

  /// Progress bar.
  final UNotificationProgress? progress;

  /// Cannot be swiped away (Android).
  final bool ongoing;

  /// Removes it when tapped.
  final bool autoCancel;

  /// No sound or vibration.
  final bool silent;

  /// Custom sound: Android res/raw name, iOS bundle file name, Windows ms-winsoundevent URI.
  final String? sound;

  /// App icon badge number carried with the notification (iOS / macOS / Android launcher).
  final int? badge;

  /// Accent colour (Android).
  final int? color;

  /// Removed automatically after this long.
  final Duration? timeout;

  /// Full-screen alert like an incoming call (Android; needs USE_FULL_SCREEN_INTENT).
  final bool fullScreen;

  /// What shows on the lock screen.
  final UNotificationVisibility visibility;

  /// Inbox style: one line each.
  final List<String> lines;

  /// Shows a running timer since [when] (Android).
  final bool chronometer;

  /// Time shown on the notification.
  final DateTime? when;

  /// Apple focus level: passive, active, timeSensitive, critical.
  final UNotificationInterruption interruption;

  /// 0-1: which notification leads the summary (iOS 15+).
  final double? relevance;

  /// Android category: alarm, call, email, event, message, progress, reminder, …
  final String? category;

  /// As a map.
  Map<String, Object?> toMap() => <String, Object?>{
    "id": id,
    "title": title,
    "body": body,
    "subtitle": subtitle,
    "payload": payload == null ? null : jsonEncode(payload),
    "image": image,
    "largeIcon": largeIcon,
    "channelId": channelId,
    "importance": importance.name,
    "group": group,
    "groupSummary": groupSummary,
    "actions": actions.map((UNotificationAction a) => a.toMap()).toList(),
    "progress": progress?.toMap(),
    "ongoing": ongoing,
    "autoCancel": autoCancel,
    "silent": silent,
    "sound": sound,
    "badge": badge,
    "color": color,
    "timeoutMs": timeout?.inMilliseconds,
    "fullScreen": fullScreen,
    "visibility": visibility.name,
    "lines": lines,
    "chronometer": chronometer,
    "when": when?.millisecondsSinceEpoch,
    "interruption": interruption.name,
    "relevance": relevance,
    "category": category,
  };

  /// Copy with some fields changed.
  UNotificationRequest copyWith({String? image, String? largeIcon}) => UNotificationRequest(
    id: id,
    title: title,
    body: body,
    subtitle: subtitle,
    payload: payload,
    image: image ?? this.image,
    largeIcon: largeIcon ?? this.largeIcon,
    channelId: channelId,
    importance: importance,
    group: group,
    groupSummary: groupSummary,
    actions: actions,
    progress: progress,
    ongoing: ongoing,
    autoCancel: autoCancel,
    silent: silent,
    sound: sound,
    badge: badge,
    color: color,
    timeout: timeout,
    fullScreen: fullScreen,
    visibility: visibility,
    lines: lines,
    chronometer: chronometer,
    when: when,
    interruption: interruption,
    relevance: relevance,
    category: category,
  );
}

/// A tap, button press, reply or dismissal.
@immutable
class UNotificationEvent {
  const UNotificationEvent({required this.type, required this.id, this.actionId, this.input, this.payload});

  /// Reads it from the native map.
  factory UNotificationEvent.fromMap(Map<Object?, Object?> m) {
    Map<String, Object?>? payload;
    final Object? raw = m["payload"];
    if (raw is String && raw.isNotEmpty) {
      try {
        payload = (jsonDecode(raw) as Map<Object?, Object?>).map((Object? k, Object? v) => MapEntry<String, Object?>("$k", v));
      } catch (_) {}
    }
    return UNotificationEvent(
      type: UNotificationEventType.values.firstWhere((UNotificationEventType t) => t.name == m["type"], orElse: () => UNotificationEventType.tap),
      id: (m["id"] as num?)?.toInt() ?? int.tryParse("${m["id"]}") ?? 0,
      actionId: m["actionId"] as String?,
      input: m["input"] as String?,
      payload: payload,
    );
  }

  /// Tap, button, reply or dismissed.
  final UNotificationEventType type;

  /// Notification id.
  final int id;

  /// The button pressed ([UNotificationAction.id]); null for a plain tap.
  final String? actionId;

  /// Text typed into a reply field.
  final String? input;

  /// Your payload from the request.
  final Map<String, Object?>? payload;

  @override
  String toString() => "UNotificationEvent(${type.name} #$id${actionId == null ? "" : " $actionId"}${input == null ? "" : " \"$input\""})";
}

/// Notification permission and what is allowed (alert, sound, badge…).
@immutable
class UNotificationPermission {
  const UNotificationPermission({required this.status, this.alert, this.sound, this.badge, this.critical, this.timeSensitive, this.exactAlarms, this.fullScreen});

  /// Reads it from the native map.
  factory UNotificationPermission.fromMap(Map<Object?, Object?> m) => UNotificationPermission(
    status: UNotificationPermissionStatus.values.firstWhere((UNotificationPermissionStatus s) => s.name == m["status"], orElse: () => UNotificationPermissionStatus.notDetermined),
    alert: m["alert"] as bool?,
    sound: m["sound"] as bool?,
    badge: m["badge"] as bool?,
    critical: m["critical"] as bool?,
    timeSensitive: m["timeSensitive"] as bool?,
    exactAlarms: m["exactAlarms"] as bool?,
    fullScreen: m["fullScreen"] as bool?,
  );

  /// Permission state.
  final UNotificationPermissionStatus status;

  /// Banners allowed.
  final bool? alert;

  /// Sounds allowed.
  final bool? sound;

  /// Badges allowed.
  final bool? badge;

  /// Critical alerts allowed (Apple).
  final bool? critical;

  /// Time-sensitive allowed (Apple).
  final bool? timeSensitive;

  /// Android 12+: exact scheduling allowed (otherwise schedules may be a few minutes late).
  final bool? exactAlarms;

  /// Android 14+: full-screen alerts allowed.
  final bool? fullScreen;

  /// True when notifications can be shown.
  bool get isGranted => status == UNotificationPermissionStatus.granted || status == UNotificationPermissionStatus.provisional || status == UNotificationPermissionStatus.ephemeral;

  @override
  String toString() => "UNotificationPermission(${status.name})";
}

/// A scheduled notification that has not fired yet, or one currently shown.
@immutable
class UNotificationInfo {
  const UNotificationInfo({required this.id, this.title, this.body, this.group, this.next, this.payload});

  /// Reads it from the native map.
  factory UNotificationInfo.fromMap(Map<Object?, Object?> m) {
    final Object? raw = m["payload"];
    Map<String, Object?>? payload;
    if (raw is String && raw.isNotEmpty) {
      try {
        payload = (jsonDecode(raw) as Map<Object?, Object?>).map((Object? k, Object? v) => MapEntry<String, Object?>("$k", v));
      } catch (_) {}
    }
    return UNotificationInfo(
      id: (m["id"] as num?)?.toInt() ?? int.tryParse("${m["id"]}") ?? 0,
      title: m["title"] as String?,
      body: m["body"] as String?,
      group: m["group"] as String?,
      next: m["next"] == null ? null : DateTime.fromMillisecondsSinceEpoch((m["next"]! as num).toInt()),
      payload: payload,
    );
  }

  /// Notification id.
  final int id;

  /// Title.
  final String? title;

  /// Text.
  final String? body;

  /// Group key.
  final String? group;

  /// When a scheduled notification fires next.
  final DateTime? next;

  /// Payload.
  final Map<String, Object?>? payload;

  @override
  String toString() => "UNotificationInfo(#$id $title${next == null ? "" : " @ $next"})";
}
