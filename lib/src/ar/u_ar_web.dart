import "dart:async";
import "dart:convert";
import "dart:js_interop";
import "dart:js_interop_unsafe";
import "dart:math" as math;
import "dart:typed_data";
import "dart:ui_web" as ui_web;

import "package:flutter/services.dart";
import "package:flutter_web_plugins/flutter_web_plugins.dart";
import "package:web/web.dart" as web;

// =============================================================================
// u_ar_web — WebXR + WebGL2 implementation of the `u` AR / 3D plugin.
//
// A canvas shown through an HtmlElementView renders the scene with a small
// glTF 2.0 renderer (the same PBR model as the Android one). "enterXr" starts
// an immersive-ar WebXR session with the Flutter view as its DOM overlay where
// the browser supports it (Chrome on Android), and otherwise a camera +
// compass session for location content (iOS Safari and the rest). AR Quick
// Look and Scene Viewer are reached through plain links, so nothing here loads
// a script from anywhere.
// =============================================================================

abstract class _G {
  static const int depthBufferBit = 0x0100;
  static const int colorBufferBit = 0x4000;
  static const int lineLoop = 0x0002;
  static const int triangles = 0x0004;
  static const int triangleStrip = 0x0005;
  static const int triangleFan = 0x0006;
  static const int srcAlpha = 0x0302;
  static const int oneMinusSrcAlpha = 0x0303;
  static const int one = 1;
  static const int cullFace = 0x0B44;
  static const int depthTest = 0x0B71;
  static const int blend = 0x0BE2;
  static const int lequal = 0x0203;
  static const int texture2d = 0x0DE1;
  static const int unsignedByte = 0x1401;
  static const int unsignedInt = 0x1405;
  static const int float = 0x1406;
  static const int rgba = 0x1908;
  static const int rgba8 = 0x8058;
  static const int rgba32f = 0x8814;
  static const int nearest = 0x2600;
  static const int linear = 0x2601;
  static const int linearMipmapLinear = 0x2703;
  static const int textureMagFilter = 0x2800;
  static const int textureMinFilter = 0x2801;
  static const int textureWrapS = 0x2802;
  static const int textureWrapT = 0x2803;
  static const int repeat = 0x2901;
  static const int clampToEdge = 0x812F;
  static const int texture0 = 0x84C0;
  static const int arrayBuffer = 0x8892;
  static const int elementArrayBuffer = 0x8893;
  static const int staticDraw = 0x88E4;
  static const int streamDraw = 0x88E0;
  static const int fragmentShader = 0x8B30;
  static const int vertexShader = 0x8B31;
  static const int compileStatus = 0x8B81;
  static const int linkStatus = 0x8B82;
  static const int framebuffer = 0x8D40;
  static const int unpackFlipY = 0x9240;
  static const int unpackPremultiply = 0x9241;
  static const int unpackColorspace = 0x9243;
}

extension type _Gl._(JSObject _) implements JSObject {
  external JSObject? createShader(int type);
  external void shaderSource(JSObject shader, String source);
  external void compileShader(JSObject shader);
  external JSAny? getShaderParameter(JSObject shader, int name);
  external String? getShaderInfoLog(JSObject shader);
  external JSObject? createProgram();
  external void attachShader(JSObject program, JSObject shader);
  external void linkProgram(JSObject program);
  external JSAny? getProgramParameter(JSObject program, int name);
  external String? getProgramInfoLog(JSObject program);
  external void deleteShader(JSObject? shader);
  external void deleteProgram(JSObject? program);
  external void useProgram(JSObject? program);
  external JSObject? getUniformLocation(JSObject program, String name);
  external JSObject? createBuffer();
  external void bindBuffer(int target, JSObject? buffer);
  external void bufferData(int target, JSAny data, int usage);
  external void deleteBuffer(JSObject? buffer);
  external JSObject? createVertexArray();
  external void bindVertexArray(JSObject? vao);
  external void deleteVertexArray(JSObject? vao);
  external void enableVertexAttribArray(int index);
  external void vertexAttribPointer(int index, int size, int type, bool normalized, int stride, int offset);
  external void drawElements(int mode, int count, int type, int offset);
  external void drawArrays(int mode, int first, int count);
  external JSObject? createTexture();
  external void bindTexture(int target, JSObject? texture);
  external void deleteTexture(JSObject? texture);
  external void texParameteri(int target, int name, int value);
  external void texImage2D(int target, int level, int internalFormat, int width, int height, int border, int format, int type, JSAny? pixels);
  @JS("texImage2D")
  external void texImage2DSource(int target, int level, int internalFormat, int format, int type, JSAny source);
  external void texSubImage2D(int target, int level, int x, int y, int width, int height, int format, int type, JSAny? pixels);
  external void generateMipmap(int target);
  external void activeTexture(int unit);
  external void pixelStorei(int name, int value);
  external void uniform1i(JSObject? location, int x);
  external void uniform1f(JSObject? location, double x);
  external void uniform2f(JSObject? location, double x, double y);
  external void uniform3f(JSObject? location, double x, double y, double z);
  external void uniform4f(JSObject? location, double x, double y, double z, double w);
  external void uniform3fv(JSObject? location, JSFloat32Array data);
  external void uniformMatrix3fv(JSObject? location, bool transpose, JSFloat32Array data);
  external void uniformMatrix4fv(JSObject? location, bool transpose, JSFloat32Array data);
  external void viewport(int x, int y, int width, int height);
  external void clearColor(double r, double g, double b, double a);
  external void clear(int mask);
  external void enable(int capability);
  external void disable(int capability);
  external void depthMask(bool flag);
  external void depthFunc(int function);
  external void colorMask(bool r, bool g, bool b, bool a);
  external void blendFuncSeparate(int srcRgb, int dstRgb, int srcAlpha, int dstAlpha);
  external void bindFramebuffer(int target, JSObject? framebuffer);
  external void readPixels(int x, int y, int width, int height, int format, int type, JSAny pixels);
  external JSPromise<JSAny?> makeXRCompatible();
}

extension type _XrSession._(JSObject _) implements JSObject {
  external JSPromise<JSObject> requestReferenceSpace(String type);
  external JSPromise<JSObject> requestHitTestSource(JSObject options);
  external int requestAnimationFrame(JSFunction<Function> callback);
  external JSPromise<JSAny?> end();
  external void updateRenderState(JSObject state);
  external JSObject get renderState;
  external JSPromise<JSObject> requestLightProbe();
  external void addEventListener(String type, JSFunction<Function> callback);
}

extension type _XrFrame._(JSObject _) implements JSObject {
  external _XrViewerPose? getViewerPose(JSObject space);
  external _XrPose? getPose(JSObject space, JSObject baseSpace);
  external JSArray<_XrHitResult> getHitTestResults(JSObject source);
  external JSPromise<JSObject> createAnchor(JSObject pose, JSObject space);
  external JSObject? getLightEstimate(JSObject probe);
}

extension type _XrPose._(JSObject _) implements JSObject {
  external _XrTransform get transform;
}

extension type _XrViewerPose._(JSObject _) implements _XrPose {
  external JSArray<_XrView> get views;
}

extension type _XrView._(JSObject _) implements JSObject {
  external JSFloat32Array get projectionMatrix;
  external _XrTransform get transform;
}

extension type _XrTransform._(JSObject _) implements JSObject {
  external JSFloat32Array get matrix;
  external _XrTransform get inverse;
}

extension type _XrHitResult._(JSObject _) implements JSObject {
  external _XrPose? getPose(JSObject baseSpace);
  external JSPromise<JSObject> createAnchor();
}

extension type _XrLayer._(JSObject _) implements JSObject {
  external JSObject? get framebuffer;
  external int get framebufferWidth;
  external int get framebufferHeight;
  external JSObject? getViewport(JSObject view);
}

// =============================================================================
// Math (column-major matrices, [x, y, z, w] quaternions)
// =============================================================================

abstract class _M {
  static Float32List identity() => Float32List(16)
    ..[0] = 1
    ..[5] = 1
    ..[10] = 1
    ..[15] = 1;

  static Float32List multiply(Float32List a, Float32List b) {
    final Float32List out = Float32List(16);
    for (int c = 0; c < 4; c++) {
      for (int r = 0; r < 4; r++) {
        out[c * 4 + r] = a[r] * b[c * 4] + a[4 + r] * b[c * 4 + 1] + a[8 + r] * b[c * 4 + 2] + a[12 + r] * b[c * 4 + 3];
      }
    }
    return out;
  }

  static Float32List invert(Float32List m) {
    final double a00 = m[0];
    final double a01 = m[1];
    final double a02 = m[2];
    final double a03 = m[3];
    final double a10 = m[4];
    final double a11 = m[5];
    final double a12 = m[6];
    final double a13 = m[7];
    final double a20 = m[8];
    final double a21 = m[9];
    final double a22 = m[10];
    final double a23 = m[11];
    final double a30 = m[12];
    final double a31 = m[13];
    final double a32 = m[14];
    final double a33 = m[15];
    final double b00 = a00 * a11 - a01 * a10;
    final double b01 = a00 * a12 - a02 * a10;
    final double b02 = a00 * a13 - a03 * a10;
    final double b03 = a01 * a12 - a02 * a11;
    final double b04 = a01 * a13 - a03 * a11;
    final double b05 = a02 * a13 - a03 * a12;
    final double b06 = a20 * a31 - a21 * a30;
    final double b07 = a20 * a32 - a22 * a30;
    final double b08 = a20 * a33 - a23 * a30;
    final double b09 = a21 * a32 - a22 * a31;
    final double b10 = a21 * a33 - a23 * a31;
    final double b11 = a22 * a33 - a23 * a32;
    double det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
    if (det.abs() < 1e-12) return identity();
    det = 1 / det;
    return Float32List.fromList(<double>[
      (a11 * b11 - a12 * b10 + a13 * b09) * det,
      (a02 * b10 - a01 * b11 - a03 * b09) * det,
      (a31 * b05 - a32 * b04 + a33 * b03) * det,
      (a22 * b04 - a21 * b05 - a23 * b03) * det,
      (a12 * b08 - a10 * b11 - a13 * b07) * det,
      (a00 * b11 - a02 * b08 + a03 * b07) * det,
      (a32 * b02 - a30 * b05 - a33 * b01) * det,
      (a20 * b05 - a22 * b02 + a23 * b01) * det,
      (a10 * b10 - a11 * b08 + a13 * b06) * det,
      (a01 * b08 - a00 * b10 - a03 * b06) * det,
      (a30 * b04 - a31 * b02 + a33 * b00) * det,
      (a21 * b02 - a20 * b04 - a23 * b00) * det,
      (a11 * b07 - a10 * b09 - a12 * b06) * det,
      (a00 * b09 - a01 * b07 + a02 * b06) * det,
      (a31 * b01 - a30 * b03 - a32 * b00) * det,
      (a20 * b03 - a21 * b01 + a22 * b00) * det,
    ]);
  }

  static Float32List compose(List<double> t, List<double> q, List<double> s) {
    final double x = q[0];
    final double y = q[1];
    final double z = q[2];
    final double w = q[3];
    final Float32List m = Float32List(16);
    m[0] = (1 - 2 * (y * y + z * z)) * s[0];
    m[1] = 2 * (x * y + w * z) * s[0];
    m[2] = 2 * (x * z - w * y) * s[0];
    m[4] = 2 * (x * y - w * z) * s[1];
    m[5] = (1 - 2 * (x * x + z * z)) * s[1];
    m[6] = 2 * (y * z + w * x) * s[1];
    m[8] = 2 * (x * z + w * y) * s[2];
    m[9] = 2 * (y * z - w * x) * s[2];
    m[10] = (1 - 2 * (x * x + y * y)) * s[2];
    m[12] = t[0];
    m[13] = t[1];
    m[14] = t[2];
    m[15] = 1;
    return m;
  }

  static Float32List perspective(double fovY, double aspect, double near, double far) {
    final double f = 1 / math.tan(fovY / 2);
    final Float32List m = Float32List(16);
    m[0] = f / aspect;
    m[5] = f;
    m[10] = (far + near) / (near - far);
    m[11] = -1;
    m[14] = 2 * far * near / (near - far);
    return m;
  }

  static Float32List lookAt(List<double> eye, List<double> target, List<double> up) {
    List<double> norm(List<double> v) {
      final double l = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
      return l < 1e-9 ? <double>[0, 0, 0] : <double>[v[0] / l, v[1] / l, v[2] / l];
    }

    List<double> cross(List<double> a, List<double> b) => <double>[a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
    final List<double> z = norm(<double>[eye[0] - target[0], eye[1] - target[1], eye[2] - target[2]]);
    final List<double> x = norm(cross(up, z));
    final List<double> y = cross(z, x);
    return Float32List.fromList(<double>[
      x[0],
      y[0],
      z[0],
      0,
      x[1],
      y[1],
      z[1],
      0,
      x[2],
      y[2],
      z[2],
      0,
      -(x[0] * eye[0] + x[1] * eye[1] + x[2] * eye[2]),
      -(y[0] * eye[0] + y[1] * eye[1] + y[2] * eye[2]),
      -(z[0] * eye[0] + z[1] * eye[1] + z[2] * eye[2]),
      1,
    ]);
  }

  static List<double> point(Float32List m, double x, double y, double z) => <double>[
    m[0] * x + m[4] * y + m[8] * z + m[12],
    m[1] * x + m[5] * y + m[9] * z + m[13],
    m[2] * x + m[6] * y + m[10] * z + m[14],
  ];

  static List<double> clip(Float32List m, List<double> p) => <double>[
    m[0] * p[0] + m[4] * p[1] + m[8] * p[2] + m[12],
    m[1] * p[0] + m[5] * p[1] + m[9] * p[2] + m[13],
    m[2] * p[0] + m[6] * p[1] + m[10] * p[2] + m[14],
    m[3] * p[0] + m[7] * p[1] + m[11] * p[2] + m[15],
  ];

  static List<double> translation(Float32List m) => <double>[m[12], m[13], m[14]];

  static List<double> scaleOf(Float32List m) => <double>[
    math.sqrt(m[0] * m[0] + m[1] * m[1] + m[2] * m[2]),
    math.sqrt(m[4] * m[4] + m[5] * m[5] + m[6] * m[6]),
    math.sqrt(m[8] * m[8] + m[9] * m[9] + m[10] * m[10]),
  ];

  static List<double> rotationOf(Float32List m) {
    final List<double> s = scaleOf(m).map((double v) => v == 0 ? 1.0 : v).toList();
    return fromBasis(m[0] / s[0], m[1] / s[0], m[2] / s[0], m[4] / s[1], m[5] / s[1], m[6] / s[1], m[8] / s[2], m[9] / s[2], m[10] / s[2]);
  }

  static List<double> fromBasis(double m00, double m10, double m20, double m01, double m11, double m21, double m02, double m12, double m22) {
    final double trace = m00 + m11 + m22;
    if (trace > 0) {
      final double s = math.sqrt(trace + 1) * 2;
      return <double>[(m21 - m12) / s, (m02 - m20) / s, (m10 - m01) / s, 0.25 * s];
    }
    if (m00 > m11 && m00 > m22) {
      final double s = math.sqrt(1 + m00 - m11 - m22) * 2;
      return <double>[0.25 * s, (m01 + m10) / s, (m02 + m20) / s, (m21 - m12) / s];
    }
    if (m11 > m22) {
      final double s = math.sqrt(1 + m11 - m00 - m22) * 2;
      return <double>[(m01 + m10) / s, 0.25 * s, (m12 + m21) / s, (m02 - m20) / s];
    }
    final double s = math.sqrt(1 + m22 - m00 - m11) * 2;
    return <double>[(m02 + m20) / s, (m12 + m21) / s, 0.25 * s, (m10 - m01) / s];
  }

  static List<double> pose(Float32List m) => <double>[...translation(m), ...rotationOf(m)];

  static Float32List poseMatrix(Object? raw) {
    final List<double> p = doubles(raw, 7, 0);
    final bool zero = p[3] == 0 && p[4] == 0 && p[5] == 0 && p[6] == 0;
    return compose(<double>[p[0], p[1], p[2]], zero ? <double>[0, 0, 0, 1] : qNormalize(<double>[p[3], p[4], p[5], p[6]]), <double>[1, 1, 1]);
  }

  static List<double> doubles(Object? raw, int count, double fallback) {
    final List<Object?> list = raw is List<Object?> ? raw : const <Object?>[];
    return <double>[
      for (int i = 0; i < count; i++)
        if (i < list.length && list[i] is num) (list[i]! as num).toDouble() else fallback,
    ];
  }

  static List<double> qNormalize(List<double> q) {
    final double l = math.sqrt(q[0] * q[0] + q[1] * q[1] + q[2] * q[2] + q[3] * q[3]);
    return l < 1e-9 ? <double>[0, 0, 0, 1] : <double>[q[0] / l, q[1] / l, q[2] / l, q[3] / l];
  }

  static List<double> qMultiply(List<double> a, List<double> b) => <double>[
    a[3] * b[0] + a[0] * b[3] + a[1] * b[2] - a[2] * b[1],
    a[3] * b[1] - a[0] * b[2] + a[1] * b[3] + a[2] * b[0],
    a[3] * b[2] + a[0] * b[1] - a[1] * b[0] + a[2] * b[3],
    a[3] * b[3] - a[0] * b[0] - a[1] * b[1] - a[2] * b[2],
  ];

  static List<double> qAxis(double x, double y, double z, double angle) {
    final double s = math.sin(angle / 2);
    return <double>[x * s, y * s, z * s, math.cos(angle / 2)];
  }

  static List<double> qSlerp(List<double> a, List<double> b, double t) {
    double cosHalf = a[0] * b[0] + a[1] * b[1] + a[2] * b[2] + a[3] * b[3];
    List<double> target = b;
    if (cosHalf < 0) {
      cosHalf = -cosHalf;
      target = <double>[-b[0], -b[1], -b[2], -b[3]];
    }
    if (cosHalf > 0.9995) return qNormalize(<double>[for (int i = 0; i < 4; i++) a[i] + (target[i] - a[i]) * t]);
    final double half = math.acos(cosHalf);
    final double sinHalf = math.sqrt(1 - cosHalf * cosHalf);
    final double ra = math.sin((1 - t) * half) / sinHalf;
    final double rb = math.sin(t * half) / sinHalf;
    return <double>[for (int i = 0; i < 4; i++) a[i] * ra + target[i] * rb];
  }

  static List<double> billboard(List<double> position, List<double> camera, bool yAxisOnly) {
    double dx = camera[0] - position[0];
    double dy = yAxisOnly ? 0 : camera[1] - position[1];
    double dz = camera[2] - position[2];
    final double l = math.sqrt(dx * dx + dy * dy + dz * dz);
    if (l < 1e-6) return <double>[0, 0, 0, 1];
    dx /= l;
    dy /= l;
    dz /= l;
    double rx = dz;
    double rz = -dx;
    final double rl = math.sqrt(rx * rx + rz * rz);
    if (rl < 1e-6) {
      rx = 1;
      rz = 0;
    } else {
      rx /= rl;
      rz /= rl;
    }
    final double ux = dy * rz;
    final double uy = dz * rx - dx * rz;
    final double uz = -dy * rx;
    return fromBasis(rx, 0, rz, ux, uy, uz, dx, dy, dz);
  }

  static double distance(List<double> a, List<double> b) => math.sqrt((a[0] - b[0]) * (a[0] - b[0]) + (a[1] - b[1]) * (a[1] - b[1]) + (a[2] - b[2]) * (a[2] - b[2]));

  static List<double> argb(Object? value, int fallback) {
    final int c = value is num ? value.toInt() : fallback;
    return <double>[((c >> 16) & 0xFF) / 255, ((c >> 8) & 0xFF) / 255, (c & 0xFF) / 255, ((c >> 24) & 0xFF) / 255];
  }

  static List<double> linear(List<double> c) => <double>[math.pow(c[0], 2.2).toDouble(), math.pow(c[1], 2.2).toDouble(), math.pow(c[2], 2.2).toDouble(), c[3]];

  static (List<double>, List<double>) aabb(Float32List m, List<double> min, List<double> max) {
    final List<double> lo = <double>[double.infinity, double.infinity, double.infinity];
    final List<double> hi = <double>[-double.infinity, -double.infinity, -double.infinity];
    for (int i = 0; i < 8; i++) {
      final List<double> p = point(m, i & 1 == 0 ? min[0] : max[0], i & 2 == 0 ? min[1] : max[1], i & 4 == 0 ? min[2] : max[2]);
      for (int k = 0; k < 3; k++) {
        lo[k] = math.min(lo[k], p[k]);
        hi[k] = math.max(hi[k], p[k]);
      }
    }
    return (lo, hi);
  }

  static double? rayAabb(List<double> origin, List<double> dir, List<double> min, List<double> max) {
    double tMin = -double.maxFinite;
    double tMax = double.maxFinite;
    for (int i = 0; i < 3; i++) {
      if (dir[i].abs() < 1e-9) {
        if (origin[i] < min[i] || origin[i] > max[i]) return null;
      } else {
        double t1 = (min[i] - origin[i]) / dir[i];
        double t2 = (max[i] - origin[i]) / dir[i];
        if (t1 > t2) {
          final double tmp = t1;
          t1 = t2;
          t2 = tmp;
        }
        tMin = math.max(tMin, t1);
        tMax = math.min(tMax, t2);
        if (tMin > tMax) return null;
      }
    }
    if (tMax < 0) return null;
    return tMin >= 0 ? tMin : tMax;
  }
}

// =============================================================================
// glTF 2.0 — CPU side
// =============================================================================

const int _stride = 20;

class _MeshData {
  _MeshData(this.vertices, this.indices, this.min, this.max);

