import "dart:math" as math;

import "package:flutter/foundation.dart";

// Models shared by the location engine and its web implementation.

/// Accuracy wanted: lowest (~3 km), low (~1 km), medium (~100 m), high (~10 m), best, navigation.
enum ULocationAccuracy { lowest, low, balanced, high, best, navigation }

/// Location permission: granted, grantedWhenInUse, denied, permanentlyDenied, restricted, notDetermined, notDeclared (missing from Info.plist/manifest), unsupported.
enum ULocationPermissionStatus {
  /// Never asked yet.
  notDetermined,

  /// Denied, can ask again.
  denied,

  /// Denied and the OS will not ask again: send the user to settings.
  deniedForever,

  /// Allowed while the app is in use.
  whileInUse,

  /// Allowed in the background too.
  always,

  /// Blocked by parental controls / device policy.
  restricted,

  /// The app does not declare the permission (AndroidManifest / Info.plist): a developer bug.
  notDeclared,

  /// This platform has no location service.
  unsupported,
}

/// Why a position could not be read: permissionDenied, serviceDisabled, timeout, notDeclared, unsupported…
enum ULocationError { serviceDisabled, permissionDenied, permissionDeniedForever, notDeclared, restricted, timeout, unavailable, unsupported }

/// iOS activity hint: lets the OS pause updates smartly and save battery.
enum ULocationActivity { other, automotive, fitness, navigation, airborne }

/// Geofence event: enter, exit or dwell.
enum UGeofenceTransition { enter, exit }

/// Location permission, precise/approximate and whether GPS is on.
@immutable
class ULocationPermission {
  const ULocationPermission({required this.status, this.precise, this.serviceEnabled = true});

  /// Reads it from the native map.
  factory ULocationPermission.fromMap(Map<Object?, Object?> m) => ULocationPermission(
    status: ULocationPermissionStatus.values.firstWhere((ULocationPermissionStatus s) => s.name == m["status"], orElse: () => ULocationPermissionStatus.notDetermined),
    precise: m["precise"] as bool?,
    serviceEnabled: m["serviceEnabled"] as bool? ?? true,
  );

  /// Permission state.
  final ULocationPermissionStatus status;

  /// False when the user granted only approximate location (iOS 14+, Android 12+).
  final bool? precise;

  /// Location services (GPS switch) are on.
  final bool serviceEnabled;

  /// True when location may be used (in use or always).
  bool get isGranted => status == ULocationPermissionStatus.whileInUse || status == ULocationPermissionStatus.always;

  /// True when background ("always") access is granted.
  bool get isAlways => status == ULocationPermissionStatus.always;

  @override
  String toString() => "ULocationPermission(${status.name}${precise == false ? ", approximate" : ""}${serviceEnabled ? "" : ", service off"})";
}

/// A GPS fix: latitude, longitude, accuracy, altitude, speed, heading, time. `p.latitude`
@immutable
class UPosition {
  const UPosition({
    required this.latitude,
    required this.longitude,
    required this.time,
    this.accuracy,
    this.altitude,
    this.altitudeAccuracy,
    this.heading,
    this.headingAccuracy,
    this.speed,
    this.speedAccuracy,
    this.floor,
    this.isMocked = false,
    this.source,
  });

