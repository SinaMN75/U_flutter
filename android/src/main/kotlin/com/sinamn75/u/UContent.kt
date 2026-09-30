package com.sinamn75.u

import android.content.Context
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File
import java.util.UUID

/** Turns file paths into content:// URIs other apps may read, through the u FileProvider. */
internal object UContent {
    fun authority(context: Context) = "${context.packageName}.u.fileprovider"

    /**
     * A shareable URI for [path]. content:// strings pass through; files outside the provider's
     * roots (files, cache and their external twins) are copied into cache/u_share first.
     */
    fun uriFor(
        context: Context,
        path: String,
    ): Uri? {
        if (path.startsWith("content://")) return Uri.parse(path)
        val file = File(if (path.startsWith("file://")) Uri.parse(path).path ?: return null else path)
        if (!file.exists()) return null
        return try {
            FileProvider.getUriForFile(context, authority(context), file)
        } catch (_: IllegalArgumentException) {
            val copy = File(File(context.cacheDir, "u_share/${UUID.randomUUID()}").apply { mkdirs() }, file.name)
            file.copyTo(copy, overwrite = true)
            FileProvider.getUriForFile(context, authority(context), copy)
        }
    }

    /** Best-effort MIME type from a file name. */
    fun mimeOf(name: String): String {
        val ext = name.substringAfterLast('.', "").lowercase()
        return android.webkit.MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext) ?: "application/octet-stream"
    }
}
