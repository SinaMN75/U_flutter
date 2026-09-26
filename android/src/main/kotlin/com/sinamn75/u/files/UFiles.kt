package com.sinamn75.u.files

import android.Manifest
import android.app.Activity
import android.app.DownloadManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.media.MediaScannerConnection
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.StatFs
import android.provider.MediaStore
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import android.util.Base64
import android.webkit.MimeTypeMap
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileInputStream
import java.security.KeyStore
import java.util.concurrent.Executors
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Native side of the "u/files" channel: public Downloads through MediaStore, the
 * "save as" document picker, opening files through a FileProvider, a dataSync
 * foreground service that keeps downloads alive in the background, Keystore
 * backed secrets for the vault master key, and DownloadManager for downloads
 * that must survive the app being killed.
 */
class UFilesHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler,
    PluginRegistry.ActivityResultListener,
    PluginRegistry.RequestPermissionsResultListener {
    private val channel = MethodChannel(messenger, "u/files")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var activity: Activity? = null

    private var pendingSaveAs: Pair<String, MethodChannel.Result>? = null
    private var pendingPermission: (() -> Unit)? = null
    private var pendingPermissionDenied: (() -> Unit)? = null

    init {
        channel.setMethodCallHandler(this)
    }

    fun setActivity(activity: Activity?) {
        this.activity = activity
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        io.shutdown()
        activity = null
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            "freeSpace" -> result.success(freeSpace(call.argument<String>("path") ?: context.filesDir.path))
            "saveToDownloads" -> saveToDownloads(call, result)
            "saveAs" -> saveAs(call, result)
            "open" -> result.success(open(call.argument<String>("path")!!, call.argument<String>("mimeType")))
            "reveal" -> result.success(showDownloads())
            "keepAwake" -> {
                keepAwake(call)
                result.success(null)
            }
            "excludeFromBackup" -> result.success(null)
            "storeSecret" -> background(result) { UFilesSecrets.store(context, call.argument<String>("alias")!!, call.argument<ByteArray>("secret")!!) }
            "loadSecret" -> loadSecret(call.argument<String>("alias")!!, result)
            "deleteSecret" -> background(result) { UFilesSecrets.delete(context, call.argument<String>("alias")!!) }
            "systemSupported" -> result.success(true)
            "systemEnqueue" -> background(result) { UFilesSystemDownloads.enqueue(context, call) }
            "systemCancel" -> background(result) { UFilesSystemDownloads.cancel(context, call.argument<String>("id")!!) }
            "systemQuery" -> background(result) { mapOf("items" to UFilesSystemDownloads.query(context)) }
            else -> result.notImplemented()
        }
    }

    private fun background(
        result: MethodChannel.Result,
        work: () -> Any?,
    ) {
        io.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("u_files", e.message ?: e.javaClass.simpleName, null) }
            }
        }
    }

    private fun freeSpace(path: String): Long {
        var file: File? = File(path)
        while (file != null && !file.exists()) file = file.parentFile
        return StatFs((file ?: context.filesDir).path).availableBytes
    }

    // -------------------------------------------------------------------------
    // Public Downloads
    // -------------------------------------------------------------------------

    private fun saveToDownloads(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val source = File(call.argument<String>("sourcePath")!!)
        val fileName = call.argument<String>("fileName")!!
        val mimeType = call.argument<String>("mimeType") ?: guessMime(fileName)
        val subfolder = call.argument<String>("subfolder")
        if (!source.isFile) {
            result.error("source_missing", "No local file at ${source.path}; download it first (UDownloadManager.download)", null)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            background(result) {
                val resolver = context.contentResolver
                val values =
                    ContentValues().apply {
                        put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                        put(MediaStore.Downloads.MIME_TYPE, mimeType)
                        put(
                            MediaStore.Downloads.RELATIVE_PATH,
                            Environment.DIRECTORY_DOWNLOADS + (subfolder?.let { "/$it" } ?: ""),
                        )
                        put(MediaStore.Downloads.IS_PENDING, 1)
                    }
                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values) ?: error("MediaStore insert failed")
                try {
                    resolver.openOutputStream(uri)!!.use { out -> FileInputStream(source).use { it.copyTo(out, 256 * 1024) } }
                    values.clear()
                    values.put(MediaStore.Downloads.IS_PENDING, 0)
                    resolver.update(uri, values, null, null)
                } catch (e: Exception) {
                    resolver.delete(uri, null, null)
                    throw e
                }
                uri.toString()
            }
            return
        }
        // API 24-28: the shared folder is a plain directory behind a runtime permission.
        withLegacyWritePermission(
            granted = {
                background(result) {
                    @Suppress("DEPRECATION")
                    val base = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                    val directory = if (subfolder == null) base else File(base, subfolder)
                    directory.mkdirs()
                    val target = uniqueFile(directory, fileName)
                    source.copyTo(target)
                    MediaScannerConnection.scanFile(context, arrayOf(target.path), arrayOf(mimeType), null)
                    target.path
                }
            },
            denied = { result.error("permission_denied", "Storage permission denied", null) },
        )
    }

    private fun withLegacyWritePermission(
        granted: () -> Unit,
        denied: () -> Unit,
    ) {
        val permission = Manifest.permission.WRITE_EXTERNAL_STORAGE
        if (ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED) {
            granted()
            return
        }
        val current = activity ?: return denied()
        pendingPermission = granted
        pendingPermissionDenied = denied
        current.requestPermissions(arrayOf(permission), PERMISSION_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST) return false
        val ok = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        (if (ok) pendingPermission else pendingPermissionDenied)?.invoke()
        pendingPermission = null
        pendingPermissionDenied = null
        return true
    }

    private fun uniqueFile(
        directory: File,
        name: String,
    ): File {
        var candidate = File(directory, name)
        if (!candidate.exists()) return candidate
        val dot = name.lastIndexOf('.')
        val stem = if (dot > 0) name.substring(0, dot) else name
        val extension = if (dot > 0) name.substring(dot) else ""
        var i = 1
        while (candidate.exists()) candidate = File(directory, "$stem (${i++})$extension")
        return candidate
    }

    // -------------------------------------------------------------------------
    // Save as (Storage Access Framework)
    // -------------------------------------------------------------------------

    private fun saveAs(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val current = activity ?: return result.error("no_activity", "Save as needs a foreground activity", null)
        val fileName = call.argument<String>("fileName")!!
        pendingSaveAs = call.argument<String>("sourcePath")!! to result
        val intent =
            Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = call.argument<String>("mimeType") ?: guessMime(fileName)
                putExtra(Intent.EXTRA_TITLE, fileName)
            }
        try {
            current.startActivityForResult(intent, SAVE_AS_REQUEST)
        } catch (e: ActivityNotFoundException) {
            pendingSaveAs = null
            result.error("unavailable", "No document provider", null)
        }
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ): Boolean {
        if (requestCode != SAVE_AS_REQUEST) return false
        val (source, result) = pendingSaveAs ?: return true
        pendingSaveAs = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return true
        }
        background(result) {
            context.contentResolver.openOutputStream(uri, "wt")!!.use { out -> FileInputStream(source).use { it.copyTo(out, 256 * 1024) } }
            uri.toString()
        }
        return true
    }

    // -------------------------------------------------------------------------
    // Open / reveal
    // -------------------------------------------------------------------------

    private fun open(
        path: String,
        mimeType: String?,
    ): Boolean {
        val uri =
            if (path.startsWith("content:")) {
                Uri.parse(path)
            } else {
                FileProvider.getUriForFile(context, "${context.packageName}.u.fileprovider", File(path))
            }
        val type = mimeType ?: context.contentResolver.getType(uri) ?: guessMime(path)
        val intent =
            Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, type)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        return try {
            (activity ?: context).startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    // Android has no "show in folder"; the system Downloads screen is the closest equivalent.
    private fun showDownloads(): Boolean =
        try {
            (activity ?: context).startActivity(Intent(DownloadManager.ACTION_VIEW_DOWNLOADS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (e: ActivityNotFoundException) {
            false
        }

    private fun guessMime(name: String): String {
        val extension = name.substringAfterLast('.', "").lowercase()
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension) ?: "application/octet-stream"
    }

    // -------------------------------------------------------------------------
    // Foreground service
    // -------------------------------------------------------------------------

    private fun keepAwake(call: MethodCall) {
        val intent =
            Intent(context, UDownloadService::class.java)
                .putExtra("title", call.argument<String>("title"))
                .putExtra("text", call.argument<String>("text"))
                .putExtra("progress", call.argument<Int>("progress") ?: -1)
        if (call.argument<Boolean>("enabled") != true) {
            context.stopService(intent)
            return
        }
        try {
            ContextCompat.startForegroundService(context, intent)
        } catch (e: Exception) {
            // Android 12+ refuses to start a foreground service from the background; the
            // download keeps running for as long as the process lives.
        }
    }

    private fun loadSecret(
        alias: String,
        result: MethodChannel.Result,
    ) {
        io.execute {
            try {
                val value = UFilesSecrets.load(context, alias)
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("keystore", e.message, null) }
            }
        }
    }

    companion object {
        private const val SAVE_AS_REQUEST = 0x5A1E
        private const val PERMISSION_REQUEST = 0x5A1F
    }
}

/** Keeps the process in the foreground while downloads run, with a live progress notification. */
class UDownloadService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int,
    ): Int {
        val notification = build(intent)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        if (wakeLock == null) {
            wakeLock =
                (getSystemService(POWER_SERVICE) as PowerManager)
                    .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "u:downloads")
                    .apply { acquire(6 * 60 * 60 * 1000L) }
            @Suppress("DEPRECATION")
            wifiLock =
                (applicationContext.getSystemService(WIFI_SERVICE) as WifiManager)
                    .createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "u:downloads")
                    .apply { acquire() }
        }
        return START_NOT_STICKY
    }

    private fun build(intent: Intent?): Notification {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && manager.getNotificationChannel(CHANNEL) == null) {
            manager.createNotificationChannel(NotificationChannel(CHANNEL, "Downloads", NotificationManager.IMPORTANCE_LOW))
        }
        val progress = intent?.getIntExtra("progress", -1) ?: -1
        val launch = packageManager.getLaunchIntentForPackage(packageName)
        val tap =
            launch?.let {
                android.app.PendingIntent.getActivity(this, 0, it, android.app.PendingIntent.FLAG_IMMUTABLE or android.app.PendingIntent.FLAG_UPDATE_CURRENT)
            }
        return NotificationCompat
            .Builder(this, CHANNEL)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle(intent?.getStringExtra("title") ?: "Downloading")
            .setContentText(intent?.getStringExtra("text"))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setContentIntent(tap)
            .setProgress(100, progress.coerceAtLeast(0), progress < 0)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    // Android 15 caps dataSync services at six hours a day.
    override fun onTimeout(
        startId: Int,
        fgsType: Int,
    ) {
        stopSelf()
    }

    override fun onDestroy() {
        wakeLock?.takeIf { it.isHeld }?.release()
        wifiLock?.takeIf { it.isHeld }?.release()
        wakeLock = null
        wifiLock = null
        super.onDestroy()
    }

    companion object {
        private const val CHANNEL = "u_downloads"
        private const val NOTIFICATION_ID = 0x0D0A
    }
}

