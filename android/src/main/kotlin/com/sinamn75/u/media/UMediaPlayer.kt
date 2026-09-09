package com.sinamn75.u.media

import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.os.Handler
import android.os.Looper
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.common.VideoSize
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.audio.DefaultAudioSink
import androidx.media3.exoplayer.audio.TeeAudioProcessor
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.session.MediaSession
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.view.TextureRegistry
import java.io.ByteArrayOutputStream

@UnstableApi
class UMediaPlayer(
    private val id: Int,
    private val context: Context,
    messenger: BinaryMessenger,
    textureRegistry: TextureRegistry,
    private val config: Map<*, *>,
    private val isVideo: Boolean,
) : Player.Listener,
    EventChannel.StreamHandler {
    private val handler = Handler(Looper.getMainLooper())
    private val eventChannel = EventChannel(messenger, "u/media/events/$id")
    private var sink: EventChannel.EventSink? = null

    private val effects = UMediaEffects()
    private val spectrum = UMediaSpectrum { bands -> emitSpectrum(bands) }

    private val httpFactory =
        DefaultHttpDataSource
            .Factory()
            .setAllowCrossProtocolRedirects(true)
            .setConnectTimeoutMs(intConfig("connectTimeoutMs", 15000))
            .setReadTimeoutMs(intConfig("connectTimeoutMs", 15000))

    private val surfaceProducer: TextureRegistry.SurfaceProducer? = if (isVideo) textureRegistry.createSurfaceProducer() else null

    private val renderersFactory =
        object : DefaultRenderersFactory(context) {
            override fun buildAudioSink(
                context: Context,
                enableFloatOutput: Boolean,
                enableAudioTrackPlaybackParams: Boolean,
            ): AudioSink =
                DefaultAudioSink
                    .Builder(context)
                    .setEnableFloatOutput(enableFloatOutput)
                    .setEnableAudioTrackPlaybackParams(enableAudioTrackPlaybackParams)
                    .setAudioProcessorChain(DefaultAudioSink.DefaultAudioProcessorChain(TeeAudioProcessor(spectrum)))
                    .build()
        }.setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_PREFER)

    private val player: ExoPlayer =
        ExoPlayer
            .Builder(context, renderersFactory)
            .setMediaSourceFactory(DefaultMediaSourceFactory(DefaultDataSource.Factory(context, httpFactory)))
            .setLoadControl(
                DefaultLoadControl
                    .Builder()
                    .setBufferDurationsMs(
                        intConfig("minBufferMs", 15000),
                        intConfig("maxBufferMs", 50000),
                        intConfig("bufferForPlaybackMs", 2500),
                        intConfig("bufferForPlaybackAfterRebufferMs", 5000),
                    ).build(),
            ).build()

    private var mediaSession: MediaSession? = null
    private var currentUri: String? = null
    private var lastSentPosition = -1L
    private val positionIntervalMs = intConfig("positionUpdateMs", 250).toLong()

    private val positionTicker =
        object : Runnable {
            override fun run() {
                emitPosition()
                if (player.isPlaying) handler.postDelayed(this, positionIntervalMs)
            }
        }

    init {
        eventChannel.setStreamHandler(this)
        player.addListener(this)
        player.setAudioAttributes(
            AudioAttributes
                .Builder()
                .setContentType(if (isVideo) C.AUDIO_CONTENT_TYPE_MOVIE else C.AUDIO_CONTENT_TYPE_MUSIC)
                .setUsage(C.USAGE_MEDIA)
                .build(),
            true,
        )
        player.setHandleAudioBecomingNoisy(boolConfig("pauseOnBecomingNoisy", true))
        if (boolConfig("wakeLock", true)) player.setWakeMode(C.WAKE_MODE_NETWORK)

        surfaceProducer?.let { producer ->
            player.setVideoSurface(producer.surface)
            producer.setCallback(
                object : TextureRegistry.SurfaceProducer.Callback {
                    override fun onSurfaceAvailable() {
                        player.setVideoSurface(producer.surface)
                    }

                    override fun onSurfaceCleanup() {
                        player.setVideoSurface(null)
                    }
                },
            )
        }

        player.repeatMode = repeatModeOf(config["repeat"] as? String)
        player.volume = (config["volume"] as? Number)?.toFloat() ?: 1f
        if (boolConfig("muted", false)) player.volume = 0f

        if (boolConfig("allowBackgroundPlayback", false)) {
            runCatching {
                mediaSession = MediaSession.Builder(context, player).setId("u_media_$id").build()
                UMediaService.register(id, mediaSession!!)
            }
        }
    }

    val textureId: Long get() = surfaceProducer?.id() ?: -1L

    private fun intConfig(
        key: String,
        fallback: Int,
    ): Int = (config[key] as? Number)?.toInt() ?: fallback

    private fun boolConfig(
        key: String,
        fallback: Boolean,
    ): Boolean = config[key] as? Boolean ?: fallback

    private fun repeatModeOf(mode: String?): Int =
        when (mode) {
            "one" -> Player.REPEAT_MODE_ONE
            "all" -> Player.REPEAT_MODE_ALL
            else -> Player.REPEAT_MODE_OFF
        }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?,
    ) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    private fun send(payload: Map<String, Any?>) {
        handler.post { sink?.success(payload) }
    }

    private fun emitSpectrum(bands: DoubleArray) {
        send(mapOf("event" to "spectrum", "magnitudes" to bands.toList()))
    }

    fun open(
        source: Map<*, *>,
        autoPlay: Boolean,
        resumeMs: Long?,
    ) {
        @Suppress("UNCHECKED_CAST")
        val headers = source["headers"] as? Map<String, String>
        if (!headers.isNullOrEmpty()) httpFactory.setDefaultRequestProperties(headers)
        (source["userAgent"] as? String)?.let { httpFactory.setUserAgent(it) }

        currentUri = source["url"] as? String ?: source["path"] as? String
        val item: MediaItem = UMediaMapper.buildMediaItem(context, source)
        player.setMediaItem(item, resumeMs ?: C.TIME_UNSET)
        player.playWhenReady = autoPlay
        player.prepare()
        send(mapOf("event" to "state", "state" to "loading"))
    }

    fun play() {
        player.play()
        handler.removeCallbacks(positionTicker)
        handler.post(positionTicker)
    }

    fun pause() {
        player.pause()
        handler.removeCallbacks(positionTicker)
        emitPosition()
    }

    fun stop() {
        player.stop()
        player.clearMediaItems()
        handler.removeCallbacks(positionTicker)
        send(mapOf("event" to "state", "state" to "idle"))
    }

    fun seek(
        positionMs: Long,
        precise: Boolean,
    ) {
        player.seekTo(positionMs)
        emitPosition()
    }

    fun stepFrame(frames: Int) {
        val delta = (1000L / 30L) * frames
        player.seekTo((player.currentPosition + delta).coerceAtLeast(0L))
        emitPosition()
    }

    fun setSpeed(
        speed: Float,
        preservePitch: Boolean,
    ) {
        player.playbackParameters = if (preservePitch) PlaybackParameters(speed) else PlaybackParameters(speed, speed)
    }

    fun setVolume(volume: Float) {
        player.volume = volume.coerceIn(0f, 1f)
    }

    fun setMuted(muted: Boolean) {
        player.volume = if (muted) 0f else 1f
    }

    fun setRepeat(mode: String?) {
        player.repeatMode = repeatModeOf(mode)
    }

    fun selectTrack(
        trackId: String,
        type: String?,
    ) {
        val found = UMediaMapper.findGroup(player.currentTracks, trackId) ?: return
        player.trackSelectionParameters =
            player.trackSelectionParameters
                .buildUpon()
                .setOverrideForType(TrackSelectionOverride(found.first, found.second))
                .setTrackTypeDisabled(UMediaMapper.trackTypeOf(type), false)
                .build()
    }

    fun setAutoQuality() {
        player.trackSelectionParameters =
            player.trackSelectionParameters
                .buildUpon()
                .clearOverridesOfType(C.TRACK_TYPE_VIDEO)
                .clearVideoSizeConstraints()
                .build()
    }

    fun setMaxHeight(height: Int) {
        player.trackSelectionParameters =
            player.trackSelectionParameters
                .buildUpon()
                .setMaxVideoSize(Int.MAX_VALUE, if (height <= 0) Int.MAX_VALUE else height)
                .build()
    }

    fun enterPip(
        activity: Activity?,
        aspectRatio: Double,
    ): Boolean = UMediaPip.enter(activity, aspectRatio)

    fun describeEqualizer(): Map<String, Any?> {
        effects.attach(player.audioSessionId)
        return effects.describe()
    }

    fun setEqualizerEnabled(enabled: Boolean) {
        effects.attach(player.audioSessionId)
        effects.setEnabled(enabled)
    }

    fun setEqualizerBand(
        index: Int,
        gainDb: Double,
    ) {
        effects.attach(player.audioSessionId)
        effects.setBand(index, gainDb)
    }

    fun setEqualizerPreset(preset: String) {
        effects.attach(player.audioSessionId)
        effects.setPreset(preset)
    }

    fun setBassBoost(strength: Double) {
        effects.attach(player.audioSessionId)
        effects.setBassBoost(strength)
    }

    fun setVirtualizer(strength: Double) {
        effects.attach(player.audioSessionId)
        effects.setVirtualizer(strength)
    }

    fun setLoudness(gain: Double) {
        effects.attach(player.audioSessionId)
        effects.setLoudness(gain)
    }

    fun startVisualizer(bands: Int) {
        spectrum.setBandCount(bands)
        spectrum.enabled = true
    }

    fun stopVisualizer() {
        spectrum.enabled = false
    }

    fun screenshot(): ByteArray? {
        val uri = currentUri ?: return null
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(uri, HashMap())
            val bitmap: Bitmap = retriever.getFrameAtTime(player.currentPosition * 1000L) ?: return null
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            bitmap.recycle()
            stream.toByteArray()
        } catch (error: RuntimeException) {
            null
        } finally {
            retriever.release()
        }
    }

    private fun emitPosition() {
        val position = player.currentPosition
        if (position == lastSentPosition && !player.isPlaying) return
        lastSentPosition = position
        send(mapOf("event" to "position", "positionMs" to position, "bufferedMs" to player.bufferedPosition))
    }

    override fun onPlaybackStateChanged(playbackState: Int) {
        when (playbackState) {
            Player.STATE_BUFFERING -> send(mapOf("event" to "state", "state" to "buffering"))
            Player.STATE_READY -> {
                effects.attach(player.audioSessionId)
                send(
                    mapOf(
                        "event" to "initialized",
                        "textureId" to if (textureId >= 0) textureId else null,
                        "durationMs" to if (player.duration == C.TIME_UNSET) 0L else player.duration,
                        "width" to player.videoSize.width,
                        "height" to player.videoSize.height,
                        "rotation" to player.videoSize.unappliedRotationDegrees,
                        "isLive" to player.isCurrentMediaItemLive,
                        "tracks" to UMediaMapper.tracksToList(player.currentTracks),
                    ),
                )
                send(mapOf("event" to "state", "state" to if (player.isPlaying) "playing" else "paused"))
            }
            Player.STATE_ENDED -> {
                handler.removeCallbacks(positionTicker)
                send(mapOf("event" to "completed"))
            }
            Player.STATE_IDLE -> send(mapOf("event" to "state", "state" to "idle"))
        }
    }

    override fun onIsPlayingChanged(isPlaying: Boolean) {
        send(mapOf("event" to "state", "state" to if (isPlaying) "playing" else "paused"))
        if (isPlaying) {
            handler.removeCallbacks(positionTicker)
            handler.post(positionTicker)
        } else {
            handler.removeCallbacks(positionTicker)
        }
    }

    override fun onVideoSizeChanged(videoSize: VideoSize) {
        surfaceProducer?.setSize(videoSize.width, videoSize.height)
        send(
            mapOf(
                "event" to "size",
                "width" to videoSize.width,
                "height" to videoSize.height,
                "rotation" to videoSize.unappliedRotationDegrees,
            ),
        )
    }

    override fun onTracksChanged(tracks: Tracks) {
        send(mapOf("event" to "tracks", "tracks" to UMediaMapper.tracksToList(tracks)))
    }

    override fun onPlayerError(error: PlaybackException) {
        send(
            mapOf(
                "event" to "error",
                "code" to codeOf(error),
                "message" to (error.message ?: error.errorCodeName),
                "detail" to error.errorCodeName,
                "platformCode" to error.errorCodeName,
            ),
        )
    }

    private fun codeOf(error: PlaybackException): String =
        when (error.errorCode) {
            PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_FAILED,
            PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT,
            -> "network"
            PlaybackException.ERROR_CODE_IO_FILE_NOT_FOUND -> "notFound"
            PlaybackException.ERROR_CODE_IO_NO_PERMISSION -> "permission"
            PlaybackException.ERROR_CODE_DECODING_FORMAT_UNSUPPORTED,
            PlaybackException.ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED,
            -> "unsupportedFormat"
            PlaybackException.ERROR_CODE_DECODER_INIT_FAILED,
            PlaybackException.ERROR_CODE_DECODING_FAILED,
            -> "decoder"
            PlaybackException.ERROR_CODE_DRM_UNSPECIFIED,
            PlaybackException.ERROR_CODE_DRM_LICENSE_ACQUISITION_FAILED,
            -> "drm"
            else -> "unknown"
        }

    fun dispose() {
        handler.removeCallbacks(positionTicker)
        eventChannel.setStreamHandler(null)
        sink = null
        spectrum.enabled = false
        effects.release()
        UMediaService.unregister(id)
        mediaSession?.release()
        mediaSession = null
        player.removeListener(this)
        player.release()
        surfaceProducer?.release()
    }
}
