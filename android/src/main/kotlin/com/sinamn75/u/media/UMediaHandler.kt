package com.sinamn75.u.media

import android.app.Activity
import android.content.Context
import androidx.media3.common.util.UnstableApi
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry

@UnstableApi
class UMediaHandler(
    private val context: Context,
    private val messenger: BinaryMessenger,
    private val textureRegistry: TextureRegistry,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "u/media")
    private val players = mutableMapOf<Int, UMediaPlayer>()
    private var nextId = 1
    private var activity: Activity? = null

    init {
        channel.setMethodCallHandler(this)
    }

    fun setActivity(value: Activity?) {
        activity = value
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        players.values.forEach { it.dispose() }
        players.clear()
        activity = null
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        if (call.method == "isAvailable") {
            result.success(true)
            return
        }

        if (call.method == "create") {
            val kind = call.argument<String>("kind") ?: "video"
            val config = call.argument<Map<String, Any?>>("config") ?: emptyMap()
            val id = nextId++
            players[id] = UMediaPlayer(id, context, messenger, textureRegistry, config, kind == "video")
            result.success(id)
            return
        }

        val id = call.argument<Int>("id")
        if (id == null) {
            result.error("ERROR_UNSPECIFIED", "Missing player id", null)
            return
        }
        val player = players[id]
        if (player == null) {
            result.error("ERROR_NOT_FOUND", "Player $id not found", null)
            return
        }

        try {
            handleOnPlayer(call, player, id, result)
        } catch (error: IllegalStateException) {
            result.error("ERROR_UNSPECIFIED", error.message, null)
        } catch (error: IllegalArgumentException) {
            result.error("ERROR_UNSPECIFIED", error.message, null)
        }
    }

    private fun handleOnPlayer(
        call: MethodCall,
        player: UMediaPlayer,
        id: Int,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            "open" -> {
                player.open(
                    call.argument<Map<String, Any?>>("source") ?: emptyMap(),
                    call.argument<Boolean>("autoPlay") ?: false,
                    call.argument<Number>("resumeMs")?.toLong(),
                )
                result.success(null)
            }
            "play" -> {
                player.play()
                result.success(null)
            }
            "pause" -> {
                player.pause()
                result.success(null)
            }
            "stop" -> {
                player.stop()
                result.success(null)
            }
            "seek" -> {
                player.seek(call.argument<Number>("positionMs")?.toLong() ?: 0L, call.argument<Boolean>("precise") ?: true)
                result.success(null)
            }
            "stepFrame" -> {
                player.stepFrame(call.argument<Int>("frames") ?: 1)
                result.success(null)
            }
            "setSpeed" -> {
                player.setSpeed(
                    call.argument<Number>("speed")?.toFloat() ?: 1f,
                    call.argument<Boolean>("preservePitch") ?: true,
                )
                result.success(null)
            }
            "setVolume" -> {
                player.setVolume(call.argument<Number>("volume")?.toFloat() ?: 1f)
                result.success(null)
            }
            "setMuted" -> {
                player.setMuted(call.argument<Boolean>("muted") ?: false)
                result.success(null)
            }
            "setRepeat" -> {
                player.setRepeat(call.argument<String>("mode"))
                result.success(null)
            }
            "selectTrack" -> {
                player.selectTrack(call.argument<String>("trackId") ?: "", call.argument<String>("type"))
                result.success(null)
            }
            "setAutoQuality" -> {
                player.setAutoQuality()
                result.success(null)
            }
            "setMaxHeight" -> {
                player.setMaxHeight(call.argument<Int>("height") ?: 0)
                result.success(null)
            }
            "getEqualizer" -> result.success(player.describeEqualizer())
            "setEqualizerEnabled" -> {
                player.setEqualizerEnabled(call.argument<Boolean>("enabled") ?: false)
                result.success(null)
            }
            "setEqualizerBand" -> {
                player.setEqualizerBand(call.argument<Int>("index") ?: 0, call.argument<Number>("gainDb")?.toDouble() ?: 0.0)
                result.success(null)
            }
            "setEqualizerPreset" -> {
                player.setEqualizerPreset(call.argument<String>("preset") ?: "")
                result.success(null)
            }
            "setBassBoost" -> {
                player.setBassBoost(call.argument<Number>("strength")?.toDouble() ?: 0.0)
                result.success(null)
            }
            "setVirtualizer" -> {
                player.setVirtualizer(call.argument<Number>("strength")?.toDouble() ?: 0.0)
                result.success(null)
            }
            "setLoudness" -> {
                player.setLoudness(call.argument<Number>("gainDb")?.toDouble() ?: 0.0)
                result.success(null)
            }
            "startVisualizer" -> {
                player.startVisualizer(call.argument<Int>("bands") ?: 48)
                result.success(null)
            }
            "stopVisualizer" -> {
                player.stopVisualizer()
                result.success(null)
            }
            "setAudioDelay" -> result.success(null)
            "enterPip" -> result.success(player.enterPip(activity, call.argument<Number>("aspectRatio")?.toDouble() ?: (16.0 / 9.0)))
            "exitPip" -> {
                UMediaPip.exit(activity)
                result.success(null)
            }
            "screenshot" -> result.success(player.screenshot())
            "setNotification" -> result.success(null)
            "dispose" -> {
                player.dispose()
                players.remove(id)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
