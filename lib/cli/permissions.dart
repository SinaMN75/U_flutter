import "package:u/cli/core.dart";
import "package:u/cli/platforms.dart";
import "package:u/cli/plist.dart";

/// An Android `<uses-permission>`; bare names get the `android.permission.` prefix.
class AndroidPermission {
  const AndroidPermission(this.name, {this.maxSdk});

  final String name;
  final int? maxSdk;

  String get fullName => name.contains(".") ? name : "android.permission.$name";
}

/// One friendly permission and everything it means on each platform.
class UPermission {
  const UPermission(
    this.name,
    this.summary, {
    this.aliases = const <String>[],
    this.android = const <AndroidPermission>[],
    this.androidFeatures = const <String>[],
    this.ios = const <String, String>{},
    this.iosBackgroundModes = const <String>[],
    this.iosFlags = const <String>[],
    this.macos = const <String, String>{},
    this.macEntitlements = const <String>[],
    this.requires = const <String>[],
    this.note,
  });

  final String name;
  final String summary;
  final List<String> aliases;
  final List<AndroidPermission> android;

  /// `<uses-feature android:required="false">` entries, so the Play Store doesn't filter devices out.
  final List<String> androidFeatures;

  /// iOS Info.plist usage-description keys and their default text.
  final Map<String, String> ios;
  final List<String> iosBackgroundModes;

  /// iOS Info.plist booleans set to true.
  final List<String> iosFlags;

  /// macOS Info.plist usage-description keys and their default text.
  final Map<String, String> macos;

  /// macOS sandbox entitlements (set to true in both DebugProfile and Release).
  final List<String> macEntitlements;

  /// Other permissions added alongside this one (not removed with it).
  final List<String> requires;
  final String? note;

  bool on(Target t) => switch (t) {
    Target.android => android.isNotEmpty || androidFeatures.isNotEmpty,
    Target.ios => ios.isNotEmpty || iosBackgroundModes.isNotEmpty || iosFlags.isNotEmpty,
    Target.macos => macos.isNotEmpty || macEntitlements.isNotEmpty,
    _ => false,
  };
}

