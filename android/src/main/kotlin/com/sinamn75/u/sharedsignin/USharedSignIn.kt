package com.sinamn75.u.sharedsignin

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

private const val PREFS = "u_shared_sign_in"
private const val KEY = "account"
private const val COLUMN = "account"

/**
 * Hands this app's shared sign-in record to sibling apps. Not declared by the plugin: an app opts in by declaring it
 * in its own manifest with authority "<applicationId>.u.sharedsignin" and a signature-level permission, so only
 * apps signed with the same key can read it.
 */
class USharedSignInProvider : ContentProvider() {
    override fun onCreate(): Boolean = true

    override fun query(uri: Uri, projection: Array<out String>?, selection: String?, selectionArgs: Array<out String>?, sortOrder: String?): Cursor {
        val cursor = MatrixCursor(arrayOf(COLUMN))
        val json = context?.getSharedPreferences(PREFS, Context.MODE_PRIVATE)?.getString(KEY, null)
        if (json != null) cursor.addRow(arrayOf(json))
        return cursor
    }

    override fun getType(uri: Uri): String? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0

    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int = 0
}

/** "u/shared_sign_in": write and clear this app's record, read the records of the sibling providers. */
class USharedSignInHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "u/shared_sign_in")
    private val io = Executors.newSingleThreadExecutor()

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        when (call.method) {
            "write" -> {
                prefs.edit().putString(KEY, call.argument<String>("json")).apply()
                result.success(true)
            }
            "clear" -> {
                prefs.edit().remove(KEY).apply()
                result.success(true)
            }
            "read" -> {
                val authorities = call.argument<List<String>>("authorities") ?: emptyList()
                io.execute {
                    val records = authorities.mapNotNull { readFrom(it) }
                    android.os.Handler(android.os.Looper.getMainLooper()).post { result.success(records) }
                }
            }
            else -> result.notImplemented()
        }
    }

    // A sibling that is not installed, not signed with the same key or not opted in simply yields nothing.
    private fun readFrom(authority: String): String? =
        try {
            context.contentResolver.query(Uri.parse("content://$authority/account"), null, null, null, null)?.use { c ->
                if (c.moveToFirst()) c.getString(0) else null
            }
        } catch (e: Exception) {
            null
        }

    fun dispose() {
        channel.setMethodCallHandler(null)
        io.shutdown()
    }
}
