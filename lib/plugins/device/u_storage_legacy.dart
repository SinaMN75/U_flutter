import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:path_provider/path_provider.dart";
import "package:u/plugins/device/u_device_channel.dart";
import "package:u/utils/web/u_web_native.dart" if (dart.library.js_interop) "package:u/utils/web/u_web_browser.dart";

// =============================================================================
// u_storage_legacy — reads what shared_preferences saved, once, for migration.
//
//   Android      FlutterSharedPreferences.xml   (native: decodes list/double prefixes)
//   iOS / macOS  NSUserDefaults.standard          (native)
//   Windows      <app support>/shared_preferences.json
//   Linux        <app support>/shared_preferences.json
//   Web          window.localStorage, JSON-encoded values
//
// Every source keeps shared_preferences' "flutter." prefix; it is stripped here.
// =============================================================================

abstract final class UStorageLegacy {
  static const String _prefix = "flutter.";

  static Future<Map<String, Object?>> read() async {
    final Map<String, Object?> raw;
    if (kIsWeb) {
      raw = UWebBridge.legacyPrefs();
    } else if (Platform.isWindows || Platform.isLinux) {
      final File? file = await _desktopFile();
      raw = file == null || !file.existsSync() ? <String, Object?>{} : asStringMap(jsonDecode(await file.readAsString())) ?? <String, Object?>{};
    } else {
      raw = await UDeviceChannel.legacyPrefs() ?? <String, Object?>{};
    }
    return <String, Object?>{
      for (final MapEntry<String, Object?> e in raw.entries)
        if (e.key.startsWith(_prefix)) e.key.substring(_prefix.length): _normalize(e.value),
    };
  }

  static Future<void> clear() async {
    if (kIsWeb) {
      UWebBridge.clearLegacyPrefs();
    } else if (Platform.isWindows || Platform.isLinux) {
      final File? file = await _desktopFile();
      if (file != null && file.existsSync()) await file.delete();
    } else {
      await UDeviceChannel.clearLegacyPrefs();
    }
  }

  static Future<File?> _desktopFile() async {
    try {
      return File("${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}shared_preferences.json");
    } catch (_) {
      return null;
    }
  }

  // JSON and platform channels hand lists back untyped; shared_preferences only ever stored List<String>.
  static Object? _normalize(Object? value) => value is List ? value.map((Object? e) => "$e").toList() : value;
}