const List<UPermission> uPermissions = <UPermission>[
  UPermission(
    "internet",
    "Network access (Android release builds and sandboxed macOS need this)",
    aliases: <String>["network"],
    android: <AndroidPermission>[AndroidPermission("INTERNET")],
    macEntitlements: <String>["com.apple.security.network.client"],
  ),
  UPermission(
    "network-state",
    "Check whether the device is online / on Wi-Fi",
    aliases: <String>["connectivity", "wifi-state"],
    android: <AndroidPermission>[AndroidPermission("ACCESS_NETWORK_STATE"), AndroidPermission("ACCESS_WIFI_STATE")],
  ),
  UPermission(
    "camera",
    "Take photos and record video",
    android: <AndroidPermission>[AndroidPermission("CAMERA")],
    androidFeatures: <String>["android.hardware.camera"],
    ios: <String, String>{"NSCameraUsageDescription": "This app uses the camera to take photos and record video."},
    macos: <String, String>{"NSCameraUsageDescription": "This app uses the camera to take photos and record video."},
    macEntitlements: <String>["com.apple.security.device.camera"],
  ),
  UPermission(
    "microphone",
    "Record audio",
    aliases: <String>["mic", "audio", "record-audio"],
    android: <AndroidPermission>[AndroidPermission("RECORD_AUDIO")],
    ios: <String, String>{"NSMicrophoneUsageDescription": "This app uses the microphone to record audio."},
    macos: <String, String>{"NSMicrophoneUsageDescription": "This app uses the microphone to record audio."},
    macEntitlements: <String>["com.apple.security.device.audio-input"],
  ),
  UPermission(
    "speech",
    "Speech recognition (also adds microphone)",
    aliases: <String>["speech-recognition"],
    requires: <String>["microphone"],
    ios: <String, String>{"NSSpeechRecognitionUsageDescription": "This app uses speech recognition to turn your voice into text."},
    macos: <String, String>{"NSSpeechRecognitionUsageDescription": "This app uses speech recognition to turn your voice into text."},
  ),
  UPermission(
    "location",
    "Location while the app is open",
    aliases: <String>["gps"],
    android: <AndroidPermission>[AndroidPermission("ACCESS_FINE_LOCATION"), AndroidPermission("ACCESS_COARSE_LOCATION")],
    ios: <String, String>{"NSLocationWhenInUseUsageDescription": "This app uses your location to show places near you."},
    macos: <String, String>{
      "NSLocationUsageDescription": "This app uses your location to show places near you.",
      "NSLocationWhenInUseUsageDescription": "This app uses your location to show places near you.",
    },
    macEntitlements: <String>["com.apple.security.personal-information.location"],
  ),
  UPermission(
    "location-always",
    "Location in the background (also adds location)",
    aliases: <String>["background-location"],
    requires: <String>["location"],
    android: <AndroidPermission>[AndroidPermission("ACCESS_BACKGROUND_LOCATION")],
    ios: <String, String>{"NSLocationAlwaysAndWhenInUseUsageDescription": "This app uses your location in the background to keep tracking your route."},
    iosBackgroundModes: <String>["location"],
    macos: <String, String>{"NSLocationAlwaysAndWhenInUseUsageDescription": "This app uses your location in the background to keep tracking your route."},
    note: "Google Play and the App Store both review background location. Only use it if the feature really needs it.",
  ),
  UPermission(
    "photos",
    "Read the photo / video library",
    aliases: <String>["gallery", "media"],
    android: <AndroidPermission>[
      AndroidPermission("READ_MEDIA_IMAGES"),
      AndroidPermission("READ_MEDIA_VIDEO"),
      AndroidPermission("READ_MEDIA_VISUAL_USER_SELECTED"),
      AndroidPermission("READ_EXTERNAL_STORAGE", maxSdk: 32),
    ],
    ios: <String, String>{"NSPhotoLibraryUsageDescription": "This app needs access to your photos so you can pick images and videos."},
    macos: <String, String>{"NSPhotoLibraryUsageDescription": "This app needs access to your photos so you can pick images and videos."},
    macEntitlements: <String>["com.apple.security.personal-information.photos-library"],
    note: "Google Play only allows READ_MEDIA_IMAGES/VIDEO when photo access is a core feature. Picking a single image with the system picker (file_picker / image_picker) needs no permission.",
  ),
  UPermission(
    "save-photos",
    "Save images / videos to the photo library",
    aliases: <String>["photos-add"],
    android: <AndroidPermission>[AndroidPermission("WRITE_EXTERNAL_STORAGE", maxSdk: 28)],
    ios: <String, String>{"NSPhotoLibraryAddUsageDescription": "This app saves photos and videos to your library."},
    macos: <String, String>{"NSPhotoLibraryAddUsageDescription": "This app saves photos and videos to your library."},
    macEntitlements: <String>["com.apple.security.personal-information.photos-library"],
  ),
  UPermission(
    "music",
    "Read audio files / the music library",
    aliases: <String>["audio-files", "media-audio"],
    android: <AndroidPermission>[AndroidPermission("READ_MEDIA_AUDIO"), AndroidPermission("READ_EXTERNAL_STORAGE", maxSdk: 32)],
    ios: <String, String>{"NSAppleMusicUsageDescription": "This app needs access to your music library to play your songs."},
    macos: <String, String>{"NSAppleMusicUsageDescription": "This app needs access to your music library to play your songs."},
    macEntitlements: <String>["com.apple.security.assets.music.read-only"],
  ),
  UPermission(
    "storage",
    "Read/write files (old Android storage, iOS Files app sharing, macOS user-selected files & Downloads)",
    aliases: <String>["files"],
    android: <AndroidPermission>[AndroidPermission("READ_EXTERNAL_STORAGE", maxSdk: 32), AndroidPermission("WRITE_EXTERNAL_STORAGE", maxSdk: 29)],
    iosFlags: <String>["UIFileSharingEnabled", "LSSupportsOpeningDocumentsInPlace"],
    macEntitlements: <String>["com.apple.security.files.user-selected.read-write", "com.apple.security.files.downloads.read-write"],
  ),
  UPermission(
    "contacts",
    "Read / write contacts",
    android: <AndroidPermission>[AndroidPermission("READ_CONTACTS"), AndroidPermission("WRITE_CONTACTS")],
    ios: <String, String>{"NSContactsUsageDescription": "This app uses your contacts so you can invite and find friends."},
    macos: <String, String>{"NSContactsUsageDescription": "This app uses your contacts so you can invite and find friends."},
    macEntitlements: <String>["com.apple.security.personal-information.addressbook"],
  ),
  UPermission(
    "calendar",
    "Read / write calendar events",
    aliases: <String>["calendars"],
    android: <AndroidPermission>[AndroidPermission("READ_CALENDAR"), AndroidPermission("WRITE_CALENDAR")],
    ios: <String, String>{
      "NSCalendarsUsageDescription": "This app adds events to your calendar.",
      "NSCalendarsFullAccessUsageDescription": "This app adds events to your calendar.",
    },
    macos: <String, String>{
      "NSCalendarsUsageDescription": "This app adds events to your calendar.",
      "NSCalendarsFullAccessUsageDescription": "This app adds events to your calendar.",
    },
    macEntitlements: <String>["com.apple.security.personal-information.calendars"],
  ),
  UPermission(
    "reminders",
    "Read / write Apple Reminders",
    ios: <String, String>{
      "NSRemindersUsageDescription": "This app adds items to your reminders.",
      "NSRemindersFullAccessUsageDescription": "This app adds items to your reminders.",
    },
    macos: <String, String>{
      "NSRemindersUsageDescription": "This app adds items to your reminders.",
      "NSRemindersFullAccessUsageDescription": "This app adds items to your reminders.",
    },
    macEntitlements: <String>["com.apple.security.personal-information.calendars"],
  ),
  UPermission(
    "bluetooth",
    "Scan for and connect to Bluetooth / BLE devices",
    aliases: <String>["ble"],
    android: <AndroidPermission>[
      AndroidPermission("BLUETOOTH", maxSdk: 30),
      AndroidPermission("BLUETOOTH_ADMIN", maxSdk: 30),
      AndroidPermission("BLUETOOTH_SCAN"),
      AndroidPermission("BLUETOOTH_CONNECT"),
      AndroidPermission("BLUETOOTH_ADVERTISE"),
    ],
    androidFeatures: <String>["android.hardware.bluetooth_le"],
    ios: <String, String>{"NSBluetoothAlwaysUsageDescription": "This app uses Bluetooth to connect to nearby devices."},
    macos: <String, String>{"NSBluetoothAlwaysUsageDescription": "This app uses Bluetooth to connect to nearby devices."},
    macEntitlements: <String>["com.apple.security.device.bluetooth"],
  ),
  UPermission(
    "notifications",
    "Show notifications (Android 13+ asks at runtime; iOS/macOS need no declaration)",
    aliases: <String>["notification", "push"],
    android: <AndroidPermission>[AndroidPermission("POST_NOTIFICATIONS")],
  ),
  UPermission(
    "alarm",
    "Exact scheduled notifications / alarms that survive reboot",
    aliases: <String>["exact-alarm", "schedule"],
    android: <AndroidPermission>[AndroidPermission("SCHEDULE_EXACT_ALARM"), AndroidPermission("RECEIVE_BOOT_COMPLETED")],
  ),
  UPermission("vibrate", "Vibrate the device", aliases: <String>["vibration", "haptics"], android: <AndroidPermission>[AndroidPermission("VIBRATE")]),
  UPermission(
    "biometric",
    "Fingerprint / Face ID authentication",
    aliases: <String>["face-id", "fingerprint", "biometrics"],
    android: <AndroidPermission>[AndroidPermission("USE_BIOMETRIC")],
    ios: <String, String>{"NSFaceIDUsageDescription": "This app uses Face ID to sign you in securely."},
  ),
  UPermission(
    "motion",
    "Motion & fitness / activity recognition",
    aliases: <String>["activity", "sensors"],
    android: <AndroidPermission>[AndroidPermission("ACTIVITY_RECOGNITION")],
    ios: <String, String>{"NSMotionUsageDescription": "This app uses motion data to count your steps and activity."},
  ),
  UPermission(
    "nfc",
    "Read NFC tags",
    android: <AndroidPermission>[AndroidPermission("NFC")],
    androidFeatures: <String>["android.hardware.nfc"],
    ios: <String, String>{"NFCReaderUsageDescription": "This app reads NFC tags."},
    note: "On iOS also enable the \"Near Field Communication Tag Reading\" capability in Xcode.",
  ),
  UPermission(
    "phone",
    "Place calls / read phone state",
    aliases: <String>["call"],
    android: <AndroidPermission>[AndroidPermission("CALL_PHONE"), AndroidPermission("READ_PHONE_STATE")],
    androidFeatures: <String>["android.hardware.telephony"],
  ),
  UPermission(
    "sms",
    "Send / read SMS",
    android: <AndroidPermission>[AndroidPermission("SEND_SMS"), AndroidPermission("RECEIVE_SMS"), AndroidPermission("READ_SMS")],
    androidFeatures: <String>["android.hardware.telephony"],
    note: "Google Play only allows SMS permissions for default SMS apps and a few approved use cases.",
  ),
  UPermission("wake-lock", "Keep the CPU / screen awake", aliases: <String>["wakelock", "keep-awake"], android: <AndroidPermission>[AndroidPermission("WAKE_LOCK")]),
  UPermission(
    "foreground-service",
    "Run a foreground service (long uploads/downloads, sync)",
    android: <AndroidPermission>[AndroidPermission("FOREGROUND_SERVICE"), AndroidPermission("FOREGROUND_SERVICE_DATA_SYNC")],
    note: "Android 14+ also needs android:foregroundServiceType on the <service>. DATA_SYNC is added by default.",
  ),
  UPermission(
    "background-audio",
    "Keep playing audio in the background",
    aliases: <String>["audio-background"],
    requires: <String>["wake-lock"],
    android: <AndroidPermission>[AndroidPermission("FOREGROUND_SERVICE"), AndroidPermission("FOREGROUND_SERVICE_MEDIA_PLAYBACK")],
    iosBackgroundModes: <String>["audio"],
  ),
  UPermission(
    "background-fetch",
    "Periodic background work / processing",
    aliases: <String>["background"],
    android: <AndroidPermission>[AndroidPermission("RECEIVE_BOOT_COMPLETED")],
    iosBackgroundModes: <String>["fetch", "processing"],
  ),
  UPermission(
    "remote-notifications",
    "Wake the app for silent push (background push delivery)",
    aliases: <String>["background-push"],
    iosBackgroundModes: <String>["remote-notification"],
    note: "You still need the Push Notifications capability (aps-environment) in Xcode.",
  ),
  UPermission(
    "local-network",
    "Talk to devices on the local network (also adds internet)",
    aliases: <String>["lan"],
    requires: <String>["internet"],
    android: <AndroidPermission>[AndroidPermission("ACCESS_WIFI_STATE"), AndroidPermission("CHANGE_WIFI_MULTICAST_STATE")],
    ios: <String, String>{"NSLocalNetworkUsageDescription": "This app finds and connects to devices on your local network."},
    macEntitlements: <String>["com.apple.security.network.server"],
  ),
  UPermission(
    "tracking",
    "Advertising ID / App Tracking Transparency",
    aliases: <String>["ads", "idfa", "ad-id"],
    android: <AndroidPermission>[AndroidPermission("com.google.android.gms.permission.AD_ID")],
    ios: <String, String>{"NSUserTrackingUsageDescription": "Your data is used to show you more relevant ads."},
  ),
  UPermission(
    "install-apk",
    "Install APK updates from inside the app",
    aliases: <String>["install-packages", "self-update"],
    android: <AndroidPermission>[AndroidPermission("REQUEST_INSTALL_PACKAGES")],
    note: "Google Play only allows this for app stores, file managers and similar apps. Fine for apps distributed outside Play.",
  ),
  UPermission("overlay", "Draw over other apps", aliases: <String>["system-alert-window"], android: <AndroidPermission>[AndroidPermission("SYSTEM_ALERT_WINDOW")]),
];

