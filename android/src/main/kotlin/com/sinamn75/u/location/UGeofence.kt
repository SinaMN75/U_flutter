package com.sinamn75.u.location

import android.Manifest
import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject

/** Geofences as framework proximity alerts, persisted so they survive restarts and reboots. */
internal object UGeofenceStore {
    private const val PREFS = "u_geofences"
    private const val KEY_FENCES = "fences"
    private const val KEY_EVENTS = "events"
    const val ACTION = "com.sinamn75.u.GEOFENCE"

    /** Set while Dart listens; events arriving without it are queued for the next listen. */
    @Volatile var sink: EventChannel.EventSink? = null

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun intent(
        context: Context,
        id: String,
    ): PendingIntent {
        val intent =
            Intent(context, UGeofenceReceiver::class.java)
                .setAction(ACTION)
                .setData(Uri.parse("u-geofence://${Uri.encode(id)}"))
                .putExtra("id", id)
        // Mutable: the system adds KEY_PROXIMITY_ENTERING when it fires.
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0)
        return PendingIntent.getBroadcast(context, id.hashCode(), intent, flags)
    }

    fun all(context: Context): List<Map<String, Any?>> {
        val array = JSONArray(prefs(context).getString(KEY_FENCES, "[]"))
        return (0 until array.length()).map { i -> array.getJSONObject(i).let { o -> o.keys().asSequence().associateWith { k -> o.opt(k)?.takeIf { it != JSONObject.NULL } } } }
    }

    private fun save(
        context: Context,
        fences: List<Map<String, Any?>>,
    ) {
        val array = JSONArray()
        fences.forEach { array.put(JSONObject(it)) }
        prefs(context).edit().putString(KEY_FENCES, array.toString()).apply()
    }

    @SuppressLint("MissingPermission")
    fun add(
        context: Context,
        manager: LocationManager,
        fence: Map<String, Any?>,
    ): Boolean {
        val id = "${fence["id"]}"
        return try {
            manager.addProximityAlert(
                (fence["latitude"] as Number).toDouble(),
                (fence["longitude"] as Number).toDouble(),
                (fence["radius"] as? Number)?.toFloat() ?: 100f,
                -1,
                intent(context, id),
            )
            save(context, all(context).filter { it["id"] != id } + fence)
            true
        } catch (_: Exception) {
            false
        }
    }

    fun remove(
        context: Context,
        manager: LocationManager,
        id: String,
    ) {
        try {
            manager.removeProximityAlert(intent(context, id))
        } catch (_: Exception) {
        }
        save(context, all(context).filter { it["id"] != id })
    }

    /** Proximity alerts are cleared on reboot: re-register them (called by the boot receiver). */
    fun restore(context: Context) {
        if (context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) return
        val manager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        all(context).forEach { add(context, manager, it) }
    }

    fun deliver(
        context: Context,
        event: Map<String, Any?>,
    ) {
        Handler(Looper.getMainLooper()).post {
            val current = sink
            if (current != null) {
                current.success(event)
            } else {
                val array = JSONArray(prefs(context).getString(KEY_EVENTS, "[]")).put(JSONObject(event))
                prefs(context).edit().putString(KEY_EVENTS, array.toString()).apply()
            }
        }
    }

    fun drain(context: Context): List<Map<String, Any?>> {
        val array = JSONArray(prefs(context).getString(KEY_EVENTS, "[]"))
        prefs(context).edit().remove(KEY_EVENTS).apply()
        return (0 until array.length()).map { i -> array.getJSONObject(i).let { o -> o.keys().asSequence().associateWith { k -> o.opt(k) } } }
    }
}

/** Receives proximity alerts, even when the app is not running. */
class UGeofenceReceiver : BroadcastReceiver() {
    override fun onReceive(
        context: Context,
        intent: Intent,
    ) {
        if (intent.action != UGeofenceStore.ACTION) return
        val id = intent.getStringExtra("id") ?: return
        val entering = intent.getBooleanExtra(LocationManager.KEY_PROXIMITY_ENTERING, false)
        val fence = UGeofenceStore.all(context).firstOrNull { it["id"] == id } ?: return
        if ((entering && fence["onEnter"] == false) || (!entering && fence["onExit"] == false)) return
        UGeofenceStore.deliver(context, mapOf("id" to id, "transition" to if (entering) "enter" else "exit", "time" to System.currentTimeMillis()))
        val title = fence["notificationTitle"] as? String ?: return
        notify(context, id, title, fence["notificationText"] as? String)
    }

    private fun notify(
        context: Context,
        id: String,
        title: String,
        text: String?,
    ) {
        if (Build.VERSION.SDK_INT >= 33 && context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(NotificationChannel(CHANNEL, "Places", NotificationManager.IMPORTANCE_DEFAULT))
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val tap = launch?.let { PendingIntent.getActivity(context, id.hashCode(), it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT) }
        val notification =
            NotificationCompat.Builder(context, CHANNEL)
                .setSmallIcon(context.applicationInfo.icon)
                .setContentTitle(title)
                .setContentText(text)
                .setAutoCancel(true)
                .setContentIntent(tap)
                .build()
        manager.notify(id.hashCode(), notification)
    }

    private companion object {
        const val CHANNEL = "u_geofence"
    }
}

/**
 * Keeps the app in the foreground while tracking location in the background. Declared by the
 * app (foregroundServiceType="location"), never by the plugin, so apps that do not track in the
 * background carry no location-service declaration for Play review.
 */
class ULocationService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int,
    ): Int {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(NotificationChannel(CHANNEL, "Location", NotificationManager.IMPORTANCE_LOW))
        val launch = packageManager.getLaunchIntentForPackage(packageName)
        val tap = launch?.let { PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_IMMUTABLE) }
        val notification =
            NotificationCompat.Builder(this, CHANNEL)
                .setSmallIcon(applicationInfo.icon)
                .setContentTitle(intent?.getStringExtra("title") ?: applicationInfo.loadLabel(packageManager))
                .setContentText(intent?.getStringExtra("text"))
                .setOngoing(true)
                .setContentIntent(tap)
                .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
                .build()
        try {
            if (Build.VERSION.SDK_INT >= 29) {
                startForeground(ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
            } else {
                startForeground(ID, notification)
            }
        } catch (_: Exception) {
            // Missing FOREGROUND_SERVICE_LOCATION or started from the background: stop quietly.
            stopSelf()
        }
        return START_NOT_STICKY
    }

    private companion object {
        const val CHANNEL = "u_location"
        const val ID = 0x554C
    }
}
