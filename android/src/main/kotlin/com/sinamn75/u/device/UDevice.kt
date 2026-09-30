package com.sinamn75.u.device

import android.Manifest
import android.annotation.SuppressLint
import android.app.ActivityManager
import android.app.UiModeManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.os.Debug
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.StatFs
import android.os.SystemClock
import android.provider.Settings
import android.telephony.TelephonyManager
import android.text.format.DateFormat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.InetSocketAddress
import java.net.Socket
import java.security.MessageDigest
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.Executors

/**
 * Native side of UDevice, UPackage and UConnectivity ("u/device").
 *
 * Everything that touches the disk or PackageManager runs on one background thread and replies
 * on the main thread. Network changes come from a default-network callback, so the Dart side
 * always holds the state of the network the app's traffic actually uses.
 */
class UDeviceHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {
    private val channel = MethodChannel(messenger, "u/device")
    private val events = EventChannel(messenger, "u/device/network")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val connectivity = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    private var sink: EventChannel.EventSink? = null
    private var callback: ConnectivityManager.NetworkCallback? = null
    private var dataSaverReceiver: BroadcastReceiver? = null

    init {
        channel.setMethodCallHandler(this)
        events.setStreamHandler(this)
    }

    fun dispose() {
        onCancel(null)
        channel.setMethodCallHandler(null)
        events.setStreamHandler(null)
        io.shutdown()
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            "bootstrap" -> background(result) { mapOf("device" to device(), "package" to packageInfo(), "network" to network()) }
            "network" -> result.success(network())
            "status" -> background(result) { status() }
            "integrity" -> background(result) { integrity() }
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
                main.post { result.error("u_device", e.message ?: e.javaClass.simpleName, null) }
            }
        }
    }

    // -------------------------------------------------------------------------
    // Device
    // -------------------------------------------------------------------------

    @SuppressLint("HardwareIds")
    private fun device(): Map<String, Any?> {
        val config = context.resources.configuration
        val activity = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memory = ActivityManager.MemoryInfo().also { activity.getMemoryInfo(it) }
        val locales = config.locales.let { list -> (0 until list.size()).map { list[it].toLanguageTag() } }
        val extra =
            mutableMapOf<String, Any?>(
                "board" to Build.BOARD,
                "bootloader" to Build.BOOTLOADER,
                "hardware" to Build.HARDWARE,
                "product" to Build.PRODUCT,
                "device" to Build.DEVICE,
                "display" to Build.DISPLAY,
                "fingerprint" to Build.FINGERPRINT,
                "host" to Build.HOST,
                "tags" to Build.TAGS,
                "buildType" to Build.TYPE,
                "supportedAbis" to Build.SUPPORTED_ABIS.toList(),
                "securityPatch" to Build.VERSION.SECURITY_PATCH,
                "codename" to Build.VERSION.CODENAME,
                "incremental" to Build.VERSION.INCREMENTAL,
                "isLowRamDevice" to activity.isLowRamDevice,
                "screenWidthDp" to config.screenWidthDp,
                "screenHeightDp" to config.screenHeightDp,
                "densityDpi" to config.densityDpi,
            )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) extra["baseOs"] = Build.VERSION.BASE_OS
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            extra["socManufacturer"] = Build.SOC_MANUFACTURER
            extra["socModel"] = Build.SOC_MODEL
        }
        return mapOf(
            "platform" to "android",
            "os" to "Android",
            "osVersion" to Build.VERSION.RELEASE,
            "osBuild" to Build.ID,
            "sdkInt" to Build.VERSION.SDK_INT,
            "model" to Build.MODEL,
            "manufacturer" to Build.MANUFACTURER.replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.ROOT) else it.toString() },
            "brand" to Build.BRAND,
            "name" to deviceName(),
            "type" to deviceType(config),
            "physical" to emulatorReasons().isEmpty(),
            "id" to Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID),
            "arch" to Build.SUPPORTED_ABIS.firstOrNull(),
            "cores" to Runtime.getRuntime().availableProcessors(),
            "memory" to memory.totalMem,
            "locales" to locales,
            "timeZone" to TimeZone.getDefault().id,
            "is24h" to DateFormat.is24HourFormat(context),
            "extra" to extra,
        )
    }

    private fun deviceName(): String {
        val global = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) Settings.Global.getString(context.contentResolver, Settings.Global.DEVICE_NAME) else null
        return global ?: Settings.Secure.getString(context.contentResolver, "bluetooth_name") ?: Build.MODEL
    }

    private fun deviceType(config: Configuration): String {
        val uiMode = (context.getSystemService(Context.UI_MODE_SERVICE) as UiModeManager).currentModeType
        return when {
            uiMode == Configuration.UI_MODE_TYPE_TELEVISION -> "tv"
            uiMode == Configuration.UI_MODE_TYPE_WATCH -> "watch"
            uiMode == Configuration.UI_MODE_TYPE_CAR -> "car"
            config.smallestScreenWidthDp >= 600 -> "tablet"
            else -> "phone"
        }
    }

    private fun emulatorReasons(): List<String> {
        val reasons = mutableListOf<String>()
        val fingerprint = Build.FINGERPRINT
        if (fingerprint.startsWith("generic") || fingerprint.startsWith("unknown") || fingerprint.contains("emulator")) reasons += "emulator build fingerprint"
        if (Build.HARDWARE in setOf("goldfish", "ranchu", "vbox86", "gce_x86", "cutf_cvm")) reasons += "emulator hardware ${Build.HARDWARE}"
        val product = Build.PRODUCT.lowercase(Locale.ROOT)
        if (product.contains("sdk_gphone") || product == "google_sdk" || product.contains("vbox86p") || product.contains("emulator") || product.contains("simulator")) reasons += "emulator product $product"
        if (Build.MODEL.contains("Emulator") || Build.MODEL.contains("Android SDK built for")) reasons += "emulator model ${Build.MODEL}"
        if (Build.MANUFACTURER.contains("Genymotion")) reasons += "Genymotion"
        if (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")) reasons += "generic brand and device"
        if (File("/dev/qemu_pipe").exists() || File("/dev/socket/qemud").exists()) reasons += "qemu device files"
        return reasons
    }

    // -------------------------------------------------------------------------
    // Package
    // -------------------------------------------------------------------------

    @Suppress("DEPRECATION")
    private fun packageInfo(): Map<String, Any?> {
        val pm = context.packageManager
        val name = context.packageName
        val info: PackageInfo =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getPackageInfo(name, PackageManager.PackageInfoFlags.of(PackageManager.GET_SIGNING_CERTIFICATES.toLong()))
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                pm.getPackageInfo(name, PackageManager.GET_SIGNING_CERTIFICATES)
            } else {
                pm.getPackageInfo(name, PackageManager.GET_SIGNATURES)
            }
        val app = context.applicationInfo
        val installer =
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) pm.getInstallSourceInfo(name).installingPackageName else pm.getInstallerPackageName(name)
            } catch (_: Exception) {
                null
            }
        val signatures =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                info.signingInfo?.apkContentsSigners
            } else {
                info.signatures
            }
        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) info.longVersionCode else info.versionCode.toLong()
        return mapOf(
            "appName" to app.loadLabel(pm).toString(),
            "packageName" to name,
            "version" to (info.versionName ?: "0.0.0"),
            "buildNumber" to versionCode.toString(),
            "installer" to installer,
            "installTime" to info.firstInstallTime,
            "updateTime" to info.lastUpdateTime,
            "signature" to signatures?.firstOrNull()?.let { sha256(it.toByteArray()) },
            "minSdk" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) app.minSdkVersion else null,
            "targetSdk" to app.targetSdkVersion,
            "executable" to app.sourceDir,
        )
    }

    private fun sha256(bytes: ByteArray): String =
        MessageDigest.getInstance("SHA-256").digest(bytes).joinToString(":") { "%02X".format(it) }

    // -------------------------------------------------------------------------
    // Network
    // -------------------------------------------------------------------------

    private fun network(): Map<String, Any?> {
        val active = connectivity.activeNetwork ?: return offline()
        val caps = connectivity.getNetworkCapabilities(active) ?: return offline()
        return snapshot(caps, connectivity.getLinkProperties(active))
    }

    private fun offline(): Map<String, Any?> = mapOf("types" to emptyList<String>(), "connected" to false, "internet" to false, "constrained" to dataSaverOn())

    private fun snapshot(
        caps: NetworkCapabilities,
        link: LinkProperties?,
    ): Map<String, Any?> {
        val types = mutableListOf<String>()
        if (caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) types += "wifi"
        if (caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) types += "cellular"
        if (caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)) types += "ethernet"
        if (caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) types += "vpn"
        if (caps.hasTransport(NetworkCapabilities.TRANSPORT_BLUETOOTH)) types += "bluetooth"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && caps.hasTransport(NetworkCapabilities.TRANSPORT_USB)) types += "usb"
        // TRANSPORT_SATELLITE (10) is API 35; compare by value so older compileSdk levels still build.
        if (Build.VERSION.SDK_INT >= 35 && caps.hasTransport(10)) types += "satellite"
        if (types.isEmpty()) types += "other"

        var metered = !caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_TEMPORARILY_NOT_METERED)) metered = false
        val result =
            mutableMapOf<String, Any?>(
                "types" to types,
                "connected" to caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET),
                "internet" to caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED),
                "captivePortal" to caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_CAPTIVE_PORTAL),
                "metered" to metered,
                "constrained" to dataSaverOn(),
                "downKbps" to caps.linkDownstreamBandwidthKbps.takeIf { it > 0 },
                "upKbps" to caps.linkUpstreamBandwidthKbps.takeIf { it > 0 },
                "interface" to link?.interfaceName,
            )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) result["roaming"] = !caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_ROAMING)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) result["signal"] = caps.signalStrength.takeIf { it != NetworkCapabilities.SIGNAL_STRENGTH_UNSPECIFIED }
        if ("cellular" in types) result["cellular"] = cellularGeneration()
        return result
    }

    private fun dataSaverOn(): Boolean = connectivity.restrictBackgroundStatus == ConnectivityManager.RESTRICT_BACKGROUND_STATUS_ENABLED

    // getDataNetworkType needs READ_PHONE_STATE (API 30+). We never request it; if the app holds it
    // we use it, below API 30 the deprecated getNetworkType needs nothing.
    @SuppressLint("MissingPermission")
    @Suppress("DEPRECATION")
    private fun cellularGeneration(): String? {
        val telephony = context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager ?: return null
        val type =
            try {
                when {
                    context.checkSelfPermission(Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED -> telephony.dataNetworkType
                    Build.VERSION.SDK_INT < Build.VERSION_CODES.R -> telephony.networkType
                    else -> return null
                }
            } catch (_: SecurityException) {
                return null
            }
        return when (type) {
            TelephonyManager.NETWORK_TYPE_GPRS, TelephonyManager.NETWORK_TYPE_EDGE, TelephonyManager.NETWORK_TYPE_CDMA,
            TelephonyManager.NETWORK_TYPE_1xRTT, TelephonyManager.NETWORK_TYPE_IDEN, TelephonyManager.NETWORK_TYPE_GSM,
            -> "2g"
            TelephonyManager.NETWORK_TYPE_UMTS, TelephonyManager.NETWORK_TYPE_EVDO_0, TelephonyManager.NETWORK_TYPE_EVDO_A,
            TelephonyManager.NETWORK_TYPE_HSDPA, TelephonyManager.NETWORK_TYPE_HSUPA, TelephonyManager.NETWORK_TYPE_HSPA,
            TelephonyManager.NETWORK_TYPE_EVDO_B, TelephonyManager.NETWORK_TYPE_EHRPD, TelephonyManager.NETWORK_TYPE_HSPAP,
            TelephonyManager.NETWORK_TYPE_TD_SCDMA,
            -> "3g"
            TelephonyManager.NETWORK_TYPE_LTE, TelephonyManager.NETWORK_TYPE_IWLAN -> "4g"
            TelephonyManager.NETWORK_TYPE_NR -> "5g"
            else -> null
        }
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?,
    ) {
        sink = events
        val cb =
            object : ConnectivityManager.NetworkCallback() {
                private var caps: NetworkCapabilities? = null
                private var link: LinkProperties? = null

                override fun onCapabilitiesChanged(
                    network: Network,
                    networkCapabilities: NetworkCapabilities,
                ) {
                    caps = networkCapabilities
                    emit(snapshot(networkCapabilities, link ?: connectivity.getLinkProperties(network)))
                }

                override fun onLinkPropertiesChanged(
                    network: Network,
                    linkProperties: LinkProperties,
                ) {
                    link = linkProperties
                    caps?.let { emit(snapshot(it, linkProperties)) }
                }

                override fun onLost(network: Network) {
                    caps = null
                    link = null
                    emit(offline())
                }
            }
        try {
            connectivity.registerDefaultNetworkCallback(cb)
            callback = cb
        } catch (e: Exception) {
            events?.error("u_device", "Cannot watch the network: ${e.message}", null)
        }
        // Data Saver toggles do not change the network, so they need their own broadcast.
        val receiver =
            object : BroadcastReceiver() {
                override fun onReceive(
                    c: Context?,
                    intent: Intent?,
                ) = emit(network())
            }
        val filter = IntentFilter(ConnectivityManager.ACTION_RESTRICT_BACKGROUND_CHANGED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            context.registerReceiver(receiver, filter)
        }
        dataSaverReceiver = receiver
    }

    override fun onCancel(arguments: Any?) {
        callback?.let {
            try {
                connectivity.unregisterNetworkCallback(it)
            } catch (_: Exception) {
            }
        }
        callback = null
        dataSaverReceiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (_: Exception) {
            }
        }
        dataSaverReceiver = null
        sink = null
    }

    private fun emit(snapshot: Map<String, Any?>) {
        main.post { sink?.success(snapshot) }
    }

    // -------------------------------------------------------------------------
    // Status
    // -------------------------------------------------------------------------

    private fun status(): Map<String, Any?> {
        val battery = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val sticky = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val present = sticky?.getBooleanExtra(BatteryManager.EXTRA_PRESENT, true) ?: true
        val state =
            if (!present) {
                "none"
            } else {
                when (sticky?.getIntExtra(BatteryManager.EXTRA_STATUS, -1)) {
                    BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
                    BatteryManager.BATTERY_STATUS_DISCHARGING -> "discharging"
                    BatteryManager.BATTERY_STATUS_FULL -> "full"
                    BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "notCharging"
                    else -> "unknown"
                }
            }
        val level = battery.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY).takeIf { present && it in 0..100 }
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val thermal =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                when (power.currentThermalStatus) {
                    PowerManager.THERMAL_STATUS_NONE, PowerManager.THERMAL_STATUS_LIGHT -> "nominal"
                    PowerManager.THERMAL_STATUS_MODERATE -> "fair"
                    PowerManager.THERMAL_STATUS_SEVERE -> "serious"
                    else -> "critical"
                }
            } else {
                "unknown"
            }
        val memory = ActivityManager.MemoryInfo().also { (context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager).getMemoryInfo(it) }
        val disk = StatFs(context.filesDir.absolutePath)
        return mapOf(
            "battery" to level,
            "batteryState" to state,
            "powerSave" to power.isPowerSaveMode,
            "thermal" to thermal,
            "memFree" to memory.availMem,
            "memTotal" to memory.totalMem,
            "diskFree" to disk.availableBytes,
            "diskTotal" to disk.totalBytes,
            "uptimeMs" to SystemClock.elapsedRealtime(),
        )
    }

    // -------------------------------------------------------------------------
    // Integrity
    // -------------------------------------------------------------------------

    private fun integrity(): Map<String, Any?> {
        val reasons = mutableListOf<String>()

        val rootReasons = mutableListOf<String>()
        for (path in SU_PATHS) if (File(path).exists()) rootReasons += "su binary at $path"
        if (Build.TAGS?.contains("test-keys") == true) rootReasons += "test-keys build"
        for (path in listOf("/system/app/Superuser.apk", "/data/adb/magisk", "/sbin/.magisk", "/data/adb/ksu")) if (File(path).exists()) rootReasons += "root manager at $path"
        readText("/proc/mounts")?.let { if (it.contains("magisk", ignoreCase = true)) rootReasons += "magisk mount" }
        reasons += rootReasons

        val emulator = emulatorReasons()
        reasons += emulator

        val hookReasons = mutableListOf<String>()
        readText("/proc/self/maps")?.lowercase(Locale.ROOT)?.let { maps ->
            for (marker in listOf("frida", "gadget", "xposed", "lsposed", "substrate", "riru", "zygisk")) if (maps.contains(marker)) hookReasons += "$marker loaded in process"
        }
        for (cls in listOf("de.robv.android.xposed.XposedBridge", "de.robv.android.xposed.XC_MethodHook")) {
            try {
                Class.forName(cls)
                hookReasons += "Xposed class $cls"
                break
            } catch (_: ClassNotFoundException) {
            }
        }
        if (portOpen(27042)) hookReasons += "frida-server port 27042 open"
        reasons += hookReasons

        val debugger = Debug.isDebuggerConnected() || Debug.waitingForDebugger()
        if (debugger) reasons += "debugger attached"
        if (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) reasons += "debuggable build"

        val developer = Settings.Global.getInt(context.contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) != 0
        val adb = Settings.Global.getInt(context.contentResolver, Settings.Global.ADB_ENABLED, 0) != 0
        if (developer) reasons += "developer options on"
        if (adb) reasons += "USB debugging on"

        return mapOf(
            "rooted" to rootReasons.isNotEmpty(),
            "emulator" to emulator.isNotEmpty(),
            "debugger" to debugger,
            "hooked" to hookReasons.isNotEmpty(),
            "developerMode" to developer,
            "adb" to adb,
            "reasons" to reasons,
        )
    }

    private fun readText(path: String): String? =
        try {
            File(path).readText()
        } catch (_: Exception) {
            null
        }

    private fun portOpen(port: Int): Boolean =
        try {
            Socket().use { it.connect(InetSocketAddress("127.0.0.1", port), 150) }
            true
        } catch (_: Exception) {
            false
        }

    private companion object {
        val SU_PATHS =
            listOf(
                "/system/bin/su",
                "/system/xbin/su",
                "/sbin/su",
                "/su/bin/su",
                "/system/sd/xbin/su",
                "/system/bin/failsafe/su",
                "/data/local/su",
                "/data/local/bin/su",
                "/data/local/xbin/su",
                "/vendor/bin/su",
            )
    }
}
