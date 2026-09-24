import "dart:ui" as ui;

import "package:u/utilities.dart";

// =============================================================================
// u_ar_platform — the native AR / 3D layer of the `u` plugin.
//
// One method channel ("u/ar") plus one event channel per session, backed by
// ARCore + a built-in OpenGL ES 3 glTF renderer on Android, ARKit + RealityKit
// on iOS and WebXR + a built-in WebGL2 glTF renderer on the web. The same
// session also runs without a camera as a plain 3D model viewer.
//
// [UArCapabilities] says what the current device actually supports so UI can
// hide the rest. Nothing in this file needs reading to use the package — the
// ready-made widgets live in `components/u_ar.dart`.
// =============================================================================

enum UArMode { world, face, image, geo, body, orientation, viewer }

enum UArCameraFacing { back, front }

enum UArPlaneDetection { none, horizontal, vertical, both }

enum UArPlaneStyle { grid, dots, solid, outline, hidden }

enum UArLightEstimation { disabled, ambient, environmentalHdr }

enum UArSceneReconstruction { none, mesh, meshWithClassification }

enum UArFocusMode { auto, fixed }

enum UArGeoMode { auto, vps, gps }

enum UArWorldAlignment { gravity, gravityAndHeading, camera }

enum UArCoachingGoal { tracking, horizontalPlane, verticalPlane, anyPlane, geoTracking }

enum UArSessionState { uninitialized, initializing, running, paused, error, disposed }

enum UArTrackingState { notAvailable, limited, normal, paused, stopped }

enum UArTrackingReason { none, initializing, excessiveMotion, insufficientFeatures, insufficientLight, relocalizing, cameraUnavailable, badState, unknown }

enum UArPlaneType { horizontalUp, horizontalDown, vertical }

enum UArPlaneClassification { none, wall, floor, ceiling, table, seat, door, window, unknown }

enum UArHitType { plane, point, depth, estimated, instant, mesh }

enum UArNodeType { model, box, sphere, cylinder, cone, plane, image, video, group }

enum UArAnchorType { world, plane, point, image, face, geo, terrain, rooftop, cloud, object, body }

enum UArBillboard { none, full, yAxis }

enum UArPivot { original, center, bottom }

enum UArAltitudeMode { absolute, terrain, rooftop }

enum UArVpsAvailability { available, unavailable, unknown }

enum UArImageFormat { png, jpeg }

enum UArAvailabilityStatus { supported, needsInstall, sdkMissing, unsupported, unknown }

enum UArPermission { granted, denied, permanentlyDenied, restricted, unknown }

enum UArErrorCode { permission, unsupported, notInstalled, sdkMissing, sessionFailed, notFound, loadFailed, network, notAuthorized, timeout, cancelled, unknown }

enum UArObjectCaptureDetail { preview, reduced, medium, full, raw }

T _enumOf<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final T value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

double _d(Object? value, [double fallback = 0]) => value is num ? value.toDouble() : fallback;

int _i(Object? value, [int fallback = 0]) => value is num ? value.toInt() : fallback;

List<double> _doubles(Object? value) => value is List<Object?> ? value.map(_d).toList(growable: false) : const <double>[];

Map<Object?, Object?> _map(Object? value) => value is Map<Object?, Object?> ? value : const <Object?, Object?>{};

List<Map<Object?, Object?>> _maps(Object? value) => value is List<Object?> ? value.whereType<Map<Object?, Object?>>().toList(growable: false) : const <Map<Object?, Object?>>[];

class UArException implements Exception {
  const UArException({required this.code, required this.message, this.detail});

  final UArErrorCode code;
  final String message;
  final String? detail;

  factory UArException.fromPlatform(PlatformException error) => UArException(
    code: _enumOf(UArErrorCode.values, error.code, UArErrorCode.unknown),
    message: error.message ?? error.code,
    detail: error.details?.toString(),
  );

  @override
  String toString() => "UArException(${code.name}): $message${detail == null ? "" : " — $detail"}";
}

// =============================================================================
// Math
// =============================================================================

class UArVector3 {
  const UArVector3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  static const UArVector3 zero = UArVector3(0, 0, 0);
  static const UArVector3 one = UArVector3(1, 1, 1);
  static const UArVector3 up = UArVector3(0, 1, 0);
  static const UArVector3 forward = UArVector3(0, 0, -1);
  static const UArVector3 right = UArVector3(1, 0, 0);

  factory UArVector3.all(double value) => UArVector3(value, value, value);

  factory UArVector3.fromList(List<double> list, [int offset = 0]) => list.length < offset + 3 ? UArVector3.zero : UArVector3(list[offset], list[offset + 1], list[offset + 2]);

  UArVector3 operator +(UArVector3 other) => UArVector3(x + other.x, y + other.y, z + other.z);

  UArVector3 operator -(UArVector3 other) => UArVector3(x - other.x, y - other.y, z - other.z);

  UArVector3 operator *(double factor) => UArVector3(x * factor, y * factor, z * factor);

  UArVector3 operator -() => UArVector3(-x, -y, -z);

  UArVector3 multiply(UArVector3 other) => UArVector3(x * other.x, y * other.y, z * other.z);

  double dot(UArVector3 other) => x * other.x + y * other.y + z * other.z;

  UArVector3 cross(UArVector3 other) => UArVector3(y * other.z - z * other.y, z * other.x - x * other.z, x * other.y - y * other.x);

  double get length => sqrt(x * x + y * y + z * z);

  double get horizontalLength => sqrt(x * x + z * z);

  UArVector3 get normalized {
    final double l = length;
    return l < 1e-9 ? UArVector3.zero : this * (1 / l);
  }

  double distanceTo(UArVector3 other) => (this - other).length;

  UArVector3 lerp(UArVector3 other, double t) => this + (other - this) * t;

  List<double> toList() => <double>[x, y, z];

  @override
  bool operator ==(Object other) => other is UArVector3 && other.x == x && other.y == y && other.z == z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => "UArVector3(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)}, ${z.toStringAsFixed(3)})";
}

class UArQuaternion {
  const UArQuaternion(this.x, this.y, this.z, this.w);

  final double x;
  final double y;
  final double z;
  final double w;

  static const UArQuaternion identity = UArQuaternion(0, 0, 0, 1);

  factory UArQuaternion.fromList(List<double> list, [int offset = 0]) =>
      list.length < offset + 4 ? UArQuaternion.identity : UArQuaternion(list[offset], list[offset + 1], list[offset + 2], list[offset + 3]);

  factory UArQuaternion.axisAngle(UArVector3 axis, double radians) {
    final UArVector3 n = axis.normalized;
    final double s = sin(radians / 2);
    return UArQuaternion(n.x * s, n.y * s, n.z * s, cos(radians / 2));
  }

  factory UArQuaternion.yaw(double radians) => UArQuaternion.axisAngle(UArVector3.up, radians);

  factory UArQuaternion.pitch(double radians) => UArQuaternion.axisAngle(UArVector3.right, radians);

  factory UArQuaternion.roll(double radians) => UArQuaternion.axisAngle(const UArVector3(0, 0, 1), radians);

  /// Yaw (Y), then pitch (X), then roll (Z), all in degrees.
  factory UArQuaternion.euler({double yaw = 0, double pitch = 0, double roll = 0}) =>
      UArQuaternion.yaw(yaw * pi / 180).multiply(UArQuaternion.pitch(pitch * pi / 180)).multiply(UArQuaternion.roll(roll * pi / 180));

  /// Rotation whose -Z axis points along [forward].
  factory UArQuaternion.lookRotation(UArVector3 forward, [UArVector3 up = UArVector3.up]) {
    final UArVector3 back = (-forward).normalized;
    UArVector3 right = up.cross(back).normalized;
    if (right.length < 1e-6) right = UArVector3.right;
    final UArVector3 trueUp = back.cross(right);
    return UArQuaternion.fromBasis(right, trueUp, back);
  }

  factory UArQuaternion.fromBasis(UArVector3 xAxis, UArVector3 yAxis, UArVector3 zAxis) {
    final double m00 = xAxis.x;
    final double m01 = yAxis.x;
    final double m02 = zAxis.x;
    final double m10 = xAxis.y;
    final double m11 = yAxis.y;
    final double m12 = zAxis.y;
    final double m20 = xAxis.z;
    final double m21 = yAxis.z;
    final double m22 = zAxis.z;
    final double trace = m00 + m11 + m22;
    if (trace > 0) {
      final double s = sqrt(trace + 1) * 2;
      return UArQuaternion((m21 - m12) / s, (m02 - m20) / s, (m10 - m01) / s, 0.25 * s);
    }
    if (m00 > m11 && m00 > m22) {
      final double s = sqrt(1 + m00 - m11 - m22) * 2;
      return UArQuaternion(0.25 * s, (m01 + m10) / s, (m02 + m20) / s, (m21 - m12) / s);
    }
    if (m11 > m22) {
      final double s = sqrt(1 + m11 - m00 - m22) * 2;
      return UArQuaternion((m01 + m10) / s, 0.25 * s, (m12 + m21) / s, (m02 - m20) / s);
    }
    final double s = sqrt(1 + m22 - m00 - m11) * 2;
    return UArQuaternion((m02 + m20) / s, (m12 + m21) / s, 0.25 * s, (m10 - m01) / s);
  }

  UArQuaternion multiply(UArQuaternion o) => UArQuaternion(
    w * o.x + x * o.w + y * o.z - z * o.y,
    w * o.y - x * o.z + y * o.w + z * o.x,
    w * o.z + x * o.y - y * o.x + z * o.w,
    w * o.w - x * o.x - y * o.y - z * o.z,
  );

  UArQuaternion operator *(UArQuaternion other) => multiply(other);

  UArQuaternion get conjugate => UArQuaternion(-x, -y, -z, w);

  UArQuaternion get normalized {
    final double l = sqrt(x * x + y * y + z * z + w * w);
    return l < 1e-9 ? UArQuaternion.identity : UArQuaternion(x / l, y / l, z / l, w / l);
  }

  UArVector3 rotate(UArVector3 v) {
    final UArVector3 q = UArVector3(x, y, z);
    final UArVector3 t = q.cross(v) * 2;
    return v + t * w + q.cross(t);
  }

  /// Heading of the rotated -Z axis around world Y, in radians.
  double get yawAngle {
    final UArVector3 f = rotate(UArVector3.forward);
    return atan2(-f.x, -f.z);
  }

  UArQuaternion slerp(UArQuaternion other, double t) {
    double cosHalf = x * other.x + y * other.y + z * other.z + w * other.w;
    UArQuaternion target = other;
    if (cosHalf < 0) {
      cosHalf = -cosHalf;
      target = UArQuaternion(-other.x, -other.y, -other.z, -other.w);
    }
    if (cosHalf > 0.9995) {
      return UArQuaternion(x + (target.x - x) * t, y + (target.y - y) * t, z + (target.z - z) * t, w + (target.w - w) * t).normalized;
    }
    final double half = acos(cosHalf);
    final double sinHalf = sqrt(1 - cosHalf * cosHalf);
    final double a = sin((1 - t) * half) / sinHalf;
    final double b = sin(t * half) / sinHalf;
    return UArQuaternion(x * a + target.x * b, y * a + target.y * b, z * a + target.z * b, w * a + target.w * b);
  }

  List<double> toList() => <double>[x, y, z, w];

  @override
  bool operator ==(Object other) => other is UArQuaternion && other.x == x && other.y == y && other.z == z && other.w == w;

  @override
  int get hashCode => Object.hash(x, y, z, w);
}

/// A rigid transform: where something is and which way it faces, in metres.
class UArPose {
  const UArPose({this.position = UArVector3.zero, this.rotation = UArQuaternion.identity});

  final UArVector3 position;
  final UArQuaternion rotation;

  static const UArPose identity = UArPose();

  factory UArPose.fromList(Object? raw) {
    final List<double> list = _doubles(raw);
    if (list.length < 7) return UArPose.identity;
    return UArPose(position: UArVector3.fromList(list), rotation: UArQuaternion.fromList(list, 3));
  }

  factory UArPose.translation(double x, double y, double z) => UArPose(position: UArVector3(x, y, z));

  UArVector3 transformPoint(UArVector3 point) => rotation.rotate(point) + position;

  UArVector3 transformDirection(UArVector3 direction) => rotation.rotate(direction);

  UArPose multiply(UArPose other) => UArPose(position: transformPoint(other.position), rotation: rotation.multiply(other.rotation).normalized);

  UArPose operator *(UArPose other) => multiply(other);

  UArPose get inverse {
    final UArQuaternion inv = rotation.conjugate;
    return UArPose(position: inv.rotate(-position), rotation: inv);
  }

  UArVector3 get forward => rotation.rotate(UArVector3.forward);

  UArVector3 get up => rotation.rotate(UArVector3.up);

  UArVector3 get right => rotation.rotate(UArVector3.right);

  UArPose translated(UArVector3 offset) => UArPose(position: position + offset, rotation: rotation);

  UArPose withRotation(UArQuaternion value) => UArPose(position: position, rotation: value);

  /// Same position, rotated only around world Y so it stays upright.
  UArPose get upright => UArPose(position: position, rotation: UArQuaternion.yaw(rotation.yawAngle));

  UArPose lerp(UArPose other, double t) => UArPose(position: position.lerp(other.position, t), rotation: rotation.slerp(other.rotation, t));

  List<double> toList() => <double>[...position.toList(), ...rotation.toList()];

  @override
  bool operator ==(Object other) => other is UArPose && other.position == position && other.rotation == rotation;

  @override
  int get hashCode => Object.hash(position, rotation);

  @override
  String toString() => "UArPose($position)";
}

/// Geographic helpers used by the GPS fallback and by location-based content.
abstract class UArGeo {
  static const double earthRadius = 6371008.8;

  static double _rad(double degrees) => degrees * pi / 180;

  /// Great-circle distance in metres.
  static double distance(double lat1, double lng1, double lat2, double lng2) {
    final double dLat = _rad(lat2 - lat1);
    final double dLng = _rad(lng2 - lng1);
    final double a = sin(dLat / 2) * sin(dLat / 2) + cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return 2 * earthRadius * atan2(sqrt(a), sqrt(1 - a));
  }

