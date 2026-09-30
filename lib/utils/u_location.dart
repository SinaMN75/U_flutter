import "package:u/utilities.dart";

/// Location: current position, live tracking, permissions, geofences, compass, addresses.
/// Wraps [ULocationChannel] (lib/plugins/location). No Google Play Services needed.
abstract final class ULocation {
  /// The current position, asking for permission if needed; check `.error` for why it failed.
  static Future<ULocationResult> current({ULocationAccuracy accuracy = ULocationAccuracy.high, Duration timeout = const Duration(seconds: 20), Duration? maxAge}) =>
      ULocationChannel.current(accuracy: accuracy, timeout: timeout, maxAge: maxAge);

  /// The current position or null (when you do not care why it failed).
  static Future<UPosition?> position({ULocationAccuracy accuracy = ULocationAccuracy.high}) async => (await current(accuracy: accuracy)).position;

  /// The last position the OS knows, instantly (may be old or null).
  static Future<UPosition?> lastKnown() => ULocationChannel.lastKnown();

  /// Live positions while listening (set `background: true` to keep tracking in the background).
  static Stream<UPosition> stream([ULocationSettings settings = const ULocationSettings()]) => ULocationChannel.positions(settings);

  /// Current permission, precise/approximate and whether location services are on.
  static Future<ULocationPermission> permission() => ULocationChannel.permission();

  /// Asks for location permission ([always] also asks for background access).
  static Future<ULocationPermission> requestPermission({bool always = false}) => ULocationChannel.requestPermission(always: always);

  /// Asks if needed and returns null when ready, or the reason location cannot be used.
  static Future<ULocationError?> ensureReady({bool always = false}) => ULocationChannel.ensureReady(always: always);

  /// True when permission is granted and location services are on.
  static Future<bool> isReady() async {
    final ULocationPermission p = await permission();
    return p.isGranted && p.serviceEnabled;
  }

  /// True when the device's location services (GPS switch) are on.
  static Future<bool> isServiceEnabled() async => (await permission()).serviceEnabled;

  /// iOS 14+: asks to upgrade approximate location to precise ([purposeKey] from Info.plist).
  static Future<bool> requestPrecise(String purposeKey) => ULocationChannel.requestPrecise(purposeKey);

  /// Opens the system location settings (to turn GPS on).
  static Future<bool> openLocationSettings() => ULaunch.settings(USettingsPage.location);

  /// Opens this app's settings (to grant a permission that was denied forever).
  static Future<bool> openAppSettings() => ULaunch.settings();

  /// Compass heading while listening (Android, iOS, Windows with a compass, mobile web).
  static Stream<UHeading> heading() => ULocationChannel.heading();

  /// Places the user arrives at and leaves (iOS).
  static Stream<UVisit> visits() => ULocationChannel.visits();

  /// Watches an area; works in the background on Android, iOS, macOS and Windows.
  static Future<bool> addGeofence(UGeofence fence) => ULocationChannel.addGeofence(fence);

  /// Stops watching an area.
  static Future<void> removeGeofence(String id) => ULocationChannel.removeGeofence(id);

  /// Stops watching every area.
  static Future<void> clearGeofences() => ULocationChannel.clearGeofences();

  /// Every watched area.
  static Future<List<UGeofence>> geofences() => ULocationChannel.geofences();

  /// Enter / exit events, including ones that happened while the app was closed.
  static Stream<UGeofenceEvent> geofenceEvents() => ULocationChannel.geofenceEvents();

  /// Addresses at a point, in [locale] (Android, iOS, macOS).
  static Future<List<UPlacemark>> addressOf(double latitude, double longitude, {String? locale}) => ULocationChannel.reverseGeocode(latitude, longitude, locale: locale);

  /// Coordinates of an address, in [locale] (Android, iOS, macOS).
  static Future<List<UPlacemark>> find(String address, {String? locale}) => ULocationChannel.geocode(address, locale: locale);

  /// True when address lookup works on this device.
  static Future<bool> isGeocodingAvailable() => ULocationChannel.isGeocodingAvailable();

  /// Distance in metres between two points.
  static double distance(double lat1, double lng1, double lat2, double lng2) => ULocationMath.distance(lat1, lng1, lat2, lng2);

  /// Bearing in degrees (0-360) from point 1 to point 2.
  static double bearing(double lat1, double lng1, double lat2, double lng2) => ULocationMath.bearing(lat1, lng1, lat2, lng2);
}
