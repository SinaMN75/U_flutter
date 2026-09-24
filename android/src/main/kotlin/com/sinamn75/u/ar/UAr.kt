package com.sinamn75.u.ar

import android.Manifest
import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.SurfaceTexture
import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.hardware.display.DisplayManager
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.net.Uri
import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLContext
import android.opengl.EGLDisplay
import android.opengl.EGLExt
import android.opengl.EGLSurface
import android.opengl.GLES11Ext
import android.opengl.GLES30
import android.opengl.Matrix
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.util.Base64
import android.view.Choreographer
import android.view.Surface
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.ar.core.Anchor
import com.google.ar.core.ArCoreApk
import com.google.ar.core.AugmentedFace
import com.google.ar.core.AugmentedImage
import com.google.ar.core.AugmentedImageDatabase
import com.google.ar.core.CameraConfig
import com.google.ar.core.CameraConfigFilter
import com.google.ar.core.Config
import com.google.ar.core.Coordinates2d
import com.google.ar.core.DepthPoint
import com.google.ar.core.Frame
import com.google.ar.core.HitResult
import com.google.ar.core.LightEstimate
import com.google.ar.core.Plane
import com.google.ar.core.Point
import com.google.ar.core.Pose
import com.google.ar.core.SemanticLabel
import com.google.ar.core.Session
import com.google.ar.core.Trackable
import com.google.ar.core.TrackingFailureReason
import com.google.ar.core.TrackingState
import com.google.ar.core.VpsAvailability
import com.google.ar.core.exceptions.NotYetAvailableException
import com.sinamn75.u.camera.USafeResult
import io.flutter.FlutterInjector
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.TextureRegistry
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.security.MessageDigest
import java.util.EnumSet
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.acos
import kotlin.math.atan
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.sqrt

// =============================================================================
// UAr — ARCore + OpenGL ES 3 implementation of the `u` AR / 3D plugin.
//
// Everything lives in this one file on purpose. ARCore is a compileOnly
// dependency: nothing in the classes loaded at startup touches it, so apps that
// never add `com.google.ar:core` keep working and only AR modes report
// "sdkMissing". The 3D viewer mode needs nothing beyond the OS.
//
// Rendering is a small self-contained glTF 2.0 renderer (PBR metallic /
// roughness, normal / occlusion / emissive maps, alpha modes, skinning, node
// animation, KHR_materials_unlit, KHR_texture_transform) drawing straight into
// a Flutter SurfaceProducer, so Flutter widgets compose over it with no
// platform-view cost.
// =============================================================================

private const val AR_PERMISSION_REQUEST = 75021
private const val STRIDE_FLOATS = 20
private const val STRIDE_BYTES = STRIDE_FLOATS * 4
private const val EGL_RECORDABLE_ANDROID = 0x3142
private const val EGL_OPENGL_ES3_BIT = 0x40

internal object UArMath {
    fun identity(): FloatArray = FloatArray(16).also { Matrix.setIdentityM(it, 0) }

    fun multiply(
        a: FloatArray,
        b: FloatArray,
    ): FloatArray = FloatArray(16).also { Matrix.multiplyMM(it, 0, a, 0, b, 0) }

    fun invert(m: FloatArray): FloatArray =
        FloatArray(16).also {
            if (!Matrix.invertM(it, 0, m, 0)) Matrix.setIdentityM(it, 0)
        }

    fun compose(
        t: FloatArray,
        q: FloatArray,
        s: FloatArray,
    ): FloatArray {
        val x = q[0]
        val y = q[1]
        val z = q[2]
        val w = q[3]
        val xx = x * x
        val yy = y * y
        val zz = z * z
        val xy = x * y
        val xz = x * z
        val yz = y * z
        val wx = w * x
        val wy = w * y
        val wz = w * z
        val m = FloatArray(16)
        m[0] = (1 - 2 * (yy + zz)) * s[0]
        m[1] = 2 * (xy + wz) * s[0]
        m[2] = 2 * (xz - wy) * s[0]
        m[4] = 2 * (xy - wz) * s[1]
        m[5] = (1 - 2 * (xx + zz)) * s[1]
        m[6] = 2 * (yz + wx) * s[1]
        m[8] = 2 * (xz + wy) * s[2]
        m[9] = 2 * (yz - wx) * s[2]
        m[10] = (1 - 2 * (xx + yy)) * s[2]
        m[12] = t[0]
        m[13] = t[1]
        m[14] = t[2]
        m[15] = 1f
        return m
    }

    fun transformPoint(
        m: FloatArray,
        x: Float,
        y: Float,
        z: Float,
    ): FloatArray =
        floatArrayOf(
            m[0] * x + m[4] * y + m[8] * z + m[12],
            m[1] * x + m[5] * y + m[9] * z + m[13],
            m[2] * x + m[6] * y + m[10] * z + m[14],
        )

    fun transformVector(
        m: FloatArray,
        x: Float,
        y: Float,
        z: Float,
    ): FloatArray =
        floatArrayOf(
            m[0] * x + m[4] * y + m[8] * z,
            m[1] * x + m[5] * y + m[9] * z,
            m[2] * x + m[6] * y + m[10] * z,
        )

    fun translation(m: FloatArray): FloatArray = floatArrayOf(m[12], m[13], m[14])

    fun scaleOf(m: FloatArray): FloatArray =
        floatArrayOf(
            sqrt(m[0] * m[0] + m[1] * m[1] + m[2] * m[2]),
            sqrt(m[4] * m[4] + m[5] * m[5] + m[6] * m[6]),
            sqrt(m[8] * m[8] + m[9] * m[9] + m[10] * m[10]),
        )

    fun rotationOf(m: FloatArray): FloatArray {
        val s = scaleOf(m)
        val sx = if (s[0] == 0f) 1f else s[0]
        val sy = if (s[1] == 0f) 1f else s[1]
        val sz = if (s[2] == 0f) 1f else s[2]
        return quatFromBasis(
            m[0] / sx,
            m[1] / sx,
            m[2] / sx,
            m[4] / sy,
            m[5] / sy,
            m[6] / sy,
            m[8] / sz,
            m[9] / sz,
            m[10] / sz,
        )
    }

    /** Quaternion from the columns of a rotation matrix. */
    fun quatFromBasis(
        m00: Float,
        m10: Float,
        m20: Float,
        m01: Float,
        m11: Float,
        m21: Float,
        m02: Float,
        m12: Float,
        m22: Float,
    ): FloatArray {
        val trace = m00 + m11 + m22
        return if (trace > 0) {
            val s = sqrt(trace + 1f) * 2f
            floatArrayOf((m21 - m12) / s, (m02 - m20) / s, (m10 - m01) / s, 0.25f * s)
        } else if (m00 > m11 && m00 > m22) {
            val s = sqrt(1f + m00 - m11 - m22) * 2f
            floatArrayOf(0.25f * s, (m01 + m10) / s, (m02 + m20) / s, (m21 - m12) / s)
        } else if (m11 > m22) {
            val s = sqrt(1f + m11 - m00 - m22) * 2f
            floatArrayOf((m01 + m10) / s, 0.25f * s, (m12 + m21) / s, (m02 - m20) / s)
        } else {
            val s = sqrt(1f + m22 - m00 - m11) * 2f
            floatArrayOf((m02 + m20) / s, (m12 + m21) / s, 0.25f * s, (m10 - m01) / s)
        }
    }

    fun quatMultiply(
        a: FloatArray,
        b: FloatArray,
    ): FloatArray =
        floatArrayOf(
            a[3] * b[0] + a[0] * b[3] + a[1] * b[2] - a[2] * b[1],
            a[3] * b[1] - a[0] * b[2] + a[1] * b[3] + a[2] * b[0],
            a[3] * b[2] + a[0] * b[1] - a[1] * b[0] + a[2] * b[3],
            a[3] * b[3] - a[0] * b[0] - a[1] * b[1] - a[2] * b[2],
        )

    fun quatNormalize(q: FloatArray): FloatArray {
        val l = sqrt(q[0] * q[0] + q[1] * q[1] + q[2] * q[2] + q[3] * q[3])
        return if (l < 1e-9f) floatArrayOf(0f, 0f, 0f, 1f) else floatArrayOf(q[0] / l, q[1] / l, q[2] / l, q[3] / l)
    }

    fun quatAxisAngle(
        x: Float,
        y: Float,
        z: Float,
        angle: Float,
    ): FloatArray {
        val s = sin(angle / 2)
        return floatArrayOf(x * s, y * s, z * s, cos(angle / 2))
    }

    fun quatSlerp(
        a: FloatArray,
        b: FloatArray,
        t: Float,
    ): FloatArray {
        var cosHalf = a[0] * b[0] + a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
        val target = if (cosHalf < 0) floatArrayOf(-b[0], -b[1], -b[2], -b[3]) else b
        if (cosHalf < 0) cosHalf = -cosHalf
        if (cosHalf > 0.9995f) {
            return quatNormalize(FloatArray(4) { a[it] + (target[it] - a[it]) * t })
        }
        val half = acos(cosHalf)
        val sinHalf = sqrt(1 - cosHalf * cosHalf)
        val ra = sin((1 - t) * half) / sinHalf
        val rb = sin(t * half) / sinHalf
        return FloatArray(4) { a[it] * ra + target[it] * rb }
    }

    fun quatRotate(
        q: FloatArray,
        v: FloatArray,
    ): FloatArray {
        val tx = 2 * (q[1] * v[2] - q[2] * v[1])
        val ty = 2 * (q[2] * v[0] - q[0] * v[2])
        val tz = 2 * (q[0] * v[1] - q[1] * v[0])
        return floatArrayOf(
            v[0] + q[3] * tx + (q[1] * tz - q[2] * ty),
            v[1] + q[3] * ty + (q[2] * tx - q[0] * tz),
            v[2] + q[3] * tz + (q[0] * ty - q[1] * tx),
        )
    }

    fun length(v: FloatArray): Float = sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])

    fun distance(
        a: FloatArray,
        b: FloatArray,
    ): Float = sqrt((a[0] - b[0]) * (a[0] - b[0]) + (a[1] - b[1]) * (a[1] - b[1]) + (a[2] - b[2]) * (a[2] - b[2]))

    fun poseMatrix(pose: List<Double>?): FloatArray {
        if (pose == null || pose.size < 7) return identity()
        return compose(
            floatArrayOf(pose[0].toFloat(), pose[1].toFloat(), pose[2].toFloat()),
            quatNormalize(floatArrayOf(pose[3].toFloat(), pose[4].toFloat(), pose[5].toFloat(), pose[6].toFloat())),
            floatArrayOf(1f, 1f, 1f),
        )
    }

    fun poseList(m: FloatArray): List<Double> {
        val t = translation(m)
        val q = rotationOf(m)
        return listOf(t[0], t[1], t[2], q[0], q[1], q[2], q[3]).map { it.toDouble() }
    }

    fun floats(
        raw: Any?,
        size: Int,
        fallback: Float,
    ): FloatArray {
        val list = raw as? List<*> ?: return FloatArray(size) { fallback }
        return FloatArray(size) { (list.getOrNull(it) as? Number)?.toFloat() ?: fallback }
    }

    /** Rotation that turns +Z toward the camera, around Y only or freely. */
    fun billboard(
        position: FloatArray,
        camera: FloatArray,
        yAxisOnly: Boolean,
    ): FloatArray {
        var dx = camera[0] - position[0]
        var dy = if (yAxisOnly) 0f else camera[1] - position[1]
        var dz = camera[2] - position[2]
        val l = sqrt(dx * dx + dy * dy + dz * dz)
        if (l < 1e-6f) return floatArrayOf(0f, 0f, 0f, 1f)
        dx /= l
        dy /= l
        dz /= l
        var rx = dz
        var ry = 0f
        var rz = -dx
        val rl = sqrt(rx * rx + rz * rz)
        if (rl < 1e-6f) {
            rx = 1f
            rz = 0f
        } else {
            rx /= rl
            rz /= rl
        }
        val ux = dy * rz - dz * ry
        val uy = dz * rx - dx * rz
        val uz = dx * ry - dy * rx
        ry = 0f
        return quatFromBasis(rx, ry, rz, ux, uy, uz, dx, dy, dz)
    }

    fun argb(
        value: Any?,
        fallback: Long,
    ): FloatArray {
        val c = (value as? Number)?.toLong() ?: fallback
        return floatArrayOf(((c shr 16) and 0xFF) / 255f, ((c shr 8) and 0xFF) / 255f, (c and 0xFF) / 255f, ((c shr 24) and 0xFF) / 255f)
    }

    /** sRGB colour from Flutter to linear light for the PBR shader. */
    fun linear(color: FloatArray): FloatArray =
        floatArrayOf(color[0].toDouble().pow(2.2).toFloat(), color[1].toDouble().pow(2.2).toFloat(), color[2].toDouble().pow(2.2).toFloat(), color[3])

    fun rayAabb(
        origin: FloatArray,
        dir: FloatArray,
        min: FloatArray,
        max: FloatArray,
    ): Float? {
        var tMin = -Float.MAX_VALUE
        var tMax = Float.MAX_VALUE
        for (i in 0 until 3) {
            if (abs(dir[i]) < 1e-9f) {
                if (origin[i] < min[i] || origin[i] > max[i]) return null
            } else {
                var t1 = (min[i] - origin[i]) / dir[i]
                var t2 = (max[i] - origin[i]) / dir[i]
                if (t1 > t2) {
                    val tmp = t1
                    t1 = t2
                    t2 = tmp
                }
                tMin = max(tMin, t1)
                tMax = min(tMax, t2)
                if (tMin > tMax) return null
            }
        }
        if (tMax < 0) return null
        return if (tMin >= 0) tMin else tMax
    }

    fun transformAabb(
        m: FloatArray,
        min: FloatArray,
        max: FloatArray,
    ): Pair<FloatArray, FloatArray> {
        val outMin = floatArrayOf(Float.MAX_VALUE, Float.MAX_VALUE, Float.MAX_VALUE)
        val outMax = floatArrayOf(-Float.MAX_VALUE, -Float.MAX_VALUE, -Float.MAX_VALUE)
        for (i in 0 until 8) {
            val p =
                transformPoint(
                    m,
                    if (i and 1 == 0) min[0] else max[0],
                    if (i and 2 == 0) min[1] else max[1],
                    if (i and 4 == 0) min[2] else max[2],
                )
            for (k in 0 until 3) {
                outMin[k] = min(outMin[k], p[k])
                outMax[k] = max(outMax[k], p[k])
            }
        }
        return Pair(outMin, outMax)
    }
}

// =============================================================================
// Sources
// =============================================================================

/** Resolves a Dart `UArSource` map into bytes or a local file. */
internal class UArSourceLoader(
    private val context: Context,
) {
    class Loaded(
        val bytes: ByteArray,
        val kind: String,
        val base: String?,
        val extension: String,
    )

    private val cacheDir = File(context.cacheDir, "u_ar").apply { mkdirs() }

    fun load(source: Map<*, *>?): Loaded {
        if (source == null) throw IllegalArgumentException("Missing source")
        val kind = source["kind"] as? String ?: "url"
        val value = source["value"]
        val ext = (source["ext"] as? String ?: "").lowercase()
        return when (kind) {
            "bytes" -> Loaded(value as? ByteArray ?: throw IllegalArgumentException("Missing bytes"), kind, null, ext)
            "asset" -> {
                val asset = value as String
                Loaded(readAsset(asset), kind, asset.substringBeforeLast('/', ""), ext)
            }
            "file" -> {
                val path = value as String
                Loaded(File(path).readBytes(), kind, File(path).parent, ext)
            }
            else -> {
                val url = value as String
                Loaded(download(url).readBytes(), kind, url.substringBeforeLast('/', ""), ext)
            }
        }
    }

    fun loadRelative(
        parent: Loaded,
        uri: String,
    ): ByteArray {
        if (uri.startsWith("data:")) {
            return Base64.decode(uri.substringAfter(","), Base64.DEFAULT)
        }
        val decoded = Uri.decode(uri)
        return when (parent.kind) {
            "asset" -> readAsset(if (parent.base.isNullOrEmpty()) decoded else "${parent.base}/$decoded")
            "file" -> File(parent.base ?: "", decoded).readBytes()
            "url" -> download(if (uri.startsWith("http")) uri else "${parent.base}/$uri").readBytes()
            else -> throw IllegalArgumentException("External resources need a url, asset or file source")
        }
    }

    fun toFile(source: Map<*, *>?): File {
        if (source == null) throw IllegalArgumentException("Missing source")
        val kind = source["kind"] as? String ?: "url"
        val value = source["value"]
        val ext = (source["ext"] as? String ?: "bin").ifEmpty { "bin" }
        return when (kind) {
            "file" -> File(value as String)
            "url" -> download(value as String)
            "asset" -> {
                val target = File(cacheDir, "asset_${hash(value as String)}.$ext")
                if (!target.exists()) target.writeBytes(readAsset(value))
                target
            }
            else -> {
                val bytes = value as ByteArray
                val target = File(cacheDir, "bytes_${hash(bytes.size.toString() + bytes.contentHashCode())}.$ext")
                if (!target.exists()) target.writeBytes(bytes)
                target
            }
        }
    }

    fun readAsset(asset: String): ByteArray {
        val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(asset)
        return context.assets.open(key).use { it.readBytes() }
    }

    fun download(url: String): File {
        val ext = url.substringBefore('?').substringAfterLast('.', "bin").take(8)
        val target = File(cacheDir, "${hash(url)}.$ext")
        if (target.exists() && target.length() > 0) return target
        var current = url
        var redirects = 0
        while (true) {
            val connection = URL(current).openConnection() as HttpURLConnection
            connection.connectTimeout = 20000
            connection.readTimeout = 60000
            connection.instanceFollowRedirects = true
            val code = connection.responseCode
            if (code in 300..399 && redirects < 5) {
                current = connection.getHeaderField("Location") ?: break
                redirects++
                connection.disconnect()
                continue
            }
            if (code !in 200..299) {
                connection.disconnect()
                throw IllegalStateException("HTTP $code for $url")
            }
            val temp = File(cacheDir, "${hash(url)}.part")
            connection.inputStream.use { input -> temp.outputStream().use { input.copyTo(it) } }
            connection.disconnect()
            temp.renameTo(target)
            return target
        }
        throw IllegalStateException("Too many redirects for $url")
    }

    private fun hash(value: String): String {
        val digest = MessageDigest.getInstance("SHA-1").digest(value.toByteArray())
        return digest.joinToString("") { "%02x".format(it) }
    }
}

// =============================================================================
// glTF 2.0 — CPU side
// =============================================================================

/** Interleaved vertices: position 3, normal 3, uv 2, joints 4, weights 4, colour 4. */
internal class UMeshData(
    val vertices: FloatArray,
    val indices: IntArray,
    val min: FloatArray,
    val max: FloatArray,
) {
    companion object {
        fun build(
            positions: FloatArray,
            normals: FloatArray?,
            uvs: FloatArray?,
            joints: FloatArray?,
            weights: FloatArray?,
            colors: FloatArray?,
            colorComponents: Int,
            indices: IntArray,
        ): UMeshData {
            val count = positions.size / 3
            val n = normals ?: computeNormals(positions, indices)
            val out = FloatArray(count * STRIDE_FLOATS)
            val min = floatArrayOf(Float.MAX_VALUE, Float.MAX_VALUE, Float.MAX_VALUE)
            val max = floatArrayOf(-Float.MAX_VALUE, -Float.MAX_VALUE, -Float.MAX_VALUE)
            for (i in 0 until count) {
                val o = i * STRIDE_FLOATS
                for (k in 0 until 3) {
                    val p = positions[i * 3 + k]
                    out[o + k] = p
                    min[k] = min(min[k], p)
                    max[k] = max(max[k], p)
                    out[o + 3 + k] = n.getOrElse(i * 3 + k) { 0f }
                }
                out[o + 6] = uvs?.getOrNull(i * 2) ?: 0f
                out[o + 7] = uvs?.getOrNull(i * 2 + 1) ?: 0f
                for (k in 0 until 4) {
                    out[o + 8 + k] = joints?.getOrNull(i * 4 + k) ?: 0f
                    out[o + 12 + k] = weights?.getOrNull(i * 4 + k) ?: 0f
                }
                if (colors != null) {
                    out[o + 16] = colors.getOrElse(i * colorComponents) { 1f }
                    out[o + 17] = colors.getOrElse(i * colorComponents + 1) { 1f }
                    out[o + 18] = colors.getOrElse(i * colorComponents + 2) { 1f }
                    out[o + 19] = if (colorComponents == 4) colors.getOrElse(i * 4 + 3) { 1f } else 1f
                } else {
                    out[o + 16] = 1f
                    out[o + 17] = 1f
                    out[o + 18] = 1f
                    out[o + 19] = 1f
                }
            }
            if (count == 0) {
                min.fill(0f)
                max.fill(0f)
            }
            return UMeshData(out, indices, min, max)
        }

        fun computeNormals(
            positions: FloatArray,
            indices: IntArray,
        ): FloatArray {
            val normals = FloatArray(positions.size)
            var i = 0
            while (i + 2 < indices.size) {
                val a = indices[i] * 3
                val b = indices[i + 1] * 3
                val c = indices[i + 2] * 3
                val ux = positions[b] - positions[a]
                val uy = positions[b + 1] - positions[a + 1]
                val uz = positions[b + 2] - positions[a + 2]
                val vx = positions[c] - positions[a]
                val vy = positions[c + 1] - positions[a + 1]
                val vz = positions[c + 2] - positions[a + 2]
                val nx = uy * vz - uz * vy
                val ny = uz * vx - ux * vz
                val nz = ux * vy - uy * vx
                for (v in intArrayOf(a, b, c)) {
                    normals[v] += nx
                    normals[v + 1] += ny
                    normals[v + 2] += nz
                }
                i += 3
            }
            var k = 0
            while (k + 2 < normals.size) {
                val l = sqrt(normals[k] * normals[k] + normals[k + 1] * normals[k + 1] + normals[k + 2] * normals[k + 2])
                if (l > 0) {
                    normals[k] /= l
                    normals[k + 1] /= l
                    normals[k + 2] /= l
                } else {
                    normals[k + 1] = 1f
                }
                k += 3
            }
            return normals
        }
    }
}

internal class UMaterialData(
    val baseColor: FloatArray = floatArrayOf(1f, 1f, 1f, 1f),
    val metallic: Float = 1f,
    val roughness: Float = 1f,
    val emissive: FloatArray = floatArrayOf(0f, 0f, 0f),
    val baseTexture: Int = -1,
    val metallicRoughnessTexture: Int = -1,
    val normalTexture: Int = -1,
    val occlusionTexture: Int = -1,
    val emissiveTexture: Int = -1,
    val normalScale: Float = 1f,
    val occlusionStrength: Float = 1f,
    val alphaMode: Int = 0,
    val alphaCutoff: Float = 0.5f,
    val doubleSided: Boolean = false,
    val unlit: Boolean = false,
    val uvTransform: FloatArray? = null,
)

internal class UGltfNode(
    val name: String,
    val children: IntArray,
    val mesh: Int,
    val skin: Int,
    val translation: FloatArray,
    val rotation: FloatArray,
    val scale: FloatArray,
    val matrix: FloatArray?,
)

internal class UGltfTexture(
    val image: Int,
    val wrapS: Int,
    val wrapT: Int,
    val minFilter: Int,
    val magFilter: Int,
)

internal class UGltfSkin(
    val joints: IntArray,
    val inverseBind: FloatArray,
)

internal class UGltfChannel(
    val node: Int,
    val path: String,
    val times: FloatArray,
    val values: FloatArray,
    val interpolation: String,
    val components: Int,
)

internal class UGltfAnimation(
    val name: String,
    val channels: List<UGltfChannel>,
    val duration: Float,
)

internal class UGltfPrimitive(
    val mesh: UMeshData,
    val material: Int,
)

internal class UGltfData(
    val nodes: List<UGltfNode>,
    val roots: IntArray,
    val meshes: List<List<UGltfPrimitive>>,
    val materials: List<UMaterialData>,
    val textures: List<UGltfTexture>,
    val images: List<Bitmap?>,
    val skins: List<UGltfSkin>,
    val animations: List<UGltfAnimation>,
)