  /// Initial bearing from the first point to the second, degrees clockwise from north.
  static double bearing(double lat1, double lng1, double lat2, double lng2) {
    final double y = sin(_rad(lng2 - lng1)) * cos(_rad(lat2));
    final double x = cos(_rad(lat1)) * sin(_rad(lat2)) - sin(_rad(lat1)) * cos(_rad(lat2)) * cos(_rad(lng2 - lng1));
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  /// East / north / up offset in metres of a point from an origin.
  static UArVector3 enu(double originLat, double originLng, double lat, double lng, {double originAltitude = 0, double altitude = 0}) {
    final double north = _rad(lat - originLat) * earthRadius;
    final double east = _rad(lng - originLng) * earthRadius * cos(_rad((lat + originLat) / 2));
    return UArVector3(east, altitude - originAltitude, north);
  }

  /// Converts an ENU offset into AR world space, given the session's north
  /// alignment ([northYaw], radians) and the world position of the origin.
  static UArVector3 enuToWorld(UArVector3 enu, {double northYaw = 0, UArVector3 origin = UArVector3.zero}) {
    final UArVector3 local = UArVector3(enu.x, enu.y, -enu.z);
    return UArQuaternion.yaw(northYaw).rotate(local) + origin;
  }

  /// Offsets a coordinate by metres east / north, returning `[lat, lng]`.
  static List<double> offset(double lat, double lng, {double east = 0, double north = 0}) => <double>[
    lat + north / earthRadius * 180 / pi,
    lng + east / (earthRadius * cos(_rad(lat))) * 180 / pi,
  ];

  static String formatDistance(double metres) {
    if (metres < 1) return "${(metres * 100).round()} cm";
    if (metres < 1000) return "${metres.round()} m";
    return "${(metres / 1000).toStringAsFixed(metres < 10000 ? 1 : 0)} km";
  }
}

// =============================================================================
// Content description
// =============================================================================

/// Where a model, image, video or reference image comes from.
class UArSource {
  const UArSource._(this.kind, this.value, this.extension);

  factory UArSource.url(String url, {String? extension}) => UArSource._("url", url, extension ?? _extensionOf(url));

  /// A Flutter asset declared in the host app's pubspec.
  factory UArSource.asset(String asset, {String? extension}) => UArSource._("asset", asset, extension ?? _extensionOf(asset));

  factory UArSource.file(String path, {String? extension}) => UArSource._("file", path, extension ?? _extensionOf(path));

  factory UArSource.bytes(Uint8List bytes, {String extension = "glb"}) => UArSource._("bytes", bytes, extension);

  final String kind;
  final Object value;
  final String extension;

  String? get path => value is String ? value as String? : null;

  static String _extensionOf(String path) {
    final String clean = path.split("?").first.split("#").first;
    final int dot = clean.lastIndexOf(".");
    return dot < 0 ? "" : clean.substring(dot + 1).toLowerCase();
  }

  Map<String, Object?> toMap() => <String, Object?>{"kind": kind, "value": value, "ext": extension};
}

class UArMaterial {
  const UArMaterial({
    this.color = const Color(0xFFFFFFFF),
    this.metallic = 0,
    this.roughness = 0.6,
    this.opacity = 1,
    this.emissive,
    this.texture,
    this.unlit = false,
    this.doubleSided = false,
    this.occluder = false,
    this.renderOnTop = false,
  });

  final Color color;
  final double metallic;
  final double roughness;
  final double opacity;
  final Color? emissive;
  final UArSource? texture;
  final bool unlit;
  final bool doubleSided;

  /// Invisible, but hides whatever is behind it — cut-outs, portals, walls.
  final bool occluder;

  /// Ignores depth so the node always draws over the scene (HUD-style labels).
  final bool renderOnTop;

  UArMaterial copyWith({Color? color, double? metallic, double? roughness, double? opacity, Color? emissive, UArSource? texture, bool? unlit, bool? doubleSided, bool? occluder, bool? renderOnTop}) =>
      UArMaterial(
        color: color ?? this.color,
        metallic: metallic ?? this.metallic,
        roughness: roughness ?? this.roughness,
        opacity: opacity ?? this.opacity,
        emissive: emissive ?? this.emissive,
        texture: texture ?? this.texture,
        unlit: unlit ?? this.unlit,
        doubleSided: doubleSided ?? this.doubleSided,
        occluder: occluder ?? this.occluder,
        renderOnTop: renderOnTop ?? this.renderOnTop,
      );

  Map<String, Object?> toMap() => <String, Object?>{
    "color": color.toARGB32(),
    "metallic": metallic,
    "roughness": roughness,
    "opacity": opacity,
    "emissive": emissive?.toARGB32(),
    "texture": texture?.toMap(),
    "unlit": unlit,
    "doubleSided": doubleSided,
    "occluder": occluder,
    "renderOnTop": renderOnTop,
  };
}

class UArAnimation {
  const UArAnimation({this.name, this.index = 0, this.loop = true, this.speed = 1, this.autoplay = true});

  /// Clip name; when null [index] picks the clip. `"*"` plays every clip at once.
  final String? name;
  final int index;
  final bool loop;
  final double speed;
  final bool autoplay;

  Map<String, Object?> toMap() => <String, Object?>{"name": name, "index": index, "loop": loop, "speed": speed, "autoplay": autoplay};
}

class UArVideoOptions {
  const UArVideoOptions({this.loop = true, this.muted = true, this.autoplay = true, this.volume = 1});

  final bool loop;
  final bool muted;
  final bool autoplay;
  final double volume;

  Map<String, Object?> toMap() => <String, Object?>{"loop": loop, "muted": muted, "autoplay": autoplay, "volume": volume};
}

/// Anything drawn in the scene. Positions are metres, relative to [parentId]
/// when set, else to [anchorId] when set, else to the world origin.
class UArNode {
  const UArNode({
    required this.id,
    required this.type,
    this.source,
    this.iosSource,
    this.anchorId,
    this.parentId,
    this.position = UArVector3.zero,
    this.rotation = UArQuaternion.identity,
    this.scale = UArVector3.one,
    this.width = 0.1,
    this.height = 0.1,
    this.depth = 0.1,
    this.radius = 0.05,
    this.material = const UArMaterial(),
    this.billboard = UArBillboard.none,
    this.visible = true,
    this.castShadow = true,
    this.hittable = true,
    this.animation,
    this.video = const UArVideoOptions(),
    this.fitSize,
    this.pivot = UArPivot.original,
    this.data = const <String, Object?>{},
  });

  factory UArNode.model({
    required String id,
    required UArSource source,
    UArSource? iosSource,
    String? anchorId,
    String? parentId,
    UArVector3 position = UArVector3.zero,
    UArQuaternion rotation = UArQuaternion.identity,
    UArVector3 scale = UArVector3.one,
    double? fitSize,
    UArPivot pivot = UArPivot.bottom,
    UArAnimation? animation = const UArAnimation(),
    bool castShadow = true,
    bool hittable = true,
    UArBillboard billboard = UArBillboard.none,
    Map<String, Object?> data = const <String, Object?>{},
  }) => UArNode(
    id: id,
    type: UArNodeType.model,
    source: source,
    iosSource: iosSource,
    anchorId: anchorId,
    parentId: parentId,
    position: position,
    rotation: rotation,
    scale: scale,
    fitSize: fitSize,
    pivot: pivot,
    animation: animation,
    castShadow: castShadow,
    hittable: hittable,
    billboard: billboard,
    data: data,
  );

  factory UArNode.box({
    required String id,
    double width = 0.1,
    double height = 0.1,
    double depth = 0.1,
    UArMaterial material = const UArMaterial(),
    String? anchorId,
    String? parentId,
    UArVector3 position = UArVector3.zero,
    UArQuaternion rotation = UArQuaternion.identity,
    bool castShadow = true,
  }) => UArNode(
    id: id,
    type: UArNodeType.box,
    width: width,
    height: height,
    depth: depth,
    material: material,
    anchorId: anchorId,
    parentId: parentId,
    position: position,
    rotation: rotation,
    castShadow: castShadow,
  );

  factory UArNode.sphere({
    required String id,
    double radius = 0.05,
    UArMaterial material = const UArMaterial(),
    String? anchorId,
    String? parentId,
    UArVector3 position = UArVector3.zero,
    bool castShadow = true,
  }) => UArNode(id: id, type: UArNodeType.sphere, radius: radius, material: material, anchorId: anchorId, parentId: parentId, position: position, castShadow: castShadow);

  factory UArNode.cylinder({
    required String id,
    double radius = 0.05,
    double height = 0.1,
    UArMaterial material = const UArMaterial(),
    String? anchorId,
    String? parentId,
    UArVector3 position = UArVector3.zero,
    UArQuaternion rotation = UArQuaternion.identity,
  }) => UArNode(id: id, type: UArNodeType.cylinder, radius: radius, height: height, material: material, anchorId: anchorId, parentId: parentId, position: position, rotation: rotation);

  factory UArNode.cone({
    required String id,
    double radius = 0.05,
    double height = 0.1,
    UArMaterial material = const UArMaterial(),
    String? anchorId,
    String? parentId,
    UArVector3 position = UArVector3.zero,
    UArQuaternion rotation = UArQuaternion.identity,
  }) => UArNode(id: id, type: UArNodeType.cone, radius: radius, height: height, material: material, anchorId: anchorId, parentId: parentId, position: position, rotation: rotation);

  /// A flat rectangle facing +Z (or lying flat when rotated -90° around X).
  factory UArNode.plane({
    required String id,
    double width = 0.2,
    double height = 0.2,
    UArMaterial material = const UArMaterial(doubleSided: true),
    String? anchorId,
    String? parentId,
    UArVector3 position = UArVector3.zero,
    UArQuaternion rotation = UArQuaternion.identity,
    UArBillboard billboard = UArBillboard.none,
  }) => UArNode(
    id: id,
    type: UArNodeType.plane,
    width: width,
    height: height,
    material: material,
    anchorId: anchorId,
    parentId: parentId,
    position: position,
    rotation: rotation,
    billboard: billboard,
    castShadow: false,
  );

  /// An image on a quad; [width] in metres, height follows the image aspect.
  factory UArNode.image({
    required String id,
    required UArSource source,
    double width = 0.3,
    String? anchorId,
    String? parentId,
    UArVector3 position = UArVector3.zero,
    UArQuaternion rotation = UArQuaternion.identity,
    UArBillboard billboard = UArBillboard.none,
    bool unlit = true,
    bool renderOnTop = false,
    double opacity = 1,
    Map<String, Object?> data = const <String, Object?>{},
  }) => UArNode(
    id: id,
    type: UArNodeType.image,
    source: source,
    width: width,
    height: 0,
    anchorId: anchorId,
    parentId: parentId,
    position: position,
    rotation: rotation,
    billboard: billboard,
    material: UArMaterial(unlit: unlit, doubleSided: true, renderOnTop: renderOnTop, opacity: opacity),
    castShadow: false,
    data: data,
  );

  factory UArNode.video({
    required String id,
    required UArSource source,
    double width = 0.6,
    double height = 0.3375,
    UArVideoOptions video = const UArVideoOptions(),
    String? anchorId,
    String? parentId,
    UArVector3 position = UArVector3.zero,
    UArQuaternion rotation = UArQuaternion.identity,
    UArBillboard billboard = UArBillboard.none,
  }) => UArNode(
    id: id,
    type: UArNodeType.video,
    source: source,
    width: width,
    height: height,
    video: video,
    anchorId: anchorId,
    parentId: parentId,
    position: position,
    rotation: rotation,
    billboard: billboard,
    material: const UArMaterial(unlit: true, doubleSided: true),
    castShadow: false,
  );

  /// An empty transform used to move several children together.
  factory UArNode.group({
    required String id,
    String? anchorId,
    String? parentId,
    UArVector3 position = UArVector3.zero,
    UArQuaternion rotation = UArQuaternion.identity,
    UArVector3 scale = UArVector3.one,
  }) => UArNode(id: id, type: UArNodeType.group, anchorId: anchorId, parentId: parentId, position: position, rotation: rotation, scale: scale, castShadow: false);

  /// A thin bar between two points, e.g. a measuring line.
  factory UArNode.line({
    required String id,
    required UArVector3 from,
    required UArVector3 to,
    double thickness = 0.004,
    Color color = const Color(0xFFFFFFFF),
    String? anchorId,
    bool renderOnTop = false,
  }) {
    final UArVector3 delta = to - from;
    final double length = delta.length;
    final UArQuaternion rotation = length < 1e-6 ? UArQuaternion.identity : UArQuaternion.lookRotation(delta);
    return UArNode(
      id: id,
      type: UArNodeType.box,
      width: thickness,
      height: thickness,
      depth: length,
      position: from.lerp(to, 0.5),
      rotation: rotation,
      anchorId: anchorId,
      material: UArMaterial(color: color, unlit: true, renderOnTop: renderOnTop),
      castShadow: false,
      hittable: false,
    );
  }

  final String id;
  final UArNodeType type;
  final UArSource? source;

  /// iOS-only alternative (USDZ / Reality) for models, preferred over [source] there.
  final UArSource? iosSource;
  final String? anchorId;
  final String? parentId;
  final UArVector3 position;
  final UArQuaternion rotation;
  final UArVector3 scale;
  final double width;
  final double height;
  final double depth;
  final double radius;
  final UArMaterial material;
  final UArBillboard billboard;
  final bool visible;
  final bool castShadow;
  final bool hittable;
  final UArAnimation? animation;
  final UArVideoOptions video;

  /// Uniformly scales a model so its largest side is this many metres.
  final double? fitSize;
  final UArPivot pivot;

  /// Free-form app data, never sent to the platform.
  final Map<String, Object?> data;

  UArPose get pose => UArPose(position: position, rotation: rotation);

