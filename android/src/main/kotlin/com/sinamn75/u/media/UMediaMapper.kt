package com.sinamn75.u.media

import android.content.Context
import android.net.Uri
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.TrackGroup
import androidx.media3.common.Tracks
import androidx.media3.common.util.UnstableApi
import io.flutter.FlutterInjector
import java.io.File

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