internal object UGltfParser {
    private const val GLB_MAGIC = 0x46546C67
    private const val CHUNK_JSON = 0x4E4F534A
    private const val CHUNK_BIN = 0x004E4942

    fun parse(
        loaded: UArSourceLoader.Loaded,
        loader: UArSourceLoader,
    ): UGltfData {
        val bytes = loaded.bytes
        var json: JSONObject
        var glbBin: ByteBuffer? = null
        val header = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
        if (bytes.size >= 12 && header.getInt(0) == GLB_MAGIC) {
            var offset = 12
            json = JSONObject()
            while (offset + 8 <= bytes.size) {
                val length = header.getInt(offset)
                val type = header.getInt(offset + 4)
                val start = offset + 8
                if (type == CHUNK_JSON) {
                    json = JSONObject(String(bytes, start, length, Charsets.UTF_8))
                } else if (type == CHUNK_BIN) {
                    glbBin = ByteBuffer.wrap(bytes, start, length).slice().order(ByteOrder.LITTLE_ENDIAN)
                }
                offset = start + length + ((4 - length % 4) % 4)
            }
        } else {
            json = JSONObject(String(bytes, Charsets.UTF_8))
        }

        val required = json.optJSONArray("extensionsRequired")
        if (required != null) {
            for (i in 0 until required.length()) {
                val name = required.getString(i)
                if (name == "KHR_draco_mesh_compression" || name == "EXT_meshopt_compression") {
                    throw IllegalStateException("$name is not supported; export the model without mesh compression")
                }
            }
        }

        val buffers = mutableListOf<ByteBuffer>()
        val bufferArray = json.optJSONArray("buffers") ?: JSONArray()
        for (i in 0 until bufferArray.length()) {
            val buffer = bufferArray.getJSONObject(i)
            val uri = buffer.optString("uri", "")
            val data =
                if (uri.isEmpty()) {
                    glbBin ?: ByteBuffer.allocate(0)
                } else {
                    ByteBuffer.wrap(loader.loadRelative(loaded, uri)).order(ByteOrder.LITTLE_ENDIAN)
                }
            buffers.add(data)
        }

        val reader = Reader(json, buffers)
        val images = readImages(json, reader, loaded, loader)
        val textures = readTextures(json)
        val materials = readMaterials(json)
        val meshes = readMeshes(json, reader)
        val nodes = readNodes(json)
        val skins = readSkins(json, reader)
        val animations = readAnimations(json, reader)

        val sceneArray = json.optJSONArray("scenes")
        val roots =
            if (sceneArray != null && sceneArray.length() > 0) {
                val scene = sceneArray.getJSONObject(json.optInt("scene", 0).coerceIn(0, sceneArray.length() - 1))
                val list = scene.optJSONArray("nodes") ?: JSONArray()
                IntArray(list.length()) { list.getInt(it) }
            } else {
                val childSet = nodes.flatMap { it.children.toList() }.toSet()
                nodes.indices.filter { it !in childSet }.toIntArray()
            }
        return UGltfData(nodes, roots, meshes, materials, textures, images, skins, animations)
    }

    private class Reader(
        val json: JSONObject,
        val buffers: List<ByteBuffer>,
    ) {
        private val accessors = json.optJSONArray("accessors") ?: JSONArray()
        private val views = json.optJSONArray("bufferViews") ?: JSONArray()

        fun components(type: String): Int =
            when (type) {
                "SCALAR" -> 1
                "VEC2" -> 2
                "VEC3" -> 3
                "VEC4" -> 4
                "MAT2" -> 4
                "MAT3" -> 9
                "MAT4" -> 16
                else -> 1
            }

        fun componentSize(type: Int): Int =
            when (type) {
                5120, 5121 -> 1
                5122, 5123 -> 2
                else -> 4
            }

        fun count(index: Int): Int = accessors.getJSONObject(index).getInt("count")

        fun componentsOf(index: Int): Int = components(accessors.getJSONObject(index).getString("type"))

        private fun read(
            buffer: ByteBuffer,
            position: Int,
            type: Int,
            normalized: Boolean,
        ): Float =
            when (type) {
                5120 -> buffer.get(position).toFloat().let { if (normalized) max(it / 127f, -1f) else it }
                5121 -> (buffer.get(position).toInt() and 0xFF).toFloat().let { if (normalized) it / 255f else it }
                5122 -> buffer.getShort(position).toFloat().let { if (normalized) max(it / 32767f, -1f) else it }
                5123 -> (buffer.getShort(position).toInt() and 0xFFFF).toFloat().let { if (normalized) it / 65535f else it }
                5125 -> (buffer.getInt(position).toLong() and 0xFFFFFFFFL).toFloat()
                else -> buffer.getFloat(position)
            }

        private fun viewInfo(viewIndex: Int): Triple<ByteBuffer, Int, Int> {
            val view = views.getJSONObject(viewIndex)
            return Triple(buffers[view.getInt("buffer")], view.optInt("byteOffset", 0), view.optInt("byteStride", 0))
        }

        fun floats(index: Int): FloatArray {
            val accessor = accessors.getJSONObject(index)
            val count = accessor.getInt("count")
            val comps = components(accessor.getString("type"))
            val type = accessor.getInt("componentType")
            val normalized = accessor.optBoolean("normalized", false)
            val out = FloatArray(count * comps)
            if (accessor.has("bufferView")) {
                val (buffer, viewOffset, viewStride) = viewInfo(accessor.getInt("bufferView"))
                val size = componentSize(type)
                val stride = if (viewStride == 0) size * comps else viewStride
                val base = viewOffset + accessor.optInt("byteOffset", 0)
                for (i in 0 until count) {
                    for (c in 0 until comps) {
                        out[i * comps + c] = read(buffer, base + i * stride + c * size, type, normalized)
                    }
                }
            }
            val sparse = accessor.optJSONObject("sparse")
            if (sparse != null) {
                val sparseCount = sparse.getInt("count")
                val idx = sparse.getJSONObject("indices")
                val values = sparse.getJSONObject("values")
                val (idxBuffer, idxOffset, _) = viewInfo(idx.getInt("bufferView"))
                val idxType = idx.getInt("componentType")
                val idxBase = idxOffset + idx.optInt("byteOffset", 0)
                val (valBuffer, valOffset, _) = viewInfo(values.getInt("bufferView"))
                val valBase = valOffset + values.optInt("byteOffset", 0)
                val size = componentSize(type)
                for (s in 0 until sparseCount) {
                    val target = read(idxBuffer, idxBase + s * componentSize(idxType), idxType, false).toInt()
                    for (c in 0 until comps) {
                        out[target * comps + c] = read(valBuffer, valBase + (s * comps + c) * size, type, normalized)
                    }
                }
            }
            return out
        }

        fun ints(index: Int): IntArray {
            val accessor = accessors.getJSONObject(index)
            val count = accessor.getInt("count")
            val type = accessor.getInt("componentType")
            val (buffer, viewOffset, viewStride) = viewInfo(accessor.getInt("bufferView"))
            val size = componentSize(type)
            val stride = if (viewStride == 0) size else viewStride
            val base = viewOffset + accessor.optInt("byteOffset", 0)
            return IntArray(count) {
                val p = base + it * stride
                when (type) {
                    5121 -> buffer.get(p).toInt() and 0xFF
                    5123 -> buffer.getShort(p).toInt() and 0xFFFF
                    else -> buffer.getInt(p)
                }
            }
        }

        fun bytesOfView(viewIndex: Int): ByteArray {
            val view = views.getJSONObject(viewIndex)
            val buffer = buffers[view.getInt("buffer")]
            val offset = view.optInt("byteOffset", 0)
            val length = view.getInt("byteLength")
            val out = ByteArray(length)
            for (i in 0 until length) out[i] = buffer.get(offset + i)
            return out
        }
    }

    private fun readImages(
        json: JSONObject,
        reader: Reader,
        loaded: UArSourceLoader.Loaded,
        loader: UArSourceLoader,
    ): List<Bitmap?> {
        val array = json.optJSONArray("images") ?: return emptyList()
        return (0 until array.length()).map { i ->
            runCatching {
                val image = array.getJSONObject(i)
                val bytes =
                    if (image.has("bufferView")) {
                        reader.bytesOfView(image.getInt("bufferView"))
                    } else {
                        loader.loadRelative(loaded, image.getString("uri"))
                    }
                UArTextures.decode(bytes, 2048)
            }.getOrNull()
        }
    }

    private fun readTextures(json: JSONObject): List<UGltfTexture> {
        val array = json.optJSONArray("textures") ?: return emptyList()
        val samplers = json.optJSONArray("samplers") ?: JSONArray()
        return (0 until array.length()).map { i ->
            val texture = array.getJSONObject(i)
            val sampler = if (texture.has("sampler")) samplers.optJSONObject(texture.getInt("sampler")) else null
            UGltfTexture(
                image = texture.optInt("source", -1),
                wrapS = sampler?.optInt("wrapS", GLES30.GL_REPEAT) ?: GLES30.GL_REPEAT,
                wrapT = sampler?.optInt("wrapT", GLES30.GL_REPEAT) ?: GLES30.GL_REPEAT,
                minFilter = sampler?.optInt("minFilter", GLES30.GL_LINEAR_MIPMAP_LINEAR) ?: GLES30.GL_LINEAR_MIPMAP_LINEAR,
                magFilter = sampler?.optInt("magFilter", GLES30.GL_LINEAR) ?: GLES30.GL_LINEAR,
            )
        }
    }

    private fun floatsOf(
        array: JSONArray?,
        size: Int,
        fallback: Float,
    ): FloatArray = FloatArray(size) { if (array != null && it < array.length()) array.optDouble(it, fallback.toDouble()).toFloat() else fallback }

    private fun uvTransform(textureInfo: JSONObject?): FloatArray? {
        val transform = textureInfo?.optJSONObject("extensions")?.optJSONObject("KHR_texture_transform") ?: return null
        val offset = floatsOf(transform.optJSONArray("offset"), 2, 0f)
        val scale = floatsOf(transform.optJSONArray("scale"), 2, 1f)
        val rotation = transform.optDouble("rotation", 0.0).toFloat()
        val c = cos(rotation)
        val s = sin(rotation)
        return floatArrayOf(c * scale[0], -s * scale[0], 0f, s * scale[1], c * scale[1], 0f, offset[0], offset[1], 1f)
    }

    private fun readMaterials(json: JSONObject): List<UMaterialData> {
        val array = json.optJSONArray("materials") ?: return emptyList()
        return (0 until array.length()).map { i ->
            val material = array.getJSONObject(i)
            val pbr = material.optJSONObject("pbrMetallicRoughness") ?: JSONObject()
            val extensions = material.optJSONObject("extensions")
            val emissiveStrength = extensions?.optJSONObject("KHR_materials_emissive_strength")?.optDouble("emissiveStrength", 1.0)?.toFloat() ?: 1f
            val emissive = floatsOf(material.optJSONArray("emissiveFactor"), 3, 0f).map { it * emissiveStrength }.toFloatArray()
            val baseInfo = pbr.optJSONObject("baseColorTexture")
            UMaterialData(
                baseColor = floatsOf(pbr.optJSONArray("baseColorFactor"), 4, 1f),
                metallic = pbr.optDouble("metallicFactor", 1.0).toFloat(),
                roughness = pbr.optDouble("roughnessFactor", 1.0).toFloat(),
                emissive = emissive,
                baseTexture = baseInfo?.optInt("index", -1) ?: -1,
                metallicRoughnessTexture = pbr.optJSONObject("metallicRoughnessTexture")?.optInt("index", -1) ?: -1,
                normalTexture = material.optJSONObject("normalTexture")?.optInt("index", -1) ?: -1,
                occlusionTexture = material.optJSONObject("occlusionTexture")?.optInt("index", -1) ?: -1,
                emissiveTexture = material.optJSONObject("emissiveTexture")?.optInt("index", -1) ?: -1,
                normalScale = material.optJSONObject("normalTexture")?.optDouble("scale", 1.0)?.toFloat() ?: 1f,
                occlusionStrength = material.optJSONObject("occlusionTexture")?.optDouble("strength", 1.0)?.toFloat() ?: 1f,
                alphaMode =
                    when (material.optString("alphaMode", "OPAQUE")) {
                        "MASK" -> 1
                        "BLEND" -> 2
                        else -> 0
                    },
                alphaCutoff = material.optDouble("alphaCutoff", 0.5).toFloat(),
                doubleSided = material.optBoolean("doubleSided", false),
                unlit = extensions?.has("KHR_materials_unlit") == true,
                uvTransform = uvTransform(baseInfo),
            )
        }
    }

    private fun readMeshes(
        json: JSONObject,
        reader: Reader,
    ): List<List<UGltfPrimitive>> {
        val array = json.optJSONArray("meshes") ?: return emptyList()
        return (0 until array.length()).map { i ->
            val primitives = array.getJSONObject(i).optJSONArray("primitives") ?: JSONArray()
            (0 until primitives.length()).mapNotNull { p ->
                val primitive = primitives.getJSONObject(p)
                val mode = primitive.optInt("mode", 4)
                if (mode != 4 && mode != 5 && mode != 6) return@mapNotNull null
                val attributes = primitive.getJSONObject("attributes")
                if (!attributes.has("POSITION")) return@mapNotNull null
                val positions = reader.floats(attributes.getInt("POSITION"))
                val count = positions.size / 3
                var indices = if (primitive.has("indices")) reader.ints(primitive.getInt("indices")) else IntArray(count) { it }
                indices =
                    when (mode) {
                        5 -> strip(indices)
                        6 -> fan(indices)
                        else -> indices
                    }
                val colorIndex = if (attributes.has("COLOR_0")) attributes.getInt("COLOR_0") else -1
                UGltfPrimitive(
                    UMeshData.build(
                        positions = positions,
                        normals = if (attributes.has("NORMAL")) reader.floats(attributes.getInt("NORMAL")) else null,
                        uvs = if (attributes.has("TEXCOORD_0")) reader.floats(attributes.getInt("TEXCOORD_0")) else null,
                        joints = if (attributes.has("JOINTS_0")) reader.floats(attributes.getInt("JOINTS_0")) else null,
                        weights = if (attributes.has("WEIGHTS_0")) reader.floats(attributes.getInt("WEIGHTS_0")) else null,
                        colors = if (colorIndex >= 0) reader.floats(colorIndex) else null,
                        colorComponents = if (colorIndex >= 0) reader.componentsOf(colorIndex) else 4,
                        indices = indices,
                    ),
                    primitive.optInt("material", -1),
                )
            }
        }
    }

    private fun strip(indices: IntArray): IntArray {
        val out = ArrayList<Int>()
        for (i in 0 until indices.size - 2) {
            if (i % 2 == 0) {
                out.add(indices[i])
                out.add(indices[i + 1])
            } else {
                out.add(indices[i + 1])
                out.add(indices[i])
            }
            out.add(indices[i + 2])
        }
        return out.toIntArray()
    }

    private fun fan(indices: IntArray): IntArray {
        val out = ArrayList<Int>()
        for (i in 1 until indices.size - 1) {
            out.add(indices[0])
            out.add(indices[i])
            out.add(indices[i + 1])
        }
        return out.toIntArray()
    }

    private fun readNodes(json: JSONObject): List<UGltfNode> {
        val array = json.optJSONArray("nodes") ?: return emptyList()
        return (0 until array.length()).map { i ->
            val node = array.getJSONObject(i)
            val children = node.optJSONArray("children")
            val matrix = node.optJSONArray("matrix")
            UGltfNode(
                name = node.optString("name", "node$i"),
                children = if (children == null) IntArray(0) else IntArray(children.length()) { children.getInt(it) },
                mesh = node.optInt("mesh", -1),
                skin = node.optInt("skin", -1),
                translation = floatsOf(node.optJSONArray("translation"), 3, 0f),
                rotation = if (node.has("rotation")) floatsOf(node.optJSONArray("rotation"), 4, 0f) else floatArrayOf(0f, 0f, 0f, 1f),
                scale = floatsOf(node.optJSONArray("scale"), 3, 1f),
                matrix = if (matrix != null && matrix.length() == 16) floatsOf(matrix, 16, 0f) else null,
            )
        }
    }

    private fun readSkins(
        json: JSONObject,
        reader: Reader,
    ): List<UGltfSkin> {
        val array = json.optJSONArray("skins") ?: return emptyList()
        return (0 until array.length()).map { i ->
            val skin = array.getJSONObject(i)
            val jointArray = skin.getJSONArray("joints")
            val joints = IntArray(jointArray.length()) { jointArray.getInt(it) }
            val inverse =
                if (skin.has("inverseBindMatrices")) {
                    reader.floats(skin.getInt("inverseBindMatrices"))
                } else {
                    FloatArray(joints.size * 16).also { m -> for (j in joints.indices) Matrix.setIdentityM(m, j * 16) }
                }
            UGltfSkin(joints, inverse)
        }
    }

    private fun readAnimations(
        json: JSONObject,
        reader: Reader,
    ): List<UGltfAnimation> {
        val array = json.optJSONArray("animations") ?: return emptyList()
        return (0 until array.length()).map { i ->
            val animation = array.getJSONObject(i)
            val samplers = animation.getJSONArray("samplers")
            val channelArray = animation.getJSONArray("channels")
            var duration = 0f
            val channels =
                (0 until channelArray.length()).mapNotNull { c ->
                    val channel = channelArray.getJSONObject(c)
                    val target = channel.getJSONObject("target")
                    val path = target.optString("path")
                    if (!target.has("node") || path == "weights") return@mapNotNull null
                    val sampler = samplers.getJSONObject(channel.getInt("sampler"))
                    val times = reader.floats(sampler.getInt("input"))
                    val values = reader.floats(sampler.getInt("output"))
                    if (times.isNotEmpty()) duration = max(duration, times.last())
                    UGltfChannel(
                        node = target.getInt("node"),
                        path = path,
                        times = times,
                        values = values,
                        interpolation = sampler.optString("interpolation", "LINEAR"),
                        components = if (path == "rotation") 4 else 3,
                    )
                }
            UGltfAnimation(animation.optString("name", "animation$i"), channels, duration)
        }
    }
}

// =============================================================================
// OpenGL ES 3 — GPU side
// =============================================================================

internal object UArTextures {
    fun decode(
        bytes: ByteArray,
        maxSize: Int,
    ): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        var sample = 1
        while (bounds.outWidth / sample > maxSize || bounds.outHeight / sample > maxSize) sample *= 2
        val options =
            BitmapFactory.Options().apply {
                inSampleSize = sample
                inPremultiplied = false
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options) ?: return null
        if (bitmap.config == Bitmap.Config.ARGB_8888) return bitmap
        return bitmap.copy(Bitmap.Config.ARGB_8888, false).also { bitmap.recycle() }
    }

    fun upload(
        bitmap: Bitmap,
        wrapS: Int = GLES30.GL_REPEAT,
        wrapT: Int = GLES30.GL_REPEAT,
        minFilter: Int = GLES30.GL_LINEAR_MIPMAP_LINEAR,
        magFilter: Int = GLES30.GL_LINEAR,
    ): Int {
        val ids = IntArray(1)
        GLES30.glGenTextures(1, ids, 0)
        GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, ids[0])
        val buffer = ByteBuffer.allocateDirect(bitmap.byteCount).order(ByteOrder.nativeOrder())
        bitmap.copyPixelsToBuffer(buffer)
        buffer.position(0)
        GLES30.glPixelStorei(GLES30.GL_UNPACK_ALIGNMENT, 1)
        GLES30.glTexImage2D(GLES30.GL_TEXTURE_2D, 0, GLES30.GL_RGBA8, bitmap.width, bitmap.height, 0, GLES30.GL_RGBA, GLES30.GL_UNSIGNED_BYTE, buffer)
        GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_WRAP_S, wrapS)
        GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_WRAP_T, wrapT)
        GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_MIN_FILTER, minFilter)
        GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_MAG_FILTER, magFilter)
        if (minFilter != GLES30.GL_LINEAR && minFilter != GLES30.GL_NEAREST) GLES30.glGenerateMipmap(GLES30.GL_TEXTURE_2D)
        return ids[0]
    }

    fun solid(
        r: Int,
        g: Int,
        b: Int,
        a: Int,
    ): Int {
        val ids = IntArray(1)
        GLES30.glGenTextures(1, ids, 0)
        GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, ids[0])
        val buffer = ByteBuffer.allocateDirect(4).put(byteArrayOf(r.toByte(), g.toByte(), b.toByte(), a.toByte()))
        buffer.position(0)
        GLES30.glTexImage2D(GLES30.GL_TEXTURE_2D, 0, GLES30.GL_RGBA8, 1, 1, 0, GLES30.GL_RGBA, GLES30.GL_UNSIGNED_BYTE, buffer)
        GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_MIN_FILTER, GLES30.GL_NEAREST)
        GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_MAG_FILTER, GLES30.GL_NEAREST)
        return ids[0]
    }

    fun external(): Int {
        val ids = IntArray(1)
        GLES30.glGenTextures(1, ids, 0)
        GLES30.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, ids[0])
        GLES30.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES30.GL_TEXTURE_WRAP_S, GLES30.GL_CLAMP_TO_EDGE)
        GLES30.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES30.GL_TEXTURE_WRAP_T, GLES30.GL_CLAMP_TO_EDGE)
        GLES30.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES30.GL_TEXTURE_MIN_FILTER, GLES30.GL_LINEAR)
        GLES30.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES30.GL_TEXTURE_MAG_FILTER, GLES30.GL_LINEAR)
        return ids[0]
    }

    fun delete(id: Int) {
        if (id != 0) GLES30.glDeleteTextures(1, intArrayOf(id), 0)
    }
}

internal class UProgram(
    vertex: String,
    fragment: String,
) {
    val id: Int = link(compile(GLES30.GL_VERTEX_SHADER, vertex), compile(GLES30.GL_FRAGMENT_SHADER, fragment))
    private val locations = HashMap<String, Int>()

    fun use() = GLES30.glUseProgram(id)

    fun loc(name: String): Int = locations.getOrPut(name) { GLES30.glGetUniformLocation(id, name) }

    fun mat4(
        name: String,
        value: FloatArray,
    ) = GLES30.glUniformMatrix4fv(loc(name), 1, false, value, 0)

    fun mat3(
        name: String,
        value: FloatArray,
    ) = GLES30.glUniformMatrix3fv(loc(name), 1, false, value, 0)

    fun vec4(
        name: String,
        value: FloatArray,
    ) = GLES30.glUniform4f(loc(name), value[0], value[1], value[2], value.getOrElse(3) { 1f })

    fun vec3(
        name: String,
        value: FloatArray,
    ) = GLES30.glUniform3f(loc(name), value[0], value[1], value[2])

    fun vec2(
        name: String,
        x: Float,
        y: Float,
    ) = GLES30.glUniform2f(loc(name), x, y)

    fun float(
        name: String,
        value: Float,
    ) = GLES30.glUniform1f(loc(name), value)

    fun int(
        name: String,
        value: Int,
    ) = GLES30.glUniform1i(loc(name), value)

    fun texture(
        name: String,
        unit: Int,
        id: Int,
        target: Int = GLES30.GL_TEXTURE_2D,
    ) {
        GLES30.glActiveTexture(GLES30.GL_TEXTURE0 + unit)
        GLES30.glBindTexture(target, id)
        GLES30.glUniform1i(loc(name), unit)
    }

    fun release() = GLES30.glDeleteProgram(id)

    private fun compile(
        type: Int,
        source: String,
    ): Int {
        val shader = GLES30.glCreateShader(type)
        GLES30.glShaderSource(shader, source)
        GLES30.glCompileShader(shader)
        val status = IntArray(1)
        GLES30.glGetShaderiv(shader, GLES30.GL_COMPILE_STATUS, status, 0)
        if (status[0] == 0) {
            val log = GLES30.glGetShaderInfoLog(shader)
            GLES30.glDeleteShader(shader)
            throw IllegalStateException("Shader compile failed: $log")
        }
        return shader
    }

    private fun link(
        vs: Int,
        fs: Int,
    ): Int {
        val program = GLES30.glCreateProgram()
        GLES30.glAttachShader(program, vs)
        GLES30.glAttachShader(program, fs)
        GLES30.glLinkProgram(program)
        val status = IntArray(1)
        GLES30.glGetProgramiv(program, GLES30.GL_LINK_STATUS, status, 0)
        GLES30.glDeleteShader(vs)
        GLES30.glDeleteShader(fs)
        if (status[0] == 0) throw IllegalStateException("Program link failed: ${GLES30.glGetProgramInfoLog(program)}")
        return program
    }
}

