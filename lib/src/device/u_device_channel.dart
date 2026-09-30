import "package:flutter/foundation.dart";
import "package:flutter/services.dart";

// =============================================================================
// u_device_channel — the native half of UDevice, UPackage and UConnectivity.
//
// One method channel ("u/device") and one event channel ("u/device/network").
// Startup costs a single round trip: [bootstrap] returns the device, package and
// network snapshots together and every module reads its part from that one map.
//
// Every call degrades gracefully: a platform that does not implement a method
// yields null, never a crash, and the Dart side falls back to what it can derive.
// On the web nothing here is called; the modules talk to UWebBridge instead.
// =============================================================================

abstract final class UDeviceChannel {
  static const MethodChannel _channel = MethodChannel("u/device");
  static const EventChannel _network = EventChannel("u/device/network");

  static Future<Map<String, Object?>>? _bootstrap;

  /// Device, package and network snapshots from one native call. Memoized: every module
  /// awaits the same future, so calling it from several `init()`s costs one round trip.
  static Future<Map<String, Object?>> bootstrap() => _bootstrap ??= _map("bootstrap").then((Map<String, Object?>? m) => m ?? <String, Object?>{});

  static Future<Map<String, Object?>?> status() => _map("status");

  static Future<Map<String, Object?>?> integrity() => _map("integrity");

  static Future<Map<String, Object?>?> network() => _map("network");

  /// Keeps the display awake while [on]; false when the platform could not do it.
  static Future<bool> keepScreenOn(bool on) async => await _call<bool>("keepScreenOn", <String, Object?>{"on": on}) ?? false;

  /// Network snapshots pushed by the OS whenever the default route or its capabilities change.
  static Stream<Map<String, Object?>> networkEvents() => _network.receiveBroadcastStream().map((dynamic event) => asStringMap(event) ?? <String, Object?>{});

  static Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint("u/device.$method failed: ${e.code}${e.message == null ? "" : " — ${e.message}"}");
      return null;
    }
  }

  static Future<Map<String, Object?>?> _map(String method) async => asStringMap(await _call<Object?>(method));
}

/// Converts the `Map<Object?, Object?>` a platform channel delivers into a string-keyed map.
Map<String, Object?>? asStringMap(Object? value) {
  if (value is! Map) return null;
  return value.map((Object? k, Object? v) => MapEntry<String, Object?>("$k", v));
}

/// Typed readers for loosely typed channel maps; a wrong or missing type reads as null.
extension UChannelMap on Map<String, Object?> {
  String? str(String key) {
    final Object? v = this[key];
    if (v == null) return null;
    final String s = "$v".trim();
    return s.isEmpty ? null : s;
  }

  int? integer(String key) {
    final Object? v = this[key];
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  double? decimal(String key) {
    final Object? v = this[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  bool? flag(String key) {
    final Object? v = this[key];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == "true" || v == "1";
    return null;
  }

  DateTime? time(String key) {
    final int? ms = integer(key);
    return ms == null || ms <= 0 ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  List<String> strings(String key) {
    final Object? v = this[key];
    return v is List ? v.where((Object? e) => e != null).map((Object? e) => "$e").toList(growable: false) : const <String>[];
  }

  Map<String, Object?> child(String key) => asStringMap(this[key]) ?? <String, Object?>{};
}