  UArNode copyWith({
    UArSource? source,
    UArSource? iosSource,
    String? anchorId,
    String? parentId,
    UArVector3? position,
    UArQuaternion? rotation,
    UArVector3? scale,
    double? width,
    double? height,
    double? depth,
    double? radius,
    UArMaterial? material,
    UArBillboard? billboard,
    bool? visible,
    bool? castShadow,
    bool? hittable,
    UArAnimation? animation,
    UArVideoOptions? video,
    double? fitSize,
    UArPivot? pivot,
    Map<String, Object?>? data,
  }) => UArNode(
    id: id,
    type: type,
    source: source ?? this.source,
    iosSource: iosSource ?? this.iosSource,
    anchorId: anchorId ?? this.anchorId,
    parentId: parentId ?? this.parentId,
    position: position ?? this.position,
    rotation: rotation ?? this.rotation,
    scale: scale ?? this.scale,
    width: width ?? this.width,
    height: height ?? this.height,
    depth: depth ?? this.depth,
    radius: radius ?? this.radius,
    material: material ?? this.material,
    billboard: billboard ?? this.billboard,
    visible: visible ?? this.visible,
    castShadow: castShadow ?? this.castShadow,
    hittable: hittable ?? this.hittable,
    animation: animation ?? this.animation,
    video: video ?? this.video,
    fitSize: fitSize ?? this.fitSize,
    pivot: pivot ?? this.pivot,
    data: data ?? this.data,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    "id": id,
    "type": type.name,
    "source": source?.toMap(),
    "iosSource": iosSource?.toMap(),
    "anchorId": anchorId,
    "parentId": parentId,
    "position": position.toList(),
    "rotation": rotation.toList(),
    "scale": scale.toList(),
    "width": width,
    "height": height,
    "depth": depth,
    "radius": radius,
    "material": material.toMap(),
    "billboard": billboard.name,
    "visible": visible,
    "castShadow": castShadow,
    "hittable": hittable,
    "animation": animation?.toMap(),
    "video": video.toMap(),
    "fitSize": fitSize,
    "pivot": pivot.name,
  };
}

/// A picture the session should recognise in the real world (posters, logos,
/// packaging, shop signs). [physicalWidth] is its printed width in metres.
class UArReferenceImage {
  const UArReferenceImage({required this.name, required this.source, this.physicalWidth = 0.2});

  final String name;
  final UArSource source;
  final double physicalWidth;

  Map<String, Object?> toMap() => <String, Object?>{"name": name, "source": source.toMap(), "width": physicalWidth};
}

/// A scanned real object (`.arobject`, iOS only).
class UArReferenceObject {
  const UArReferenceObject({required this.name, required this.source});

  final String name;
  final UArSource source;

  Map<String, Object?> toMap() => <String, Object?>{"name": name, "source": source.toMap()};
}

/// Camera placement for [UArMode.viewer], orbiting [target].
class UArOrbit {
  const UArOrbit({this.yaw = 30, this.pitch = 15, this.distance = 1.5, this.target = UArVector3.zero, this.fov = 45});

  /// Degrees around the vertical axis.
  final double yaw;

  /// Degrees above the horizon.
  final double pitch;
  final double distance;
  final UArVector3 target;

  /// Vertical field of view in degrees.
  final double fov;

  UArOrbit copyWith({double? yaw, double? pitch, double? distance, UArVector3? target, double? fov}) =>
      UArOrbit(yaw: yaw ?? this.yaw, pitch: pitch ?? this.pitch, distance: distance ?? this.distance, target: target ?? this.target, fov: fov ?? this.fov);

  UArOrbit lerp(UArOrbit other, double t) => UArOrbit(
    yaw: yaw + (other.yaw - yaw) * t,
    pitch: pitch + (other.pitch - pitch) * t,
    distance: distance + (other.distance - distance) * t,
    target: target.lerp(other.target, t),
    fov: fov + (other.fov - fov) * t,
  );

  Map<String, Object?> toMap() => <String, Object?>{"yaw": yaw, "pitch": pitch, "distance": distance, "target": target.toList(), "fov": fov};
}

class UArConfig {
  const UArConfig({
    this.mode = UArMode.world,
    this.camera = UArCameraFacing.back,
    this.planeDetection = UArPlaneDetection.both,
    this.planeStyle = UArPlaneStyle.grid,
    this.planeColor = const Color(0x80FFFFFF),
    this.showFeaturePoints = false,
    this.showWorldOrigin = false,
    this.showAnchors = false,
    this.showSceneMesh = false,
    this.occlusion = true,
    this.peopleOcclusion = true,
    this.sceneReconstruction = UArSceneReconstruction.none,
    this.lightEstimation = UArLightEstimation.environmentalHdr,
    this.focusMode = UArFocusMode.auto,
    this.instantPlacement = true,
    this.reticle = false,
    this.reticleColor = const Color(0xFFFFFFFF),
    this.coaching = true,
    this.coachingGoal = UArCoachingGoal.anyPlane,
    this.images = const <UArReferenceImage>[],
    this.maxTrackedImages = 4,
    this.objects = const <UArReferenceObject>[],
    this.geoMode = UArGeoMode.auto,
    this.cloudAnchors = false,
    this.semantics = false,
    this.showFaceMesh = false,
    this.faceMeshColor = const Color(0x55FFFFFF),
    this.collaboration = false,
    this.worldMap,
    this.worldAlignment = UArWorldAlignment.gravity,
    this.shadows = true,
    this.shadowOpacity = 0.45,
    this.exposure = 1,
    this.environmentIntensity = 1,
    this.background = const Color(0xFFF2F2F2),
    this.transparentBackground = false,
    this.orbit = const UArOrbit(),
    this.eventRate = 30,
    this.highFps = false,
  });

  /// A plain 3D model viewer: no camera, no permission, works everywhere.
  const UArConfig.viewer({
    this.background = const Color(0xFFF2F2F2),
    this.transparentBackground = false,
    this.shadows = true,
    this.shadowOpacity = 0.35,
    this.exposure = 1,
    this.environmentIntensity = 1,
    this.orbit = const UArOrbit(),
    this.eventRate = 30,
  }) : mode = UArMode.viewer,
       camera = UArCameraFacing.back,
       planeDetection = UArPlaneDetection.none,
       planeStyle = UArPlaneStyle.hidden,
       planeColor = const Color(0x00000000),
       showFeaturePoints = false,
       showWorldOrigin = false,
       showAnchors = false,
       showSceneMesh = false,
       occlusion = false,
       peopleOcclusion = false,
       sceneReconstruction = UArSceneReconstruction.none,
       lightEstimation = UArLightEstimation.disabled,
       focusMode = UArFocusMode.auto,
       instantPlacement = false,
       reticle = false,
       reticleColor = const Color(0x00000000),
       coaching = false,
       coachingGoal = UArCoachingGoal.tracking,
       images = const <UArReferenceImage>[],
       maxTrackedImages = 0,
       objects = const <UArReferenceObject>[],
       geoMode = UArGeoMode.auto,
       cloudAnchors = false,
       semantics = false,
       showFaceMesh = false,
       faceMeshColor = const Color(0x00000000),
       collaboration = false,
       worldMap = null,
       worldAlignment = UArWorldAlignment.gravity,
       highFps = false;

  final UArMode mode;
  final UArCameraFacing camera;
  final UArPlaneDetection planeDetection;
  final UArPlaneStyle planeStyle;
  final Color planeColor;
  final bool showFeaturePoints;
  final bool showWorldOrigin;
  final bool showAnchors;

  /// Draws the LiDAR scene mesh (iOS Pro devices).
  final bool showSceneMesh;

  /// Real surfaces hide virtual content behind them (Depth API / LiDAR).
  final bool occlusion;

  /// People walking in front of content hide it (iOS A12+).
  final bool peopleOcclusion;
  final UArSceneReconstruction sceneReconstruction;
  final UArLightEstimation lightEstimation;
  final UArFocusMode focusMode;

  /// Place content before a surface is found (Android), refined as it is.
  final bool instantPlacement;

  /// Draws a placement ring where the screen centre meets a surface and reports it in [UArFrame.centerHit].
  final bool reticle;
  final Color reticleColor;

  /// Shows the platform's own "move your phone" guidance where one exists (iOS).
  final bool coaching;
  final UArCoachingGoal coachingGoal;
  final List<UArReferenceImage> images;
  final int maxTrackedImages;
  final List<UArReferenceObject> objects;
  final UArGeoMode geoMode;

  /// Google Cloud Anchors (Android). Needs an ARCore API key in the host app.
  final bool cloudAnchors;

  /// Outdoor scene labels — sky, building, road… (Android).
  final bool semantics;
  final bool showFaceMesh;
  final Color faceMeshColor;

  /// Multi-user ARKit sessions; exchange [UArController.collaborationData] yourself.
  final bool collaboration;

  /// A map saved with [UArController.getWorldMap] to restore content (iOS).
  final Uint8List? worldMap;
  final UArWorldAlignment worldAlignment;
  final bool shadows;
  final double shadowOpacity;
  final double exposure;
  final double environmentIntensity;
  final Color background;
  final bool transparentBackground;
  final UArOrbit orbit;

  /// Maximum frame events per second sent to Dart.
  final int eventRate;

  /// Prefers a 60 fps camera where the device offers one.
  final bool highFps;

  bool get isViewer => mode == UArMode.viewer;

  UArConfig copyWith({
    UArMode? mode,
    UArCameraFacing? camera,
    UArPlaneDetection? planeDetection,
    UArPlaneStyle? planeStyle,
    Color? planeColor,
    bool? showFeaturePoints,
    bool? showWorldOrigin,
    bool? showAnchors,
    bool? showSceneMesh,
    bool? occlusion,
    bool? peopleOcclusion,
    UArSceneReconstruction? sceneReconstruction,
    UArLightEstimation? lightEstimation,
    UArFocusMode? focusMode,
    bool? instantPlacement,
    bool? reticle,
    Color? reticleColor,
    bool? coaching,
    UArCoachingGoal? coachingGoal,
    List<UArReferenceImage>? images,
    int? maxTrackedImages,
    List<UArReferenceObject>? objects,
    UArGeoMode? geoMode,
    bool? cloudAnchors,
    bool? semantics,
    bool? showFaceMesh,
    Color? faceMeshColor,
    bool? collaboration,
    Uint8List? worldMap,
    UArWorldAlignment? worldAlignment,
    bool? shadows,
    double? shadowOpacity,
    double? exposure,
    double? environmentIntensity,
    Color? background,
    bool? transparentBackground,
    UArOrbit? orbit,
    int? eventRate,
    bool? highFps,
  }) => UArConfig(
    mode: mode ?? this.mode,
    camera: camera ?? this.camera,
    planeDetection: planeDetection ?? this.planeDetection,
    planeStyle: planeStyle ?? this.planeStyle,
    planeColor: planeColor ?? this.planeColor,
    showFeaturePoints: showFeaturePoints ?? this.showFeaturePoints,
    showWorldOrigin: showWorldOrigin ?? this.showWorldOrigin,
    showAnchors: showAnchors ?? this.showAnchors,
    showSceneMesh: showSceneMesh ?? this.showSceneMesh,
    occlusion: occlusion ?? this.occlusion,
    peopleOcclusion: peopleOcclusion ?? this.peopleOcclusion,
    sceneReconstruction: sceneReconstruction ?? this.sceneReconstruction,
    lightEstimation: lightEstimation ?? this.lightEstimation,
    focusMode: focusMode ?? this.focusMode,
    instantPlacement: instantPlacement ?? this.instantPlacement,
    reticle: reticle ?? this.reticle,
    reticleColor: reticleColor ?? this.reticleColor,
    coaching: coaching ?? this.coaching,
    coachingGoal: coachingGoal ?? this.coachingGoal,
    images: images ?? this.images,
    maxTrackedImages: maxTrackedImages ?? this.maxTrackedImages,
    objects: objects ?? this.objects,
    geoMode: geoMode ?? this.geoMode,
    cloudAnchors: cloudAnchors ?? this.cloudAnchors,
    semantics: semantics ?? this.semantics,
    showFaceMesh: showFaceMesh ?? this.showFaceMesh,
    faceMeshColor: faceMeshColor ?? this.faceMeshColor,
    collaboration: collaboration ?? this.collaboration,
    worldMap: worldMap ?? this.worldMap,
    worldAlignment: worldAlignment ?? this.worldAlignment,
    shadows: shadows ?? this.shadows,
    shadowOpacity: shadowOpacity ?? this.shadowOpacity,
    exposure: exposure ?? this.exposure,
    environmentIntensity: environmentIntensity ?? this.environmentIntensity,
    background: background ?? this.background,
    transparentBackground: transparentBackground ?? this.transparentBackground,
    orbit: orbit ?? this.orbit,
    eventRate: eventRate ?? this.eventRate,
    highFps: highFps ?? this.highFps,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    "mode": mode.name,
    "camera": camera.name,
    "planeDetection": planeDetection.name,
    "planeStyle": planeStyle.name,
    "planeColor": planeColor.toARGB32(),
    "showFeaturePoints": showFeaturePoints,
    "showWorldOrigin": showWorldOrigin,
    "showAnchors": showAnchors,
    "showSceneMesh": showSceneMesh,
    "occlusion": occlusion,
    "peopleOcclusion": peopleOcclusion,
    "sceneReconstruction": sceneReconstruction.name,
    "lightEstimation": lightEstimation.name,
    "focusMode": focusMode.name,
    "instantPlacement": instantPlacement,
    "reticle": reticle,
    "reticleColor": reticleColor.toARGB32(),
    "coaching": coaching,
    "coachingGoal": coachingGoal.name,
    "images": images.map((UArReferenceImage image) => image.toMap()).toList(growable: false),
    "maxTrackedImages": maxTrackedImages,
    "objects": objects.map((UArReferenceObject object) => object.toMap()).toList(growable: false),
    "geoMode": geoMode.name,
    "cloudAnchors": cloudAnchors,
    "semantics": semantics,
    "showFaceMesh": showFaceMesh,
    "faceMeshColor": faceMeshColor.toARGB32(),
    "collaboration": collaboration,
    "worldMap": worldMap,
    "worldAlignment": worldAlignment.name,
    "shadows": shadows,
    "shadowOpacity": shadowOpacity,
    "exposure": exposure,
    "environmentIntensity": environmentIntensity,
    "background": background.toARGB32(),
    "transparentBackground": transparentBackground,
    "orbit": orbit.toMap(),
    "eventRate": eventRate,
    "highFps": highFps,
  };
}

// =============================================================================
// Results
// =============================================================================

class UArCapabilities {
  const UArCapabilities({
    this.platform = "",
    this.worldTracking = false,
    this.planeHorizontal = false,
    this.planeVertical = false,
    this.planeClassification = false,
    this.depth = false,
    this.peopleOcclusion = false,
    this.sceneReconstruction = false,
    this.lidar = false,
    this.imageTracking = false,
    this.objectTracking = false,
    this.faceTracking = false,
    this.bodyTracking = false,
    this.geospatial = false,
    this.gpsGeo = false,
    this.cloudAnchors = false,
    this.worldMap = false,
    this.collaboration = false,
    this.lightEstimation = false,
    this.environmentHdr = false,
    this.instantPlacement = false,
    this.semantics = false,
    this.recording = false,
    this.snapshot = false,
    this.roomPlan = false,
    this.objectCapture = false,
    this.textRecognition = false,
    this.barcodeDetection = false,
    this.cameraImage = false,
    this.nativeViewer = false,
    this.viewer = false,
    this.webXr = false,
    this.sensorAr = false,
    this.formats = const <String>[],
  });

