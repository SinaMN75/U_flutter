import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:u/plugins/location/u_location_types.dart";
import "package:u/plugins/location/u_location_web_stub.dart" if (dart.library.js_interop) "package:u/plugins/location/u_location_web.dart";

export "package:u/plugins/location/u_location_types.dart";

// =============================================================================
// u_location_channel — positions, permissions, geofences, compass and geocoding
// ("u/location" + "u/location/updates|heading|geofence|visits").
//
//   Android  LocationManager (fused provider on 12+, no Google Play Services), proximity
//            alerts for geofences, rotation-vector compass, platform Geocoder
//   iOS      CoreLocation: precise/approximate, background updates, significant changes,
//            visits, region monitoring, heading, CLGeocoder
//   macOS    CoreLocation (no heading / visits), CLGeocoder
//   Windows  Windows.Devices.Geolocation (+ geofence monitor, compass sensor)
//   Linux    GeoClue2 over D-Bus; geofences evaluated in Dart while running
//   Web      navigator.geolocation, Permissions API, device orientation; Dart geofences
//
// Failures come back as a [ULocationResult] / [ULocationException] with the exact reason.
// =============================================================================

abstract final class ULocationChannel {
  static const MethodChannel _channel = MethodChannel("u/location");
  static const EventChannel _updates = EventChannel("u/location/updates");
  static const EventChannel _heading = EventChannel("u/location/heading");
  static const EventChannel _geofence = EventChannel("u/location/geofence");
  static const EventChannel _visits = EventChannel("u/location/visits");

  static Future<T?> _call<T>(String method, [Map<String, Object?>? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint("u/location.$method failed: ${e.code} ${e.message ?? ""}");
      return null;
    }
  }

  static ULocationError _error(String? code) => ULocationError.values.firstWhere((ULocationError e) => e.name == code, orElse: () => ULocationError.unavailable);

  static Object _mapStreamError(Object error) => error is PlatformException ? ULocationException(_error(error.code), error.message) : error;

  // --- Permission --------------------------------------------------------------

  static Future<ULocationPermission> permission() async {
    if (kIsWeb) return ULocationWeb.permission();
    final Map<Object?, Object?>? raw = await _call<Map<Object?, Object?>>("permission");
    return raw == null ? const ULocationPermission(status: ULocationPermissionStatus.unsupported, serviceEnabled: false) : ULocationPermission.fromMap(raw);
  }

  /// Asks for location access; [always] asks for background access too (after foreground is granted).
  static Future<ULocationPermission> requestPermission({bool always = false}) async {
    if (kIsWeb) return ULocationWeb.requestPermission();
    final Map<Object?, Object?>? raw = await _call<Map<Object?, Object?>>("requestPermission", <String, Object?>{"always": always});
    return raw == null ? await permission() : ULocationPermission.fromMap(raw);
  }

  /// iOS 14+: asks to switch approximate location to precise for this session.
  static Future<bool> requestPrecise(String purposeKey) async => !kIsWeb && (await _call<bool>("requestPrecise", <String, Object?>{"purposeKey": purposeKey}) ?? false);

  static ULocationError? _blocking(ULocationPermission p) {
    if (!p.serviceEnabled) return ULocationError.serviceDisabled;
    return switch (p.status) {
      ULocationPermissionStatus.denied => ULocationError.permissionDenied,
      ULocationPermissionStatus.deniedForever => ULocationError.permissionDeniedForever,
      ULocationPermissionStatus.notDeclared => ULocationError.notDeclared,
      ULocationPermissionStatus.restricted => ULocationError.restricted,
      ULocationPermissionStatus.unsupported => ULocationError.unsupported,
      _ => null,
    };
  }

  /// Makes sure location can be read, asking once if needed. Null when ready, else why not.
  static Future<ULocationError?> ensureReady({bool always = false}) async {
    ULocationPermission p = await permission();
    if (p.status == ULocationPermissionStatus.notDetermined || (always && p.status == ULocationPermissionStatus.whileInUse)) p = await requestPermission(always: always);
    return _blocking(p);
  }

  // --- Positions ---------------------------------------------------------------

  static Future<ULocationResult> current({
    ULocationAccuracy accuracy = ULocationAccuracy.high,
    Duration timeout = const Duration(seconds: 20),
    Duration? maxAge,
    bool askPermission = true,
  }) async {
    final ULocationError? blocked = askPermission ? await ensureReady() : _blocking(await permission());
    if (blocked != null) return ULocationResult.failure(blocked);
    if (kIsWeb) return ULocationWeb.current(accuracy: accuracy, timeout: timeout, maxAge: maxAge);
    try {
      final Map<Object?, Object?>? raw = await _channel.invokeMethod<Map<Object?, Object?>>("current", <String, Object?>{
        "accuracy": accuracy.name,
        "timeoutMs": timeout.inMilliseconds,
        "maxAgeMs": maxAge?.inMilliseconds,
      });
      return raw == null ? const ULocationResult.failure(ULocationError.unavailable) : ULocationResult.success(UPosition.fromMap(raw));
    } on PlatformException catch (e) {
      return ULocationResult.failure(_error(e.code));
    } on MissingPluginException {
      return const ULocationResult.failure(ULocationError.unsupported);
    }
  }

  static Future<UPosition?> lastKnown() async {
    if (kIsWeb) return null;
    final Map<Object?, Object?>? raw = await _call<Map<Object?, Object?>>("lastKnown");
    return raw == null ? null : UPosition.fromMap(raw);
  }