UPermission findPermission(String name) {
  final String n = name.toLowerCase().trim().replaceAll("_", "-");
  for (final UPermission p in uPermissions) {
    if (p.name == n || p.aliases.contains(n)) {
      return p;
    }
  }
  throw CliException("Unknown permission \"$name\". Run `dart run u:app permission list` to see them all.");
}

/// Permission names from positionals like `camera,internet location`.
List<UPermission> parsePermissions(Iterable<String> args) {
  final List<UPermission> out = <UPermission>[];
  for (final String a in args) {
    for (final String part in a.split(",")) {
      if (part.trim().isEmpty) {
        continue;
      }
      final UPermission p = findPermission(part);
      if (!out.contains(p)) {
        out.add(p);
      }
    }
  }
  if (out.isEmpty) {
    throw CliException("Name at least one permission, e.g. `dart run u:app permission add camera internet`.");
  }
  return out;
}

/// [perms] plus everything they require, dependencies first.
List<UPermission> withRequirements(List<UPermission> perms) {
  final List<UPermission> out = <UPermission>[];
  void visit(UPermission p) {
    for (final String r in p.requires) {
      visit(findPermission(r));
    }
    if (!out.contains(p)) {
      out.add(p);
    }
  }

  perms.forEach(visit);
  return out;
}