  final Float32List vertices;
  final Uint32List indices;
  final List<double> min;
  final List<double> max;

  static _MeshData build(List<double> positions, List<double>? normals, List<double>? uvs, List<double>? joints, List<double>? weights, List<double>? colors, int colorComponents, List<int> indices) {
    final int count = positions.length ~/ 3;
    final List<double> n = normals ?? _computeNormals(positions, indices);
    final Float32List out = Float32List(count * _stride);
    final List<double> lo = <double>[double.infinity, double.infinity, double.infinity];
    final List<double> hi = <double>[-double.infinity, -double.infinity, -double.infinity];
    for (int i = 0; i < count; i++) {
      final int o = i * _stride;
      for (int k = 0; k < 3; k++) {
        final double p = positions[i * 3 + k];
        out[o + k] = p;
        lo[k] = math.min(lo[k], p);
        hi[k] = math.max(hi[k], p);
        out[o + 3 + k] = i * 3 + k < n.length ? n[i * 3 + k] : 0;
      }
      if (uvs != null && i * 2 + 1 < uvs.length) {
        out[o + 6] = uvs[i * 2];
        out[o + 7] = uvs[i * 2 + 1];
      }
      for (int k = 0; k < 4; k++) {
        if (joints != null && i * 4 + k < joints.length) out[o + 8 + k] = joints[i * 4 + k];
        if (weights != null && i * 4 + k < weights.length) out[o + 12 + k] = weights[i * 4 + k];
      }
      for (int k = 0; k < 4; k++) {
        out[o + 16 + k] = colors != null && k < colorComponents && i * colorComponents + k < colors.length ? colors[i * colorComponents + k] : 1;
      }
    }
    if (count == 0) {
      lo.fillRange(0, 3, 0);
      hi.fillRange(0, 3, 0);
    }
    return _MeshData(out, Uint32List.fromList(indices), lo, hi);
  }

  static List<double> _computeNormals(List<double> p, List<int> indices) {
    final List<double> n = List<double>.filled(p.length, 0);
    for (int i = 0; i + 2 < indices.length; i += 3) {
      final int a = indices[i] * 3;
      final int b = indices[i + 1] * 3;
      final int c = indices[i + 2] * 3;
      if (c + 2 >= p.length || a + 2 >= p.length || b + 2 >= p.length) continue;
      final double ux = p[b] - p[a];
      final double uy = p[b + 1] - p[a + 1];
      final double uz = p[b + 2] - p[a + 2];
      final double vx = p[c] - p[a];
      final double vy = p[c + 1] - p[a + 1];
      final double vz = p[c + 2] - p[a + 2];
      final double nx = uy * vz - uz * vy;
      final double ny = uz * vx - ux * vz;
      final double nz = ux * vy - uy * vx;
      for (final int v in <int>[a, b, c]) {
        n[v] += nx;
        n[v + 1] += ny;
        n[v + 2] += nz;
      }
    }
    for (int k = 0; k + 2 < n.length; k += 3) {
      final double l = math.sqrt(n[k] * n[k] + n[k + 1] * n[k + 1] + n[k + 2] * n[k + 2]);
      if (l > 0) {
        n[k] /= l;
        n[k + 1] /= l;
        n[k + 2] /= l;
      } else {
        n[k + 1] = 1;
      }
    }
    return n;
  }

  static _MeshData box(double w, double h, double d) {
    final double x = w / 2;
    final double y = h / 2;
    final double z = d / 2;
    final List<(List<double>, List<List<double>>)> faces = <(List<double>, List<List<double>>)>[
      (
        <double>[0, 0, 1],
        <List<double>>[
          <double>[-x, y, z],
          <double>[x, y, z],
          <double>[x, -y, z],
          <double>[-x, -y, z],
        ],
      ),
      (
        <double>[0, 0, -1],
        <List<double>>[
          <double>[x, y, -z],
          <double>[-x, y, -z],
          <double>[-x, -y, -z],
          <double>[x, -y, -z],
        ],
      ),
      (
        <double>[1, 0, 0],
        <List<double>>[
          <double>[x, y, z],
          <double>[x, y, -z],
          <double>[x, -y, -z],
          <double>[x, -y, z],
        ],
      ),
      (
        <double>[-1, 0, 0],
        <List<double>>[
          <double>[-x, y, -z],
          <double>[-x, y, z],
          <double>[-x, -y, z],
          <double>[-x, -y, -z],
        ],
      ),
      (
        <double>[0, 1, 0],
        <List<double>>[
          <double>[-x, y, -z],
          <double>[x, y, -z],
          <double>[x, y, z],
          <double>[-x, y, z],
        ],
      ),
      (
        <double>[0, -1, 0],
        <List<double>>[
          <double>[-x, -y, z],
          <double>[x, -y, z],
          <double>[x, -y, -z],
          <double>[-x, -y, -z],
        ],
      ),
    ];
    final List<double> positions = <double>[];
    final List<double> normals = <double>[];
    final List<double> uvs = <double>[];
    final List<int> indices = <int>[];
    const List<double> corners = <double>[0, 0, 1, 0, 1, 1, 0, 1];
    for (final (List<double>, List<List<double>>) face in faces) {
      final int start = positions.length ~/ 3;
      for (int i = 0; i < 4; i++) {
        positions.addAll(face.$2[i]);
        normals.addAll(face.$1);
        uvs.addAll(<double>[corners[i * 2], corners[i * 2 + 1]]);
      }
      indices.addAll(<int>[start, start + 2, start + 1, start, start + 3, start + 2]);
    }
    return build(positions, normals, uvs, null, null, null, 4, indices);
  }

  static _MeshData sphere(double radius, {int segments = 32, int rings = 20}) {
    final List<double> positions = <double>[];
    final List<double> normals = <double>[];
    final List<double> uvs = <double>[];
    final List<int> indices = <int>[];
    for (int r = 0; r <= rings; r++) {
      final double v = r / rings;
      final double phi = v * math.pi;
      for (int s = 0; s <= segments; s++) {
        final double u = s / segments;
        final double theta = u * 2 * math.pi;
        final double nx = math.sin(phi) * math.sin(theta);
        final double ny = math.cos(phi);
        final double nz = math.sin(phi) * math.cos(theta);
        positions.addAll(<double>[nx * radius, ny * radius, nz * radius]);
        normals.addAll(<double>[nx, ny, nz]);
        uvs.addAll(<double>[u, v]);
      }
    }
    for (int r = 0; r < rings; r++) {
      for (int s = 0; s < segments; s++) {
        final int a = r * (segments + 1) + s;
        final int b = a + segments + 1;
        indices.addAll(<int>[a, b, a + 1, b, b + 1, a + 1]);
      }
    }
    return build(positions, normals, uvs, null, null, null, 4, indices);
  }

  static _MeshData cylinder(double radius, double height, bool cone, {int segments = 32}) {
    final List<double> positions = <double>[];
    final List<double> normals = <double>[];
    final List<double> uvs = <double>[];
    final List<int> indices = <int>[];
    final double half = height / 2;
    final double top = cone ? 0 : radius;
    final double slope = (radius - top) / height;
    final double l = math.sqrt(1 + slope * slope);
    for (int s = 0; s <= segments; s++) {
      final double u = s / segments;
      final double theta = u * 2 * math.pi;
      final double x = math.sin(theta);
      final double z = math.cos(theta);
      positions.addAll(<double>[x * top, half, z * top, x * radius, -half, z * radius]);
      normals.addAll(<double>[x / l, slope / l, z / l, x / l, slope / l, z / l]);
      uvs.addAll(<double>[u, 0, u, 1]);
    }
    for (int s = 0; s < segments; s++) {
      final int a = s * 2;
      indices.addAll(<int>[a, a + 1, a + 2, a + 1, a + 3, a + 2]);
    }
    for (final double y in cone ? <double>[-half] : <double>[half, -half]) {
      final int center = positions.length ~/ 3;
      final double ny = y > 0 ? 1 : -1;
      final double r = y > 0 ? top : radius;
      positions.addAll(<double>[0, y, 0]);
      normals.addAll(<double>[0, ny, 0]);
      uvs.addAll(<double>[0.5, 0.5]);
      for (int s = 0; s <= segments; s++) {
        final double theta = s / segments * 2 * math.pi;
        positions.addAll(<double>[math.sin(theta) * r, y, math.cos(theta) * r]);
        normals.addAll(<double>[0, ny, 0]);
        uvs.addAll(<double>[0.5 + math.sin(theta) / 2, 0.5 + math.cos(theta) / 2]);
      }
      for (int s = 0; s < segments; s++) {
        indices.addAll(ny > 0 ? <int>[center, center + 1 + s, center + 2 + s] : <int>[center, center + 2 + s, center + 1 + s]);
      }
    }
    return build(positions, normals, uvs, null, null, null, 4, indices);
  }

  static _MeshData quad(double w, double h) {
    final double x = w / 2;
    final double y = h / 2;
    return build(
      <double>[-x, y, 0, x, y, 0, x, -y, 0, -x, -y, 0],
      <double>[0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1],
      <double>[0, 0, 1, 0, 1, 1, 0, 1],
      null,
      null,
      null,
      4,
      <int>[0, 2, 1, 0, 3, 2],
    );
  }
}

class _MaterialData {
  List<double> baseColor = <double>[1, 1, 1, 1];
  double metallic = 1;
  double roughness = 1;
  List<double> emissive = <double>[0, 0, 0];
  int baseTexture = -1;
  int mrTexture = -1;
  int normalTexture = -1;
  int occlusionTexture = -1;
  int emissiveTexture = -1;
  double normalScale = 1;
  double occlusionStrength = 1;
  int alphaMode = 0;
  double alphaCutoff = 0.5;
  bool doubleSided = false;
  bool unlit = false;
  Float32List? uvTransform;
}

class _GltfNode {
  _GltfNode(this.children, this.mesh, this.skin, this.translation, this.rotation, this.scale, this.matrix);

  final List<int> children;
  final int mesh;
  final int skin;
  final List<double> translation;
  final List<double> rotation;
  final List<double> scale;
  final Float32List? matrix;
}

class _GltfChannel {
  _GltfChannel(this.node, this.path, this.times, this.values, this.interpolation);

  final int node;
  final String path;
  final List<double> times;
  final List<double> values;
  final String interpolation;
}

class _GltfAnimation {
  _GltfAnimation(this.name, this.channels, this.duration);

  final String name;
  final List<_GltfChannel> channels;
  final double duration;
}

class _GltfSkin {
  _GltfSkin(this.joints, this.inverseBind);

  final List<int> joints;
  final List<double> inverseBind;
}

class _GltfData {
  final List<_GltfNode> nodes = <_GltfNode>[];
  List<int> roots = <int>[];
  final List<List<(_MeshData, int)>> meshes = <List<(_MeshData, int)>>[];
  final List<_MaterialData> materials = <_MaterialData>[];
  final List<(int, int, int, int)> textures = <(int, int, int, int)>[];
  final List<web.ImageBitmap?> images = <web.ImageBitmap?>[];
  final List<_GltfSkin> skins = <_GltfSkin>[];
  final List<_GltfAnimation> animations = <_GltfAnimation>[];

  static Future<_GltfData> parse(Uint8List bytes, String? baseUrl) async {
    final _GltfData data = _GltfData();
    final ByteData header = ByteData.sublistView(bytes);
    Map<String, Object?> json = <String, Object?>{};
    Uint8List? bin;
    if (bytes.length >= 12 && header.getUint32(0, Endian.little) == 0x46546C67) {
      int offset = 12;
      while (offset + 8 <= bytes.length) {
        final int length = header.getUint32(offset, Endian.little);
        final int type = header.getUint32(offset + 4, Endian.little);
        final int start = offset + 8;
        if (type == 0x4E4F534A) {
          json = (jsonDecode(utf8.decode(bytes.sublist(start, start + length))) as Map<String, Object?>?) ?? <String, Object?>{};
        } else if (type == 0x004E4942) {
          bin = Uint8List.sublistView(bytes, start, start + length);
        }
        offset = start + length + ((4 - length % 4) % 4);
      }
    } else {
      json = (jsonDecode(utf8.decode(bytes)) as Map<String, Object?>?) ?? <String, Object?>{};
    }
    for (final Object? name in (json["extensionsRequired"] as List<Object?>?) ?? const <Object?>[]) {
      if (name == "KHR_draco_mesh_compression" || name == "EXT_meshopt_compression") {
        throw StateError("$name is not supported; export the model without mesh compression");
      }
    }
    final List<Uint8List> buffers = <Uint8List>[];
    for (final Object? raw in (json["buffers"] as List<Object?>?) ?? const <Object?>[]) {
      final Map<String, Object?> buffer = (raw as Map<String, Object?>?) ?? <String, Object?>{};
      final String? uri = buffer["uri"] as String?;
      buffers.add(uri == null ? (bin ?? Uint8List(0)) : await _resolve(uri, baseUrl));
    }
    final _Accessors accessors = _Accessors(json, buffers);

    for (final Object? raw in (json["images"] as List<Object?>?) ?? const <Object?>[]) {
      final Map<String, Object?> image = (raw as Map<String, Object?>?) ?? <String, Object?>{};
      try {
        final Uint8List imageBytes = image["bufferView"] is num ? accessors.view((image["bufferView"]! as num).toInt()) : await _resolve(image["uri"] as String? ?? "", baseUrl);
        data.images.add(await _decodeImage(imageBytes, image["mimeType"] as String? ?? "image/png"));
      } catch (_) {
        data.images.add(null);
      }
    }
    final List<Object?> samplers = (json["samplers"] as List<Object?>?) ?? const <Object?>[];
    for (final Object? raw in (json["textures"] as List<Object?>?) ?? const <Object?>[]) {
      final Map<String, Object?> texture = (raw as Map<String, Object?>?) ?? <String, Object?>{};
      final int samplerIndex = (texture["sampler"] as num?)?.toInt() ?? -1;
      final Map<String, Object?> sampler = samplerIndex >= 0 && samplerIndex < samplers.length ? (samplers[samplerIndex] as Map<String, Object?>?) ?? <String, Object?>{} : <String, Object?>{};
      data.textures.add((
        (texture["source"] as num?)?.toInt() ?? -1,
        (sampler["wrapS"] as num?)?.toInt() ?? _G.repeat,
        (sampler["wrapT"] as num?)?.toInt() ?? _G.repeat,
        (sampler["minFilter"] as num?)?.toInt() ?? _G.linearMipmapLinear,
      ));
    }
    for (final Object? raw in (json["materials"] as List<Object?>?) ?? const <Object?>[]) {
      data.materials.add(_material((raw as Map<String, Object?>?) ?? <String, Object?>{}));
    }
    for (final Object? raw in (json["meshes"] as List<Object?>?) ?? const <Object?>[]) {
      final Map<String, Object?> mesh = (raw as Map<String, Object?>?) ?? <String, Object?>{};
      final List<(_MeshData, int)> primitives = <(_MeshData, int)>[];
      for (final Object? p in (mesh["primitives"] as List<Object?>?) ?? const <Object?>[]) {
        final Map<String, Object?> primitive = (p as Map<String, Object?>?) ?? <String, Object?>{};
        final int mode = (primitive["mode"] as num?)?.toInt() ?? 4;
        final Map<String, Object?> attributes = (primitive["attributes"] as Map<String, Object?>?) ?? <String, Object?>{};
        if (mode < 4 || attributes["POSITION"] == null) continue;
        int? attr(String name) => (attributes[name] as num?)?.toInt();
        final List<double> positions = accessors.floats(attr("POSITION")!);
        List<int> indices = primitive["indices"] is num ? accessors.ints((primitive["indices"]! as num).toInt()) : List<int>.generate(positions.length ~/ 3, (int i) => i);
        if (mode == 5) {
          indices = <int>[
            for (int i = 0; i + 2 < indices.length; i++) ...(i.isEven ? <int>[indices[i], indices[i + 1], indices[i + 2]] : <int>[indices[i + 1], indices[i], indices[i + 2]]),
          ];
        } else if (mode == 6) {
          indices = <int>[
            for (int i = 1; i + 1 < indices.length; i++) ...<int>[indices[0], indices[i], indices[i + 1]],
          ];
        }
        final int? colorIndex = attr("COLOR_0");
        primitives.add((
          _MeshData.build(
            positions,
            attr("NORMAL") == null ? null : accessors.floats(attr("NORMAL")!),
            attr("TEXCOORD_0") == null ? null : accessors.floats(attr("TEXCOORD_0")!),
            attr("JOINTS_0") == null ? null : accessors.floats(attr("JOINTS_0")!),
            attr("WEIGHTS_0") == null ? null : accessors.floats(attr("WEIGHTS_0")!),
            colorIndex == null ? null : accessors.floats(colorIndex),
            colorIndex == null ? 4 : accessors.components(colorIndex),
            indices,
          ),
          (primitive["material"] as num?)?.toInt() ?? -1,
        ));
      }
      data.meshes.add(primitives);
    }
    for (final Object? raw in (json["nodes"] as List<Object?>?) ?? const <Object?>[]) {
      final Map<String, Object?> node = (raw as Map<String, Object?>?) ?? <String, Object?>{};
      final List<double> matrix = _M.doubles(node["matrix"], 16, 0);
      data.nodes.add(
        _GltfNode(
          ((node["children"] as List<Object?>?) ?? const <Object?>[]).map((Object? e) => (e! as num).toInt()).toList(),
          (node["mesh"] as num?)?.toInt() ?? -1,
          (node["skin"] as num?)?.toInt() ?? -1,
          _M.doubles(node["translation"], 3, 0),
          node["rotation"] == null ? <double>[0, 0, 0, 1] : _M.doubles(node["rotation"], 4, 0),
          _M.doubles(node["scale"], 3, 1),
          node["matrix"] == null ? null : Float32List.fromList(matrix),
        ),
      );
    }
    for (final Object? raw in (json["skins"] as List<Object?>?) ?? const <Object?>[]) {
      final Map<String, Object?> skin = (raw as Map<String, Object?>?) ?? <String, Object?>{};
      final List<int> joints = ((skin["joints"] as List<Object?>?) ?? const <Object?>[]).map((Object? e) => (e! as num).toInt()).toList();
      final List<double> inverse = skin["inverseBindMatrices"] is num
          ? accessors.floats((skin["inverseBindMatrices"]! as num).toInt())
          : <double>[for (int j = 0; j < joints.length; j++) ..._M.identity()];
      data.skins.add(_GltfSkin(joints, inverse));
    }
    int index = 0;
    for (final Object? raw in (json["animations"] as List<Object?>?) ?? const <Object?>[]) {
      final Map<String, Object?> animation = (raw as Map<String, Object?>?) ?? <String, Object?>{};
      final List<Object?> animationSamplers = (animation["samplers"] as List<Object?>?) ?? const <Object?>[];
      double duration = 0;
      final List<_GltfChannel> channels = <_GltfChannel>[];
      for (final Object? c in (animation["channels"] as List<Object?>?) ?? const <Object?>[]) {
        final Map<String, Object?> channel = (c as Map<String, Object?>?) ?? <String, Object?>{};
        final Map<String, Object?> target = (channel["target"] as Map<String, Object?>?) ?? <String, Object?>{};
        final String path = target["path"] as String? ?? "";
        if (target["node"] == null || path == "weights") continue;
        final Map<String, Object?> sampler = (animationSamplers[(channel["sampler"] as num?)?.toInt() ?? 0] as Map<String, Object?>?) ?? <String, Object?>{};
        final List<double> times = accessors.floats((sampler["input"] as num?)?.toInt() ?? 0);
        if (times.isNotEmpty) duration = math.max(duration, times.last);
        channels.add(_GltfChannel((target["node"]! as num).toInt(), path, times, accessors.floats((sampler["output"] as num?)?.toInt() ?? 0), sampler["interpolation"] as String? ?? "LINEAR"));
      }
      data.animations.add(_GltfAnimation(animation["name"] as String? ?? "animation$index", channels, duration));
      index++;
    }
    final List<Object?> scenes = (json["scenes"] as List<Object?>?) ?? const <Object?>[];
    if (scenes.isNotEmpty) {
      final int sceneIndex = ((json["scene"] as num?)?.toInt() ?? 0).clamp(0, scenes.length - 1);
      final Map<String, Object?> scene = (scenes[sceneIndex] as Map<String, Object?>?) ?? <String, Object?>{};
      data.roots = ((scene["nodes"] as List<Object?>?) ?? const <Object?>[]).map((Object? e) => (e! as num).toInt()).toList();
    } else {
      final Set<int> children = data.nodes.expand((_GltfNode n) => n.children).toSet();
      data.roots = <int>[
        for (int i = 0; i < data.nodes.length; i++)
          if (!children.contains(i)) i,
      ];
    }
    return data;
  }