internal object UArShaders {
    const val BACKGROUND_VS = """#version 300 es
layout(location = 0) in vec2 a_Position;
layout(location = 1) in vec2 a_TexCoord;
out vec2 v_TexCoord;
void main() {
    gl_Position = vec4(a_Position, 0.0, 1.0);
    v_TexCoord = a_TexCoord;
}
"""

    const val BACKGROUND_FS = """#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump float;
uniform samplerExternalOES u_Texture;
in vec2 v_TexCoord;
out vec4 o_Color;
void main() {
    o_Color = vec4(texture(u_Texture, v_TexCoord).rgb, 1.0);
}
"""

    const val PBR_VS = """#version 300 es
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
out float v_ViewDepth;
mat4 jointMatrix(float index) {
    int x = int(index) * 4;
    return mat4(
        texelFetch(u_JointTexture, ivec2(x, 0), 0),
        texelFetch(u_JointTexture, ivec2(x + 1, 0), 0),
        texelFetch(u_JointTexture, ivec2(x + 2, 0), 0),
        texelFetch(u_JointTexture, ivec2(x + 3, 0), 0));
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
    vec4 view = u_View * world;
    v_WorldPos = world.xyz;
    v_Normal = normalize(transpose(inverse(mat3(u_Model))) * normal);
    v_Uv = a_Uv;
    v_Color = a_Color;
    v_ViewDepth = -view.z;
    gl_Position = u_Projection * view;
}
"""

    const val PBR_FS = """#version 300 es
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
uniform sampler2D u_DepthTexture;
uniform mat3 u_DepthTransform;
uniform vec2 u_Viewport;
in vec3 v_WorldPos;
in vec3 v_Normal;
in vec2 v_Uv;
in vec4 v_Color;
in float v_ViewDepth;
out vec4 o_Color;

vec3 toLinear(vec3 c) { return pow(c, vec3(2.2)); }

vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

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
    if ((u_Flags & 1) != 0) {
        texel = texture(u_BaseTexture, uv);
    }
    float alpha = base.a * texel.a * u_Opacity;
    if (u_AlphaMode == 1) {
        if (alpha < u_AlphaCutoff) discard;
        alpha = u_Opacity;
    } else if (u_AlphaMode == 0) {
        alpha = u_Opacity;
    }
    if ((u_Flags & 128) != 0) {
        vec2 ndc = gl_FragCoord.xy / u_Viewport * 2.0 - 1.0;
        vec2 duv = (u_DepthTransform * vec3(ndc, 1.0)).xy;
        vec2 raw = texture(u_DepthTexture, duv).rg * 255.0;
        float real = (raw.x + raw.y * 256.0) * 0.001;
        if (real > 0.0) {
            alpha *= clamp((real - v_ViewDepth) / 0.06 + 0.5, 0.0, 1.0);
        }
        if (alpha < 0.01) discard;
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
    if ((u_Flags & 8) != 0) {
        occlusion = mix(1.0, texture(u_OcclusionTexture, uv).r, u_OcclusionStrength);
    }
    vec3 emissive = u_Emissive;
    if ((u_Flags & 16) != 0) {
        emissive *= toLinear(texture(u_EmissiveTexture, uv).rgb);
    }
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
    vec3 envSpecular = irradiance(r) * (1.0 - roughness * 0.6);
    vec3 ambient = ((1.0 - fr) * (1.0 - metallic) * albedo * irradiance(n) + fr * envSpecular) * occlusion;
    vec3 color = (direct + ambient) * u_Exposure + emissive;
    color = pow(aces(color), vec3(1.0 / 2.2));
    o_Color = vec4(color, alpha);
}
"""

    const val PLANE_VS = """#version 300 es
layout(location = 0) in vec2 a_Local;
uniform mat4 u_Model;
uniform mat4 u_ViewProjection;
out vec2 v_Local;
void main() {
    v_Local = a_Local;
    gl_Position = u_ViewProjection * u_Model * vec4(a_Local.x, 0.0, a_Local.y, 1.0);
}
"""

    const val PLANE_FS = """#version 300 es
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
        float line = 1.0 - min(min(g.x, g.y), 1.0);
        a = u_Color.a * max(line, 0.12);
    } else if (u_Style == 1) {
        vec2 c = fract(v_Local * 10.0) - 0.5;
        a = u_Color.a * (1.0 - smoothstep(0.07, 0.11, length(c)));
    } else if (u_Style == 2) {
        a = u_Color.a * 0.45;
    }
    if (a < 0.003) discard;
    o_Color = vec4(u_Color.rgb, a);
}
"""

    const val FLAT_VS = """#version 300 es
layout(location = 0) in vec3 a_Position;
uniform mat4 u_Mvp;
uniform float u_PointSize;
void main() {
    gl_Position = u_Mvp * vec4(a_Position, 1.0);
    gl_PointSize = u_PointSize;
}
"""

    const val FLAT_FS = """#version 300 es
precision mediump float;
uniform vec4 u_Color;
uniform int u_Round;
out vec4 o_Color;
void main() {
    if (u_Round == 1) {
        vec2 c = gl_PointCoord - 0.5;
        if (dot(c, c) > 0.25) discard;
    }
    o_Color = u_Color;
}
"""

    const val QUAD_VS = """#version 300 es
layout(location = 0) in vec2 a_Local;
uniform mat4 u_Mvp;
out vec2 v_Uv;
void main() {
    v_Uv = a_Local;
    gl_Position = u_Mvp * vec4(a_Local.x, 0.0, a_Local.y, 1.0);
}
"""

    const val QUAD_FS = """#version 300 es
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
        a = u_Color.a * (smoothstep(0.72, 0.78, r) - smoothstep(0.9, 0.96, r));
        a += u_Color.a * 0.6 * (1.0 - smoothstep(0.05, 0.09, r));
    }
    if (a < 0.003) discard;
    o_Color = vec4(u_Color.rgb, a);
}
"""

    const val VIDEO_VS = """#version 300 es
layout(location = 0) in vec3 a_Position;
layout(location = 2) in vec2 a_Uv;
uniform mat4 u_Mvp;
uniform mat4 u_TexMatrix;
out vec2 v_Uv;
void main() {
    v_Uv = (u_TexMatrix * vec4(a_Uv.x, 1.0 - a_Uv.y, 0.0, 1.0)).xy;
    gl_Position = u_Mvp * vec4(a_Position, 1.0);
}
"""

    const val VIDEO_FS = """#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump float;
uniform samplerExternalOES u_Texture;
uniform float u_Opacity;
in vec2 v_Uv;
out vec4 o_Color;
void main() {
    o_Color = vec4(texture(u_Texture, v_Uv).rgb, u_Opacity);
}
"""
}

internal class UGpuMesh(
    data: UMeshData,
) {
    val vao: Int
    private val vbo: Int
    private val ibo: Int
    val count: Int = data.indices.size
    val min: FloatArray = data.min
    val max: FloatArray = data.max

    init {
        val ids = IntArray(1)
        GLES30.glGenVertexArrays(1, ids, 0)
        vao = ids[0]
        GLES30.glBindVertexArray(vao)
        GLES30.glGenBuffers(1, ids, 0)
        vbo = ids[0]
        GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER, vbo)
        val vertices = ByteBuffer.allocateDirect(data.vertices.size * 4).order(ByteOrder.nativeOrder()).asFloatBuffer().put(data.vertices)
        vertices.position(0)
        GLES30.glBufferData(GLES30.GL_ARRAY_BUFFER, data.vertices.size * 4, vertices, GLES30.GL_STATIC_DRAW)
        val layout = intArrayOf(3, 3, 2, 4, 4, 4)
        var offset = 0
        for (i in layout.indices) {
            GLES30.glEnableVertexAttribArray(i)
            GLES30.glVertexAttribPointer(i, layout[i], GLES30.GL_FLOAT, false, STRIDE_BYTES, offset)
            offset += layout[i] * 4
        }
        GLES30.glGenBuffers(1, ids, 0)
        ibo = ids[0]
        GLES30.glBindBuffer(GLES30.GL_ELEMENT_ARRAY_BUFFER, ibo)
        val indices = ByteBuffer.allocateDirect(data.indices.size * 4).order(ByteOrder.nativeOrder()).asIntBuffer().put(data.indices)
        indices.position(0)
        GLES30.glBufferData(GLES30.GL_ELEMENT_ARRAY_BUFFER, data.indices.size * 4, indices, GLES30.GL_STATIC_DRAW)
        GLES30.glBindVertexArray(0)
    }

    fun draw() {
        GLES30.glBindVertexArray(vao)
        GLES30.glDrawElements(GLES30.GL_TRIANGLES, count, GLES30.GL_UNSIGNED_INT, 0)
        GLES30.glBindVertexArray(0)
    }

    fun release() {
        GLES30.glDeleteVertexArrays(1, intArrayOf(vao), 0)
        GLES30.glDeleteBuffers(2, intArrayOf(vbo, ibo), 0)
    }
}

internal object UArPrimitives {
    private fun mesh(
        positions: List<Float>,
        normals: List<Float>,
        uvs: List<Float>,
        indices: List<Int>,
    ): UMeshData = UMeshData.build(positions.toFloatArray(), normals.toFloatArray(), uvs.toFloatArray(), null, null, null, 4, indices.toIntArray())

    fun box(
        w: Float,
        h: Float,
        d: Float,
    ): UMeshData {
        val x = w / 2
        val y = h / 2
        val z = d / 2
        val faces =
            listOf(
                floatArrayOf(0f, 0f, 1f) to listOf(floatArrayOf(-x, y, z), floatArrayOf(x, y, z), floatArrayOf(x, -y, z), floatArrayOf(-x, -y, z)),
                floatArrayOf(0f, 0f, -1f) to listOf(floatArrayOf(x, y, -z), floatArrayOf(-x, y, -z), floatArrayOf(-x, -y, -z), floatArrayOf(x, -y, -z)),
                floatArrayOf(1f, 0f, 0f) to listOf(floatArrayOf(x, y, z), floatArrayOf(x, y, -z), floatArrayOf(x, -y, -z), floatArrayOf(x, -y, z)),
                floatArrayOf(-1f, 0f, 0f) to listOf(floatArrayOf(-x, y, -z), floatArrayOf(-x, y, z), floatArrayOf(-x, -y, z), floatArrayOf(-x, -y, -z)),
                floatArrayOf(0f, 1f, 0f) to listOf(floatArrayOf(-x, y, -z), floatArrayOf(x, y, -z), floatArrayOf(x, y, z), floatArrayOf(-x, y, z)),
                floatArrayOf(0f, -1f, 0f) to listOf(floatArrayOf(-x, -y, z), floatArrayOf(x, -y, z), floatArrayOf(x, -y, -z), floatArrayOf(-x, -y, -z)),
            )
        val positions = ArrayList<Float>()
        val normals = ArrayList<Float>()
        val uvs = ArrayList<Float>()
        val indices = ArrayList<Int>()
        val corners = listOf(0f to 0f, 1f to 0f, 1f to 1f, 0f to 1f)
        for ((normal, quad) in faces) {
            val start = positions.size / 3
            for (i in 0 until 4) {
                positions.addAll(quad[i].toList())
                normals.addAll(normal.toList())
                uvs.add(corners[i].first)
                uvs.add(corners[i].second)
            }
            indices.addAll(listOf(start, start + 2, start + 1, start, start + 3, start + 2))
        }
        return mesh(positions, normals, uvs, indices)
    }

    fun sphere(
        radius: Float,
        segments: Int = 32,
        rings: Int = 20,
    ): UMeshData {
        val positions = ArrayList<Float>()
        val normals = ArrayList<Float>()
        val uvs = ArrayList<Float>()
        val indices = ArrayList<Int>()
        for (r in 0..rings) {
            val v = r.toFloat() / rings
            val phi = v * PI.toFloat()
            for (s in 0..segments) {
                val u = s.toFloat() / segments
                val theta = u * 2 * PI.toFloat()
                val nx = sin(phi) * sin(theta)
                val ny = cos(phi)
                val nz = sin(phi) * cos(theta)
                positions.addAll(listOf(nx * radius, ny * radius, nz * radius))
                normals.addAll(listOf(nx, ny, nz))
                uvs.addAll(listOf(u, v))
            }
        }
        for (r in 0 until rings) {
            for (s in 0 until segments) {
                val a = r * (segments + 1) + s
                val b = a + segments + 1
                indices.addAll(listOf(a, b, a + 1, b, b + 1, a + 1))
            }
        }
        return mesh(positions, normals, uvs, indices)
    }

    fun cylinder(
        radius: Float,
        height: Float,
        cone: Boolean,
        segments: Int = 32,
    ): UMeshData {
        val positions = ArrayList<Float>()
        val normals = ArrayList<Float>()
        val uvs = ArrayList<Float>()
        val indices = ArrayList<Int>()
        val half = height / 2
        val top = if (cone) 0f else radius
        val slope = (radius - top) / height
        for (s in 0..segments) {
            val u = s.toFloat() / segments
            val theta = u * 2 * PI.toFloat()
            val x = sin(theta)
            val z = cos(theta)
            val l = sqrt(1 + slope * slope)
            positions.addAll(listOf(x * top, half, z * top))
            normals.addAll(listOf(x / l, slope / l, z / l))
            uvs.addAll(listOf(u, 0f))
            positions.addAll(listOf(x * radius, -half, z * radius))
            normals.addAll(listOf(x / l, slope / l, z / l))
            uvs.addAll(listOf(u, 1f))
        }
        for (s in 0 until segments) {
            val a = s * 2
            indices.addAll(listOf(a, a + 1, a + 2, a + 1, a + 3, a + 2))
        }
        val caps = if (cone) listOf(-half) else listOf(half, -half)
        for (y in caps) {
            val center = positions.size / 3
            val ny = if (y > 0) 1f else -1f
            val r = if (y > 0) top else radius
            positions.addAll(listOf(0f, y, 0f))
            normals.addAll(listOf(0f, ny, 0f))
            uvs.addAll(listOf(0.5f, 0.5f))
            for (s in 0..segments) {
                val theta = s.toFloat() / segments * 2 * PI.toFloat()
                positions.addAll(listOf(sin(theta) * r, y, cos(theta) * r))
                normals.addAll(listOf(0f, ny, 0f))
                uvs.addAll(listOf(0.5f + sin(theta) / 2, 0.5f + cos(theta) / 2))
            }
            for (s in 0 until segments) {
                if (ny > 0) indices.addAll(listOf(center, center + 1 + s, center + 2 + s)) else indices.addAll(listOf(center, center + 2 + s, center + 1 + s))
            }
        }
        return mesh(positions, normals, uvs, indices)
    }

    /** A quad in the XY plane facing +Z, uv (0,0) at the top-left. */
    fun quad(
        w: Float,
        h: Float,
    ): UMeshData {
        val x = w / 2
        val y = h / 2
        return mesh(
            listOf(-x, y, 0f, x, y, 0f, x, -y, 0f, -x, -y, 0f),
            listOf(0f, 0f, 1f, 0f, 0f, 1f, 0f, 0f, 1f, 0f, 0f, 1f),
            listOf(0f, 0f, 1f, 0f, 1f, 1f, 0f, 1f),
            listOf(0, 2, 1, 0, 3, 2),
        )
    }
}

internal class UMaterial {
    var baseColor = floatArrayOf(1f, 1f, 1f, 1f)
    var metallic = 0f
    var roughness = 0.6f
    var emissive = floatArrayOf(0f, 0f, 0f)
    var baseTexture = 0
    var metallicRoughnessTexture = 0
    var normalTexture = 0
    var occlusionTexture = 0
    var emissiveTexture = 0
    var normalScale = 1f
    var occlusionStrength = 1f
    var alphaMode = 0
    var alphaCutoff = 0.5f
    var doubleSided = false
    var unlit = false
    var uvTransform: FloatArray? = null
    var opacity = 1f
    var occluder = false
    var renderOnTop = false
    var ownsTextures = false

    val isBlended: Boolean get() = alphaMode == 2 || opacity < 0.999f

    fun applyDart(map: Map<*, *>?) {
        if (map == null) return
        baseColor = UArMath.linear(UArMath.argb(map["color"], 0xFFFFFFFFL))
        metallic = (map["metallic"] as? Number)?.toFloat() ?: 0f
        roughness = (map["roughness"] as? Number)?.toFloat() ?: 0.6f
        opacity = (map["opacity"] as? Number)?.toFloat() ?: 1f
        emissive = (map["emissive"] as? Number)?.let { UArMath.linear(UArMath.argb(it, 0L)).copyOf(3) } ?: floatArrayOf(0f, 0f, 0f)
        unlit = map["unlit"] == true
        doubleSided = map["doubleSided"] == true
        occluder = map["occluder"] == true
        renderOnTop = map["renderOnTop"] == true
        if (unlit) baseColor = UArMath.argb(map["color"], 0xFFFFFFFFL)
        alphaMode = if (baseTexture != 0 || opacity < 1f || baseColor[3] < 1f) 2 else 0
    }

    fun release() {
        if (!ownsTextures) return
        for (id in intArrayOf(baseTexture, metallicRoughnessTexture, normalTexture, occlusionTexture, emissiveTexture)) UArTextures.delete(id)
    }

    companion object {
        fun fromGltf(
            data: UMaterialData,
            textures: IntArray,
        ): UMaterial =
            UMaterial().apply {
                baseColor = data.baseColor
                metallic = data.metallic
                roughness = data.roughness
                emissive = data.emissive
                baseTexture = textures.getOrElse(data.baseTexture) { 0 }
                metallicRoughnessTexture = textures.getOrElse(data.metallicRoughnessTexture) { 0 }
                normalTexture = textures.getOrElse(data.normalTexture) { 0 }
                occlusionTexture = textures.getOrElse(data.occlusionTexture) { 0 }
                emissiveTexture = textures.getOrElse(data.emissiveTexture) { 0 }
                normalScale = data.normalScale
                occlusionStrength = data.occlusionStrength
                alphaMode = data.alphaMode
                alphaCutoff = data.alphaCutoff
                doubleSided = data.doubleSided
                unlit = data.unlit
                uvTransform = data.uvTransform
            }
    }
}

/** Lighting and occlusion state shared by every draw of one frame. */
internal class UArEnvironment {
    var lightDirection = floatArrayOf(0.35f, 0.85f, 0.4f)
    var lightColor = floatArrayOf(2.2f, 2.2f, 2.1f)
    var sh: FloatArray? = null
    var sky = floatArrayOf(0.55f, 0.58f, 0.62f)
    var ground = floatArrayOf(0.25f, 0.24f, 0.23f)
    var exposure = 1f
    var cameraPosition = floatArrayOf(0f, 0f, 0f)
    var depthTexture = 0
    var depthTransform = floatArrayOf(1f, 0f, 0f, 0f, 1f, 0f, 0f, 0f, 1f)
    var useDepth = false
    var viewportWidth = 1f
    var viewportHeight = 1f
    var view = UArMath.identity()
    var projection = UArMath.identity()
    var viewProjection = UArMath.identity()
}

/** GPU copy of a parsed glTF file. Shared by every instance of the same source. */
internal class UModel(
    val data: UGltfData,
) {
    val textures: IntArray
    val materials: List<UMaterial>
    val meshes: List<List<Pair<UGpuMesh, Int>>>
    var references = 0

    init {
        textures =
            IntArray(data.textures.size) { i ->
                val texture = data.textures[i]
                val bitmap = data.images.getOrNull(texture.image)
                if (bitmap == null) 0 else UArTextures.upload(bitmap, texture.wrapS, texture.wrapT, texture.minFilter, texture.magFilter)
            }
        data.images.forEach { it?.recycle() }
        materials = data.materials.map { UMaterial.fromGltf(it, textures) }
        meshes = data.meshes.map { primitives -> primitives.map { Pair(UGpuMesh(it.mesh), it.material) } }
    }

    fun release() {
        textures.forEach { UArTextures.delete(it) }
        meshes.forEach { list -> list.forEach { it.first.release() } }
    }
}