  /// Live positions. One native stream at a time; later listeners share it.
  static Stream<UPosition> positions([ULocationSettings settings = const ULocationSettings()]) {
    if (kIsWeb) return ULocationWeb.positions(settings);
    return _updates.receiveBroadcastStream(settings.toMap()).map((dynamic e) => UPosition.fromMap(e as Map<Object?, Object?>)).handleError((Object e) => throw _mapStreamError(e));
  }

  static Stream<UHeading> heading() {
    if (kIsWeb) return ULocationWeb.heading();
    return _heading.receiveBroadcastStream().map((dynamic e) => UHeading.fromMap(e as Map<Object?, Object?>)).handleError((Object e) => throw _mapStreamError(e));
  }

  /// Places the user arrived at / left (iOS; empty elsewhere).
  static Stream<UVisit> visits() {
    if (kIsWeb) return const Stream<UVisit>.empty();
    return _visits.receiveBroadcastStream().map((dynamic e) => UVisit.fromMap(e as Map<Object?, Object?>)).handleError((Object e) => throw _mapStreamError(e));
  }

  // --- Geofences ---------------------------------------------------------------

  static final Map<String, UGeofence> _soft = <String, UGeofence>{};
  static final Map<String, bool> _inside = <String, bool>{};
  static final StreamController<UGeofenceEvent> _softEvents = StreamController<UGeofenceEvent>.broadcast();
  static StreamSubscription<UPosition>? _softWatch;

  /// Starts watching [fence]. Native on Android, iOS, macOS and Windows (works in the background);
  /// elsewhere evaluated in Dart while the app runs.
  static Future<bool> addGeofence(UGeofence fence) async {
    final bool? native = kIsWeb ? null : await _call<bool>("addGeofence", fence.toMap());
    if (native != null) return native;
    _soft[fence.id] = fence;
    _softWatch ??= positions(const ULocationSettings(accuracy: ULocationAccuracy.balanced, distanceFilter: 20)).listen(_evaluate, onError: (Object _) {});
    return true;
  }

  static void _evaluate(UPosition p) {
    for (final UGeofence f in _soft.values) {
      final bool inside = p.distanceTo(f.latitude, f.longitude) <= f.radius;
      final bool? was = _inside[f.id];
      _inside[f.id] = inside;
      if (was == null || was == inside) continue;
      if ((inside && f.onEnter) || (!inside && f.onExit)) {
        _softEvents.add(UGeofenceEvent(id: f.id, transition: inside ? UGeofenceTransition.enter : UGeofenceTransition.exit, time: p.time));
      }
    }
  }

  static Future<void> removeGeofence(String id) async {
    if (_soft.remove(id) != null) {
      _inside.remove(id);
      if (_soft.isEmpty) await _stopSoft();
      return;
    }
    await _call<void>("removeGeofence", <String, Object?>{"id": id});
  }

  static Future<void> clearGeofences() async {
    _soft.clear();
    _inside.clear();
    await _stopSoft();
    await _call<void>("clearGeofences");
  }

  static Future<void> _stopSoft() async {
    await _softWatch?.cancel();
    _softWatch = null;
  }

  static Future<List<UGeofence>> geofences() async {
    final List<Object?>? raw = kIsWeb ? null : await _call<List<Object?>>("geofences");
    return <UGeofence>[
      ...?raw?.whereType<Map<Object?, Object?>>().map(UGeofence.fromMap),
      ..._soft.values,
    ];
  }

  /// Enter / exit events, including ones that happened while the app was not running (delivered on listen).
  static Stream<UGeofenceEvent> geofenceEvents() {
    if (kIsWeb) return _softEvents.stream;
    final Stream<UGeofenceEvent> native = _geofence.receiveBroadcastStream().map((dynamic e) => UGeofenceEvent.fromMap(e as Map<Object?, Object?>)).handleError((Object _) {});
    final StreamController<UGeofenceEvent> merged = StreamController<UGeofenceEvent>.broadcast();
    StreamSubscription<UGeofenceEvent>? a;
    StreamSubscription<UGeofenceEvent>? b;
    merged
      ..onListen = () {
        a = native.listen(merged.add);
        b = _softEvents.stream.listen(merged.add);
      }
      ..onCancel = () async {
        await a?.cancel();
        await b?.cancel();
        await merged.close();
      };
    return merged.stream;
  }

  // --- Geocoding ----------------------------------------------------------------

  /// Addresses at a point (Android, iOS, macOS). Empty when unavailable.
  static Future<List<UPlacemark>> reverseGeocode(double latitude, double longitude, {String? locale}) async {
    if (kIsWeb) return const <UPlacemark>[];
    final List<Object?>? raw = await _call<List<Object?>>("reverseGeocode", <String, Object?>{"latitude": latitude, "longitude": longitude, "locale": locale});
    return (raw ?? <Object?>[]).whereType<Map<Object?, Object?>>().map(UPlacemark.fromMap).toList();
  }

  /// Places matching an address (Android, iOS, macOS). Empty when unavailable.
  static Future<List<UPlacemark>> geocode(String address, {String? locale}) async {
    if (kIsWeb) return const <UPlacemark>[];
    final List<Object?>? raw = await _call<List<Object?>>("geocode", <String, Object?>{"address": address, "locale": locale});
    return (raw ?? <Object?>[]).whereType<Map<Object?, Object?>>().map(UPlacemark.fromMap).toList();
  }

  static Future<bool> isGeocodingAvailable() async => !kIsWeb && (await _call<bool>("geocodingAvailable") ?? false);
}