  factory UArCapabilities.fromMap(Map<Object?, Object?> map) {
    bool b(String key) => map[key] == true;
    return UArCapabilities(
      platform: (map["platform"] as String?) ?? "",
      worldTracking: b("worldTracking"),
      planeHorizontal: b("planeHorizontal"),
      planeVertical: b("planeVertical"),
      planeClassification: b("planeClassification"),
      depth: b("depth"),
      peopleOcclusion: b("peopleOcclusion"),
      sceneReconstruction: b("sceneReconstruction"),
      lidar: b("lidar"),
      imageTracking: b("imageTracking"),
      objectTracking: b("objectTracking"),
      faceTracking: b("faceTracking"),
      bodyTracking: b("bodyTracking"),
      geospatial: b("geospatial"),
      gpsGeo: b("gpsGeo"),
      cloudAnchors: b("cloudAnchors"),
      worldMap: b("worldMap"),
      collaboration: b("collaboration"),
      lightEstimation: b("lightEstimation"),
      environmentHdr: b("environmentHdr"),
      instantPlacement: b("instantPlacement"),
      semantics: b("semantics"),
      recording: b("recording"),
      snapshot: b("snapshot"),
      roomPlan: b("roomPlan"),
      objectCapture: b("objectCapture"),
      textRecognition: b("textRecognition"),
      barcodeDetection: b("barcodeDetection"),
      cameraImage: b("cameraImage"),
      nativeViewer: b("nativeViewer"),
      viewer: b("viewer"),
      webXr: b("webXr"),
      sensorAr: b("sensorAr"),
      formats: map["formats"] is List<Object?> ? (map["formats"]! as List<Object?>).whereType<String>().toList(growable: false) : const <String>[],
    );
  }

  final String platform;
  final bool worldTracking;
  final bool planeHorizontal;
  final bool planeVertical;
  final bool planeClassification;
  final bool depth;
  final bool peopleOcclusion;
  final bool sceneReconstruction;
  final bool lidar;
  final bool imageTracking;
  final bool objectTracking;
  final bool faceTracking;
  final bool bodyTracking;

  /// Visual positioning (ARCore Geospatial / ARKit location anchors).
  final bool geospatial;

  /// GPS + compass placement, available wherever world tracking is.
  final bool gpsGeo;
  final bool cloudAnchors;
  final bool worldMap;
  final bool collaboration;
  final bool lightEstimation;
  final bool environmentHdr;
  final bool instantPlacement;
  final bool semantics;
  final bool recording;
  final bool snapshot;
  final bool roomPlan;
  final bool objectCapture;
  final bool textRecognition;
  final bool barcodeDetection;
  final bool cameraImage;

  /// Scene Viewer (Android) / AR Quick Look (iOS, iOS Safari).
  final bool nativeViewer;

  /// The camera-less 3D viewer.
  final bool viewer;
  final bool webXr;

  /// Camera + compass overlay without world tracking (web fallback).
  final bool sensorAr;

  /// Model formats the in-app renderer loads.
  final List<String> formats;

  bool get anyAr => worldTracking || faceTracking || sensorAr;
}

class UArAvailability {
  const UArAvailability({this.status = UArAvailabilityStatus.unknown, this.capabilities = const UArCapabilities(), this.message});

  factory UArAvailability.fromMap(Map<Object?, Object?> map) => UArAvailability(
    status: _enumOf(UArAvailabilityStatus.values, map["status"], UArAvailabilityStatus.unknown),
    capabilities: UArCapabilities.fromMap(_map(map["capabilities"])),
    message: map["message"] as String?,
  );

  final UArAvailabilityStatus status;
  final UArCapabilities capabilities;
  final String? message;

  bool get isSupported => status == UArAvailabilityStatus.supported;
}

class UArPermissionState {
  const UArPermissionState({this.camera = UArPermission.unknown, this.location = UArPermission.unknown, this.microphone = UArPermission.unknown});

  factory UArPermissionState.fromMap(Map<Object?, Object?> map) => UArPermissionState(
    camera: _enumOf(UArPermission.values, map["camera"], UArPermission.unknown),
    location: _enumOf(UArPermission.values, map["location"], UArPermission.unknown),
    microphone: _enumOf(UArPermission.values, map["microphone"], UArPermission.unknown),
  );

  final UArPermission camera;
  final UArPermission location;
  final UArPermission microphone;

  bool get cameraGranted => camera == UArPermission.granted;

  bool get locationGranted => location == UArPermission.granted;
}

class UArPlane {
  const UArPlane({
    required this.id,
    required this.type,
    required this.pose,
    this.classification = UArPlaneClassification.none,
    this.width = 0,
    this.length = 0,
    this.polygon = const <Offset>[],
    this.tracking = UArTrackingState.normal,
    this.subsumedBy,
  });

  factory UArPlane.fromMap(Map<Object?, Object?> map) {
    final List<double> polygon = _doubles(map["polygon"]);
    final List<double> extent = _doubles(map["extent"]);
    return UArPlane(
      id: "${map["id"]}",
      type: _enumOf(UArPlaneType.values, map["type"], UArPlaneType.horizontalUp),
      classification: _enumOf(UArPlaneClassification.values, map["classification"], UArPlaneClassification.none),
      pose: UArPose.fromList(map["pose"]),
      width: extent.isNotEmpty ? extent[0] : 0,
      length: extent.length > 1 ? extent[1] : 0,
      polygon: <Offset>[for (int i = 0; i + 1 < polygon.length; i += 2) Offset(polygon[i], polygon[i + 1])],
      tracking: _enumOf(UArTrackingState.values, map["tracking"], UArTrackingState.normal),
      subsumedBy: map["subsumedBy"] as String?,
    );
  }

  final String id;
  final UArPlaneType type;
  final UArPlaneClassification classification;

  /// Centre of the plane; its local Y axis is the surface normal.
  final UArPose pose;
  final double width;
  final double length;

  /// Outline in the plane's local X/Z, metres.
  final List<Offset> polygon;
  final UArTrackingState tracking;
  final String? subsumedBy;

  bool get isHorizontal => type != UArPlaneType.vertical;

  bool get isVertical => type == UArPlaneType.vertical;

  double get area => width * length;
}

class UArAnchor {
  const UArAnchor({required this.id, required this.pose, this.type = UArAnchorType.world, this.tracking = UArTrackingState.normal, this.name, this.cloudId, this.trackableId});

  factory UArAnchor.fromMap(Map<Object?, Object?> map) => UArAnchor(
    id: "${map["id"]}",
    pose: UArPose.fromList(map["pose"]),
    type: _enumOf(UArAnchorType.values, map["type"], UArAnchorType.world),
    tracking: _enumOf(UArTrackingState.values, map["tracking"], UArTrackingState.normal),
    name: map["name"] as String?,
    cloudId: map["cloudId"] as String?,
    trackableId: map["trackableId"] as String?,
  );

  final String id;
  final UArPose pose;
  final UArAnchorType type;
  final UArTrackingState tracking;
  final String? name;
  final String? cloudId;
  final String? trackableId;

  UArAnchor copyWith({UArPose? pose, UArTrackingState? tracking, String? cloudId}) =>
      UArAnchor(id: id, pose: pose ?? this.pose, type: type, tracking: tracking ?? this.tracking, name: name, cloudId: cloudId ?? this.cloudId, trackableId: trackableId);
}

class UArHitResult {
  const UArHitResult({required this.pose, required this.distance, required this.type, this.trackableId, this.planeType, this.classification = UArPlaneClassification.none});

  factory UArHitResult.fromMap(Map<Object?, Object?> map) => UArHitResult(
    pose: UArPose.fromList(map["pose"]),
    distance: _d(map["distance"]),
    type: _enumOf(UArHitType.values, map["type"], UArHitType.estimated),
    trackableId: map["trackableId"] as String?,
    planeType: map["planeType"] == null ? null : _enumOf(UArPlaneType.values, map["planeType"], UArPlaneType.horizontalUp),
    classification: _enumOf(UArPlaneClassification.values, map["classification"], UArPlaneClassification.none),
  );

  final UArPose pose;
  final double distance;
  final UArHitType type;
  final String? trackableId;
  final UArPlaneType? planeType;
  final UArPlaneClassification classification;

  bool get isWall => planeType == UArPlaneType.vertical || classification == UArPlaneClassification.wall;

  bool get isFloor => classification == UArPlaneClassification.floor || (planeType == UArPlaneType.horizontalUp && classification == UArPlaneClassification.none);

  bool get isTable => classification == UArPlaneClassification.table;

  bool get isCeiling => planeType == UArPlaneType.horizontalDown || classification == UArPlaneClassification.ceiling;
}

class UArNodeHit {
  const UArNodeHit({required this.nodeId, required this.position, this.distance = 0});

  factory UArNodeHit.fromMap(Map<Object?, Object?> map) => UArNodeHit(nodeId: "${map["id"]}", position: UArVector3.fromList(_doubles(map["position"])), distance: _d(map["distance"]));

  final String nodeId;
  final UArVector3 position;
  final double distance;
}

class UArNodeInfo {
  const UArNodeInfo({required this.id, this.min = UArVector3.zero, this.max = UArVector3.zero, this.animations = const <String>[]});

  factory UArNodeInfo.fromMap(Map<Object?, Object?> map) => UArNodeInfo(
    id: "${map["id"]}",
    min: UArVector3.fromList(_doubles(map["min"])),
    max: UArVector3.fromList(_doubles(map["max"])),
    animations: map["animations"] is List<Object?> ? (map["animations"]! as List<Object?>).map((Object? e) => "$e").toList(growable: false) : const <String>[],
  );

  final String id;

  /// World-space bounds right after loading.
  final UArVector3 min;
  final UArVector3 max;
  final List<String> animations;

  UArVector3 get size => max - min;

  UArVector3 get center => min.lerp(max, 0.5);

  double get radius => size.length / 2;
}

class UArLightEstimate {
  const UArLightEstimate({
    this.intensity = 1,
    this.colorTemperature = 6500,
    this.colorCorrection = const <double>[1, 1, 1, 1],
    this.direction,
    this.mainIntensity,
    this.sphericalHarmonics = const <double>[],
  });

  factory UArLightEstimate.fromMap(Map<Object?, Object?> map) {
    final List<double> direction = _doubles(map["direction"]);
    final List<double> main = _doubles(map["mainIntensity"]);
    final List<double> correction = _doubles(map["colorCorrection"]);
    return UArLightEstimate(
      intensity: _d(map["intensity"], 1),
      colorTemperature: _d(map["colorTemperature"], 6500),
      colorCorrection: correction.length == 4 ? correction : const <double>[1, 1, 1, 1],
      direction: direction.length == 3 ? UArVector3.fromList(direction) : null,
      mainIntensity: main.length == 3 ? UArVector3.fromList(main) : null,
      sphericalHarmonics: _doubles(map["sh"]),
    );
  }

  /// 0..1-ish scene brightness (ARCore pixel intensity / ARKit lumens ÷ 1000).
  final double intensity;
  final double colorTemperature;
  final List<double> colorCorrection;
  final UArVector3? direction;
  final UArVector3? mainIntensity;
  final List<double> sphericalHarmonics;

  bool get isDark => intensity < 0.25;
}

class UArGeoPose {
  const UArGeoPose({
    this.latitude = 0,
    this.longitude = 0,
    this.altitude = 0,
    this.heading = 0,
    this.horizontalAccuracy = -1,
    this.verticalAccuracy = -1,
    this.headingAccuracy = -1,
    this.state = "",
    this.tracking = UArTrackingState.notAvailable,
    this.source = "gps",
  });

  factory UArGeoPose.fromMap(Map<Object?, Object?> map) => UArGeoPose(
    latitude: _d(map["latitude"]),
    longitude: _d(map["longitude"]),
    altitude: _d(map["altitude"]),
    heading: _d(map["heading"]),
    horizontalAccuracy: _d(map["horizontalAccuracy"], -1),
    verticalAccuracy: _d(map["verticalAccuracy"], -1),
    headingAccuracy: _d(map["headingAccuracy"], -1),
    state: (map["state"] as String?) ?? "",
    tracking: _enumOf(UArTrackingState.values, map["tracking"], UArTrackingState.notAvailable),
    source: (map["source"] as String?) ?? "gps",
  );

  final double latitude;
  final double longitude;
  final double altitude;

  /// Degrees clockwise from true north the camera faces.
  final double heading;
  final double horizontalAccuracy;
  final double verticalAccuracy;
  final double headingAccuracy;
  final String state;
  final UArTrackingState tracking;

  /// "vps", "geoTracking" or "gps".
  final String source;

  bool get isTracking => tracking == UArTrackingState.normal;

  bool get isPrecise => horizontalAccuracy >= 0 && horizontalAccuracy < 5 && headingAccuracy >= 0 && headingAccuracy < 10;
}

class UArTrackedImage {
  const UArTrackedImage({required this.name, required this.pose, this.index = 0, this.width = 0, this.height = 0, this.tracking = UArTrackingState.normal});

  factory UArTrackedImage.fromMap(Map<Object?, Object?> map) => UArTrackedImage(
    name: "${map["name"]}",
    index: _i(map["index"]),
    pose: UArPose.fromList(map["pose"]),
    width: _d(map["width"]),
    height: _d(map["height"]),
    tracking: _enumOf(UArTrackingState.values, map["tracking"], UArTrackingState.normal),
  );

  final String name;
  final int index;

  /// Centre of the image; local Y is the image normal, X along its width.
  final UArPose pose;
  final double width;
  final double height;
  final UArTrackingState tracking;