/** Secrets sealed with a non-exportable AES-GCM key in the Android Keystore. */
internal object UFilesSecrets {
    private const val KEY_ALIAS = "u_files_kek"
    private const val PREFS = "u_secure_store"

    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec
                .Builder(KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    fun store(
        context: Context,
        alias: String,
        secret: ByteArray,
    ): Boolean {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding").apply { init(Cipher.ENCRYPT_MODE, key()) }
        val sealed = cipher.iv + cipher.doFinal(secret)
        return context
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(alias, Base64.encodeToString(sealed, Base64.NO_WRAP))
            .commit()
    }

    /** Null means "not stored" — or stored under a key that no longer exists (e.g. restored backup). */
    fun load(
        context: Context,
        alias: String,
    ): ByteArray? {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val encoded = prefs.getString(alias, null) ?: return null
        val sealed = Base64.decode(encoded, Base64.NO_WRAP)
        return try {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, sealed, 0, 12))
            cipher.doFinal(sealed, 12, sealed.size - 12)
        } catch (e: KeyPermanentlyInvalidatedException) {
            prefs.edit().remove(alias).commit()
            null
        } catch (e: AEADBadTagException) {
            prefs.edit().remove(alias).commit()
            null
        }
    }

    fun delete(
        context: Context,
        alias: String,
    ): Boolean =
        context
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .remove(alias)
            .commit()
}