  static _MaterialData _material(Map<String, Object?> material) {
    final _MaterialData data = _MaterialData();
    final Map<String, Object?> pbr = (material["pbrMetallicRoughness"] as Map<String, Object?>?) ?? <String, Object?>{};
    final Map<String, Object?> extensions = (material["extensions"] as Map<String, Object?>?) ?? <String, Object?>{};
    int textureIndex(Object? info) => info is Map<String, Object?> ? (info["index"] as num?)?.toInt() ?? -1 : -1;
    data.baseColor = _M.doubles(pbr["baseColorFactor"], 4, 1);
    data.metallic = (pbr["metallicFactor"] as num?)?.toDouble() ?? 1;
    data.roughness = (pbr["roughnessFactor"] as num?)?.toDouble() ?? 1;
    final double strength = ((extensions["KHR_materials_emissive_strength"] as Map<String, Object?>?)?["emissiveStrength"] as num?)?.toDouble() ?? 1;
    data.emissive = _M.doubles(material["emissiveFactor"], 3, 0).map((double e) => e * strength).toList();
    data.baseTexture = textureIndex(pbr["baseColorTexture"]);
    data.mrTexture = textureIndex(pbr["metallicRoughnessTexture"]);
    data.normalTexture = textureIndex(material["normalTexture"]);
    data.occlusionTexture = textureIndex(material["occlusionTexture"]);
    data.emissiveTexture = textureIndex(material["emissiveTexture"]);
    data.normalScale = ((material["normalTexture"] as Map<String, Object?>?)?["scale"] as num?)?.toDouble() ?? 1;
    data.occlusionStrength = ((material["occlusionTexture"] as Map<String, Object?>?)?["strength"] as num?)?.toDouble() ?? 1;
    data.alphaMode = switch (material["alphaMode"]) {
      "MASK" => 1,
      "BLEND" => 2,
      _ => 0,
    };
    data.alphaCutoff = (material["alphaCutoff"] as num?)?.toDouble() ?? 0.5;
    data.doubleSided = material["doubleSided"] == true;
    data.unlit = extensions.containsKey("KHR_materials_unlit");
    final Map<String, Object?>? transform = ((pbr["baseColorTexture"] as Map<String, Object?>?)?["extensions"] as Map<String, Object?>?)?["KHR_texture_transform"] as Map<String, Object?>?;
    if (transform != null) {
      final List<double> offset = _M.doubles(transform["offset"], 2, 0);
      final List<double> scale = _M.doubles(transform["scale"], 2, 1);
      final double r = (transform["rotation"] as num?)?.toDouble() ?? 0;
      final double c = math.cos(r);
      final double s = math.sin(r);
      data.uvTransform = Float32List.fromList(<double>[c * scale[0], -s * scale[0], 0, s * scale[1], c * scale[1], 0, offset[0], offset[1], 1]);
    }
    return data;
  }

  static Future<Uint8List> _resolve(String uri, String? baseUrl) async {
    if (uri.startsWith("data:")) return base64Decode(uri.substring(uri.indexOf(",") + 1));
    final String url = baseUrl == null || uri.startsWith("http") ? uri : "$baseUrl/$uri";
    return _fetchBytes(url);
  }
}

Future<Uint8List> _fetchBytes(String url) async {
  final web.Response response = await web.window.fetch(url.toJS).toDart;
  if (!response.ok) throw StateError("HTTP ${response.status} for $url");
  final JSArrayBuffer buffer = await response.arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}

Future<web.ImageBitmap> _decodeImage(Uint8List bytes, String mime) async {
  final web.Blob blob = web.Blob(<JSAny>[bytes.toJS].toJS, web.BlobPropertyBag(type: mime));
  final JSObject options = <String, Object?>{"premultiplyAlpha": "none", "colorSpaceConversion": "none"}.jsify()! as JSObject;
  final JSPromise<web.ImageBitmap> promise = globalContext.callMethod<JSPromise<web.ImageBitmap>>("createImageBitmap".toJS, blob, options);
  return promise.toDart;
}

class _Accessors {
  _Accessors(Map<String, Object?> json, this.buffers) : accessors = (json["accessors"] as List<Object?>?) ?? const <Object?>[], views = (json["bufferViews"] as List<Object?>?) ?? const <Object?>[];

  final List<Object?> accessors;
  final List<Object?> views;
  final List<Uint8List> buffers;

  Map<String, Object?> _accessor(int index) => (accessors[index] as Map<String, Object?>?) ?? <String, Object?>{};

  int components(int index) => switch (_accessor(index)["type"]) {
    "VEC2" => 2,
    "VEC3" => 3,
    "VEC4" || "MAT2" => 4,
    "MAT3" => 9,
    "MAT4" => 16,
    _ => 1,
  };

  static int _size(int type) => type == 5120 || type == 5121 ? 1 : (type == 5122 || type == 5123 ? 2 : 4);

  (ByteData, int, int) _viewInfo(int index) {
    final Map<String, Object?> view = (views[index] as Map<String, Object?>?) ?? <String, Object?>{};
    final Uint8List buffer = buffers[(view["buffer"] as num?)?.toInt() ?? 0];
    return (ByteData.sublistView(buffer), (view["byteOffset"] as num?)?.toInt() ?? 0, (view["byteStride"] as num?)?.toInt() ?? 0);
  }

  double _read(ByteData data, int position, int type, bool normalized) {
    if (position + _size(type) > data.lengthInBytes) return 0;
    switch (type) {
      case 5120:
        final double v = data.getInt8(position).toDouble();
        return normalized ? math.max(v / 127, -1) : v;
      case 5121:
        final double v = data.getUint8(position).toDouble();
        return normalized ? v / 255 : v;
      case 5122:
        final double v = data.getInt16(position, Endian.little).toDouble();
        return normalized ? math.max(v / 32767, -1) : v;
      case 5123:
        final double v = data.getUint16(position, Endian.little).toDouble();
        return normalized ? v / 65535 : v;
      case 5125:
        return data.getUint32(position, Endian.little).toDouble();
      default:
        return data.getFloat32(position, Endian.little);
    }
  }

  List<double> floats(int index) {
    final Map<String, Object?> accessor = _accessor(index);
    final int count = (accessor["count"] as num?)?.toInt() ?? 0;
    final int comps = components(index);
    final int type = (accessor["componentType"] as num?)?.toInt() ?? 5126;
    final bool normalized = accessor["normalized"] == true;
    final List<double> out = List<double>.filled(count * comps, 0);
    if (accessor["bufferView"] is num) {
      final (ByteData data, int viewOffset, int viewStride) = _viewInfo((accessor["bufferView"]! as num).toInt());
      final int size = _size(type);
      final int stride = viewStride == 0 ? size * comps : viewStride;
      final int base = viewOffset + ((accessor["byteOffset"] as num?)?.toInt() ?? 0);
      for (int i = 0; i < count; i++) {
        for (int c = 0; c < comps; c++) {
          out[i * comps + c] = _read(data, base + i * stride + c * size, type, normalized);
        }
      }
    }
    return out;
  }

  List<int> ints(int index) => floats(index).map((double v) => v.toInt()).toList();

  Uint8List view(int index) {
    final Map<String, Object?> view = (views[index] as Map<String, Object?>?) ?? <String, Object?>{};
    final Uint8List buffer = buffers[(view["buffer"] as num?)?.toInt() ?? 0];
    final int offset = (view["byteOffset"] as num?)?.toInt() ?? 0;
    final int length = (view["byteLength"] as num?)?.toInt() ?? 0;
    return Uint8List.sublistView(buffer, offset, offset + length);
  }
}

// =============================================================================
// WebGL2 — GPU side
// =============================================================================

const String _pbrVs = """#version 300 es
layout(location = 0) in vec3 a_Position;
layout(location = 1) in vec3 a_Normal;
layout(location = 2) in vec2 a_Uv;
layout(location = 3) in vec4 a_Joints;
layout(location = 4) in vec4 a_Weights;
layout(location = 5) in vec4 a_Color;
uniform mat4 u_Model;
uniform mat4 u_View;
uniform mat4 u_Projection;
uniform int u_Skinned;
uniform highp sampler2D u_JointTexture;
out vec3 v_WorldPos;
out vec3 v_Normal;
out vec2 v_Uv;
out vec4 v_Color;
mat4 jointMatrix(float index) {
    int x = int(index) * 4;
    return mat4(texelFetch(u_JointTexture, ivec2(x, 0), 0), texelFetch(u_JointTexture, ivec2(x + 1, 0), 0),
        texelFetch(u_JointTexture, ivec2(x + 2, 0), 0), texelFetch(u_JointTexture, ivec2(x + 3, 0), 0));
}
void main() {
    vec4 position = vec4(a_Position, 1.0);
    vec3 normal = a_Normal;
    if (u_Skinned == 1) {
        mat4 skin = a_Weights.x * jointMatrix(a_Joints.x) + a_Weights.y * jointMatrix(a_Joints.y)
            + a_Weights.z * jointMatrix(a_Joints.z) + a_Weights.w * jointMatrix(a_Joints.w);
        position = skin * position;
        normal = mat3(skin) * normal;
    }
    vec4 world = u_Model * position;
    v_WorldPos = world.xyz;
    v_Normal = normalize(transpose(inverse(mat3(u_Model))) * normal);
    v_Uv = a_Uv;
    v_Color = a_Color;
    gl_Position = u_Projection * u_View * world;
}
""";

const String _pbrFs = """#version 300 es
precision highp float;
const float PI = 3.14159265;
uniform vec4 u_BaseColor;
uniform float u_Metallic;
uniform float u_Roughness;
uniform vec3 u_Emissive;
uniform sampler2D u_BaseTexture;
uniform sampler2D u_MrTexture;
uniform sampler2D u_NormalTexture;
uniform sampler2D u_OcclusionTexture;
uniform sampler2D u_EmissiveTexture;
uniform int u_Flags;
uniform float u_NormalScale;
uniform float u_OcclusionStrength;
uniform int u_AlphaMode;
uniform float u_AlphaCutoff;
uniform float u_Opacity;
uniform mat3 u_UvTransform;
uniform vec3 u_CameraPos;
uniform vec3 u_LightDir;
uniform vec3 u_LightColor;
uniform vec3 u_Sh[9];
uniform int u_UseSh;
uniform vec3 u_Sky;
uniform vec3 u_Ground;
uniform float u_Exposure;
in vec3 v_WorldPos;
in vec3 v_Normal;
in vec2 v_Uv;
in vec4 v_Color;
out vec4 o_Color;
vec3 toLinear(vec3 c) { return pow(c, vec3(2.2)); }
vec3 aces(vec3 x) { return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0); }
vec3 irradiance(vec3 n) {
    if (u_UseSh == 1) {
        vec3 r = u_Sh[0] + u_Sh[1] * n.y + u_Sh[2] * n.z + u_Sh[3] * n.x + u_Sh[4] * (n.y * n.x) + u_Sh[5] * (n.y * n.z)
            + u_Sh[6] * (3.0 * n.z * n.z - 1.0) + u_Sh[7] * (n.z * n.x) + u_Sh[8] * (n.x * n.x - n.y * n.y);
        return max(r, vec3(0.0));
    }
    return mix(u_Ground, u_Sky, n.y * 0.5 + 0.5);
}
mat3 cotangentFrame(vec3 n, vec3 p, vec2 uv) {
    vec3 dp1 = dFdx(p);
    vec3 dp2 = dFdy(p);
    vec2 duv1 = dFdx(uv);
    vec2 duv2 = dFdy(uv);
    vec3 dp2perp = cross(dp2, n);
    vec3 dp1perp = cross(n, dp1);
    vec3 t = dp2perp * duv1.x + dp1perp * duv2.x;
    vec3 b = dp2perp * duv1.y + dp1perp * duv2.y;
    float invmax = inversesqrt(max(max(dot(t, t), dot(b, b)), 1e-12));
    return mat3(t * invmax, b * invmax, n);
}
void main() {
    vec2 uv = (u_UvTransform * vec3(v_Uv, 1.0)).xy;
    vec4 base = u_BaseColor * v_Color;
    vec4 texel = vec4(1.0);
    if ((u_Flags & 1) != 0) texel = texture(u_BaseTexture, uv);
    float alpha = base.a * texel.a * u_Opacity;
    if (u_AlphaMode == 1) {
        if (alpha < u_AlphaCutoff) discard;
        alpha = u_Opacity;
    } else if (u_AlphaMode == 0) {
        alpha = u_Opacity;
    }
    if ((u_Flags & 32) != 0) {
        o_Color = vec4(base.rgb * texel.rgb, alpha);
        return;
    }
    vec3 albedo = toLinear(texel.rgb) * base.rgb;
    float metallic = u_Metallic;
    float roughness = u_Roughness;
    if ((u_Flags & 2) != 0) {
        vec4 mr = texture(u_MrTexture, uv);
        roughness *= mr.g;
        metallic *= mr.b;
    }
    roughness = clamp(roughness, 0.04, 1.0);
    vec3 n = normalize(v_Normal);
    if (!gl_FrontFacing) n = -n;
    if ((u_Flags & 4) != 0) {
        vec3 t = texture(u_NormalTexture, uv).xyz * 2.0 - 1.0;
        t.xy *= u_NormalScale;
        n = normalize(cotangentFrame(n, v_WorldPos, uv) * t);
    }
    float occlusion = 1.0;
    if ((u_Flags & 8) != 0) occlusion = mix(1.0, texture(u_OcclusionTexture, uv).r, u_OcclusionStrength);
    vec3 emissive = u_Emissive;
    if ((u_Flags & 16) != 0) emissive *= toLinear(texture(u_EmissiveTexture, uv).rgb);
    vec3 v = normalize(u_CameraPos - v_WorldPos);
    vec3 l = normalize(u_LightDir);
    vec3 h = normalize(l + v);
    float ndl = max(dot(n, l), 0.0);
    float ndv = max(dot(n, v), 1e-4);
    float ndh = max(dot(n, h), 0.0);
    float vdh = max(dot(v, h), 0.0);
    float a = roughness * roughness;
    float a2 = a * a;
    float d = ndh * ndh * (a2 - 1.0) + 1.0;
    float distribution = a2 / (PI * d * d);
    float k = (roughness + 1.0) * (roughness + 1.0) / 8.0;
    float geometry = (ndl / (ndl * (1.0 - k) + k)) * (ndv / (ndv * (1.0 - k) + k));
    vec3 f0 = mix(vec3(0.04), albedo, metallic);
    vec3 fresnel = f0 + (1.0 - f0) * pow(1.0 - vdh, 5.0);
    vec3 specular = distribution * geometry * fresnel / (4.0 * ndl * ndv + 1e-4);
    vec3 kd = (1.0 - fresnel) * (1.0 - metallic);
    vec3 direct = (kd * albedo / PI + specular) * u_LightColor * ndl;
    vec3 r = reflect(-v, n);
    vec3 fr = f0 + (max(vec3(1.0 - roughness), f0) - f0) * pow(1.0 - ndv, 5.0);
    vec3 ambient = ((1.0 - fr) * (1.0 - metallic) * albedo * irradiance(n) + fr * irradiance(r) * (1.0 - roughness * 0.6)) * occlusion;
    vec3 color = (direct + ambient) * u_Exposure + emissive;
    o_Color = vec4(pow(aces(color), vec3(1.0 / 2.2)), alpha);
}
""";

const String _planeVs = """#version 300 es
layout(location = 0) in vec2 a_Local;
uniform mat4 u_Model;
uniform mat4 u_ViewProjection;
out vec2 v_Local;
void main() {
    v_Local = a_Local;
    gl_Position = u_ViewProjection * u_Model * vec4(a_Local.x, 0.0, a_Local.y, 1.0);
}
""";

const String _planeFs = """#version 300 es
precision highp float;
uniform vec4 u_Color;
uniform int u_Style;
in vec2 v_Local;
out vec4 o_Color;
void main() {
    float a = u_Color.a;
    if (u_Style == 0) {
        vec2 c = v_Local * 8.0;
        vec2 g = abs(fract(c - 0.5) - 0.5) / fwidth(c);
        a = u_Color.a * max(1.0 - min(min(g.x, g.y), 1.0), 0.12);
    } else if (u_Style == 1) {
        vec2 c = fract(v_Local * 10.0) - 0.5;
        a = u_Color.a * (1.0 - smoothstep(0.07, 0.11, length(c)));
    } else if (u_Style == 2) {
        a = u_Color.a * 0.45;
    }
    if (a < 0.003) discard;
    o_Color = vec4(u_Color.rgb, a);
}
""";

const String _quadVs = """#version 300 es
layout(location = 0) in vec2 a_Local;
uniform mat4 u_Mvp;
out vec2 v_Uv;
void main() {
    v_Uv = a_Local;
    gl_Position = u_Mvp * vec4(a_Local.x, 0.0, a_Local.y, 1.0);
}
""";

const String _quadFs = """#version 300 es
precision mediump float;
uniform vec4 u_Color;
uniform int u_Kind;
in vec2 v_Uv;
out vec4 o_Color;
void main() {
    float r = length(v_Uv);
    float a;
    if (u_Kind == 0) {
        a = u_Color.a * (1.0 - smoothstep(0.15, 1.0, r));
    } else {
        a = u_Color.a * (smoothstep(0.72, 0.78, r) - smoothstep(0.9, 0.96, r)) + u_Color.a * 0.6 * (1.0 - smoothstep(0.05, 0.09, r));
    }
    if (a < 0.003) discard;
    o_Color = vec4(u_Color.rgb, a);
}
""";

class _Program {
  _Program(this.gl, String vertex, String fragment) {
    final JSObject vs = _compile(_G.vertexShader, vertex);
    final JSObject fs = _compile(_G.fragmentShader, fragment);
    final JSObject program = gl.createProgram()!;
    gl.attachShader(program, vs);
    gl.attachShader(program, fs);
    gl.linkProgram(program);
    gl.deleteShader(vs);
    gl.deleteShader(fs);
    if (gl.getProgramParameter(program, _G.linkStatus).dartify() != true) throw StateError("Program link failed: ${gl.getProgramInfoLog(program)}");
    id = program;
  }

