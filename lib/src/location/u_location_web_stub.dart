import "package:u/src/location/u_location_types.dart";

// Off the web these are never called; ULocationChannel checks kIsWeb first.
abstract final class ULocationWeb {
  static Future<ULocationPermission> permission() async => const ULocationPermission(status: ULocationPermissionStatus.unsupported, serviceEnabled: false);

  static Future<ULocationPermission> requestPermission() => permission();

  static Future<ULocationResult> current({required ULocationAccuracy accuracy, required Duration timeout, Duration? maxAge}) async => const ULocationResult.failure(ULocationError.unsupported);

  static Stream<UPosition> positions(ULocationSettings settings) => const Stream<UPosition>.empty();

  static Stream<UHeading> heading() => const Stream<UHeading>.empty();
}
