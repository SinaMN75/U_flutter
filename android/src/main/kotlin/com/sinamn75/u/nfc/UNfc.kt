package com.sinamn75.u.nfc

import android.Manifest
import android.app.Activity
import android.app.Application
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.cardemulation.CardEmulation
import android.nfc.tech.IsoDep
import android.nfc.tech.Ndef
import android.nfc.tech.NdefFormatable
import android.nfc.tech.NfcA
import android.nfc.tech.NfcB
import android.nfc.tech.NfcF
import android.nfc.tech.NfcV
import android.nfc.tech.TagTechnology
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger

/**
 * Native side of UNfc / UNfcCard / UNfcReader ("u/nfc").
 *
 * Card emulation: AIDs are registered at runtime on [UNfcHceService] (category "other"), so apps never
 * clash on a shared static AID. Reader mode: each discovered tag gets a handle; Dart drives it with
 * transceive / NDEF calls until it reports `tagDone`. Tag I/O runs on one background thread.
 */
class UNfcHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler,
    UNfcHce.Listener,
    Application.ActivityLifecycleCallbacks {
    private val channel = MethodChannel(messenger, "u/nfc")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val hceComponent = ComponentName(context, UNfcHceService::class.java)
    private val nextHandle = AtomicInteger(0)
    private val tags = ConcurrentHashMap<Int, Tag>()
    private val connected = ConcurrentHashMap<Int, TagTechnology>()

    private var activity: Activity? = null
    private var resumed = false
    private var readerOn = false

    private val adapter: NfcAdapter? get() = NfcAdapter.getDefaultAdapter(context)

    init {
        channel.setMethodCallHandler(this)
        UNfcHce.listener = this
        // AIDs registered without `persist` by a previous run that never called stop: drop them.
        if (!UNfcHce.isPersisted(context) && !UNfcHce.active) unregisterAids()
    }

    fun setActivity(value: Activity?) {
        if (activity === value) return
        activity?.application?.unregisterActivityLifecycleCallbacks(this)
        if (value == null) stopReader()
        activity = value
        resumed = value != null
        value?.application?.registerActivityLifecycleCallbacks(this)
        if (UNfcHce.active) setPreferred(true)
    }

    fun dispose() {
        stopReader()
        setActivity(null)
        if (!UNfcHce.isPersisted(context)) stopCard()
        if (UNfcHce.listener === this) UNfcHce.listener = null
        channel.setMethodCallHandler(null)
        io.shutdown()
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            "status" -> result.success(status())
            "openSettings" -> result.success(openSettings())
            "startCard" -> startCard(call, result)
            "stopCard" -> {
                stopCard()
                result.success(null)
            }
            "startReader" -> startReader(call, result)
            "stopReader" -> {
                stopReader()
                result.success(null)
            }
            "transceive" -> onTag(call, result) { tag, handle -> transceive(tag, handle, call) }
            "readNdef" -> onTag(call, result) { tag, handle -> readNdef(tag, handle) }
            "writeNdef" -> onTag(call, result) { tag, handle -> writeNdef(tag, handle, call) }
            "tagDone" -> {
                val handle = call.argument<Int>("handle") ?: -1
                io.execute { release(handle) }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // ---------------------------------------------------------------- status

    private fun status(): Map<String, Any?> {
        val a = adapter
        return mapOf(
            "nfc" to
                when {
                    a == null -> "unsupported"
                    a.isEnabled -> "enabled"
                    else -> "disabled"
                },
            "cardEmulation" to (a != null && context.packageManager.hasSystemFeature(PackageManager.FEATURE_NFC_HOST_CARD_EMULATION)),
            "reader" to (a != null),
            "permission" to hasPermission(),
            "cardActive" to UNfcHce.active,
            "readerActive" to readerOn,
        )
    }

    private fun openSettings(): Boolean =
        listOf(Settings.ACTION_NFC_SETTINGS, Settings.ACTION_WIRELESS_SETTINGS).any {
            try {
                val intent = Intent(it)
                val a = activity
                if (a != null) a.startActivity(intent) else context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                true
            } catch (_: Exception) {
                false
            }
        }

    private fun hasPermission(): Boolean = context.checkSelfPermission(Manifest.permission.NFC) == PackageManager.PERMISSION_GRANTED

    /** Shared checks; replies with an error and returns null when NFC can't be used. */
    private fun requireAdapter(result: MethodChannel.Result): NfcAdapter? {
        val a = adapter
        if (a == null) {
            result.error("unsupported", "This device has no NFC.", null)
            return null
        }
        if (!hasPermission()) {
            result.error("permission", "The app has no NFC permission. Run: dart run u:app permission add nfc", null)
            return null
        }
        if (!a.isEnabled) {
            result.error("disabled", "NFC is turned off. Call UNfc.openSettings().", null)
            return null
        }
        return a
    }

    // ---------------------------------------------------------------- card emulation

    private fun startCard(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val a = requireAdapter(result) ?: return
        if (!context.packageManager.hasSystemFeature(PackageManager.FEATURE_NFC_HOST_CARD_EMULATION)) {
            return result.error("unsupported", "This device can't emulate NFC cards (no HCE).", null)
        }
        val aids = call.argument<List<String>>("aids").orEmpty()
        val response = call.argument<ByteArray>("response")
        val forward = call.argument<Boolean>("forward") ?: false
        val persist = call.argument<Boolean>("persist") ?: false
        try {
            val emulation = CardEmulation.getInstance(a)
            emulation.removeAidsForService(hceComponent, CardEmulation.CATEGORY_OTHER)
            if (!emulation.registerAidsForService(hceComponent, CardEmulation.CATEGORY_OTHER, aids)) {
                return result.error("aid", "Android rejected the AIDs $aids.", null)
            }
            UNfcHce.set(context, aids, response, forward, persist)
            setPreferred(true)
            result.success(null)
        } catch (e: Exception) {
            result.error("error", e.message, null)
        }
    }

    private fun stopCard() {
        UNfcHce.clear(context)
        setPreferred(false)
        unregisterAids()
    }

    private fun unregisterAids() {
        try {
            val a = adapter ?: return
            if (!hasPermission()) return
            CardEmulation.getInstance(a).removeAidsForService(hceComponent, CardEmulation.CATEGORY_OTHER)
        } catch (_: Exception) {
        }
    }

    /** While the app is in front, our service wins routing even if another app registered the same AID. */
    private fun setPreferred(preferred: Boolean) {
        try {
            val a = adapter ?: return
            val act = activity ?: return
            val emulation = CardEmulation.getInstance(a)
            if (preferred && resumed && UNfcHce.active) {
                emulation.setPreferredService(act, hceComponent)
            } else if (!preferred) {
                emulation.unsetPreferredService(act)
            }
        } catch (_: Exception) {
        }
    }

    override fun onCardEvent(event: Map<String, Any?>) {
        main.post { channel.invokeMethod("cardEvent", event) }
    }

    override fun onCommand(
        apdu: ByteArray,
        reply: (ByteArray) -> Unit,
    ) {
        main.post {
            channel.invokeMethod(
                "command",
                apdu,
                object : MethodChannel.Result {
                    override fun success(value: Any?) = reply(value as? ByteArray ?: UNfcBytes.SW_UNKNOWN)

                    override fun error(
                        code: String,
                        message: String?,
                        details: Any?,
                    ) = reply(UNfcBytes.SW_UNKNOWN)

                    override fun notImplemented() = reply(UNfcBytes.SW_INS_NOT_SUPPORTED)
                },
            )
        }
    }

    // ---------------------------------------------------------------- reader mode

    private fun startReader(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val a = requireAdapter(result) ?: return
        val act = activity ?: return result.error("noActivity", "Reader mode needs a foreground activity.", null)
        val techs = call.argument<List<String>>("techs") ?: listOf("a", "b", "f", "v")
        var flags = 0
        if ("a" in techs) flags = flags or NfcAdapter.FLAG_READER_NFC_A
        if ("b" in techs) flags = flags or NfcAdapter.FLAG_READER_NFC_B
        if ("f" in techs) flags = flags or NfcAdapter.FLAG_READER_NFC_F
        if ("v" in techs) flags = flags or NfcAdapter.FLAG_READER_NFC_V
        if (call.argument<Boolean>("skipNdef") == true) flags = flags or NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK
        if (call.argument<Boolean>("sound") == false) flags = flags or NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS
        val extras = Bundle()
        call.argument<Int>("presenceCheckMs")?.let { extras.putInt(NfcAdapter.EXTRA_READER_PRESENCE_CHECK_DELAY, it) }
        try {
            a.enableReaderMode(act, { tag -> onTagDiscovered(tag) }, flags, extras)
            readerOn = true
            result.success(null)
        } catch (e: Exception) {
            result.error("error", e.message, null)
        }
    }

    private fun stopReader() {
        if (readerOn) {
            try {
                activity?.let { adapter?.disableReaderMode(it) }
            } catch (_: Exception) {
            }
        }
        readerOn = false
        connected.keys.toList().forEach { release(it) }
        tags.clear()
    }

    private fun onTagDiscovered(tag: Tag) {
        val handle = nextHandle.incrementAndGet()
        tags[handle] = tag
        val ndef = Ndef.get(tag)
        val info =
            mapOf(
                "handle" to handle,
                "id" to tag.id,
                "techs" to tag.techList.map { it.substringAfterLast('.') },
                "ndef" to ndef?.cachedNdefMessage?.let { records(it) },
                "ndefWritable" to (ndef?.isWritable ?: false),
                "ndefMaxSize" to (ndef?.maxSize ?: 0),
                "ndefFormatable" to (NdefFormatable.get(tag) != null),
                "historicalBytes" to IsoDep.get(tag)?.let { it.historicalBytes ?: it.hiLayerResponse },
            )
        main.post { channel.invokeMethod("tag", info) }
    }

    /** Runs [block] on the I/O thread against the tag behind `handle`, replying on the main thread. */
    private fun onTag(
        call: MethodCall,
        result: MethodChannel.Result,
        block: (Tag, Int) -> Any?,
    ) {
        val handle = call.argument<Int>("handle") ?: -1
        io.execute {
            val tag = tags[handle]
            if (tag == null) {
                main.post { result.error("tagLost", "The tag is no longer available.", null) }
                return@execute
            }
            try {
                val value = block(tag, handle)
                main.post { result.success(value) }
            } catch (e: android.nfc.TagLostException) {
                release(handle)
                main.post { result.error("tagLost", "The tag left the field.", null) }
            } catch (e: Exception) {
                main.post { result.error("io", e.message ?: e.javaClass.simpleName, null) }
            }
        }
    }

    /** Connects (or reuses) one technology on the tag; only one can be connected at a time. */
    private fun <T : TagTechnology> connect(
        handle: Int,
        tech: T?,
        name: String,
    ): T {
        if (tech == null) throw IllegalStateException("The tag doesn't support $name.")
        val current = connected[handle]
        if (current != null && current.javaClass == tech.javaClass && current.isConnected) {
            @Suppress("UNCHECKED_CAST")
            return current as T
        }
        current?.let { runCatching { it.close() } }
        tech.connect()
        connected[handle] = tech
        return tech
    }

    private fun transceive(
        tag: Tag,
        handle: Int,
        call: MethodCall,
    ): ByteArray {
        val data = call.argument<ByteArray>("data") ?: ByteArray(0)
        val timeout = call.argument<Int>("timeoutMs")
        return when (call.argument<String>("tech") ?: "isoDep") {
            "nfcA" -> connect(handle, NfcA.get(tag), "NfcA").also { t -> timeout?.let { t.timeout = it } }.transceive(data)
            "nfcB" -> connect(handle, NfcB.get(tag), "NfcB").transceive(data)
            "nfcF" -> connect(handle, NfcF.get(tag), "NfcF").also { t -> timeout?.let { t.timeout = it } }.transceive(data)
            "nfcV" -> connect(handle, NfcV.get(tag), "NfcV").transceive(data)
            else -> connect(handle, IsoDep.get(tag), "IsoDep").also { t -> timeout?.let { t.timeout = it } }.transceive(data)
        }
    }

    private fun readNdef(
        tag: Tag,
        handle: Int,
    ): List<Map<String, Any?>>? {
        val ndef = connect(handle, Ndef.get(tag), "NDEF")
        return ndef.ndefMessage?.let { records(it) }
    }

    private fun writeNdef(
        tag: Tag,
        handle: Int,
        call: MethodCall,
    ): Any? {
        val raw = call.argument<List<Map<String, Any?>>>("records").orEmpty()
        val message =
            NdefMessage(
                raw
                    .map {
                        NdefRecord(
                            (it["tnf"] as Int).toShort(),
                            it["type"] as? ByteArray ?: ByteArray(0),
                            it["id"] as? ByteArray ?: ByteArray(0),
                            it["payload"] as? ByteArray ?: ByteArray(0),
                        )
                    }.toTypedArray(),
            )
        val ndef = Ndef.get(tag)
        if (ndef != null) {
            val connectedNdef = connect(handle, ndef, "NDEF")
            if (!connectedNdef.isWritable) throw IllegalStateException("The tag is read-only.")
            connectedNdef.writeNdefMessage(message)
        } else {
            connect(handle, NdefFormatable.get(tag), "NDEF").format(message)
        }
        if (call.argument<Boolean>("lock") == true) {
            connect(handle, Ndef.get(tag), "NDEF").makeReadOnly()
        }
        return null
    }

    private fun records(message: NdefMessage): List<Map<String, Any?>> =
        message.records.map {
            mapOf("tnf" to it.tnf.toInt(), "type" to it.type, "id" to it.id, "payload" to it.payload)
        }

    private fun release(handle: Int) {
        connected.remove(handle)?.let { runCatching { it.close() } }
        tags.remove(handle)
    }

    // ---------------------------------------------------------------- activity lifecycle

    override fun onActivityResumed(a: Activity) {
        if (a !== activity) return
        resumed = true
        if (UNfcHce.active) setPreferred(true)
    }

    override fun onActivityPaused(a: Activity) {
        if (a !== activity) return
        setPreferred(false)
        resumed = false
    }

    override fun onActivityCreated(
        a: Activity,
        b: Bundle?,
    ) {}

    override fun onActivityStarted(a: Activity) {}

    override fun onActivityStopped(a: Activity) {}

    override fun onActivitySaveInstanceState(
        a: Activity,
        b: Bundle,
    ) {}

    override fun onActivityDestroyed(a: Activity) {}
}
