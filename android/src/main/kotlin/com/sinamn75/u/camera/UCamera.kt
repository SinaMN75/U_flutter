package com.sinamn75.u.camera

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.SurfaceTexture
import android.graphics.YuvImage
import android.hardware.display.DisplayManager
import android.hardware.camera2.CameraCaptureSession
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraDevice
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraMetadata
import android.hardware.camera2.CaptureRequest
import android.hardware.camera2.CaptureResult
import android.hardware.camera2.TotalCaptureResult
import android.hardware.camera2.params.MeteringRectangle
import android.hardware.camera2.params.StreamConfigurationMap
import android.media.CamcorderProfile
import android.media.Image
import android.media.ImageReader
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.provider.Settings
import android.util.Range
import android.util.Size
import android.view.OrientationEventListener
import android.view.Surface
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.TextureRegistry
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

private const val PERMISSION_REQUEST_CODE = 75011

/** Maps Dart config names onto Camera2 constants and back. */
internal object UCameraMapper {
    fun facingName(lensFacing: Int): String =
        when (lensFacing) {
            CameraCharacteristics.LENS_FACING_FRONT -> "front"
            CameraCharacteristics.LENS_FACING_BACK -> "back"
            CameraCharacteristics.LENS_FACING_EXTERNAL -> "external"
            else -> "unspecified"
        }

    fun lensName(
        focalLength: Float,
        focalLengths: FloatArray,
    ): String {
        if (focalLengths.isEmpty()) return "unknown"
        val shortest = focalLengths.min()
        val longest = focalLengths.max()
        return when {
            focalLengths.size == 1 -> "wide"
            focalLength <= shortest + 0.01f && shortest < longest -> "ultraWide"
            focalLength >= longest - 0.01f && shortest < longest -> "telephoto"
            else -> "wide"
        }
    }

    fun targetSize(resolution: String?): Size =
        when (resolution) {
            "low" -> Size(320, 240)
            "medium" -> Size(640, 480)
            "veryHigh" -> Size(1920, 1080)
            "ultraHigh" -> Size(3840, 2160)
            "max" -> Size(Int.MAX_VALUE, Int.MAX_VALUE)
            else -> Size(1280, 720)
        }

    fun chooseSize(
        available: Array<Size>?,
        target: Size,
    ): Size {
        if (available == null || available.isEmpty()) return Size(1280, 720)
        if (target.width == Int.MAX_VALUE) return available.maxByOrNull { it.width.toLong() * it.height } ?: available[0]
        val targetPixels = target.width.toLong() * target.height
        return available.minByOrNull { candidate ->
            val pixels = candidate.width.toLong() * candidate.height
            kotlin.math.abs(pixels - targetPixels)
        } ?: available[0]
    }

    fun flashMode(name: String?): Int =
        when (name) {
            "auto" -> CameraMetadata.CONTROL_AE_MODE_ON_AUTO_FLASH
            "on" -> CameraMetadata.CONTROL_AE_MODE_ON_ALWAYS_FLASH
            else -> CameraMetadata.CONTROL_AE_MODE_ON
        }

    fun focusMode(name: String?): Int =
        when (name) {
            "continuousVideo" -> CameraMetadata.CONTROL_AF_MODE_CONTINUOUS_VIDEO
            "macro" -> CameraMetadata.CONTROL_AF_MODE_MACRO
            "auto" -> CameraMetadata.CONTROL_AF_MODE_AUTO
            "manual", "infinity" -> CameraMetadata.CONTROL_AF_MODE_OFF
            else -> CameraMetadata.CONTROL_AF_MODE_CONTINUOUS_PICTURE
        }

    fun whiteBalanceMode(name: String?): Int =
        when (name) {
            "incandescent" -> CameraMetadata.CONTROL_AWB_MODE_INCANDESCENT
            "fluorescent" -> CameraMetadata.CONTROL_AWB_MODE_FLUORESCENT
            "warmFluorescent" -> CameraMetadata.CONTROL_AWB_MODE_WARM_FLUORESCENT
            "daylight" -> CameraMetadata.CONTROL_AWB_MODE_DAYLIGHT
            "cloudy" -> CameraMetadata.CONTROL_AWB_MODE_CLOUDY_DAYLIGHT
            "twilight" -> CameraMetadata.CONTROL_AWB_MODE_TWILIGHT
            "shade" -> CameraMetadata.CONTROL_AWB_MODE_SHADE
            "manual", "locked" -> CameraMetadata.CONTROL_AWB_MODE_OFF
            else -> CameraMetadata.CONTROL_AWB_MODE_AUTO
        }

    fun videoEncoder(name: String?): Int =
        when (name) {
            "hevc" -> MediaRecorder.VideoEncoder.HEVC
            "vp8" -> MediaRecorder.VideoEncoder.VP8
            "vp9" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) MediaRecorder.VideoEncoder.VP9 else MediaRecorder.VideoEncoder.H264
            "av1" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) MediaRecorder.VideoEncoder.AV1 else MediaRecorder.VideoEncoder.H264
            else -> MediaRecorder.VideoEncoder.H264
        }

    fun containerFormat(name: String?): Int =
        when (name) {
            "webm" -> MediaRecorder.OutputFormat.WEBM
            else -> MediaRecorder.OutputFormat.MPEG_4
        }

    fun permissionName(status: Int): String = if (status == PackageManager.PERMISSION_GRANTED) "granted" else "denied"
}

/**
 * One open camera. Owns the device, the capture session, the preview texture,
 * the analysis reader, the still reader and the recorder.
 */
