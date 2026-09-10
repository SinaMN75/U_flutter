package com.sinamn75.u.media

import android.app.Activity
import android.app.PictureInPictureParams
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.media.AudioManager
import android.media.MediaMetadataRetriever
import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
import android.media.audiofx.Virtualizer
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Rational
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.TrackGroup
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
import androidx.media3.session.MediaSessionService
import io.flutter.FlutterInjector
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.ln
import kotlin.math.min
import kotlin.math.sin

@UnstableApi
object UMediaMapper {
    fun buildMediaItem(
        context: Context,
        source: Map<*, *>,
    ): MediaItem {
        val builder = MediaItem.Builder().setUri(resolveUri(context, source))

        (source["id"] as? String)?.let { builder.setMediaId(it) }
        (source["metadata"] as? Map<*, *>)?.let { builder.setMediaMetadata(buildMetadata(it)) }

        val startMs = (source["startMs"] as? Number)?.toLong()
        val endMs = (source["endMs"] as? Number)?.toLong()
        if (startMs != null || endMs != null) {
            builder.setClippingConfiguration(
                MediaItem.ClippingConfiguration
                    .Builder()
                    .setStartPositionMs(startMs ?: 0L)
                    .setEndPositionMs(endMs ?: C.TIME_END_OF_SOURCE)
                    .build(),
            )
        }

        (source["drm"] as? Map<*, *>)?.let { drm ->
            val uuid =
                when (drm["scheme"] as? String) {
                    "widevine" -> C.WIDEVINE_UUID
                    "playready" -> C.PLAYREADY_UUID
                    "clearkey" -> C.CLEARKEY_UUID
                    else -> null
                }
            if (uuid != null) {
                val drmBuilder = MediaItem.DrmConfiguration.Builder(uuid)
                (drm["licenseUrl"] as? String)?.let { drmBuilder.setLicenseUri(it) }
                @Suppress("UNCHECKED_CAST")
                (drm["headers"] as? Map<String, String>)?.let { drmBuilder.setLicenseRequestHeaders(it) }
                (drm["multiSession"] as? Boolean)?.let { drmBuilder.setMultiSession(it) }
                builder.setDrmConfiguration(drmBuilder.build())
            }
        }

        return builder.build()
    }

    private fun resolveUri(
        context: Context,
        source: Map<*, *>,
    ): Uri =
        when (source["kind"] as? String) {
            "network" -> Uri.parse(source["url"] as? String ?: "")
            "file" -> Uri.fromFile(File(source["path"] as? String ?: ""))
            "asset" -> {
                val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(source["asset"] as? String ?: "")
                Uri.parse("asset:///$key")
            }
            "content" -> Uri.parse(source["uri"] as? String ?: "")
            "bytes" -> Uri.fromFile(writeTempFile(context, source["bytes"] as? ByteArray ?: ByteArray(0)))
            else -> Uri.EMPTY
        }

    private fun writeTempFile(
        context: Context,
        bytes: ByteArray,
    ): File {
        val directory = File(context.cacheDir, "u_media")
        if (!directory.exists()) directory.mkdirs()
        val file = File(directory, "src_${bytes.size}_${bytes.contentHashCode()}.bin")
        if (!file.exists() || file.length().toInt() != bytes.size) file.writeBytes(bytes)
        return file
    }

    private fun buildMetadata(map: Map<*, *>): MediaMetadata {
        val builder = MediaMetadata.Builder()
        (map["title"] as? String)?.let { builder.setTitle(it) }
        (map["artist"] as? String)?.let { builder.setArtist(it) }
        (map["album"] as? String)?.let { builder.setAlbumTitle(it) }
        (map["albumArtist"] as? String)?.let { builder.setAlbumArtist(it) }
        (map["genre"] as? String)?.let { builder.setGenre(it) }
        (map["trackNumber"] as? Number)?.let { builder.setTrackNumber(it.toInt()) }
        (map["artworkUri"] as? String)?.let { builder.setArtworkUri(Uri.parse(it)) }
        return builder.build()
    }