  String get anchorId => "image:$name";

  bool get isTracking => tracking == UArTrackingState.normal;
}

class UArFace {
  const UArFace({required this.id, required this.pose, this.regions = const <String, UArPose>{}, this.blendShapes = const <String, double>{}, this.lookAt});

  factory UArFace.fromMap(Map<Object?, Object?> map) {
    final Map<Object?, Object?> regions = _map(map["regions"]);
    final Map<Object?, Object?> shapes = _map(map["blendShapes"]);
    final List<double> look = _doubles(map["lookAt"]);
    return UArFace(
      id: "${map["id"]}",
      pose: UArPose.fromList(map["pose"]),
      regions: <String, UArPose>{for (final MapEntry<Object?, Object?> e in regions.entries) "${e.key}": UArPose.fromList(e.value)},
      blendShapes: <String, double>{for (final MapEntry<Object?, Object?> e in shapes.entries) "${e.key}": _d(e.value)},
      lookAt: look.length == 3 ? UArVector3.fromList(look) : null,
    );
  }

  final String id;
  final UArPose pose;

  /// noseTip, foreheadLeft, foreheadRight (Android); leftEye, rightEye (iOS).
  final Map<String, UArPose> regions;

  /// ARKit blend shapes, 0..1 (eyeBlinkLeft, jawOpen, mouthSmileLeft, …).
  final Map<String, double> blendShapes;
  final UArVector3? lookAt;

  String get anchorId => "face:$id";

  double shape(String name) => blendShapes[name] ?? 0;
}

class UArBody {
  const UArBody({required this.pose, this.joints = const <String, UArVector3>{}, this.screenJoints = const <String, Offset>{}});

  factory UArBody.fromMap(Map<Object?, Object?> map) {
    final Map<Object?, Object?> joints = _map(map["joints"]);
    final Map<Object?, Object?> screen = _map(map["screen"]);
    return UArBody(
      pose: UArPose.fromList(map["pose"]),
      joints: <String, UArVector3>{for (final MapEntry<Object?, Object?> e in joints.entries) "${e.key}": UArVector3.fromList(_doubles(e.value))},
      screenJoints: <String, Offset>{
        for (final MapEntry<Object?, Object?> e in screen.entries)
          if (_doubles(e.value).length == 2) "${e.key}": Offset(_doubles(e.value)[0], _doubles(e.value)[1]),
      },
    );
  }

  final UArPose pose;

  /// World positions of the skeleton joints.
  final Map<String, UArVector3> joints;

  /// Joints projected to the view, normalised 0..1.
  final Map<String, Offset> screenJoints;
}

/// Where a tracked world point lands on the view, normalised 0..1.
class UArProjection {
  const UArProjection({required this.id, required this.x, required this.y, required this.distance, required this.visibility});

  final String id;
  final double x;
  final double y;
  final double distance;

  /// 1 on screen, 0 in front but outside the view, -1 behind the camera.
  final int visibility;

  bool get isVisible => visibility == 1;

  bool get isBehind => visibility < 0;

  Offset toOffset(Size size) => Offset(x * size.width, y * size.height);
}

class UArFrame {
  const UArFrame({
    this.timestamp = 0,
    this.camera = UArPose.identity,
    this.fov = 60,
    this.light,
    this.geo,
    this.centerHit,
    this.northYaw,
    this.heading,
    this.headingAccuracy,
    this.semantics = const <String, double>{},
    this.projections = const <String, UArProjection>{},
  });

  factory UArFrame.fromMap(Map<Object?, Object?> map) {
    final Map<String, UArProjection> projections = <String, UArProjection>{};
    final Object? raw = map["projections"];
    if (raw is List<Object?>) {
      for (final Object? entry in raw) {
        if (entry is! List<Object?> || entry.length < 5) continue;
        final String id = "${entry[0]}";
        projections[id] = UArProjection(id: id, x: _d(entry[1]), y: _d(entry[2]), distance: _d(entry[3]), visibility: _i(entry[4]));
      }
    }
    final Map<Object?, Object?> semantics = _map(map["semantics"]);
    return UArFrame(
      timestamp: _d(map["t"]),
      camera: UArPose.fromList(map["camera"]),
      fov: _d(map["fov"], 60),
      light: map["light"] is Map<Object?, Object?> ? UArLightEstimate.fromMap(_map(map["light"])) : null,
      geo: map["geo"] is Map<Object?, Object?> ? UArGeoPose.fromMap(_map(map["geo"])) : null,
      centerHit: map["center"] is Map<Object?, Object?> ? UArHitResult.fromMap(_map(map["center"])) : null,
      northYaw: map["northYaw"] is num ? _d(map["northYaw"]) : null,
      heading: map["heading"] is num ? _d(map["heading"]) : null,
      headingAccuracy: map["headingAccuracy"] is num ? _d(map["headingAccuracy"]) : null,
      semantics: <String, double>{for (final MapEntry<Object?, Object?> e in semantics.entries) "${e.key}": _d(e.value)},
      projections: projections,
    );
  }

  final double timestamp;
  final UArPose camera;

  /// Vertical field of view in degrees.
  final double fov;
  final UArLightEstimate? light;
  final UArGeoPose? geo;

  /// Where the screen centre meets a surface, when [UArConfig.reticle] is on.
  final UArHitResult? centerHit;

  /// Rotation (radians) from an east/up/south frame into world space, when known.
  final double? northYaw;

  /// Compass heading of the camera, degrees clockwise from true north, when known.
  final double? heading;
  final double? headingAccuracy;

  /// Fraction of the view covered by each outdoor label (sky, building, …).
  final Map<String, double> semantics;
  final Map<String, UArProjection> projections;
}

class UArTextResult {
  const UArTextResult({required this.text, this.confidence = 1, this.corners = const <Offset>[]});

  factory UArTextResult.fromMap(Map<Object?, Object?> map) => UArTextResult(text: "${map["text"]}", confidence: _d(map["confidence"], 1), corners: _offsets(map["corners"]));

  final String text;
  final double confidence;

  /// Outline in view coordinates, normalised 0..1.
  final List<Offset> corners;

  Offset get center => _centerOf(corners);
}

class UArCodeResult {
  const UArCodeResult({required this.text, required this.format, this.corners = const <Offset>[]});

  factory UArCodeResult.fromMap(Map<Object?, Object?> map) => UArCodeResult(text: "${map["text"]}", format: "${map["format"]}", corners: _offsets(map["corners"]));

  final String text;
  final String format;

  /// Outline in view coordinates, normalised 0..1.
  final List<Offset> corners;

  Offset get center => _centerOf(corners);
}

List<Offset> _offsets(Object? raw) {
  final List<double> list = _doubles(raw);
  return <Offset>[for (int i = 0; i + 1 < list.length; i += 2) Offset(list[i], list[i + 1])];
}

Offset _centerOf(List<Offset> points) {
  if (points.isEmpty) return const Offset(0.5, 0.5);
  double x = 0;
  double y = 0;
  for (final Offset p in points) {
    x += p.dx;
    y += p.dy;
  }
  return Offset(x / points.length, y / points.length);
}

/// A grayscale copy of the current camera frame.
class UArCameraImage {
  const UArCameraImage({required this.bytes, required this.width, required this.height, required this.stride, required this.transform});

  factory UArCameraImage.fromMap(Map<Object?, Object?> map) => UArCameraImage(
    bytes: (map["bytes"] as Uint8List?) ?? Uint8List(0),
    width: _i(map["width"]),
    height: _i(map["height"]),
    stride: _i(map["stride"]),
    transform: _doubles(map["transform"]),
  );

  final Uint8List bytes;
  final int width;
  final int height;
  final int stride;

  /// Affine image-pixel → normalised-view transform `[a, b, c, d, e, f]`.
  final List<double> transform;

  Offset toView(Offset imagePoint) => transform.length < 6
      ? Offset(imagePoint.dx / max(width, 1), imagePoint.dy / max(height, 1))
      : Offset(
          transform[0] * imagePoint.dx + transform[1] * imagePoint.dy + transform[2],
          transform[3] * imagePoint.dx + transform[4] * imagePoint.dy + transform[5],
        );
}

class UArRecording {
  const UArRecording({this.path, this.bytes, this.mimeType = "video/mp4", this.duration = Duration.zero});

  factory UArRecording.fromMap(Map<Object?, Object?> map) => UArRecording(
    path: map["path"] as String?,
    bytes: map["bytes"] as Uint8List?,
    mimeType: (map["mime"] as String?) ?? "video/mp4",
    duration: Duration(milliseconds: _i(map["duration"])),
  );

  final String? path;

  /// Filled on the web, where there is no file system.
  final Uint8List? bytes;
  final String mimeType;
  final Duration duration;
}

class UArRoomItem {
  const UArRoomItem({required this.kind, required this.category, required this.dimensions, required this.pose, this.confidence = ""});

  factory UArRoomItem.fromMap(String kind, Map<Object?, Object?> map) => UArRoomItem(
    kind: kind,
    category: "${map["category"] ?? kind}",
    dimensions: UArVector3.fromList(_doubles(map["dimensions"])),
    pose: UArPose.fromList(map["pose"]),
    confidence: "${map["confidence"] ?? ""}",
  );

  /// wall, door, window, opening, floor or object.
  final String kind;

  /// For objects: bed, sofa, table, storage, refrigerator, …
  final String category;

  /// Width, height, depth in metres.
  final UArVector3 dimensions;
  final UArPose pose;
  final String confidence;

  double get area => dimensions.x * dimensions.y;
}

class UArRoomScanResult {
  const UArRoomScanResult({this.usdzPath, this.jsonPath, this.items = const <UArRoomItem>[]});

  factory UArRoomScanResult.fromMap(Map<Object?, Object?> map) {
    final List<UArRoomItem> items = <UArRoomItem>[];
    for (final String kind in <String>["wall", "door", "window", "opening", "floor", "object"]) {
      items.addAll(_maps(map["${kind}s"]).map((Map<Object?, Object?> e) => UArRoomItem.fromMap(kind, e)));
    }
    return UArRoomScanResult(usdzPath: map["usdz"] as String?, jsonPath: map["json"] as String?, items: items);
  }

  final String? usdzPath;
  final String? jsonPath;
  final List<UArRoomItem> items;

  List<UArRoomItem> get walls => items.where((UArRoomItem i) => i.kind == "wall").toList(growable: false);

  List<UArRoomItem> get doors => items.where((UArRoomItem i) => i.kind == "door").toList(growable: false);

  List<UArRoomItem> get windows => items.where((UArRoomItem i) => i.kind == "window").toList(growable: false);

  List<UArRoomItem> get objects => items.where((UArRoomItem i) => i.kind == "object").toList(growable: false);

  /// Floor area in square metres, from the scanned floor or the walls' footprint.
  double get floorArea {
    final List<UArRoomItem> floors = items.where((UArRoomItem i) => i.kind == "floor").toList(growable: false);
    if (floors.isNotEmpty) return floors.fold(0, (double sum, UArRoomItem f) => sum + f.dimensions.x * max(f.dimensions.y, f.dimensions.z));
    return 0;
  }
}

class UArObjectCaptureResult {
  const UArObjectCaptureResult({this.modelPath, this.imagesPath});

  factory UArObjectCaptureResult.fromMap(Map<Object?, Object?> map) => UArObjectCaptureResult(modelPath: map["model"] as String?, imagesPath: map["images"] as String?);

  /// The reconstructed USDZ.
  final String? modelPath;

  /// The captured photos, reusable for a server-side reconstruction.
  final String? imagesPath;
}

class UArValue {
  const UArValue({
    this.state = UArSessionState.uninitialized,
    this.tracking = UArTrackingState.notAvailable,
    this.trackingReason = UArTrackingReason.initializing,
    this.capabilities = const UArCapabilities(),
    this.config = const UArConfig(),
    this.planes = const <String, UArPlane>{},
    this.anchors = const <String, UArAnchor>{},
    this.nodes = const <String, UArNode>{},
    this.images = const <String, UArTrackedImage>{},
    this.faces = const <String, UArFace>{},
    this.body,
    this.frame = const UArFrame(),
    this.textureId,
    this.viewType,
    this.isRecording = false,
    this.isXrActive = false,
    this.error,
  });

  final UArSessionState state;
  final UArTrackingState tracking;
  final UArTrackingReason trackingReason;
  final UArCapabilities capabilities;
  final UArConfig config;
  final Map<String, UArPlane> planes;
  final Map<String, UArAnchor> anchors;
  final Map<String, UArNode> nodes;
  final Map<String, UArTrackedImage> images;
  final Map<String, UArFace> faces;
  final UArBody? body;
  final UArFrame frame;
  final int? textureId;
  final String? viewType;
  final bool isRecording;

  /// On the web: an immersive WebXR / sensor session is running.
  final bool isXrActive;
  final UArException? error;

  bool get isRunning => state == UArSessionState.running;

  bool get isTracking => tracking == UArTrackingState.normal;

  bool get hasPlanes => planes.isNotEmpty;

  bool get hasHorizontalPlane => planes.values.any((UArPlane p) => p.isHorizontal);

  bool get hasVerticalPlane => planes.values.any((UArPlane p) => p.isVertical);

  UArGeoPose? get geo => frame.geo;

  UArLightEstimate? get light => frame.light;

  UArValue copyWith({
    UArSessionState? state,
    UArTrackingState? tracking,
    UArTrackingReason? trackingReason,
    UArCapabilities? capabilities,
    UArConfig? config,
    Map<String, UArPlane>? planes,
    Map<String, UArAnchor>? anchors,
    Map<String, UArNode>? nodes,
    Map<String, UArTrackedImage>? images,
    Map<String, UArFace>? faces,
    UArBody? body,
    bool clearBody = false,
    UArFrame? frame,
    int? textureId,
    String? viewType,
    bool? isRecording,
    bool? isXrActive,
    UArException? error,
    bool clearError = false,
  }) => UArValue(
    state: state ?? this.state,
    tracking: tracking ?? this.tracking,
    trackingReason: trackingReason ?? this.trackingReason,
    capabilities: capabilities ?? this.capabilities,
    config: config ?? this.config,
    planes: planes ?? this.planes,
    anchors: anchors ?? this.anchors,
    nodes: nodes ?? this.nodes,
    images: images ?? this.images,
    faces: faces ?? this.faces,
    body: clearBody ? null : body ?? this.body,
    frame: frame ?? this.frame,
    textureId: textureId ?? this.textureId,
    viewType: viewType ?? this.viewType,
    isRecording: isRecording ?? this.isRecording,
    isXrActive: isXrActive ?? this.isXrActive,
    error: clearError ? null : error ?? this.error,
  );
}

// =============================================================================
// Channels and static helpers
// =============================================================================

abstract class UArChannel {
  static const MethodChannel _channel = MethodChannel("u/ar");