@Suppress("TooManyFunctions")
internal class UCameraSession(
    private val id: Int,
    private val context: Context,
    messenger: BinaryMessenger,
    textureRegistry: TextureRegistry,
    private val config: Map<*, *>,
    private val activityProvider: () -> Activity? = { null },
) : EventChannel.StreamHandler {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val eventChannel = EventChannel(messenger, "u/camera/events/$id")
    private val frameChannel = EventChannel(messenger, "u/camera/frames/$id")
    private var eventSink: EventChannel.EventSink? = null
    private var frameSink: EventChannel.EventSink? = null

    private val background = HandlerThread("u-camera-$id").apply { start() }
    private val handler = Handler(background.looper)

    private val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
    private val surfaceProducer: TextureRegistry.SurfaceProducer = textureRegistry.createSurfaceProducer()

    private var cameraId: String = ""
    private lateinit var characteristics: CameraCharacteristics
    private var device: CameraDevice? = null
    private var session: CameraCaptureSession? = null
    private var requestBuilder: CaptureRequest.Builder? = null

    private var previewSize: Size = Size(1280, 720)
    private var stillSize: Size = Size(1920, 1080)
    private var analysisSize: Size = Size(640, 480)

    private var stillReader: ImageReader? = null
    private var analysisReader: ImageReader? = null
    private var recorder: MediaRecorder? = null
    private var recordingPath: String? = null
    private var recordingStartedAt = 0L

    private var streamingFrames = false
    private var frameFormat = "nv21"
    private var frameIntervalMs = 80L
    private var frameDownscale = 1
    private var lastFrameAt = 0L

    private var zoomRatio = 1f
    private var maxZoom = 1f
    private var flashName = "off"
    private var torchOn = false
    private var previewPaused = false
    private var lockedRotation: Int? = null

    private var orientationListener: OrientationEventListener? = null
    private var displayListener: DisplayManager.DisplayListener? = null
    private var deviceRotation = 0
    private var displayRotation = 0
    private var disposed = false

    val textureId: Long get() = surfaceProducer.id()

    init {
        eventChannel.setStreamHandler(this)
        frameChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?,
                ) {
                    frameSink = events
                }

                override fun onCancel(arguments: Any?) {
                    frameSink = null
                }
            },
        )
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

    private fun send(payload: Map<String, Any?>) {
        if (disposed) return
        mainHandler.post { runCatching { eventSink?.success(payload) } }
    }

    private fun sendFrame(payload: Map<String, Any?>) {
        if (disposed) return
        mainHandler.post { runCatching { frameSink?.success(payload) } }
    }

    private fun <T> once(callback: (T?, String?) -> Unit): (T?, String?) -> Unit {
        val delivered = AtomicBoolean(false)
        return { value, error ->
            if (delivered.compareAndSet(false, true)) {
                mainHandler.post { runCatching { callback(value, error) } }
            }
        }
    }

    private fun onceError(callback: (String?) -> Unit): (String?) -> Unit {
        val delivered = AtomicBoolean(false)
        return { error ->
            if (delivered.compareAndSet(false, true)) {
                mainHandler.post { runCatching { callback(error) } }
            }
        }
    }

    private fun stringConfig(key: String): String? = config[key] as? String

    private fun boolConfig(
        key: String,
        fallback: Boolean,
    ): Boolean = config[key] as? Boolean ?: fallback

    private fun intConfig(key: String): Int? = (config[key] as? Number)?.toInt()

    // -------------------------------------------------------------------------
    // Open / close
    // -------------------------------------------------------------------------

    fun open(onReady: (Map<String, Any?>?, String?) -> Unit) {
        val ready = once(onReady)
        try {
            cameraId = resolveCameraId()
            characteristics = manager.getCameraCharacteristics(cameraId)
            configureSizes()
            startOrientationListener()
            startDisplayListener()
        } catch (error: Exception) {
            ready(null, error.message ?: "unknown")
            return
        }

        if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            ready(null, "permission")
            return
        }

        try {
            manager.openCamera(
                cameraId,
                object : CameraDevice.StateCallback() {
                    override fun onOpened(camera: CameraDevice) {
                        if (disposed) {
                            runCatching { camera.close() }
                            ready(null, "disposed")
                            return
                        }
                        device = camera
                        createSession { error ->
                            if (error == null) {
                                ready(runCatching { describe() }.getOrNull(), null)
                            } else {
                                ready(null, error)
                            }
                        }
                    }

                    override fun onDisconnected(camera: CameraDevice) {
                        runCatching { camera.close() }
                        device = null
                        send(mapOf("event" to "disconnected"))
                        ready(null, "disconnected")
                    }

                    override fun onError(
                        camera: CameraDevice,
                        error: Int,
                    ) {
                        runCatching { camera.close() }
                        device = null
                        val code = if (error == ERROR_CAMERA_IN_USE || error == ERROR_MAX_CAMERAS_IN_USE) "inUse" else "unknown"
                        send(mapOf("event" to "error", "code" to code, "message" to "Camera error $error"))
                        ready(null, code)
                    }
                },
                handler,
            )
        } catch (error: SecurityException) {
            ready(null, "permission")
        } catch (error: Exception) {
            ready(null, error.message ?: "unknown")
        }
    }

    private fun resolveCameraId(): String {
        val explicit = stringConfig("deviceId")
        if (!explicit.isNullOrEmpty() && manager.cameraIdList.contains(explicit)) return explicit
        val wanted =
            when (stringConfig("facing")) {
                "front" -> CameraCharacteristics.LENS_FACING_FRONT
                "external" -> CameraCharacteristics.LENS_FACING_EXTERNAL
                else -> CameraCharacteristics.LENS_FACING_BACK
            }
        for (candidate in manager.cameraIdList) {
            val facing = manager.getCameraCharacteristics(candidate).get(CameraCharacteristics.LENS_FACING)
            if (facing == wanted) return candidate
        }
        return manager.cameraIdList.firstOrNull() ?: throw IllegalArgumentException("No camera available")
    }

    private fun configureSizes() {
        val map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP) ?: return
        previewSize = UCameraMapper.chooseSize(map.getOutputSizes(SurfaceTexture::class.java), UCameraMapper.targetSize(stringConfig("resolution")))
        stillSize = UCameraMapper.chooseSize(map.getOutputSizes(ImageFormat.JPEG), UCameraMapper.targetSize(stringConfig("photoResolution")))
        val analysisTarget = Size(previewSize.width / max(1, frameDownscale), previewSize.height / max(1, frameDownscale))
        analysisSize = UCameraMapper.chooseSize(map.getOutputSizes(ImageFormat.YUV_420_888), Size(min(analysisTarget.width, 1280), min(analysisTarget.height, 720)))
        maxZoom = characteristics.get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM) ?: 1f
        frameDownscale = max(1, intConfig("frameDownscale") ?: 1)
        frameIntervalMs = ((1000.0 / max(1.0, (config["frameMaxFps"] as? Number)?.toDouble() ?: 12.0)).toLong())
        frameFormat = stringConfig("frameFormat") ?: "nv21"
    }

    private fun createSession(onReady: (String?) -> Unit) {
        val ready = onceError(onReady)
        val camera = device
        if (camera == null || disposed) {
            ready("notFound")
            return
        }

        val prepared =
            runCatching {
                surfaceProducer.setSize(previewSize.width, previewSize.height)
                val preview = surfaceProducer.surface

                runCatching { stillReader?.close() }
                val still = ImageReader.newInstance(stillSize.width, stillSize.height, ImageFormat.JPEG, 2)
                stillReader = still

                runCatching { analysisReader?.close() }
                val analysis =
                    ImageReader.newInstance(analysisSize.width, analysisSize.height, ImageFormat.YUV_420_888, 2).apply {
                        setOnImageAvailableListener({ reader -> onAnalysisImage(reader) }, handler)
                    }
                analysisReader = analysis

                val surfaces = mutableListOf(preview, still.surface, analysis.surface)
                recorder?.let { surfaces.add(it.surface) }
                Pair(preview, surfaces)
            }.getOrNull()

        if (prepared == null) {
            ready("configuration")
            return
        }
        val previewSurface = prepared.first
        val targets = prepared.second

        try {
            @Suppress("DEPRECATION")
            camera.createCaptureSession(
                targets,
                object : CameraCaptureSession.StateCallback() {
                    override fun onConfigured(configured: CameraCaptureSession) {
                        if (disposed) {
                            runCatching { configured.close() }
                            ready("disposed")
                            return
                        }
                        session = configured
                        buildRequest(previewSurface)
                        startRepeating()
                        ready(null)
                    }

                    override fun onConfigureFailed(configured: CameraCaptureSession) {
                        ready("configuration")
                    }
                },
                handler,
            )
        } catch (error: Exception) {
            ready(error.message ?: "configuration")
        }
    }

    private fun buildRequest(previewSurface: Surface) {
        runCatching { buildRequestInternal(previewSurface) }
    }

    private fun buildRequestInternal(previewSurface: Surface) {
        val camera = device ?: return
        val template = if (recorder != null) CameraDevice.TEMPLATE_RECORD else CameraDevice.TEMPLATE_PREVIEW
        val builder = camera.createCaptureRequest(template)
        builder.addTarget(previewSurface)
        recorder?.let { builder.addTarget(it.surface) }
        if (streamingFrames) analysisReader?.let { builder.addTarget(it.surface) }

        builder.set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO)
        builder.set(CaptureRequest.CONTROL_AF_MODE, UCameraMapper.focusMode(stringConfig("focusMode")))
        builder.set(CaptureRequest.CONTROL_AE_MODE, UCameraMapper.flashMode(flashName))
        builder.set(CaptureRequest.CONTROL_AWB_MODE, UCameraMapper.whiteBalanceMode(stringConfig("whiteBalance")))
        if (torchOn) builder.set(CaptureRequest.FLASH_MODE, CameraMetadata.FLASH_MODE_TORCH)
        applyStabilization(builder, stringConfig("stabilization"))
        (config["fps"] as? Number)?.let { fps ->
            builder.set(CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE, Range(fps.toInt(), fps.toInt()))
        }
        (config["initialZoom"] as? Number)?.let { setZoomInternal(builder, it.toFloat()) }
        requestBuilder = builder
    }

    private fun applyStabilization(
        builder: CaptureRequest.Builder,
        mode: String?,
    ) {
        val available = characteristics.get(CameraCharacteristics.CONTROL_AVAILABLE_VIDEO_STABILIZATION_MODES) ?: intArrayOf()
        val wantsOn = mode != null && mode != "off"
        if (wantsOn && available.contains(CameraMetadata.CONTROL_VIDEO_STABILIZATION_MODE_ON)) {
            builder.set(CaptureRequest.CONTROL_VIDEO_STABILIZATION_MODE, CameraMetadata.CONTROL_VIDEO_STABILIZATION_MODE_ON)
        }
        val opticalModes = characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_OPTICAL_STABILIZATION) ?: intArrayOf()
        if (wantsOn && opticalModes.contains(CameraMetadata.LENS_OPTICAL_STABILIZATION_MODE_ON)) {
            builder.set(CaptureRequest.LENS_OPTICAL_STABILIZATION_MODE, CameraMetadata.LENS_OPTICAL_STABILIZATION_MODE_ON)
        }
    }

    private fun startRepeating() {
        val current = session ?: return
        val builder = requestBuilder ?: return
        if (previewPaused) {
            runCatching { current.stopRepeating() }
            return
        }
        runCatching { current.setRepeatingRequest(builder.build(), null, handler) }
    }

    fun dispose() {
        if (disposed) return
        disposed = true
        runCatching { orientationListener?.disable() }
        orientationListener = null
        runCatching {
            displayListener?.let { (context.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager)?.unregisterDisplayListener(it) }
        }
        displayListener = null
        runCatching { session?.stopRepeating() }
        runCatching { session?.close() }
        session = null
        runCatching { recorder?.stop() }
        runCatching { recorder?.release() }
        recorder = null
        recordingPath = null
        runCatching { stillReader?.setOnImageAvailableListener(null, handler) }
        runCatching { stillReader?.close() }
        stillReader = null
        runCatching { analysisReader?.setOnImageAvailableListener(null, handler) }
        runCatching { analysisReader?.close() }
        analysisReader = null
        runCatching { device?.close() }
        device = null
        requestBuilder = null
        runCatching { surfaceProducer.release() }
        runCatching { eventChannel.setStreamHandler(null) }
        runCatching { frameChannel.setStreamHandler(null) }
        eventSink = null
        frameSink = null
        runCatching { background.quitSafely() }
    }

    // -------------------------------------------------------------------------
    // Description
    // -------------------------------------------------------------------------

    fun describe(): Map<String, Any?> =
        mapOf(
            "sessionId" to id,
            "textureId" to textureId,
            "previewSize" to mapOf("width" to previewSize.width, "height" to previewSize.height),
            "sensorOrientation" to (characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 0),
            "displayRotation" to displayRotation,
            "mirrored" to (characteristics.get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_FRONT),
            "zoom" to zoomRatio.toDouble(),
            "device" to UCameraEnumerator.describeDevice(manager, cameraId),
            "capabilities" to describeCapabilities(),
        )

    private fun describeCapabilities(): Map<String, Any?> {
        val hasFlash = characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
        val exposureRange = characteristics.get(CameraCharacteristics.CONTROL_AE_COMPENSATION_RANGE)
        val exposureStep = characteristics.get(CameraCharacteristics.CONTROL_AE_COMPENSATION_STEP)
        val isoRange = characteristics.get(CameraCharacteristics.SENSOR_INFO_SENSITIVITY_RANGE)
        val exposureTime = characteristics.get(CameraCharacteristics.SENSOR_INFO_EXPOSURE_TIME_RANGE)
        val minFocus = characteristics.get(CameraCharacteristics.LENS_INFO_MINIMUM_FOCUS_DISTANCE) ?: 0f
        val afRegions = characteristics.get(CameraCharacteristics.CONTROL_MAX_REGIONS_AF) ?: 0
        val aeRegions = characteristics.get(CameraCharacteristics.CONTROL_MAX_REGIONS_AE) ?: 0
        val capabilities = characteristics.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES) ?: intArrayOf()
        val manualSensor = capabilities.contains(CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_MANUAL_SENSOR)
        val raw = capabilities.contains(CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_RAW)
        val depth = capabilities.contains(CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_DEPTH_OUTPUT)
        val stabilizationModes = characteristics.get(CameraCharacteristics.CONTROL_AVAILABLE_VIDEO_STABILIZATION_MODES) ?: intArrayOf()
        val sceneModes = characteristics.get(CameraCharacteristics.CONTROL_AVAILABLE_SCENE_MODES) ?: intArrayOf()

        val zoomUpper =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                characteristics.get(CameraCharacteristics.CONTROL_ZOOM_RATIO_RANGE)?.upper ?: maxZoom
            } else {
                maxZoom
            }

        return mapOf(
            "flash" to hasFlash,
            "torch" to hasFlash,
            "zoom" to range(1.0, zoomUpper.toDouble(), supported = zoomUpper > 1f),
            "exposureOffset" to
                range(
                    (exposureRange?.lower ?: 0).toDouble() * (exposureStep?.toDouble() ?: 1.0),
                    (exposureRange?.upper ?: 0).toDouble() * (exposureStep?.toDouble() ?: 1.0),
                    supported = exposureRange != null && exposureRange.upper > exposureRange.lower,
                ),
            "iso" to range((isoRange?.lower ?: 0).toDouble(), (isoRange?.upper ?: 0).toDouble(), supported = manualSensor && isoRange != null),
            "exposureDuration" to
                range(
                    (exposureTime?.lower ?: 0L).toDouble() / 1000.0,
                    (exposureTime?.upper ?: 0L).toDouble() / 1000.0,
                    supported = manualSensor && exposureTime != null,
                ),
            "focusDistance" to range(0.0, minFocus.toDouble(), supported = minFocus > 0f),
            "temperature" to range(2000.0, 8000.0, supported = false),
            "focusPoint" to (afRegions > 0),
            "exposurePoint" to (aeRegions > 0),
            "manualFocus" to (minFocus > 0f),
            "manualExposure" to manualSensor,
            "whiteBalance" to true,
            "stabilization" to
                buildList {
                    add("off")
                    add("auto")
                    if (stabilizationModes.contains(CameraMetadata.CONTROL_VIDEO_STABILIZATION_MODE_ON)) add("standard")
                },
            "hdr" to sceneModes.contains(CameraMetadata.CONTROL_SCENE_MODE_HDR),
            "nightMode" to sceneModes.contains(CameraMetadata.CONTROL_SCENE_MODE_NIGHT),
            "rawCapture" to raw,
            "depthCapture" to depth,
            "videoRecording" to true,
            "pauseRecording" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N),
            "audioRecording" to true,
            "imageStream" to true,
            "platformScanning" to false,
            "multiCamera" to capabilities.contains(CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_LOGICAL_MULTI_CAMERA),
            "pictureInPicture" to false,
            "lensSwitching" to capabilities.contains(CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_LOGICAL_MULTI_CAMERA),
            "orientationLock" to true,
            "snapshot" to true,
            "videoCodecs" to listOf("h264", "hevc"),
            "photoFormats" to listOf("jpeg", "png"),
            "frameFormats" to listOf("nv21", "yuv420", "gray8"),
            "maxPhotoSize" to mapOf("width" to stillSize.width, "height" to stillSize.height),
            "maxVideoSize" to mapOf("width" to previewSize.width, "height" to previewSize.height),
            "maxFps" to 60.0,
        )
    }

    private fun range(
        min: Double,
        max: Double,
        supported: Boolean = true,
    ): Map<String, Any?> = mapOf("min" to min, "max" to max, "step" to 0.0, "supported" to supported)

    // -------------------------------------------------------------------------
    // Controls
    // -------------------------------------------------------------------------

    fun setFlashMode(mode: String?) {
        flashName = mode ?: "off"
        val builder = requestBuilder ?: return
        torchOn = mode == "torch"
        builder.set(CaptureRequest.CONTROL_AE_MODE, UCameraMapper.flashMode(mode))
        builder.set(CaptureRequest.FLASH_MODE, if (torchOn) CameraMetadata.FLASH_MODE_TORCH else CameraMetadata.FLASH_MODE_OFF)
        startRepeating()
        send(mapOf("event" to "torch", "on" to torchOn))
    }

    fun setTorch(on: Boolean) {
        torchOn = on
        val builder = requestBuilder ?: return
        builder.set(CaptureRequest.FLASH_MODE, if (on) CameraMetadata.FLASH_MODE_TORCH else CameraMetadata.FLASH_MODE_OFF)
        startRepeating()
        send(mapOf("event" to "torch", "on" to on))
    }

    fun setZoom(zoom: Float) {
        val builder = requestBuilder ?: return
        setZoomInternal(builder, zoom)
        startRepeating()
        send(mapOf("event" to "zoom", "zoom" to zoomRatio.toDouble()))
    }

    private fun setZoomInternal(
        builder: CaptureRequest.Builder,
        zoom: Float,
    ) {
        zoomRatio = zoom.coerceAtLeast(1f)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val supported = characteristics.get(CameraCharacteristics.CONTROL_ZOOM_RATIO_RANGE)
            if (supported != null) {
                zoomRatio = zoomRatio.coerceIn(supported.lower, supported.upper)
                builder.set(CaptureRequest.CONTROL_ZOOM_RATIO, zoomRatio)
                return
            }
        }
        zoomRatio = zoomRatio.coerceIn(1f, maxZoom)
        val sensor = characteristics.get(CameraCharacteristics.SENSOR_INFO_ACTIVE_ARRAY_SIZE) ?: return
        val cropWidth = (sensor.width() / zoomRatio).roundToInt()
        val cropHeight = (sensor.height() / zoomRatio).roundToInt()
        val left = (sensor.width() - cropWidth) / 2
        val top = (sensor.height() - cropHeight) / 2
        builder.set(CaptureRequest.SCALER_CROP_REGION, Rect(left, top, left + cropWidth, top + cropHeight))
    }

    fun setExposureOffset(offset: Double) {
        val builder = requestBuilder ?: return
        val step = characteristics.get(CameraCharacteristics.CONTROL_AE_COMPENSATION_STEP)?.toDouble() ?: 1.0
        val range = characteristics.get(CameraCharacteristics.CONTROL_AE_COMPENSATION_RANGE) ?: return
        val steps = (offset / (if (step == 0.0) 1.0 else step)).roundToInt().coerceIn(range.lower, range.upper)
        builder.set(CaptureRequest.CONTROL_AE_EXPOSURE_COMPENSATION, steps)
        startRepeating()
    }

    fun setExposureMode(mode: String?) {
        val builder = requestBuilder ?: return
        when (mode) {
            "locked" -> builder.set(CaptureRequest.CONTROL_AE_LOCK, true)
            "manual" -> builder.set(CaptureRequest.CONTROL_AE_MODE, CameraMetadata.CONTROL_AE_MODE_OFF)
            else -> {
                builder.set(CaptureRequest.CONTROL_AE_LOCK, false)
                builder.set(CaptureRequest.CONTROL_AE_MODE, UCameraMapper.flashMode(flashName))
            }
        }
        startRepeating()
    }

    fun setFocusMode(mode: String?) {
        val builder = requestBuilder ?: return
        builder.set(CaptureRequest.CONTROL_AF_MODE, UCameraMapper.focusMode(mode))
        if (mode == "infinity") builder.set(CaptureRequest.LENS_FOCUS_DISTANCE, 0f)
        startRepeating()
    }

    fun setPoint(
        x: Double?,
        y: Double?,
        focus: Boolean,
    ) {
        val builder = requestBuilder ?: return
        val sensor = characteristics.get(CameraCharacteristics.SENSOR_INFO_ACTIVE_ARRAY_SIZE) ?: return
        if (x == null || y == null) {
            if (focus) {
                builder.set(CaptureRequest.CONTROL_AF_REGIONS, null)
            } else {
                builder.set(CaptureRequest.CONTROL_AE_REGIONS, null)
            }
            startRepeating()
            return
        }

        val (sensorX, sensorY) = toSensorPoint(x, y)
        val halfWidth = sensor.width() / 12
        val halfHeight = sensor.height() / 12
        val centerX = (sensorX * sensor.width()).roundToInt().coerceIn(0, sensor.width())
        val centerY = (sensorY * sensor.height()).roundToInt().coerceIn(0, sensor.height())
        val region =
            MeteringRectangle(
                max(0, centerX - halfWidth),
                max(0, centerY - halfHeight),
                halfWidth * 2,
                halfHeight * 2,
                MeteringRectangle.METERING_WEIGHT_MAX - 1,
            )
        if (focus) {
            builder.set(CaptureRequest.CONTROL_AF_REGIONS, arrayOf(region))
            builder.set(CaptureRequest.CONTROL_AF_TRIGGER, CameraMetadata.CONTROL_AF_TRIGGER_START)
        } else {
            builder.set(CaptureRequest.CONTROL_AE_REGIONS, arrayOf(region))
        }
        startRepeating()
        if (focus) {
            builder.set(CaptureRequest.CONTROL_AF_TRIGGER, CameraMetadata.CONTROL_AF_TRIGGER_IDLE)
            send(mapOf("event" to "focus", "point" to listOf(x, y)))
        }
    }

    fun setFocusDistance(distance: Double) {
        val builder = requestBuilder ?: return
        builder.set(CaptureRequest.CONTROL_AF_MODE, CameraMetadata.CONTROL_AF_MODE_OFF)
        builder.set(CaptureRequest.LENS_FOCUS_DISTANCE, distance.toFloat())
        startRepeating()
    }

    fun setIso(iso: Double) {
        val builder = requestBuilder ?: return
        builder.set(CaptureRequest.CONTROL_AE_MODE, CameraMetadata.CONTROL_AE_MODE_OFF)
        builder.set(CaptureRequest.SENSOR_SENSITIVITY, iso.roundToInt())
        startRepeating()
    }

    fun setExposureDuration(micros: Long) {
        val builder = requestBuilder ?: return
        builder.set(CaptureRequest.CONTROL_AE_MODE, CameraMetadata.CONTROL_AE_MODE_OFF)
        builder.set(CaptureRequest.SENSOR_EXPOSURE_TIME, micros * 1000L)
        startRepeating()
    }

    fun setWhiteBalance(
        mode: String?,
        temperature: Double?,
    ) {
        val builder = requestBuilder ?: return
        builder.set(CaptureRequest.CONTROL_AWB_MODE, UCameraMapper.whiteBalanceMode(mode))
        builder.set(CaptureRequest.CONTROL_AWB_LOCK, mode == "locked")
        startRepeating()
    }

    fun setStabilization(mode: String?) {
        val builder = requestBuilder ?: return
        applyStabilization(builder, mode)
        startRepeating()
    }

    fun setSceneMode(
        hdr: Boolean,
        night: Boolean,
    ) {
        val builder = requestBuilder ?: return
        val scene =
            when {
                hdr -> CameraMetadata.CONTROL_SCENE_MODE_HDR
                night -> CameraMetadata.CONTROL_SCENE_MODE_NIGHT
                else -> CameraMetadata.CONTROL_SCENE_MODE_DISABLED
            }
        builder.set(CaptureRequest.CONTROL_MODE, if (scene == CameraMetadata.CONTROL_SCENE_MODE_DISABLED) CameraMetadata.CONTROL_MODE_AUTO else CameraMetadata.CONTROL_MODE_USE_SCENE_MODE)
        builder.set(CaptureRequest.CONTROL_SCENE_MODE, scene)
        startRepeating()
    }

    fun setPreviewPaused(paused: Boolean) {
        previewPaused = paused
        if (paused) {
            runCatching { session?.stopRepeating() }
        } else {
            startRepeating()
        }
    }

    fun lockOrientation(name: String?) {
        lockedRotation =
            when (name) {
                "landscapeRight" -> 90
                "portraitDown" -> 180
                "landscapeLeft" -> 270
                "portraitUp" -> 0
                else -> null
            }
    }

    private fun startOrientationListener() {
        val listener =
            object : OrientationEventListener(context) {
                override fun onOrientationChanged(orientation: Int) {
                    syncDisplayRotation()
                    if (orientation == ORIENTATION_UNKNOWN) return
                    val rounded = ((orientation + 45) / 90 * 90) % 360
                    if (rounded == deviceRotation) return
                    deviceRotation = rounded
                    send(mapOf("event" to "orientation", "degrees" to rounded))
                }
            }
        if (listener.canDetectOrientation()) {
            listener.enable()
            orientationListener = listener
        }
    }

    private fun startDisplayListener() {
        displayRotation = readDisplayRotation()
        val manager = context.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager ?: return
        val listener =
            object : DisplayManager.DisplayListener {
                override fun onDisplayAdded(displayId: Int) = Unit

                override fun onDisplayRemoved(displayId: Int) = Unit

                override fun onDisplayChanged(displayId: Int) {
                    syncDisplayRotation()
                }
            }
        runCatching {
            manager.registerDisplayListener(listener, mainHandler)
            displayListener = listener
        }
    }

    private fun syncDisplayRotation() {
        val rotation = readDisplayRotation()
        if (rotation == displayRotation) return
        displayRotation = rotation
        send(mapOf("event" to "displayRotation", "degrees" to rotation))
    }

    @Suppress("DEPRECATION")
    private fun readDisplayRotation(): Int {
        val source: Context = activityProvider() ?: context
        val display =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                runCatching { source.display }.getOrNull()
            } else {
                null
            } ?: (source.getSystemService(Context.WINDOW_SERVICE) as? WindowManager)?.defaultDisplay
        return when (display?.rotation) {
            Surface.ROTATION_90 -> 90
            Surface.ROTATION_180 -> 180
            Surface.ROTATION_270 -> 270
            else -> 0
        }
    }

    private fun previewRotation(): Int {
        val sensorOrientation = characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 0
        val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
        return if (facing == CameraCharacteristics.LENS_FACING_FRONT) {
            (sensorOrientation + displayRotation) % 360
        } else {
            (sensorOrientation - displayRotation + 360) % 360
        }
    }

    private fun toSensorPoint(
        x: Double,
        y: Double,
    ): Pair<Double, Double> =
        when (previewRotation()) {
            90 -> Pair(y, 1 - x)
            180 -> Pair(1 - x, 1 - y)
            270 -> Pair(1 - y, x)
            else -> Pair(x, y)
        }

    private fun captureRotation(): Int {
        val sensorOrientation = characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 0
        val rotation = lockedRotation ?: deviceRotation
        val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
        val signed = if (facing == CameraCharacteristics.LENS_FACING_FRONT) -rotation else rotation
        return (sensorOrientation + signed + 360) % 360
    }

    // -------------------------------------------------------------------------
    // Still capture
    // -------------------------------------------------------------------------

    fun takePhoto(
        arguments: Map<*, *>,
        result: (Map<String, Any?>?, String?) -> Unit,
    ) {
        val deliver = once(result)
        val reader = stillReader
        val camera = device
        val current = session
        if (reader == null || camera == null || current == null || disposed) {
            deliver(null, "notFound")
            return
        }

        val includeBytes = arguments["includeBytes"] as? Boolean ?: true
        val targetPath = arguments["path"] as? String ?: defaultFile("jpg").absolutePath
        val mirrored = characteristics.get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_FRONT

        reader.setOnImageAvailableListener({ source ->
            val frame = runCatching { source.acquireLatestImage() }.getOrNull() ?: return@setOnImageAvailableListener
            try {
                val width = frame.width
                val height = frame.height
                val buffer = frame.planes[0].buffer
                val bytes = ByteArray(buffer.remaining())
                buffer.get(bytes)
                val rotation = captureRotation()
                File(targetPath).writeBytes(bytes)
                deliver(
                    mapOf(
                        "path" to targetPath,
                        "bytes" to if (includeBytes) bytes else null,
                        "width" to width,
                        "height" to height,
                        "format" to "jpeg",
                        "orientation" to rotation,
                        "sizeInBytes" to bytes.size,
                        "mirrored" to mirrored,
                    ),
                    null,
                )
            } catch (error: Exception) {
                deliver(null, error.message ?: "capture")
            } catch (error: OutOfMemoryError) {
                deliver(null, "outOfMemory")
            } finally {
                runCatching { frame.close() }
                runCatching { source.setOnImageAvailableListener(null, handler) }
            }
        }, handler)

        try {
            val builder = camera.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE)
            builder.addTarget(reader.surface)
            requestBuilder?.let { source ->
                builder.set(CaptureRequest.CONTROL_AF_MODE, source.get(CaptureRequest.CONTROL_AF_MODE))
                builder.set(CaptureRequest.CONTROL_AE_MODE, source.get(CaptureRequest.CONTROL_AE_MODE))
                builder.set(CaptureRequest.CONTROL_AWB_MODE, source.get(CaptureRequest.CONTROL_AWB_MODE))
                builder.set(CaptureRequest.FLASH_MODE, source.get(CaptureRequest.FLASH_MODE))
                source.get(CaptureRequest.SCALER_CROP_REGION)?.let { builder.set(CaptureRequest.SCALER_CROP_REGION, it) }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    source.get(CaptureRequest.CONTROL_ZOOM_RATIO)?.let { builder.set(CaptureRequest.CONTROL_ZOOM_RATIO, it) }
                }
            }
            builder.set(CaptureRequest.JPEG_ORIENTATION, captureRotation())
            builder.set(CaptureRequest.JPEG_QUALITY, ((arguments["quality"] as? Number)?.toInt() ?: 92).toByte())
            current.capture(
                builder.build(),
                object : CameraCaptureSession.CaptureCallback() {
                    override fun onCaptureFailed(
                        capture: CameraCaptureSession,
                        request: CaptureRequest,
                        failure: android.hardware.camera2.CaptureFailure,
                    ) {
                        runCatching { reader.setOnImageAvailableListener(null, handler) }
                        deliver(null, "capture")
                    }
                },
                handler,
            )
        } catch (error: Exception) {
            runCatching { reader.setOnImageAvailableListener(null, handler) }
            deliver(null, error.message ?: "capture")
        }
    }

    fun takeSnapshot(
        quality: Int,
        result: (Map<String, Any?>?, String?) -> Unit,
    ) {
        val deliver = once(result)
        val reader = analysisReader
        if (reader == null || disposed) {
            deliver(null, "unsupported")
            return
        }
        if (!streamingFrames) {
            runCatching { requestBuilder?.addTarget(reader.surface) }
            startRepeating()
        }
        reader.setOnImageAvailableListener({ source ->
            val frame = runCatching { source.acquireLatestImage() }.getOrNull() ?: return@setOnImageAvailableListener
            try {
                val width = frame.width
                val height = frame.height
                val rotation = captureRotation()
                val jpeg = yuvToJpeg(frame, quality)
                deliver(
                    mapOf(
                        "bytes" to jpeg,
                        "width" to width,
                        "height" to height,
                        "format" to "jpeg",
                        "orientation" to rotation,
                        "sizeInBytes" to jpeg.size,
                    ),
                    null,
                )
            } catch (error: Exception) {
                deliver(null, error.message ?: "capture")
            } catch (error: OutOfMemoryError) {
                deliver(null, "outOfMemory")
            } finally {
                runCatching { frame.close() }
                runCatching {
                    source.setOnImageAvailableListener(if (streamingFrames) { r -> onAnalysisImage(r) } else null, handler)
                }
            }
        }, handler)
    }

    private fun yuvToJpeg(
        image: Image,
        quality: Int,
    ): ByteArray {
        val nv21 = toNv21(image)
        val yuv = YuvImage(nv21, ImageFormat.NV21, image.width, image.height, null)
        val stream = ByteArrayOutputStream()
        yuv.compressToJpeg(android.graphics.Rect(0, 0, image.width, image.height), quality, stream)
        return stream.toByteArray()
    }

    // -------------------------------------------------------------------------
    // Frame streaming
    // -------------------------------------------------------------------------

    fun startImageStream(
        format: String?,
        maxFps: Double?,
        downscale: Int?,
    ) {
        frameFormat = format ?: frameFormat
        if (maxFps != null && maxFps > 0) frameIntervalMs = (1000.0 / maxFps).toLong()
        frameDownscale = max(1, downscale ?: frameDownscale)
        if (streamingFrames) return
        streamingFrames = true
        analysisReader?.let { requestBuilder?.addTarget(it.surface) }
        analysisReader?.setOnImageAvailableListener({ reader -> onAnalysisImage(reader) }, handler)
        startRepeating()
    }

    fun stopImageStream() {
        if (!streamingFrames) return
        streamingFrames = false
        analysisReader?.let { requestBuilder?.removeTarget(it.surface) }
        startRepeating()
    }

    private fun onAnalysisImage(reader: ImageReader) {
        var image: Image? = null
        try {
            image = runCatching { reader.acquireLatestImage() }.getOrNull() ?: return
            if (!streamingFrames || disposed) return
            val now = System.currentTimeMillis()
            if (now - lastFrameAt < frameIntervalMs) return
            lastFrameAt = now

            val width = image.width
            val height = image.height
            val payload: Map<String, Any?> =
                when (frameFormat) {
                    "gray8" -> {
                        val plane = image.planes[0]
                        val rowStride = plane.rowStride
                        val buffer = plane.buffer
                        val bytes = ByteArray(buffer.remaining())
                        buffer.get(bytes)
                        mapOf(
                            "planes" to listOf(bytes),
                            "format" to "gray8",
                            "width" to width,
                            "height" to height,
                            "rowStrides" to listOf(rowStride),
                            "pixelStrides" to listOf(plane.pixelStride),
                            "rotation" to captureRotation(),
                            "timestampUs" to (image.timestamp / 1000),
                        )
                    }

                    "yuv420" -> {
                        val planes = image.planes.map { plane ->
                            val buffer = plane.buffer
                            val bytes = ByteArray(buffer.remaining())
                            buffer.get(bytes)
                            bytes
                        }
                        mapOf(
                            "planes" to planes,
                            "format" to "yuv420",
                            "width" to width,
                            "height" to height,
                            "rowStrides" to image.planes.map { it.rowStride },
                            "pixelStrides" to image.planes.map { it.pixelStride },
                            "rotation" to captureRotation(),
                            "timestampUs" to (image.timestamp / 1000),
                        )
                    }

                    else -> {
                        val nv21 = toNv21(image)
                        mapOf(
                            "planes" to listOf(nv21),
                            "format" to "nv21",
                            "width" to width,
                            "height" to height,
                            "rowStrides" to listOf(width),
                            "pixelStrides" to listOf(1),
                            "rotation" to captureRotation(),
                            "timestampUs" to (image.timestamp / 1000),
                        )
                    }
                }
            sendFrame(payload)
        } catch (error: Exception) {
            // The reader was closed underneath us; the next frame will recover.
        } catch (error: OutOfMemoryError) {
            // Skip this frame rather than take the process down.
        } finally {
            runCatching { image?.close() }
        }
    }

    private fun toNv21(image: Image): ByteArray {
        val width = image.width
        val height = image.height
        val ySize = width * height
        val out = ByteArray(ySize + ySize / 2)

        val yPlane = image.planes[0]
        val yBuffer = yPlane.buffer
        val yRowStride = yPlane.rowStride
        if (yRowStride == width) {
            yBuffer.get(out, 0, ySize)
        } else {
            var offset = 0
            val row = ByteArray(yRowStride)
            for (y in 0 until height) {
                yBuffer.position(y * yRowStride)
                val length = min(yRowStride, yBuffer.remaining())
                yBuffer.get(row, 0, length)
                System.arraycopy(row, 0, out, offset, width)
                offset += width
            }
        }

        val uPlane = image.planes[1]
        val vPlane = image.planes[2]
        val uBuffer = uPlane.buffer
        val vBuffer = vPlane.buffer
        val chromaRowStride = uPlane.rowStride
        val chromaPixelStride = uPlane.pixelStride
        var outIndex = ySize
        val chromaHeight = height / 2
        val chromaWidth = width / 2
        for (row in 0 until chromaHeight) {
            for (col in 0 until chromaWidth) {
                val index = row * chromaRowStride + col * chromaPixelStride
                if (index >= vBuffer.limit() || index >= uBuffer.limit()) continue
                out[outIndex++] = vBuffer.get(index)
                out[outIndex++] = uBuffer.get(index)
            }
        }
        return out
    }

    // -------------------------------------------------------------------------
    // Video recording
    // -------------------------------------------------------------------------

    fun startRecording(
        arguments: Map<*, *>,
        onDone: (String?) -> Unit,
    ) {
        val done = onceError(onDone)
        if (recorder != null || disposed) {
            done("recording")
            return
        }
        val path = arguments["path"] as? String ?: defaultFile(if (stringConfig("videoContainer") == "webm") "webm" else "mp4").absolutePath
        val enableAudio = arguments["enableAudio"] as? Boolean ?: true
        val hasAudioPermission = ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

        val created =
            runCatching {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) MediaRecorder(context) else @Suppress("DEPRECATION") MediaRecorder()
            }.getOrNull()
        if (created == null) {
            done("recording")
            return
        }
        try {
            if (enableAudio && hasAudioPermission) created.setAudioSource(MediaRecorder.AudioSource.CAMCORDER)
            created.setVideoSource(MediaRecorder.VideoSource.SURFACE)
            created.setOutputFormat(UCameraMapper.containerFormat(stringConfig("videoContainer")))
            created.setOutputFile(path)
            created.setVideoEncodingBitRate((arguments["bitrate"] as? Number)?.toInt() ?: estimateBitrate())
            created.setVideoFrameRate(((config["fps"] as? Number)?.toInt() ?: 30))
            created.setVideoSize(previewSize.width, previewSize.height)
            created.setVideoEncoder(UCameraMapper.videoEncoder(arguments["codec"] as? String))
            if (enableAudio && hasAudioPermission) {
                created.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                created.setAudioEncodingBitRate((config["audioBitrate"] as? Number)?.toInt() ?: 128000)
                created.setAudioSamplingRate(44100)
            }
            created.setOrientationHint(captureRotation())
            (arguments["maxDurationMs"] as? Number)?.let { created.setMaxDuration(it.toInt()) }
            (arguments["maxBytes"] as? Number)?.let { created.setMaxFileSize(it.toLong()) }
            created.prepare()
        } catch (error: Exception) {
            runCatching { created.release() }
            done(error.message ?: "recording")
            return
        }

        recorder = created
        recordingPath = path
        recordingStartedAt = System.currentTimeMillis()

        createSession { error ->
            if (error != null) {
                runCatching { created.release() }
                recorder = null
                recordingPath = null
                done(error)
                return@createSession
            }
            runCatching { created.start() }
                .onSuccess { done(null) }
                .onFailure { failure ->
                    runCatching { created.release() }
                    recorder = null
                    recordingPath = null
                    done(failure.message ?: "recording")
                }
        }
    }

    fun stopRecording(onDone: (Map<String, Any?>?, String?) -> Unit) {
        val deliver = once(onDone)
        val current = recorder
        if (current == null) {
            deliver(null, "notFound")
            return
        }
        val path = recordingPath
        val duration = System.currentTimeMillis() - recordingStartedAt
        runCatching { current.stop() }
        runCatching { current.release() }
        recorder = null
        recordingPath = null

        createSession { _ ->
            val file = if (path == null) null else File(path)
            deliver(
                mapOf(
                    "path" to path,
                    "durationMs" to duration,
                    "width" to previewSize.width,
                    "height" to previewSize.height,
                    "sizeInBytes" to (runCatching { file?.length() }.getOrNull() ?: 0L),
                    "container" to (stringConfig("videoContainer") ?: "mp4"),
                ),
                null,
            )
        }
    }

    fun pauseRecording() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) runCatching { recorder?.pause() }
    }

    fun resumeRecording() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) runCatching { recorder?.resume() }
    }

    private fun estimateBitrate(): Int {
        val pixels = previewSize.width * previewSize.height
        return when {
            pixels >= 3840 * 2160 -> 35_000_000
            pixels >= 1920 * 1080 -> 10_000_000
            pixels >= 1280 * 720 -> 5_000_000
            else -> 2_000_000
        }
    }

    private fun defaultFile(extension: String): File {
        val directory = File(context.cacheDir, "u_camera")
        if (!directory.exists()) directory.mkdirs()
        return File(directory, "${System.currentTimeMillis()}.$extension")
    }
}

