import "dart:async";
import "dart:math" as math;

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:u/src/location/u_location_types.dart";
import "package:u/src/location/u_location_web_stub.dart" if (dart.library.js_interop) "package:u/src/location/u_location_web.dart";

export "package:u/src/location/u_location_types.dart";

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

/// Engine behind ULocation; use ULocation instead.
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

  // The native side has one sink per channel: a second listener would silently steal the stream and
  // cancelling either would stop both. Every listener shares one native subscription instead.
  static final Map<int, _PositionWatcher> _positionWatchers = <int, _PositionWatcher>{};
  static final Map<int, MultiStreamController<UHeading>> _headingWatchers = <int, MultiStreamController<UHeading>>{};
  static int _nextWatcher = 0;
  static StreamSubscription<dynamic>? _positionsNative;
  static ULocationSettings? _positionsSettings;
  static StreamSubscription<dynamic>? _headingNative;

  /// Live positions. One native stream at a time; later listeners share it (with the finest settings any of them asked for).
  static Stream<UPosition> positions([ULocationSettings settings = const ULocationSettings()]) {
    if (kIsWeb) return ULocationWeb.positions(settings);
    return Stream<UPosition>.multi((MultiStreamController<UPosition> controller) {
      final int id = _nextWatcher++;
      _positionWatchers[id] = _PositionWatcher(settings, controller);
      controller.onCancel = () {
        _positionWatchers.remove(id);
        _syncPositions();
      };
      _syncPositions();
    });
  }

  static void _syncPositions() {
    if (_positionWatchers.isEmpty) {
      unawaited(_positionsNative?.cancel());
      _positionsNative = null;
      _positionsSettings = null;
      return;
    }
    final ULocationSettings merged = _mergeSettings(_positionWatchers.values.map((_PositionWatcher w) => w.settings).toList());
    final ULocationSettings? active = _positionsSettings;
    if (_positionsNative != null && active != null && mapEquals(active.toMap(), merged.toMap())) return;
    // Cancel first: the native "cancel" is not tied to a listener, so sent later it would stop the new one.
    unawaited(_positionsNative?.cancel());
    _positionsSettings = merged;
    _positionsNative = _updates.receiveBroadcastStream(merged.toMap()).listen(
      (dynamic e) {
        final UPosition position = UPosition.fromMap(e as Map<Object?, Object?>);
        for (final _PositionWatcher watcher in _positionWatchers.values.toList()) {
          watcher.offer(position);
        }
      },
      onError: (Object e) {
        final Object error = _mapStreamError(e);
        for (final _PositionWatcher watcher in _positionWatchers.values.toList()) {
          watcher.controller.addError(error);
        }
      },
    );
  }

  static ULocationSettings _mergeSettings(List<ULocationSettings> all) {
    if (all.length == 1) return all.first;
    final ULocationSettings? background = all.where((ULocationSettings s) => s.background).firstOrNull;
    final ULocationSettings lead = background ?? all.first;
    return ULocationSettings(
      accuracy: all.map((ULocationSettings s) => s.accuracy).reduce((ULocationAccuracy a, ULocationAccuracy b) => a.index >= b.index ? a : b),
      distanceFilter: all.map((ULocationSettings s) => s.distanceFilter).reduce(math.min),
      interval: all.map((ULocationSettings s) => s.interval).reduce((Duration a, Duration b) => a <= b ? a : b),
      background: background != null,
      significantChangesOnly: all.every((ULocationSettings s) => s.significantChangesOnly),
      activity: lead.activity,
      pauseAutomatically: all.every((ULocationSettings s) => s.pauseAutomatically),
      showBackgroundIndicator: lead.showBackgroundIndicator,
      notificationTitle: lead.notificationTitle,
      notificationText: lead.notificationText,
    );
  }

  /// Compass updates; every listener shares one native stream.
  static Stream<UHeading> heading() {
    if (kIsWeb) return ULocationWeb.heading();
    return Stream<UHeading>.multi((MultiStreamController<UHeading> controller) {
      final int id = _nextWatcher++;
      _headingWatchers[id] = controller;
      controller.onCancel = () {
        _headingWatchers.remove(id);
        if (_headingWatchers.isEmpty) {
          unawaited(_headingNative?.cancel());
          _headingNative = null;
        }
      };
      _headingNative ??= _heading.receiveBroadcastStream().listen(
        (dynamic e) {
          final UHeading heading = UHeading.fromMap(e as Map<Object?, Object?>);
          for (final MultiStreamController<UHeading> watcher in _headingWatchers.values.toList()) {
            watcher.add(heading);
          }
        },
        onError: (Object e) {
          final Object error = _mapStreamError(e);
          for (final MultiStreamController<UHeading> watcher in _headingWatchers.values.toList()) {
            watcher.addError(error);
          }
        },
      );
    });
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

class _PositionWatcher {
  _PositionWatcher(this.settings, this.controller);

  final ULocationSettings settings;
  final MultiStreamController<UPosition> controller;
  UPosition? _last;

  // The shared stream may run with a finer distance filter than this listener asked for.
  void offer(UPosition position) {
    final UPosition? last = _last;
    if (last != null && settings.distanceFilter > 0 && _meters(last, position) < settings.distanceFilter) return;
    _last = position;
    controller.add(position);
  }

  static double _meters(UPosition a, UPosition b) {
    const double radius = 6371000;
    final double dLat = (b.latitude - a.latitude) * math.pi / 180;
    final double dLon = (b.longitude - a.longitude) * math.pi / 180;
    final double h = math.pow(math.sin(dLat / 2), 2) + math.cos(a.latitude * math.pi / 180) * math.cos(b.latitude * math.pi / 180) * math.pow(math.sin(dLon / 2), 2);
    return 2 * radius * math.asin(math.min(1, math.sqrt(h)));
  }
}
