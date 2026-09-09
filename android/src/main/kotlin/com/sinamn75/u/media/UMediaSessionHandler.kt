package com.sinamn75.u.media

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * System audio focus is owned by ExoPlayer itself (setAudioAttributes with handleAudioFocus),
 * so this handler deliberately does not request focus a second time: doing so would let one
 * abandon call revoke the focus ExoPlayer still relies on. It only reports the events Dart
 * cannot observe, and lets the Dart arbiter coordinate between our own controllers.
 */
class UMediaSessionHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "u/media_session")
    private var noisyRegistered = false

    private val noisyReceiver =
        object : BroadcastReceiver() {
            override fun onReceive(
                receiverContext: Context?,
                intent: Intent?,
            ) {
                if (intent?.action == AudioManager.ACTION_AUDIO_BECOMING_NOISY) channel.invokeMethod("onBecomingNoisy", null)
            }
        }

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            "requestFocus" -> {
                registerNoisy()
                result.success(true)
            }
            "abandonFocus" -> {
                unregisterNoisy()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun registerNoisy() {
        if (noisyRegistered) return
        context.registerReceiver(noisyReceiver, IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY))
        noisyRegistered = true
    }

    private fun unregisterNoisy() {
        if (!noisyRegistered) return
        runCatching { context.unregisterReceiver(noisyReceiver) }
        noisyRegistered = false
    }

    fun dispose() {
        unregisterNoisy()
        channel.setMethodCallHandler(null)
    }
}