/** Enumerates the device's cameras without opening any of them. */
internal object UCameraEnumerator {
    fun describeDevice(
        manager: CameraManager,
        cameraId: String,
    ): Map<String, Any?> {
        val characteristics = manager.getCameraCharacteristics(cameraId)
        val focalLengths = characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS) ?: floatArrayOf()
        val map: StreamConfigurationMap? = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
        val capabilities = characteristics.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES) ?: intArrayOf()
        val maxDigitalZoom = characteristics.get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM) ?: 1f
        val zoomRange =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) characteristics.get(CameraCharacteristics.CONTROL_ZOOM_RATIO_RANGE) else null

        val formats =
            map?.getOutputSizes(ImageFormat.JPEG)?.map { size ->
                mapOf(
                    "size" to mapOf("width" to size.width, "height" to size.height),
                    "minFps" to 0.0,
                    "maxFps" to 30.0,
                )
            } ?: emptyList()

        return mapOf(
            "id" to cameraId,
            "name" to "Camera $cameraId",
            "facing" to UCameraMapper.facingName(characteristics.get(CameraCharacteristics.LENS_FACING) ?: -1),
            "lens" to UCameraMapper.lensName(focalLengths.firstOrNull() ?: 0f, focalLengths),
            "sensorOrientation" to (characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 0),
            "hasFlash" to (characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true),
            "isLogical" to capabilities.contains(CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_LOGICAL_MULTI_CAMERA),
            "physicalDeviceIds" to
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) characteristics.physicalCameraIds.toList() else emptyList<String>(),
            "focalLengths" to focalLengths.map { it.toDouble() },
            "minFocusDistance" to (characteristics.get(CameraCharacteristics.LENS_INFO_MINIMUM_FOCUS_DISTANCE)?.toDouble() ?: 0.0),
            "formats" to formats,
            "minZoom" to (zoomRange?.lower?.toDouble() ?: 1.0),
            "maxZoom" to (zoomRange?.upper?.toDouble() ?: maxDigitalZoom.toDouble()),
            "neutralZoom" to 1.0,
        )
    }

    fun list(manager: CameraManager): List<Map<String, Any?>> =
        manager.cameraIdList.mapNotNull { id ->
            runCatching { describeDevice(manager, id) }.getOrNull()
        }
}