/** Per-node pose, animation and skinning state for one use of a [UModel]. */
internal class UModelInstance(
    val model: UModel,
) {
    private val data = model.data
    private val translations = Array(data.nodes.size) { data.nodes[it].translation.copyOf() }
    private val rotations = Array(data.nodes.size) { data.nodes[it].rotation.copyOf() }
    private val scales = Array(data.nodes.size) { data.nodes[it].scale.copyOf() }
    val globals = Array(data.nodes.size) { UArMath.identity() }
    private val jointTextures = IntArray(data.skins.size)
    private val jointBuffers = data.skins.map { ByteBuffer.allocateDirect(it.joints.size * 64).order(ByteOrder.nativeOrder()).asFloatBuffer() }
    private val defaultMaterial = UMaterial().apply { roughness = 0.8f }

    var clips: List<Int> = emptyList()
    var time = 0f
    var loop = true
    var speed = 1f
    var playing = false
    var onFinished: (() -> Unit)? = null
    val min = floatArrayOf(0f, 0f, 0f)
    val max = floatArrayOf(0f, 0f, 0f)

    val animationNames: List<String> get() = data.animations.map { it.name }

    init {
        updateGlobals()
        computeBounds()
        if (data.skins.isNotEmpty()) {
            val ids = IntArray(data.skins.size)
            GLES30.glGenTextures(ids.size, ids, 0)
            for (i in ids.indices) {
                jointTextures[i] = ids[i]
                GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, ids[i])
                GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_MIN_FILTER, GLES30.GL_NEAREST)
                GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_MAG_FILTER, GLES30.GL_NEAREST)
                GLES30.glTexImage2D(GLES30.GL_TEXTURE_2D, 0, GLES30.GL_RGBA32F, data.skins[i].joints.size * 4, 1, 0, GLES30.GL_RGBA, GLES30.GL_FLOAT, null)
            }
        }
    }

    fun play(
        name: String?,
        index: Int,
        loop: Boolean,
        speed: Float,
    ) {
        clips =
            when {
                data.animations.isEmpty() -> emptyList()
                name == "*" -> data.animations.indices.toList()
                name != null -> listOfNotNull(data.animations.indexOfFirst { it.name == name }.takeIf { it >= 0 })
                else -> listOf(index.coerceIn(0, data.animations.size - 1))
            }
        this.loop = loop
        this.speed = speed
        time = 0f
        playing = clips.isNotEmpty()
    }

    fun stop() {
        playing = false
    }

    fun update(delta: Float) {
        if (playing && clips.isNotEmpty()) {
            time += delta * speed
            val duration = clips.maxOf { data.animations[it].duration }
            if (duration > 0 && time > duration) {
                if (loop) {
                    time %= duration
                } else {
                    time = duration
                    playing = false
                    onFinished?.invoke()
                }
            }
            for (clip in clips) sample(data.animations[clip], time)
        }
        updateGlobals()
    }

    private fun sample(
        animation: UGltfAnimation,
        t: Float,
    ) {
        for (channel in animation.channels) {
            val times = channel.times
            if (times.isEmpty() || channel.node !in translations.indices) continue
            val c = channel.components
            val cubic = channel.interpolation == "CUBICSPLINE"
            val stride = if (cubic) c * 3 else c
            var k = 0
            if (t >= times.last()) {
                k = times.size - 1
            } else if (t > times[0]) {
                var lo = 0
                var hi = times.size - 1
                while (hi - lo > 1) {
                    val mid = (lo + hi) / 2
                    if (times[mid] <= t) lo = mid else hi = mid
                }
                k = lo
            }
            val next = min(k + 1, times.size - 1)
            val span = times[next] - times[k]
            val f = if (span <= 0f || t <= times[k]) 0f else ((t - times[k]) / span).coerceIn(0f, 1f)
            val valueOffset = if (cubic) c else 0
            val a = FloatArray(c) { channel.values.getOrElse(k * stride + valueOffset + it) { 0f } }
            val b = FloatArray(c) { channel.values.getOrElse(next * stride + valueOffset + it) { 0f } }
            val result =
                when {
                    channel.interpolation == "STEP" || k == next -> a
                    cubic -> {
                        val outTangent = FloatArray(c) { channel.values.getOrElse(k * stride + 2 * c + it) { 0f } }
                        val inTangent = FloatArray(c) { channel.values.getOrElse(next * stride + it) { 0f } }
                        val f2 = f * f
                        val f3 = f2 * f
                        FloatArray(c) {
                            (2 * f3 - 3 * f2 + 1) * a[it] + (f3 - 2 * f2 + f) * span * outTangent[it] + (-2 * f3 + 3 * f2) * b[it] + (f3 - f2) * span * inTangent[it]
                        }.let { if (c == 4) UArMath.quatNormalize(it) else it }
                    }
                    c == 4 -> UArMath.quatSlerp(a, b, f)
                    else -> FloatArray(c) { a[it] + (b[it] - a[it]) * f }
                }
            when (channel.path) {
                "translation" -> translations[channel.node] = result
                "rotation" -> rotations[channel.node] = result
                "scale" -> scales[channel.node] = result
            }
        }
    }

    private fun updateGlobals() {
        val parentMatrix = UArMath.identity()
        for (root in data.roots) visit(root, parentMatrix)
    }

    private fun visit(
        index: Int,
        parent: FloatArray,
    ) {
        if (index !in data.nodes.indices) return
        val node = data.nodes[index]
        val local = node.matrix ?: UArMath.compose(translations[index], rotations[index], scales[index])
        Matrix.multiplyMM(globals[index], 0, parent, 0, local, 0)
        for (child in node.children) visit(child, globals[index])
    }

    private fun computeBounds() {
        val lo = floatArrayOf(Float.MAX_VALUE, Float.MAX_VALUE, Float.MAX_VALUE)
        val hi = floatArrayOf(-Float.MAX_VALUE, -Float.MAX_VALUE, -Float.MAX_VALUE)
        var any = false
        for (i in data.nodes.indices) {
            val mesh = data.nodes[i].mesh
            if (mesh < 0 || mesh >= model.meshes.size) continue
            for ((gpu, _) in model.meshes[mesh]) {
                val (bMin, bMax) = UArMath.transformAabb(globals[i], gpu.min, gpu.max)
                for (k in 0 until 3) {
                    lo[k] = min(lo[k], bMin[k])
                    hi[k] = max(hi[k], bMax[k])
                }
                any = true
            }
        }
        if (any) {
            lo.copyInto(min)
            hi.copyInto(max)
        }
    }

    fun draw(
        renderer: UArRenderer,
        modelMatrix: FloatArray,
        env: UArEnvironment,
        pass: Int,
        overrideOpacity: Float,
    ) {
        for (i in data.nodes.indices) {
            val node = data.nodes[i]
            if (node.mesh < 0 || node.mesh >= model.meshes.size) continue
            val world = UArMath.multiply(modelMatrix, globals[i])
            var jointTexture = 0
            if (node.skin >= 0 && node.skin < data.skins.size) {
                jointTexture = uploadJoints(node.skin, i)
            }
            for ((mesh, materialIndex) in model.meshes[node.mesh]) {
                val material = model.materials.getOrNull(materialIndex) ?: defaultMaterial
                val blended = material.alphaMode == 2 || overrideOpacity < 0.999f || env.useDepth
                if (pass == 0 && blended) continue
                if (pass == 1 && !blended) continue
                renderer.drawMesh(mesh, material, world, env, jointTexture, overrideOpacity)
            }
        }
    }

    private fun uploadJoints(
        skinIndex: Int,
        meshNode: Int,
    ): Int {
        val skin = data.skins[skinIndex]
        val inverseMesh = UArMath.invert(globals[meshNode])
        val buffer = jointBuffers[skinIndex]
        buffer.position(0)
        val temp = FloatArray(16)
        val jointMatrix = FloatArray(16)
        for (j in skin.joints.indices) {
            val joint = skin.joints[j]
            Matrix.multiplyMM(temp, 0, globals.getOrElse(joint) { UArMath.identity() }, 0, skin.inverseBind, j * 16)
            Matrix.multiplyMM(jointMatrix, 0, inverseMesh, 0, temp, 0)
            buffer.put(jointMatrix)
        }
        buffer.position(0)
        GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, jointTextures[skinIndex])
        GLES30.glTexSubImage2D(GLES30.GL_TEXTURE_2D, 0, 0, 0, skin.joints.size * 4, 1, GLES30.GL_RGBA, GLES30.GL_FLOAT, buffer)
        return jointTextures[skinIndex]
    }

    fun release() {
        if (jointTextures.isNotEmpty()) GLES30.glDeleteTextures(jointTextures.size, jointTextures, 0)
    }
}

/** A video decoded straight into an external OES texture. */
internal class UArVideo(
    context: Context,
    file: File,
    options: Map<*, *>?,
    onEnded: () -> Unit,
) : SurfaceTexture.OnFrameAvailableListener {
    val texture: Int = UArTextures.external()
    private val surfaceTexture = SurfaceTexture(texture)
    private val surface = Surface(surfaceTexture)
    private val player = MediaPlayer()
    val matrix = UArMath.identity()

    @Volatile private var frameAvailable = false
    var width = 16
    var height = 9

    init {
        surfaceTexture.setOnFrameAvailableListener(this)
        player.setSurface(surface)
        player.setDataSource(context, Uri.fromFile(file))
        player.isLooping = options?.get("loop") != false
        val volume = if (options?.get("muted") == false) (options["volume"] as? Number)?.toFloat() ?: 1f else 0f
        player.setVolume(volume, volume)
        player.setOnVideoSizeChangedListener { _, w, h ->
            if (w > 0 && h > 0) {
                width = w
                height = h
            }
        }
        player.setOnCompletionListener { onEnded() }
        player.setOnPreparedListener { if (options?.get("autoplay") != false) it.start() }
        player.prepareAsync()
    }

    override fun onFrameAvailable(texture: SurfaceTexture?) {
        frameAvailable = true
    }

    fun update() {
        if (!frameAvailable) return
        frameAvailable = false
        runCatching {
            surfaceTexture.updateTexImage()
            surfaceTexture.getTransformMatrix(matrix)
        }
    }

    fun control(
        play: Boolean?,
        seekMs: Int?,
        volume: Float?,
    ) {
        runCatching {
            if (seekMs != null) player.seekTo(seekMs)
            if (volume != null) player.setVolume(volume, volume)
            if (play == true) player.start()
            if (play == false) player.pause()
        }
    }

    fun release() {
        runCatching { player.stop() }
        runCatching { player.release() }
        runCatching { surface.release() }
        runCatching { surfaceTexture.release() }
        UArTextures.delete(texture)
    }
}

/** Programs, shared buffers and the draw calls used by a session. */
internal class UArRenderer {
    lateinit var pbr: UProgram
    lateinit var background: UProgram
    lateinit var plane: UProgram
    lateinit var flat: UProgram
    lateinit var quad: UProgram
    lateinit var video: UProgram
    private var white = 0
    private var dummyDepth = 0
    private var backgroundVao = 0
    private var backgroundVbo = 0
    private var dynamicVao = 0
    private var dynamicVbo = 0
    private var dynamicIbo = 0
    private var quadVao = 0
    private var quadVbo = 0
    private val identity3 = floatArrayOf(1f, 0f, 0f, 0f, 1f, 0f, 0f, 0f, 1f)

    fun init() {
        pbr = UProgram(UArShaders.PBR_VS, UArShaders.PBR_FS)
        background = UProgram(UArShaders.BACKGROUND_VS, UArShaders.BACKGROUND_FS)
        plane = UProgram(UArShaders.PLANE_VS, UArShaders.PLANE_FS)
        flat = UProgram(UArShaders.FLAT_VS, UArShaders.FLAT_FS)
        quad = UProgram(UArShaders.QUAD_VS, UArShaders.QUAD_FS)
        video = UProgram(UArShaders.VIDEO_VS, UArShaders.VIDEO_FS)
        white = UArTextures.solid(255, 255, 255, 255)
        dummyDepth = UArTextures.solid(0, 0, 0, 0)
        val ids = IntArray(3)
        GLES30.glGenVertexArrays(3, ids, 0)
        backgroundVao = ids[0]
        dynamicVao = ids[1]
        quadVao = ids[2]
        val buffers = IntArray(4)
        GLES30.glGenBuffers(4, buffers, 0)
        backgroundVbo = buffers[0]
        dynamicVbo = buffers[1]
        dynamicIbo = buffers[2]
        quadVbo = buffers[3]

        GLES30.glBindVertexArray(backgroundVao)
        GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER, backgroundVbo)
        GLES30.glBufferData(GLES30.GL_ARRAY_BUFFER, 16 * 4, null, GLES30.GL_DYNAMIC_DRAW)
        GLES30.glEnableVertexAttribArray(0)
        GLES30.glVertexAttribPointer(0, 2, GLES30.GL_FLOAT, false, 16, 0)
        GLES30.glEnableVertexAttribArray(1)
        GLES30.glVertexAttribPointer(1, 2, GLES30.GL_FLOAT, false, 16, 8)

        GLES30.glBindVertexArray(quadVao)
        GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER, quadVbo)
        val quadData = floatArrayOf(-1f, -1f, 1f, -1f, -1f, 1f, 1f, 1f)
        GLES30.glBufferData(GLES30.GL_ARRAY_BUFFER, quadData.size * 4, floatBuffer(quadData), GLES30.GL_STATIC_DRAW)
        GLES30.glEnableVertexAttribArray(0)
        GLES30.glVertexAttribPointer(0, 2, GLES30.GL_FLOAT, false, 8, 0)
        GLES30.glBindVertexArray(0)
    }

    fun release() {
        for (program in listOf(pbr, background, plane, flat, quad, video)) runCatching { program.release() }
        GLES30.glDeleteVertexArrays(3, intArrayOf(backgroundVao, dynamicVao, quadVao), 0)
        GLES30.glDeleteBuffers(4, intArrayOf(backgroundVbo, dynamicVbo, dynamicIbo, quadVbo), 0)
        UArTextures.delete(white)
        UArTextures.delete(dummyDepth)
    }

    private fun floatBuffer(data: FloatArray): FloatBuffer {
        val buffer = ByteBuffer.allocateDirect(data.size * 4).order(ByteOrder.nativeOrder()).asFloatBuffer()
        buffer.put(data)
        buffer.position(0)
        return buffer
    }

    /** [uvs] holds the camera texture coordinate of each NDC corner (-1,-1), (1,-1), (-1,1), (1,1). */
    fun drawBackground(
        texture: Int,
        uvs: FloatArray,
    ) {
        val data =
            floatArrayOf(
                -1f, -1f, uvs[0], uvs[1],
                1f, -1f, uvs[2], uvs[3],
                -1f, 1f, uvs[4], uvs[5],
                1f, 1f, uvs[6], uvs[7],
            )
        GLES30.glDisable(GLES30.GL_DEPTH_TEST)
        GLES30.glDepthMask(false)
        background.use()
        background.texture("u_Texture", 0, texture, GLES11Ext.GL_TEXTURE_EXTERNAL_OES)
        GLES30.glBindVertexArray(backgroundVao)
        GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER, backgroundVbo)
        GLES30.glBufferSubData(GLES30.GL_ARRAY_BUFFER, 0, data.size * 4, floatBuffer(data))
        GLES30.glDrawArrays(GLES30.GL_TRIANGLE_STRIP, 0, 4)
        GLES30.glBindVertexArray(0)
        GLES30.glDepthMask(true)
        GLES30.glEnable(GLES30.GL_DEPTH_TEST)
    }

    fun drawMesh(
        mesh: UGpuMesh,
        material: UMaterial,
        model: FloatArray,
        env: UArEnvironment,
        jointTexture: Int,
        opacity: Float,
    ) {
        pbr.use()
        pbr.mat4("u_Model", model)
        pbr.mat4("u_View", env.view)
        pbr.mat4("u_Projection", env.projection)
        pbr.int("u_Skinned", if (jointTexture != 0) 1 else 0)
        pbr.texture("u_JointTexture", 6, if (jointTexture != 0) jointTexture else white)
        pbr.vec4("u_BaseColor", material.baseColor)
        pbr.float("u_Metallic", material.metallic)
        pbr.float("u_Roughness", material.roughness)
        pbr.vec3("u_Emissive", material.emissive)
        var flags = 0
        if (material.baseTexture != 0) flags = flags or 1
        if (material.metallicRoughnessTexture != 0) flags = flags or 2
        if (material.normalTexture != 0) flags = flags or 4
        if (material.occlusionTexture != 0) flags = flags or 8
        if (material.emissiveTexture != 0) flags = flags or 16
        if (material.unlit) flags = flags or 32
        if (env.useDepth && !material.renderOnTop) flags = flags or 128
        pbr.int("u_Flags", flags)
        pbr.texture("u_BaseTexture", 0, if (material.baseTexture != 0) material.baseTexture else white)
        pbr.texture("u_MrTexture", 1, if (material.metallicRoughnessTexture != 0) material.metallicRoughnessTexture else white)
        pbr.texture("u_NormalTexture", 2, if (material.normalTexture != 0) material.normalTexture else white)
        pbr.texture("u_OcclusionTexture", 3, if (material.occlusionTexture != 0) material.occlusionTexture else white)
        pbr.texture("u_EmissiveTexture", 4, if (material.emissiveTexture != 0) material.emissiveTexture else white)
        pbr.texture("u_DepthTexture", 5, if (env.useDepth && env.depthTexture != 0) env.depthTexture else dummyDepth)
        pbr.mat3("u_DepthTransform", env.depthTransform)
        pbr.vec2("u_Viewport", env.viewportWidth, env.viewportHeight)
        pbr.float("u_NormalScale", material.normalScale)
        pbr.float("u_OcclusionStrength", material.occlusionStrength)
        pbr.int("u_AlphaMode", material.alphaMode)
        pbr.float("u_AlphaCutoff", material.alphaCutoff)
        pbr.float("u_Opacity", material.opacity * opacity)
        pbr.mat3("u_UvTransform", material.uvTransform ?: identity3)
        pbr.vec3("u_CameraPos", env.cameraPosition)
        pbr.vec3("u_LightDir", env.lightDirection)
        pbr.vec3("u_LightColor", env.lightColor)
        val sh = env.sh
        pbr.int("u_UseSh", if (sh != null) 1 else 0)
        if (sh != null) GLES30.glUniform3fv(pbr.loc("u_Sh"), 9, sh, 0)
        pbr.vec3("u_Sky", env.sky)
        pbr.vec3("u_Ground", env.ground)
        pbr.float("u_Exposure", env.exposure)

        if (material.doubleSided) GLES30.glDisable(GLES30.GL_CULL_FACE) else GLES30.glEnable(GLES30.GL_CULL_FACE)
        if (material.renderOnTop) GLES30.glDisable(GLES30.GL_DEPTH_TEST)
        if (material.occluder) GLES30.glColorMask(false, false, false, false)
        mesh.draw()
        if (material.occluder) GLES30.glColorMask(true, true, true, true)
        if (material.renderOnTop) GLES30.glEnable(GLES30.GL_DEPTH_TEST)
        GLES30.glDisable(GLES30.GL_CULL_FACE)
    }

    fun drawVideo(
        mesh: UGpuMesh,
        video: UArVideo,
        mvp: FloatArray,
        opacity: Float,
    ) {
        this.video.use()
        this.video.mat4("u_Mvp", mvp)
        this.video.mat4("u_TexMatrix", video.matrix)
        this.video.float("u_Opacity", opacity)
        this.video.texture("u_Texture", 0, video.texture, GLES11Ext.GL_TEXTURE_EXTERNAL_OES)
        mesh.draw()
    }

    /** Draws a polygon given as local X/Z pairs, fan-triangulated, in the given style. */
    fun drawPlane(
        polygon: FloatArray,
        model: FloatArray,
        viewProjection: FloatArray,
        color: FloatArray,
        style: Int,
    ) {
        val count = polygon.size / 2
        if (count < 3) return
        plane.use()
        plane.mat4("u_Model", model)
        plane.mat4("u_ViewProjection", viewProjection)
        plane.vec4("u_Color", color)
        GLES30.glBindVertexArray(dynamicVao)
        GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER, dynamicVbo)
        GLES30.glBufferData(GLES30.GL_ARRAY_BUFFER, polygon.size * 4, floatBuffer(polygon), GLES30.GL_STREAM_DRAW)
        GLES30.glEnableVertexAttribArray(0)
        GLES30.glVertexAttribPointer(0, 2, GLES30.GL_FLOAT, false, 8, 0)
        GLES30.glDepthMask(false)
        if (style == 3) {
            plane.int("u_Style", 3)
            GLES30.glLineWidth(3f)
            GLES30.glDrawArrays(GLES30.GL_LINE_LOOP, 0, count)
        } else {
            plane.int("u_Style", style)
            GLES30.glDrawArrays(GLES30.GL_TRIANGLE_FAN, 0, count)
        }
        GLES30.glDepthMask(true)
        GLES30.glBindVertexArray(0)
    }

    fun drawFlat(
        vertices: FloatArray,
        indices: ShortArray?,
        mode: Int,
        mvp: FloatArray,
        color: FloatArray,
        pointSize: Float = 8f,
        round: Boolean = false,
    ) {
        if (vertices.isEmpty()) return
        flat.use()
        flat.mat4("u_Mvp", mvp)
        flat.vec4("u_Color", color)
        flat.float("u_PointSize", pointSize)
        flat.int("u_Round", if (round) 1 else 0)
        GLES30.glBindVertexArray(dynamicVao)
        GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER, dynamicVbo)
        GLES30.glBufferData(GLES30.GL_ARRAY_BUFFER, vertices.size * 4, floatBuffer(vertices), GLES30.GL_STREAM_DRAW)
        GLES30.glEnableVertexAttribArray(0)
        GLES30.glVertexAttribPointer(0, 3, GLES30.GL_FLOAT, false, 12, 0)
        if (indices != null) {
            val buffer = ByteBuffer.allocateDirect(indices.size * 2).order(ByteOrder.nativeOrder()).asShortBuffer().put(indices)
            buffer.position(0)
            GLES30.glBindBuffer(GLES30.GL_ELEMENT_ARRAY_BUFFER, dynamicIbo)
            GLES30.glBufferData(GLES30.GL_ELEMENT_ARRAY_BUFFER, indices.size * 2, buffer, GLES30.GL_STREAM_DRAW)
            GLES30.glDrawElements(mode, indices.size, GLES30.GL_UNSIGNED_SHORT, 0)
        } else {
            GLES30.glDrawArrays(mode, 0, vertices.size / 3)
        }
        GLES30.glBindVertexArray(0)
    }

    /** A flat disc in the model's X/Z plane: kind 0 soft shadow, 1 placement ring. */
    fun drawQuad(
        mvp: FloatArray,
        color: FloatArray,
        kind: Int,
    ) {
        quad.use()
        quad.mat4("u_Mvp", mvp)
        quad.vec4("u_Color", color)
        quad.int("u_Kind", kind)
        GLES30.glDepthMask(false)
        GLES30.glBindVertexArray(quadVao)
        GLES30.glDrawArrays(GLES30.GL_TRIANGLE_STRIP, 0, 4)
        GLES30.glBindVertexArray(0)
        GLES30.glDepthMask(true)
    }
}

// =============================================================================
// ARCore — only this class touches com.google.ar.core
// =============================================================================

internal class UArPlaneDraw(
    val id: String,
    val model: FloatArray,
    val polygon: FloatArray,
    val vertical: Boolean,
)

internal class UArFaceDraw(
    val vertices: FloatArray,
    val indices: ShortArray,
)

/**
 * Wraps one ARCore [Session]. Every method runs on the session's GL thread; the
 * async ARCore callbacks are bounced back to it through [post].
 */