/** Downloads owned by the system DownloadManager, keyed by the Dart task id. */
internal object UFilesSystemDownloads {
    private const val PREFS = "u_system_downloads"

    private fun manager(context: Context) = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager

    fun enqueue(
        context: Context,
        call: MethodCall,
    ): Boolean {
        val id = call.argument<String>("id")!!
        val fileName = call.argument<String>("fileName")!!
        val request =
            DownloadManager.Request(Uri.parse(call.argument<String>("url")!!)).apply {
                call.argument<Map<String, String>>("headers")?.forEach { (name, value) -> addRequestHeader(name, value) }
                setTitle(call.argument<String>("title") ?: fileName)
                call.argument<String>("mimeType")?.let { setMimeType(it) }
                val wifiOnly = call.argument<Boolean>("wifiOnly") == true
                setAllowedNetworkTypes(
                    if (wifiOnly) DownloadManager.Request.NETWORK_WIFI else DownloadManager.Request.NETWORK_WIFI or DownloadManager.Request.NETWORK_MOBILE,
                )
                setAllowedOverMetered(!wifiOnly)
                setNotificationVisibility(
                    if (call.argument<Boolean>("showNotification") != false) {
                        DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED
                    } else {
                        DownloadManager.Request.VISIBILITY_VISIBLE
                    },
                )
                if (call.argument<Boolean>("publicDownloads") == true) {
                    setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
                } else {
                    // DownloadManager can only write to external storage; the Dart side moves the
                    // finished file from here into private storage.
                    val directory = File(context.getExternalFilesDir(null), "u_system_downloads").apply { mkdirs() }
                    setDestinationUri(Uri.fromFile(File(directory, "$id.part")))
                }
            }
        val downloadId = manager(context).enqueue(request)
        context
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putLong(id, downloadId)
            .commit()
        return true
    }