  /// Reads it from the native map.
  factory UPosition.fromMap(Map<Object?, Object?> m) => UPosition(
    latitude: (m["latitude"]! as num).toDouble(),
    longitude: (m["longitude"]! as num).toDouble(),
    time: DateTime.fromMillisecondsSinceEpoch((m["time"] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch),
    accuracy: (m["accuracy"] as num?)?.toDouble(),
    altitude: (m["altitude"] as num?)?.toDouble(),
    altitudeAccuracy: (m["altitudeAccuracy"] as num?)?.toDouble(),
    heading: (m["heading"] as num?)?.toDouble(),
    headingAccuracy: (m["headingAccuracy"] as num?)?.toDouble(),
    speed: (m["speed"] as num?)?.toDouble(),
    speedAccuracy: (m["speedAccuracy"] as num?)?.toDouble(),
    floor: (m["floor"] as num?)?.toInt(),
    isMocked: m["mocked"] == true,
    source: m["source"] as String?,
  );

  /// Latitude in degrees.
  final double latitude;

  /// Longitude in degrees.
  final double longitude;

  /// When it was measured.
  final DateTime time;

  /// Horizontal accuracy radius in metres.
  final double? accuracy;

  /// Metres above sea level.
  final double? altitude;

  /// Altitude accuracy in metres.
  final double? altitudeAccuracy;

  /// Direction of travel in degrees from north.
  final double? heading;

  /// Heading accuracy in degrees.
  final double? headingAccuracy;

  /// Metres per second.
  final double? speed;

  /// Speed accuracy in m/s.
  final double? speedAccuracy;

  /// Building floor (iOS indoor positioning).
  final int? floor;

  /// Produced by a fake-GPS app or the simulator.
  final bool isMocked;

  /// gps, network, fused, wifi, cellular, ip, … when the platform tells.
  final String? source;

  /// Great-circle distance to another point in metres.
  double distanceTo(double latitude, double longitude) => ULocationMath.distance(this.latitude, this.longitude, latitude, longitude);

  /// Initial bearing to another point in degrees from north.
  double bearingTo(double latitude, double longitude) => ULocationMath.bearing(this.latitude, this.longitude, latitude, longitude);

  /// As a map.
  Map<String, Object?> toMap() => <String, Object?>{
    "latitude": latitude,
    "longitude": longitude,
    "time": time.millisecondsSinceEpoch,
    "accuracy": accuracy,
    "altitude": altitude,
    "altitudeAccuracy": altitudeAccuracy,
    "heading": heading,
    "headingAccuracy": headingAccuracy,
    "speed": speed,
    "speedAccuracy": speedAccuracy,
    "floor": floor,
    "mocked": isMocked,
    "source": source,
  };

  @override
  String toString() => "UPosition($latitude, $longitude ±${accuracy?.toStringAsFixed(0)}m${isMocked ? ", mocked" : ""})";
}

/// Outcome of a one-shot location request: a position or the reason there is none.
@immutable
class ULocationResult {
  /// A result with a position.
  const ULocationResult.success(UPosition this.position) : error = null;

  /// A result with an error.
  const ULocationResult.failure(ULocationError this.error) : position = null;

  /// The position, or null on failure.
  final UPosition? position;

  /// Why it failed, or null.
  final ULocationError? error;

  /// True when a position was read.
  bool get isSuccess => position != null;

  @override
  String toString() => isSuccess ? "ULocationResult($position)" : "ULocationResult(${error!.name})";
}

/// Thrown into position / heading streams.
class ULocationException implements Exception {
  const ULocationException(this.error, [this.message]);

  /// Why it failed.
  final ULocationError error;

  /// Human-readable reason.
  final String? message;

  @override
  String toString() => "ULocationException(${error.name}${message == null ? "" : ": $message"})";
}

/// Live tracking options: accuracy, distance filter, interval, background, activity. `const ULocationSettings(distanceFilter: 10)`
@immutable
class ULocationSettings {
  const ULocationSettings({
    this.accuracy = ULocationAccuracy.high,
    this.distanceFilter = 0,
    this.interval = const Duration(seconds: 5),
    this.background = false,
    this.significantChangesOnly = false,
    this.activity = ULocationActivity.other,
    this.pauseAutomatically = false,
    this.showBackgroundIndicator = true,
    this.notificationTitle,
    this.notificationText,
  });

  /// Accuracy wanted.
  final ULocationAccuracy accuracy;

  /// Minimum movement in metres before a new position is reported.
  final double distanceFilter;

  /// How often to report (Android, Windows, web; iOS/macOS report on movement).
  final Duration interval;

  /// Keep tracking in the background (Android: foreground service; iOS: needs the "location" background mode).
  final bool background;

  /// Battery-friendly: only ~500 m moves (iOS / macOS significant-change service).
  final bool significantChangesOnly;

  /// Movement type hint (driving, walking…) for the OS to save battery.
  final ULocationActivity activity;

  /// iOS: pauses updates when the user stops moving.
  final bool pauseAutomatically;

