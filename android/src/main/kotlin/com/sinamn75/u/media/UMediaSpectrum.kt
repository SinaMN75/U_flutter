package com.sinamn75.u.media

import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.audio.TeeAudioProcessor
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.ln
import kotlin.math.min
import kotlin.math.sin

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
