package com.sinamn75.u.screenguard

import android.app.Activity
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Native screenshot / screen-recording prevention for Android.
 *
 * FLAG_SECURE blocks screenshots, renders screen recordings as black frames
 * and hides the app content in the recent-apps thumbnail.
 */
class ScreenGuardHandler(
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel: MethodChannel = MethodChannel(messenger, "u/screen_guard")

    private var activity: Activity? = null

    init {
        channel.setMethodCallHandler(this)
    }

    fun setActivity(activity: Activity?) {
        this.activity = activity
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        activity = null
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            "enable" -> {
                applySecure(true)
                result.success(null)
            }
            "disable" -> {
                applySecure(false)
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
}