  /// iOS blue status-bar pill while tracking in the background.
  final bool showBackgroundIndicator;

  /// Android background-tracking notification.
  final String? notificationTitle;

  /// Android: text of the "using location" notification in the background.
  final String? notificationText;

  /// As a map.
  Map<String, Object?> toMap() => <String, Object?>{
    "accuracy": accuracy.name,
    "distanceFilter": distanceFilter,
    "intervalMs": interval.inMilliseconds,
    "background": background,
    "significant": significantChangesOnly,
    "activity": activity.name,
    "pause": pauseAutomatically,
    "indicator": showBackgroundIndicator,
    "notificationTitle": notificationTitle,
    "notificationText": notificationText,
  };
}

/// A circle to watch for enter/exit. `UGeofence(id: "home", latitude: 35.7, longitude: 51.4, radius: 200)`
@immutable
class UGeofence {
  const UGeofence({required this.id, required this.latitude, required this.longitude, this.radius = 100, this.onEnter = true, this.onExit = true, this.notificationTitle, this.notificationText});

  /// Reads it from the native map.
  factory UGeofence.fromMap(Map<Object?, Object?> m) => UGeofence(
    id: "${m["id"]}",
    latitude: (m["latitude"]! as num).toDouble(),
    longitude: (m["longitude"]! as num).toDouble(),
    radius: (m["radius"] as num?)?.toDouble() ?? 100,
    onEnter: m["onEnter"] != false,
    onExit: m["onExit"] != false,
    notificationTitle: m["notificationTitle"] as String?,
    notificationText: m["notificationText"] as String?,
  );

  /// Your id for this area.
  final String id;

  /// Center latitude.
  final double latitude;

  /// Center longitude.
  final double longitude;

  /// Metres; the OS enforces a minimum of ~100 m for reliable triggers.
  final double radius;

  /// Reports entering.
  final bool onEnter;

  /// Reports leaving.
  final bool onExit;

  /// When set, a notification is shown on the transition even if the app is not running.
  final String? notificationTitle;

  /// Shows this notification on enter/exit even when the app is closed.
  final String? notificationText;

  /// As a map.
  Map<String, Object?> toMap() => <String, Object?>{
    "id": id,
    "latitude": latitude,
    "longitude": longitude,
    "radius": radius,
    "onEnter": onEnter,
    "onExit": onExit,
    "notificationTitle": notificationTitle,
    "notificationText": notificationText,
  };
}

/// An enter/exit event of a geofence.
@immutable
class UGeofenceEvent {
  const UGeofenceEvent({required this.id, required this.transition, required this.time});

  /// Reads it from the native map.
  factory UGeofenceEvent.fromMap(Map<Object?, Object?> m) => UGeofenceEvent(
    id: "${m["id"]}",
    transition: m["transition"] == "exit" ? UGeofenceTransition.exit : UGeofenceTransition.enter,
    time: DateTime.fromMillisecondsSinceEpoch((m["time"] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch),
  );

  /// Id of the geofence.
  final String id;

  /// Enter or exit.
  final UGeofenceTransition transition;

  /// When it happened.
  final DateTime time;

  @override
  String toString() => "UGeofenceEvent($id ${transition.name})";
}

/// Compass reading: degrees from north, accuracy.
@immutable
class UHeading {
  const UHeading({required this.magnetic, required this.time, this.trueNorth, this.accuracy});

  /// Reads it from the native map.
  factory UHeading.fromMap(Map<Object?, Object?> m) => UHeading(
    magnetic: (m["magnetic"]! as num).toDouble(),
    trueNorth: (m["true"] as num?)?.toDouble(),
    accuracy: (m["accuracy"] as num?)?.toDouble(),
    time: DateTime.fromMillisecondsSinceEpoch((m["time"] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch),
  );

  /// Degrees from magnetic north.
  final double magnetic;

  /// Degrees from true (geographic) north, when known.
  final double? trueNorth;

  /// Uncertainty in degrees.
  final double? accuracy;

  /// When it was measured.
  final DateTime time;

  /// The best available heading.
  double get degrees => trueNorth ?? magnetic;
}

/// A visit (arrival / departure at a place), iOS only.
@immutable
class UVisit {
  const UVisit({required this.latitude, required this.longitude, this.accuracy, this.arrival, this.departure});