  final _Gl gl;
  late final JSObject id;
  final Map<String, JSObject?> _locations = <String, JSObject?>{};

  JSObject _compile(int type, String source) {
    final JSObject shader = gl.createShader(type)!;
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (gl.getShaderParameter(shader, _G.compileStatus).dartify() != true) throw StateError("Shader compile failed: ${gl.getShaderInfoLog(shader)}");
    return shader;
  }

  JSObject? loc(String name) => _locations.putIfAbsent(name, () => gl.getUniformLocation(id, name));

  void use() => gl.useProgram(id);

  void mat4(String name, Float32List value) => gl.uniformMatrix4fv(loc(name), false, value.toJS);

  void mat3(String name, Float32List value) => gl.uniformMatrix3fv(loc(name), false, value.toJS);

  void vec4(String name, List<double> v) => gl.uniform4f(loc(name), v[0], v[1], v[2], v.length > 3 ? v[3] : 1);

  void vec3(String name, List<double> v) => gl.uniform3f(loc(name), v[0], v[1], v[2]);

  void float(String name, double v) => gl.uniform1f(loc(name), v);

  void integer(String name, int v) => gl.uniform1i(loc(name), v);

  void texture(String name, int unit, JSObject? texture) {
    gl.activeTexture(_G.texture0 + unit);
    gl.bindTexture(_G.texture2d, texture);
    gl.uniform1i(loc(name), unit);
  }
}

class _GpuMesh {
  _GpuMesh(this.gl, _MeshData data) : count = data.indices.length, min = data.min, max = data.max {
    vao = gl.createVertexArray();
    gl.bindVertexArray(vao);
    vbo = gl.createBuffer();
    gl.bindBuffer(_G.arrayBuffer, vbo);
    gl.bufferData(_G.arrayBuffer, data.vertices.toJS, _G.staticDraw);
    const List<int> layout = <int>[3, 3, 2, 4, 4, 4];
    int offset = 0;
    for (int i = 0; i < layout.length; i++) {
      gl.enableVertexAttribArray(i);
      gl.vertexAttribPointer(i, layout[i], _G.float, false, _stride * 4, offset);
      offset += layout[i] * 4;
    }
    ibo = gl.createBuffer();
    gl.bindBuffer(_G.elementArrayBuffer, ibo);
    gl.bufferData(_G.elementArrayBuffer, data.indices.toJS, _G.staticDraw);
    gl.bindVertexArray(null);
  }

  final _Gl gl;
  final int count;
  final List<double> min;
  final List<double> max;
  JSObject? vao;
  JSObject? vbo;
  JSObject? ibo;

  void draw() {
    gl.bindVertexArray(vao);
    gl.drawElements(_G.triangles, count, _G.unsignedInt, 0);
    gl.bindVertexArray(null);
  }

  void release() {
    gl.deleteVertexArray(vao);
    gl.deleteBuffer(vbo);
    gl.deleteBuffer(ibo);
  }
}

class _Material {
  List<double> baseColor = <double>[1, 1, 1, 1];
  double metallic = 0;
  double roughness = 0.6;
  List<double> emissive = <double>[0, 0, 0];
  JSObject? baseTexture;
  JSObject? mrTexture;
  JSObject? normalTexture;
  JSObject? occlusionTexture;
  JSObject? emissiveTexture;
  double normalScale = 1;
  double occlusionStrength = 1;
  int alphaMode = 0;
  double alphaCutoff = 0.5;
  bool doubleSided = false;
  bool unlit = false;
  Float32List? uvTransform;
  double opacity = 1;
  bool occluder = false;
  bool renderOnTop = false;

  bool get isBlended => alphaMode == 2 || opacity < 0.999;

  void applyDart(Map<Object?, Object?>? map) {
    if (map == null) return;
    unlit = map["unlit"] == true;
    baseColor = unlit ? _M.argb(map["color"], 0xFFFFFFFF) : _M.linear(_M.argb(map["color"], 0xFFFFFFFF));
    metallic = (map["metallic"] as num?)?.toDouble() ?? 0;
    roughness = (map["roughness"] as num?)?.toDouble() ?? 0.6;
    opacity = (map["opacity"] as num?)?.toDouble() ?? 1;
    emissive = map["emissive"] is num ? _M.linear(_M.argb(map["emissive"], 0)).sublist(0, 3) : <double>[0, 0, 0];
    doubleSided = map["doubleSided"] == true;
    occluder = map["occluder"] == true;
    renderOnTop = map["renderOnTop"] == true;
    alphaMode = baseTexture != null || opacity < 1 || baseColor[3] < 1 ? 2 : 0;
  }
}

class _Environment {
  List<double> lightDirection = <double>[0.35, 0.85, 0.4];
  List<double> lightColor = <double>[2.4, 2.4, 2.3];
  Float32List? sh;
  List<double> sky = <double>[0.62, 0.64, 0.68];
  List<double> ground = <double>[0.3, 0.29, 0.28];
  double exposure = 1;
  List<double> cameraPosition = <double>[0, 0, 0];
  Float32List view = _M.identity();
  Float32List projection = _M.identity();
  Float32List viewProjection = _M.identity();
}

class _Model {
  _Model(this.gl, this.data) {
    textures = <JSObject?>[
      for (final (int, int, int, int) texture in data.textures)
        if (texture.$1 >= 0 && texture.$1 < data.images.length && data.images[texture.$1] != null) _Renderer.uploadImage(gl, data.images[texture.$1]!, texture.$2, texture.$3, texture.$4) else null,
    ];
    JSObject? tex(int index) => index >= 0 && index < textures.length ? textures[index] : null;
    materials = <_Material>[
      for (final _MaterialData m in data.materials)
        _Material()
          ..baseColor = m.baseColor
          ..metallic = m.metallic
          ..roughness = m.roughness
          ..emissive = m.emissive
          ..baseTexture = tex(m.baseTexture)
          ..mrTexture = tex(m.mrTexture)
          ..normalTexture = tex(m.normalTexture)
          ..occlusionTexture = tex(m.occlusionTexture)
          ..emissiveTexture = tex(m.emissiveTexture)
          ..normalScale = m.normalScale
          ..occlusionStrength = m.occlusionStrength
          ..alphaMode = m.alphaMode
          ..alphaCutoff = m.alphaCutoff
          ..doubleSided = m.doubleSided
          ..unlit = m.unlit
          ..uvTransform = m.uvTransform,
    ];
    meshes = <List<(_GpuMesh, int)>>[
      for (final List<(_MeshData, int)> primitives in data.meshes) <(_GpuMesh, int)>[for (final (_MeshData, int) p in primitives) (_GpuMesh(gl, p.$1), p.$2)],
    ];
  }

  final _Gl gl;
  final _GltfData data;
  late final List<JSObject?> textures;
  late final List<_Material> materials;
  late final List<List<(_GpuMesh, int)>> meshes;
  int references = 0;

  void release() {
    for (final JSObject? texture in textures) {
      gl.deleteTexture(texture);
    }
    for (final List<(_GpuMesh, int)> list in meshes) {
      for (final (_GpuMesh, int) p in list) {
        p.$1.release();
      }
    }
  }
}

class _ModelInstance {
  _ModelInstance(this.gl, this.model)
    : translations = model.data.nodes.map((_GltfNode n) => List<double>.of(n.translation)).toList(),
      rotations = model.data.nodes.map((_GltfNode n) => List<double>.of(n.rotation)).toList(),
      scales = model.data.nodes.map((_GltfNode n) => List<double>.of(n.scale)).toList(),
      globals = List<Float32List>.generate(model.data.nodes.length, (int _) => _M.identity()) {
    _updateGlobals();
    _computeBounds();
    for (final _GltfSkin skin in model.data.skins) {
      final JSObject? texture = gl.createTexture();
      gl.bindTexture(_G.texture2d, texture);
      gl.texParameteri(_G.texture2d, _G.textureMinFilter, _G.nearest);
      gl.texParameteri(_G.texture2d, _G.textureMagFilter, _G.nearest);
      gl.texImage2D(_G.texture2d, 0, _G.rgba32f, math.max(1, skin.joints.length * 4), 1, 0, _G.rgba, _G.float, null);
      jointTextures.add(texture);
    }
  }

  final _Gl gl;
  final _Model model;
  final List<List<double>> translations;
  final List<List<double>> rotations;
  final List<List<double>> scales;
  final List<Float32List> globals;
  final List<JSObject?> jointTextures = <JSObject?>[];
  final _Material _fallback = _Material()..roughness = 0.8;
  List<int> clips = <int>[];
  double time = 0;
  bool loop = true;
  double speed = 1;
  bool playing = false;
  void Function()? onFinished;
  List<double> min = <double>[0, 0, 0];
  List<double> max = <double>[0, 0, 0];

  List<String> get animationNames => model.data.animations.map((_GltfAnimation a) => a.name).toList();

  void play(String? name, int index, bool loop, double speed) {
    final List<_GltfAnimation> animations = model.data.animations;
    if (animations.isEmpty) {
      clips = <int>[];
    } else if (name == "*") {
      clips = List<int>.generate(animations.length, (int i) => i);
    } else if (name != null) {
      final int found = animations.indexWhere((_GltfAnimation a) => a.name == name);
      clips = found < 0 ? <int>[] : <int>[found];
    } else {
      clips = <int>[index.clamp(0, animations.length - 1)];
    }
    this.loop = loop;
    this.speed = speed;
    time = 0;
    playing = clips.isNotEmpty;
  }

  void update(double delta) {
    if (playing && clips.isNotEmpty) {
      time += delta * speed;
      final double duration = clips.map((int c) => model.data.animations[c].duration).reduce(math.max);
      if (duration > 0 && time > duration) {
        if (loop) {
          time %= duration;
        } else {
          time = duration;
          playing = false;
          onFinished?.call();
        }
      }
      for (final int clip in clips) {
        _sample(model.data.animations[clip], time);
      }
    }
    _updateGlobals();
  }

  void _sample(_GltfAnimation animation, double t) {
    for (final _GltfChannel channel in animation.channels) {
      final List<double> times = channel.times;
      if (times.isEmpty || channel.node >= translations.length) continue;
      final int c = channel.path == "rotation" ? 4 : 3;
      final bool cubic = channel.interpolation == "CUBICSPLINE";
      final int stride = cubic ? c * 3 : c;
      int k = 0;
      if (t >= times.last) {
        k = times.length - 1;
      } else if (t > times.first) {
        int lo = 0;
        int hi = times.length - 1;
        while (hi - lo > 1) {
          final int mid = (lo + hi) ~/ 2;
          if (times[mid] <= t) {
            lo = mid;
          } else {
            hi = mid;
          }
        }
        k = lo;
      }
      final int next = math.min(k + 1, times.length - 1);
      final double span = times[next] - times[k];
      final double f = span <= 0 || t <= times[k] ? 0 : ((t - times[k]) / span).clamp(0, 1).toDouble();
      final int offset = cubic ? c : 0;
      double value(int key, int i) {
        final int index = key * stride + offset + i;
        return index < channel.values.length ? channel.values[index] : 0;
      }

      final List<double> a = <double>[for (int i = 0; i < c; i++) value(k, i)];
      final List<double> b = <double>[for (int i = 0; i < c; i++) value(next, i)];
      final List<double> result = channel.interpolation == "STEP" || k == next ? a : (c == 4 ? _M.qSlerp(a, b, f) : <double>[for (int i = 0; i < c; i++) a[i] + (b[i] - a[i]) * f]);
      switch (channel.path) {
        case "translation":
          translations[channel.node] = result;
        case "rotation":
          rotations[channel.node] = result;
        case "scale":
          scales[channel.node] = result;
      }
    }
  }

  void _updateGlobals() {
    for (final int root in model.data.roots) {
      _visit(root, _M.identity(), 0);
    }
  }

  void _visit(int index, Float32List parent, int depth) {
    if (index < 0 || index >= model.data.nodes.length || depth > 64) return;
    final _GltfNode node = model.data.nodes[index];
    final Float32List local = node.matrix ?? _M.compose(translations[index], rotations[index], scales[index]);
    globals[index] = _M.multiply(parent, local);
    for (final int child in node.children) {
      _visit(child, globals[index], depth + 1);
    }
  }

  void _computeBounds() {
    final List<double> lo = <double>[double.infinity, double.infinity, double.infinity];
    final List<double> hi = <double>[-double.infinity, -double.infinity, -double.infinity];
    bool any = false;
    for (int i = 0; i < model.data.nodes.length; i++) {
      final int mesh = model.data.nodes[i].mesh;
      if (mesh < 0 || mesh >= model.meshes.length) continue;
      for (final (_GpuMesh, int) p in model.meshes[mesh]) {
        final (List<double>, List<double>) box = _M.aabb(globals[i], p.$1.min, p.$1.max);
        for (int k = 0; k < 3; k++) {
          lo[k] = math.min(lo[k], box.$1[k]);
          hi[k] = math.max(hi[k], box.$2[k]);
        }
        any = true;
      }
    }
    if (any) {
      min = lo;
      max = hi;
    }
  }

  void draw(_Renderer renderer, Float32List modelMatrix, _Environment env, int pass, double opacity) {
    for (int i = 0; i < model.data.nodes.length; i++) {
      final _GltfNode node = model.data.nodes[i];
      if (node.mesh < 0 || node.mesh >= model.meshes.length) continue;
      final Float32List world = _M.multiply(modelMatrix, globals[i]);
      JSObject? jointTexture;
      if (node.skin >= 0 && node.skin < model.data.skins.length) jointTexture = _uploadJoints(node.skin, i);
      for (final (_GpuMesh, int) p in model.meshes[node.mesh]) {
        final _Material material = p.$2 >= 0 && p.$2 < model.materials.length ? model.materials[p.$2] : _fallback;
        final bool blended = material.alphaMode == 2 || opacity < 0.999;
        if (pass == 0 && blended || pass == 1 && !blended) continue;
        renderer.drawMesh(p.$1, material, world, env, jointTexture, opacity);
      }
    }
  }

  JSObject? _uploadJoints(int skinIndex, int meshNode) {
    final _GltfSkin skin = model.data.skins[skinIndex];
    final Float32List inverseMesh = _M.invert(globals[meshNode]);
    final Float32List data = Float32List(skin.joints.length * 16);
    for (int j = 0; j < skin.joints.length; j++) {
      final int joint = skin.joints[j];
      final Float32List bind = Float32List.fromList(skin.inverseBind.sublist(j * 16, j * 16 + 16));
      final Float32List jointMatrix = _M.multiply(inverseMesh, _M.multiply(joint < globals.length ? globals[joint] : _M.identity(), bind));
      data.setRange(j * 16, j * 16 + 16, jointMatrix);
    }
    final JSObject? texture = jointTextures[skinIndex];
    gl.bindTexture(_G.texture2d, texture);
    gl.texSubImage2D(_G.texture2d, 0, 0, 0, skin.joints.length * 4, 1, _G.rgba, _G.float, data.toJS);
    return texture;
  }

  void release() {
    for (final JSObject? texture in jointTextures) {
      gl.deleteTexture(texture);
    }
  }
}

class _Renderer {
  _Renderer(this.gl) {
    pbr = _Program(gl, _pbrVs, _pbrFs);
    plane = _Program(gl, _planeVs, _planeFs);
    quad = _Program(gl, _quadVs, _quadFs);
    white = gl.createTexture();
    gl.bindTexture(_G.texture2d, white);
    gl.texImage2D(_G.texture2d, 0, _G.rgba8, 1, 1, 0, _G.rgba, _G.unsignedByte, Uint8List.fromList(<int>[255, 255, 255, 255]).toJS);
    dynamicVao = gl.createVertexArray();
    dynamicVbo = gl.createBuffer();
    quadVao = gl.createVertexArray();
    final JSObject? quadVbo = gl.createBuffer();
    gl.bindVertexArray(quadVao);
    gl.bindBuffer(_G.arrayBuffer, quadVbo);
    gl.bufferData(_G.arrayBuffer, Float32List.fromList(<double>[-1, -1, 1, -1, -1, 1, 1, 1]).toJS, _G.staticDraw);
    gl.enableVertexAttribArray(0);
    gl.vertexAttribPointer(0, 2, _G.float, false, 8, 0);
    gl.bindVertexArray(null);
  }

  final _Gl gl;
  late final _Program pbr;
  late final _Program plane;
  late final _Program quad;
  JSObject? white;
  JSObject? dynamicVao;
  JSObject? dynamicVbo;
  JSObject? quadVao;
  static final Float32List _identity3 = Float32List.fromList(<double>[1, 0, 0, 0, 1, 0, 0, 0, 1]);

  static JSObject? uploadImage(_Gl gl, JSAny image, int wrapS, int wrapT, int minFilter) {
    final JSObject? texture = gl.createTexture();
    gl.bindTexture(_G.texture2d, texture);
    gl.pixelStorei(_G.unpackFlipY, 0);
    gl.pixelStorei(_G.unpackPremultiply, 0);
    gl.pixelStorei(_G.unpackColorspace, 0);
    gl.texImage2DSource(_G.texture2d, 0, _G.rgba8, _G.rgba, _G.unsignedByte, image);
    gl.texParameteri(_G.texture2d, _G.textureWrapS, wrapS);
    gl.texParameteri(_G.texture2d, _G.textureWrapT, wrapT);
    gl.texParameteri(_G.texture2d, _G.textureMinFilter, minFilter);
    gl.texParameteri(_G.texture2d, _G.textureMagFilter, _G.linear);
    if (minFilter != _G.linear && minFilter != _G.nearest) gl.generateMipmap(_G.texture2d);
    return texture;
  }

