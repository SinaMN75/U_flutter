package com.sinamn75.u.nfc

import android.content.Context
import android.nfc.cardemulation.HostApduService
import android.os.Bundle

/**
 * Card-emulation state shared by [UNfcHceService] (bound by the NFC stack) and [UNfcHandler] (the Flutter side).
 *
 * The service is declared in u's manifest with no static AIDs, so it is inert in every app until
 * `UNfcCard.start` registers AIDs at runtime. `persist` keeps the config in prefs so the phone keeps
 * answering after the app is closed (the NFC stack starts the process and binds the service on demand).
 */
object UNfcHce {
    private const val PREFS = "u_nfc_hce"

    @Volatile
    var aids: List<String> = emptyList()

    /** Answer to a SELECT of one of [aids] (status word appended natively), or null to forward it to Dart. */
    @Volatile
    var response: ByteArray? = null

    /** Forward every APDU without a native answer to Dart (needs the Flutter engine alive). */
    @Volatile
    var forward = false

    /** Set by UNfcHandler while a Flutter engine is attached. */
    @Volatile
    var listener: Listener? = null

    interface Listener {
        fun onCardEvent(event: Map<String, Any?>)

        fun onCommand(
            apdu: ByteArray,
            reply: (ByteArray) -> Unit,
        )
    }

    val active: Boolean get() = aids.isNotEmpty()

    fun set(
        context: Context,
        aids: List<String>,
        response: ByteArray?,
        forward: Boolean,
        persist: Boolean,
    ) {
        this.aids = aids
        this.response = response
        this.forward = forward
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
        if (persist && response != null) {
            prefs.putString("aids", aids.joinToString(",")).putString("response", UNfcBytes.toHex(response))
        } else {
            prefs.clear()
        }
        prefs.apply()
    }

    fun clear(context: Context) {
        aids = emptyList()
        response = null
        forward = false
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply()
    }

    fun isPersisted(context: Context): Boolean = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).contains("aids")

    /** Cold start by the NFC stack (app was closed): reload a persisted config. */
    fun restore(context: Context) {
        if (active) return
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val saved = prefs.getString("aids", null) ?: return
        aids = saved.split(",").filter { it.isNotEmpty() }
        response = prefs.getString("response", null)?.let { UNfcBytes.fromHex(it) }
        forward = false
    }

    fun matches(aid: String): Boolean = aids.any { if (it.endsWith("*")) aid.startsWith(it.dropLast(1)) else aid == it }

    fun emit(event: Map<String, Any?>) {
        listener?.onCardEvent(event)
    }
}

/** HostApduService behind UNfcCard: answers the reader's APDUs natively or forwards them to Dart. */
class UNfcHceService : HostApduService() {
    private var selectedAid: String? = null

    override fun processCommandApdu(
        commandApdu: ByteArray?,
        extras: Bundle?,
    ): ByteArray? {
        val apdu = commandApdu ?: return UNfcBytes.SW_WRONG_LENGTH
        UNfcHce.restore(applicationContext)
        if (!UNfcHce.active) return UNfcBytes.SW_FILE_NOT_FOUND

        val select = UNfcBytes.selectedAid(apdu)
        if (select != null) {
            if (!UNfcHce.matches(select)) return UNfcBytes.SW_FILE_NOT_FOUND
            selectedAid = select
            UNfcHce.emit(mapOf("type" to "selected", "aid" to select))
            val response = UNfcHce.response
            if (response != null) {
                UNfcHce.emit(mapOf("type" to "read", "aid" to select))
                return response + UNfcBytes.SW_OK
            }
        }

        val listener = UNfcHce.listener
        if (!UNfcHce.forward || listener == null) {
            return if (select != null) UNfcBytes.SW_OK else UNfcBytes.SW_INS_NOT_SUPPORTED
        }
        // Answered asynchronously; the NFC stack keeps the reader waiting (WTX) until sendResponseApdu.
        listener.onCommand(apdu) { sendResponseApdu(it) }
        return null
    }

    override fun onDeactivated(reason: Int) {
        val aid = selectedAid
        selectedAid = null
        UNfcHce.emit(
            mapOf(
                "type" to "deactivated",
                "aid" to aid,
                "reason" to if (reason == DEACTIVATION_DESELECTED) "deselected" else "linkLoss",
            ),
        )
    }
}

/** Hex and ISO 7816 helpers shared by the NFC classes. */
object UNfcBytes {
    val SW_OK = byteArrayOf(0x90.toByte(), 0x00)
    val SW_FILE_NOT_FOUND = byteArrayOf(0x6A, 0x82.toByte())
    val SW_INS_NOT_SUPPORTED = byteArrayOf(0x6D, 0x00)
    val SW_WRONG_LENGTH = byteArrayOf(0x67, 0x00)
    val SW_UNKNOWN = byteArrayOf(0x6F, 0x00)

    fun toHex(bytes: ByteArray): String = bytes.joinToString("") { "%02X".format(it) }

    fun fromHex(hex: String): ByteArray = ByteArray(hex.length / 2) { hex.substring(it * 2, it * 2 + 2).toInt(16).toByte() }

    /** AID of a `00 A4 04 xx Lc <AID>` SELECT, or null for any other command. */
    fun selectedAid(apdu: ByteArray): String? {
        if (apdu.size < 5 || apdu[1] != 0xA4.toByte() || apdu[2] != 0x04.toByte()) return null
        val lc = apdu[4].toInt() and 0xFF
        if (lc == 0 || apdu.size < 5 + lc) return null
        return toHex(apdu.copyOfRange(5, 5 + lc))
    }
}
