package com.sinamn75.u.screenguard

import android.Manifest
import android.app.Activity
import android.content.ContentResolver
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.FileObserver
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.MediaStore
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.system.exitProcess

/**
 * Native screenshot / screen-recording prevention for Android.
 *
 * FLAG_SECURE blocks screenshots, renders screen recordings and casts as black
 * frames and hides the app content in the recent-apps thumbnail. Detection of
 * the attempt is layered on top: the official ScreenCaptureCallback on API 34+,
 * a MediaStore observer on API 29+ and a FileObserver on the screenshot folders
 * below that. Every detection is reported to Dart and, when `exitOnCapture` is
 * set, kills the process.
 */
class ScreenGuardHandler(
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private companion object {
        const val PERMISSION_REQUEST_CODE = 75081
        const val DETECTION_WINDOW_MS = 15_000L
        val SCREENSHOT_MARKERS: List<String> =
            listOf("screenshot", "screen_shot", "screen shot", "screencapture")
    }

    private val channel: MethodChannel = MethodChannel(messenger, "u/screen_guard")
    private val mainHandler: Handler = Handler(Looper.getMainLooper())

    private var activity: Activity? = null
    private var guardEnabled = false
    private var exitOnCapture = true
    private var terminating = false

    // Held as Any? so the API 34 callback type is never resolved on older devices.
    private var screenCaptureCallback: Any? = null
    private var mediaObserver: ContentObserver? = null
    private val fileObservers: MutableList<FileObserver> = mutableListOf()

    init {
        channel.setMethodCallHandler(this)
    }

    fun setActivity(activity: Activity?) {
        this.activity = activity
        if (activity != null && guardEnabled) {
            applySecure(true)
            startDetection()
        }
    }

    fun dispose() {
        stopDetection()
        channel.setMethodCallHandler(null)
        activity = null
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            "enable" -> {
                exitOnCapture = call.argument<Boolean>("exitOnCapture") ?: true
                guardEnabled = true
                applySecure(true)
                requestDetectionPermissions()
                startDetection()
                result.success(null)
            }

            "disable" -> {
                guardEnabled = false
                applySecure(false)
                stopDetection()
                result.success(null)
            }

            "isCaptured" -> result.success(false)
            "terminate" -> {
                terminate()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun applySecure(enabled: Boolean) {
        val current: Activity = activity ?: return
        current.runOnUiThread {
            if (enabled) {
                current.window.setFlags(
                    WindowManager.LayoutParams.FLAG_SECURE,
                    WindowManager.LayoutParams.FLAG_SECURE,
                )
            } else {
                current.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
        }
    }

    private fun startDetection() {
        registerScreenCaptureCallback()
        registerMediaObserver()
        registerFileObservers()
    }

    private fun stopDetection() {
        unregisterScreenCaptureCallback()
        mediaObserver?.let { activity?.contentResolver?.unregisterContentObserver(it) }
        mediaObserver = null
        fileObservers.forEach { it.stopWatching() }
        fileObservers.clear()
    }

    private fun registerScreenCaptureCallback() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return
        val current: Activity = activity ?: return
        if (screenCaptureCallback != null) return
        if (!hasPermission(Manifest.permission.DETECT_SCREEN_CAPTURE)) return
        val callback: Activity.ScreenCaptureCallback =
            Activity.ScreenCaptureCallback { onCapture("screenshot") }
        runCatching {
            current.registerScreenCaptureCallback(
                current.mainExecutor,
                callback
            )
        }.onSuccess { screenCaptureCallback = callback }
    }

    private fun unregisterScreenCaptureCallback() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return
        val callback = screenCaptureCallback as? Activity.ScreenCaptureCallback ?: return
        runCatching { activity?.unregisterScreenCaptureCallback(callback) }
        screenCaptureCallback = null
    }

    private fun registerMediaObserver() {
        val resolver: ContentResolver = activity?.contentResolver ?: return
        if (mediaObserver != null) return
        if (!hasPermission(readImagesPermission())) return
        val observer = object : ContentObserver(mainHandler) {
            override fun onChange(
                selfChange: Boolean,
                uri: Uri?,
            ) {
                super.onChange(selfChange, uri)
                if (uri != null && isFreshScreenshot(uri)) onCapture("screenshot")
            }
        }
        runCatching {
            resolver.registerContentObserver(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI, true, observer
            )
        }.onSuccess { mediaObserver = observer }
    }

    // MediaStore only exposes the file once it is indexed, so devices that write
    // the screenshot straight to disk are covered by watching the folders too.
    @Suppress("DEPRECATION")
    private fun registerFileObservers() {
        if (fileObservers.isNotEmpty()) return
        if (!hasPermission(readImagesPermission())) return
        screenshotDirectories().filter { it.isDirectory }.forEach { dir ->
                val observer = object : FileObserver(
                    dir.absolutePath,
                    FileObserver.CREATE or FileObserver.MOVED_TO or FileObserver.CLOSE_WRITE,
                ) {
                    override fun onEvent(
                        event: Int,
                        path: String?,
                    ) {
                        if (path != null && !path.startsWith(".")) onCapture("screenshot")
                    }
                }
                runCatching { observer.startWatching() }.onSuccess { fileObservers.add(observer) }
            }
    }

    @Suppress("DEPRECATION")
    private fun screenshotDirectories(): List<File> {
        val external: File = android.os.Environment.getExternalStorageDirectory()
        return listOf(
            File(external, "Pictures/Screenshots"),
            File(external, "DCIM/Screenshots"),
            File(external, "Screenshots"),
            File(external, "Pictures/Screenshot"),
            File(external, "DCIM/Screenshot"),
        )
    }

    // Both the name and the folder are checked, and only recent entries count,
    // so images the app itself writes never trigger the guard.
    @Suppress("DEPRECATION")
    private fun isFreshScreenshot(uri: Uri): Boolean {
        val resolver: ContentResolver = activity?.contentResolver ?: return false
        val projection: Array<String> = arrayOf(
            MediaStore.Images.Media.DISPLAY_NAME,
            MediaStore.Images.Media.DATE_ADDED,
            MediaStore.Images.Media.DATA,
        )
        return runCatching {
            resolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (!cursor.moveToFirst()) return@use false
                val name: String = cursor.getString(0)?.lowercase().orEmpty()
                val addedSeconds: Long = cursor.getLong(1)
                val path: String = cursor.getString(2)?.lowercase().orEmpty()
                val ageMs: Long = System.currentTimeMillis() - addedSeconds * 1000L
                val looksLikeScreenshot: Boolean =
                    SCREENSHOT_MARKERS.any { name.contains(it) || path.contains(it) }
                looksLikeScreenshot && ageMs in 0..DETECTION_WINDOW_MS
            } ?: false
        }.getOrDefault(false)
    }

    private fun readImagesPermission(): String =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.READ_MEDIA_IMAGES
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }

    private fun hasPermission(permission: String): Boolean {
        val current: Activity = activity ?: return false
        return current.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestDetectionPermissions() {
        val current: Activity = activity ?: return
        val wanted: MutableList<String> = mutableListOf(readImagesPermission())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            wanted.add(Manifest.permission.DETECT_SCREEN_CAPTURE)
        }
        val missing: List<String> = wanted.filterNot { hasPermission(it) }
        if (missing.isEmpty()) return
        runCatching { current.requestPermissions(missing.toTypedArray(), PERMISSION_REQUEST_CODE) }
        // Detection can only attach once the grant lands, so retry shortly after.
        mainHandler.postDelayed({ if (guardEnabled) startDetection() }, 2_000L)
    }

    private fun onCapture(reason: String) {
        if (!guardEnabled) return
        mainHandler.post {
            channel.invokeMethod("onScreenshot", null)
            channel.invokeMethod("onViolation", reason)
            if (exitOnCapture) terminate()
        }
    }

    private fun terminate() {
        if (terminating) return
        terminating = true
        val current: Activity? = activity
        mainHandler.postDelayed({
            current?.finishAndRemoveTask()
            Process.killProcess(Process.myPid())
            exitProcess(0)
        }, 150L)
    }
}
