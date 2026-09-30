package com.sinamn75.u.location

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Address
import android.location.Geocoder
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.location.LocationRequest
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.Locale
import java.util.concurrent.Executors

/**
 * Native side of ULocation ("u/location" + updates / heading / geofence / visits events).
 * LocationManager only — the fused provider on Android 12+, GPS / network below — so it works
 * without Google Play Services. The app declares the permissions it needs; the plugin declares none.
 */
class ULocationHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler,
    PluginRegistry.RequestPermissionsResultListener {
    private val channel = MethodChannel(messenger, "u/location")
    private val updatesChannel = EventChannel(messenger, "u/location/updates")
    private val headingChannel = EventChannel(messenger, "u/location/heading")
    private val geofenceChannel = EventChannel(messenger, "u/location/geofence")
    private val visitsChannel = EventChannel(messenger, "u/location/visits")
    private val manager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    private val main = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()
    private val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private var binding: ActivityPluginBinding? = null
    private var pendingPermission: MethodChannel.Result? = null
    private var wantsAlways = false
    private var updatesSink: EventChannel.EventSink? = null
    private var updatesListener: LocationListener? = null
    private var headingListener: SensorEventListener? = null

    init {
        channel.setMethodCallHandler(this)
        updatesChannel.setStreamHandler(Updates())
        headingChannel.setStreamHandler(Heading())
        geofenceChannel.setStreamHandler(Geofences())
        visitsChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?,
                ) {}

                override fun onCancel(arguments: Any?) {}
            },
        )
    }

    private val activity: Activity? get() = binding?.activity

    fun attach(binding: ActivityPluginBinding) {
        detach()
        this.binding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    fun detach() {
        binding?.removeRequestPermissionsResultListener(this)
        binding = null
    }

    fun dispose() {
        detach()
        stopUpdates()
        stopHeading()
        channel.setMethodCallHandler(null)
        io.shutdown()
        UGeofenceStore.sink = null
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            when (call.method) {
                "permission" -> result.success(permission())
                "requestPermission" -> requestPermission(call.argument<Boolean>("always") == true, result)
                "requestPrecise" -> result.success(false)
                "current" -> current(call, result)
                "lastKnown" -> result.success(if (hasForeground()) lastKnown()?.let { toMap(it) } else null)
                "addGeofence" -> result.success(addGeofence(call.arguments as Map<*, *>))
                "removeGeofence" -> {
                    UGeofenceStore.remove(context, manager, call.argument<String>("id") ?: "")
                    result.success(null)
                }
                "clearGeofences" -> {
                    UGeofenceStore.all(context).forEach { UGeofenceStore.remove(context, manager, "${it["id"]}") }
                    result.success(null)
                }
                "geofences" -> result.success(UGeofenceStore.all(context))
                "reverseGeocode" -> geocode(call, result, reverse = true)
                "geocode" -> geocode(call, result, reverse = false)
                "geocodingAvailable" -> result.success(Geocoder.isPresent())
                else -> result.notImplemented()
            }
        } catch (e: SecurityException) {
            result.error("permissionDenied", e.message, null)
        } catch (e: Exception) {
            result.error("unavailable", e.message ?: e.javaClass.simpleName, null)
        }
    }

    // -------------------------------------------------------------------------
    // Permission
    // -------------------------------------------------------------------------

    private fun declared(permission: String): Boolean =
        try {
            val info =
                if (Build.VERSION.SDK_INT >= 33) {
                    context.packageManager.getPackageInfo(context.packageName, PackageManager.PackageInfoFlags.of(PackageManager.GET_PERMISSIONS.toLong()))
                } else {
                    @Suppress("DEPRECATION")
                    context.packageManager.getPackageInfo(context.packageName, PackageManager.GET_PERMISSIONS)
                }
            info.requestedPermissions?.contains(permission) == true
        } catch (_: Exception) {
            false
        }

    private fun granted(permission: String) = context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun hasForeground() = granted(Manifest.permission.ACCESS_FINE_LOCATION) || granted(Manifest.permission.ACCESS_COARSE_LOCATION)

    private fun hasBackground() = Build.VERSION.SDK_INT < 29 || granted(Manifest.permission.ACCESS_BACKGROUND_LOCATION)

    private fun serviceEnabled(): Boolean =
        if (Build.VERSION.SDK_INT >= 28) {
            manager.isLocationEnabled
        } else {
            manager.isProviderEnabled(LocationManager.GPS_PROVIDER) || manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        }

    private fun permission(): Map<String, Any?> {
        val status =
            when {
                !declared(Manifest.permission.ACCESS_FINE_LOCATION) && !declared(Manifest.permission.ACCESS_COARSE_LOCATION) -> "notDeclared"
                hasForeground() && hasBackground() -> "always"
                hasForeground() -> "whileInUse"
                !prefs.getBoolean(KEY_ASKED, false) -> "notDetermined"
                // Asked before and the OS will not show the dialog again.
                activity?.let {
                    !it.shouldShowRequestPermissionRationale(Manifest.permission.ACCESS_FINE_LOCATION) &&
                        !it.shouldShowRequestPermissionRationale(Manifest.permission.ACCESS_COARSE_LOCATION)
                } == true -> "deniedForever"
                else -> "denied"
            }
        return mapOf(
            "status" to status,
            "precise" to if (hasForeground()) granted(Manifest.permission.ACCESS_FINE_LOCATION) else null,
            "serviceEnabled" to serviceEnabled(),
        )
    }

    private fun requestPermission(
        always: Boolean,
        result: MethodChannel.Result,
    ) {
        val current = activity
        if (current == null || permission()["status"] == "notDeclared") return result.success(permission())
        val wanted =
            when {
                !hasForeground() -> listOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION).filter { declared(it) }
                always && !hasBackground() && declared(Manifest.permission.ACCESS_BACKGROUND_LOCATION) -> listOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
                else -> emptyList()
            }
        if (wanted.isEmpty()) return result.success(permission())
        pendingPermission?.success(permission())
        pendingPermission = result
        wantsAlways = always
        prefs.edit().putBoolean(KEY_ASKED, true).apply()
        current.requestPermissions(wanted.toTypedArray(), REQUEST_PERMISSION)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_PERMISSION) return false
        val result = pendingPermission ?: return true
        // Background access must be asked for separately, after foreground access (Android 11+).
        if (wantsAlways && hasForeground() && !hasBackground() && Manifest.permission.ACCESS_BACKGROUND_LOCATION !in permissions &&
            declared(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        ) {
            activity?.requestPermissions(arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION), REQUEST_PERMISSION)
            return true
        }
        pendingPermission = null
        result.success(permission())
        return true
    }

    // -------------------------------------------------------------------------
    // Positions
    // -------------------------------------------------------------------------

    private fun provider(accuracy: String): String? {
        val enabled = manager.getProviders(true)
        if (Build.VERSION.SDK_INT >= 31 && LocationManager.FUSED_PROVIDER in enabled) return LocationManager.FUSED_PROVIDER
        val fine = granted(Manifest.permission.ACCESS_FINE_LOCATION)
        val precise = accuracy == "high" || accuracy == "best" || accuracy == "navigation"
        return when {
            precise && fine && LocationManager.GPS_PROVIDER in enabled -> LocationManager.GPS_PROVIDER
            LocationManager.NETWORK_PROVIDER in enabled -> LocationManager.NETWORK_PROVIDER
            fine && LocationManager.GPS_PROVIDER in enabled -> LocationManager.GPS_PROVIDER
            else -> null
        }
    }

    @SuppressLint("MissingPermission")
    private fun lastKnown(): Location? =
        manager.getProviders(true).mapNotNull {
            try {
                manager.getLastKnownLocation(it)
            } catch (_: SecurityException) {
                null
            }
        }.maxByOrNull { it.time }

    @SuppressLint("MissingPermission")
    private fun current(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        if (!hasForeground()) return result.error("permissionDenied", null, null)
        if (!serviceEnabled()) return result.error("serviceDisabled", null, null)
        val maxAge = call.argument<Number>("maxAgeMs")?.toLong()
        if (maxAge != null) {
            lastKnown()?.takeIf { System.currentTimeMillis() - it.time <= maxAge }?.let { return result.success(toMap(it)) }
        }
        val provider = provider(call.argument<String>("accuracy") ?: "high") ?: return result.error("serviceDisabled", null, null)
        val timeout = call.argument<Number>("timeoutMs")?.toLong() ?: 20000L
        var done = false
        val finish: (Location?, String?) -> Unit = { location, error ->
            if (!done) {
                done = true
                if (location != null) result.success(toMap(location)) else result.error(error ?: "unavailable", null, null)
            }
        }
        if (Build.VERSION.SDK_INT >= 30) {
            val cancel = CancellationSignal()
            main.postDelayed({
                cancel.cancel()
                finish(null, "timeout")
            }, timeout)
            manager.getCurrentLocation(provider, cancel, context.mainExecutor) { location -> finish(location ?: lastKnown(), "unavailable") }
        } else {
            val listener =
                object : LocationListener {
                    override fun onLocationChanged(location: Location) {
                        manager.removeUpdates(this)
                        finish(location, null)
                    }

                    @Deprecated("Required below API 29")
                    override fun onStatusChanged(
                        provider: String?,
                        status: Int,
                        extras: Bundle?,
                    ) {}

                    override fun onProviderEnabled(provider: String) {}

                    override fun onProviderDisabled(provider: String) {}
                }
            manager.requestLocationUpdates(provider, 0L, 0f, listener, Looper.getMainLooper())
            main.postDelayed({
                manager.removeUpdates(listener)
                finish(null, "timeout")
            }, timeout)
        }
    }

    inner class Updates : EventChannel.StreamHandler {
        @SuppressLint("MissingPermission")
        override fun onListen(
            arguments: Any?,
            events: EventChannel.EventSink?,
        ) {
            val sink = events ?: return
            val args = arguments as? Map<*, *> ?: emptyMap<String, Any?>()
            if (!hasForeground()) return sink.error("permissionDenied", null, null)
            if (!serviceEnabled()) return sink.error("serviceDisabled", null, null)
            val accuracy = args["accuracy"] as? String ?: "high"
            val provider = provider(accuracy) ?: return sink.error("serviceDisabled", null, null)
            val interval = (args["intervalMs"] as? Number)?.toLong() ?: 5000L
            val distance = (args["distanceFilter"] as? Number)?.toFloat() ?: 0f
            stopUpdates()
            updatesSink = sink
            val listener =
                object : LocationListener {
                    override fun onLocationChanged(location: Location) {
                        updatesSink?.success(toMap(location))
                    }

                    @Deprecated("Required below API 29")
                    override fun onStatusChanged(
                        provider: String?,
                        status: Int,
                        extras: Bundle?,
                    ) {}

                    override fun onProviderEnabled(provider: String) {}

                    override fun onProviderDisabled(provider: String) {
                        updatesSink?.error("serviceDisabled", provider, null)
                    }
                }
            updatesListener = listener
            if (Build.VERSION.SDK_INT >= 31) {
                val quality =
                    when (accuracy) {
                        "lowest", "low" -> LocationRequest.QUALITY_LOW_POWER
                        "balanced" -> LocationRequest.QUALITY_BALANCED_POWER_ACCURACY
                        else -> LocationRequest.QUALITY_HIGH_ACCURACY
                    }
                val request = LocationRequest.Builder(interval).setQuality(quality).setMinUpdateDistanceMeters(distance).build()
                manager.requestLocationUpdates(provider, request, context.mainExecutor, listener)
            } else {
                manager.requestLocationUpdates(provider, interval, distance, listener, Looper.getMainLooper())
            }
            if (args["background"] == true) startService(args, sink)
        }

        override fun onCancel(arguments: Any?) {
            stopUpdates()
        }
    }

    // Keeps the process in the foreground while tracking; the app declares the service (see u:app).
    private fun startService(
        args: Map<*, *>,
        sink: EventChannel.EventSink,
    ) {
        val component = ComponentName(context, ULocationService::class.java)
        val declared =
            try {
                context.packageManager.getServiceInfo(component, 0)
                true
            } catch (_: PackageManager.NameNotFoundException) {
                false
            }
        if (!declared) return sink.error("notDeclared", "Declare com.sinamn75.u.location.ULocationService (foregroundServiceType=location) in AndroidManifest.xml", null)
        val intent =
            Intent().setComponent(component)
                .putExtra("title", args["notificationTitle"] as? String)
                .putExtra("text", args["notificationText"] as? String)
        try {
            if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(intent) else context.startService(intent)
        } catch (e: Exception) {
            sink.error("unavailable", e.message, null)
        }
    }

    private fun stopUpdates() {
        updatesListener?.let { manager.removeUpdates(it) }
        updatesListener = null
        updatesSink = null
        try {
            context.stopService(Intent(context, ULocationService::class.java))
        } catch (_: Exception) {
        }
    }

    // -------------------------------------------------------------------------
    // Heading
    // -------------------------------------------------------------------------

    inner class Heading : EventChannel.StreamHandler {
        override fun onListen(
            arguments: Any?,
            events: EventChannel.EventSink?,
        ) {
            val sink = events ?: return
            val sensors = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
            val rotation = sensors.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR) ?: return sink.error("unsupported", "No rotation sensor", null)
            stopHeading()
            val matrix = FloatArray(9)
            val angles = FloatArray(3)
            var accuracy = 30.0
            var last = -1.0
            var lastAt = 0L
            val listener =
                object : SensorEventListener {
                    override fun onSensorChanged(event: SensorEvent) {
                        SensorManager.getRotationMatrixFromVector(matrix, event.values)
                        SensorManager.getOrientation(matrix, angles)
                        val magnetic = (Math.toDegrees(angles[0].toDouble()) + 360) % 360
                        val now = System.currentTimeMillis()
                        // At most ~20 updates a second, and only when it moved by a degree.
                        if (now - lastAt < 50 || (last >= 0 && Math.abs(magnetic - last) < 1)) return
                        last = magnetic
                        lastAt = now
                        val location = if (hasForeground()) lastKnown() else null
                        val trueNorth =
                            location?.let {
                                val field = GeomagneticField(it.latitude.toFloat(), it.longitude.toFloat(), it.altitude.toFloat(), now)
                                (magnetic + field.declination + 360) % 360
                            }
                        sink.success(mapOf("magnetic" to magnetic, "true" to trueNorth, "accuracy" to accuracy, "time" to now))
                    }

                    override fun onAccuracyChanged(
                        sensor: Sensor?,
                        value: Int,
                    ) {
                        accuracy =
                            when (value) {
                                SensorManager.SENSOR_STATUS_ACCURACY_HIGH -> 10.0
                                SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM -> 20.0
                                else -> 45.0
                            }
                    }
                }
            headingListener = listener
            sensors.registerListener(listener, rotation, SensorManager.SENSOR_DELAY_UI)
        }

        override fun onCancel(arguments: Any?) {
            stopHeading()
        }
    }

    private fun stopHeading() {
        headingListener?.let { (context.getSystemService(Context.SENSOR_SERVICE) as SensorManager).unregisterListener(it) }
        headingListener = null
    }

    // -------------------------------------------------------------------------
    // Geofences (proximity alerts: framework API, no Play Services)
    // -------------------------------------------------------------------------

    private fun addGeofence(args: Map<*, *>): Boolean {
        if (!granted(Manifest.permission.ACCESS_FINE_LOCATION)) return false
        val fence = args.entries.associate { "${it.key}" to it.value }
        return UGeofenceStore.add(context, manager, fence)
    }

    inner class Geofences : EventChannel.StreamHandler {
        override fun onListen(
            arguments: Any?,
            events: EventChannel.EventSink?,
        ) {
            UGeofenceStore.sink = events
            // Transitions that happened while the app was not running.
            UGeofenceStore.drain(context).forEach { events?.success(it) }
        }

        override fun onCancel(arguments: Any?) {
            UGeofenceStore.sink = null
        }
    }

    // -------------------------------------------------------------------------
    // Geocoding
    // -------------------------------------------------------------------------

    private fun geocode(
        call: MethodCall,
        result: MethodChannel.Result,
        reverse: Boolean,
    ) {
        if (!Geocoder.isPresent()) return result.success(emptyList<Any>())
        val locale = call.argument<String>("locale")?.let { Locale.forLanguageTag(it) } ?: Locale.getDefault()
        val geocoder = Geocoder(context, locale)
        val deliver: (List<Address>?) -> Unit = { list -> main.post { result.success(list.orEmpty().map { placemark(it) }) } }
        if (Build.VERSION.SDK_INT >= 33) {
            val listener =
                object : Geocoder.GeocodeListener {
                    override fun onGeocode(addresses: MutableList<Address>) = deliver(addresses)

                    override fun onError(errorMessage: String?) = deliver(null)
                }
            if (reverse) {
                geocoder.getFromLocation(call.argument<Double>("latitude") ?: 0.0, call.argument<Double>("longitude") ?: 0.0, 5, listener)
            } else {
                geocoder.getFromLocationName(call.argument<String>("address") ?: "", 5, listener)
            }
        } else {
            io.execute {
                val list =
                    try {
                        @Suppress("DEPRECATION")
                        if (reverse) {
                            geocoder.getFromLocation(call.argument<Double>("latitude") ?: 0.0, call.argument<Double>("longitude") ?: 0.0, 5)
                        } else {
                            geocoder.getFromLocationName(call.argument<String>("address") ?: "", 5)
                        }
                    } catch (_: Exception) {
                        null
                    }
                deliver(list)
            }
        }
    }

    private fun placemark(a: Address): Map<String, Any?> =
        mapOf(
            "name" to a.featureName,
            "street" to a.thoroughfare,
            "houseNumber" to a.subThoroughfare,
            "city" to a.locality,
            "district" to a.subLocality,
            "state" to a.adminArea,
            "county" to a.subAdminArea,
            "postalCode" to a.postalCode,
            "country" to a.countryName,
            "countryCode" to a.countryCode,
            "latitude" to if (a.hasLatitude()) a.latitude else null,
            "longitude" to if (a.hasLongitude()) a.longitude else null,
            "lines" to (0..a.maxAddressLineIndex).mapNotNull { a.getAddressLine(it) },
        )

    companion object {
        private const val REQUEST_PERMISSION = 0x554C
        private const val PREFS = "u_location"
        private const val KEY_ASKED = "asked"

        fun toMap(l: Location): Map<String, Any?> {
            val map =
                mutableMapOf<String, Any?>(
                    "latitude" to l.latitude,
                    "longitude" to l.longitude,
                    "time" to l.time,
                    "accuracy" to if (l.hasAccuracy()) l.accuracy.toDouble() else null,
                    "altitude" to if (l.hasAltitude()) l.altitude else null,
                    "heading" to if (l.hasBearing()) l.bearing.toDouble() else null,
                    "speed" to if (l.hasSpeed()) l.speed.toDouble() else null,
                    "source" to l.provider,
                )
            if (Build.VERSION.SDK_INT >= 26) {
                if (l.hasVerticalAccuracy()) map["altitudeAccuracy"] = l.verticalAccuracyMeters.toDouble()
                if (l.hasBearingAccuracy()) map["headingAccuracy"] = l.bearingAccuracyDegrees.toDouble()
                if (l.hasSpeedAccuracy()) map["speedAccuracy"] = l.speedAccuracyMetersPerSecond.toDouble()
            }
            map["mocked"] =
                if (Build.VERSION.SDK_INT >= 31) {
                    l.isMock
                } else {
                    @Suppress("DEPRECATION")
                    l.isFromMockProvider
                }
            return map
        }
    }
}