  /// Reads it from the native map.
  factory UVisit.fromMap(Map<Object?, Object?> m) => UVisit(
    latitude: (m["latitude"]! as num).toDouble(),
    longitude: (m["longitude"]! as num).toDouble(),
    accuracy: (m["accuracy"] as num?)?.toDouble(),
    arrival: m["arrival"] == null ? null : DateTime.fromMillisecondsSinceEpoch((m["arrival"]! as num).toInt()),
    departure: m["departure"] == null ? null : DateTime.fromMillisecondsSinceEpoch((m["departure"]! as num).toInt()),
  );

  /// Latitude of the place.
  final double latitude;

  /// Longitude of the place.
  final double longitude;

  /// Accuracy in metres.
  final double? accuracy;

  /// When the user arrived.
  final DateTime? arrival;

  /// Null while the user is still there.
  final DateTime? departure;
}

/// An address: street, city, postal code, country… with coordinates.
@immutable
class UPlacemark {
  const UPlacemark({
    this.name,
    this.street,
    this.houseNumber,
    this.city,
    this.district,
    this.state,
    this.county,
    this.postalCode,
    this.country,
    this.countryCode,
    this.latitude,
    this.longitude,
    this.lines = const <String>[],
  });

  /// Reads it from the native map.
  factory UPlacemark.fromMap(Map<Object?, Object?> m) => UPlacemark(
    name: m["name"] as String?,
    street: m["street"] as String?,
    houseNumber: m["houseNumber"] as String?,
    city: m["city"] as String?,
    district: m["district"] as String?,
    state: m["state"] as String?,
    county: m["county"] as String?,
    postalCode: m["postalCode"] as String?,
    country: m["country"] as String?,
    countryCode: m["countryCode"] as String?,
    latitude: (m["latitude"] as num?)?.toDouble(),
    longitude: (m["longitude"] as num?)?.toDouble(),
    lines: ((m["lines"] as List<Object?>?) ?? <Object?>[]).whereType<String>().toList(),
  );

  /// Place name.
  final String? name;

  /// Street.
  final String? street;

  /// House number.
  final String? houseNumber;

  /// City.
  final String? city;

  /// District / neighbourhood.
  final String? district;

  /// Province / state.
  final String? state;

  /// County.
  final String? county;

  /// Postal code.
  final String? postalCode;

  /// Country name.
  final String? country;

  /// ISO country code.
  final String? countryCode;

  /// Latitude.
  final double? latitude;

  /// Longitude.
  final double? longitude;

  /// The address as the OS formats it, one line each.
  final List<String> lines;

  /// One-line address.
  String get address => lines.isNotEmpty ? lines.join(", ") : <String?>[name, street, district, city, state, country].whereType<String>().where((String s) => s.isNotEmpty).join(", ");

  @override
  String toString() => "UPlacemark($address)";
}

/// Geodesic helpers (WGS-84 sphere).
abstract final class ULocationMath {
  /// Earth radius in metres used for distances.
  static const double earthRadius = 6371008.8;

  static double _rad(double d) => d * math.pi / 180;

  /// Haversine distance in metres.
  static double distance(double lat1, double lng1, double lat2, double lng2) {
    final double dLat = _rad(lat2 - lat1);
    final double dLng = _rad(lng2 - lng1);
    final double a = math.pow(math.sin(dLat / 2), 2) + math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadius * math.asin(math.min(1, math.sqrt(a)));
  }

  /// Initial bearing in degrees (0-360) from point 1 to point 2.
  static double bearing(double lat1, double lng1, double lat2, double lng2) {
    final double y = math.sin(_rad(lng2 - lng1)) * math.cos(_rad(lat2));
    final double x = math.cos(_rad(lat1)) * math.sin(_rad(lat2)) - math.sin(_rad(lat1)) * math.cos(_rad(lat2)) * math.cos(_rad(lng2 - lng1));
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }
}