    fun tracksToList(tracks: Tracks): List<Map<String, Any?>> {
        val result = mutableListOf<Map<String, Any?>>()
        tracks.groups.forEachIndexed { groupIndex, group ->
            val typeName =
                when (group.type) {
                    C.TRACK_TYPE_VIDEO -> "video"
                    C.TRACK_TYPE_AUDIO -> "audio"
                    C.TRACK_TYPE_TEXT -> "subtitle"
                    else -> null
                } ?: return@forEachIndexed

            for (trackIndex in 0 until group.length) {
                val format: Format = group.getTrackFormat(trackIndex)
                result.add(
                    mapOf(
                        "id" to "$groupIndex:$trackIndex",
                        "type" to typeName,
                        "label" to format.label,
                        "language" to format.language,
                        "codec" to format.codecs,
                        "bitrate" to format.bitrate.takeIf { it != Format.NO_VALUE },
                        "width" to format.width.takeIf { it != Format.NO_VALUE },
                        "height" to format.height.takeIf { it != Format.NO_VALUE },
                        "frameRate" to format.frameRate.takeIf { it != Format.NO_VALUE.toFloat() }?.toDouble(),
                        "channels" to format.channelCount.takeIf { it != Format.NO_VALUE },
                        "sampleRate" to format.sampleRate.takeIf { it != Format.NO_VALUE },
                        "isDefault" to ((format.selectionFlags and C.SELECTION_FLAG_DEFAULT) != 0),
                        "isForced" to ((format.selectionFlags and C.SELECTION_FLAG_FORCED) != 0),
                        "isSelected" to group.isTrackSelected(trackIndex),
                        "isAuto" to false,
                    ),
                )
            }
        }
        return result
    }

    fun findGroup(
        tracks: Tracks,
        trackId: String,
    ): Pair<TrackGroup, Int>? {
        val parts = trackId.split(":")
        if (parts.size != 2) return null
        val groupIndex = parts[0].toIntOrNull() ?: return null
        val trackIndex = parts[1].toIntOrNull() ?: return null
        if (groupIndex < 0 || groupIndex >= tracks.groups.size) return null
        val group = tracks.groups[groupIndex]
        if (trackIndex < 0 || trackIndex >= group.length) return null
        return group.mediaTrackGroup to trackIndex
    }

    fun trackTypeOf(name: String?): Int =
        when (name) {
            "audio" -> C.TRACK_TYPE_AUDIO
            "subtitle" -> C.TRACK_TYPE_TEXT
            else -> C.TRACK_TYPE_VIDEO
        }
}

class UMediaEffects {
    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var loudness: LoudnessEnhancer? = null
    private var sessionId = 0
    private var preset: String? = null

    fun attach(audioSessionId: Int) {
        if (audioSessionId == 0 || audioSessionId == sessionId) return
        release()
        sessionId = audioSessionId
        runCatching { equalizer = Equalizer(0, audioSessionId) }
        runCatching { bassBoost = BassBoost(0, audioSessionId) }
        runCatching { virtualizer = Virtualizer(0, audioSessionId) }
        runCatching { loudness = LoudnessEnhancer(audioSessionId) }
    }

    fun release() {
        runCatching { equalizer?.release() }
        runCatching { bassBoost?.release() }
        runCatching { virtualizer?.release() }
        runCatching { loudness?.release() }
        equalizer = null
        bassBoost = null
        virtualizer = null
        loudness = null
        sessionId = 0
    }

    fun describe(): Map<String, Any?> {
        val current = equalizer
        if (current == null) return mapOf("available" to false)

        val bands = mutableListOf<Map<String, Any?>>()
        val range = runCatching { current.bandLevelRange }.getOrNull()
        val minDb = (range?.getOrNull(0) ?: -1500).toDouble() / 100.0
        val maxDb = (range?.getOrNull(1) ?: 1500).toDouble() / 100.0

        val count = runCatching { current.numberOfBands.toInt() }.getOrDefault(0)
        for (index in 0 until count) {
            bands.add(
                mapOf(
                    "index" to index,
                    "centerFrequencyHz" to runCatching { current.getCenterFreq(index.toShort()) / 1000 }.getOrDefault(0),
                    "gainDb" to runCatching { current.getBandLevel(index.toShort()).toDouble() / 100.0 }.getOrDefault(0.0),
                    "minDb" to minDb,
                    "maxDb" to maxDb,
                ),
            )
        }

        val presets = mutableListOf<String>()
        val presetCount = runCatching { current.numberOfPresets.toInt() }.getOrDefault(0)
        for (index in 0 until presetCount) {
            runCatching { presets.add(current.getPresetName(index.toShort())) }
        }

        return mapOf(
            "available" to true,
            "enabled" to (runCatching { current.enabled }.getOrDefault(false)),
            "bands" to bands,
            "presets" to presets,
            "preset" to preset,
            "bassBoost" to (runCatching { (bassBoost?.roundedStrength ?: 0).toDouble() / 1000.0 }.getOrDefault(0.0)),
            "virtualizer" to (runCatching { (virtualizer?.roundedStrength ?: 0).toDouble() / 1000.0 }.getOrDefault(0.0)),
            "loudness" to (runCatching { (loudness?.targetGain ?: 0f).toDouble() / 1000.0 }.getOrDefault(0.0)),
        )
    }