// ---------------------------------------------------------------------------------------------
// AndroidManifest.xml

RegExp _usesPermission(String fullName) => RegExp('<uses-permission(?:-sdk-23)?\\s[^>]*android:name="${RegExp.escape(fullName)}"[^>]*?(?:/>|>\\s*</uses-permission(?:-sdk-23)?>)');

RegExp _usesFeature(String name) => RegExp('<uses-feature\\s[^>]*android:name="${RegExp.escape(name)}"[^>]*?(?:/>|>\\s*</uses-feature>)');

bool androidHas(String manifest, UPermission p) =>
    p.android.every((AndroidPermission a) => _usesPermission(a.fullName).hasMatch(manifest)) && p.androidFeatures.every((String f) => _usesFeature(f).hasMatch(manifest));

/// Inserts [line] after the last match of [after] or else before `<application`.
String _insertManifestLine(String text, String line, List<RegExp> after) {
  for (final RegExp re in after) {
    final Match? last = re.allMatches(text).lastOrNull;
    if (last != null) {
      final int at = lineEnd(text, last.end);
      return text.replaceRange(at, at, "${indentAt(text, last.start)}$line\n");
    }
  }
  final (int, int)? app = Xml.openTag(text, "application");
  if (app == null) {
    throw EditSkip("<application> not found");
  }
  final int at = lineStart(text, app.$1);
  return text.replaceRange(at, at, "${indentAt(text, app.$1)}$line\n");
}