  static Future<T?> invoke<T>(String method, [Map<String, Object?>? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw UArException.fromPlatform(error);
    } on MissingPluginException {
      throw const UArException(code: UArErrorCode.unsupported, message: "AR is not available on this platform");
    } on UArException {
      rethrow;
    } catch (error) {
      throw UArException(code: UArErrorCode.unknown, message: "$error");
    }
  }

  static Future<Map<Object?, Object?>?> invokeMap(String method, [Map<String, Object?>? arguments]) => invoke<Map<Object?, Object?>>(method, arguments);

  static Future<List<Object?>?> invokeList(String method, [Map<String, Object?>? arguments]) => invoke<List<Object?>>(method, arguments);

  static Stream<Map<Object?, Object?>> events(int sessionId) =>
      EventChannel("u/ar/events/$sessionId").receiveBroadcastStream().map((Object? event) => (event as Map<Object?, Object?>?) ?? const <Object?, Object?>{});
}

class UArNativeViewerOptions {
  const UArNativeViewerOptions({required this.source, this.iosSource, this.title, this.link, this.arFirst = true, this.resizable = true, this.fallbackUrl});

  /// GLB / glTF for Scene Viewer (Android, Android browsers).
  final UArSource source;

  /// USDZ / Reality for AR Quick Look (iOS, iOS Safari).
  final UArSource? iosSource;
  final String? title;

  /// A web page shown as a call-to-action inside the viewer.
  final String? link;

  /// Starts in the camera rather than the 3D preview.
  final bool arFirst;
  final bool resizable;

  /// Opened in the browser when no AR viewer is installed.
  final String? fallbackUrl;

  Map<String, Object?> toMap() => <String, Object?>{
    "source": source.toMap(),
    "iosSource": iosSource?.toMap(),
    "title": title,
    "link": link,
    "arFirst": arFirst,
    "resizable": resizable,
    "fallbackUrl": fallbackUrl,
  };
}

class UArRoomScanOptions {
  const UArRoomScanOptions({this.exportModel = true, this.parametric = true, this.doneLabel, this.cancelLabel});

  final bool exportModel;

  /// Exports clean boxes (walls, furniture) instead of the raw mesh.
  final bool parametric;
  final String? doneLabel;
  final String? cancelLabel;

  Map<String, Object?> toMap() => <String, Object?>{"exportModel": exportModel, "parametric": parametric, "done": doneLabel ?? U.s.done, "cancel": cancelLabel ?? U.s.cancel};
}

class UArObjectCaptureOptions {
  const UArObjectCaptureOptions({this.detail = UArObjectCaptureDetail.reduced, this.labels = const <String, String>{}});

  final UArObjectCaptureDetail detail;

  /// Overrides for the capture screen's buttons: continue, start, finish, cancel, processing.
  final Map<String, String> labels;

  Map<String, Object?> toMap() => <String, Object?>{"detail": detail.name, "labels": labels};
}

/// Device-level AR questions and one-shot native experiences.
abstract class UAr {
  static Future<UArAvailability> availability() async {
    try {
      return UArAvailability.fromMap(await UArChannel.invokeMap("availability") ?? const <Object?, Object?>{});
    } on UArException catch (error) {
      return UArAvailability(status: UArAvailabilityStatus.unsupported, message: error.message);
    }
  }

  static Future<UArCapabilities> capabilities() async => (await availability()).capabilities;

  /// Prompts for "Google Play Services for AR" on Android; no-op elsewhere.
  static Future<UArAvailability> requestInstall() async {
    try {
      return UArAvailability.fromMap(await UArChannel.invokeMap("requestInstall") ?? const <Object?, Object?>{});
    } on UArException catch (error) {
      return UArAvailability(status: UArAvailabilityStatus.unsupported, message: error.message);
    }
  }

  static Future<UArPermissionState> permissionStatus() async {
    try {
      return UArPermissionState.fromMap(await UArChannel.invokeMap("permissionStatus") ?? const <Object?, Object?>{});
    } on UArException {
      return const UArPermissionState();
    }
  }

  static Future<UArPermissionState> requestPermission({bool location = false, bool microphone = false}) async {
    try {
      return UArPermissionState.fromMap(await UArChannel.invokeMap("requestPermission", <String, Object?>{"location": location, "microphone": microphone}) ?? const <Object?, Object?>{});
    } on UArException {
      return const UArPermissionState();
    }
  }

  static Future<bool> openSettings() async {
    try {
      return await UArChannel.invoke<bool>("openSettings") ?? false;
    } on UArException {
      return false;
    }
  }

  /// Hands the model to the system viewer: Scene Viewer on Android, AR Quick
  /// Look on iOS, and either of them from a mobile browser.
  static Future<bool> openNativeViewer(UArNativeViewerOptions options) async {
    try {
      return await UArChannel.invoke<bool>("openNativeViewer", options.toMap()) ?? false;
    } on UArException {
      return false;
    }
  }

  /// Scans a room with LiDAR (iOS 16+ RoomPlan) and returns its layout.
  static Future<UArRoomScanResult?> scanRoom({UArRoomScanOptions options = const UArRoomScanOptions()}) async {
    final Map<Object?, Object?>? raw = await UArChannel.invokeMap("scanRoom", options.toMap());
    return raw == null ? null : UArRoomScanResult.fromMap(raw);
  }

  /// Walks the user around a real object and reconstructs it as a USDZ model
  /// on the device (iOS 17+ Object Capture, LiDAR devices).
  static Future<UArObjectCaptureResult?> captureObject({UArObjectCaptureOptions options = const UArObjectCaptureOptions()}) async {
    final Map<Object?, Object?>? raw = await UArChannel.invokeMap("captureObject", options.toMap());
    return raw == null ? null : UArObjectCaptureResult.fromMap(raw);
  }
}

// =============================================================================
// Controller
// =============================================================================

class _GpsAnchor {
  const _GpsAnchor({required this.latitude, required this.longitude, required this.altitude, required this.altitudeMode, required this.heading});

  final double latitude;
  final double longitude;
  final double altitude;
  final UArAltitudeMode altitudeMode;
  final double heading;
}

class _Track {
  const _Track({this.nodeId, this.anchorId, this.offset = UArVector3.zero});

  final String? nodeId;
  final String? anchorId;
  final UArVector3 offset;

  Map<String, Object?> toMap(String id) => <String, Object?>{"id": id, "nodeId": nodeId, "anchorId": anchorId, "offset": offset.toList()};
}

/// Drives one AR (or 3D viewer) session. Hand it to a [UArView]; the view
/// creates the native session and the controller talks to it.
class UArController extends ValueNotifier<UArValue> {
  UArController({UArConfig config = const UArConfig()}) : super(UArValue(config: config));

  int? _sessionId;
  bool _creating = false;
  bool _disposed = false;
  Size _viewSize = Size.zero;
  double _pixelRatio = 1;
  int _nextId = 1;
  StreamSubscription<Map<Object?, Object?>>? _events;
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;
  UArVector3 _positionOrigin = UArVector3.zero;
  final Map<String, _GpsAnchor> _gpsAnchors = <String, _GpsAnchor>{};
  final Map<String, _Track> _tracks = <String, _Track>{};
  final Map<String, Completer<UArNodeInfo>> _pendingNodes = <String, Completer<UArNodeInfo>>{};
  Completer<void>? _ready;

  final ValueNotifier<Map<String, UArProjection>> projections = ValueNotifier<Map<String, UArProjection>>(const <String, UArProjection>{});
  final StreamController<UArFrame> _frameController = StreamController<UArFrame>.broadcast();
  final StreamController<UArTrackedImage> _imageController = StreamController<UArTrackedImage>.broadcast();
  final StreamController<Uint8List> _collaborationController = StreamController<Uint8List>.broadcast();
  final StreamController<Map<String, Object?>> _nodeEventController = StreamController<Map<String, Object?>>.broadcast();
  final StreamController<UArException> _errorController = StreamController<UArException>.broadcast();

  int? get sessionId => _sessionId;

  UArConfig get config => value.config;

  bool get isDisposed => _disposed;

  Size get viewSize => _viewSize;

  Stream<UArFrame> get frames => _frameController.stream;

  /// Every image detection or update, including when tracking is lost.
  Stream<UArTrackedImage> get imageEvents => _imageController.stream;

  /// ARKit collaboration packets to send to the other devices.
  Stream<Uint8List> get collaborationData => _collaborationController.stream;

  /// Node events: `{"id", "event": loaded | animationEnded | videoEnded | error, "message"}`.
  Stream<Map<String, Object?>> get nodeEvents => _nodeEventController.stream;

  Stream<UArException> get errors => _errorController.stream;

  /// Resolves once the native session has started.
  Future<void> get ready => (_ready ??= Completer<void>()).future;

  String newId([String prefix = "n"]) => "$prefix${DateTime.now().microsecondsSinceEpoch}_${_nextId++}";

  // ---------------------------------------------------------------------------
  // Lifecycle (driven by UArView)
  // ---------------------------------------------------------------------------

  Future<void> attachSurface(Size size, double pixelRatio) async {
    final bool changed = size != _viewSize || pixelRatio != _pixelRatio;
    _viewSize = size;
    _pixelRatio = pixelRatio;
    if (_disposed || size.isEmpty) return;
    if (_sessionId != null) {
      if (changed) await _safe(() => _invoke("resize", _sizeArgs()));
      return;
    }
    if (_creating || defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb) return;
    _creating = true;
    value = value.copyWith(state: UArSessionState.initializing);
    try {
      final Map<Object?, Object?> raw = await UArChannel.invokeMap("create", <String, Object?>{"config": config.toMap(), ..._sizeArgs()}) ?? const <Object?, Object?>{};
      final int id = _i(raw["sessionId"], -1);
      if (id < 0) throw const UArException(code: UArErrorCode.sessionFailed, message: "No session id");
      value = value.copyWith(textureId: raw["textureId"] is num ? _i(raw["textureId"]) : null, viewType: raw["viewType"] as String?);
      await _start(id);
    } on UArException catch (error) {
      _fail(error);
    } finally {
      _creating = false;
    }
  }

  /// Called by [UArView] once the iOS platform view exists.
  Future<void> attachPlatformView(int viewId) async {
    if (_disposed) return;
    value = value.copyWith(state: UArSessionState.initializing);
    try {
      await _start(viewId);
    } on UArException catch (error) {
      _fail(error);
    }
  }

  Future<void> _start(int id) async {
    if (_disposed) {
      await _safe(() => UArChannel.invoke<void>("dispose", <String, Object?>{"sessionId": id}));
      return;
    }
    _sessionId = id;
    _events = UArChannel.events(id).listen(
      _onEvent,
      onError: (Object error) => _fail(UArException(code: UArErrorCode.sessionFailed, message: "$error")),
    );
    final Map<Object?, Object?> raw = await UArChannel.invokeMap("start", <String, Object?>{"sessionId": id, ..._sizeArgs()}) ?? const <Object?, Object?>{};
    value = value.copyWith(state: UArSessionState.running, capabilities: UArCapabilities.fromMap(_map(raw["capabilities"])), clearError: true);
    if (_tracks.isNotEmpty) await _pushTracks();
    final Completer<void> ready = _ready ??= Completer<void>();
    if (!ready.isCompleted) ready.complete();
  }

  Map<String, Object?> _sizeArgs() => <String, Object?>{"width": _viewSize.width, "height": _viewSize.height, "pixelRatio": _pixelRatio};

  void _fail(UArException error) {
    if (_disposed) return;
    value = value.copyWith(state: UArSessionState.error, error: error);
    _errorController.add(error);
    final Completer<void>? ready = _ready;
    if (ready != null && !ready.isCompleted && _sessionId == null) ready.completeError(error);
  }

  /// Called by [UArView] on platforms with no AR / 3D support.
  void reportUnsupported() {
    if (value.state == UArSessionState.error) return;
    _fail(const UArException(code: UArErrorCode.unsupported, message: "AR and 3D are not available on this platform"));
  }

  Future<T?> _invoke<T>(String method, [Map<String, Object?> arguments = const <String, Object?>{}]) {
    final int? id = _sessionId;
    if (id == null) throw const UArException(code: UArErrorCode.notFound, message: "The AR session has not started yet");
    return UArChannel.invoke<T>(method, <String, Object?>{...arguments, "sessionId": id});
  }

