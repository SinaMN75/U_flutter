import "package:u/utilities.dart";

/// GPS position, live tracking, permissions, geofences, compass and addresses on all 6 platforms, no Google Play Services. Needs `dart run u:app permission add location`. `final UPosition? p = await ULocation.position();`
abstract final class ULocation {
  /// Current position, asking for permission when needed; on failure `.error` says why (denied, GPS off, timeout…). Web: HTTPS only. `final r = await ULocation.current(); if (r.position != null) …`
  static Future<ULocationResult> current({ULocationAccuracy accuracy = ULocationAccuracy.high, Duration timeout = const Duration(seconds: 20), Duration? maxAge}) =>
      ULocationChannel.current(accuracy: accuracy, timeout: timeout, maxAge: maxAge);

  /// Current position, or null when it cannot be read (use current() to know why). `final UPosition? p = await ULocation.position();`
  static Future<UPosition?> position({ULocationAccuracy accuracy = ULocationAccuracy.high}) async => (await current(accuracy: accuracy)).position;

  /// Last position the OS remembers, instantly; may be old or null (web and Linux: null). `ULocation.lastKnown()`
  static Future<UPosition?> lastKnown() => ULocationChannel.lastKnown();

  /// Live positions while you listen; `background: true` keeps going in the background (Android/iOS, needs `permission add location-always`). `ULocation.stream(const ULocationSettings(distanceFilter: 10)).listen(update)`
  static Stream<UPosition> stream([ULocationSettings settings = const ULocationSettings()]) => ULocationChannel.positions(settings);

  /// Permission state, precise vs approximate, and whether the GPS switch is on. `(await ULocation.permission()).isGranted`
  static Future<ULocationPermission> permission() => ULocationChannel.permission();

  /// Asks for location permission; [always] also asks for background access (Android/iOS/macOS). `await ULocation.requestPermission()`
  static Future<ULocationPermission> requestPermission({bool always = false}) => ULocationChannel.requestPermission(always: always);

  /// Asks if needed; returns null when location is usable, else the reason (show a message or open settings). `final err = await ULocation.ensureReady(); if (err != null) …`
  static Future<ULocationError?> ensureReady({bool always = false}) => ULocationChannel.ensureReady(always: always);

  /// True when permission is granted and location services are on.
  static Future<bool> isReady() async {
    final ULocationPermission p = await permission();
    return p.isGranted && p.serviceEnabled;
  }

  /// True when the device's location switch is on.
  static Future<bool> isServiceEnabled() async => (await permission()).serviceEnabled;

  /// iOS 14+ only: asks to upgrade approximate to precise; [purposeKey] from NSLocationTemporaryUsageDescriptionDictionary. `ULocation.requestPrecise("Delivery")`
  static Future<bool> requestPrecise(String purposeKey) => ULocationChannel.requestPrecise(purposeKey);

  /// Opens the system location settings so the user can turn GPS on (web: false). `ULocation.openLocationSettings()`
  static Future<bool> openLocationSettings() => ULaunch.settings(USettingsPage.location);

  /// Opens this app's settings to grant a permission that was denied forever (web: false). `ULocation.openAppSettings()`
  static Future<bool> openAppSettings() => ULaunch.settings();

  /// Compass direction while you listen: Android, iOS, Windows with a compass, mobile web; not macOS/Linux. `ULocation.heading().listen((h) => angle = h.degrees)`
  static Stream<UHeading> heading() => ULocationChannel.heading();

  /// iOS only: places the user arrives at and leaves (battery friendly). `ULocation.visits().listen(logVisit)`
  static Stream<UVisit> visits() => ULocationChannel.visits();

  /// Watches a circle; enter/exit works in the background on Android, iOS, macOS, Windows; Linux/web only while the app runs. `ULocation.addGeofence(UGeofence(id: "home", latitude: 35.7, longitude: 51.4, radius: 200))` · background: `permission add location-always`
  static Future<bool> addGeofence(UGeofence fence) => ULocationChannel.addGeofence(fence);

  /// Stops watching one area. `ULocation.removeGeofence("home")`
  static Future<void> removeGeofence(String id) => ULocationChannel.removeGeofence(id);

  /// Stops watching every area.
  static Future<void> clearGeofences() => ULocationChannel.clearGeofences();

  /// Every area being watched.
  static Future<List<UGeofence>> geofences() => ULocationChannel.geofences();

  /// Enter/exit events, including ones that happened while the app was closed. `ULocation.geofenceEvents().listen((e) => UNotification.show(1, title: "Welcome home"))`
  static Stream<UGeofenceEvent> geofenceEvents() => ULocationChannel.geofenceEvents();

  /// Street address of a point, in [locale] (Android, iOS, macOS; empty elsewhere). `(await ULocation.addressOf(35.7, 51.4)).first.street`
  static Future<List<UPlacemark>> addressOf(double latitude, double longitude, {String? locale}) => ULocationChannel.reverseGeocode(latitude, longitude, locale: locale);

  /// Coordinates of an address text (Android, iOS, macOS; empty elsewhere). `await ULocation.find("Azadi Tower, Tehran")`
  static Future<List<UPlacemark>> find(String address, {String? locale}) => ULocationChannel.geocode(address, locale: locale);

  /// True when addressOf / find work on this device.
  static Future<bool> isGeocodingAvailable() => ULocationChannel.isGeocodingAvailable();

  /// Distance in metres between two points (pure math, any platform). `ULocation.distance(35.7, 51.4, 32.6, 51.6)`
  static double distance(double lat1, double lng1, double lat2, double lng2) => ULocationMath.distance(lat1, lng1, lat2, lng2);

  /// Direction in degrees (0 = north) from point 1 to point 2. `ULocation.bearing(lat1, lng1, lat2, lng2)`
  static double bearing(double lat1, double lng1, double lat2, double lng2) => ULocationMath.bearing(lat1, lng1, lat2, lng2);
}