/**
 * Replies at most once, always on the platform thread. Camera callbacks land on
 * background threads and can fire twice, both of which take the process down if
 * they reach a raw [MethodChannel.Result].
 */
internal class USafeResult(
    private val delegate: MethodChannel.Result,
) : MethodChannel.Result {
    private val delivered = AtomicBoolean(false)
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun success(result: Any?) = reply { delegate.success(result) }

    override fun error(
        code: String,
        message: String?,
        details: Any?,
    ) = reply { delegate.error(code, message, details) }

    override fun notImplemented() = reply { delegate.notImplemented() }

    private fun reply(block: () -> Unit) {
        if (!delivered.compareAndSet(false, true)) return
        if (Looper.myLooper() == Looper.getMainLooper()) {
            runCatching { block() }
        } else {
            mainHandler.post { runCatching { block() } }
        }
    }
}

/** Method-channel front end: owns every session and the permission flow. */
internal class UCameraHandler(
    private val context: Context,
    private val messenger: BinaryMessenger,
    private val textureRegistry: TextureRegistry,
) : MethodChannel.MethodCallHandler,
    PluginRegistry.RequestPermissionsResultListener {
    private val channel = MethodChannel(messenger, "u/camera")
    private val sessions = mutableMapOf<Int, UCameraSession>()
    private var nextId = 1
    private var activity: Activity? = null
    private var permissionResult: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler(this)
    }

    fun setActivity(value: Activity?) {
        activity = value
    }

    fun dispose() {
        runCatching { channel.setMethodCallHandler(null) }
        sessions.values.forEach { runCatching { it.dispose() } }
        sessions.clear()
        runCatching { permissionResult?.success(permissionMap()) }
        permissionResult = null
        activity = null
    }

    private val manager: CameraManager get() = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val safe = USafeResult(result)
        try {
            when (call.method) {
                "isSupported" -> safe.success(context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY))
                "availableCameras" -> safe.success(runCatching { UCameraEnumerator.list(manager) }.getOrDefault(emptyList()))
                "permissionStatus" -> safe.success(permissionMap())
                "requestPermission" -> requestPermission(call.argument<Boolean>("audio") ?: false, safe)
                "openSettings" -> safe.success(openSettings())
                "create" -> createSession(call, safe)
                else -> handleSessionCall(call, safe)
            }
        } catch (error: Exception) {
            safe.error("unknown", error.message ?: "Camera call failed", null)
        } catch (error: OutOfMemoryError) {
            safe.error("outOfMemory", "Out of memory", null)
        }
    }

    private fun permissionMap(): Map<String, Any?> =
        mapOf(
            "camera" to UCameraMapper.permissionName(ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)),
            "microphone" to UCameraMapper.permissionName(ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO)),
        )

    private fun requestPermission(
        audio: Boolean,
        result: MethodChannel.Result,
    ) {
        val current = activity
        if (current == null) {
            result.success(permissionMap())
            return
        }
        val wanted = mutableListOf(Manifest.permission.CAMERA)
        if (audio) wanted.add(Manifest.permission.RECORD_AUDIO)
        val missing = wanted.filter { ContextCompat.checkSelfPermission(context, it) != PackageManager.PERMISSION_GRANTED }
        if (missing.isEmpty()) {
            result.success(permissionMap())
            return
        }
        permissionResult = result
        ActivityCompat.requestPermissions(current, missing.toTypedArray(), PERMISSION_REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        val pending = permissionResult ?: return true
        permissionResult = null
        val current = activity
        val permanentlyDenied =
            current != null &&
                permissions.indices.any { index ->
                    grantResults.getOrNull(index) != PackageManager.PERMISSION_GRANTED &&
                        !ActivityCompat.shouldShowRequestPermissionRationale(current, permissions[index])
                }
        val base = permissionMap().toMutableMap()
        if (permanentlyDenied && base["camera"] == "denied") base["camera"] = "permanentlyDenied"
        pending.success(base)
        return true
    }

    private fun openSettings(): Boolean {
        val current = activity ?: return false
        return runCatching {
            val intent = android.content.Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", context.packageName, null))
            current.startActivity(intent)
            true
        }.getOrDefault(false)
    }

    private fun createSession(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val config = call.argument<Map<String, Any?>>("config") ?: emptyMap()
        val id = nextId++
        val session =
            runCatching { UCameraSession(id, context, messenger, textureRegistry, config) { activity } }.getOrNull()
        if (session == null) {
            result.error("unknown", "Unable to open camera", null)
            return
        }
        sessions[id] = session
        session.open { description, error ->
            if (description != null) {
                result.success(description)
            } else {
                runCatching { sessions.remove(id)?.dispose() }
                result.error(error ?: "unknown", "Unable to open camera", null)
            }
        }
    }

    private fun handleSessionCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val id = call.argument<Int>("sessionId")
        val session = if (id == null) null else sessions[id]
        if (session == null) {
            result.error("notFound", "Camera session not found", null)
            return
        }

        when (call.method) {
            "dispose" -> {
                runCatching { sessions.remove(id)?.dispose() }
                result.success(null)
            }

            "takePhoto" -> session.takePhoto(call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()) { photo, error ->
                if (photo != null) result.success(photo) else result.error(error ?: "capture", "Photo capture failed", null)
            }

            "takeSnapshot" -> session.takeSnapshot(call.argument<Int>("quality") ?: 90) { photo, error ->
                if (photo != null) result.success(photo) else result.error(error ?: "capture", "Snapshot failed", null)
            }

            "startRecording" -> session.startRecording(call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()) { error ->
                if (error == null) result.success(null) else result.error("recording", error, null)
            }

            "stopRecording" -> session.stopRecording { video, error ->
                if (video != null) result.success(video) else result.error(error ?: "recording", "Stop failed", null)
            }

            "pauseRecording" -> {
                session.pauseRecording()
                result.success(null)
            }

            "resumeRecording" -> {
                session.resumeRecording()
                result.success(null)
            }

            "setFlashMode" -> {
                session.setFlashMode(call.argument<String>("mode"))
                result.success(null)
            }

            "setTorch" -> {
                session.setTorch(call.argument<Boolean>("on") ?: false)
                result.success(null)
            }

            "setZoom" -> {
                session.setZoom((call.argument<Number>("zoom") ?: 1).toFloat())
                result.success(null)
            }

            "setExposureOffset" -> {
                session.setExposureOffset((call.argument<Number>("offset") ?: 0).toDouble())
                result.success(null)
            }

            "setExposureMode" -> {
                session.setExposureMode(call.argument<String>("mode"))
                result.success(null)
            }

            "setExposurePoint" -> {
                session.setPoint(call.argument<Number>("x")?.toDouble(), call.argument<Number>("y")?.toDouble(), focus = false)
                result.success(null)
            }

            "setFocusMode" -> {
                session.setFocusMode(call.argument<String>("mode"))
                result.success(null)
            }

            "setFocusPoint" -> {
                session.setPoint(call.argument<Number>("x")?.toDouble(), call.argument<Number>("y")?.toDouble(), focus = true)
                result.success(null)
            }

            "setFocusDistance" -> {
                session.setFocusDistance((call.argument<Number>("distance") ?: 0).toDouble())
                result.success(null)
            }

            "setIso" -> {
                session.setIso((call.argument<Number>("iso") ?: 100).toDouble())
                result.success(null)
            }

            "setExposureDuration" -> {
                session.setExposureDuration((call.argument<Number>("micros") ?: 0).toLong())
                result.success(null)
            }

            "setWhiteBalance" -> {
                session.setWhiteBalance(call.argument<String>("mode"), call.argument<Number>("temperature")?.toDouble())
                result.success(null)
            }

            "setStabilization" -> {
                session.setStabilization(call.argument<String>("mode"))
                result.success(null)
            }

            "setHdr" -> {
                session.setSceneMode(call.argument<String>("mode") == "on", night = false)
                result.success(null)
            }

            "setNightMode" -> {
                session.setSceneMode(hdr = false, night = call.argument<String>("mode") == "on")
                result.success(null)
            }

            "setPreviewPaused" -> {
                session.setPreviewPaused(call.argument<Boolean>("paused") ?: false)
                result.success(null)
            }

            "lockOrientation" -> {
                session.lockOrientation(call.argument<String>("orientation"))
                result.success(null)
            }

            "unlockOrientation" -> {
                session.lockOrientation(null)
                result.success(null)
            }

            "startImageStream" -> {
                session.startImageStream(
                    call.argument<String>("format"),
                    call.argument<Number>("maxFps")?.toDouble(),
                    call.argument<Number>("downscale")?.toInt(),
                )
                result.success(null)
            }

            "stopImageStream" -> {
                session.stopImageStream()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }
}