  void drawMesh(_GpuMesh mesh, _Material material, Float32List model, _Environment env, JSObject? jointTexture, double opacity) {
    pbr.use();
    pbr.mat4("u_Model", model);
    pbr.mat4("u_View", env.view);
    pbr.mat4("u_Projection", env.projection);
    pbr.integer("u_Skinned", jointTexture != null ? 1 : 0);
    pbr.texture("u_JointTexture", 6, jointTexture ?? white);
    pbr.vec4("u_BaseColor", material.baseColor);
    pbr.float("u_Metallic", material.metallic);
    pbr.float("u_Roughness", material.roughness);
    pbr.vec3("u_Emissive", material.emissive);
    int flags = 0;
    if (material.baseTexture != null) flags |= 1;
    if (material.mrTexture != null) flags |= 2;
    if (material.normalTexture != null) flags |= 4;
    if (material.occlusionTexture != null) flags |= 8;
    if (material.emissiveTexture != null) flags |= 16;
    if (material.unlit) flags |= 32;
    pbr.integer("u_Flags", flags);
    pbr.texture("u_BaseTexture", 0, material.baseTexture ?? white);
    pbr.texture("u_MrTexture", 1, material.mrTexture ?? white);
    pbr.texture("u_NormalTexture", 2, material.normalTexture ?? white);
    pbr.texture("u_OcclusionTexture", 3, material.occlusionTexture ?? white);
    pbr.texture("u_EmissiveTexture", 4, material.emissiveTexture ?? white);
    pbr.float("u_NormalScale", material.normalScale);
    pbr.float("u_OcclusionStrength", material.occlusionStrength);
    pbr.integer("u_AlphaMode", material.alphaMode);
    pbr.float("u_AlphaCutoff", material.alphaCutoff);
    pbr.float("u_Opacity", material.opacity * opacity);
    pbr.mat3("u_UvTransform", material.uvTransform ?? _identity3);
    pbr.vec3("u_CameraPos", env.cameraPosition);
    pbr.vec3("u_LightDir", env.lightDirection);
    pbr.vec3("u_LightColor", env.lightColor);
    final Float32List? sh = env.sh;
    pbr.integer("u_UseSh", sh != null ? 1 : 0);
    if (sh != null) gl.uniform3fv(pbr.loc("u_Sh"), sh.toJS);
    pbr.vec3("u_Sky", env.sky);
    pbr.vec3("u_Ground", env.ground);
    pbr.float("u_Exposure", env.exposure);
    if (material.doubleSided) {
      gl.disable(_G.cullFace);
    } else {
      gl.enable(_G.cullFace);
    }
    if (material.renderOnTop) gl.disable(_G.depthTest);
    if (material.occluder) gl.colorMask(false, false, false, false);
    mesh.draw();
    if (material.occluder) gl.colorMask(true, true, true, true);
    if (material.renderOnTop) gl.enable(_G.depthTest);
    gl.disable(_G.cullFace);
  }

  void drawPlane(Float32List polygon, Float32List model, Float32List viewProjection, List<double> color, int style) {
    final int count = polygon.length ~/ 2;
    if (count < 3) return;
    plane.use();
    plane.mat4("u_Model", model);
    plane.mat4("u_ViewProjection", viewProjection);
    plane.vec4("u_Color", color);
    plane.integer("u_Style", style == 3 ? 2 : style);
    gl.bindVertexArray(dynamicVao);
    gl.bindBuffer(_G.arrayBuffer, dynamicVbo);
    gl.bufferData(_G.arrayBuffer, polygon.toJS, _G.streamDraw);
    gl.enableVertexAttribArray(0);
    gl.vertexAttribPointer(0, 2, _G.float, false, 8, 0);
    gl.depthMask(false);
    gl.drawArrays(style == 3 ? _G.lineLoop : _G.triangleFan, 0, count);
    gl.depthMask(true);
    gl.bindVertexArray(null);
  }

  void drawQuad(Float32List mvp, List<double> color, int kind) {
    quad.use();
    quad.mat4("u_Mvp", mvp);
    quad.vec4("u_Color", color);
    quad.integer("u_Kind", kind);
    gl.depthMask(false);
    gl.bindVertexArray(quadVao);
    gl.drawArrays(_G.triangleStrip, 0, 4);
    gl.bindVertexArray(null);
    gl.depthMask(true);
  }
}

// =============================================================================
// Scene nodes
// =============================================================================

class _Node {
  _Node(this.id);

  final String id;
  Map<Object?, Object?> map = <Object?, Object?>{};
  String type = "group";
  String? anchorId;
  String? parentId;
  List<double> position = <double>[0, 0, 0];
  List<double> rotation = <double>[0, 0, 0, 1];
  List<double> scale = <double>[1, 1, 1];
  String billboard = "none";
  bool visible = true;
  bool castShadow = true;
  bool hittable = true;
  double? fitSize;
  String pivot = "original";
  double width = 0.1;
  double height = 0.1;
  double depth = 0.1;
  double radius = 0.05;
  _Material material = _Material();
  _GpuMesh? mesh;
  _ModelInstance? model;
  String? modelKey;
  web.HTMLVideoElement? video;
  JSObject? imageTexture;
  Float32List normalization = _M.identity();
  String sourceKey = "";
  bool loaded = false;
  int token = 0;
  Float32List world = _M.identity();
  int worldFrame = -1;
  bool worldValid = false;

  void apply(Map<Object?, Object?> next) {
    map = next;
    type = next["type"] as String? ?? type;
    anchorId = next["anchorId"] as String?;
    parentId = next["parentId"] as String?;
    position = _M.doubles(next["position"], 3, 0);
    final List<double> q = _M.doubles(next["rotation"], 4, 0);
    rotation = q.every((double v) => v == 0) ? <double>[0, 0, 0, 1] : _M.qNormalize(q);
    scale = _M.doubles(next["scale"], 3, 1);
    billboard = next["billboard"] as String? ?? "none";
    visible = next["visible"] != false;
    castShadow = next["castShadow"] != false;
    hittable = next["hittable"] != false;
    fitSize = (next["fitSize"] as num?)?.toDouble();
    pivot = next["pivot"] as String? ?? "original";
    width = (next["width"] as num?)?.toDouble() ?? width;
    height = (next["height"] as num?)?.toDouble() ?? height;
    depth = (next["depth"] as num?)?.toDouble() ?? depth;
    radius = (next["radius"] as num?)?.toDouble() ?? radius;
    if (type != "model") {
      final JSObject? texture = material.baseTexture;
      material.applyDart(next["material"] as Map<Object?, Object?>?);
      material.baseTexture = texture;
      if (type == "image" || type == "video") {
        material.alphaMode = 2;
        material.doubleSided = true;
        if (type == "video") material.unlit = true;
      }
    }
  }

  (List<double>, List<double>)? bounds() {
    final _ModelInstance? instance = model;
    if (instance != null) return (instance.min, instance.max);
    final _GpuMesh? m = mesh;
    return m == null ? null : (m.min, m.max);
  }

  void updateNormalization() {
    final _ModelInstance? instance = model;
    if (instance == null) return;
    final List<double> size = <double>[for (int i = 0; i < 3; i++) instance.max[i] - instance.min[i]];
    final double largest = math.max(size[0], math.max(size[1], size[2]));
    final double s = fitSize != null && largest > 0 ? fitSize! / largest : 1;
    final double cx = (instance.min[0] + instance.max[0]) / 2;
    final double cy = (instance.min[1] + instance.max[1]) / 2;
    final double cz = (instance.min[2] + instance.max[2]) / 2;
    final List<double> offset = switch (pivot) {
      "bottom" => <double>[-cx, -instance.min[1], -cz],
      "center" => <double>[-cx, -cy, -cz],
      _ => <double>[0, 0, 0],
    };
    normalization = _M.multiply(_M.compose(<double>[0, 0, 0], <double>[0, 0, 0, 1], <double>[s, s, s]), _M.compose(offset, <double>[0, 0, 0, 1], <double>[1, 1, 1]));
  }
}

class _PendingHit {
  _PendingHit(this.x, this.y, this.types, this.completer);

