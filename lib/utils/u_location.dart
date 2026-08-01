import "package:u/utilities.dart";

abstract class ULocation {
  static Future<Position?> getUserLocation({final Function(Position)? onUserLocationFound}) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }
    final Position currentPosition = await Geolocator.getCurrentPosition();
    if (onUserLocationFound != null) onUserLocationFound(currentPosition);

    return currentPosition;
  }
}