    fun setEnabled(enabled: Boolean) {
        runCatching { equalizer?.enabled = enabled }
        runCatching { bassBoost?.enabled = enabled }
        runCatching { virtualizer?.enabled = enabled }
        runCatching { loudness?.enabled = enabled }
    }

    fun setBand(
        index: Int,
        gainDb: Double,
    ) {
        runCatching {
            equalizer?.enabled = true
            equalizer?.setBandLevel(index.toShort(), (gainDb * 100).toInt().toShort())
        }
        preset = null
    }

    fun setPreset(name: String) {
        val current = equalizer ?: return
        runCatching {
            val count = current.numberOfPresets.toInt()
            for (index in 0 until count) {
                if (current.getPresetName(index.toShort()) == name) {
                    current.enabled = true
                    current.usePreset(index.toShort())
                    preset = name
                    return
                }
            }
        }
    }

    fun setBassBoost(strength: Double) {
        runCatching {
            bassBoost?.enabled = strength > 0
            bassBoost?.setStrength((strength.coerceIn(0.0, 1.0) * 1000).toInt().toShort())
        }
    }

    fun setVirtualizer(strength: Double) {
        runCatching {
            virtualizer?.enabled = strength > 0
            virtualizer?.setStrength((strength.coerceIn(0.0, 1.0) * 1000).toInt().toShort())
        }
    }

    fun setLoudness(gain: Double) {
        runCatching {
            loudness?.enabled = gain > 0
            loudness?.setTargetGain((gain.coerceIn(0.0, 1.0) * 1000).toInt())
        }
    }
}

/**
 * Reads PCM straight out of the Media3 audio pipeline through TeeAudioProcessor, so the
 * spectrum needs no RECORD_AUDIO permission (the platform Visualizer API would).
 */
