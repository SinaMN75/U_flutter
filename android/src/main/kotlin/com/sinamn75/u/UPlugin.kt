package com.sinamn75.u

import com.sinamn75.u.ar.UArHandler
import com.sinamn75.u.camera.UCameraHandler
import com.sinamn75.u.device.UDeviceHandler
import com.sinamn75.u.files.UFilesHandler
import com.sinamn75.u.launch.ULaunchHandler
import com.sinamn75.u.location.ULocationHandler
import com.sinamn75.u.notification.UNotificationHandler
import com.sinamn75.u.share.UShareHandler
import com.sinamn75.u.media.UMediaHandler
import com.sinamn75.u.media.UMediaSessionHandler
import com.sinamn75.u.nfc.UNfcHandler
import com.sinamn75.u.screenguard.ScreenGuardHandler
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

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
    private var device: UDeviceHandler? = null
    private var launch: ULaunchHandler? = null
    private var share: UShareHandler? = null
    private var location: ULocationHandler? = null
    private var notify: UNotificationHandler? = null
    private var nfc: UNfcHandler? = null
    private var activityBinding: ActivityPluginBinding? = null
    private val userLeaveHint = PluginRegistry.UserLeaveHintListener { media?.onUserLeaveHint() }

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
        device = UDeviceHandler(flutterPluginBinding.applicationContext, flutterPluginBinding.binaryMessenger)
        launch = ULaunchHandler(flutterPluginBinding.applicationContext, flutterPluginBinding.binaryMessenger)
        share = UShareHandler(flutterPluginBinding.applicationContext, flutterPluginBinding.binaryMessenger)
        location = ULocationHandler(flutterPluginBinding.applicationContext, flutterPluginBinding.binaryMessenger)
        notify = UNotificationHandler(flutterPluginBinding.applicationContext, flutterPluginBinding.binaryMessenger)
        nfc = UNfcHandler(flutterPluginBinding.applicationContext, flutterPluginBinding.binaryMessenger)
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
        device?.dispose()
        device = null
        launch?.dispose()
        launch = null
        share?.dispose()
        share = null
        location?.dispose()
        location = null
        notify?.dispose()
        notify = null
        nfc?.dispose()
        nfc = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        attachLeaveHint(binding)
        launch?.attach(binding)
        share?.attach(binding)
        location?.attach(binding)
        notify?.attach(binding)
        screenGuard?.setActivity(binding.activity)
        device?.setActivity(binding.activity)
        nfc?.setActivity(binding.activity)
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
        attachLeaveHint(binding)
        launch?.attach(binding)
        share?.attach(binding)
        location?.attach(binding)
        notify?.attach(binding)
        screenGuard?.setActivity(binding.activity)
        device?.setActivity(binding.activity)
        nfc?.setActivity(binding.activity)
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

    private fun attachLeaveHint(binding: ActivityPluginBinding) {
        activityBinding?.removeOnUserLeaveHintListener(userLeaveHint)
        binding.addOnUserLeaveHintListener(userLeaveHint)
        activityBinding = binding
    }

    private fun detachLeaveHint() {
        launch?.detach()
        share?.detach()
        location?.detach()
        notify?.detach()
        activityBinding?.removeOnUserLeaveHintListener(userLeaveHint)
        activityBinding = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachLeaveHint()
        screenGuard?.setActivity(null)
        device?.setActivity(null)
        nfc?.setActivity(null)
        media?.setActivity(null)
        camera?.setActivity(null)
        ar?.setActivity(null)
        files?.setActivity(null)
    }

    override fun onDetachedFromActivity() {
        detachLeaveHint()
        screenGuard?.setActivity(null)
        device?.setActivity(null)
        nfc?.setActivity(null)
        media?.setActivity(null)
        camera?.setActivity(null)
        ar?.setActivity(null)
        files?.setActivity(null)
    }
}
