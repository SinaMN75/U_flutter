package com.sinamn75.u

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

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "u")
        channel.setMethodCallHandler(this)
        screenGuard = ScreenGuardHandler(flutterPluginBinding.binaryMessenger)
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
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        screenGuard?.setActivity(binding.activity)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        screenGuard?.setActivity(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        screenGuard?.setActivity(null)
    }

    override fun onDetachedFromActivity() {
        screenGuard?.setActivity(null)
    }
}
