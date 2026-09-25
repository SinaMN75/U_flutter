package com.sinamn75.u

import com.sinamn75.u.ar.UArHandler
import com.sinamn75.u.camera.UCameraHandler
import com.sinamn75.u.files.UFilesHandler
import com.sinamn75.u.media.UMediaHandler
import com.sinamn75.u.media.UMediaSessionHandler
import com.sinamn75.u.screenguard.ScreenGuardHandler
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** UPlugin: root registration point for every native feature of the `u` plugin. */
class UPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodCallHandler {
    private lateinit var channel: MethodChannel

    // Native feature handlers, each owning its own method channel.
    private var screenGuard: ScreenGuardHandler? = null
    private var media: UMediaHandler? = null
    private var mediaSession: UMediaSessionHandler? = null
    private var camera: UCameraHandler? = null
    private var ar: UArHandler? = null
    private var files: UFilesHandler? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "u")
        channel.setMethodCallHandler(this)
        screenGuard = ScreenGuardHandler(flutterPluginBinding.binaryMessenger)
        media =
            UMediaHandler(
                flutterPluginBinding.applicationContext,
                flutterPluginBinding.binaryMessenger,
                flutterPluginBinding.textureRegistry,
            )
        mediaSession = UMediaSessionHandler(flutterPluginBinding.applicationContext, flutterPluginBinding.binaryMessenger)
        camera =
            UCameraHandler(
                flutterPluginBinding.applicationContext,
                flutterPluginBinding.binaryMessenger,
                flutterPluginBinding.textureRegistry,
            )
        ar =
            UArHandler(
                flutterPluginBinding.applicationContext,
                flutterPluginBinding.binaryMessenger,
                flutterPluginBinding.textureRegistry,
            )
        files = UFilesHandler(flutterPluginBinding.applicationContext, flutterPluginBinding.binaryMessenger)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        screenGuard?.dispose()
        screenGuard = null
        media?.dispose()
        media = null
        mediaSession?.dispose()
        mediaSession = null
        camera?.dispose()
        camera = null
        ar?.dispose()
        ar = null
        files?.dispose()
        files = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        screenGuard?.setActivity(binding.activity)
        media?.setActivity(binding.activity)
        camera?.setActivity(binding.activity)
        camera?.let { binding.addRequestPermissionsResultListener(it) }
        ar?.setActivity(binding.activity)
        ar?.let { binding.addRequestPermissionsResultListener(it) }
        files?.setActivity(binding.activity)
        files?.let {
            binding.addActivityResultListener(it)
            binding.addRequestPermissionsResultListener(it)
        }
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        screenGuard?.setActivity(binding.activity)
        media?.setActivity(binding.activity)
        camera?.setActivity(binding.activity)
        camera?.let { binding.addRequestPermissionsResultListener(it) }
        ar?.setActivity(binding.activity)
        ar?.let { binding.addRequestPermissionsResultListener(it) }
        files?.setActivity(binding.activity)
        files?.let {
            binding.addActivityResultListener(it)
            binding.addRequestPermissionsResultListener(it)
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        screenGuard?.setActivity(null)
        media?.setActivity(null)
        camera?.setActivity(null)
        ar?.setActivity(null)
        files?.setActivity(null)
    }

    override fun onDetachedFromActivity() {
        screenGuard?.setActivity(null)
        media?.setActivity(null)
        camera?.setActivity(null)
        ar?.setActivity(null)
        files?.setActivity(null)
    }
}