internal class UArCoreSession(
    private val context: Context,
    private var config: Map<*, *>,
    private val cameraTexture: Int,
    private val loader: UArSourceLoader,
    private val post: (() -> Unit) -> Unit,
    private val emit: (Map<String, Any?>) -> Unit,
) {
    private val session: Session
    private var frame: Frame? = null
    private val front = config["camera"] == "front" || config["mode"] == "face"
    private val planeIds = HashMap<Plane, String>()
    private val planeById = HashMap<String, Plane>()
    private val anchors = LinkedHashMap<String, Anchor>()
    private val anchorTypes = HashMap<String, String>()
    private val anchorTrackables = HashMap<String, String>()
    private val cloudIds = HashMap<String, String>()
    private val lastAnchorPoses = HashMap<String, FloatArray>()
    private val lastAnchorStates = HashMap<String, String>()
    private val hitTrackables = LinkedHashMap<String, Trackable>()
    private val images = HashMap<String, AugmentedImage>()
    private val faceIds = HashMap<AugmentedFace, String>()
    private val pendingPlanes = LinkedHashSet<Plane>()
    private val removedPlanes = LinkedHashSet<String>()
    private var nextId = 1
    private var lastPlaneEmit = 0L
    private var lastAnchorEmit = 0L
    private var lastImageEmit = 0L
    private var lastFaceEmit = 0L
    private var depthTexture = 0
    private var depthSupported = false
    private var geospatialSupported = false
    private var semanticsSupported = false
    private var instantEnabled = false

    val view = UArMath.identity()
    val projection = UArMath.identity()
    val cameraMatrix = UArMath.identity()
    val backgroundUvs = floatArrayOf(0f, 1f, 1f, 1f, 0f, 0f, 1f, 0f)
    var backgroundChanged = true
    var tracking = "notAvailable"
    var reason = "initializing"
    var timestamp = 0L
    var fov = 60f
    var points = FloatArray(0)
    val planes = ArrayList<UArPlaneDraw>()
    val faces = ArrayList<UArFaceDraw>()
    val depthTransform = floatArrayOf(1f, 0f, 0f, 0f, 1f, 0f, 0f, 0f, 1f)
    private val depthBase = floatArrayOf(1f, 0f, 0f, 0f, 1f, 0f, 0f, 0f, 1f)
    var depthReady = false
    var lightMap: Map<String, Any?>? = null
    var geoMap: Map<String, Any?>? = null
    var semanticsMap: Map<String, Any?>? = null
    var centerHit: Map<String, Any?>? = null
    var centerHitMatrix: FloatArray? = null

    init {
        session =
            if (front) {
                Session(context, EnumSet.of(Session.Feature.FRONT_CAMERA))
            } else {
                Session(context)
            }
        session.setCameraTextureName(cameraTexture)
        if (config["highFps"] == true) {
            runCatching {
                val filter = CameraConfigFilter(session).setTargetFps(EnumSet.of(CameraConfig.TargetFps.TARGET_FPS_60))
                session.getSupportedCameraConfigs(filter).firstOrNull()?.let { session.cameraConfig = it }
            }
        }
        depthSupported = runCatching { session.isDepthModeSupported(Config.DepthMode.AUTOMATIC) }.getOrDefault(false)
        geospatialSupported = runCatching { session.isGeospatialModeSupported(Config.GeospatialMode.ENABLED) }.getOrDefault(false)
        semanticsSupported = runCatching { session.isSemanticModeSupported(Config.SemanticMode.ENABLED) }.getOrDefault(false)
        configure(config, null)
    }

    fun capabilities(): Map<String, Any?> =
        mapOf(
            "platform" to "android",
            "worldTracking" to true,
            "planeHorizontal" to true,
            "planeVertical" to true,
            "planeClassification" to false,
            "depth" to depthSupported,
            "peopleOcclusion" to false,
            "sceneReconstruction" to false,
            "lidar" to false,
            "imageTracking" to true,
            "objectTracking" to false,
            "faceTracking" to true,
            "bodyTracking" to false,
            "geospatial" to geospatialSupported,
            "gpsGeo" to true,
            "cloudAnchors" to true,
            "worldMap" to false,
            "collaboration" to false,
            "lightEstimation" to true,
            "environmentHdr" to true,
            "instantPlacement" to true,
            "semantics" to semanticsSupported,
            "recording" to true,
            "snapshot" to true,
            "roomPlan" to false,
            "objectCapture" to false,
            "textRecognition" to false,
            "barcodeDetection" to false,
            "cameraImage" to true,
            "nativeViewer" to true,
            "viewer" to true,
            "webXr" to false,
            "sensorAr" to false,
            "formats" to listOf("glb", "gltf"),
        )

    fun configure(
        map: Map<*, *>,
        imageDatabase: AugmentedImageDatabase?,
    ) {
        config = map
        val mode = map["mode"] as? String ?: "world"
        val arConfig = Config(session)
        arConfig.updateMode = Config.UpdateMode.LATEST_CAMERA_IMAGE
        arConfig.focusMode = if (map["focusMode"] == "fixed") Config.FocusMode.FIXED else Config.FocusMode.AUTO
        arConfig.planeFindingMode =
            if (front || mode == "orientation") {
                Config.PlaneFindingMode.DISABLED
            } else {
                when (map["planeDetection"]) {
                    "none" -> Config.PlaneFindingMode.DISABLED
                    "horizontal" -> Config.PlaneFindingMode.HORIZONTAL
                    "vertical" -> Config.PlaneFindingMode.VERTICAL
                    else -> Config.PlaneFindingMode.HORIZONTAL_AND_VERTICAL
                }
            }
        arConfig.lightEstimationMode =
            when (map["lightEstimation"]) {
                "disabled" -> Config.LightEstimationMode.DISABLED
                "ambient" -> Config.LightEstimationMode.AMBIENT_INTENSITY
                else -> if (front) Config.LightEstimationMode.AMBIENT_INTENSITY else Config.LightEstimationMode.ENVIRONMENTAL_HDR
            }
        arConfig.depthMode = if (!front && depthSupported && map["occlusion"] != false) Config.DepthMode.AUTOMATIC else Config.DepthMode.DISABLED
        instantEnabled = !front && map["instantPlacement"] != false
        arConfig.instantPlacementMode = if (instantEnabled) Config.InstantPlacementMode.LOCAL_Y_UP else Config.InstantPlacementMode.DISABLED
        if (front) arConfig.augmentedFaceMode = Config.AugmentedFaceMode.MESH3D
        if (!front && geospatialSupported && (mode == "geo" && map["geoMode"] != "gps")) arConfig.geospatialMode = Config.GeospatialMode.ENABLED
        if (!front && map["cloudAnchors"] == true) arConfig.cloudAnchorMode = Config.CloudAnchorMode.ENABLED
        if (!front && semanticsSupported && map["semantics"] == true) arConfig.semanticMode = Config.SemanticMode.ENABLED
        if (imageDatabase != null && !front) arConfig.augmentedImageDatabase = imageDatabase
        session.configure(arConfig)
    }

    fun buildImageDatabase(images: List<Triple<String, Bitmap, Float>>): AugmentedImageDatabase {
        val database = AugmentedImageDatabase(session)
        for ((name, bitmap, width) in images) {
            runCatching { database.addImage(name, bitmap, width) }.onFailure {
                emit(mapOf("type" to "error", "code" to "loadFailed", "message" to "Reference image '$name' was rejected: ${it.message}"))
            }
        }
        return database
    }

    fun resume() = session.resume()

    fun pause() = session.pause()

    fun close() {
        runCatching { session.pause() }
        runCatching { session.close() }
        if (depthTexture != 0) UArTextures.delete(depthTexture)
    }

    fun reset(keepAnchors: Boolean) {
        if (!keepAnchors) {
            anchors.values.forEach { runCatching { it.detach() } }
            anchors.clear()
            anchorTypes.clear()
            anchorTrackables.clear()
            lastAnchorPoses.clear()
            lastAnchorStates.clear()
        }
        planeIds.clear()
        planeById.clear()
        hitTrackables.clear()
        images.clear()
        planes.clear()
    }

    fun setDisplayGeometry(
        rotation: Int,
        width: Int,
        height: Int,
    ) = session.setDisplayGeometry(rotation, width, height)

    private fun newId(prefix: String): String = "$prefix${nextId++}"

    private fun poseList(pose: Pose): List<Double> = listOf(pose.tx(), pose.ty(), pose.tz(), pose.qx(), pose.qy(), pose.qz(), pose.qw()).map { it.toDouble() }

    private fun poseMatrix(pose: Pose): FloatArray = FloatArray(16).also { pose.toMatrix(it, 0) }

    private fun trackingName(state: TrackingState): String =
        when (state) {
            TrackingState.TRACKING -> "normal"
            TrackingState.PAUSED -> "limited"
            else -> "stopped"
        }

    private fun reasonName(reason: TrackingFailureReason): String =
        when (reason) {
            TrackingFailureReason.NONE -> "none"
            TrackingFailureReason.BAD_STATE -> "badState"
            TrackingFailureReason.INSUFFICIENT_LIGHT -> "insufficientLight"
            TrackingFailureReason.EXCESSIVE_MOTION -> "excessiveMotion"
            TrackingFailureReason.INSUFFICIENT_FEATURES -> "insufficientFeatures"
            TrackingFailureReason.CAMERA_UNAVAILABLE -> "cameraUnavailable"
            else -> "unknown"
        }

    /** Runs one ARCore update and refreshes every public field. Returns false with no new frame. */
    fun update(
        viewWidth: Int,
        viewHeight: Int,
        wantPoints: Boolean,
        wantReticle: Boolean,
    ): Boolean {
        val current = session.update()
        frame = current
        timestamp = current.timestamp
        if (current.hasDisplayGeometryChanged() || backgroundChanged) {
            val ndc = floatArrayOf(-1f, -1f, 1f, -1f, -1f, 1f, 1f, 1f)
            current.transformCoordinates2d(Coordinates2d.OPENGL_NORMALIZED_DEVICE_COORDINATES, ndc, Coordinates2d.TEXTURE_NORMALIZED, backgroundUvs)
            val depthCorners = FloatArray(6)
            current.transformCoordinates2d(Coordinates2d.OPENGL_NORMALIZED_DEVICE_COORDINATES, floatArrayOf(-1f, -1f, 1f, -1f, -1f, 1f), Coordinates2d.IMAGE_NORMALIZED, depthCorners)
            val ax0 = (depthCorners[2] - depthCorners[0]) / 2
            val ax1 = (depthCorners[3] - depthCorners[1]) / 2
            val ay0 = (depthCorners[4] - depthCorners[0]) / 2
            val ay1 = (depthCorners[5] - depthCorners[1]) / 2
            depthBase[0] = ax0
            depthBase[1] = ax1
            depthBase[2] = 0f
            depthBase[3] = ay0
            depthBase[4] = ay1
            depthBase[5] = 0f
            depthBase[6] = depthCorners[0] + ax0 + ay0
            depthBase[7] = depthCorners[1] + ax1 + ay1
            depthBase[8] = 1f
            backgroundChanged = false
        }
        val camera = current.camera
        tracking = trackingName(camera.trackingState)
        reason = if (camera.trackingState == TrackingState.TRACKING) "none" else reasonName(camera.trackingFailureReason)
        camera.getProjectionMatrix(projection, 0, 0.01f, 200f)
        camera.getViewMatrix(view, 0)
        camera.displayOrientedPose.toMatrix(cameraMatrix, 0)
        fov = (2 * atan(1 / projection[5]) * 180 / PI).toFloat()

        if (camera.trackingState != TrackingState.TRACKING) {
            centerHit = null
            centerHitMatrix = null
            return true
        }

        updateDepth(current)
        updateLight(current)
        updatePlanes(current)
        updateImages(current)
        updateFaces()
        updateGeo()
        updateSemantics(current)
        points =
            if (wantPoints) {
                runCatching {
                    current.acquirePointCloud().use { cloud ->
                        val buffer = cloud.points
                        val out = FloatArray(buffer.remaining() / 4 * 3)
                        var i = 0
                        while (buffer.remaining() >= 4) {
                            out[i++] = buffer.get()
                            out[i++] = buffer.get()
                            out[i++] = buffer.get()
                            buffer.get()
                        }
                        out
                    }
                }.getOrDefault(FloatArray(0))
            } else {
                FloatArray(0)
            }
        if (wantReticle) {
            val hits = hitTest(viewWidth / 2f, viewHeight / 2f, setOf("plane", "depth", "point", "instant"))
            val first = hits.firstOrNull()
            centerHit = first
            centerHitMatrix = (first?.get("pose") as? List<*>)?.let { UArMath.poseMatrix(it.map { v -> (v as Number).toDouble() }) }
        } else {
            centerHit = null
            centerHitMatrix = null
        }
        emitAnchors()
        return true
    }

    private fun updateDepth(current: Frame) {
        if (config["occlusion"] == false || !depthSupported || front) {
            depthReady = false
            return
        }
        try {
            current.acquireDepthImage16Bits().use { image ->
                if (depthTexture == 0) {
                    val ids = IntArray(1)
                    GLES30.glGenTextures(1, ids, 0)
                    depthTexture = ids[0]
                    GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, depthTexture)
                    GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_WRAP_S, GLES30.GL_CLAMP_TO_EDGE)
                    GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_WRAP_T, GLES30.GL_CLAMP_TO_EDGE)
                    GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_MIN_FILTER, GLES30.GL_NEAREST)
                    GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_MAG_FILTER, GLES30.GL_NEAREST)
                }
                val plane = image.planes[0]
                GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, depthTexture)
                GLES30.glPixelStorei(GLES30.GL_UNPACK_ALIGNMENT, 2)
                GLES30.glTexImage2D(GLES30.GL_TEXTURE_2D, 0, GLES30.GL_RG8, plane.rowStride / 2, image.height, 0, GLES30.GL_RG, GLES30.GL_UNSIGNED_BYTE, plane.buffer)
                GLES30.glPixelStorei(GLES30.GL_UNPACK_ALIGNMENT, 4)
                depthBase.copyInto(depthTransform)
                if (plane.rowStride / 2 != image.width) {
                    val scale = image.width.toFloat() / (plane.rowStride / 2)
                    depthTransform[0] *= scale
                    depthTransform[3] *= scale
                    depthTransform[6] *= scale
                }
                depthReady = true
            }
        } catch (_: NotYetAvailableException) {
        } catch (_: Exception) {
            depthReady = false
        }
    }

    val depth: Int get() = depthTexture

    private fun updateLight(current: Frame) {
        val estimate = current.lightEstimate
        if (estimate.state != LightEstimate.State.VALID) {
            lightMap = null
            return
        }
        val correction = FloatArray(4)
        estimate.getColorCorrection(correction, 0)
        val map =
            mutableMapOf<String, Any?>(
                "intensity" to estimate.pixelIntensity.toDouble(),
                "colorCorrection" to correction.map { it.toDouble() },
            )
        if (config["lightEstimation"] != "ambient" && !front) {
            runCatching {
                map["direction"] = estimate.environmentalHdrMainLightDirection.map { it.toDouble() }
                map["mainIntensity"] = estimate.environmentalHdrMainLightIntensity.map { it.toDouble() }
                map["sh"] = estimate.environmentalHdrAmbientSphericalHarmonics.map { it.toDouble() }
            }
        }
        lightMap = map
    }

    /** Pushes the current light estimate into the renderer's environment. */
    fun applyLight(env: UArEnvironment) {
        val map = lightMap ?: return
        val direction = (map["direction"] as? List<*>)?.map { (it as Number).toFloat() }
        val main = (map["mainIntensity"] as? List<*>)?.map { (it as Number).toFloat() }
        val sh = (map["sh"] as? List<*>)?.map { (it as Number).toFloat() }
        if (direction != null && main != null && sh != null && sh.size == 27) {
            env.lightDirection = direction.toFloatArray()
            env.lightColor = main.toFloatArray()
            val factors = floatArrayOf(0.282095f, -0.325735f, 0.325735f, -0.325735f, 0.273137f, -0.273137f, 0.078848f, -0.273137f, 0.136569f)
            env.sh = FloatArray(27) { sh[it] * factors[it / 3] }
        } else {
            val intensity = (map["intensity"] as? Double)?.toFloat() ?: 0.5f
            val correction = (map["colorCorrection"] as? List<*>)?.map { (it as Number).toFloat() } ?: listOf(1f, 1f, 1f, 1f)
            val scale = intensity * 3.2f
            env.lightColor = floatArrayOf(correction[0] * scale, correction[1] * scale, correction[2] * scale)
            env.sh = null
            env.sky = floatArrayOf(correction[0] * intensity * 1.1f, correction[1] * intensity * 1.1f, correction[2] * intensity * 1.1f)
            env.ground = floatArrayOf(correction[0] * intensity * 0.45f, correction[1] * intensity * 0.45f, correction[2] * intensity * 0.45f)
        }
    }

    private fun floorY(): Float? =
        planeIds.keys
            .filter { it.type == Plane.Type.HORIZONTAL_UPWARD_FACING && it.trackingState == TrackingState.TRACKING && it.subsumedBy == null }
            .minOfOrNull { it.centerPose.ty() }

    private fun classify(plane: Plane): String =
        when (plane.type) {
            Plane.Type.VERTICAL -> "wall"
            Plane.Type.HORIZONTAL_DOWNWARD_FACING -> "ceiling"
            else -> {
                val floor = floorY()
                val height = if (floor == null) 0f else plane.centerPose.ty() - floor
                when {
                    floor == null || height < 0.2f -> "floor"
                    height < 0.6f -> "seat"
                    height < 1.3f -> "table"
                    else -> "none"
                }
            }
        }

    private fun planeType(plane: Plane): String =
        when (plane.type) {
            Plane.Type.VERTICAL -> "vertical"
            Plane.Type.HORIZONTAL_DOWNWARD_FACING -> "horizontalDown"
            else -> "horizontalUp"
        }

    private fun planeId(plane: Plane): String =
        planeIds.getOrPut(plane) {
            val id = newId("p")
            planeById[id] = plane
            id
        }

    private fun planeMap(plane: Plane): Map<String, Any?> {
        val polygon = plane.polygon
        val list = ArrayList<Double>(polygon.remaining())
        while (polygon.hasRemaining()) list.add(polygon.get().toDouble())
        return mapOf(
            "id" to planeId(plane),
            "type" to planeType(plane),
            "classification" to classify(plane),
            "pose" to poseList(plane.centerPose),
            "extent" to listOf(plane.extentX.toDouble(), plane.extentZ.toDouble()),
            "polygon" to list,
            "tracking" to trackingName(plane.trackingState),
            "subsumedBy" to plane.subsumedBy?.let { planeIds[it] },
        )
    }

    private fun updatePlanes(current: Frame) {
        for (plane in current.getUpdatedTrackables(Plane::class.java)) {
            if (plane.trackingState == TrackingState.STOPPED || plane.subsumedBy != null) {
                planeIds[plane]?.let { removedPlanes.add(it) }
                pendingPlanes.remove(plane)
            } else {
                pendingPlanes.add(plane)
            }
        }
        planes.clear()
        for (plane in session.getAllTrackables(Plane::class.java)) {
            if (plane.trackingState != TrackingState.TRACKING || plane.subsumedBy != null) continue
            val polygon = plane.polygon
            val array = FloatArray(polygon.remaining())
            polygon.get(array)
            planes.add(UArPlaneDraw(planeId(plane), poseMatrix(plane.centerPose), array, plane.type == Plane.Type.VERTICAL))
        }
        val now = SystemClock.uptimeMillis()
        if ((pendingPlanes.isNotEmpty() || removedPlanes.isNotEmpty()) && now - lastPlaneEmit > 200) {
            lastPlaneEmit = now
            val updated = pendingPlanes.map { planeMap(it) }
            val removed = removedPlanes.toList()
            pendingPlanes.clear()
            removedPlanes.clear()
            emit(mapOf("type" to "planes", "updated" to updated, "removed" to removed))
        }
    }

    private fun updateImages(current: Frame) {
        val updated = ArrayList<Map<String, Any?>>()
        for (image in current.getUpdatedTrackables(AugmentedImage::class.java)) {
            images[image.name] = image
            updated.add(imageMap(image))
        }
        val now = SystemClock.uptimeMillis()
        if (updated.isNotEmpty() && now - lastImageEmit > 100) {
            lastImageEmit = now
            emit(mapOf("type" to "images", "updated" to updated))
        }
    }

    private fun imageMap(image: AugmentedImage): Map<String, Any?> =
        mapOf(
            "name" to image.name,
            "index" to image.index,
            "pose" to poseList(image.centerPose),
            "width" to image.extentX.toDouble(),
            "height" to image.extentZ.toDouble(),
            "tracking" to
                when {
                    image.trackingState == TrackingState.TRACKING && image.trackingMethod == AugmentedImage.TrackingMethod.FULL_TRACKING -> "normal"
                    image.trackingState == TrackingState.TRACKING -> "limited"
                    else -> "notAvailable"
                },
        )

    private fun updateFaces() {
        faces.clear()
        if (!front) return
        val updated = ArrayList<Map<String, Any?>>()
        val alive = HashSet<String>()
        for (face in session.getAllTrackables(AugmentedFace::class.java)) {
            if (face.trackingState != TrackingState.TRACKING) continue
            val id = faceIds.getOrPut(face) { newId("f") }
            alive.add(id)
            updated.add(
                mapOf(
                    "id" to id,
                    "pose" to poseList(face.centerPose),
                    "regions" to
                        mapOf(
                            "noseTip" to poseList(face.getRegionPose(AugmentedFace.RegionType.NOSE_TIP)),
                            "foreheadLeft" to poseList(face.getRegionPose(AugmentedFace.RegionType.FOREHEAD_LEFT)),
                            "foreheadRight" to poseList(face.getRegionPose(AugmentedFace.RegionType.FOREHEAD_RIGHT)),
                        ),
                ),
            )
            if (config["showFaceMesh"] == true) {
                val vertices = face.meshVertices
                val local = FloatArray(vertices.remaining())
                vertices.get(local)
                val center = poseMatrix(face.centerPose)
                val world = FloatArray(local.size)
                var i = 0
                while (i + 2 < local.size) {
                    val p = UArMath.transformPoint(center, local[i], local[i + 1], local[i + 2])
                    world[i] = p[0]
                    world[i + 1] = p[1]
                    world[i + 2] = p[2]
                    i += 3
                }
                val indexBuffer = face.meshTriangleIndices
                val indices = ShortArray(indexBuffer.remaining())
                indexBuffer.get(indices)
                faces.add(UArFaceDraw(world, indices))
            }
        }
        val removed = faceIds.filterValues { it !in alive }
        removed.keys.forEach { faceIds.remove(it) }
        val now = SystemClock.uptimeMillis()
        if (removed.isNotEmpty() || updated.isNotEmpty() && now - lastFaceEmit > 33) {
            lastFaceEmit = now
            emit(mapOf("type" to "faces", "updated" to updated, "removed" to removed.values.toList()))
        }
    }

    private fun updateGeo() {
        val earth = runCatching { session.earth }.getOrNull()
        if (earth == null) {
            geoMap = null
            return
        }
        val map =
            mutableMapOf<String, Any?>(
                "state" to earth.earthState.name,
                "tracking" to trackingName(earth.trackingState),
                "source" to "vps",
            )
        if (earth.trackingState == TrackingState.TRACKING) {
            val pose = earth.cameraGeospatialPose
            val q = pose.eastUpSouthQuaternion
            val forward = UArMath.quatRotate(q, floatArrayOf(0f, 0f, -1f))
            val heading = ((atan2(forward[0], -forward[2]) * 180 / PI) + 360) % 360
            map["latitude"] = pose.latitude
            map["longitude"] = pose.longitude
            map["altitude"] = pose.altitude
            map["heading"] = heading
            map["horizontalAccuracy"] = pose.horizontalAccuracy
            map["verticalAccuracy"] = pose.verticalAccuracy
            map["headingAccuracy"] = pose.orientationYawAccuracy
        }
        geoMap = map
    }

    private fun updateSemantics(current: Frame) {
        if (config["semantics"] != true || !semanticsSupported) {
            semanticsMap = null
            return
        }
        val map = HashMap<String, Any?>()
        for (label in SemanticLabel.values()) {
            try {
                map[label.name.lowercase()] = current.getSemanticLabelFraction(label).toDouble()
            } catch (_: Exception) {
            }
        }
        semanticsMap = map
    }

    // -------------------------------------------------------------------------
    // Hit testing
    // -------------------------------------------------------------------------

    fun hitTest(
        x: Float,
        y: Float,
        types: Set<String>,
    ): List<Map<String, Any?>> {
        val current = frame ?: return emptyList()
        if (current.camera.trackingState != TrackingState.TRACKING) return emptyList()
        val out = ArrayList<Map<String, Any?>>()
        for (hit in current.hitTest(x, y)) {
            val trackable = hit.trackable
            val type =
                when (trackable) {
                    is Plane -> if (trackable.isPoseInPolygon(hit.hitPose) && trackable.subsumedBy == null) "plane" else null
                    is DepthPoint -> "depth"
                    is Point -> if (trackable.orientationMode == Point.OrientationMode.ESTIMATED_SURFACE_NORMAL) "point" else "estimated"
                    else -> null
                } ?: continue
            if (type !in types) continue
            out.add(hitMap(hit, type, trackable))
        }
        if (out.isEmpty() && instantEnabled && "instant" in types) {
            current.hitTestInstantPlacement(x, y, 1.5f).firstOrNull()?.let { out.add(hitMap(it, "instant", it.trackable)) }
        }
        return out
    }

    private fun hitMap(
        hit: HitResult,
        type: String,
        trackable: Trackable,
    ): Map<String, Any?> {
        val trackableId =
            if (trackable is Plane) {
                planeId(trackable)
            } else {
                val id = newId("t")
                hitTrackables[id] = trackable
                while (hitTrackables.size > 64) hitTrackables.remove(hitTrackables.keys.first())
                id
            }
        val plane = trackable as? Plane
        return mapOf(
            "pose" to poseList(hit.hitPose),
            "distance" to hit.distance.toDouble(),
            "type" to type,
            "trackableId" to trackableId,
            "planeType" to plane?.let { planeType(it) },
            "classification" to (plane?.let { classify(it) } ?: "none"),
        )
    }

    // -------------------------------------------------------------------------
    // Anchors
    // -------------------------------------------------------------------------

    private fun pose(list: List<Double>): Pose {
        val q = UArMath.quatNormalize(floatArrayOf(list[3].toFloat(), list[4].toFloat(), list[5].toFloat(), list[6].toFloat()))
        return Pose(floatArrayOf(list[0].toFloat(), list[1].toFloat(), list[2].toFloat()), q)
    }

    fun addAnchor(
        id: String,
        poseList: List<Double>,
        trackableId: String?,
        type: String = "world",
    ): Map<String, Any?> {
        val trackable: Trackable? = trackableId?.let { planeById[it] ?: hitTrackables[it] }
        val anchor =
            runCatching { trackable?.createAnchor(pose(poseList)) }.getOrNull() ?: session.createAnchor(pose(poseList))
        anchors.remove(id)?.detach()
        anchors[id] = anchor
        anchorTypes[id] =
            when (trackable) {
                is Plane -> "plane"
                is Point, is DepthPoint -> "point"
                else -> type
            }
        if (trackableId != null) anchorTrackables[id] = trackableId
        return anchorMap(id, anchor)
    }

    fun updateAnchor(
        id: String,
        poseList: List<Double>,
    ) {
        val old = anchors[id]
        val anchor = session.createAnchor(pose(poseList))
        anchors[id] = anchor
        old?.detach()
    }

    fun removeAnchor(id: String) {
        anchors.remove(id)?.detach()
        anchorTypes.remove(id)
        anchorTrackables.remove(id)
        lastAnchorPoses.remove(id)
        lastAnchorStates.remove(id)
        emit(mapOf("type" to "anchors", "updated" to emptyList<Any>(), "removed" to listOf(id)))
    }

    private fun anchorMap(
        id: String,
        anchor: Anchor,
    ): Map<String, Any?> =
        mapOf(
            "id" to id,
            "pose" to poseList(anchor.pose),
            "type" to (anchorTypes[id] ?: "world"),
            "tracking" to trackingName(anchor.trackingState),
            "cloudId" to cloudIds[id],
            "trackableId" to anchorTrackables[id],
        )

    private fun emitAnchors() {
        val now = SystemClock.uptimeMillis()
        if (now - lastAnchorEmit < 100) return
        lastAnchorEmit = now
        val updated = ArrayList<Map<String, Any?>>()
        for ((id, anchor) in anchors) {
            val matrix = poseMatrix(anchor.pose)
            val state = trackingName(anchor.trackingState)
            val last = lastAnchorPoses[id]
            val moved = last == null || UArMath.distance(UArMath.translation(last), UArMath.translation(matrix)) > 0.002f
            if (moved || lastAnchorStates[id] != state) {
                lastAnchorPoses[id] = matrix
                lastAnchorStates[id] = state
                updated.add(anchorMap(id, anchor))
            }
        }
        if (updated.isNotEmpty()) emit(mapOf("type" to "anchors", "updated" to updated, "removed" to emptyList<String>()))
    }

    /** World matrix of an anchor, a tracked image ("image:name"), a face ("face" / "face:id") or the camera. */
    fun anchorMatrix(id: String): FloatArray? {
        if (id == "camera") return cameraMatrix
        if (id.startsWith("image:")) {
            val image = images[id.removePrefix("image:")] ?: return null
            return if (image.trackingState == TrackingState.TRACKING) poseMatrix(image.centerPose) else null
        }
        if (id == "face" || id.startsWith("face:")) {
            val wanted = id.removePrefix("face:").removePrefix("face")
            val face =
                faceIds.entries.firstOrNull { wanted.isEmpty() || it.value == wanted }?.key
                    ?: return null
            return if (face.trackingState == TrackingState.TRACKING) poseMatrix(face.centerPose) else null
        }
        val anchor = anchors[id] ?: return null
        return if (anchor.trackingState == TrackingState.STOPPED) null else poseMatrix(anchor.pose)
    }

    fun hasAnchor(id: String): Boolean = anchors.containsKey(id)

    // -------------------------------------------------------------------------
    // Geospatial and Cloud Anchors
    // -------------------------------------------------------------------------

    fun addGeoAnchor(
        id: String,
        latitude: Double,
        longitude: Double,
        altitude: Double,
        mode: String,
        heading: Double,
        done: (Map<String, Any?>?, String?) -> Unit,
    ) {
        val earth = runCatching { session.earth }.getOrNull()
        if (earth == null) {
            done(null, "unsupported")
            return
        }
        if (earth.trackingState != TrackingState.TRACKING) {
            done(null, "notTracking")
            return
        }
        val q = UArMath.quatAxisAngle(0f, 1f, 0f, (-heading * PI / 180).toFloat())
        when (mode) {
            "terrain" ->
                earth.resolveAnchorOnTerrainAsync(latitude, longitude, altitude, q[0], q[1], q[2], q[3]) { anchor, state ->
                    post {
                        if (state == Anchor.TerrainAnchorState.SUCCESS && anchor != null) {
                            anchors[id] = anchor
                            anchorTypes[id] = "terrain"
                            done(anchorMap(id, anchor), null)
                        } else {
                            done(null, state.name)
                        }
                    }
                }
            "rooftop" ->
                earth.resolveAnchorOnRooftopAsync(latitude, longitude, altitude, q[0], q[1], q[2], q[3]) { anchor, state ->
                    post {
                        if (state == Anchor.RooftopAnchorState.SUCCESS && anchor != null) {
                            anchors[id] = anchor
                            anchorTypes[id] = "rooftop"
                            done(anchorMap(id, anchor), null)
                        } else {
                            done(null, state.name)
                        }
                    }
                }
            else -> {
                val anchor = earth.createAnchor(latitude, longitude, altitude, q[0], q[1], q[2], q[3])
                anchors[id] = anchor
                anchorTypes[id] = "geo"
                done(anchorMap(id, anchor), null)
            }
        }
    }

    fun checkVps(
        latitude: Double,
        longitude: Double,
        done: (String) -> Unit,
    ) {
        session.checkVpsAvailabilityAsync(latitude, longitude) { availability ->
            post {
                done(
                    when (availability) {
                        VpsAvailability.AVAILABLE -> "available"
                        VpsAvailability.UNAVAILABLE -> "unavailable"
                        else -> "unknown"
                    },
                )
            }
        }
    }

    fun hostCloudAnchor(
        id: String,
        ttlDays: Int,
        done: (String?, String?) -> Unit,
    ) {
        val anchor = anchors[id]
        if (anchor == null) {
            done(null, "notFound")
            return
        }
        session.hostCloudAnchorAsync(anchor, ttlDays) { cloudId, state ->
            post {
                if (state == Anchor.CloudAnchorState.SUCCESS && cloudId != null) {
                    cloudIds[id] = cloudId
                    done(cloudId, null)
                } else {
                    done(null, state.name)
                }
            }
        }
    }

    fun resolveCloudAnchor(
        cloudId: String,
        id: String,
        done: (Map<String, Any?>?, String?) -> Unit,
    ) {
        session.resolveCloudAnchorAsync(cloudId) { anchor, state ->
            post {
                if (state == Anchor.CloudAnchorState.SUCCESS && anchor != null) {
                    anchors[id] = anchor
                    anchorTypes[id] = "cloud"
                    cloudIds[id] = cloudId
                    done(anchorMap(id, anchor), null)
                } else {
                    done(null, state.name)
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // Camera image
    // -------------------------------------------------------------------------

    fun cameraImage(maxSize: Int): Map<String, Any?>? {
        val current = frame ?: return null
        return try {
            current.acquireCameraImage().use { image ->
                val plane = image.planes[0]
                val width = image.width
                val height = image.height
                var step = 1
                while (width / step > maxSize || height / step > maxSize) step++
                val outW = width / step
                val outH = height / step
                val out = ByteArray(outW * outH)
                val buffer = plane.buffer
                val rowStride = plane.rowStride
                val pixelStride = plane.pixelStride
                for (y in 0 until outH) {
                    val row = y * step * rowStride
                    for (x in 0 until outW) out[y * outW + x] = buffer.get(row + x * step * pixelStride)
                }
                val corners = floatArrayOf(0f, 0f, width.toFloat(), 0f, 0f, height.toFloat())
                val view = FloatArray(6)
                current.transformCoordinates2d(Coordinates2d.IMAGE_PIXELS, corners, Coordinates2d.VIEW_NORMALIZED, view)
                val a = (view[2] - view[0]) / width * step
                val d = (view[3] - view[1]) / width * step
                val b = (view[4] - view[0]) / height * step
                val e = (view[5] - view[1]) / height * step
                mapOf(
                    "bytes" to out,
                    "width" to outW,
                    "height" to outH,
                    "stride" to outW,
                    "transform" to listOf(a, b, view[0], d, e, view[1]).map { it.toDouble() },
                )
            }
        } catch (_: Exception) {
            null
        }
    }

    companion object {
        fun sdkPresent(): Boolean = runCatching { Class.forName("com.google.ar.core.Session") }.isSuccess

        fun availability(context: Context): String =
            runCatching {
                var availability = ArCoreApk.getInstance().checkAvailability(context)
                var tries = 0
                while (availability.isTransient && tries < 20) {
                    Thread.sleep(100)
                    availability = ArCoreApk.getInstance().checkAvailability(context)
                    tries++
                }
                when (availability) {
                    ArCoreApk.Availability.SUPPORTED_INSTALLED -> "supported"
                    ArCoreApk.Availability.SUPPORTED_APK_TOO_OLD, ArCoreApk.Availability.SUPPORTED_NOT_INSTALLED -> "needsInstall"
                    ArCoreApk.Availability.UNSUPPORTED_DEVICE_NOT_CAPABLE -> "unsupported"
                    else -> "unknown"
                }
            }.getOrDefault("unknown")

        fun requestInstall(activity: Activity): String =
            runCatching {
                when (ArCoreApk.getInstance().requestInstall(activity, true)) {
                    ArCoreApk.InstallStatus.INSTALLED -> "supported"
                    else -> "needsInstall"
                }
            }.getOrDefault("unsupported")

        /** Opens a throwaway session to learn what this device supports. */
        fun probe(context: Context): Map<String, Any?> =
            runCatching {
                val session = Session(context)
                val result =
                    mapOf(
                        "depth" to runCatching { session.isDepthModeSupported(Config.DepthMode.AUTOMATIC) }.getOrDefault(false),
                        "geospatial" to runCatching { session.isGeospatialModeSupported(Config.GeospatialMode.ENABLED) }.getOrDefault(false),
                        "semantics" to runCatching { session.isSemanticModeSupported(Config.SemanticMode.ENABLED) }.getOrDefault(false),
                    )
                session.close()
                result
            }.getOrDefault(emptyMap())

        fun errorCode(error: Throwable): String =
            when (error.javaClass.simpleName) {
                "UnavailableArcoreNotInstalledException", "UnavailableApkTooOldException" -> "notInstalled"
                "UnavailableSdkTooOldException", "UnavailableDeviceNotCompatibleException" -> "unsupported"
                "UnavailableUserDeclinedInstallationException" -> "cancelled"
                "CameraNotAvailableException" -> "sessionFailed"
                "SecurityException" -> "permission"
                else -> "sessionFailed"
            }
    }
}

// =============================================================================
// Scene nodes
// =============================================================================

internal class UArNodeRuntime(
    val id: String,
) {
    var type = "group"
    var anchorId: String? = null
    var parentId: String? = null
    var position = floatArrayOf(0f, 0f, 0f)
    var rotation = floatArrayOf(0f, 0f, 0f, 1f)
    var scale = floatArrayOf(1f, 1f, 1f)
    var billboard = "none"
    var visible = true
    var castShadow = true
    var hittable = true
    var fitSize: Float? = null
    var pivot = "original"
    var width = 0.1f
    var height = 0.1f
    var depth = 0.1f
    var radius = 0.05f
    var material = UMaterial()
    var mesh: UGpuMesh? = null
    var model: UModelInstance? = null
    var modelKey: String? = null
    var video: UArVideo? = null
    var imageTexture = 0
    var normalization = UArMath.identity()
    var sourceKey: String? = null
    var loaded = false
    var animation: Map<*, *>? = null
    var videoOptions: Map<*, *>? = null
    val world = UArMath.identity()
    var worldFrame = -1L
    var worldValid = false

    fun apply(map: Map<*, *>) {
        type = map["type"] as? String ?: type
        anchorId = map["anchorId"] as? String
        parentId = map["parentId"] as? String
        position = UArMath.floats(map["position"], 3, 0f)
        rotation = UArMath.quatNormalize(UArMath.floats(map["rotation"], 4, 0f).let { if (it.all { v -> v == 0f }) floatArrayOf(0f, 0f, 0f, 1f) else it })
        scale = UArMath.floats(map["scale"], 3, 1f)
        billboard = map["billboard"] as? String ?: "none"
        visible = map["visible"] != false
        castShadow = map["castShadow"] != false
        hittable = map["hittable"] != false
        fitSize = (map["fitSize"] as? Number)?.toFloat()
        pivot = map["pivot"] as? String ?: "original"
        width = (map["width"] as? Number)?.toFloat() ?: width
        height = (map["height"] as? Number)?.toFloat() ?: height
        depth = (map["depth"] as? Number)?.toFloat() ?: depth
        radius = (map["radius"] as? Number)?.toFloat() ?: radius
        animation = map["animation"] as? Map<*, *>
        videoOptions = map["video"] as? Map<*, *>
        if (type != "model") {
            val texture = material.baseTexture
            material.applyDart(map["material"] as? Map<*, *>)
            material.baseTexture = texture
            if (type == "image") {
                material.alphaMode = 2
                material.doubleSided = true
            }
        }
    }

    fun localBounds(): Pair<FloatArray, FloatArray>? {
        val instance = model
        if (instance != null) return Pair(instance.min, instance.max)
        val m = mesh ?: return null
        return Pair(m.min, m.max)
    }

    fun updateNormalization() {
        val instance = model ?: return
        val size = FloatArray(3) { instance.max[it] - instance.min[it] }
        val largest = max(size[0], max(size[1], size[2]))
        val s = fitSize?.let { if (largest > 0f) it / largest else 1f } ?: 1f
        val cx = (instance.min[0] + instance.max[0]) / 2
        val cy = (instance.min[1] + instance.max[1]) / 2
        val cz = (instance.min[2] + instance.max[2]) / 2
        val offset =
            when (pivot) {
                "bottom" -> floatArrayOf(-cx, -instance.min[1], -cz)
                "center" -> floatArrayOf(-cx, -cy, -cz)
                else -> floatArrayOf(0f, 0f, 0f)
            }
        val scaleMatrix = UArMath.compose(floatArrayOf(0f, 0f, 0f), floatArrayOf(0f, 0f, 0f, 1f), floatArrayOf(s, s, s))
        val translate = UArMath.compose(offset, floatArrayOf(0f, 0f, 0f, 1f), floatArrayOf(1f, 1f, 1f))
        normalization = UArMath.multiply(scaleMatrix, translate)
    }
}

// =============================================================================
// Session: EGL surface, render loop, scene and method handling
// =============================================================================

internal class UArSession(
    val id: Int,
    private val context: Context,
    messenger: BinaryMessenger,
    textureRegistry: TextureRegistry,
    private var config: Map<*, *>,
    private val activityProvider: () -> Activity?,
) : EventChannel.StreamHandler,
    SensorEventListener {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val eventChannel = EventChannel(messenger, "u/ar/events/$id")
    private var eventSink: EventChannel.EventSink? = null
    private val thread = HandlerThread("u-ar-$id").apply { start() }
    private val gl = Handler(thread.looper)
    private val producer: TextureRegistry.SurfaceProducer = textureRegistry.createSurfaceProducer()
    private val loader = UArSourceLoader(context)
    private val workers = Executors.newFixedThreadPool(2)
    private val renderer = UArRenderer()
    private val env = UArEnvironment()
    private val nodes = LinkedHashMap<String, UArNodeRuntime>()
    private val models = HashMap<String, UModel>()
    private val staticAnchors = HashMap<String, FloatArray>()
    private var core: UArCoreSession? = null
    private var imageDatabaseKey = ""
    private var cameraTexture = 0

    private var eglDisplay: EGLDisplay = EGL14.EGL_NO_DISPLAY
    private var eglContext: EGLContext = EGL14.EGL_NO_CONTEXT
    private var eglConfig: EGLConfig? = null
    private var eglSurface: EGLSurface = EGL14.EGL_NO_SURFACE
    private var pbufferSurface: EGLSurface = EGL14.EGL_NO_SURFACE

    private var width = 0
    private var height = 0
    private var pixelRatio = 1f
    private var displayRotation = 0
    private var started = false
    private var paused = false
    private var disposed = false
    private var frameCounter = 0L
    private var lastFrameNanos = 0L
    private var lastEventMs = 0L
    private var lastTracking = ""
    private var lastReason = ""
    private var tracks: List<Map<*, *>> = emptyList()
    private val viewerCamera = UArMath.identity()
    private var viewerFov = 45f

    private var pendingSnapshot: Pair<Map<*, *>, MethodChannel.Result>? = null
    private var recorder: MediaRecorder? = null
    private var recorderSurface: EGLSurface = EGL14.EGL_NO_SURFACE
    private var recordingPath: String? = null
    private var recordingStart = 0L
    private var recordWidth = 0
    private var recordHeight = 0

    private var sensorManager: SensorManager? = null
    private var declination = 0f
    private var sensorHeading: Float? = null
    private var headingAccuracy = -1f
    private var northSin = 0f
    private var northCos = 0f
    private var northYaw: Float? = null

    private val choreographerCallback =
        object : Choreographer.FrameCallback {
            override fun doFrame(frameTimeNanos: Long) {
                if (disposed) return
                runCatching { renderFrame() }.onFailure { error ->
                    emit(mapOf("type" to "error", "code" to "sessionFailed", "message" to (error.message ?: error.javaClass.simpleName)))
                }
                if (!disposed) Choreographer.getInstance().postFrameCallback(this)
            }
        }

    val textureId: Long get() = producer.id()

    private val isViewer: Boolean get() = config["mode"] == "viewer"

    init {
        eventChannel.setStreamHandler(this)
        producer.setCallback(
            object : TextureRegistry.SurfaceProducer.Callback {
                override fun onSurfaceAvailable() {
                    gl.post { createWindowSurface() }
                }

                override fun onSurfaceCleanup() {
                    val latch = CountDownLatch(1)
                    gl.post {
                        destroyWindowSurface()
                        latch.countDown()
                    }
                    runCatching { latch.await(1, TimeUnit.SECONDS) }
                }
            },
        )
        gl.post {
            setupEgl()
            renderer.init()
            cameraTexture = UArTextures.external()
        }
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?,
    ) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun emit(payload: Map<String, Any?>) {
        if (disposed) return
        mainHandler.post { runCatching { eventSink?.success(payload) } }
    }

    // -------------------------------------------------------------------------
    // EGL
    // -------------------------------------------------------------------------

    private fun setupEgl() {
        eglDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
        val version = IntArray(2)
        EGL14.eglInitialize(eglDisplay, version, 0, version, 1)
        eglConfig = chooseConfig(4) ?: chooseConfig(0) ?: throw IllegalStateException("No EGL config")
        eglContext = EGL14.eglCreateContext(eglDisplay, eglConfig, EGL14.EGL_NO_CONTEXT, intArrayOf(EGL14.EGL_CONTEXT_CLIENT_VERSION, 3, EGL14.EGL_NONE), 0)
        pbufferSurface = EGL14.eglCreatePbufferSurface(eglDisplay, eglConfig, intArrayOf(EGL14.EGL_WIDTH, 1, EGL14.EGL_HEIGHT, 1, EGL14.EGL_NONE), 0)
        EGL14.eglMakeCurrent(eglDisplay, pbufferSurface, pbufferSurface, eglContext)
    }

    private fun chooseConfig(samples: Int): EGLConfig? {
        val attributes =
            mutableListOf(
                EGL14.EGL_RED_SIZE, 8,
                EGL14.EGL_GREEN_SIZE, 8,
                EGL14.EGL_BLUE_SIZE, 8,
                EGL14.EGL_ALPHA_SIZE, 8,
                EGL14.EGL_DEPTH_SIZE, 24,
                EGL14.EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
                EGL_RECORDABLE_ANDROID, 1,
            )
        if (samples > 0) attributes.addAll(listOf(EGL14.EGL_SAMPLE_BUFFERS, 1, EGL14.EGL_SAMPLES, samples))
        attributes.add(EGL14.EGL_NONE)
        val configs = arrayOfNulls<EGLConfig>(1)
        val count = IntArray(1)
        val ok = EGL14.eglChooseConfig(eglDisplay, attributes.toIntArray(), 0, configs, 0, 1, count, 0)
        return if (ok && count[0] > 0) configs[0] else null
    }

    private fun createWindowSurface() {
        if (disposed || width <= 0 || height <= 0) return
        destroyWindowSurface()
        val surface = producer.surface ?: return
        eglSurface = EGL14.eglCreateWindowSurface(eglDisplay, eglConfig, surface, intArrayOf(EGL14.EGL_NONE), 0)
        if (eglSurface == EGL14.EGL_NO_SURFACE) return
        EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext)
    }

    private fun destroyWindowSurface() {
        if (eglSurface != EGL14.EGL_NO_SURFACE) {
            EGL14.eglMakeCurrent(eglDisplay, pbufferSurface, pbufferSurface, eglContext)
            EGL14.eglDestroySurface(eglDisplay, eglSurface)
            eglSurface = EGL14.EGL_NO_SURFACE
        }
    }

    private fun readDisplayRotation(): Int =
        runCatching {
            val activity = activityProvider()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                (activity?.display ?: (context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager).getDisplay(0)).rotation
            } else {
                @Suppress("DEPRECATION")
                (context.getSystemService(Context.WINDOW_SERVICE) as WindowManager).defaultDisplay.rotation
            }
        }.getOrDefault(0)

    // -------------------------------------------------------------------------
    // Lifecycle
    // -------------------------------------------------------------------------

    private fun resize(
        widthDp: Double,
        heightDp: Double,
        ratio: Double,
    ) {
        pixelRatio = ratio.toFloat()
        val w = max(1, (widthDp * ratio).roundToInt())
        val h = max(1, (heightDp * ratio).roundToInt())
        if (w == width && h == height && eglSurface != EGL14.EGL_NO_SURFACE) return
        width = w
        height = h
        producer.setSize(width, height)
        createWindowSurface()
        displayRotation = readDisplayRotation()
        core?.setDisplayGeometry(displayRotation, width, height)
        core?.backgroundChanged = true
    }

    private fun start(
        args: Map<*, *>,
        result: MethodChannel.Result,
    ) {
        resize((args["width"] as? Number)?.toDouble() ?: 1.0, (args["height"] as? Number)?.toDouble() ?: 1.0, (args["pixelRatio"] as? Number)?.toDouble() ?: 1.0)
        if (!isViewer) {
            if (!UArCoreSession.sdkPresent()) {
                result.error("sdkMissing", "Add implementation(\"com.google.ar:core:1.45.0\") to android/app/build.gradle to enable AR", null)
                return
            }
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                result.error("permission", "Camera permission is required", null)
                return
            }
            try {
                val session = UArCoreSession(context, config, cameraTexture, loader, { block -> gl.post(block) }, ::emit)
                core = session
                session.setDisplayGeometry(displayRotation, width, height)
                session.resume()
                loadImageDatabase()
            } catch (error: Throwable) {
                core = null
                result.error(UArCoreSession.errorCode(error), error.message ?: error.javaClass.simpleName, null)
                return
            }
            if (config["mode"] == "geo" || config["worldAlignment"] == "gravityAndHeading") startHeading()
        }
        started = true
        lastFrameNanos = System.nanoTime()
        Choreographer.getInstance().postFrameCallback(choreographerCallback)
        result.success(mapOf("capabilities" to capabilities()))
        emit(mapOf("type" to "state", "session" to "running", "tracking" to if (isViewer) "normal" else "notAvailable", "reason" to if (isViewer) "none" else "initializing"))
    }

    fun capabilities(): Map<String, Any?> = core?.capabilities() ?: UArHandler.viewerCapabilities()

    private fun loadImageDatabase() {
        val session = core ?: return
        val images = (config["images"] as? List<*>)?.filterIsInstance<Map<*, *>>() ?: emptyList()
        val key = images.joinToString("|") { "${it["name"]}:${it["width"]}" }
        if (key == imageDatabaseKey) return
        imageDatabaseKey = key
        if (images.isEmpty()) {
            session.configure(config, null)
            return
        }
        workers.execute {
            val decoded =
                images.mapNotNull { image ->
                    runCatching {
                        val bytes = loader.load(image["source"] as? Map<*, *>).bytes
                        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return@runCatching null
                        Triple(image["name"] as String, bitmap, (image["width"] as? Number)?.toFloat() ?: 0.2f)
                    }.getOrNull()
                }
            gl.post {
                val current = core ?: return@post
                runCatching { current.configure(config, current.buildImageDatabase(decoded)) }.onFailure {
                    emit(mapOf("type" to "error", "code" to "loadFailed", "message" to (it.message ?: "Image database failed")))
                }
            }
        }
    }

    fun onHostPause() = gl.post { if (started && !paused) runCatching { core?.pause() } }

    fun onHostResume() = gl.post { if (started && !paused) runCatching { core?.resume() } }

    fun dispose() {
        if (disposed) return
        disposed = true
        runCatching { eventChannel.setStreamHandler(null) }
        stopHeading()
        gl.post {
            runCatching { stopRecordingInternal() }
            runCatching { core?.close() }
            core = null
            for (node in nodes.values) releaseNode(node)
            nodes.clear()
            models.values.forEach { runCatching { it.release() } }
            models.clear()
            runCatching { renderer.release() }
            UArTextures.delete(cameraTexture)
            destroyWindowSurface()
            if (pbufferSurface != EGL14.EGL_NO_SURFACE) EGL14.eglDestroySurface(eglDisplay, pbufferSurface)
            EGL14.eglMakeCurrent(eglDisplay, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT)
            if (eglContext != EGL14.EGL_NO_CONTEXT) EGL14.eglDestroyContext(eglDisplay, eglContext)
            EGL14.eglTerminate(eglDisplay)
            runCatching { producer.release() }
            thread.quitSafely()
        }
        workers.shutdownNow()
    }

    // -------------------------------------------------------------------------
    // Compass heading (GPS placement on devices without visual positioning)
    // -------------------------------------------------------------------------

    private fun startHeading() {
        if (sensorManager != null) return
        mainHandler.post {
            val manager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
            val sensor = manager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR) ?: return@post
            sensorManager = manager
            manager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)
        }
    }

    private fun stopHeading() {
        mainHandler.post {
            sensorManager?.unregisterListener(this)
            sensorManager = null
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        val matrix = FloatArray(9)
        SensorManager.getRotationMatrixFromVector(matrix, event.values)
        val east = -matrix[2]
        val north = -matrix[5]
        val up = -matrix[8]
        if (abs(up) > 0.85f) return
        sensorHeading = ((atan2(east, north) * 180 / PI).toFloat() + declination + 360f) % 360f
        if (event.values.size > 4 && event.values[4] > 0f) headingAccuracy = (event.values[4] * 180 / PI).toFloat()
    }

    override fun onAccuracyChanged(
        sensor: Sensor?,
        accuracy: Int,
    ) {
        if (headingAccuracy > 0f) return
        headingAccuracy =
            when (accuracy) {
                SensorManager.SENSOR_STATUS_ACCURACY_HIGH -> 10f
                SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM -> 20f
                SensorManager.SENSOR_STATUS_ACCURACY_LOW -> 35f
                else -> 60f
            }
    }

    private fun updateNorthYaw(camera: FloatArray) {
        val heading = sensorHeading ?: return
        val fx = -camera[8]
        val fy = -camera[9]
        val fz = -camera[10]
        if (abs(fy) > 0.85f) return
        val alpha = atan2(fx, -fz)
        val theta = (heading * PI / 180).toFloat() - alpha
        if (northYaw == null) {
            northSin = sin(theta)
            northCos = cos(theta)
        } else {
            northSin += (sin(theta) - northSin) * 0.04f
            northCos += (cos(theta) - northCos) * 0.04f
        }
        northYaw = atan2(northSin, northCos)
    }

    // -------------------------------------------------------------------------
    // Frame
    // -------------------------------------------------------------------------

    private fun renderFrame() {
        if (!started || paused || eglSurface == EGL14.EGL_NO_SURFACE) return
        val now = System.nanoTime()
        val delta = ((now - lastFrameNanos) / 1e9f).coerceIn(0f, 0.1f)
        lastFrameNanos = now
        frameCounter++
        EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext)
        if (frameCounter % 30 == 0L) {
            val rotation = readDisplayRotation()
            if (rotation != displayRotation) {
                displayRotation = rotation
                core?.setDisplayGeometry(displayRotation, width, height)
            }
        }

        val session = core
        if (session != null) {
            try {
                session.update(width, height, config["showFeaturePoints"] == true, config["reticle"] == true)
            } catch (error: Throwable) {
                if (error.javaClass.simpleName == "CameraNotAvailableException") {
                    emit(mapOf("type" to "state", "session" to "paused", "tracking" to "notAvailable", "reason" to "cameraUnavailable"))
                    paused = true
                    return
                }
                throw error
            }
            session.view.copyInto(env.view)
            session.projection.copyInto(env.projection)
            env.cameraPosition = UArMath.translation(session.cameraMatrix)
            env.useDepth = session.depthReady && config["occlusion"] != false
            env.depthTexture = session.depth
            session.depthTransform.copyInto(env.depthTransform)
            applyEnvironment()
            updateNorthYaw(session.cameraMatrix)
            if (session.tracking != lastTracking || session.reason != lastReason) {
                lastTracking = session.tracking
                lastReason = session.reason
                emit(mapOf("type" to "state", "tracking" to session.tracking, "reason" to session.reason, "session" to "running"))
            }
        } else {
            updateViewerCamera()
            applyEnvironment()
        }
        Matrix.multiplyMM(env.viewProjection, 0, env.projection, 0, env.view, 0)

        for (node in nodes.values) {
            node.model?.update(delta)
            node.video?.update()
        }

        drawScene(width, height)
        pendingSnapshot?.let { (args, result) ->
            pendingSnapshot = null
            snapshotNow(args, result)
        }
        EGL14.eglSwapBuffers(eglDisplay, eglSurface)

        if (recorder != null && recorderSurface != EGL14.EGL_NO_SURFACE) {
            EGL14.eglMakeCurrent(eglDisplay, recorderSurface, recorderSurface, eglContext)
            drawScene(recordWidth, recordHeight)
            EGLExt.eglPresentationTimeANDROID(eglDisplay, recorderSurface, now)
            EGL14.eglSwapBuffers(eglDisplay, recorderSurface)
            EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext)
        }

        val rate = (config["eventRate"] as? Number)?.toInt()?.coerceIn(1, 60) ?: 30
        val nowMs = SystemClock.uptimeMillis()
        if (nowMs - lastEventMs >= 1000 / rate) {
            lastEventMs = nowMs
            emitFrame()
        }
    }

    private fun applyEnvironment() {
        val intensity = (config["environmentIntensity"] as? Number)?.toFloat() ?: 1f
        env.exposure = (config["exposure"] as? Number)?.toFloat() ?: 1f
        val session = core
        if (session != null && config["lightEstimation"] != "disabled" && session.lightMap != null) {
            session.applyLight(env)
        } else {
            env.lightDirection = floatArrayOf(0.35f, 0.85f, 0.4f)
            env.lightColor = floatArrayOf(2.4f, 2.4f, 2.3f)
            env.sh = null
            env.sky = floatArrayOf(0.62f, 0.64f, 0.68f)
            env.ground = floatArrayOf(0.3f, 0.29f, 0.28f)
        }
        if (intensity != 1f) {
            env.lightColor = env.lightColor.map { it * intensity }.toFloatArray()
            env.sky = env.sky.map { it * intensity }.toFloatArray()
            env.ground = env.ground.map { it * intensity }.toFloatArray()
            env.sh = env.sh?.map { it * intensity }?.toFloatArray()
        }
    }

    private fun updateViewerCamera() {
        val orbit = config["orbit"] as? Map<*, *>
        val yaw = ((orbit?.get("yaw") as? Number)?.toDouble() ?: 30.0) * PI / 180
        val pitch = ((orbit?.get("pitch") as? Number)?.toDouble() ?: 15.0) * PI / 180
        val distance = (orbit?.get("distance") as? Number)?.toFloat() ?: 1.5f
        val target = UArMath.floats(orbit?.get("target"), 3, 0f)
        viewerFov = (orbit?.get("fov") as? Number)?.toFloat() ?: 45f
        val eye =
            floatArrayOf(
                target[0] + distance * (cos(pitch) * sin(yaw)).toFloat(),
                target[1] + distance * sin(pitch).toFloat(),
                target[2] + distance * (cos(pitch) * cos(yaw)).toFloat(),
            )
        Matrix.setLookAtM(env.view, 0, eye[0], eye[1], eye[2], target[0], target[1], target[2], 0f, 1f, 0f)
        val aspect = if (height == 0) 1f else width.toFloat() / height
        Matrix.perspectiveM(env.projection, 0, viewerFov, aspect, max(0.005f, distance * 0.01f), distance * 50f + 50f)
        UArMath.invert(env.view).copyInto(viewerCamera)
        env.cameraPosition = eye
        env.useDepth = false
    }

    private val cameraMatrix: FloatArray get() = core?.cameraMatrix ?: viewerCamera

    private fun anchorMatrix(id: String): FloatArray? = core?.anchorMatrix(id) ?: staticAnchors[id] ?: if (id == "camera") cameraMatrix else null

    private fun worldOf(
        node: UArNodeRuntime,
        depth: Int = 0,
    ): FloatArray? {
        if (node.worldFrame == frameCounter) return if (node.worldValid) node.world else null
        node.worldFrame = frameCounter
        node.worldValid = false
        if (depth > 32) return null
        val parentId = node.parentId
        val anchorId = node.anchorId
        val base: FloatArray =
            when {
                parentId != null -> nodes[parentId]?.let { worldOf(it, depth + 1) } ?: return null
                anchorId != null -> anchorMatrix(anchorId) ?: return null
                else -> UArMath.identity()
            }
        var local = UArMath.compose(node.position, node.rotation, node.scale)
        var world = UArMath.multiply(base, local)
        if (node.billboard != "none") {
            val position = UArMath.translation(world)
            val baseScale = UArMath.scaleOf(base)
            val q = UArMath.billboard(position, UArMath.translation(cameraMatrix), node.billboard == "yAxis")
            local = UArMath.compose(position, q, floatArrayOf(node.scale[0] * baseScale[0], node.scale[1] * baseScale[1], node.scale[2] * baseScale[2]))
            world = local
        }
        Matrix.multiplyMM(node.world, 0, world, 0, node.normalization, 0)
        node.worldValid = true
        return node.world
    }

    private fun drawScene(
        viewWidth: Int,
        viewHeight: Int,
    ) {
        GLES30.glViewport(0, 0, viewWidth, viewHeight)
        env.viewportWidth = viewWidth.toFloat()
        env.viewportHeight = viewHeight.toFloat()
        val session = core
        if (session == null) {
            if (config["transparentBackground"] == true) {
                GLES30.glClearColor(0f, 0f, 0f, 0f)
            } else {
                val bg = UArMath.argb(config["background"], 0xFFF2F2F2L)
                GLES30.glClearColor(bg[0], bg[1], bg[2], 1f)
            }
            GLES30.glClear(GLES30.GL_COLOR_BUFFER_BIT or GLES30.GL_DEPTH_BUFFER_BIT)
        } else {
            GLES30.glClearColor(0f, 0f, 0f, 1f)
            GLES30.glClear(GLES30.GL_COLOR_BUFFER_BIT or GLES30.GL_DEPTH_BUFFER_BIT)
            renderer.drawBackground(cameraTexture, session.backgroundUvs)
        }
        GLES30.glEnable(GLES30.GL_DEPTH_TEST)
        GLES30.glDepthFunc(GLES30.GL_LEQUAL)
        GLES30.glEnable(GLES30.GL_BLEND)
        GLES30.glBlendFuncSeparate(GLES30.GL_SRC_ALPHA, GLES30.GL_ONE_MINUS_SRC_ALPHA, GLES30.GL_ONE, GLES30.GL_ONE_MINUS_SRC_ALPHA)

        if (session != null) drawTrackables(session)
        drawShadows()

        val visible = nodes.values.filter { it.visible && it.loaded && worldOf(it) != null }
        for (node in visible) if (!node.material.renderOnTop) drawNode(node, 0)
        val camera = UArMath.translation(cameraMatrix)
        val blended =
            visible
                .filter { !it.material.renderOnTop }
                .sortedByDescending { UArMath.distance(UArMath.translation(it.world), camera) }
        for (node in blended) drawNode(node, 1)
        for (node in visible) {
            if (node.material.renderOnTop) {
                drawNode(node, 0)
                drawNode(node, 1)
            }
        }

        if (session != null && config["reticle"] == true) {
            session.centerHitMatrix?.let { matrix ->
                val distance = UArMath.distance(UArMath.translation(matrix), camera)
                val size = (0.05f + distance * 0.035f).coerceIn(0.04f, 0.3f)
                val scaled = UArMath.multiply(matrix, UArMath.compose(floatArrayOf(0f, 0.002f, 0f), floatArrayOf(0f, 0f, 0f, 1f), floatArrayOf(size, size, size)))
                renderer.drawQuad(UArMath.multiply(env.viewProjection, scaled), UArMath.argb(config["reticleColor"], 0xFFFFFFFFL), 1)
            }
        }
        GLES30.glDisable(GLES30.GL_BLEND)
    }

    private fun drawTrackables(session: UArCoreSession) {
        val style =
            when (config["planeStyle"]) {
                "dots" -> 1
                "solid" -> 2
                "outline" -> 3
                "hidden" -> -1
                else -> 0
            }
        if (style >= 0) {
            val color = UArMath.argb(config["planeColor"], 0x80FFFFFFL)
            for (plane in session.planes) renderer.drawPlane(plane.polygon, plane.model, env.viewProjection, color, style)
        }
        if (config["showFeaturePoints"] == true && session.points.isNotEmpty()) {
            renderer.drawFlat(session.points, null, GLES30.GL_POINTS, env.viewProjection, floatArrayOf(1f, 0.85f, 0.2f, 1f), 10f, true)
        }
        if (config["showFaceMesh"] == true) {
            val color = UArMath.argb(config["faceMeshColor"], 0x55FFFFFFL)
            for (face in session.faces) renderer.drawFlat(face.vertices, face.indices, GLES30.GL_TRIANGLES, env.viewProjection, color)
        }
        if (config["showWorldOrigin"] == true) {
            renderer.drawFlat(floatArrayOf(0f, 0f, 0f, 0.2f, 0f, 0f), null, GLES30.GL_LINES, env.viewProjection, floatArrayOf(1f, 0.2f, 0.2f, 1f))
            renderer.drawFlat(floatArrayOf(0f, 0f, 0f, 0f, 0.2f, 0f), null, GLES30.GL_LINES, env.viewProjection, floatArrayOf(0.2f, 1f, 0.2f, 1f))
            renderer.drawFlat(floatArrayOf(0f, 0f, 0f, 0f, 0f, 0.2f), null, GLES30.GL_LINES, env.viewProjection, floatArrayOf(0.2f, 0.4f, 1f, 1f))
        }
    }

    private fun drawShadows() {
        if (config["shadows"] == false) return
        val opacity = (config["shadowOpacity"] as? Number)?.toFloat() ?: 0.45f
        for (node in nodes.values) {
            if (!node.visible || !node.loaded || !node.castShadow || node.material.occluder) continue
            if (node.type == "image" || node.type == "video" || node.type == "plane" || node.type == "group") continue
            val world = worldOf(node) ?: continue
            val bounds = node.localBounds() ?: continue
            val (min, max) = UArMath.transformAabb(world, bounds.first, bounds.second)
            val sx = (max[0] - min[0]) * 0.62f
            val sz = (max[2] - min[2]) * 0.62f
            if (sx <= 0f || sz <= 0f) continue
            val center = floatArrayOf((min[0] + max[0]) / 2, min[1] + 0.002f, (min[2] + max[2]) / 2)
            val matrix = UArMath.compose(center, floatArrayOf(0f, 0f, 0f, 1f), floatArrayOf(sx, 1f, sz))
            renderer.drawQuad(UArMath.multiply(env.viewProjection, matrix), floatArrayOf(0f, 0f, 0f, opacity), 0)
        }
    }

    private fun drawNode(
        node: UArNodeRuntime,
        pass: Int,
    ) {
        val world = node.world
        when (node.type) {
            "model" -> node.model?.draw(renderer, world, env, pass, node.material.opacity)
            "video" -> {
                val video = node.video ?: return
                val mesh = node.mesh ?: return
                if (pass != 0) return
                renderer.drawVideo(mesh, video, UArMath.multiply(env.viewProjection, world), node.material.opacity)
            }
            "group" -> Unit
            else -> {
                val mesh = node.mesh ?: return
                val blended = node.material.isBlended || env.useDepth
                if (pass == 0 && blended || pass == 1 && !blended) return
                renderer.drawMesh(mesh, node.material, world, env, 0, 1f)
            }
        }
    }

    private fun emitFrame() {
        val payload =
            mutableMapOf<String, Any?>(
                "type" to "frame",
                "t" to SystemClock.uptimeMillis().toDouble(),
                "camera" to UArMath.poseList(cameraMatrix),
                "fov" to (core?.fov ?: viewerFov).toDouble(),
            )
        val session = core
        if (session != null) {
            payload["light"] = session.lightMap
            payload["geo"] = session.geoMap
            payload["center"] = session.centerHit
            payload["semantics"] = session.semanticsMap
        }
        northYaw?.let {
            payload["northYaw"] = it.toDouble()
            val m = cameraMatrix
            val alpha = atan2(-m[8], m[10])
            payload["heading"] = (((alpha + it) * 180 / PI) + 360) % 360
            payload["headingAccuracy"] = headingAccuracy.toDouble()
        }
        if (tracks.isNotEmpty()) payload["projections"] = projections()
        emit(payload)
    }

    private fun projections(): List<List<Any>> {
        val out = ArrayList<List<Any>>()
        val camera = UArMath.translation(cameraMatrix)
        for (track in tracks) {
            val id = track["id"] as? String ?: continue
            val offset = UArMath.floats(track["offset"], 3, 0f)
            val nodeId = track["nodeId"] as? String
            val anchorId = track["anchorId"] as? String
            val point =
                when {
                    nodeId != null -> nodes[nodeId]?.let { worldOf(it) }?.let { UArMath.transformPoint(it, offset[0], offset[1], offset[2]) }
                    anchorId != null -> anchorMatrix(anchorId)?.let { UArMath.transformPoint(it, offset[0], offset[1], offset[2]) }
                    else -> offset
                }
            if (point == null) {
                out.add(listOf(id, 0.5, 0.5, 0.0, -1))
                continue
            }
            val clip = FloatArray(4)
            Matrix.multiplyMV(clip, 0, env.viewProjection, 0, floatArrayOf(point[0], point[1], point[2], 1f), 0)
            val distance = UArMath.distance(point, camera).toDouble()
            if (clip[3] <= 0.0001f) {
                val x = if (clip[3] == 0f) 0.5 else 0.5 - clip[0] / clip[3] / 2
                out.add(listOf(id, x, 0.5, distance, -1))
                continue
            }
            val x = (clip[0] / clip[3] + 1) / 2
            val y = (1 - clip[1] / clip[3]) / 2
            val onScreen = x in 0f..1f && y in 0f..1f
            out.add(listOf(id, x.toDouble(), y.toDouble(), distance, if (onScreen) 1 else 0))
        }
        return out
    }

    // -------------------------------------------------------------------------
    // Nodes
    // -------------------------------------------------------------------------

    private fun sourceKey(map: Map<*, *>): String {
        val source = map["source"] as? Map<*, *>
        val value = source?.get("value")
        val sourcePart = if (value is ByteArray) "bytes:${value.size}:${value.contentHashCode()}" else "${source?.get("kind")}:$value"
        return "${map["type"]}|$sourcePart|${map["width"]}|${map["height"]}|${map["depth"]}|${map["radius"]}"
    }

    private fun nodeInfo(node: UArNodeRuntime): Map<String, Any?> {
        val bounds = node.localBounds() ?: Pair(floatArrayOf(0f, 0f, 0f), floatArrayOf(0f, 0f, 0f))
        node.worldFrame = -1
        val world = worldOf(node) ?: UArMath.multiply(UArMath.compose(node.position, node.rotation, node.scale), node.normalization)
        val (min, max) = UArMath.transformAabb(world, bounds.first, bounds.second)
        return mapOf(
            "id" to node.id,
            "loaded" to node.loaded,
            "min" to min.map { it.toDouble() },
            "max" to max.map { it.toDouble() },
            "animations" to (node.model?.animationNames ?: emptyList<String>()),
        )
    }

    private fun addNode(
        map: Map<*, *>,
        result: MethodChannel.Result,
    ) {
        val id = map["id"] as? String ?: return result.error("notFound", "Node id missing", null)
        val existing = nodes[id]
        val key = sourceKey(map)
        val node = existing ?: UArNodeRuntime(id)
        node.apply(map)
        nodes[id] = node
        if (existing != null && existing.sourceKey == key && existing.loaded) {
            node.updateNormalization()
            if (node.type == "model") applyAnimation(node)
            result.success(nodeInfo(node))
            return
        }
        releaseContent(node)
        node.sourceKey = key
        node.loaded = false
        when (node.type) {
            "box" -> finishPrimitive(node, UArPrimitives.box(node.width, node.height, node.depth), result)
            "sphere" -> finishPrimitive(node, UArPrimitives.sphere(node.radius), result)
            "cylinder" -> finishPrimitive(node, UArPrimitives.cylinder(node.radius, node.height, false), result)
            "cone" -> finishPrimitive(node, UArPrimitives.cylinder(node.radius, node.height, true), result)
            "plane" -> finishPrimitive(node, UArPrimitives.quad(node.width, node.height), result)
            "group" -> {
                node.loaded = true
                result.success(nodeInfo(node))
            }
            "model" -> {
                result.success(mapOf("id" to id, "loaded" to false))
                loadModel(node, map["source"] as? Map<*, *>, key)
            }
            "image" -> {
                result.success(mapOf("id" to id, "loaded" to false))
                loadImage(node, map["source"] as? Map<*, *>, key)
            }
            "video" -> {
                result.success(mapOf("id" to id, "loaded" to false))
                loadVideo(node, map["source"] as? Map<*, *>, key)
            }
            else -> result.error("unsupported", "Unknown node type ${node.type}", null)
        }
    }

    private fun finishPrimitive(
        node: UArNodeRuntime,
        data: UMeshData,
        result: MethodChannel.Result,
    ) {
        node.mesh = UGpuMesh(data)
        node.loaded = true
        result.success(nodeInfo(node))
    }

    private fun loadFailed(
        node: UArNodeRuntime,
        error: Throwable,
    ) = emit(mapOf("type" to "node", "id" to node.id, "event" to "error", "message" to (error.message ?: error.javaClass.simpleName)))

    private fun loadModel(
        node: UArNodeRuntime,
        source: Map<*, *>?,
        key: String,
    ) {
        val modelKey = key.substringBefore("|", "") + "|" + key.split("|").getOrElse(1) { "" }
        val cached = models[modelKey]
        if (cached != null) {
            attachModel(node, cached, modelKey)
            return
        }
        workers.execute {
            try {
                val loaded = loader.load(source)
                val data = UGltfParser.parse(loaded, loader)
                gl.post {
                    if (disposed || nodes[node.id] !== node || node.sourceKey != key) return@post
                    try {
                        val model = models.getOrPut(modelKey) { UModel(data) }
                        attachModel(node, model, modelKey)
                    } catch (error: Throwable) {
                        loadFailed(node, error)
                    }
                }
            } catch (error: Throwable) {
                loadFailed(node, error)
            }
        }
    }

    private fun attachModel(
        node: UArNodeRuntime,
        model: UModel,
        modelKey: String,
    ) {
        model.references++
        val instance = UModelInstance(model)
        instance.onFinished = { emit(mapOf("type" to "node", "id" to node.id, "event" to "animationEnded")) }
        node.model = instance
        node.modelKey = modelKey
        node.updateNormalization()
        applyAnimation(node)
        node.loaded = true
        emit(mapOf("type" to "node", "event" to "loaded") + nodeInfo(node))
    }

    private fun applyAnimation(node: UArNodeRuntime) {
        val animation = node.animation ?: return
        val instance = node.model ?: return
        if (animation["autoplay"] == false || instance.playing) return
        instance.play(
            animation["name"] as? String,
            (animation["index"] as? Number)?.toInt() ?: 0,
            animation["loop"] != false,
            (animation["speed"] as? Number)?.toFloat() ?: 1f,
        )
    }

    private fun loadImage(
        node: UArNodeRuntime,
        source: Map<*, *>?,
        key: String,
    ) {
        workers.execute {
            try {
                val bitmap = UArTextures.decode(loader.load(source).bytes, 2048) ?: throw IllegalStateException("Unreadable image")
                gl.post {
                    if (disposed || nodes[node.id] !== node || node.sourceKey != key) {
                        bitmap.recycle()
                        return@post
                    }
                    val texture = UArTextures.upload(bitmap, GLES30.GL_CLAMP_TO_EDGE, GLES30.GL_CLAMP_TO_EDGE)
                    val aspect = bitmap.height.toFloat() / max(1, bitmap.width)
                    bitmap.recycle()
                    node.imageTexture = texture
                    node.material.baseTexture = texture
                    node.material.alphaMode = 2
                    val h = if (node.height > 0f) node.height else node.width * aspect
                    node.mesh = UGpuMesh(UArPrimitives.quad(node.width, h))
                    node.loaded = true
                    emit(mapOf("type" to "node", "event" to "loaded") + nodeInfo(node))
                }
            } catch (error: Throwable) {
                loadFailed(node, error)
            }
        }
    }

    private fun loadVideo(
        node: UArNodeRuntime,
        source: Map<*, *>?,
        key: String,
    ) {
        workers.execute {
            try {
                val file = loader.toFile(source)
                gl.post {
                    if (disposed || nodes[node.id] !== node || node.sourceKey != key) return@post
                    try {
                        node.video = UArVideo(context, file, node.videoOptions) { emit(mapOf("type" to "node", "id" to node.id, "event" to "videoEnded")) }
                        node.mesh = UGpuMesh(UArPrimitives.quad(node.width, node.height))
                        node.loaded = true
                        emit(mapOf("type" to "node", "event" to "loaded") + nodeInfo(node))
                    } catch (error: Throwable) {
                        loadFailed(node, error)
                    }
                }
            } catch (error: Throwable) {
                loadFailed(node, error)
            }
        }
    }

    private fun releaseContent(node: UArNodeRuntime) {
        node.mesh?.release()
        node.mesh = null
        node.model?.let { instance ->
            instance.release()
            val key = node.modelKey
            val model = instance.model
            model.references--
            if (model.references <= 0 && key != null) {
                models.remove(key)
                model.release()
            }
        }
        node.model = null
        node.modelKey = null
        node.video?.release()
        node.video = null
        if (node.imageTexture != 0) UArTextures.delete(node.imageTexture)
        node.imageTexture = 0
        node.material.baseTexture = 0
        node.normalization = UArMath.identity()
    }

    private fun releaseNode(node: UArNodeRuntime) = runCatching { releaseContent(node) }

    private fun removeNode(id: String) {
        val node = nodes.remove(id) ?: return
        releaseNode(node)
        nodes.values.filter { it.parentId == id }.map { it.id }.forEach { removeNode(it) }
    }

    private fun transformNode(args: Map<*, *>) {
        val node = nodes[args["id"] as? String ?: return] ?: return
        val position = (args["position"] as? List<*>)?.let { UArMath.floats(it, 3, 0f) }
        val rotation = (args["rotation"] as? List<*>)?.let { UArMath.quatNormalize(UArMath.floats(it, 4, 0f)) }
        val scale = (args["scale"] as? List<*>)?.let { UArMath.floats(it, 3, 1f) }
        if (args["world"] == true) {
            val parent =
                when {
                    node.parentId != null -> nodes[node.parentId!!]?.let { worldOf(it) }
                    node.anchorId != null -> anchorMatrix(node.anchorId!!)
                    else -> null
                } ?: UArMath.identity()
            val inverse = UArMath.invert(parent)
            if (position != null) node.position = UArMath.transformPoint(inverse, position[0], position[1], position[2])
            if (rotation != null) node.rotation = UArMath.quatMultiply(UArMath.rotationOf(inverse), rotation)
        } else {
            if (position != null) node.position = position
            if (rotation != null) node.rotation = rotation
        }
        if (scale != null) node.scale = scale
        node.worldFrame = -1
    }

    private fun hitTestNodes(
        x: Float,
        y: Float,
    ): Map<String, Any?>? {
        val ndcX = x * 2 - 1
        val ndcY = 1 - y * 2
        val inverse = UArMath.invert(env.viewProjection)
        val near = FloatArray(4)
        val far = FloatArray(4)
        Matrix.multiplyMV(near, 0, inverse, 0, floatArrayOf(ndcX, ndcY, -1f, 1f), 0)
        Matrix.multiplyMV(far, 0, inverse, 0, floatArrayOf(ndcX, ndcY, 1f, 1f), 0)
        val origin = floatArrayOf(near[0] / near[3], near[1] / near[3], near[2] / near[3])
        val end = floatArrayOf(far[0] / far[3], far[1] / far[3], far[2] / far[3])
        val dir = floatArrayOf(end[0] - origin[0], end[1] - origin[1], end[2] - origin[2])
        val length = UArMath.length(dir)
        for (i in 0 until 3) dir[i] /= length
        var best: Pair<UArNodeRuntime, Float>? = null
        for (node in nodes.values) {
            if (!node.visible || !node.loaded || !node.hittable) continue
            val world = worldOf(node) ?: continue
            val bounds = node.localBounds() ?: continue
            val (min, max) = UArMath.transformAabb(world, bounds.first, bounds.second)
            val t = UArMath.rayAabb(origin, dir, min, max) ?: continue
            if (best == null || t < best.second) best = Pair(node, t)
        }
        val hit = best ?: return null
        val point = FloatArray(3) { origin[it] + dir[it] * hit.second }
        return mapOf("id" to hit.first.id, "position" to point.map { it.toDouble() }, "distance" to hit.second.toDouble())
    }

    // -------------------------------------------------------------------------
    // Capture
    // -------------------------------------------------------------------------

    private fun snapshotNow(
        args: Map<*, *>,
        result: MethodChannel.Result,
    ) {
        val buffer = ByteBuffer.allocateDirect(width * height * 4).order(ByteOrder.nativeOrder())
        GLES30.glReadPixels(0, 0, width, height, GLES30.GL_RGBA, GLES30.GL_UNSIGNED_BYTE, buffer)
        val w = width
        val h = height
        workers.execute {
            try {
                buffer.position(0)
                val raw = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                raw.copyPixelsFromBuffer(buffer)
                val flip = android.graphics.Matrix().apply { preScale(1f, -1f) }
                val bitmap = Bitmap.createBitmap(raw, 0, 0, w, h, flip, false)
                raw.recycle()
                val out = ByteArrayOutputStream()
                val png = args["format"] == "png"
                bitmap.compress(if (png) Bitmap.CompressFormat.PNG else Bitmap.CompressFormat.JPEG, (args["quality"] as? Number)?.toInt() ?: 92, out)
                bitmap.recycle()
                result.success(out.toByteArray())
            } catch (error: Throwable) {
                result.error("unknown", error.message, null)
            }
        }
    }

    private fun startRecording(
        audio: Boolean,
        result: MethodChannel.Result,
    ) {
        if (recorder != null) {
            result.error("unknown", "Already recording", null)
            return
        }
        try {
            val scale = min(1f, 1920f / max(width, height))
            recordWidth = ((width * scale).roundToInt() / 2) * 2
            recordHeight = ((height * scale).roundToInt() / 2) * 2
            val file = File(context.cacheDir, "u_ar_${System.currentTimeMillis()}.mp4")
            val withAudio = audio && ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
            val media = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) MediaRecorder(context) else @Suppress("DEPRECATION") MediaRecorder()
            if (withAudio) media.setAudioSource(MediaRecorder.AudioSource.MIC)
            media.setVideoSource(MediaRecorder.VideoSource.SURFACE)
            media.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            media.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
            if (withAudio) media.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            media.setVideoSize(recordWidth, recordHeight)
            media.setVideoFrameRate(30)
            media.setVideoEncodingBitRate(recordWidth * recordHeight * 6)
            media.setOutputFile(file.absolutePath)
            media.prepare()
            recorderSurface = EGL14.eglCreateWindowSurface(eglDisplay, eglConfig, media.surface, intArrayOf(EGL14.EGL_NONE), 0)
            media.start()
            recorder = media
            recordingPath = file.absolutePath
            recordingStart = SystemClock.uptimeMillis()
            result.success(null)
        } catch (error: Throwable) {
            stopRecordingInternal()
            result.error("unknown", error.message, null)
        }
    }

    private fun stopRecordingInternal(): Map<String, Any?>? {
        val media = recorder ?: return null
        recorder = null
        runCatching { media.stop() }
        runCatching { media.release() }
        if (recorderSurface != EGL14.EGL_NO_SURFACE) {
            EGL14.eglMakeCurrent(eglDisplay, pbufferSurface, pbufferSurface, eglContext)
            EGL14.eglDestroySurface(eglDisplay, recorderSurface)
            recorderSurface = EGL14.EGL_NO_SURFACE
            if (eglSurface != EGL14.EGL_NO_SURFACE) EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext)
        }
        return mapOf("path" to recordingPath, "mime" to "video/mp4", "duration" to (SystemClock.uptimeMillis() - recordingStart).toInt())
    }

    // -------------------------------------------------------------------------
    // Method calls (always executed on the GL thread)
    // -------------------------------------------------------------------------

    fun handle(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        gl.post {
            if (disposed) {
                result.error("notFound", "Session disposed", null)
                return@post
            }
            try {
                EGL14.eglMakeCurrent(
                    eglDisplay,
                    if (eglSurface != EGL14.EGL_NO_SURFACE) eglSurface else pbufferSurface,
                    if (eglSurface != EGL14.EGL_NO_SURFACE) eglSurface else pbufferSurface,
                    eglContext,
                )
                handleOnGl(call, result)
            } catch (error: Throwable) {
                result.error(UArCoreSession.errorCode(error).let { if (it == "sessionFailed") "unknown" else it }, error.message ?: error.javaClass.simpleName, null)
            }
        }
    }

    private fun handleOnGl(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
        when (call.method) {
            "start" -> start(args, result)
            "resize" -> {
                resize((args["width"] as? Number)?.toDouble() ?: 1.0, (args["height"] as? Number)?.toDouble() ?: 1.0, (args["pixelRatio"] as? Number)?.toDouble() ?: 1.0)
                result.success(null)
            }
            "pause" -> {
                paused = true
                runCatching { core?.pause() }
                emit(mapOf("type" to "state", "session" to "paused", "tracking" to "paused", "reason" to "none"))
                result.success(null)
            }
            "resume" -> {
                core?.resume()
                paused = false
                lastFrameNanos = System.nanoTime()
                emit(mapOf("type" to "state", "session" to "running", "tracking" to "limited", "reason" to "initializing"))
                result.success(null)
            }
            "reset" -> {
                val keepNodes = args["keepNodes"] == true
                core?.reset(false)
                staticAnchors.clear()
                if (!keepNodes) {
                    nodes.values.forEach { releaseNode(it) }
                    nodes.clear()
                }
                result.success(null)
            }
            "updateConfig" -> {
                val next = args["config"] as? Map<*, *> ?: emptyMap<String, Any?>()
                val oldMode = config["mode"]
                config = next
                if (next["mode"] != oldMode) {
                    result.error("unsupported", "Changing the mode needs a new session", null)
                    return
                }
                core?.configure(next, null)
                imageDatabaseKey = ""
                loadImageDatabase()
                if (next["mode"] == "geo" || next["worldAlignment"] == "gravityAndHeading") startHeading()
                result.success(null)
            }
            "hitTest" -> {
                val types = (args["types"] as? List<*>)?.filterIsInstance<String>()?.toSet() ?: setOf("plane", "depth", "point", "estimated", "instant")
                val x = ((args["x"] as? Number)?.toFloat() ?: 0.5f) * width
                val y = ((args["y"] as? Number)?.toFloat() ?: 0.5f) * height
                result.success(core?.hitTest(x, y, types) ?: emptyList<Any>())
            }
            "hitTestNodes" -> result.success(hitTestNodes((args["x"] as? Number)?.toFloat() ?: 0.5f, (args["y"] as? Number)?.toFloat() ?: 0.5f))
            "addAnchor" -> {
                val id = args["id"] as String
                val pose = (args["pose"] as List<*>).map { (it as Number).toDouble() }
                val session = core
                if (session != null) {
                    result.success(session.addAnchor(id, pose, args["trackableId"] as? String, if (args["name"] == "geo") "geo" else "world"))
                } else {
                    staticAnchors[id] = UArMath.poseMatrix(pose)
                    result.success(mapOf("id" to id, "pose" to pose, "type" to "world", "tracking" to "normal"))
                }
            }
            "updateAnchor" -> {
                val id = args["id"] as String
                val pose = (args["pose"] as List<*>).map { (it as Number).toDouble() }
                if (core?.hasAnchor(id) == true) core?.updateAnchor(id, pose) else staticAnchors[id] = UArMath.poseMatrix(pose)
                result.success(null)
            }
            "removeAnchor" -> {
                val id = args["id"] as String
                core?.removeAnchor(id)
                staticAnchors.remove(id)
                if (args["removeNodes"] != false) nodes.values.filter { it.anchorId == id }.map { it.id }.forEach { removeNode(it) }
                result.success(null)
            }
            "addNode", "updateNode" -> addNode(args["node"] as? Map<*, *> ?: emptyMap<String, Any?>(), result)
            "transformNode" -> {
                transformNode(args)
                result.success(null)
            }
            "removeNode" -> {
                removeNode(args["id"] as? String ?: "")
                result.success(null)
            }
            "clearNodes" -> {
                nodes.values.forEach { releaseNode(it) }
                nodes.clear()
                result.success(null)
            }
            "nodePose" -> {
                val node = nodes[args["id"] as? String ?: ""]
                result.success(node?.let { worldOf(it) }?.let { UArMath.poseList(it) })
            }
            "playAnimation" -> {
                nodes[args["id"] as? String ?: ""]?.model?.play(
                    args["name"] as? String,
                    (args["index"] as? Number)?.toInt() ?: 0,
                    args["loop"] != false,
                    (args["speed"] as? Number)?.toFloat() ?: 1f,
                )
                result.success(null)
            }
            "stopAnimation" -> {
                nodes[args["id"] as? String ?: ""]?.model?.stop()
                result.success(null)
            }
            "controlVideo" -> {
                nodes[args["id"] as? String ?: ""]?.video?.control(args["play"] as? Boolean, (args["seek"] as? Number)?.toInt(), (args["volume"] as? Number)?.toFloat())
                result.success(null)
            }
            "setTracks" -> {
                tracks = (args["tracks"] as? List<*>)?.filterIsInstance<Map<*, *>>() ?: emptyList()
                result.success(null)
            }
            "setOrbit" -> {
                config = config.toMutableMap().apply { put("orbit", args["orbit"]) }
                result.success(null)
            }
            "snapshot" -> {
                if (eglSurface == EGL14.EGL_NO_SURFACE || !started) {
                    result.error("unknown", "Nothing is being rendered", null)
                } else {
                    pendingSnapshot = Pair(args, result)
                }
            }
            "startRecording" -> startRecording(args["audio"] == true, result)
            "stopRecording" -> result.success(stopRecordingInternal())
            "cameraImage" -> result.success(core?.cameraImage((args["maxSize"] as? Number)?.toInt() ?: 1024))
            "addGeoAnchor" -> {
                val session = core ?: return result.error("unsupported", "Geospatial needs an AR session", null)
                session.addGeoAnchor(
                    args["id"] as String,
                    (args["latitude"] as Number).toDouble(),
                    (args["longitude"] as Number).toDouble(),
                    (args["altitude"] as? Number)?.toDouble() ?: 0.0,
                    args["altitudeMode"] as? String ?: "terrain",
                    (args["heading"] as? Number)?.toDouble() ?: 0.0,
                ) { anchor, error -> if (anchor != null) result.success(anchor) else result.error(if (error == "unsupported") "unsupported" else "notAuthorized", error, null) }
            }
            "checkVps" -> {
                val session = core ?: return result.success("unknown")
                session.checkVps((args["latitude"] as Number).toDouble(), (args["longitude"] as Number).toDouble()) { result.success(it) }
            }
            "hostCloudAnchor" -> {
                val session = core ?: return result.error("unsupported", "Cloud anchors need an AR session", null)
                session.hostCloudAnchor(args["id"] as String, (args["ttlDays"] as? Number)?.toInt() ?: 1) { cloudId, error ->
                    if (cloudId != null) result.success(cloudId) else result.error("notAuthorized", error, null)
                }
            }
            "resolveCloudAnchor" -> {
                val session = core ?: return result.error("unsupported", "Cloud anchors need an AR session", null)
                session.resolveCloudAnchor(args["cloudId"] as String, args["id"] as String) { anchor, error ->
                    if (anchor != null) result.success(anchor) else result.error("notFound", error, null)
                }
            }
            "updateLocation" -> {
                val latitude = (args["latitude"] as? Number)?.toFloat() ?: 0f
                val longitude = (args["longitude"] as? Number)?.toFloat() ?: 0f
                val altitude = (args["altitude"] as? Number)?.toFloat() ?: 0f
                declination = GeomagneticField(latitude, longitude, altitude, System.currentTimeMillis()).declination
                startHeading()
                result.success(null)
            }
            "getWorldMap", "collaborationData", "recognizeText", "detectBarcodes", "enterXr", "exitXr" ->
                result.error("unsupported", "${call.method} is not available on Android", null)
            else -> result.notImplemented()
        }
    }
}