  Future<void> _safe(Future<Object?> Function() call) async {
    try {
      await call();
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final int? id = _sessionId;
    _sessionId = null;
    unawaited(_events?.cancel());
    unawaited(_positionSubscription?.cancel());
    if (id != null) unawaited(_safe(() => UArChannel.invoke<void>("dispose", <String, Object?>{"sessionId": id})));
    for (final Completer<UArNodeInfo> pending in _pendingNodes.values) {
      if (!pending.isCompleted) pending.completeError(const UArException(code: UArErrorCode.cancelled, message: "Disposed"));
    }
    _pendingNodes.clear();
    unawaited(_frameController.close());
    unawaited(_imageController.close());
    unawaited(_collaborationController.close());
    unawaited(_nodeEventController.close());
    unawaited(_errorController.close());
    projections.dispose();
    value = value.copyWith(state: UArSessionState.disposed);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  void _onEvent(Map<Object?, Object?> event) {
    if (_disposed) return;
    switch (event["type"]) {
      case "state":
        value = value.copyWith(
          tracking: _enumOf(UArTrackingState.values, event["tracking"], value.tracking),
          trackingReason: _enumOf(UArTrackingReason.values, event["reason"], UArTrackingReason.none),
          state: event["session"] == "paused" ? UArSessionState.paused : (event["session"] == "running" ? UArSessionState.running : null),
          isXrActive: event["xr"] is bool ? event["xr"]! as bool : null,
        );
      case "frame":
        final UArFrame frame = UArFrame.fromMap(event);
        value = value.copyWith(frame: frame);
        if (frame.projections.isNotEmpty || projections.value.isNotEmpty) projections.value = frame.projections;
        _frameController.add(frame);
      case "planes":
        final Map<String, UArPlane> planes = Map<String, UArPlane>.of(value.planes);
        for (final Map<Object?, Object?> raw in _maps(event["updated"])) {
          final UArPlane plane = UArPlane.fromMap(raw);
          planes[plane.id] = plane;
        }
        for (final Object? id in (event["removed"] as List<Object?>?) ?? const <Object?>[]) {
          planes.remove("$id");
        }
        value = value.copyWith(planes: planes);
      case "anchors":
        final Map<String, UArAnchor> anchors = Map<String, UArAnchor>.of(value.anchors);
        for (final Map<Object?, Object?> raw in _maps(event["updated"])) {
          final UArAnchor anchor = UArAnchor.fromMap(raw);
          anchors[anchor.id] = anchor;
        }
        for (final Object? id in (event["removed"] as List<Object?>?) ?? const <Object?>[]) {
          anchors.remove("$id");
        }
        value = value.copyWith(anchors: anchors);
      case "images":
        final Map<String, UArTrackedImage> images = Map<String, UArTrackedImage>.of(value.images);
        for (final Map<Object?, Object?> raw in _maps(event["updated"])) {
          final UArTrackedImage image = UArTrackedImage.fromMap(raw);
          images[image.name] = image;
          _imageController.add(image);
        }
        value = value.copyWith(images: images);
      case "faces":
        final Map<String, UArFace> faces = Map<String, UArFace>.of(value.faces);
        for (final Map<Object?, Object?> raw in _maps(event["updated"])) {
          final UArFace face = UArFace.fromMap(raw);
          faces[face.id] = face;
        }
        for (final Object? id in (event["removed"] as List<Object?>?) ?? const <Object?>[]) {
          faces.remove("$id");
        }
        value = value.copyWith(faces: faces);
      case "body":
        value = event["body"] is Map<Object?, Object?> ? value.copyWith(body: UArBody.fromMap(_map(event["body"]))) : value.copyWith(clearBody: true);
      case "collaboration":
        final Object? data = event["data"];
        if (data is Uint8List) _collaborationController.add(data);
      case "node":
        final String id = "${event["id"]}";
        final String kind = "${event["event"]}";
        final Completer<UArNodeInfo>? pending = _pendingNodes.remove(id);
        if (pending != null && !pending.isCompleted) {
          if (kind == "error") {
            pending.completeError(UArException(code: UArErrorCode.loadFailed, message: "${event["message"] ?? "Load failed"}"));
          } else {
            pending.complete(UArNodeInfo.fromMap(event));
          }
        }
        _nodeEventController.add(<String, Object?>{"id": id, "event": kind, "message": event["message"]});
      case "error":
        _errorController.add(UArException(code: _enumOf(UArErrorCode.values, event["code"], UArErrorCode.unknown), message: "${event["message"] ?? ""}"));
      case "config":
        value = value.copyWith(capabilities: UArCapabilities.fromMap(_map(event["capabilities"])));
    }
  }

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------

  Future<void> pause() async {
    await _invoke<void>("pause");
    value = value.copyWith(state: UArSessionState.paused);
  }

  Future<void> resume() async {
    await _invoke<void>("resume");
    value = value.copyWith(state: UArSessionState.running);
  }

  /// Restarts tracking. Anchors and nodes are dropped unless kept.
  Future<void> reset({bool keepNodes = false}) async {
    await _invoke<void>("reset", <String, Object?>{"keepNodes": keepNodes});
    value = value.copyWith(planes: const <String, UArPlane>{}, anchors: const <String, UArAnchor>{}, images: const <String, UArTrackedImage>{}, nodes: keepNodes ? null : const <String, UArNode>{});
    _gpsAnchors.clear();
  }

  Future<void> updateConfig(UArConfig config) async {
    value = value.copyWith(config: config);
    if (_sessionId != null) await _invoke<void>("updateConfig", <String, Object?>{"config": config.toMap()});
  }

  /// Web only: starts the immersive WebXR (or camera + compass) session. Must be
  /// called from a user gesture such as a button tap.
  Future<bool> enterXr() async {
    final bool ok = await _invoke<bool>("enterXr") ?? false;
    value = value.copyWith(isXrActive: ok);
    return ok;
  }

  Future<void> exitXr() async {
    await _invoke<void>("exitXr");
    value = value.copyWith(isXrActive: false);
  }

  // ---------------------------------------------------------------------------
  // Hit testing
  // ---------------------------------------------------------------------------

  Offset _normalize(Offset point) => _viewSize.isEmpty ? const Offset(0.5, 0.5) : Offset(point.dx / _viewSize.width, point.dy / _viewSize.height);

  /// Real-world surfaces under a point of the view (logical pixels), nearest first.
  Future<List<UArHitResult>> hitTest(
    Offset point, {
    List<UArHitType> types = const <UArHitType>[UArHitType.plane, UArHitType.depth, UArHitType.point, UArHitType.estimated, UArHitType.instant, UArHitType.mesh],
  }) async {
    final Offset n = _normalize(point);
    final List<Object?>? raw = await _invoke<List<Object?>>("hitTest", <String, Object?>{"x": n.dx, "y": n.dy, "types": types.map((UArHitType t) => t.name).toList(growable: false)});
    return _maps(raw).map(UArHitResult.fromMap).toList(growable: false);
  }

  /// Same as [hitTest] from the middle of the view.
  Future<List<UArHitResult>> hitTestCenter({
    List<UArHitType> types = const <UArHitType>[UArHitType.plane, UArHitType.depth, UArHitType.point, UArHitType.estimated, UArHitType.instant, UArHitType.mesh],
  }) => hitTest(Offset(_viewSize.width / 2, _viewSize.height / 2), types: types);

  /// The node under a point of the view, if any.
  Future<UArNodeHit?> hitTestNodes(Offset point) async {
    final Offset n = _normalize(point);
    final Map<Object?, Object?>? raw = await _invoke<Map<Object?, Object?>>("hitTestNodes", <String, Object?>{"x": n.dx, "y": n.dy});
    return raw == null || raw["id"] == null ? null : UArNodeHit.fromMap(raw);
  }

  // ---------------------------------------------------------------------------
  // Anchors
  // ---------------------------------------------------------------------------

  Future<UArAnchor> addAnchor(UArPose pose, {String? id, String? trackableId, String? name}) async {
    final String anchorId = id ?? newId("a");
    final Map<Object?, Object?>? raw = await _invoke<Map<Object?, Object?>>("addAnchor", <String, Object?>{"id": anchorId, "pose": pose.toList(), "trackableId": trackableId, "name": name});
    final UArAnchor anchor = raw == null ? UArAnchor(id: anchorId, pose: pose) : UArAnchor.fromMap(raw);
    value = value.copyWith(anchors: <String, UArAnchor>{...value.anchors, anchor.id: anchor});
    return anchor;
  }

  /// Anchors to the surface of a hit, so the content follows plane refinements.
  Future<UArAnchor> addAnchorAtHit(UArHitResult hit, {String? id, bool faceCamera = true}) {
    UArPose pose = hit.pose;
    if (faceCamera && !hit.isWall) {
      final UArVector3 toCamera = value.frame.camera.position - hit.pose.position;
      pose = UArPose(position: hit.pose.position, rotation: UArQuaternion.yaw(atan2(toCamera.x, toCamera.z)));
    }
    return addAnchor(pose, id: id, trackableId: hit.trackableId);
  }

  /// Moves an existing anchor; attached nodes follow.
  Future<void> updateAnchor(String id, UArPose pose) async {
    await _invoke<void>("updateAnchor", <String, Object?>{"id": id, "pose": pose.toList()});
    final UArAnchor? anchor = value.anchors[id];
    if (anchor != null) {
      value = value.copyWith(
        anchors: <String, UArAnchor>{
          ...value.anchors,
          id: anchor.copyWith(pose: pose),
        },
      );
    }
  }

  Future<void> removeAnchor(String id, {bool removeNodes = true}) async {
    await _invoke<void>("removeAnchor", <String, Object?>{"id": id, "removeNodes": removeNodes});
    _gpsAnchors.remove(id);
    final Map<String, UArAnchor> anchors = Map<String, UArAnchor>.of(value.anchors)..remove(id);
    final Map<String, UArNode> nodes = removeNodes ? (Map<String, UArNode>.of(value.nodes)..removeWhere((String _, UArNode n) => n.anchorId == id)) : value.nodes;
    value = value.copyWith(anchors: anchors, nodes: nodes);
  }

  // ---------------------------------------------------------------------------
  // Nodes
  // ---------------------------------------------------------------------------

  /// Adds (or replaces) a node. Completes when the model or texture is loaded.
  Future<UArNodeInfo> addNode(UArNode node) async {
    final Completer<UArNodeInfo> completer = Completer<UArNodeInfo>();
    _pendingNodes[node.id] = completer;
    value = value.copyWith(nodes: <String, UArNode>{...value.nodes, node.id: node});
    try {
      final Map<Object?, Object?>? raw = await _invoke<Map<Object?, Object?>>("addNode", <String, Object?>{"node": node.toMap()});
      if (raw != null && raw["loaded"] == true) {
        _pendingNodes.remove(node.id);
        if (!completer.isCompleted) completer.complete(UArNodeInfo.fromMap(raw));
      }
    } on UArException catch (error) {
      _pendingNodes.remove(node.id);
      if (!completer.isCompleted) completer.completeError(error);
    }
    return completer.future.timeout(
      const Duration(seconds: 90),
      onTimeout: () {
        _pendingNodes.remove(node.id);
        throw const UArException(code: UArErrorCode.timeout, message: "Loading the node timed out");
      },
    );
  }

  Future<List<UArNodeInfo>> addNodes(List<UArNode> nodes) => Future.wait(nodes.map(addNode));

  /// Re-sends every property of a node already in the scene.
  Future<void> updateNode(UArNode node) async {
    value = value.copyWith(nodes: <String, UArNode>{...value.nodes, node.id: node});
    await _invoke<void>("updateNode", <String, Object?>{"node": node.toMap()});
  }

  /// Lightweight transform change, cheap enough to call every frame.
  Future<void> transformNode(String id, {UArVector3? position, UArQuaternion? rotation, UArVector3? scale, bool world = false}) async {
    final UArNode? node = value.nodes[id];
    if (node != null && !world) {
      value = value.copyWith(
        nodes: <String, UArNode>{
          ...value.nodes,
          id: node.copyWith(position: position, rotation: rotation, scale: scale),
        },
      );
    }
    await _invoke<void>("transformNode", <String, Object?>{"id": id, "position": position?.toList(), "rotation": rotation?.toList(), "scale": scale?.toList(), "world": world});
  }

  Future<void> setNodeVisible(String id, bool visible) async {
    final UArNode? node = value.nodes[id];
    if (node == null) return;
    await updateNode(node.copyWith(visible: visible));
  }

  Future<void> removeNode(String id) async {
    value = value.copyWith(nodes: Map<String, UArNode>.of(value.nodes)..remove(id));
    await _invoke<void>("removeNode", <String, Object?>{"id": id});
  }

  Future<void> clearNodes() async {
    value = value.copyWith(nodes: const <String, UArNode>{});
    await _invoke<void>("clearNodes");
  }

  /// World pose of a node right now.
  Future<UArPose?> nodePose(String id) async {
    final List<Object?>? raw = await _invoke<List<Object?>>("nodePose", <String, Object?>{"id": id});
    return raw == null ? null : UArPose.fromList(raw);
  }

  Future<void> playAnimation(String nodeId, {String? name, int index = 0, bool loop = true, double speed = 1}) =>
      _invoke<void>("playAnimation", <String, Object?>{"id": nodeId, "name": name, "index": index, "loop": loop, "speed": speed});

  Future<void> stopAnimation(String nodeId) => _invoke<void>("stopAnimation", <String, Object?>{"id": nodeId});

  /// Play / pause / seek a video node.
  Future<void> controlVideo(String nodeId, {bool? play, Duration? seek, double? volume}) =>
      _invoke<void>("controlVideo", <String, Object?>{"id": nodeId, "play": play, "seek": seek?.inMilliseconds, "volume": volume});

  /// Renders a Flutter widget into an image node — info cards, price tags,
  /// labels. [width] is the size in metres; height follows [size]'s aspect.
  Future<UArNodeInfo?> addWidgetNode({
    required String id,
    required Widget child,
    Size size = const Size(320, 200),
    double width = 0.3,
    double pixelRatio = 3,
    BuildContext? context,
    String? anchorId,
    String? parentId,
    UArVector3 position = UArVector3.zero,
    UArQuaternion rotation = UArQuaternion.identity,
    UArBillboard billboard = UArBillboard.yAxis,
    bool renderOnTop = false,
    Duration settle = const Duration(milliseconds: 50),
  }) async {
    final Uint8List? png = await UArWidgetRenderer.render(child, size: size, pixelRatio: pixelRatio, context: context, settle: settle);
    if (png == null) return null;
    return addNode(
      UArNode.image(
        id: id,
        source: UArSource.bytes(png, extension: "png"),
        width: width,
        anchorId: anchorId,
        parentId: parentId,
        position: position,
        rotation: rotation,
        billboard: billboard,
        renderOnTop: renderOnTop,
      ),
    );
  }

  /// Draws a measuring bar between two world points.
  Future<UArNodeInfo> addLine(String id, UArVector3 from, UArVector3 to, {double thickness = 0.004, Color color = const Color(0xFFFFFFFF), bool renderOnTop = true}) =>
      addNode(UArNode.line(id: id, from: from, to: to, thickness: thickness, color: color, renderOnTop: renderOnTop));

  // ---------------------------------------------------------------------------
  // Screen projections (anchor Flutter widgets to the world)
  // ---------------------------------------------------------------------------

  /// Reports every frame where a node, an anchor or a world point lands on the
  /// view, through [projections]. [offset] is local to the node / anchor.
  Future<void> track(String id, {String? nodeId, String? anchorId, UArVector3 offset = UArVector3.zero}) async {
    _tracks[id] = _Track(nodeId: nodeId, anchorId: anchorId, offset: offset);
    if (_sessionId != null) await _pushTracks();
  }

  Future<void> untrack(String id) async {
    if (_tracks.remove(id) == null) return;
    projections.value = Map<String, UArProjection>.of(projections.value)..remove(id);
    if (_sessionId != null) await _pushTracks();
  }

  Future<void> clearTracks() async {
    _tracks.clear();
    projections.value = const <String, UArProjection>{};
    if (_sessionId != null) await _pushTracks();
  }

  Future<void> _pushTracks() => _invoke<void>("setTracks", <String, Object?>{
    "tracks": <Map<String, Object?>>[for (final MapEntry<String, _Track> e in _tracks.entries) e.value.toMap(e.key)],
  });

  // ---------------------------------------------------------------------------
  // Viewer camera
  // ---------------------------------------------------------------------------

  Future<void> setOrbit(UArOrbit orbit) async {
    value = value.copyWith(config: value.config.copyWith(orbit: orbit));
    if (_sessionId != null) await _invoke<void>("setOrbit", <String, Object?>{"orbit": orbit.toMap()});
  }

  // ---------------------------------------------------------------------------
  // Capture
  // ---------------------------------------------------------------------------

  Future<Uint8List?> takeSnapshot({UArImageFormat format = UArImageFormat.jpeg, int quality = 92}) => _invoke<Uint8List>("snapshot", <String, Object?>{"format": format.name, "quality": quality});

  Future<void> startRecording({bool audio = false}) async {
    await _invoke<void>("startRecording", <String, Object?>{"audio": audio});
    value = value.copyWith(isRecording: true);
  }

  Future<UArRecording?> stopRecording() async {
    final Map<Object?, Object?>? raw = await _invoke<Map<Object?, Object?>>("stopRecording");
    value = value.copyWith(isRecording: false);
    return raw == null ? null : UArRecording.fromMap(raw);
  }

  Future<UArCameraImage?> cameraImage({int maxSize = 1024}) async {
    final Map<Object?, Object?>? raw = await _invoke<Map<Object?, Object?>>("cameraImage", <String, Object?>{"maxSize": maxSize});
    return raw == null ? null : UArCameraImage.fromMap(raw);
  }

  /// Reads QR codes and barcodes in view — Apple Vision on iOS, the bundled
  /// Dart decoder on the camera frame elsewhere.
  Future<List<UArCodeResult>> detectCodes({UCodeScanOptions options = const UCodeScanOptions(multiple: true)}) async {
    if (value.capabilities.barcodeDetection) {
      try {
        final List<Object?>? raw = await _invoke<List<Object?>>("detectBarcodes");
        if (raw != null) return _maps(raw).map(UArCodeResult.fromMap).toList(growable: false);
      } on UArException catch (_) {}
    }
    final UArCameraImage? image = await cameraImage();
    if (image == null || image.bytes.isEmpty) return const <UArCodeResult>[];
    final List<UCode> codes = await UCodeScanWorker.decode(image.bytes, image.width, image.height, image.stride, options);
    return codes.map((UCode code) => UArCodeResult(text: code.text, format: code.format.name, corners: code.corners.map(image.toView).toList(growable: false))).toList(growable: false);
  }

  /// Reads text in view (shop signs, labels). iOS only — Apple Vision.
  Future<List<UArTextResult>> recognizeText({List<String> languages = const <String>[], bool accurate = true}) async {
    final List<Object?>? raw = await _invoke<List<Object?>>("recognizeText", <String, Object?>{"languages": languages, "accurate": accurate});
    return _maps(raw).map(UArTextResult.fromMap).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Geo
  // ---------------------------------------------------------------------------

  bool get _useVps => config.geoMode != UArGeoMode.gps && value.capabilities.geospatial;

  /// Pins an anchor to a real-world coordinate. Uses visual positioning when
  /// the device and location support it, else GPS + compass.
  Future<UArAnchor> addGeoAnchor({
    required double latitude,
    required double longitude,
    double altitude = 0,
    UArAltitudeMode altitudeMode = UArAltitudeMode.terrain,
    double heading = 0,
    String? id,
  }) async {
    final String anchorId = id ?? newId("g");
    if (_useVps) {
      try {
        final Map<Object?, Object?>? raw = await _invoke<Map<Object?, Object?>>("addGeoAnchor", <String, Object?>{
          "id": anchorId,
          "latitude": latitude,
          "longitude": longitude,
          "altitude": altitude,
          "altitudeMode": altitudeMode.name,
          "heading": heading,
        });
        if (raw != null) {
          final UArAnchor anchor = UArAnchor.fromMap(raw);
          value = value.copyWith(anchors: <String, UArAnchor>{...value.anchors, anchor.id: anchor});
          return anchor;
        }
      } on UArException {
        if (config.geoMode == UArGeoMode.vps) rethrow;
      }
    }
    final _GpsAnchor target = _GpsAnchor(latitude: latitude, longitude: longitude, altitude: altitude, altitudeMode: altitudeMode, heading: heading);
    _gpsAnchors[anchorId] = target;
    await startLocationUpdates();
    return addAnchor(_gpsPose(target), id: anchorId, name: "geo");
  }

  UArPose _gpsPose(_GpsAnchor target) {
    final Position? here = _lastPosition;
    final UArGeoPose? vps = value.frame.geo;
    final double originLat = vps != null && vps.source != "gps" && vps.isTracking ? vps.latitude : here?.latitude ?? target.latitude;
    final double originLng = vps != null && vps.source != "gps" && vps.isTracking ? vps.longitude : here?.longitude ?? target.longitude;
    final double originAlt = here?.altitude ?? 0;
    final UArVector3 enu = UArGeo.enu(originLat, originLng, target.latitude, target.longitude);
    final double cameraY = value.frame.camera.position.y;
    final double y = switch (target.altitudeMode) {
      UArAltitudeMode.absolute => here == null ? cameraY : cameraY + target.altitude - originAlt,
      _ => cameraY - 1.4 + target.altitude,
    };
    final double northYaw = value.frame.northYaw ?? 0;
    final UArVector3 world = UArGeo.enuToWorld(UArVector3(enu.x, 0, enu.z), northYaw: northYaw, origin: _positionOrigin);
    return UArPose(position: UArVector3(world.x, y, world.z), rotation: UArQuaternion.yaw(northYaw - target.heading * pi / 180));
  }

  /// Streams the device position for GPS placement. Started automatically.
  Future<void> startLocationUpdates({int distanceFilter = 1}) async {
    if (_positionSubscription != null) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const UArException(code: UArErrorCode.permission, message: "Location permission is required");
    }
    _positionSubscription = Geolocator.getPositionStream(locationSettings: LocationSettings(distanceFilter: distanceFilter)).listen(_onPosition);
    try {
      _onPosition(await Geolocator.getCurrentPosition());
    } catch (_) {}
  }

  void _onPosition(Position position) {
    final Position? previous = _lastPosition;
    final bool better = previous == null || position.accuracy <= previous.accuracy + 2;
    if (!better) return;
    _lastPosition = position;
    _positionOrigin = value.frame.camera.position;
    unawaited(
      _safe(() => _invoke<void>("updateLocation", <String, Object?>{"latitude": position.latitude, "longitude": position.longitude, "altitude": position.altitude, "accuracy": position.accuracy})),
    );
  }

  Position? get lastPosition => _lastPosition;

  /// Re-places GPS anchors from the latest fix and heading. Call after the
  /// position accuracy improves or when the user walks a long way.
  Future<void> refreshGeoAnchors() async {
    for (final MapEntry<String, _GpsAnchor> entry in _gpsAnchors.entries.toList(growable: false)) {
      await _safe(() => updateAnchor(entry.key, _gpsPose(entry.value)));
    }
  }

  Future<UArVpsAvailability> checkVpsAvailability(double latitude, double longitude) async {
    try {
      final String? raw = await UArChannel.invoke<String>("checkVps", <String, Object?>{"sessionId": _sessionId, "latitude": latitude, "longitude": longitude});
      return _enumOf(UArVpsAvailability.values, raw, UArVpsAvailability.unknown);
    } on UArException {
      return UArVpsAvailability.unknown;
    }
  }

  // ---------------------------------------------------------------------------
  // Sharing and persistence
  // ---------------------------------------------------------------------------

  /// Uploads an anchor to Google Cloud Anchors and returns its cloud id.
  Future<String> hostCloudAnchor(String anchorId, {int ttlDays = 1}) async {
    final String? cloudId = await _invoke<String>("hostCloudAnchor", <String, Object?>{"id": anchorId, "ttlDays": ttlDays});
    if (cloudId == null) throw const UArException(code: UArErrorCode.unknown, message: "Hosting failed");
    final UArAnchor? anchor = value.anchors[anchorId];
    if (anchor != null) {
      value = value.copyWith(
        anchors: <String, UArAnchor>{
          ...value.anchors,
          anchorId: anchor.copyWith(cloudId: cloudId),
        },
      );
    }
    return cloudId;
  }

  Future<UArAnchor> resolveCloudAnchor(String cloudId, {String? id}) async {
    final Map<Object?, Object?>? raw = await _invoke<Map<Object?, Object?>>("resolveCloudAnchor", <String, Object?>{"cloudId": cloudId, "id": id ?? newId("c")});
    if (raw == null) throw const UArException(code: UArErrorCode.notFound, message: "Anchor not resolved");
    final UArAnchor anchor = UArAnchor.fromMap(raw);
    value = value.copyWith(anchors: <String, UArAnchor>{...value.anchors, anchor.id: anchor});
    return anchor;
  }

  /// Serialised ARKit world map; pass it back through [UArConfig.worldMap].
  Future<Uint8List?> getWorldMap() => _invoke<Uint8List>("getWorldMap");

  Future<void> sendCollaborationData(Uint8List data) => _invoke<void>("collaborationData", <String, Object?>{"data": data});

  // ---------------------------------------------------------------------------
  // Measurement helpers
  // ---------------------------------------------------------------------------

  double distanceToCamera(UArVector3 point) => value.frame.camera.position.distanceTo(point);

  /// Planes of one kind, largest first.
  List<UArPlane> planesOf({UArPlaneType? type, UArPlaneClassification? classification}) =>
      value.planes.values.where((UArPlane p) => (type == null || p.type == type) && (classification == null || p.classification == classification)).toList(growable: false)
        ..sort((UArPlane a, UArPlane b) => b.area.compareTo(a.area));

  /// Height of the lowest horizontal plane, a good guess for the floor.
  double? get floorHeight {
    final Iterable<UArPlane> floors = value.planes.values.where((UArPlane p) => p.type == UArPlaneType.horizontalUp);
    if (floors.isEmpty) return null;
    return floors.map((UArPlane p) => p.pose.position.y).reduce(min);
  }
}

// =============================================================================
// Views
// =============================================================================

/// The native AR / 3D surface of a [UArController]. Draws a GPU texture on
/// Android, a RealityKit view on iOS and a canvas on the web; [child] is laid
/// over it. Gestures are left to [child] so every platform behaves the same.
class UArView extends StatefulWidget {
  const UArView({required this.controller, this.child, this.placeholder, this.unsupported, super.key});

  final UArController controller;
  final Widget? child;
  final Widget? placeholder;
  final Widget? unsupported;

  @override
  State<UArView> createState() => _UArViewState();
}

class _UArViewState extends State<UArView> {
  static const String _iosViewType = "u/ar_view";

  bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  bool get _isSupported => kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    if (!_isSupported) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) widget.controller.reportUnsupported();
      });
      return widget.unsupported ?? const SizedBox.shrink();
    }
    final double ratio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = constraints.biggest;
        if (size.isFinite && !size.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((Duration _) {
            if (mounted) unawaited(widget.controller.attachSurface(size, ratio));
          });
        }
        return ValueListenableBuilder<UArValue>(
          valueListenable: widget.controller,
          builder: (BuildContext context, UArValue value, Widget? child) => Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _surface(value),
              if (value.state == UArSessionState.initializing || value.state == UArSessionState.uninitialized && !_isIos) ?widget.placeholder,
              ?child,
            ],
          ),
          child: widget.child,
        );
      },
    );
  }

  Widget _surface(UArValue value) {
    if (_isIos) {
      return UiKitView(
        viewType: _iosViewType,
        creationParams: <String, Object?>{"config": widget.controller.config.toMap()},
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (int id) => unawaited(widget.controller.attachPlatformView(id)),
      );
    }
    final String? viewType = value.viewType;
    if (viewType != null) return HtmlElementView(viewType: viewType);
    final int? textureId = value.textureId;
    if (textureId == null) return const SizedBox.expand();
    return Texture(textureId: textureId);
  }
}