String androidAdd(String text, UPermission p) {
  String out = text;
  final RegExp anyPermission = RegExp("<uses-permission[^>]*>");
  final RegExp anyFeature = RegExp("<uses-feature[^>]*>");
  for (final AndroidPermission a in p.android) {
    if (_usesPermission(a.fullName).hasMatch(out)) {
      continue;
    }
    final String max = a.maxSdk == null ? "" : " android:maxSdkVersion=\"${a.maxSdk}\"";
    out = _insertManifestLine(out, "<uses-permission android:name=\"${a.fullName}\"$max />", <RegExp>[anyPermission]);
  }
  for (final String f in p.androidFeatures) {
    if (_usesFeature(f).hasMatch(out)) {
      continue;
    }
    out = _insertManifestLine(out, "<uses-feature android:name=\"$f\" android:required=\"false\" />", <RegExp>[anyFeature, anyPermission]);
  }
  return out;
}

String androidRemove(String text, UPermission p, bool Function(Object item) keep) {
  String out = text;
  for (final AndroidPermission a in p.android) {
    if (keep(a.fullName)) {
      continue;
    }
    Match? m;
    while ((m = _usesPermission(a.fullName).firstMatch(out)) != null) {
      out = Xml.removeLine(out, m!);
    }
  }
  for (final String f in p.androidFeatures) {
    if (keep(f)) {
      continue;
    }
    Match? m;
    while ((m = _usesFeature(f).firstMatch(out)) != null) {
      out = Xml.removeLine(out, m!);
    }
  }
  return out;
}

