import "dart:async";
import "dart:js_interop";
import "dart:js_interop_unsafe";

import "package:u/src/location/u_location_types.dart";
import "package:web/web.dart" as web;

// Browser half of ULocationChannel.
abstract final class ULocationWeb {
  static Future<ULocationPermission> permission() async {
    final JSObject navigator = web.window.navigator as JSObject;
    if (!navigator.has("geolocation")) return const ULocationPermission(status: ULocationPermissionStatus.unsupported, serviceEnabled: false);
    try {
      final JSObject query = JSObject()..["name"] = "geolocation".toJS;
      final JSObject permissions = navigator["permissions"]! as JSObject;
      final JSObject status = await permissions.callMethod<JSPromise<JSObject>>("query".toJS, query).toDart;
      final String state = (status["state"] as JSString?)?.toDart ?? "prompt";
      return ULocationPermission(
        status: switch (state) {
          "granted" => ULocationPermissionStatus.whileInUse,
          "denied" => ULocationPermissionStatus.deniedForever,
          _ => ULocationPermissionStatus.notDetermined,
        },
      );
    } catch (_) {
      // Safari < 16 has no Permissions API for geolocation: asking is the only way to know.
      return const ULocationPermission(status: ULocationPermissionStatus.notDetermined);
    }
  }

  // Browsers only prompt when a position is requested.
  static Future<ULocationPermission> requestPermission() async {
    await current(accuracy: ULocationAccuracy.low, timeout: const Duration(seconds: 30), maxAge: const Duration(days: 1));
    return permission();
  }

  static web.PositionOptions _options(ULocationAccuracy accuracy, Duration timeout, Duration? maxAge) => web.PositionOptions(
    enableHighAccuracy: accuracy.index >= ULocationAccuracy.high.index,
    timeout: timeout.inMilliseconds,
    maximumAge: maxAge?.inMilliseconds ?? 0,
  );

  static UPosition _position(web.GeolocationPosition p) {
    final web.GeolocationCoordinates c = p.coords;
    return UPosition(
      latitude: c.latitude,
      longitude: c.longitude,
      time: DateTime.fromMillisecondsSinceEpoch(p.timestamp.toInt()),
      accuracy: c.accuracy,
      altitude: c.altitude,
      altitudeAccuracy: c.altitudeAccuracy,
      heading: c.heading?.isNaN ?? true ? null : c.heading,
      speed: c.speed,
      source: "browser",
    );
  }

  static ULocationError _error(web.GeolocationPositionError e) => switch (e.code) {
    1 => ULocationError.permissionDenied,
    3 => ULocationError.timeout,
    _ => ULocationError.unavailable,
  };

  static Future<ULocationResult> current({required ULocationAccuracy accuracy, required Duration timeout, Duration? maxAge}) {
    final Completer<ULocationResult> done = Completer<ULocationResult>();
    try {
      web.window.navigator.geolocation.getCurrentPosition(
        ((web.GeolocationPosition p) => done.complete(ULocationResult.success(_position(p)))).toJS,
        ((web.GeolocationPositionError e) => done.complete(ULocationResult.failure(_error(e)))).toJS,
        _options(accuracy, timeout, maxAge),
      );
    } catch (_) {
      return Future<ULocationResult>.value(const ULocationResult.failure(ULocationError.unsupported));
    }
    return done.future;
  }

  static Stream<UPosition> positions(ULocationSettings settings) {
    late final StreamController<UPosition> controller;
    int? watch;
    UPosition? last;
    controller = StreamController<UPosition>(
      onListen: () {
        watch = web.window.navigator.geolocation.watchPosition(
          ((web.GeolocationPosition p) {
            final UPosition next = _position(p);
            // The browser has no distance filter: apply it here.
            final UPosition? previous = last;
            if (previous != null && settings.distanceFilter > 0 && next.distanceTo(previous.latitude, previous.longitude) < settings.distanceFilter) return;
            last = next;
            controller.add(next);
          }).toJS,
          ((web.GeolocationPositionError e) => controller.addError(ULocationException(_error(e), e.message))).toJS,
          _options(settings.accuracy, const Duration(minutes: 1), null),
        );
      },
      onCancel: () {
        if (watch != null) web.window.navigator.geolocation.clearWatch(watch!);
        unawaited(controller.close());
      },
    );
    return controller.stream;
  }

  static Stream<UHeading> heading() {
    late final StreamController<UHeading> controller;
    JSExportedDartFunction<void Function(JSObject e)>? listener;
    String event = "deviceorientationabsolute";
    controller = StreamController<UHeading>(
      onListen: () async {
        final JSObject window = web.window as JSObject;
        // iOS 13+ asks for motion permission; must be granted from a user gesture.
        final JSObject? orientation = window["DeviceOrientationEvent"] as JSObject?;
        if (orientation != null && orientation.has("requestPermission")) {
          try {
            final String state = (await orientation.callMethod<JSPromise<JSString>>("requestPermission".toJS).toDart).toDart;
            if (state != "granted") return controller.addError(const ULocationException(ULocationError.permissionDenied));
          } catch (_) {}
        }
        if (!window.has("ondeviceorientationabsolute")) event = "deviceorientation";
        listener = ((JSObject e) {
          final JSNumber? webkit = e["webkitCompassHeading"] as JSNumber?;
          final JSNumber? alpha = e["alpha"] as JSNumber?;
          final bool absolute = (e["absolute"] as JSBoolean?)?.toDart ?? false;
          double? degrees;
          if (webkit != null) {
            degrees = webkit.toDartDouble;
          } else if (alpha != null && (absolute || event == "deviceorientationabsolute")) {
            degrees = (360 - alpha.toDartDouble) % 360;
          }
          if (degrees == null) return;
          final JSNumber? accuracy = e["webkitCompassAccuracy"] as JSNumber?;
          controller.add(UHeading(magnetic: degrees, accuracy: accuracy?.toDartDouble, time: DateTime.now()));
        }).toJS;
        web.window.addEventListener(event, listener);
      },
      onCancel: () {
        if (listener != null) web.window.removeEventListener(event, listener);
        unawaited(controller.close());
      },
    );
    return controller.stream;
  }
}