@UnstableApi
class UMediaSpectrum(
    private val onBands: (DoubleArray) -> Unit,
) : TeeAudioProcessor.AudioBufferSink {
    private companion object {
        const val FFT_SIZE = 1024
        const val MIN_INTERVAL_MS = 40L
    }

    private val samples = FloatArray(FFT_SIZE)
    private val real = DoubleArray(FFT_SIZE)
    private val imaginary = DoubleArray(FFT_SIZE)
    private val window = DoubleArray(FFT_SIZE) { 0.5 - 0.5 * cos(2.0 * Math.PI * it / (FFT_SIZE - 1)) }

    private var writeIndex = 0
    private var channelCount = 2
    private var encoding = 2
    private var bandCount = 48
    private var lastEmit = 0L

    var enabled = false

    fun setBandCount(count: Int) {
        bandCount = count.coerceIn(8, 128)
    }

    override fun flush(
        sampleRateHz: Int,
        channelCount: Int,
        encoding: Int,
    ) {
        this.channelCount = channelCount.coerceAtLeast(1)
        this.encoding = encoding
        writeIndex = 0
    }

    override fun handleBuffer(buffer: ByteBuffer) {
        if (!enabled) return
        val view = buffer.duplicate().order(ByteOrder.nativeOrder())
        while (view.remaining() >= 2 * channelCount) {
            var sum = 0f
            for (channel in 0 until channelCount) {
                sum += view.short.toFloat() / Short.MAX_VALUE
            }
            samples[writeIndex++] = sum / channelCount
            if (writeIndex >= FFT_SIZE) {
                writeIndex = 0
                maybeEmit()
            }
        }
    }

    private fun maybeEmit() {
        val now = System.currentTimeMillis()
        if (now - lastEmit < MIN_INTERVAL_MS) return
        lastEmit = now

        for (i in 0 until FFT_SIZE) {
            real[i] = samples[i] * window[i]
            imaginary[i] = 0.0
        }
        transform()

        val usable = FFT_SIZE / 2
        val output = DoubleArray(bandCount)
        for (band in 0 until bandCount) {
            val start = binFor(band, usable)
            val end = min(binFor(band + 1, usable), usable)
            var peak = 0.0
            for (bin in start until end.coerceAtLeast(start + 1)) {
                val magnitude = hypot(real[bin], imaginary[bin])
                if (magnitude > peak) peak = magnitude
            }
            val decibels = 20.0 * ln(peak + 1e-9) / ln(10.0)
            output[band] = ((decibels + 70.0) / 70.0).coerceIn(0.0, 1.0)
        }
        onBands(output)
    }

    private fun binFor(
        band: Int,
        usable: Int,
    ): Int {
        val ratio = band.toDouble() / bandCount
        val scaled = Math.pow(usable.toDouble(), ratio)
        return scaled.toInt().coerceIn(0, usable)
    }

    private fun transform() {
        var j = 0
        for (i in 0 until FFT_SIZE - 1) {
            if (i < j) {
                val tempReal = real[i]
                real[i] = real[j]
                real[j] = tempReal
                val tempImaginary = imaginary[i]
                imaginary[i] = imaginary[j]
                imaginary[j] = tempImaginary
            }
            var k = FFT_SIZE shr 1
            while (k in 1..j) {
                j -= k
                k = k shr 1
            }
            j += k
        }

        var length = 2
        while (length <= FFT_SIZE) {
            val angle = -2.0 * Math.PI / length
            val stepReal = cos(angle)
            val stepImaginary = sin(angle)
            var index = 0
            while (index < FFT_SIZE) {
                var currentReal = 1.0
                var currentImaginary = 0.0
                for (offset in 0 until length / 2) {
                    val a = index + offset
                    val b = a + length / 2
                    val productReal = currentReal * real[b] - currentImaginary * imaginary[b]
                    val productImaginary = currentReal * imaginary[b] + currentImaginary * real[b]
                    real[b] = real[a] - productReal
                    imaginary[b] = imaginary[a] - productImaginary
                    real[a] += productReal
                    imaginary[a] += productImaginary
                    val nextReal = currentReal * stepReal - currentImaginary * stepImaginary
                    currentImaginary = currentReal * stepImaginary + currentImaginary * stepReal
                    currentReal = nextReal
                }
                index += length
            }
            length = length shl 1
        }
    }
}

object UMediaPip {
    fun isSupported(activity: Activity?): Boolean {
        val current = activity ?: return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return current.packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
    }

    fun enter(
        activity: Activity?,
        aspectRatio: Double,
    ): Boolean {
        val current = activity ?: return false
        if (!isSupported(current)) return false
        val safeRatio = if (aspectRatio.isFinite() && aspectRatio > 0.42 && aspectRatio < 2.38) aspectRatio else 16.0 / 9.0
        val numerator = (safeRatio * 1000).toInt()
        val params =
            PictureInPictureParams
                .Builder()
                .setAspectRatio(Rational(numerator, 1000))
                .build()
        return current.enterPictureInPictureMode(params)
    }

    fun exit(activity: Activity?) {
        val current = activity ?: return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        if (current.isInPictureInPictureMode) current.moveTaskToBack(false)
    }
}

@UnstableApi
class UMediaService : MediaSessionService() {
    companion object {
        private val sessions = linkedMapOf<Int, MediaSession>()

        fun register(
            id: Int,
            session: MediaSession,
        ) {
            sessions[id] = session
        }

        fun unregister(id: Int) {
            sessions.remove(id)
        }

        fun current(): MediaSession? = sessions.values.lastOrNull()
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? = current()

    override fun onTaskRemoved(rootIntent: Intent?) {
        val session = current()
        if (session == null || !session.player.playWhenReady || session.player.mediaItemCount == 0) {
            stopSelf()
        }
        super.onTaskRemoved(rootIntent)
    }
}

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