    fun cancel(
        context: Context,
        id: String,
    ): Boolean {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val downloadId = prefs.getLong(id, -1)
        if (downloadId >= 0) manager(context).remove(downloadId)
        prefs.edit().remove(id).commit()
        return true
    }

    fun query(context: Context): List<Map<String, Any?>> {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val ids = prefs.all.mapNotNull { (key, value) -> (value as? Long)?.let { key to it } }.toMap()
        if (ids.isEmpty()) return emptyList()
        val byDownloadId = ids.entries.associate { (task, download) -> download to task }
        val items = mutableListOf<Map<String, Any?>>()
        manager(context).query(DownloadManager.Query().setFilterById(*ids.values.toLongArray())).use { cursor ->
            while (cursor.moveToNext()) {
                val downloadId = cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_ID))
                val status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
                val local = cursor.getString(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_LOCAL_URI))
                val reason = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON))
                val path = local?.let { if (it.startsWith("file:")) Uri.parse(it).path else it }
                items +=
                    mapOf(
                        "id" to byDownloadId[downloadId],
                        "state" to
                            when (status) {
                                DownloadManager.STATUS_PENDING -> "queued"
                                DownloadManager.STATUS_RUNNING -> "running"
                                DownloadManager.STATUS_PAUSED -> "paused"
                                DownloadManager.STATUS_SUCCESSFUL -> "completed"
                                else -> "failed"
                            },
                        "received" to cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)),
                        "total" to cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)),
                        "path" to path,
                        "error" to if (status == DownloadManager.STATUS_FAILED) "DownloadManager reason $reason" else null,
                    )
            }
        }
        return items
    }
}
