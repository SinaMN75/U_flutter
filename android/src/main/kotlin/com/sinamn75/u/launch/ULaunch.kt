package com.sinamn75.u.launch

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Browser
import android.provider.Settings
import android.text.Html
import com.sinamn75.u.UContent
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Native side of ULaunch ("u/launch" + "u/launch/events"): intents, Custom Tabs without the
 * androidx.browser library, settings panels, compose screens, store pages and deep links.
 */
class ULaunchHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    PluginRegistry.NewIntentListener,
    PluginRegistry.ActivityResultListener {
    private val channel = MethodChannel(messenger, "u/launch")
    private val events = EventChannel(messenger, "u/launch/events")
    private var sink: EventChannel.EventSink? = null
    private var binding: ActivityPluginBinding? = null
    private var initialLink: String? = null
    private var initialRead = false
    private val pending = mutableListOf<Map<String, Any?>>()

    init {
        channel.setMethodCallHandler(this)
        events.setStreamHandler(this)
    }

    private val activity: Activity? get() = binding?.activity

    fun attach(binding: ActivityPluginBinding) {
        detach()
        this.binding = binding
        binding.addOnNewIntentListener(this)
        binding.addActivityResultListener(this)
        if (!initialRead) {
            initialRead = true
            initialLink = linkFrom(binding.activity.intent)
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
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            when (call.method) {
                "open" -> result.success(open(call))
                "canOpen" -> result.success(canOpen(call.argument<String>("url") ?: ""))
                "isInstalled" -> result.success(isInstalled(call.argument<String>("id") ?: ""))
                "openApp" -> result.success(openApp(call.argument<String>("id") ?: ""))
                "openSettings" -> result.success(openSettings(call.argument<String>("page") ?: "app", call.argument<String>("channelId")))
                "closeInApp" -> result.success(closeInApp())
                "email" -> result.success(email(call))
                "sms" -> result.success(sms(call))
                "openStore" -> result.success(openStore(call.argument<String>("store") ?: "auto", call.argument<String>("appId"), call.argument<Boolean>("review") == true))
                "requestReview" -> result.success(false)
                "initialLink" -> result.success(initialLink)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("u_launch", e.message ?: e.javaClass.simpleName, null)
        }
    }

    // -------------------------------------------------------------------------
    // Opening
    // -------------------------------------------------------------------------

    private fun open(call: MethodCall): Boolean {
        val url = call.argument<String>("url") ?: return false
        val mode = call.argument<String>("mode") ?: "platformDefault"
        val headers = call.argument<Map<String, String>>("headers") ?: emptyMap()
        val pkg = call.argument<String>("package")
        if (url.startsWith("intent:")) return openIntentUri(url)
        val uri = Uri.parse(url)
        val web = uri.scheme == "http" || uri.scheme == "https"
        return when {
            mode == "inApp" && web -> openCustomTab(uri, headers, call.argument<Number>("toolbarColor")?.toInt(), call.argument<Boolean>("showTitle") != false)
            mode == "nonBrowser" -> openNonBrowser(uri)
            else -> start(viewIntent(uri, headers).apply { if (pkg != null) setPackage(pkg) }, fallbackWithoutPackage = pkg != null)
        }
    }

    private fun viewIntent(
        uri: Uri,
        headers: Map<String, String>,
    ) = Intent(Intent.ACTION_VIEW, uri).apply {
        addCategory(Intent.CATEGORY_BROWSABLE)
        if (headers.isNotEmpty()) putExtra(Browser.EXTRA_HEADERS, Bundle().apply { headers.forEach { (k, v) -> putString(k, v) } })
    }

    // "intent://…#Intent;…;end" links from web pages, with their browser_fallback_url.
    private fun openIntentUri(url: String): Boolean {
        val intent =
            try {
                Intent.parseUri(url, Intent.URI_INTENT_SCHEME).apply {
                    addCategory(Intent.CATEGORY_BROWSABLE)
                    component = null
                    selector = null
                }
            } catch (_: Exception) {
                return false
            }
        if (start(intent)) return true
        val fallback = intent.getStringExtra("browser_fallback_url") ?: return false
        return start(Intent(Intent.ACTION_VIEW, Uri.parse(fallback)))
    }

    // Custom Tabs spoken directly as an intent protocol, so no androidx.browser dependency.
    private fun openCustomTab(
        uri: Uri,
        headers: Map<String, String>,
        toolbarColor: Int?,
        showTitle: Boolean,
    ): Boolean {
        val intent =
            viewIntent(uri, headers).apply {
                putExtras(Bundle().apply { putBinder(EXTRA_SESSION, null) })
                putExtra(EXTRA_TITLE_VISIBILITY, if (showTitle) 1 else 0)
                putExtra(EXTRA_URLBAR_HIDING, true)
                if (toolbarColor != null) putExtra(EXTRA_TOOLBAR_COLOR, toolbarColor)
                customTabsPackage()?.let { setPackage(it) }
            }
        val current = activity ?: return start(intent)
        return try {
            // The result arrives when the user leaves the tab: that is the "closed" event.
            current.startActivityForResult(intent, REQUEST_CUSTOM_TAB)
            true
        } catch (_: ActivityNotFoundException) {
            start(viewIntent(uri, headers))
        }
    }

    // The default browser when it supports Custom Tabs, else any browser that does.
    private fun customTabsPackage(): String? {
        val services = queryServices(Intent(ACTION_CUSTOM_TABS_CONNECTION)).map { it.serviceInfo.packageName }.toSet()
        if (services.isEmpty()) return null
        val default = resolveActivity(Intent(Intent.ACTION_VIEW, Uri.parse("http://")))?.activityInfo?.packageName
        return if (default != null && default in services) default else services.first()
    }

    private fun openNonBrowser(uri: Uri): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            return start(Intent(Intent.ACTION_VIEW, uri).addCategory(Intent.CATEGORY_BROWSABLE).addFlags(Intent.FLAG_ACTIVITY_REQUIRE_NON_BROWSER))
        }
        val browsers = queryActivities(Intent(Intent.ACTION_VIEW, Uri.parse("http://example.com"))).map { it.activityInfo.packageName }.toSet()
        val app = queryActivities(Intent(Intent.ACTION_VIEW, uri)).map { it.activityInfo.packageName }.firstOrNull { it !in browsers } ?: return false
        return start(Intent(Intent.ACTION_VIEW, uri).setPackage(app))
    }

    private fun start(
        intent: Intent,
        fallbackWithoutPackage: Boolean = false,
    ): Boolean {
        return try {
            val current = activity
            if (current != null) current.startActivity(intent) else context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (_: ActivityNotFoundException) {
            if (fallbackWithoutPackage) start(Intent(intent).setPackage(null)) else false
        } catch (_: SecurityException) {
            false
        }
    }

    private fun canOpen(url: String): Boolean {
        if (url.startsWith("intent:")) return true
        return resolveActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) != null
    }

    private fun isInstalled(id: String): Boolean =
        try {
            if (Build.VERSION.SDK_INT >= 33) {
                context.packageManager.getPackageInfo(id, PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(id, 0)
            }
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }

    private fun openApp(id: String): Boolean {
        val intent = context.packageManager.getLaunchIntentForPackage(id) ?: return false
        return start(intent)
    }

    private fun closeInApp(): Boolean {
        val current = activity ?: return false
        // Bringing our own activity back to the top finishes the Custom Tab stacked above it.
        current.startActivity(Intent(current, current.javaClass).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP))
        return true
    }

    // -------------------------------------------------------------------------
    // Settings
    // -------------------------------------------------------------------------

    private fun openSettings(
        page: String,
        channelId: String?,
    ): Boolean {
        val pkg = context.packageName
        val packageUri = Uri.fromParts("package", pkg, null)
        val sdk = Build.VERSION.SDK_INT
        val intent: Intent? =
            when (page) {
                "notifications" -> if (sdk >= 26) Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, pkg) else null
                "notificationChannel" ->
                    if (sdk >= 26 && channelId != null) {
                        Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, pkg).putExtra(Settings.EXTRA_CHANNEL_ID, channelId)
                    } else {
                        null
                    }
                "location" -> Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
                "wifi" -> Intent(if (sdk >= 29) Settings.Panel.ACTION_WIFI else Settings.ACTION_WIFI_SETTINGS)
                "bluetooth" -> Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                "battery" -> Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                "display" -> Intent(Settings.ACTION_DISPLAY_SETTINGS)
                "sound" -> Intent(if (sdk >= 29) Settings.Panel.ACTION_VOLUME else Settings.ACTION_SOUND_SETTINGS)
                "dateTime" -> Intent(Settings.ACTION_DATE_SETTINGS)
                "language" -> if (sdk >= 33) Intent(Settings.ACTION_APP_LOCALE_SETTINGS, packageUri) else Intent(Settings.ACTION_LOCALE_SETTINGS)
                "security" -> Intent(Settings.ACTION_SECURITY_SETTINGS)
                "nfc" -> Intent(if (sdk >= 29) Settings.Panel.ACTION_NFC else Settings.ACTION_NFC_SETTINGS)
                "dataUsage" -> Intent(if (sdk >= 29) Settings.Panel.ACTION_INTERNET_CONNECTIVITY else Settings.ACTION_DATA_USAGE_SETTINGS)
                "accessibility" -> Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                "developer" -> Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
                "storage" -> Intent(Settings.ACTION_INTERNAL_STORAGE_SETTINGS)
                "vpn" -> Intent(Settings.ACTION_VPN_SETTINGS)
                "airplaneMode" -> Intent(Settings.ACTION_AIRPLANE_MODE_SETTINGS)
                "apps" -> Intent(Settings.ACTION_MANAGE_APPLICATIONS_SETTINGS)
                "exactAlarms" -> if (sdk >= 31) Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, packageUri) else null
                "overlay" -> Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, packageUri)
                "allFilesAccess" -> if (sdk >= 30) Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, packageUri) else null
                "installUnknownApps" -> if (sdk >= 26) Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, packageUri) else null
                "usageAccess" -> Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                "defaultApps" -> Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
                "fullScreenIntents" -> if (sdk >= 34) Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, packageUri) else null
                else -> null
            }
        if (intent != null && start(intent)) return true
        return start(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri))
    }

    // -------------------------------------------------------------------------
    // Compose
    // -------------------------------------------------------------------------

    private fun email(call: MethodCall): String {
        val to = call.argument<List<String>>("to") ?: emptyList()
        val cc = call.argument<List<String>>("cc") ?: emptyList()
        val bcc = call.argument<List<String>>("bcc") ?: emptyList()
        val subject = call.argument<String>("subject")
        val body = call.argument<String>("body")
        val html = call.argument<Boolean>("html") == true
        val files = (call.argument<List<String>>("attachments") ?: emptyList()).mapNotNull { UContent.uriFor(context, it) }
        val mailto = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:"))
        val intent =
            if (files.isEmpty()) {
                mailto
            } else {
                Intent(if (files.size == 1) Intent.ACTION_SEND else Intent.ACTION_SEND_MULTIPLE).apply {
                    type = "message/rfc822"
                    // Only email apps: the selector restricts the chooser to mailto handlers.
                    selector = mailto
                    if (files.size == 1) putExtra(Intent.EXTRA_STREAM, files[0]) else putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(files))
                    clipData = ClipData.newRawUri(null, files[0]).apply { files.drop(1).forEach { addItem(ClipData.Item(it)) } }
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
            }
        intent.putExtra(Intent.EXTRA_EMAIL, to.toTypedArray())
        if (cc.isNotEmpty()) intent.putExtra(Intent.EXTRA_CC, cc.toTypedArray())
        if (bcc.isNotEmpty()) intent.putExtra(Intent.EXTRA_BCC, bcc.toTypedArray())
        if (subject != null) intent.putExtra(Intent.EXTRA_SUBJECT, subject)
        if (body != null) {
            if (html) {
                intent.putExtra(Intent.EXTRA_HTML_TEXT, body)
                intent.putExtra(Intent.EXTRA_TEXT, Html.fromHtml(body, Html.FROM_HTML_MODE_LEGACY))
            } else {
                intent.putExtra(Intent.EXTRA_TEXT, body)
            }
        }
        if (start(intent)) return "opened"
        val url = call.argument<String>("mailto") ?: return "unavailable"
        return if (start(Intent(Intent.ACTION_VIEW, Uri.parse(url)))) "opened" else "unavailable"
    }

    private fun sms(call: MethodCall): String {
        val to = call.argument<List<String>>("to") ?: emptyList()
        val body = call.argument<String>("body")
        val files = (call.argument<List<String>>("attachments") ?: emptyList()).mapNotNull { UContent.uriFor(context, it) }
        val intent =
            if (files.isEmpty()) {
                Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:${to.joinToString(";")}"))
            } else {
                Intent(Intent.ACTION_SEND).apply {
                    type = context.contentResolver.getType(files[0]) ?: "image/*"
                    putExtra(Intent.EXTRA_STREAM, files[0])
                    putExtra("address", to.joinToString(";"))
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
            }
        if (body != null) intent.putExtra("sms_body", body)
        return if (start(intent)) "opened" else "unavailable"
    }

    // -------------------------------------------------------------------------
    // Stores
    // -------------------------------------------------------------------------

    private fun openStore(
        store: String,
        appId: String?,
        review: Boolean,
    ): Boolean {
        val pkg = appId ?: context.packageName
        val chosen =
            if (store != "auto") {
                store
            } else {
                when (installer()) {
                    "com.farsitel.bazaar" -> "bazaar"
                    "ir.mservices.market" -> "myket"
                    "com.sec.android.app.samsungapps" -> "galaxy"
                    "com.huawei.appmarket" -> "huawei"
                    else -> "googlePlay"
                }
            }
        return when (chosen) {
            "bazaar" ->
                start(Intent(if (review) Intent.ACTION_EDIT else Intent.ACTION_VIEW, Uri.parse("bazaar://details?id=$pkg")).setPackage("com.farsitel.bazaar")) ||
                    start(Intent(Intent.ACTION_VIEW, Uri.parse("https://cafebazaar.ir/app/$pkg")))
            "myket" ->
                start(Intent(Intent.ACTION_VIEW, Uri.parse(if (review) "myket://comment?id=$pkg" else "myket://details?id=$pkg")).setPackage("ir.mservices.market")) ||
                    start(Intent(Intent.ACTION_VIEW, Uri.parse("https://myket.ir/app/$pkg")))
            "galaxy" -> start(Intent(Intent.ACTION_VIEW, Uri.parse("samsungapps://ProductDetail/$pkg")))
            "huawei" -> start(Intent(Intent.ACTION_VIEW, Uri.parse("appmarket://details?id=$pkg")).setPackage("com.huawei.appmarket"))
            "googlePlay" ->
                start(Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$pkg")).setPackage("com.android.vending")) ||
                    start(Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=$pkg")))
            else -> false
        }
    }

    @Suppress("DEPRECATION")
    private fun installer(): String? =
        try {
            if (Build.VERSION.SDK_INT >= 30) context.packageManager.getInstallSourceInfo(context.packageName).installingPackageName else context.packageManager.getInstallerPackageName(context.packageName)
        } catch (_: Exception) {
            null
        }

    // -------------------------------------------------------------------------
    // Deep links
    // -------------------------------------------------------------------------

    // VIEW intents with a data URI that is not a file handed over for sharing and not a notification tap.
    private fun linkFrom(intent: Intent?): String? {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return null
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return null
        if (intent.hasExtra("u_notification")) return null
        val data = intent.data ?: return null
        if (data.scheme == "content" || data.scheme == "file") return null
        return data.toString()
    }

    override fun onNewIntent(intent: Intent): Boolean {
        val link = linkFrom(intent) ?: return false
        emit(mapOf("type" to "link", "url" to link))
        return false
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ): Boolean {
        if (requestCode != REQUEST_CUSTOM_TAB) return false
        emit(mapOf("type" to "closed"))
        return true
    }

    private fun emit(event: Map<String, Any?>) {
        val current = sink
        if (current == null) pending += event else current.success(event)
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?,
    ) {
        sink = events
        pending.forEach { events?.success(it) }
        pending.clear()
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    // -------------------------------------------------------------------------

    private fun resolveActivity(intent: Intent) =
        if (Build.VERSION.SDK_INT >= 33) {
            context.packageManager.resolveActivity(intent, PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_DEFAULT_ONLY.toLong()))
        } else {
            @Suppress("DEPRECATION")
            context.packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
        }

    private fun queryActivities(intent: Intent) =
        if (Build.VERSION.SDK_INT >= 33) {
            context.packageManager.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_DEFAULT_ONLY.toLong()))
        } else {
            @Suppress("DEPRECATION")
            context.packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
        }

    private fun queryServices(intent: Intent) =
        if (Build.VERSION.SDK_INT >= 33) {
            context.packageManager.queryIntentServices(intent, PackageManager.ResolveInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            context.packageManager.queryIntentServices(intent, 0)
        }

    private companion object {
        const val REQUEST_CUSTOM_TAB = 0x5547
        const val EXTRA_SESSION = "android.support.customtabs.extra.SESSION"
        const val EXTRA_TOOLBAR_COLOR = "android.support.customtabs.extra.TOOLBAR_COLOR"
        const val EXTRA_TITLE_VISIBILITY = "android.support.customtabs.extra.TITLE_VISIBILITY"
        const val EXTRA_URLBAR_HIDING = "android.support.customtabs.extra.ENABLE_URLBAR_HIDING"
        const val ACTION_CUSTOM_TABS_CONNECTION = "android.support.customtabs.action.CustomTabsService"
    }
}
