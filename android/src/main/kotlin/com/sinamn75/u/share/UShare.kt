package com.sinamn75.u.share

import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ClipData
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import com.sinamn75.u.UContent
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors

/**
 * Native side of UShare ("u/share" + "u/share/received"): the chooser with the picked app
 * reported back, direct shares to one package, and shares other apps send to this one.
 */
class UShareHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    PluginRegistry.NewIntentListener,
    PluginRegistry.ActivityResultListener {
    private val channel = MethodChannel(messenger, "u/share")
    private val events = EventChannel(messenger, "u/share/received")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null
    private var binding: ActivityPluginBinding? = null
    private var pendingResult: MethodChannel.Result? = null
    private var chosen: String? = null
    private var initial: Map<String, Any?>? = null
    private var initialRead = false
    private val queued = mutableListOf<Map<String, Any?>>()

    // The chooser reports the picked component through this broadcast (Android 5.1+).
    private val chosenReceiver =
        object : BroadcastReceiver() {
            override fun onReceive(
                c: Context?,
                intent: Intent?,
            ) {
                val component =
                    if (Build.VERSION.SDK_INT >= 33) {
                        intent?.getParcelableExtra(Intent.EXTRA_CHOSEN_COMPONENT, ComponentName::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent?.getParcelableExtra(Intent.EXTRA_CHOSEN_COMPONENT)
                    }
                chosen = component?.packageName
            }
        }

    init {
        channel.setMethodCallHandler(this)
        events.setStreamHandler(this)
        val filter = IntentFilter(ACTION_CHOSEN)
        if (Build.VERSION.SDK_INT >= 33) {
            context.registerReceiver(chosenReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            context.registerReceiver(chosenReceiver, filter)
        }
    }

    private val activity: Activity? get() = binding?.activity

    fun attach(binding: ActivityPluginBinding) {
        detach()
        this.binding = binding
        binding.addOnNewIntentListener(this)
        binding.addActivityResultListener(this)
        if (!initialRead) {
            initialRead = true
            readShare(binding.activity.intent) { initial = it }
        }
    }

    fun detach() {
        binding?.removeOnNewIntentListener(this)
        binding?.removeActivityResultListener(this)
        binding = null
    }

    fun dispose() {
        detach()
        channel.setMethodCallHandler(null)
        events.setStreamHandler(null)
        try {
            context.unregisterReceiver(chosenReceiver)
        } catch (_: Exception) {
        }
        io.shutdown()
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            when (call.method) {
                "share" -> share(call, result)
                "shareTo" -> result.success(shareTo(call))
                "canShareTo" -> result.success(canShareTo(call.argument<String>("target") ?: ""))
                "initialShare" -> result.success(initial)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("u_share", e.message ?: e.javaClass.simpleName, null)
        }
    }

    // -------------------------------------------------------------------------
    // Sharing out
    // -------------------------------------------------------------------------

    private fun sendIntent(call: MethodCall): Intent? {
        val text = listOfNotNull(call.argument<String>("text"), call.argument<String>("url")).filter { it.isNotEmpty() }.joinToString("\n")
        val files = call.argument<List<Map<String, Any?>>>("files") ?: emptyList()
        val uris = files.mapNotNull { f -> (f["path"] as? String)?.let { UContent.uriFor(context, it) } }
        if (text.isEmpty() && uris.isEmpty()) return null
        return Intent(if (uris.size > 1) Intent.ACTION_SEND_MULTIPLE else Intent.ACTION_SEND).apply {
            type = mimeFor(files, uris.isEmpty())
            if (text.isNotEmpty()) putExtra(Intent.EXTRA_TEXT, text)
            call.argument<String>("subject")?.let { putExtra(Intent.EXTRA_SUBJECT, it) }
            call.argument<String>("title")?.let { putExtra(Intent.EXTRA_TITLE, it) }
            when (uris.size) {
                0 -> {}
                1 -> putExtra(Intent.EXTRA_STREAM, uris[0])
                else -> putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(uris))
            }
            if (uris.isNotEmpty()) {
                // ClipData carries the read grant through the chooser to the target app.
                clipData = ClipData.newRawUri(null, uris[0]).apply { uris.drop(1).forEach { addItem(ClipData.Item(it)) } }
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
        }
    }

    // One concrete type when all files agree, "type/*" when only the family agrees, else */*.
    private fun mimeFor(
        files: List<Map<String, Any?>>,
        textOnly: Boolean,
    ): String {
        if (textOnly) return "text/plain"
        val types = files.map { (it["mimeType"] as? String) ?: UContent.mimeOf((it["name"] as? String) ?: (it["path"] as? String) ?: "") }.distinct()
        if (types.size == 1) return types[0]
        val families = types.map { it.substringBefore('/') }.distinct()
        return if (families.size == 1) "${families[0]}/*" else "*/*"
    }

    private fun share(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val intent = sendIntent(call) ?: return result.success(mapOf("status" to "unavailable"))
        val callback =
            PendingIntent.getBroadcast(
                context,
                0,
                Intent(ACTION_CHOSEN).setPackage(context.packageName),
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0),
            )
        val chooser = Intent.createChooser(intent, call.argument<String>("title"), callback.intentSender)
        val current = activity
        if (current == null) {
            context.startActivity(chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            return result.success(mapOf("status" to "shown"))
        }
        pendingResult?.success(mapOf("status" to "dismissed"))
        pendingResult = result
        chosen = null
        current.startActivityForResult(chooser, REQUEST_SHARE)
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ): Boolean {
        if (requestCode != REQUEST_SHARE) return false
        val result = pendingResult ?: return true
        pendingResult = null
        // The chosen-component broadcast is delivered before we come back to the foreground.
        main.post {
            val pkg = chosen
            result.success(if (pkg != null) mapOf("status" to "success", "target" to pkg) else mapOf("status" to "dismissed"))
        }
        return true
    }

    private fun shareTo(call: MethodCall): Map<String, Any?> {
        val target = call.argument<String>("target") ?: ""
        val intent = sendIntent(call) ?: return mapOf("status" to "unavailable")
        val direct =
            when (target) {
                "email" -> Intent(intent).apply { selector = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:")) }
                "sms" ->
                    if (intent.hasExtra(Intent.EXTRA_STREAM)) {
                        intent
                    } else {
                        Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:")).putExtra("sms_body", intent.getStringExtra(Intent.EXTRA_TEXT))
                    }
                else -> {
                    val pkg = packageFor(target)?.firstOrNull { installed(listOf(it)) } ?: return mapOf("status" to "unavailable")
                    Intent(intent).setPackage(pkg)
                }
            }
        return try {
            val current = activity
            if (current != null) current.startActivity(direct) else context.startActivity(direct.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            mapOf("status" to "success", "target" to (direct.`package` ?: target))
        } catch (_: Exception) {
            mapOf("status" to "unavailable")
        }
    }

    private fun canShareTo(target: String): Boolean =
        when (target) {
            "email", "sms" -> true
            else -> packageFor(target)?.let { installed(it) } ?: false
        }

    private fun packageFor(target: String): List<String>? =
        when (target) {
            "whatsapp" -> listOf("com.whatsapp", "com.whatsapp.w4b")
            "telegram" -> listOf("org.telegram.messenger", "org.thunderdog.challegram")
            "eitaa" -> listOf("ir.eitaa.messenger")
            "rubika" -> listOf("ir.resaneh1.iptv")
            "bale" -> listOf("ir.nasim")
            "soroush" -> listOf("mobi.mmdt.ottplus")
            "instagram" -> listOf("com.instagram.android")
            "x" -> listOf("com.twitter.android")
            else -> null
        }

    private fun installed(packages: List<String>): Boolean =
        packages.any {
            try {
                if (Build.VERSION.SDK_INT >= 33) {
                    context.packageManager.getPackageInfo(it, PackageManager.PackageInfoFlags.of(0))
                } else {
                    @Suppress("DEPRECATION")
                    context.packageManager.getPackageInfo(it, 0)
                }
                true
            } catch (_: PackageManager.NameNotFoundException) {
                false
            }
        }

    // -------------------------------------------------------------------------
    // Receiving
    // -------------------------------------------------------------------------

    override fun onNewIntent(intent: Intent): Boolean {
        readShare(intent) { share -> emit(share) }
        return false
    }

    // ACTION_SEND / SEND_MULTIPLE, and VIEW of a content:// or file:// document ("Open with").
    private fun readShare(
        intent: Intent?,
        deliver: (Map<String, Any?>) -> Unit,
    ) {
        if (intent == null || intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return
        val action = intent.action ?: return
        val uris = mutableListOf<Uri>()
        when (action) {
            Intent.ACTION_SEND -> streamOf(intent)?.let { uris += it }
            Intent.ACTION_SEND_MULTIPLE -> uris += streamsOf(intent)
            Intent.ACTION_VIEW -> intent.data?.takeIf { it.scheme == "content" || it.scheme == "file" }?.let { uris += it } ?: return
            else -> return
        }
        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
        val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
        if (text == null && uris.isEmpty()) return
        // The sender's read grant ends with the activity: copy files now, off the main thread.
        io.execute {
            val files = uris.mapNotNull { copyIn(it) }
            main.post { deliver(mapOf("text" to text, "subject" to subject, "files" to files)) }
        }
    }

    private fun streamOf(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    private fun streamsOf(intent: Intent): List<Uri> =
        if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java) ?: emptyList()
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM) ?: emptyList()
        }

    private fun copyIn(uri: Uri): Map<String, Any?>? =
        try {
            val resolver = context.contentResolver
            val name =
                resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                    if (c.moveToFirst()) c.getString(0) else null
                } ?: uri.lastPathSegment ?: "file"
            val safe = name.replace(Regex("[/\\\\:*?\"<>|]"), "_")
            val target = File(File(context.cacheDir, "u_received/${UUID.randomUUID()}").apply { mkdirs() }, safe)
            resolver.openInputStream(uri)?.use { input -> target.outputStream().use { input.copyTo(it) } } ?: return null
            mapOf("path" to target.absolutePath, "name" to safe, "mimeType" to (resolver.getType(uri) ?: UContent.mimeOf(safe)))
        } catch (_: Exception) {
            null
        }

    private fun emit(share: Map<String, Any?>) {
        val current = sink
        if (current == null) queued += share else current.success(share)
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?,
    ) {
        sink = events
        queued.forEach { events?.success(it) }
        queued.clear()
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    private companion object {
        const val REQUEST_SHARE = 0x5548
        const val ACTION_CHOSEN = "com.sinamn75.u.SHARE_CHOSEN"
    }
}
