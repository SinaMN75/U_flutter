package com.sinamn75.u.notification

import android.Manifest
import android.app.Activity
import android.app.AlarmManager
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.RemoteInput
import com.sinamn75.u.location.UGeofenceStore
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import org.json.JSONObject

/** Native side of UNotification ("u/notify" + "u/notify/events"). */
class UNotificationHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    PluginRegistry.NewIntentListener,
    PluginRegistry.RequestPermissionsResultListener {
    private val channel = MethodChannel(messenger, "u/notify")
    private val events = EventChannel(messenger, "u/notify/events")
    private val prefs = context.getSharedPreferences("u_notifications", Context.MODE_PRIVATE)
    private var binding: ActivityPluginBinding? = null
    private var pendingPermission: MethodChannel.Result? = null
    private var launchEvent: Map<String, Any?>? = null
    private var launchRead = false

    init {
        channel.setMethodCallHandler(this)
        events.setStreamHandler(this)
    }

    private val activity: Activity? get() = binding?.activity

    fun attach(binding: ActivityPluginBinding) {
        detach()
        this.binding = binding
        binding.addOnNewIntentListener(this)
        binding.addRequestPermissionsResultListener(this)
        if (!launchRead) {
            launchRead = true
            launchEvent = eventFrom(binding.activity.intent)?.also { UNotificationEngine.deliver(context, it) }
        }
    }

    fun detach() {
        binding?.removeOnNewIntentListener(this)
        binding?.removeRequestPermissionsResultListener(this)
        binding = null
    }

    fun dispose() {
        detach()
        channel.setMethodCallHandler(null)
        events.setStreamHandler(null)
        UNotificationEngine.sink = null
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            when (call.method) {
                "init" -> {
                    UNotificationEngine.setIcon(context, call.argument<String>("icon"))
                    result.success(null)
                }
                "permission" -> result.success(permission())
                "requestPermission" -> requestPermission(result)
                "show" -> result.success(UNotificationEngine.show(context, call.arguments as Map<*, *>))
                "schedule" -> result.success(UNotificationEngine.schedule(context, JSONObject(call.arguments as Map<*, *>)))
                "cancel" -> {
                    val id = call.argument<Int>("id") ?: 0
                    NotificationManagerCompat.from(context).cancel(id)
                    UNotificationEngine.remove(context, id)
                    result.success(null)
                }
                "cancelAll" -> {
                    NotificationManagerCompat.from(context).cancelAll()
                    UNotificationEngine.removeAll(context)
                    result.success(null)
                }
                "cancelGroup" -> {
                    val group = call.argument<String>("group")
                    val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    manager.activeNotifications.filter { it.notification.group == group }.forEach { manager.cancel(it.tag, it.id) }
                    result.success(null)
                }
                "pending" -> result.success(pending())
                "active" -> result.success(active())
                "createChannel" -> {
                    UNotificationEngine.createChannel(context, call.arguments as Map<*, *>)
                    result.success(null)
                }
                "deleteChannel" -> {
                    if (Build.VERSION.SDK_INT >= 26) (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).deleteNotificationChannel(call.argument<String>("id"))
                    result.success(null)
                }
                "createChannelGroup" -> {
                    UNotificationEngine.createGroup(context, call.argument<String>("id") ?: "", call.argument<String>("name") ?: "")
                    result.success(null)
                }
                "channels" ->
                    result.success(
                        if (Build.VERSION.SDK_INT >= 26) (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).notificationChannels.map { it.id } else emptyList(),
                    )
                // Android badges come from the notifications themselves (UNotificationRequest.badge).
                "setBadge" -> result.success(false)
                "launchEvent" -> result.success(launchEvent)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("u_notify", e.message ?: e.javaClass.simpleName, null)
        }
    }

    private fun granted() = Build.VERSION.SDK_INT < 33 || context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    private fun permission(): Map<String, Any?> {
        val enabled = NotificationManagerCompat.from(context).areNotificationsEnabled()
        val status =
            when {
                granted() && enabled -> "granted"
                !granted() && !prefs.getBoolean("asked", false) -> "notDetermined"
                else -> "denied"
            }
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return mapOf(
            "status" to status,
            "alert" to enabled,
            "exactAlarms" to (Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms()),
            "fullScreen" to (Build.VERSION.SDK_INT < 34 || manager.canUseFullScreenIntent()),
        )
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val current = activity
        if (Build.VERSION.SDK_INT < 33 || granted() || current == null) return result.success(permission())
        pendingPermission?.success(permission())
        pendingPermission = result
        prefs.edit().putBoolean("asked", true).apply()
        current.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_PERMISSION)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_PERMISSION) return false
        pendingPermission?.success(permission())
        pendingPermission = null
        return true
    }

    private fun pending(): List<Map<String, Any?>> =
        UNotificationEngine.schedules(context).values.map { record ->
            val request = record.getJSONObject("request")
            mapOf(
                "id" to request.optInt("id"),
                "title" to request.optString("title").takeIf { request.has("title") && !request.isNull("title") },
                "body" to request.optString("body").takeIf { request.has("body") && !request.isNull("body") },
                "payload" to request.optString("payload").takeIf { request.has("payload") && !request.isNull("payload") },
                "next" to record.optLong("at"),
            )
        }

    private fun active(): List<Map<String, Any?>> {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return manager.activeNotifications.map {
            mapOf(
                "id" to it.id,
                "title" to it.notification.extras.getCharSequence(android.app.Notification.EXTRA_TITLE)?.toString(),
                "body" to it.notification.extras.getCharSequence(android.app.Notification.EXTRA_TEXT)?.toString(),
                "group" to it.notification.group,
            )
        }
    }

    // Taps and foreground buttons open the activity with the event in an extra.
    private fun eventFrom(intent: Intent?): Map<String, Any?>? {
        if (intent == null || intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return null
        val raw = intent.getStringExtra(UNotificationEngine.EXTRA_EVENT) ?: return null
        intent.removeExtra(UNotificationEngine.EXTRA_EVENT)
        return try {
            UNotificationEngine.toMap(JSONObject(raw))
        } catch (_: Exception) {
            null
        }
    }

    override fun onNewIntent(intent: Intent): Boolean {
        val event = eventFrom(intent) ?: return false
        UNotificationEngine.deliver(context, event)
        return true
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?,
    ) {
        UNotificationEngine.sink = events
        UNotificationEngine.drain(context).forEach { events?.success(it) }
    }

    override fun onCancel(arguments: Any?) {
        UNotificationEngine.sink = null
    }

    private companion object {
        const val REQUEST_PERMISSION = 0x554E
    }
}

