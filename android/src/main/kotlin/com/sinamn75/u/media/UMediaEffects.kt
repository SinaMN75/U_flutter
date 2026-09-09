package com.sinamn75.u.media

import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
import android.media.audiofx.Virtualizer

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