// =============================================================================
// Method channel front end
// =============================================================================

internal class UArHandler(
    private val context: Context,
    private val messenger: BinaryMessenger,
    private val textureRegistry: TextureRegistry,
) : MethodChannel.MethodCallHandler,
    PluginRegistry.RequestPermissionsResultListener,
    Application.ActivityLifecycleCallbacks {
    private val channel = MethodChannel(messenger, "u/ar")
    private val sessions = mutableMapOf<Int, UArSession>()
    private val background = Executors.newSingleThreadExecutor()
    private var nextId = 1
    private var activity: Activity? = null
    private var permissionResult: MethodChannel.Result? = null
    private var probed: Map<String, Any?>? = null

    init {
        channel.setMethodCallHandler(this)
    }

    fun setActivity(value: Activity?) {
        activity?.application?.unregisterActivityLifecycleCallbacks(this)
        activity = value
        value?.application?.registerActivityLifecycleCallbacks(this)
    }

    fun dispose() {
        runCatching { channel.setMethodCallHandler(null) }
        sessions.values.forEach { runCatching { it.dispose() } }
        sessions.clear()
        runCatching { permissionResult?.success(permissionMap()) }
        permissionResult = null
        setActivity(null)
        background.shutdownNow()
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val safe = USafeResult(result)
        try {
            when (call.method) {
                "availability" -> background.execute { safe.success(availability()) }
                "requestInstall" -> {
                    val current = activity
                    if (current == null || !UArCoreSession.sdkPresent()) {
                        safe.success(availability())
                    } else {
                        UArCoreSession.requestInstall(current)
                        background.execute { safe.success(availability()) }
                    }
                }
                "permissionStatus" -> safe.success(permissionMap())
                "requestPermission" -> requestPermission(call.argument<Boolean>("location") == true, call.argument<Boolean>("microphone") == true, safe)
                "openSettings" -> safe.success(openSettings())
                "openNativeViewer" -> safe.success(openNativeViewer(call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()))
                "scanRoom", "captureObject" -> safe.error("unsupported", "${call.method} needs iOS with LiDAR", null)
                "create" -> {
                    val config = call.argument<Map<String, Any?>>("config") ?: emptyMap()
                    val id = nextId++
                    val session = UArSession(id, context, messenger, textureRegistry, config) { activity }
                    sessions[id] = session
                    safe.success(mapOf("sessionId" to id, "textureId" to session.textureId))
                }
                "dispose" -> {
                    val id = call.argument<Int>("sessionId")
                    if (id != null) sessions.remove(id)?.dispose()
                    safe.success(null)
                }
                else -> {
                    val id = call.argument<Int>("sessionId")
                    val session = if (id == null) null else sessions[id]
                    if (session == null) {
                        safe.error("notFound", "AR session not found", null)
                    } else {
                        session.handle(call, safe)
                    }
                }
            }
        } catch (error: Throwable) {
            safe.error("unknown", error.message ?: "AR call failed", null)
        }
    }

    private fun availability(): Map<String, Any?> {
        if (!UArCoreSession.sdkPresent()) {
            return mapOf(
                "status" to "sdkMissing",
                "message" to "Add implementation(\"com.google.ar:core:1.45.0\") to android/app/build.gradle to enable AR",
                "capabilities" to viewerCapabilities(),
            )
        }
        val status = UArCoreSession.availability(context)
        val caps = HashMap(viewerCapabilities())
        if (status == "supported") {
            val probe = probed ?: UArCoreSession.probe(context).also { probed = it }
            caps.putAll(
                mapOf(
                    "worldTracking" to true,
                    "planeHorizontal" to true,
                    "planeVertical" to true,
                    "imageTracking" to true,
                    "faceTracking" to context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_FRONT),
                    "depth" to (probe["depth"] == true),
                    "geospatial" to (probe["geospatial"] == true),
                    "semantics" to (probe["semantics"] == true),
                    "gpsGeo" to true,
                    "cloudAnchors" to true,
                    "lightEstimation" to true,
                    "environmentHdr" to true,
                    "instantPlacement" to true,
                    "recording" to true,
                    "cameraImage" to true,
                ),
            )
        }
        return mapOf("status" to status, "capabilities" to caps)
    }

    private fun permissionName(permission: String): String =
        if (ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED) "granted" else "denied"

    private fun permissionMap(): Map<String, Any?> =
        mapOf(
            "camera" to permissionName(Manifest.permission.CAMERA),
            "location" to permissionName(Manifest.permission.ACCESS_FINE_LOCATION),
            "microphone" to permissionName(Manifest.permission.RECORD_AUDIO),
        )

    private fun requestPermission(
        location: Boolean,
        microphone: Boolean,
        result: MethodChannel.Result,
    ) {
        val current = activity
        if (current == null) {
            result.success(permissionMap())
            return
        }
        val wanted = mutableListOf(Manifest.permission.CAMERA)
        if (location) {
            wanted.add(Manifest.permission.ACCESS_FINE_LOCATION)
            wanted.add(Manifest.permission.ACCESS_COARSE_LOCATION)
        }
        if (microphone) wanted.add(Manifest.permission.RECORD_AUDIO)
        val missing = wanted.filter { ContextCompat.checkSelfPermission(context, it) != PackageManager.PERMISSION_GRANTED }
        if (missing.isEmpty()) {
            result.success(permissionMap())
            return
        }
        permissionResult = result
        ActivityCompat.requestPermissions(current, missing.toTypedArray(), AR_PERMISSION_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != AR_PERMISSION_REQUEST) return false
        val pending = permissionResult ?: return true
        permissionResult = null
        val map = permissionMap().toMutableMap()
        val current = activity
        if (current != null && map["camera"] == "denied" && !ActivityCompat.shouldShowRequestPermissionRationale(current, Manifest.permission.CAMERA)) {
            map["camera"] = "permanentlyDenied"
        }
        pending.success(map)
        return true
    }

    private fun openSettings(): Boolean {
        val current = activity ?: return false
        return runCatching {
            current.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", context.packageName, null)))
            true
        }.getOrDefault(false)
    }

    private fun openNativeViewer(args: Map<*, *>): Boolean {
        val current = activity ?: return false
        val source = args["source"] as? Map<*, *>
        val url = if (source?.get("kind") == "url") source["value"] as? String else null
        val fallback = args["fallbackUrl"] as? String
        if (url == null) return false
        fun viewerUri(mode: String): Uri {
            val builder =
                Uri
                    .parse("https://arvr.google.com/scene-viewer/1.0")
                    .buildUpon()
                    .appendQueryParameter("file", url)
                    .appendQueryParameter("mode", mode)
            (args["title"] as? String)?.let { builder.appendQueryParameter("title", it) }
            (args["link"] as? String)?.let { builder.appendQueryParameter("link", it) }
            if (args["resizable"] == false) builder.appendQueryParameter("resizable", "false")
            return builder.build()
        }
        val preferred = if (args["arFirst"] == false) "3d_preferred" else "ar_preferred"
        val attempts =
            listOf(
                Intent(Intent.ACTION_VIEW, viewerUri(preferred)).setPackage("com.google.android.googlequicksearchbox"),
                Intent(Intent.ACTION_VIEW, viewerUri("ar_only")).setPackage("com.google.ar.core"),
            )
        for (intent in attempts) {
            intent.putExtra("browser_fallback_url", fallback ?: url)
            if (runCatching { current.startActivity(intent) }.isSuccess) return true
        }
        if (fallback != null) return runCatching { current.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(fallback))) }.isSuccess
        return false
    }

    override fun onActivityPaused(activity: Activity) {
        if (activity === this.activity) sessions.values.forEach { it.onHostPause() }
    }

    override fun onActivityResumed(activity: Activity) {
        if (activity === this.activity) sessions.values.forEach { it.onHostResume() }
    }

    override fun onActivityCreated(
        activity: Activity,
        savedInstanceState: Bundle?,
    ) = Unit

    override fun onActivityStarted(activity: Activity) = Unit

    override fun onActivityStopped(activity: Activity) = Unit

    override fun onActivitySaveInstanceState(
        activity: Activity,
        outState: Bundle,
    ) = Unit

    override fun onActivityDestroyed(activity: Activity) = Unit

    companion object {
        fun viewerCapabilities(): Map<String, Any?> =
            mapOf(
                "platform" to "android",
                "viewer" to true,
                "nativeViewer" to true,
                "snapshot" to true,
                "recording" to true,
                "formats" to listOf("glb", "gltf"),
            )
    }
}