/** Scheduled fires, background buttons, replies and dismissals — with or without the app running. */
class UNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(
        context: Context,
        intent: Intent,
    ) {
        when (intent.action) {
            UNotificationEngine.ACTION_FIRE -> UNotificationEngine.fire(context, intent.getIntExtra("id", 0))
            UNotificationEngine.ACTION_BUTTON, UNotificationEngine.ACTION_DISMISS -> {
                val raw = intent.getStringExtra(UNotificationEngine.EXTRA_EVENT) ?: return
                val event = UNotificationEngine.toMap(JSONObject(raw)).toMutableMap()
                RemoteInput.getResultsFromIntent(intent)?.getCharSequence(UNotificationEngine.INPUT_KEY)?.let { event["input"] = it.toString() }
                UNotificationEngine.deliver(context, event)
                // A handled reply / button must leave the shade, or Android keeps showing a spinner.
                if (intent.action == UNotificationEngine.ACTION_BUTTON) NotificationManagerCompat.from(context).cancel((event["id"] as? Number)?.toInt() ?: 0)
            }
        }
    }
}

/** Alarms and proximity alerts do not survive reboots, updates or clock changes: re-arm them. */
class UBootReceiver : BroadcastReceiver() {
    override fun onReceive(
        context: Context,
        intent: Intent,
    ) {
        UNotificationEngine.restore(context)
        if (intent.action != Intent.ACTION_TIME_CHANGED && intent.action != Intent.ACTION_TIMEZONE_CHANGED) UGeofenceStore.restore(context)
    }
}