// ---------------------------------------------------------------------------------------------
// Apple

bool iosHas(Plist info, UPermission p) =>
    p.ios.keys.every(info.has) &&
    p.iosFlags.every((String k) => info.getBool(k) ?? false) &&
    p.iosBackgroundModes.every((String m) => (info.getStringArray("UIBackgroundModes") ?? <String>[]).contains(m));

bool macosHas(Plist info, List<Plist> entitlements, UPermission p) =>
    p.macos.keys.every(info.has) && p.macEntitlements.every((String e) => entitlements.every((Plist pl) => pl.getBool(e) ?? false));

void iosAdd(Plist info, UPermission p, String? message) {
  p.ios.forEach((String key, String text) {
    if (message != null || !info.has(key)) {
      info.setString(key, message ?? text);
    }
  });
  for (final String k in p.iosFlags) {
    info.setBool(k, value: true);
  }
  for (final String m in p.iosBackgroundModes) {
    info.addToArray("UIBackgroundModes", m);
  }
}

void iosRemove(Plist info, UPermission p, bool Function(Object item) keep) {
  for (final String k in <String>[...p.ios.keys, ...p.iosFlags]) {
    if (!keep(k)) {
      info.remove(k);
    }
  }
  for (final String m in p.iosBackgroundModes) {
    if (!keep("bg:$m")) {
      info.removeFromArray("UIBackgroundModes", m);
    }
  }
}

void macosAddInfo(Plist info, UPermission p, String? message) => p.macos.forEach((String key, String text) {
  if (message != null || !info.has(key)) {
    info.setString(key, message ?? text);
  }
});

/// Names of catalog permissions fully declared on [t], for `info` and `permission list`.
List<String> declaredPermissions(Project p, Target t) {
  switch (t) {
    case Target.android:
      final String? m = p.read(AndroidFiles.manifest);
      return m == null ? <String>[] : uPermissions.where((UPermission x) => x.on(t) && androidHas(m, x)).map((UPermission x) => x.name).toList();
    case Target.ios:
      final Plist? info = readPlist(p, const AppleFiles(Target.ios).infoPlist);
      return info == null ? <String>[] : uPermissions.where((UPermission x) => x.on(t) && iosHas(info, x)).map((UPermission x) => x.name).toList();
    case Target.macos:
      final Plist? info = readPlist(p, const AppleFiles(Target.macos).infoPlist);
      final List<Plist> ents = AppleFiles.entitlements.map((String e) => readPlist(p, e)).whereType<Plist>().toList();
      return info == null ? <String>[] : uPermissions.where((UPermission x) => x.on(t) && macosHas(info, ents, x)).map((UPermission x) => x.name).toList();
    case Target.linux:
    case Target.windows:
    case Target.web:
      return <String>[];
  }
}