/// Renders a widget off-screen into PNG bytes, for textures in the scene.
abstract class UArWidgetRenderer {
  static Future<Uint8List?> render(
    Widget widget, {
    Size size = const Size(320, 200),
    double pixelRatio = 3,
    BuildContext? context,
    TextDirection? textDirection,
    Duration settle = const Duration(milliseconds: 50),
  }) async {
    try {
      final ui.FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
      final RenderRepaintBoundary boundary = RenderRepaintBoundary();
      final RenderView renderView = RenderView(
        view: view,
        child: RenderPositionedBox(child: boundary),
        configuration: ViewConfiguration(logicalConstraints: BoxConstraints.tight(size), physicalConstraints: BoxConstraints.tight(size * pixelRatio), devicePixelRatio: pixelRatio),
      );
      final PipelineOwner pipelineOwner = PipelineOwner()..rootNode = renderView;
      renderView.prepareInitialFrame();
      final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());
      Widget content = MediaQuery(
        data: MediaQueryData(size: size, devicePixelRatio: pixelRatio),
        child: Directionality(textDirection: textDirection ?? (context == null ? TextDirection.ltr : Directionality.of(context)), child: widget),
      );
      if (context != null) content = InheritedTheme.captureAll(context, content);
      final RenderObjectToWidgetElement<RenderBox> root = RenderObjectToWidgetAdapter<RenderBox>(container: boundary, child: content).attachToRenderTree(buildOwner);
      buildOwner.buildScope(root);
      if (settle > Duration.zero) {
        await Future<void>.delayed(settle);
        buildOwner.buildScope(root);
      }
      buildOwner.finalizeTree();
      pipelineOwner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