  final double x;
  final double y;
  final List<String> types;
  final Completer<List<Map<String, Object?>>> completer;
  JSObject? source;
  bool requested = false;
}

// =============================================================================
// Session
// =============================================================================

class _WebArSession {
  _WebArSession(this.id, this.config, this._emit) {
    viewType = "u-ar-$id";
    _container.style
      ..position = "relative"
      ..width = "100%"
      ..height = "100%"
      ..overflow = "hidden"
      ..pointerEvents = "none";
    _video
      ..autoplay = true
      ..muted = true
      ..setAttribute("playsinline", "true");
    _video.style
      ..position = "absolute"
      ..left = "0"
      ..top = "0"
      ..width = "100%"
      ..height = "100%"
      ..objectFit = "cover"
      ..display = "none";
    _canvas.style
      ..position = "absolute"
      ..left = "0"
      ..top = "0"
      ..width = "100%"
      ..height = "100%";
    _container
      ..append(_video)
      ..append(_canvas);
    final JSObject options = JSObject()
      ..["alpha"] = true.toJS
      ..["antialias"] = true.toJS
      ..["premultipliedAlpha"] = true.toJS
      ..["xrCompatible"] = true.toJS;
    _gl = _canvas.getContext("webgl2", options)! as _Gl;
    _renderer = _Renderer(_gl);
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) => _container);
  }

  final int id;
  Map<Object?, Object?> config;
  final void Function(Map<String, Object?> payload) _emit;
  late final String viewType;
  final web.HTMLDivElement _container = web.HTMLDivElement();
  final web.HTMLCanvasElement _canvas = web.HTMLCanvasElement();
  final web.HTMLVideoElement _video = web.HTMLVideoElement();
  late final _Gl _gl;
  late final _Renderer _renderer;
  final _Environment _env = _Environment();
  final Map<String, _Node> _nodes = <String, _Node>{};
  final Map<String, _Model> _models = <String, _Model>{};
  final Map<String, Float32List> _anchors = <String, Float32List>{};
  final Map<String, JSObject> _xrAnchors = <String, JSObject>{};
  final List<(String, Float32List)> _pendingXrAnchors = <(String, Float32List)>[];
  final Map<String, Map<String, Object?>> _planes = <String, Map<String, Object?>>{};
  final Map<String, (Float32List, Float32List, bool)> _planeDraw = <String, (Float32List, Float32List, bool)>{};
  final List<_PendingHit> _pendingHits = <_PendingHit>[];
  List<Map<Object?, Object?>> _tracks = <Map<Object?, Object?>>[];
  Float32List _camera = _M.identity();
  double _fov = 45;
  int _frame = 0;
  double _lastTime = 0;
  double _lastEvent = 0;
  double _lastPlaneEmit = 0;
  int _width = 1;
  int _height = 1;
  bool _started = false;
  bool _disposed = false;
  bool _loopRunning = false;
  String _mode = "viewer";
  _XrSession? _xr;
  JSObject? _refSpace;
  JSObject? _viewerSpace;
  JSObject? _centerSource;
  JSObject? _lightProbe;
  Map<String, Object?>? _centerHit;
  Float32List? _centerMatrix;
  Map<String, Object?>? _light;
  String _tracking = "";
  List<double> _viewport = <double>[0, 0, 1, 1];
  double? _alpha;
  double? _beta;
  double? _gamma;
  double? _compass;
  JSFunction<Function>? _orientationListener;
  web.MediaStream? _stream;
  (Map<Object?, Object?>, Completer<Uint8List?>)? _pendingSnapshot;
  web.MediaRecorder? _recorder;
  final List<web.Blob> _chunks = <web.Blob>[];
  DateTime _recordingStart = DateTime.now();
  int _planeCounter = 0;
  String? _savedBackground;

  bool get _isViewer => config["mode"] == "viewer";

  Map<String, Object?> capabilities(Map<String, Object?> base) => base;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void start() {
    if (_started) return;
    _started = true;
    _mode = "viewer";
    _startLoop();
    _emit(<String, Object?>{"type": "state", "session": "running", "tracking": _isViewer ? "normal" : "notAvailable", "reason": _isViewer ? "none" : "initializing", "xr": false});
  }

  void _startLoop() {
    if (_loopRunning || _disposed) return;
    _loopRunning = true;
    void tick(JSNumber time) {
      if (_disposed || _mode == "xr") {
        _loopRunning = false;
        return;
      }
      _onFrame(time.toDartDouble);
      web.window.requestAnimationFrame(tick.toJS);
    }

    web.window.requestAnimationFrame(tick.toJS);
  }

  void dispose() {
    _disposed = true;
    unawaited(exitXr());
    _stopSensor();
    for (final _Node node in _nodes.values) {
      _releaseContent(node);
    }
    _nodes.clear();
    for (final _Model model in _models.values) {
      model.release();
    }
    _models.clear();
    _container.remove();
  }

  /// Lets pointer events fall through the platform-view wrapper to Flutter, so
  /// the gesture detectors laid over the view receive them.
  void _releasePointers() {
    web.Element? element = _container.parentElement;
    for (int i = 0; i < 3 && element != null; i++) {
      final String tag = element.tagName.toLowerCase();
      if (tag == "flutter-view" || tag == "flt-glass-pane" || tag == "body") break;
      (element as web.HTMLElement).style.pointerEvents = "none";
      element = element.parentElement;
    }
  }

  void _resize() {
    _releasePointers();
    final double ratio = web.window.devicePixelRatio;
    final int w = math.max(1, (_container.clientWidth * ratio).round());
    final int h = math.max(1, (_container.clientHeight * ratio).round());
    if (w != _width || h != _height) {
      _width = w;
      _height = h;
      _canvas
        ..width = w
        ..height = h;
    }
  }

  // ---------------------------------------------------------------------------
  // Frames
  // ---------------------------------------------------------------------------

  void _onFrame(double time) {
    final double delta = _lastTime == 0 ? 0 : ((time - _lastTime) / 1000).clamp(0, 0.1).toDouble();
    _lastTime = time;
    _frame++;
    _resize();
    if (_mode == "sensor") {
      _updateSensorCamera();
    } else {
      _updateOrbitCamera();
    }
    _applyEnvironment();
    _advance(delta);
    _gl.bindFramebuffer(_G.framebuffer, null);
    _viewport = <double>[0, 0, _width.toDouble(), _height.toDouble()];
    _drawScene(clear: true);
    _finishFrame();
  }

  void _advance(double delta) {
    for (final _Node node in _nodes.values) {
      node.model?.update(delta);
      final web.HTMLVideoElement? video = node.video;
      final JSObject? texture = node.imageTexture;
      if (video != null && texture != null && video.readyState >= 2) {
        _gl.bindTexture(_G.texture2d, texture);
        _gl.texImage2DSource(_G.texture2d, 0, _G.rgba8, _G.rgba, _G.unsignedByte, video);
      }
    }
  }

  void _finishFrame() {
    final (Map<Object?, Object?>, Completer<Uint8List?>)? snapshot = _pendingSnapshot;
    if (snapshot != null) {
      _pendingSnapshot = null;
      unawaited(_readSnapshot(snapshot.$1, snapshot.$2));
    }
    final double now = web.window.performance.now();
    final int rate = ((config["eventRate"] as num?)?.toInt() ?? 30).clamp(1, 60);
    if (now - _lastEvent >= 1000 / rate) {
      _lastEvent = now;
      _emitFrame();
    }
  }

  void _updateOrbitCamera() {
    final Map<Object?, Object?> orbit = (config["orbit"] as Map<Object?, Object?>?) ?? const <Object?, Object?>{};
    final double yaw = ((orbit["yaw"] as num?)?.toDouble() ?? 30) * math.pi / 180;
    final double pitch = ((orbit["pitch"] as num?)?.toDouble() ?? 15) * math.pi / 180;
    final double distance = (orbit["distance"] as num?)?.toDouble() ?? 1.5;
    final List<double> target = _M.doubles(orbit["target"], 3, 0);
    _fov = (orbit["fov"] as num?)?.toDouble() ?? 45;
    final List<double> eye = <double>[
      target[0] + distance * math.cos(pitch) * math.sin(yaw),
      target[1] + distance * math.sin(pitch),
      target[2] + distance * math.cos(pitch) * math.cos(yaw),
    ];
    _env.view = _M.lookAt(eye, target, <double>[0, 1, 0]);
    _env.projection = _M.perspective(_fov * math.pi / 180, _width / _height, math.max(0.005, distance * 0.01), distance * 50 + 50);
    _camera = _M.invert(_env.view);
    _env.cameraPosition = eye;
    _env.viewProjection = _M.multiply(_env.projection, _env.view);
  }

  void _applyEnvironment() {
    final double intensity = (config["environmentIntensity"] as num?)?.toDouble() ?? 1;
    _env.exposure = (config["exposure"] as num?)?.toDouble() ?? 1;
    final Map<String, Object?>? light = _light;
    if (light != null && light["sh"] is List<double>) {
      final List<double> sh = light["sh"]! as List<double>;
      const List<double> factors = <double>[0.282095, 0.325735, 0.325735, 0.325735, 0.273137, 0.273137, 0.078848, 0.273137, 0.136569];
      _env.sh = Float32List.fromList(<double>[for (int i = 0; i < 27; i++) sh[i] * factors[i ~/ 3] * intensity]);
      _env.lightDirection = _M.doubles(light["direction"], 3, 1);
      _env.lightColor = _M.doubles(light["mainIntensity"], 3, 2).map((double v) => v * intensity).toList();
    } else {
      _env.sh = null;
      _env.lightDirection = <double>[0.35, 0.85, 0.4];
      _env.lightColor = <double>[2.4 * intensity, 2.4 * intensity, 2.3 * intensity];
      _env.sky = <double>[0.62 * intensity, 0.64 * intensity, 0.68 * intensity];
      _env.ground = <double>[0.3 * intensity, 0.29 * intensity, 0.28 * intensity];
    }
  }

  Float32List? _anchorMatrix(String id) {
    if (id == "camera") return _camera;
    return _anchors[id];
  }

  Float32List? _worldOf(_Node node, [int depth = 0]) {
    if (node.worldFrame == _frame) return node.worldValid ? node.world : null;
    node.worldFrame = _frame;
    node.worldValid = false;
    if (depth > 32) return null;
    final String? parentId = node.parentId;
    final String? anchorId = node.anchorId;
    Float32List? base;
    if (parentId != null) {
      final _Node? parent = _nodes[parentId];
      base = parent == null ? null : _worldOf(parent, depth + 1);
    } else if (anchorId != null) {
      base = _anchorMatrix(anchorId);
    } else {
      base = _M.identity();
    }
    if (base == null) return null;
    Float32List world = _M.multiply(base, _M.compose(node.position, node.rotation, node.scale));
    if (node.billboard != "none") {
      final List<double> position = _M.translation(world);
      final List<double> baseScale = _M.scaleOf(base);
      final List<double> q = _M.billboard(position, _M.translation(_camera), node.billboard == "yAxis");
      world = _M.compose(position, q, <double>[node.scale[0] * baseScale[0], node.scale[1] * baseScale[1], node.scale[2] * baseScale[2]]);
    }
    node.world = _M.multiply(world, node.normalization);
    node.worldValid = true;
    return node.world;
  }

  void _drawScene({required bool clear}) {
    _gl.viewport(_viewport[0].toInt(), _viewport[1].toInt(), _viewport[2].toInt(), _viewport[3].toInt());
    if (clear) {
      if (_isViewer && config["transparentBackground"] != true) {
        final List<double> bg = _M.argb(config["background"], 0xFFF2F2F2);
        _gl.clearColor(bg[0], bg[1], bg[2], 1);
      } else {
        _gl.clearColor(0, 0, 0, 0);
      }
      _gl.clear(_G.colorBufferBit | _G.depthBufferBit);
    }
    _gl.enable(_G.depthTest);
    _gl.depthFunc(_G.lequal);
    _gl.enable(_G.blend);
    _gl.blendFuncSeparate(_G.srcAlpha, _G.oneMinusSrcAlpha, _G.one, _G.oneMinusSrcAlpha);

    if (_mode == "xr") {
      final int style = switch (config["planeStyle"]) {
        "dots" => 1,
        "solid" => 2,
        "outline" => 3,
        "hidden" => -1,
        _ => 0,
      };
      if (style >= 0) {
        final List<double> color = _M.argb(config["planeColor"], 0x80FFFFFF);
        for (final (Float32List, Float32List, bool) plane in _planeDraw.values) {
          _renderer.drawPlane(plane.$2, plane.$1, _env.viewProjection, color, style);
        }
      }
    }
    _drawShadows();
    final List<_Node> visible = _nodes.values.where((_Node n) => n.visible && n.loaded && _worldOf(n) != null).toList();
    for (final _Node node in visible) {
      if (!node.material.renderOnTop) _drawNode(node, 0);
    }
    final List<double> camera = _M.translation(_camera);
    final List<_Node> blended = visible.where((_Node n) => !n.material.renderOnTop).toList()
      ..sort((_Node a, _Node b) => _M.distance(_M.translation(b.world), camera).compareTo(_M.distance(_M.translation(a.world), camera)));
    for (final _Node node in blended) {
      _drawNode(node, 1);
    }
    for (final _Node node in visible) {
      if (node.material.renderOnTop) {
        _drawNode(node, 0);
        _drawNode(node, 1);
      }
    }
    final Float32List? reticle = _centerMatrix;
    if (_mode == "xr" && config["reticle"] == true && reticle != null) {
      final double distance = _M.distance(_M.translation(reticle), camera);
      final double size = (0.05 + distance * 0.035).clamp(0.04, 0.3).toDouble();
      final Float32List scaled = _M.multiply(reticle, _M.compose(<double>[0, 0.002, 0], <double>[0, 0, 0, 1], <double>[size, size, size]));
      _renderer.drawQuad(_M.multiply(_env.viewProjection, scaled), _M.argb(config["reticleColor"], 0xFFFFFFFF), 1);
    }
    _gl.disable(_G.blend);
  }

  void _drawShadows() {
    if (config["shadows"] == false) return;
    final double opacity = (config["shadowOpacity"] as num?)?.toDouble() ?? 0.45;
    for (final _Node node in _nodes.values) {
      if (!node.visible || !node.loaded || !node.castShadow || node.material.occluder) continue;
      if (node.type == "image" || node.type == "video" || node.type == "plane" || node.type == "group") continue;
      final Float32List? world = _worldOf(node);
      final (List<double>, List<double>)? bounds = node.bounds();
      if (world == null || bounds == null) continue;
      final (List<double>, List<double>) box = _M.aabb(world, bounds.$1, bounds.$2);
      final double sx = (box.$2[0] - box.$1[0]) * 0.62;
      final double sz = (box.$2[2] - box.$1[2]) * 0.62;
      if (sx <= 0 || sz <= 0) continue;
      final Float32List matrix = _M.compose(<double>[(box.$1[0] + box.$2[0]) / 2, box.$1[1] + 0.002, (box.$1[2] + box.$2[2]) / 2], <double>[0, 0, 0, 1], <double>[sx, 1, sz]);
      _renderer.drawQuad(_M.multiply(_env.viewProjection, matrix), <double>[0, 0, 0, opacity], 0);
    }
  }

  void _drawNode(_Node node, int pass) {
    if (node.type == "model") {
      node.model?.draw(_renderer, node.world, _env, pass, node.material.opacity);
      return;
    }
    final _GpuMesh? mesh = node.mesh;
    if (mesh == null || node.type == "group") return;
    final bool blended = node.material.isBlended;
    if (pass == 0 && blended || pass == 1 && !blended) return;
    _renderer.drawMesh(mesh, node.material, node.world, _env, null, 1);
  }

  void _emitFrame() {
    final Map<String, Object?> payload = <String, Object?>{
      "type": "frame",
      "t": web.window.performance.now(),
      "camera": _M.pose(_camera),
      "fov": _fov,
    };
    if (_mode == "xr") {
      payload["light"] = _light == null ? null : <String, Object?>{..._light!, "sh": null};
      payload["center"] = _centerHit;
    }
    final double? heading = _heading();
    if (heading != null) {
      payload["heading"] = heading;
      payload["northYaw"] = _mode == "sensor" ? 0.0 : _northYaw;
      payload["headingAccuracy"] = 15.0;
    }
    if (_tracks.isNotEmpty) payload["projections"] = _projections();
    _emit(payload);
    if (_mode == "xr" && web.window.performance.now() - _lastPlaneEmit > 200 && _planes.isNotEmpty) {
      _lastPlaneEmit = web.window.performance.now();
      _emit(<String, Object?>{"type": "planes", "updated": _planes.values.toList(), "removed": <String>[]});
      _planes.clear();
    }
  }

  List<List<Object?>> _projections() {
    final List<List<Object?>> out = <List<Object?>>[];
    final List<double> camera = _M.translation(_camera);
    final double vw = _viewport[2] <= 0 ? 1 : _viewport[2];
    final double vh = _viewport[3] <= 0 ? 1 : _viewport[3];
    for (final Map<Object?, Object?> track in _tracks) {
      final String id = "${track["id"]}";
      final List<double> offset = _M.doubles(track["offset"], 3, 0);
      final String? nodeId = track["nodeId"] as String?;
      final String? anchorId = track["anchorId"] as String?;
      List<double>? point;
      if (nodeId != null) {
        final _Node? node = _nodes[nodeId];
        final Float32List? world = node == null ? null : _worldOf(node);
        if (world != null) point = _M.point(world, offset[0], offset[1], offset[2]);
      } else if (anchorId != null) {
        final Float32List? anchor = _anchorMatrix(anchorId);
        if (anchor != null) point = _M.point(anchor, offset[0], offset[1], offset[2]);
      } else {
        point = offset;
      }
      if (point == null) {
        out.add(<Object?>[id, 0.5, 0.5, 0.0, -1]);
        continue;
      }
      final List<double> clip = _M.clip(_env.viewProjection, point);
      final double distance = _M.distance(point, camera);
      if (clip[3] <= 0.0001) {
        final double edge = clip[3] == 0 ? 0.5 : 0.5 - clip[0] / clip[3] / 2;
        out.add(<Object?>[id, edge, 0.5, distance, -1]);
        continue;
      }
      final double px = (clip[0] / clip[3] + 1) / 2 * _viewport[2] + _viewport[0];
      final double py = (1 - clip[1] / clip[3]) / 2 * _viewport[3] + _viewport[1];
      final double x = px / (_viewport[0] * 2 + vw);
      final double y = py / (_viewport[1] * 2 + vh);
      final int visibility = x >= 0 && x <= 1 && y >= 0 && y <= 1 ? 1 : 0;
      out.add(<Object?>[id, x, y, distance, visibility]);
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Heading and camera + compass mode
  // ---------------------------------------------------------------------------

  double _northYaw = 0;

  double? _heading() {
    if (_mode == "sensor") {
      final List<double> f = <double>[-_camera[8], -_camera[9], -_camera[10]];
      return (math.atan2(f[0], -f[2]) * 180 / math.pi + 360) % 360;
    }
    if (_mode == "xr" && _alpha != null) {
      final double? compass = _compassHeading();
      if (compass == null) return null;
      final List<double> f = <double>[-_camera[8], -_camera[9], -_camera[10]];
      if (f[1].abs() < 0.85) {
        final double theta = compass * math.pi / 180 - math.atan2(f[0], -f[2]);
        _northYaw = math.atan2(
          _northYaw == 0 ? math.sin(theta) : math.sin(_northYaw) * 0.96 + math.sin(theta) * 0.04,
          _northYaw == 0 ? math.cos(theta) : math.cos(_northYaw) * 0.96 + math.cos(theta) * 0.04,
        );
      }
      return compass;
    }
    return null;
  }

  /// Heading of the back camera, degrees clockwise from north.
  double? _compassHeading() {
    final List<double>? f = _deviceForward();
    if (f == null) return null;
    return (math.atan2(f[0], f[1]) * 180 / math.pi + 360) % 360;
  }

  /// Back-camera direction in east / north / up.
  List<double>? _deviceForward() {
    final List<double>? r = _deviceRotation();
    if (r == null) return null;
    return <double>[-r[2], -r[5], -r[8]];
  }

  /// Device → east/north/up rotation, row-major 3x3.
  List<double>? _deviceRotation() {
    final double? alphaRaw = _compass != null ? 360 - _compass! : _alpha;
    if (alphaRaw == null || _beta == null || _gamma == null) return null;
    final double a = alphaRaw * math.pi / 180;
    final double b = _beta! * math.pi / 180;
    final double g = _gamma! * math.pi / 180;
    final double cA = math.cos(a);
    final double sA = math.sin(a);
    final double cB = math.cos(b);
    final double sB = math.sin(b);
    final double cG = math.cos(g);
    final double sG = math.sin(g);
    return <double>[
      cA * cG - sA * sB * sG,
      -cB * sA,
      cG * sA * sB + cA * sG,
      cG * sA + cA * sB * sG,
      cA * cB,
      sA * sG - cA * cG * sB,
      -cB * sG,
      sB,
      cB * cG,
    ];
  }

  void _listenOrientation() {
    if (_orientationListener != null) return;
    void onOrientation(web.Event event) {
      final JSObject e = event as JSObject;
      final JSAny? alpha = e["alpha"];
      if (alpha != null) _alpha = (alpha as JSNumber).toDartDouble;
      final JSAny? beta = e["beta"];
      if (beta != null) _beta = (beta as JSNumber).toDartDouble;
      final JSAny? gamma = e["gamma"];
      if (gamma != null) _gamma = (gamma as JSNumber).toDartDouble;
      final JSAny? compass = e["webkitCompassHeading"];
      if (compass != null) _compass = (compass as JSNumber).toDartDouble;
    }

    _orientationListener = onOrientation.toJS;
    final bool absolute = globalContext.has("ondeviceorientationabsolute") || web.window.has("ondeviceorientationabsolute");
    web.window.addEventListener(absolute ? "deviceorientationabsolute" : "deviceorientation", _orientationListener);
  }

  void _updateSensorCamera() {
    final List<double>? r = _deviceRotation();
    final double angle = (web.window.screen.orientation.angle) * math.pi / 180;
    Float32List rotation = _M.identity();
    if (r != null) {
      final List<double> world = <double>[
        r[0],
        r[1],
        r[2],
        r[6],
        r[7],
        r[8],
        -r[3],
        -r[4],
        -r[5],
      ];
      rotation = Float32List.fromList(<double>[
        world[0],
        world[3],
        world[6],
        0,
        world[1],
        world[4],
        world[7],
        0,
        world[2],
        world[5],
        world[8],
        0,
        0,
        0,
        0,
        1,
      ]);
    }
    final Float32List screen = _M.compose(<double>[0, 0, 0], _M.qAxis(0, 0, 1, -angle), <double>[1, 1, 1]);
    _camera = _M.multiply(rotation, screen);
    _env.view = _M.invert(_camera);
    _fov = 60;
    _env.projection = _M.perspective(_fov * math.pi / 180, _width / _height, 0.05, 5000);
    _env.cameraPosition = <double>[0, 0, 0];
    _env.viewProjection = _M.multiply(_env.projection, _env.view);
  }

  Future<bool> _startSensor() async {
    final JSAny? orientationEvent = globalContext["DeviceOrientationEvent"];
    if (orientationEvent != null && (orientationEvent as JSObject).has("requestPermission")) {
      try {
        final JSString state = await orientationEvent.callMethod<JSPromise<JSString>>("requestPermission".toJS).toDart;
        if (state.toDart != "granted") return false;
      } catch (_) {
        return false;
      }
    }
    try {
      final JSObject constraints = JSObject()
        ..["video"] = (JSObject()..["facingMode"] = (JSObject()..["ideal"] = "environment".toJS))
        ..["audio"] = false.toJS;
      _stream = await web.window.navigator.mediaDevices.getUserMedia(constraints as web.MediaStreamConstraints).toDart;
      _video.srcObject = _stream;
      _video.style.display = "block";
      await _video.play().toDart;
    } catch (_) {
      return false;
    }
    _listenOrientation();
    _mode = "sensor";
    _emit(<String, Object?>{"type": "state", "session": "running", "tracking": "normal", "reason": "none", "xr": true});
    return true;
  }

  void _stopSensor() {
    final JSFunction<Function>? listener = _orientationListener;
    if (listener != null) {
      web.window.removeEventListener("deviceorientationabsolute", listener);
      web.window.removeEventListener("deviceorientation", listener);
      _orientationListener = null;
    }
    final web.MediaStream? stream = _stream;
    if (stream != null) {
      for (final web.MediaStreamTrack track in stream.getTracks().toDart) {
        track.stop();
      }
    }
    _stream = null;
    _video.style.display = "none";
  }

  // ---------------------------------------------------------------------------
  // WebXR
  // ---------------------------------------------------------------------------

  static Future<bool> xrSupported() async {
    final JSAny? xr = web.window.navigator["xr"];
    if (xr == null) return false;
    try {
      final JSBoolean supported = await (xr as JSObject).callMethod<JSPromise<JSBoolean>>("isSessionSupported".toJS, "immersive-ar".toJS).toDart;
      return supported.toDart;
    } catch (_) {
      return false;
    }
  }

  Future<bool> enterXr() async {
    if (_isViewer || _mode != "viewer") return _mode != "viewer";
    if (config["mode"] != "geo" || config["geoMode"] == "vps" || await xrSupported()) {
      if (await _startXr()) return true;
    }
    return _startSensor();
  }

  Future<bool> _startXr() async {
    final JSAny? xrSystem = web.window.navigator["xr"];
    if (xrSystem == null || !await xrSupported()) return false;
    final web.Element overlay = web.document.querySelector("flutter-view") ?? web.document.body!;
    final List<Object?> images = (config["images"] as List<Object?>?) ?? const <Object?>[];
    final JSArray<JSAny> tracked = <JSAny>[].toJS;
    for (final Object? raw in images) {
      final Map<Object?, Object?> image = (raw as Map<Object?, Object?>?) ?? const <Object?, Object?>{};
      try {
        final Uint8List bytes = await _loadBytes(image["source"] as Map<Object?, Object?>?);
        final web.ImageBitmap bitmap = await _decodeImage(bytes, "image/png");
        tracked.add(
          JSObject()
            ..["image"] = bitmap
            ..["widthInMeters"] = ((image["width"] as num?)?.toDouble() ?? 0.2).toJS,
        );
      } catch (_) {}
    }
    final JSObject init = JSObject()
      ..["requiredFeatures"] = <JSAny>["local".toJS].toJS
      ..["optionalFeatures"] = <JSAny>[
        "hit-test".toJS,
        "anchors".toJS,
        "dom-overlay".toJS,
        "light-estimation".toJS,
        "plane-detection".toJS,
        if (tracked.length > 0) "image-tracking".toJS,
      ].toJS
      ..["domOverlay"] = (JSObject()..["root"] = overlay);
    if (tracked.length > 0) init["trackedImages"] = tracked;
    try {
      final _XrSession session = await (xrSystem as JSObject).callMethod<JSPromise<_XrSession>>("requestSession".toJS, "immersive-ar".toJS, init).toDart;
      _xr = session;
      await _gl.makeXRCompatible().toDart;
      final JSObject layer = (globalContext["XRWebGLLayer"]! as JSFunction<Function>).callAsConstructor<JSObject>(session, _gl);
      session.updateRenderState(JSObject()..["baseLayer"] = layer);
      _refSpace = await session.requestReferenceSpace("local").toDart;
      _viewerSpace = await session.requestReferenceSpace("viewer").toDart;
      try {
        _centerSource = await session.requestHitTestSource(JSObject()..["space"] = _viewerSpace).toDart;
      } catch (_) {}
      if (config["lightEstimation"] != "disabled") {
        try {
          _lightProbe = await session.requestLightProbe().toDart;
        } catch (_) {}
      }
      session.addEventListener("end", ((web.Event _) => _onXrEnded()).toJS);
      _mode = "xr";
      final web.HTMLElement? body = web.document.body;
      _savedBackground = body?.style.background;
      body?.style.background = "transparent";
      (overlay as web.HTMLElement).style.background = "transparent";
      _listenOrientation();
      void xrTick(JSNumber time, JSObject frame) {
        if (_disposed || _xr == null) return;
        _xr!.requestAnimationFrame(xrTick.toJS);
        _onXrFrame(time.toDartDouble, frame as _XrFrame);
      }

      session.requestAnimationFrame(xrTick.toJS);
      _emit(<String, Object?>{"type": "state", "session": "running", "tracking": "limited", "reason": "initializing", "xr": true});
      return true;
    } catch (error) {
      _emit(<String, Object?>{"type": "error", "code": "sessionFailed", "message": "$error"});
      _xr = null;
      return false;
    }
  }

  void _onXrEnded() {
    _xr = null;
    _mode = "viewer";
    _refSpace = null;
    _viewerSpace = null;
    _centerSource = null;
    _lightProbe = null;
    web.document.body?.style.background = _savedBackground ?? "";
    _emit(<String, Object?>{"type": "state", "session": "running", "tracking": "notAvailable", "reason": "none", "xr": false});
    _startLoop();
  }

  Future<void> exitXr() async {
    final _XrSession? session = _xr;
    if (session != null) {
      try {
        await session.end().toDart;
      } catch (_) {}
    }
    if (_mode == "sensor") {
      _stopSensor();
      _mode = "viewer";
      _emit(<String, Object?>{"type": "state", "session": "running", "tracking": "notAvailable", "reason": "none", "xr": false});
    }
  }

  void _onXrFrame(double time, _XrFrame frame) {
    final double delta = _lastTime == 0 ? 0 : ((time - _lastTime) / 1000).clamp(0, 0.1).toDouble();
    _lastTime = time;
    _frame++;
    final JSObject? space = _refSpace;
    final _XrSession? session = _xr;
    if (space == null || session == null) return;
    final _XrLayer layer = session.renderState["baseLayer"]! as _XrLayer;
    _gl.bindFramebuffer(_G.framebuffer, layer.framebuffer);
    _gl.clearColor(0, 0, 0, 0);
    _gl.clear(_G.colorBufferBit | _G.depthBufferBit);
    final _XrViewerPose? pose = frame.getViewerPose(space);
    if (pose == null) {
      _setTracking("limited", "initializing");
      return;
    }
    _setTracking("normal", "none");
    final List<_XrView> views = pose.views.toDart;
    if (views.isEmpty) return;
    final _XrView view = views.first;
    final JSObject? viewport = layer.getViewport(view);
    if (viewport != null) {
      _viewport = <double>[
        (viewport["x"]! as JSNumber).toDartDouble,
        (viewport["y"]! as JSNumber).toDartDouble,
        (viewport["width"]! as JSNumber).toDartDouble,
        (viewport["height"]! as JSNumber).toDartDouble,
      ];
    }
    _env.projection = view.projectionMatrix.toDart;
    _env.view = view.transform.inverse.matrix.toDart;
    _camera = view.transform.matrix.toDart;
    _env.cameraPosition = _M.translation(_camera);
    _env.viewProjection = _M.multiply(_env.projection, _env.view);
    _fov = 2 * math.atan(1 / _env.projection[5]) * 180 / math.pi;

    _updateXrPlanes(frame, space);
    _updateXrAnchors(frame, space);
    _updateXrImages(frame, space);
    _updateXrHits(frame, space);
    _updateXrLight(frame);
    _applyEnvironment();
    _advance(delta);
    _drawScene(clear: false);
    _finishFrame();
  }

  void _setTracking(String tracking, String reason) {
    if (tracking == _tracking) return;
    _tracking = tracking;
    _emit(<String, Object?>{"type": "state", "tracking": tracking, "reason": reason, "session": "running", "xr": true});
  }

  void _updateXrPlanes(_XrFrame frame, JSObject space) {
    final JSAny? detected = frame["detectedPlanes"];
    if (detected == null) return;
    final Set<String> alive = <String>{};
    double? floor;
    final List<(String, Float32List, Float32List, bool, String?)> collected = <(String, Float32List, Float32List, bool, String?)>[];
    void visit(JSObject plane) {
      JSAny? id = plane["__uAr"];
      if (id == null) {
        id = "p${++_planeCounter}".toJS;
        plane["__uAr"] = id;
      }
      final String planeId = (id as JSString).toDart;
      final _XrPose? pose = frame.getPose(plane["planeSpace"]! as JSObject, space);
      if (pose == null) return;
      final Float32List matrix = pose.transform.matrix.toDart;
      final List<JSObject> points = (plane["polygon"]! as JSArray<JSObject>).toDart;
      final Float32List polygon = Float32List(points.length * 2);
      for (int i = 0; i < points.length; i++) {
        polygon[i * 2] = (points[i]["x"]! as JSNumber).toDartDouble;
        polygon[i * 2 + 1] = (points[i]["z"]! as JSNumber).toDartDouble;
      }
      final bool vertical = (plane["orientation"] as JSString?)?.toDart == "vertical";
      final String? label = (plane["semanticLabel"] as JSString?)?.toDart;
      if (!vertical) floor = floor == null ? matrix[13] : math.min(floor!, matrix[13]);
      alive.add(planeId);
      collected.add((planeId, matrix, polygon, vertical, label));
    }

    (detected as JSObject).callMethod<JSAny?>("forEach".toJS, visit.toJS);
    _planeDraw.removeWhere((String key, (Float32List, Float32List, bool) _) => !alive.contains(key));
    for (final (String, Float32List, Float32List, bool, String?) plane in collected) {
      _planeDraw[plane.$1] = (plane.$2, plane.$3, plane.$4);
      final double height = floor == null ? 0 : plane.$2[13] - floor!;
      final String classification =
          plane.$5 ??
          (plane.$4
              ? "wall"
              : height < 0.2
              ? "floor"
              : height < 0.6
              ? "seat"
              : height < 1.3
              ? "table"
              : "none");
      _planes[plane.$1] = <String, Object?>{
        "id": plane.$1,
        "type": plane.$4 ? "vertical" : "horizontalUp",
        "classification": classification,
        "pose": _M.pose(plane.$2),
        "extent": <double>[0, 0],
        "polygon": plane.$3.toList(),
        "tracking": "normal",
      };
    }
  }

  void _updateXrAnchors(_XrFrame frame, JSObject space) {
    for (final (String, Float32List) pending in _pendingXrAnchors) {
      final JSObject transform = _rigid(pending.$2);
      try {
        unawaited(frame.createAnchor(transform, space).toDart.then((JSObject anchor) => _xrAnchors[pending.$1] = anchor));
      } catch (_) {}
    }
    _pendingXrAnchors.clear();
    for (final MapEntry<String, JSObject> entry in _xrAnchors.entries) {
      final _XrPose? pose = frame.getPose(entry.value["anchorSpace"]! as JSObject, space);
      if (pose != null) _anchors[entry.key] = pose.transform.matrix.toDart;
    }
  }

  void _updateXrImages(_XrFrame frame, JSObject space) {
    if (!frame.has("getImageTrackingResults")) return;
    final List<Object?> images = (config["images"] as List<Object?>?) ?? const <Object?>[];
    final List<JSObject> results = frame.callMethod<JSArray<JSObject>>("getImageTrackingResults".toJS).toDart;
    final List<Map<String, Object?>> updated = <Map<String, Object?>>[];
    for (final JSObject result in results) {
      final int index = (result["index"]! as JSNumber).toDartInt;
      if (index >= images.length) continue;
      final String name = "${((images[index] as Map<Object?, Object?>?) ?? const <Object?, Object?>{})["name"]}";
      final _XrPose? pose = frame.getPose(result["imageSpace"]! as JSObject, space);
      final String state = (result["trackingState"] as JSString?)?.toDart ?? "untracked";
      if (pose != null) _anchors["image:$name"] = pose.transform.matrix.toDart;
      final double width = (result["measuredWidthInMeters"] as JSNumber?)?.toDartDouble ?? 0;
      updated.add(<String, Object?>{
        "name": name,
        "index": index,
        "pose": pose == null ? null : _M.pose(pose.transform.matrix.toDart),
        "width": width,
        "height": width,
        "tracking": state == "tracked" ? "normal" : (state == "emulated" ? "limited" : "notAvailable"),
      });
    }
    if (updated.isNotEmpty) _emit(<String, Object?>{"type": "images", "updated": updated});
  }

  JSObject _rigid(Float32List matrix) {
    final List<double> t = _M.translation(matrix);
    final List<double> q = _M.rotationOf(matrix);
    final JSObject position = JSObject()
      ..["x"] = t[0].toJS
      ..["y"] = t[1].toJS
      ..["z"] = t[2].toJS
      ..["w"] = 1.toJS;
    final JSObject orientation = JSObject()
      ..["x"] = q[0].toJS
      ..["y"] = q[1].toJS
      ..["z"] = q[2].toJS
      ..["w"] = q[3].toJS;
    return (globalContext["XRRigidTransform"]! as JSFunction<Function>).callAsConstructor<JSObject>(position, orientation);
  }

  Map<String, Object?> _hitMap(Float32List matrix, String type) {
    final List<double> position = _M.translation(matrix);
    final List<double> up = <double>[matrix[4], matrix[5], matrix[6]];
    final bool vertical = up[1].abs() < 0.5;
    return <String, Object?>{
      "pose": _M.pose(matrix),
      "distance": _M.distance(position, _M.translation(_camera)),
      "type": type,
      "planeType": vertical ? "vertical" : (up[1] < 0 ? "horizontalDown" : "horizontalUp"),
      "classification": vertical ? "wall" : "none",
    };
  }

  void _updateXrHits(_XrFrame frame, JSObject space) {
    final JSObject? center = _centerSource;
    if (center != null) {
      final List<_XrHitResult> results = frame.getHitTestResults(center).toDart;
      final _XrPose? pose = results.isEmpty ? null : results.first.getPose(space);
      if (pose == null) {
        _centerHit = null;
        _centerMatrix = null;
      } else {
        _centerMatrix = pose.transform.matrix.toDart;
        _centerHit = _hitMap(_centerMatrix!, "plane");
      }
    }
    for (final _PendingHit hit in List<_PendingHit>.of(_pendingHits)) {
      final JSObject? source = hit.source;
      if (source == null) {
        if (!hit.requested) {
          hit.requested = true;
          _requestHitSource(hit);
        }
        continue;
      }
      final List<_XrHitResult> results = frame.getHitTestResults(source).toDart;
      final List<Map<String, Object?>> hits = <Map<String, Object?>>[];
      for (final _XrHitResult result in results) {
        final _XrPose? pose = result.getPose(space);
        if (pose != null) hits.add(_hitMap(pose.transform.matrix.toDart, "plane"));
      }
      try {
        source.callMethod<JSAny?>("cancel".toJS);
      } catch (_) {}
      _pendingHits.remove(hit);
      if (!hit.completer.isCompleted) hit.completer.complete(hits);
    }
  }

  void _requestHitSource(_PendingHit hit) {
    final _XrSession? session = _xr;
    final JSObject? viewer = _viewerSpace;
    if (session == null || viewer == null) {
      _pendingHits.remove(hit);
      hit.completer.complete(<Map<String, Object?>>[]);
      return;
    }
    final Float32List inverse = _M.invert(_env.projection);
    final List<double> p = _M.clip(inverse, <double>[hit.x * 2 - 1, 1 - hit.y * 2, -1]);
    final List<double> dir = <double>[p[0] / p[3], p[1] / p[3], p[2] / p[3]];
    final double l = math.sqrt(dir[0] * dir[0] + dir[1] * dir[1] + dir[2] * dir[2]);
    final JSObject origin = JSObject()
      ..["x"] = 0.toJS
      ..["y"] = 0.toJS
      ..["z"] = 0.toJS
      ..["w"] = 1.toJS;
    final JSObject direction = JSObject()
      ..["x"] = (dir[0] / l).toJS
      ..["y"] = (dir[1] / l).toJS
      ..["z"] = (dir[2] / l).toJS
      ..["w"] = 0.toJS;
    final JSObject ray = (globalContext["XRRay"]! as JSFunction<Function>).callAsConstructor<JSObject>(origin, direction);
    final JSObject options = JSObject()
      ..["space"] = viewer
      ..["offsetRay"] = ray;
    session.requestHitTestSource(options).toDart.then((JSObject source) => hit.source = source).catchError((Object _) {
      _pendingHits.remove(hit);
      if (!hit.completer.isCompleted) hit.completer.complete(<Map<String, Object?>>[]);
      return JSObject();
    });
  }

  void _updateXrLight(_XrFrame frame) {
    final JSObject? probe = _lightProbe;
    if (probe == null) {
      _light = null;
      return;
    }
    final JSObject? estimate = frame.getLightEstimate(probe);
    if (estimate == null) return;
    final JSObject direction = estimate["primaryLightDirection"]! as JSObject;
    final JSObject intensity = estimate["primaryLightIntensity"]! as JSObject;
    double v(JSObject o, String k) => (o[k]! as JSNumber).toDartDouble;
    final List<double> sh = (estimate["sphericalHarmonicsCoefficients"]! as JSFloat32Array).toDart.toList();
    final List<double> main = <double>[v(intensity, "x"), v(intensity, "y"), v(intensity, "z")];
    _light = <String, Object?>{
      "intensity": (main[0] + main[1] + main[2]) / 3,
      "direction": <double>[v(direction, "x"), v(direction, "y"), v(direction, "z")],
      "mainIntensity": main,
      "sh": sh.length >= 27 ? sh : null,
    };
  }

  // ---------------------------------------------------------------------------
  // Commands
  // ---------------------------------------------------------------------------

  Future<List<Map<String, Object?>>> hitTest(double x, double y, List<String> types) async {
    if (_mode == "xr") {
      final Completer<List<Map<String, Object?>>> completer = Completer<List<Map<String, Object?>>>();
      _pendingHits.add(_PendingHit(x, y, types, completer));
      return completer.future.timeout(const Duration(seconds: 2), onTimeout: () => <Map<String, Object?>>[]);
    }
    if (_mode == "sensor") {
      final Float32List inverse = _M.invert(_env.viewProjection);
      final List<double> near = _M.clip(inverse, <double>[x * 2 - 1, 1 - y * 2, -1]);
      final List<double> far = _M.clip(inverse, <double>[x * 2 - 1, 1 - y * 2, 1]);
      final List<double> o = <double>[near[0] / near[3], near[1] / near[3], near[2] / near[3]];
      final List<double> e = <double>[far[0] / far[3], far[1] / far[3], far[2] / far[3]];
      final List<double> d = <double>[e[0] - o[0], e[1] - o[1], e[2] - o[2]];
      const double ground = -1.4;
      if (d[1] >= -1e-6) return <Map<String, Object?>>[];
      final double t = (ground - o[1]) / d[1];
      final Float32List matrix = _M.compose(<double>[o[0] + d[0] * t, ground, o[2] + d[2] * t], <double>[0, 0, 0, 1], <double>[1, 1, 1]);
      return <Map<String, Object?>>[_hitMap(matrix, "estimated")];
    }
    return <Map<String, Object?>>[];
  }

  Map<String, Object?>? hitTestNodes(double x, double y) {
    final Float32List inverse = _M.invert(_env.viewProjection);
    final List<double> near = _M.clip(inverse, <double>[x * 2 - 1, 1 - y * 2, -1]);
    final List<double> far = _M.clip(inverse, <double>[x * 2 - 1, 1 - y * 2, 1]);
    final List<double> origin = <double>[near[0] / near[3], near[1] / near[3], near[2] / near[3]];
    final List<double> end = <double>[far[0] / far[3], far[1] / far[3], far[2] / far[3]];
    final List<double> dir = <double>[end[0] - origin[0], end[1] - origin[1], end[2] - origin[2]];
    final double length = math.sqrt(dir[0] * dir[0] + dir[1] * dir[1] + dir[2] * dir[2]);
    for (int i = 0; i < 3; i++) {
      dir[i] /= length;
    }
    (_Node, double)? best;
    for (final _Node node in _nodes.values) {
      if (!node.visible || !node.loaded || !node.hittable) continue;
      final Float32List? world = _worldOf(node);
      final (List<double>, List<double>)? bounds = node.bounds();
      if (world == null || bounds == null) continue;
      final (List<double>, List<double>) box = _M.aabb(world, bounds.$1, bounds.$2);
      final double? t = _M.rayAabb(origin, dir, box.$1, box.$2);
      if (t != null && (best == null || t < best.$2)) best = (node, t);
    }
    if (best == null) return null;
    return <String, Object?>{
      "id": best.$1.id,
      "position": <double>[for (int i = 0; i < 3; i++) origin[i] + dir[i] * best.$2],
      "distance": best.$2,
    };
  }

  Map<String, Object?> addAnchor(String id, Object? pose, String type) {
    final Float32List matrix = _M.poseMatrix(pose);
    _anchors[id] = matrix;
    if (_mode == "xr") _pendingXrAnchors.add((id, matrix));
    return <String, Object?>{"id": id, "pose": _M.pose(matrix), "type": type, "tracking": "normal"};
  }

  void updateAnchor(String id, Object? pose) {
    final Float32List matrix = _M.poseMatrix(pose);
    _anchors[id] = matrix;
    final JSObject? old = _xrAnchors.remove(id);
    if (old != null) {
      try {
        old.callMethod<JSAny?>("delete".toJS);
      } catch (_) {}
    }
    if (_mode == "xr") _pendingXrAnchors.add((id, matrix));
  }

  void removeAnchor(String id, bool removeNodes) {
    _anchors.remove(id);
    final JSObject? old = _xrAnchors.remove(id);
    if (old != null) {
      try {
        old.callMethod<JSAny?>("delete".toJS);
      } catch (_) {}
    }
    if (removeNodes) {
      for (final String nodeId in _nodes.values.where((_Node n) => n.anchorId == id).map((_Node n) => n.id).toList()) {
        removeNode(nodeId);
      }
    }
    _emit(<String, Object?>{
      "type": "anchors",
      "updated": <Object?>[],
      "removed": <String>[id],
    });
  }

  void reset(bool keepNodes) {
    _anchors.clear();
    _xrAnchors.clear();
    _planeDraw.clear();
    if (!keepNodes) {
      for (final String id in _nodes.keys.toList()) {
        removeNode(id);
      }
    }
  }

  String _sourceKey(Map<Object?, Object?> map) {
    final Map<Object?, Object?>? source = map["source"] as Map<Object?, Object?>?;
    final Object? value = source?["value"];
    final String part = value is Uint8List ? "bytes:${value.length}:${value.isEmpty ? 0 : value[value.length ~/ 2]}" : "${source?["kind"]}:$value";
    return "${map["type"]}|$part|${map["width"]}|${map["height"]}|${map["depth"]}|${map["radius"]}";
  }

  Map<String, Object?> _info(_Node node) {
    final (List<double>, List<double>) bounds = node.bounds() ?? (<double>[0, 0, 0], <double>[0, 0, 0]);
    node.worldFrame = -1;
    final Float32List world = _worldOf(node) ?? _M.multiply(_M.compose(node.position, node.rotation, node.scale), node.normalization);
    final (List<double>, List<double>) box = _M.aabb(world, bounds.$1, bounds.$2);
    return <String, Object?>{
      "id": node.id,
      "loaded": node.loaded,
      "min": box.$1,
      "max": box.$2,
      "animations": node.model?.animationNames ?? <String>[],
    };
  }

  void _loaded(_Node node) => _emit(<String, Object?>{"type": "node", "event": "loaded", ..._info(node)});

  void _failed(_Node node, Object error) => _emit(<String, Object?>{"type": "node", "id": node.id, "event": "error", "message": "$error"});

  Future<Uint8List> _loadBytes(Map<Object?, Object?>? source) async {
    if (source == null) throw StateError("Missing source");
    final Object? value = source["value"];
    if (value is Uint8List) return value;
    return _fetchBytes(_sourceUrl(source));
  }

  static String _sourceUrl(Map<Object?, Object?> source) {
    final String value = "${source["value"]}";
    return source["kind"] == "asset" ? ui_web.assetManager.getAssetUrl(value) : value;
  }

  static String? _baseOf(Map<Object?, Object?>? source) {
    if (source == null || source["value"] is Uint8List) return null;
    final String url = _sourceUrl(source);
    final int slash = url.lastIndexOf("/");
    return slash < 0 ? "" : url.substring(0, slash);
  }

  Map<String, Object?> addNode(Map<Object?, Object?> map) {
    final String id = "${map["id"]}";
    final _Node? existing = _nodes[id];
    final String key = _sourceKey(map);
    final _Node node = existing ?? _Node(id);
    node.apply(map);
    _nodes[id] = node;
    if (existing != null && existing.sourceKey == key && existing.loaded) {
      node.updateNormalization();
      return _info(node);
    }
    _releaseContent(node);
    node.sourceKey = key;
    node.loaded = false;
    final int token = ++node.token;
    switch (node.type) {
      case "box":
        node.mesh = _GpuMesh(_gl, _MeshData.box(node.width, node.height, node.depth));
      case "sphere":
        node.mesh = _GpuMesh(_gl, _MeshData.sphere(node.radius));
      case "cylinder":
        node.mesh = _GpuMesh(_gl, _MeshData.cylinder(node.radius, node.height, false));
      case "cone":
        node.mesh = _GpuMesh(_gl, _MeshData.cylinder(node.radius, node.height, true));
      case "plane":
        node.mesh = _GpuMesh(_gl, _MeshData.quad(node.width, node.height));
      case "group":
        break;
      case "model":
        unawaited(_loadModel(node, map["source"] as Map<Object?, Object?>?, token));
        return <String, Object?>{"id": id, "loaded": false};
      case "image":
        unawaited(_loadImage(node, map["source"] as Map<Object?, Object?>?, token));
        return <String, Object?>{"id": id, "loaded": false};
      case "video":
        _loadVideo(node, map["source"] as Map<Object?, Object?>?, map["video"] as Map<Object?, Object?>?);
        return <String, Object?>{"id": id, "loaded": false};
    }
    node.loaded = true;
    return _info(node);
  }

  Future<void> _loadModel(_Node node, Map<Object?, Object?>? source, int token) async {
    try {
      final String modelKey = "${source?["kind"]}:${source?["value"] is Uint8List ? (source!["value"]! as Uint8List).length : source?["value"]}";
      _Model? model = _models[modelKey];
      if (model == null) {
        final Uint8List bytes = await _loadBytes(source);
        final _GltfData data = await _GltfData.parse(bytes, _baseOf(source));
        if (_disposed || node.token != token) return;
        model = _models[modelKey] ?? _Model(_gl, data);
        _models[modelKey] = model;
      }
      if (_disposed || node.token != token) return;
      model.references++;
      final _ModelInstance instance = _ModelInstance(_gl, model)..onFinished = () => _emit(<String, Object?>{"type": "node", "id": node.id, "event": "animationEnded"});
      node.model = instance;
      node.modelKey = modelKey;
      node.updateNormalization();
      final Map<Object?, Object?>? animation = node.map["animation"] as Map<Object?, Object?>?;
      if (animation != null && animation["autoplay"] != false) {
        instance.play(animation["name"] as String?, (animation["index"] as num?)?.toInt() ?? 0, animation["loop"] != false, (animation["speed"] as num?)?.toDouble() ?? 1);
      }
      node.loaded = true;
      _loaded(node);
    } catch (error) {
      _failed(node, error);
    }
  }

  Future<void> _loadImage(_Node node, Map<Object?, Object?>? source, int token) async {
    try {
      final Uint8List bytes = await _loadBytes(source);
      final String ext = "${source?["ext"] ?? "png"}";
      final web.ImageBitmap bitmap = await _decodeImage(bytes, ext == "jpg" || ext == "jpeg" ? "image/jpeg" : "image/$ext");
      if (_disposed || node.token != token) return;
      final JSObject? texture = _Renderer.uploadImage(_gl, bitmap, _G.clampToEdge, _G.clampToEdge, _G.linearMipmapLinear);
      node.imageTexture = texture;
      node.material.baseTexture = texture;
      node.material.alphaMode = 2;
      final double h = node.height > 0 ? node.height : node.width * bitmap.height / math.max(1, bitmap.width);
      node.mesh = _GpuMesh(_gl, _MeshData.quad(node.width, h));
      node.loaded = true;
      _loaded(node);
    } catch (error) {
      _failed(node, error);
    }
  }

  void _loadVideo(_Node node, Map<Object?, Object?>? source, Map<Object?, Object?>? options) {
    if (source == null) return;
    final web.HTMLVideoElement video = web.HTMLVideoElement()
      ..crossOrigin = "anonymous"
      ..loop = options?["loop"] != false
      ..muted = options?["muted"] != false
      ..setAttribute("playsinline", "true");
    final Object? value = source["value"];
    video.src = value is Uint8List ? web.URL.createObjectURL(web.Blob(<JSAny>[value.toJS].toJS)) : _sourceUrl(source);
    video.addEventListener("ended", ((web.Event _) => _emit(<String, Object?>{"type": "node", "id": node.id, "event": "videoEnded"})).toJS);
    node.video = video;
    final JSObject? texture = _gl.createTexture();
    _gl.bindTexture(_G.texture2d, texture);
    _gl.texImage2D(_G.texture2d, 0, _G.rgba8, 1, 1, 0, _G.rgba, _G.unsignedByte, Uint8List.fromList(<int>[0, 0, 0, 255]).toJS);
    _gl.texParameteri(_G.texture2d, _G.textureMinFilter, _G.linear);
    _gl.texParameteri(_G.texture2d, _G.textureWrapS, _G.clampToEdge);
    _gl.texParameteri(_G.texture2d, _G.textureWrapT, _G.clampToEdge);
    node.imageTexture = texture;
    node.material.baseTexture = texture;
    node.mesh = _GpuMesh(_gl, _MeshData.quad(node.width, node.height));
    node.loaded = true;
    if (options?["autoplay"] != false) unawaited(video.play().toDart.catchError((Object _) => null));
    _loaded(node);
  }

  void _releaseContent(_Node node) {
    node.mesh?.release();
    node.mesh = null;
    final _ModelInstance? instance = node.model;
    if (instance != null) {
      instance.release();
      final _Model model = instance.model;
      model.references--;
      final String? key = node.modelKey;
      if (model.references <= 0 && key != null) {
        _models.remove(key);
        model.release();
      }
    }
    node.model = null;
    node.video?.pause();
    node.video = null;
    _gl.deleteTexture(node.imageTexture);
    node.imageTexture = null;
    node.material.baseTexture = null;
    node.normalization = _M.identity();
  }

  void removeNode(String id) {
    final _Node? node = _nodes.remove(id);
    if (node == null) return;
    _releaseContent(node);
    for (final String child in _nodes.values.where((_Node n) => n.parentId == id).map((_Node n) => n.id).toList()) {
      removeNode(child);
    }
  }

  void clearNodes() {
    for (final String id in _nodes.keys.toList()) {
      removeNode(id);
    }
  }

  void transformNode(Map<Object?, Object?> args) {
    final _Node? node = _nodes["${args["id"]}"];
    if (node == null) return;
    final List<double>? position = args["position"] == null ? null : _M.doubles(args["position"], 3, 0);
    final List<double>? rotation = args["rotation"] == null ? null : _M.qNormalize(_M.doubles(args["rotation"], 4, 0));
    if (args["world"] == true) {
      Float32List parent = _M.identity();
      final String? parentId = node.parentId;
      final String? anchorId = node.anchorId;
      if (parentId != null && _nodes[parentId] != null) {
        parent = _worldOf(_nodes[parentId]!) ?? parent;
      } else if (anchorId != null) {
        parent = _anchorMatrix(anchorId) ?? parent;
      }
      final Float32List inverse = _M.invert(parent);
      if (position != null) node.position = _M.point(inverse, position[0], position[1], position[2]);
      if (rotation != null) node.rotation = _M.qMultiply(_M.rotationOf(inverse), rotation);
    } else {
      if (position != null) node.position = position;
      if (rotation != null) node.rotation = rotation;
    }
    if (args["scale"] != null) node.scale = _M.doubles(args["scale"], 3, 1);
    node.worldFrame = -1;
  }

  List<double>? nodePose(String id) {
    final _Node? node = _nodes[id];
    final Float32List? world = node == null ? null : _worldOf(node);
    return world == null ? null : _M.pose(world);
  }

  void playAnimation(Map<Object?, Object?> args) => _nodes["${args["id"]}"]?.model?.play(
    args["name"] as String?,
    (args["index"] as num?)?.toInt() ?? 0,
    args["loop"] != false,
    (args["speed"] as num?)?.toDouble() ?? 1,
  );

  void stopAnimation(String id) => _nodes[id]?.model?.playing = false;

  void controlVideo(Map<Object?, Object?> args) {
    final web.HTMLVideoElement? video = _nodes["${args["id"]}"]?.video;
    if (video == null) return;
    if (args["seek"] is num) video.currentTime = (args["seek"]! as num) / 1000;
    if (args["volume"] is num) video.volume = (args["volume"]! as num).toDouble();
    if (args["play"] == true) unawaited(video.play().toDart.catchError((Object _) => null));
    if (args["play"] == false) video.pause();
  }

  void setTracks(List<Object?> tracks) => _tracks = tracks.whereType<Map<Object?, Object?>>().toList();

  void setOrbit(Object? orbit) => config = <Object?, Object?>{...config, "orbit": orbit};

  Future<Uint8List?> snapshot(Map<Object?, Object?> args) {
    final Completer<Uint8List?> completer = Completer<Uint8List?>();
    _pendingSnapshot = (args, completer);
    return completer.future;
  }

  Future<void> _readSnapshot(Map<Object?, Object?> args, Completer<Uint8List?> completer) async {
    try {
      final int w = _viewport[2].toInt();
      final int h = _viewport[3].toInt();
      final Uint8List pixels = Uint8List(w * h * 4);
      _gl.readPixels(_viewport[0].toInt(), _viewport[1].toInt(), w, h, _G.rgba, _G.unsignedByte, pixels.toJS);
      final Uint8ClampedList flipped = Uint8ClampedList(w * h * 4);
      for (int y = 0; y < h; y++) {
        flipped.setRange(y * w * 4, (y + 1) * w * 4, pixels, (h - 1 - y) * w * 4);
      }
      final web.HTMLCanvasElement canvas = web.HTMLCanvasElement()
        ..width = w
        ..height = h;
      final web.CanvasRenderingContext2D context = canvas.getContext("2d")! as web.CanvasRenderingContext2D;
      if (_mode == "sensor" && _video.readyState >= 2) context.drawImage(_video, 0, 0, w, h);
      final web.HTMLCanvasElement layer = web.HTMLCanvasElement()
        ..width = w
        ..height = h;
      (layer.getContext("2d")! as web.CanvasRenderingContext2D).putImageData(web.ImageData(flipped.toJS, w, h.toJS), 0, 0);
      context.drawImage(layer, 0, 0);
      final bool png = args["format"] == "png";
      final Completer<web.Blob?> blob = Completer<web.Blob?>();
      void onBlob(web.Blob? value) => blob.complete(value);
      canvas.toBlob(onBlob.toJS, png ? "image/png" : "image/jpeg", (((args["quality"] as num?) ?? 92) / 100).toJS);
      final web.Blob? result = await blob.future;
      if (result == null) {
        completer.complete(null);
        return;
      }
      final JSArrayBuffer buffer = await result.arrayBuffer().toDart;
      completer.complete(buffer.toDart.asUint8List());
    } catch (error) {
      completer.completeError(error);
    }
  }

  void startRecording() {
    final web.MediaStream stream = _canvas.captureStream(30);
    _chunks.clear();
    final web.MediaRecorder recorder = web.MediaRecorder(stream);
    recorder.ondataavailable = ((web.BlobEvent event) {
      if (event.data.size > 0) _chunks.add(event.data);
    }).toJS;
    recorder.start(250);
    _recorder = recorder;
    _recordingStart = DateTime.now();
  }

  Future<Map<String, Object?>?> stopRecording() async {
    final web.MediaRecorder? recorder = _recorder;
    if (recorder == null) return null;
    final Completer<void> stopped = Completer<void>();
    recorder.onstop = ((web.Event _) => stopped.complete()).toJS;
    recorder.stop();
    await stopped.future;
    _recorder = null;
    final web.Blob blob = web.Blob(_chunks.toJS, web.BlobPropertyBag(type: "video/webm"));
    final JSArrayBuffer buffer = await blob.arrayBuffer().toDart;
    return <String, Object?>{"bytes": buffer.toDart.asUint8List(), "mime": "video/webm", "duration": DateTime.now().difference(_recordingStart).inMilliseconds};
  }

  Map<String, Object?>? cameraImage(int maxSize) {
    if (_mode != "sensor" || _video.readyState < 2) return null;
    final int vw = _video.videoWidth;
    final int vh = _video.videoHeight;
    if (vw == 0 || vh == 0) return null;
    int step = 1;
    while (vw / step > maxSize || vh / step > maxSize) {
      step++;
    }
    final int w = vw ~/ step;
    final int h = vh ~/ step;
    final web.HTMLCanvasElement canvas = web.HTMLCanvasElement()
      ..width = w
      ..height = h;
    final web.CanvasRenderingContext2D context = canvas.getContext("2d")! as web.CanvasRenderingContext2D;
    context.drawImage(_video, 0, 0, w, h);
    final Uint8ClampedList rgba = context.getImageData(0, 0, w, h).data.toDart;
    final Uint8List gray = Uint8List(w * h);
    for (int i = 0; i < w * h; i++) {
      gray[i] = (rgba[i * 4] * 77 + rgba[i * 4 + 1] * 150 + rgba[i * 4 + 2] * 29) >> 8;
    }
    final double cw = math.max(1, _container.clientWidth).toDouble();
    final double ch = math.max(1, _container.clientHeight).toDouble();
    final double scale = math.max(cw / vw, ch / vh);
    final double ox = (cw - vw * scale) / 2;
    final double oy = (ch - vh * scale) / 2;
    return <String, Object?>{
      "bytes": gray,
      "width": w,
      "height": h,
      "stride": w,
      "transform": <double>[step * scale / cw, 0, ox / cw, 0, step * scale / ch, oy / ch],
    };
  }
}

// =============================================================================
// Plugin entry
// =============================================================================

class UArWeb {
  UArWeb(this._messenger);

  final BinaryMessenger _messenger;
  final Map<int, _WebArSession> _sessions = <int, _WebArSession>{};
  int _nextId = 1;

  static void registerWith(Registrar registrar) {
    final UArWeb instance = UArWeb(registrar);
    MethodChannel("u/ar", const StandardMethodCodec(), registrar).setMethodCallHandler(instance._handle);
  }

  static bool get _isIos {
    final String ua = web.window.navigator.userAgent.toLowerCase();
    return ua.contains("iphone") || ua.contains("ipad") || (ua.contains("macintosh") && web.window.navigator.maxTouchPoints > 1);
  }

  static bool get _isAndroid => web.window.navigator.userAgent.toLowerCase().contains("android");

  static bool get _quickLook {
    final web.HTMLAnchorElement anchor = web.HTMLAnchorElement();
    try {
      return anchor.relList.supports("ar");
    } catch (_) {
      return false;
    }
  }

  static bool get _sensor => globalContext.has("DeviceOrientationEvent") && (_isIos || _isAndroid);

  Future<Map<String, Object?>> _capabilities() async {
    final bool xr = await _WebArSession.xrSupported();
    return <String, Object?>{
      "platform": "web",
      "worldTracking": xr,
      "planeHorizontal": xr,
      "planeVertical": xr,
      "imageTracking": xr,
      "lightEstimation": xr,
      "environmentHdr": xr,
      "instantPlacement": xr,
      "gpsGeo": xr || _sensor,
      "recording": true,
      "snapshot": true,
      "cameraImage": _sensor,
      "nativeViewer": _quickLook || _isAndroid,
      "viewer": true,
      "webXr": xr,
      "sensorAr": _sensor,
      "formats": <String>["glb", "gltf"],
    };
  }

  void _push(String channel, Map<String, Object?> payload) {
    final ByteData encoded = const StandardMethodCodec().encodeSuccessEnvelope(payload);
    ServicesBinding.instance.channelBuffers.push(channel, encoded, (ByteData? _) {});
  }

  Future<Object?> _handle(MethodCall call) async {
    final Map<Object?, Object?> args = (call.arguments as Map<Object?, Object?>?) ?? <Object?, Object?>{};
    switch (call.method) {
      case "availability":
      case "requestInstall":
        final Map<String, Object?> caps = await _capabilities();
        return <String, Object?>{"status": caps["webXr"] == true || caps["sensorAr"] == true ? "supported" : "unsupported", "capabilities": caps};
      case "permissionStatus":
      case "requestPermission":
        return <String, Object?>{"camera": "unknown", "location": "unknown", "microphone": "unknown"};
      case "openSettings":
        return false;
      case "openNativeViewer":
        return _openNativeViewer(args);
      case "scanRoom":
      case "captureObject":
        throw PlatformException(code: "unsupported", message: "${call.method} needs iOS with LiDAR");
      case "create":
        final int id = _nextId++;
        final String channel = "u/ar/events/$id";
        MethodChannel(channel, const StandardMethodCodec(), _messenger).setMethodCallHandler((MethodCall _) async => null);
        final _WebArSession session = _WebArSession(id, (args["config"] as Map<Object?, Object?>?) ?? <Object?, Object?>{}, (Map<String, Object?> payload) => _push(channel, payload));
        _sessions[id] = session;
        return <String, Object?>{"sessionId": id, "viewType": session.viewType};
    }
    final int? id = (args["sessionId"] as num?)?.toInt();
    final _WebArSession? session = id == null ? null : _sessions[id];
    if (call.method == "checkVps") return "unavailable";
    if (session == null) throw PlatformException(code: "notFound", message: "AR session not found");
    switch (call.method) {
      case "dispose":
        _sessions.remove(id)?.dispose();
        return null;
      case "start":
        session.start();
        return <String, Object?>{"capabilities": await _capabilities()};
      case "enterXr":
        return session.enterXr();
      case "exitXr":
        await session.exitXr();
        return null;
      case "resize":
      case "pause":
      case "resume":
      case "updateLocation":
        return null;
      case "reset":
        session.reset(args["keepNodes"] == true);
        return null;
      case "updateConfig":
        session.config = (args["config"] as Map<Object?, Object?>?) ?? session.config;
        return null;
      case "hitTest":
        return session.hitTest(
          ((args["x"] as num?) ?? 0.5).toDouble(),
          ((args["y"] as num?) ?? 0.5).toDouble(),
          ((args["types"] as List<Object?>?) ?? const <Object?>[]).whereType<String>().toList(),
        );
      case "hitTestNodes":
        return session.hitTestNodes(((args["x"] as num?) ?? 0.5).toDouble(), ((args["y"] as num?) ?? 0.5).toDouble());
      case "addAnchor":
        return session.addAnchor("${args["id"]}", args["pose"], args["name"] == "geo" ? "geo" : "world");
      case "updateAnchor":
        session.updateAnchor("${args["id"]}", args["pose"]);
        return null;
      case "removeAnchor":
        session.removeAnchor("${args["id"]}", args["removeNodes"] != false);
        return null;
      case "addNode":
      case "updateNode":
        return session.addNode((args["node"] as Map<Object?, Object?>?) ?? <Object?, Object?>{});
      case "transformNode":
        session.transformNode(args);
        return null;
      case "removeNode":
        session.removeNode("${args["id"]}");
        return null;
      case "clearNodes":
        session.clearNodes();
        return null;
      case "nodePose":
        return session.nodePose("${args["id"]}");
      case "playAnimation":
        session.playAnimation(args);
        return null;
      case "stopAnimation":
        session.stopAnimation("${args["id"]}");
        return null;
      case "controlVideo":
        session.controlVideo(args);
        return null;
      case "setTracks":
        session.setTracks((args["tracks"] as List<Object?>?) ?? const <Object?>[]);
        return null;
      case "setOrbit":
        session.setOrbit(args["orbit"]);
        return null;
      case "snapshot":
        return session.snapshot(args);
      case "startRecording":
        session.startRecording();
        return null;
      case "stopRecording":
        return session.stopRecording();
      case "cameraImage":
        return session.cameraImage((args["maxSize"] as num?)?.toInt() ?? 1024);
      default:
        throw PlatformException(code: "unsupported", message: "${call.method} is not available on the web");
    }
  }

  bool _openNativeViewer(Map<Object?, Object?> args) {
    final Map<Object?, Object?>? source = args["source"] as Map<Object?, Object?>?;
    final Map<Object?, Object?>? iosSource = args["iosSource"] as Map<Object?, Object?>?;
    String? url(Map<Object?, Object?>? s) {
      if (s == null || s["value"] is Uint8List) return null;
      return Uri.base.resolve(_WebArSession._sourceUrl(s)).toString();
    }

    if (_isIos && _quickLook) {
      final String? usdz = url(iosSource);
      if (usdz == null) return false;
      final String link = args["link"] is String ? "#canonicalWebPageURL=${Uri.encodeComponent("${args["link"]}")}" : "";
      final web.HTMLAnchorElement anchor = web.HTMLAnchorElement()
        ..rel = "ar"
        ..href = "$usdz$link"
        ..append(web.HTMLImageElement());
      web.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      return true;
    }
    if (_isAndroid) {
      final String? glb = url(source);
      if (glb == null) return false;
      final String mode = args["arFirst"] == false ? "3d_preferred" : "ar_preferred";
      final String title = args["title"] is String ? "&title=${Uri.encodeComponent("${args["title"]}")}" : "";
      final String link = args["link"] is String ? "&link=${Uri.encodeComponent("${args["link"]}")}" : "";
      final String fallback = Uri.encodeComponent("${args["fallbackUrl"] ?? glb}");
      web.window.location.href =
          "intent://arvr.google.com/scene-viewer/1.0?file=${Uri.encodeComponent(glb)}&mode=$mode$title$link"
          "#Intent;scheme=https;package=com.google.android.googlequicksearchbox;action=android.intent.action.VIEW;S.browser_fallback_url=$fallback;end;";
      return true;
    }
    return false;
  }
}
