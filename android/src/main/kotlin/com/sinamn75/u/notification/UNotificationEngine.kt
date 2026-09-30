package com.sinamn75.u.notification

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationChannelGroup
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.RemoteInput
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject

/**
 * Everything notifications need without a running Flutter engine: building and posting,
 * alarms for schedules (re-armed after firing, reboots and time changes) and the event queue.
 */
internal object UNotificationEngine {
    private const val PREFS = "u_notifications"
    private const val KEY_SCHEDULES = "schedules"
    private const val KEY_EVENTS = "events"
    private const val KEY_ICON = "icon"
    const val EXTRA_EVENT = "u_notification"
    const val INPUT_KEY = "u_input"
    const val ACTION_FIRE = "com.sinamn75.u.notification.FIRE"
    const val ACTION_BUTTON = "com.sinamn75.u.notification.ACTION"
    const val ACTION_DISMISS = "com.sinamn75.u.notification.DISMISS"

    /** Set while Dart listens; otherwise events wait in preferences. */
    @Volatile var sink: EventChannel.EventSink? = null

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun manager(context: Context) = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    fun setIcon(
        context: Context,
        name: String?,
    ) {
        prefs(context).edit().putString(KEY_ICON, name).apply()
    }

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

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
        return (0 until array.length()).map { toMap(array.getJSONObject(it)) }
    }

    fun toMap(o: JSONObject): Map<String, Any?> = o.keys().asSequence().associateWith { k -> o.opt(k)?.takeIf { it != JSONObject.NULL } }

    // -------------------------------------------------------------------------
    // Channels
    // -------------------------------------------------------------------------

    fun importance(name: String?): Int =
        when (name) {
            "min" -> NotificationManager.IMPORTANCE_MIN
            "low" -> NotificationManager.IMPORTANCE_LOW
            "normal" -> NotificationManager.IMPORTANCE_DEFAULT
            else -> NotificationManager.IMPORTANCE_HIGH
        }

    private fun priority(name: String?): Int =
        when (name) {
            "min" -> NotificationCompat.PRIORITY_MIN
            "low" -> NotificationCompat.PRIORITY_LOW
            "normal" -> NotificationCompat.PRIORITY_DEFAULT
            "max" -> NotificationCompat.PRIORITY_MAX
            else -> NotificationCompat.PRIORITY_HIGH
        }

    fun createChannel(
        context: Context,
        c: Map<*, *>,
    ) {
        if (Build.VERSION.SDK_INT < 26) return
        val channel = NotificationChannel("${c["id"]}", "${c["name"] ?: c["id"]}", importance(c["importance"] as? String))
        (c["description"] as? String)?.let { channel.description = it }
        (c["group"] as? String)?.let { channel.group = it }
        channel.setShowBadge(c["showBadge"] != false)
        channel.setBypassDnd(c["bypassDnd"] == true)
        channel.enableVibration(c["vibration"] != false)
        (c["vibrationPattern"] as? List<*>)?.let { p -> channel.vibrationPattern = p.map { (it as Number).toLong() }.toLongArray() }
        (c["lightColor"] as? Number)?.let {
            channel.enableLights(true)
            channel.lightColor = it.toInt()
        }
        channel.lockscreenVisibility = visibility(c["visibility"] as? String)
        when (val sound = c["sound"] as? String) {
            null -> {}
            "none" -> channel.setSound(null, null)
            else -> soundUri(context, sound)?.let { channel.setSound(it, AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION).build()) }
        }
        manager(context).createNotificationChannel(channel)
    }

    private fun soundUri(
        context: Context,
        name: String,
    ): Uri? {
        val id = context.resources.getIdentifier(name.substringBeforeLast('.'), "raw", context.packageName)
        return if (id == 0) null else Uri.parse("android.resource://${context.packageName}/$id")
    }

    // Channels are created on demand: one per importance for requests that name none.
    private fun channelFor(
        context: Context,
        request: Map<*, *>,
    ): String {
        val importance = request["importance"] as? String ?: "high"
        val id = request["channelId"] as? String ?: "u_$importance"
        if (Build.VERSION.SDK_INT >= 26 && manager(context).getNotificationChannel(id) == null) {
            val name =
                when (id) {
                    "u_min", "u_low" -> "Silent"
                    "u_normal" -> "General"
                    "u_high", "u_max" -> "Important"
                    else -> id
                }
            createChannel(context, mapOf("id" to id, "name" to name, "importance" to importance, "sound" to request["sound"]))
        }
        return id
    }

    private fun visibility(name: String?): Int =
        when (name) {
            "public" -> NotificationCompat.VISIBILITY_PUBLIC
            "secret" -> NotificationCompat.VISIBILITY_SECRET
            else -> NotificationCompat.VISIBILITY_PRIVATE
        }

    // -------------------------------------------------------------------------
    // Building
    // -------------------------------------------------------------------------

    private fun smallIcon(context: Context): Int {
        val name = prefs(context).getString(KEY_ICON, null)
        if (name != null) {
            for (type in listOf("drawable", "mipmap")) {
                val id = context.resources.getIdentifier(name, type, context.packageName)
                if (id != 0) return id
            }
        }
        return context.applicationInfo.icon
    }

    // Decoded at most ~1024px wide: full-size photos exceed the binder transaction limit.
    private fun bitmap(path: String?): Bitmap? {
        if (path == null) return null
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            var sample = 1
            while (bounds.outWidth / sample > 1024 || bounds.outHeight / sample > 1024) sample *= 2
            BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
        } catch (_: Exception) {
            null
        }
    }

    private fun eventJson(
        type: String,
        id: Int,
        actionId: String?,
        payload: Any?,
    ) = JSONObject().put("type", type).put("id", id).put("actionId", actionId ?: JSONObject.NULL).put("payload", payload ?: JSONObject.NULL).toString()

    // Opens the app; UNotificationHandler reads the event from the intent.
    private fun activityIntent(
        context: Context,
        code: Int,
        event: String,
    ): PendingIntent? {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
        launch.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK).putExtra(EXTRA_EVENT, event)
        return PendingIntent.getActivity(context, code, launch, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }

    private fun broadcast(
        context: Context,
        action: String,
        code: Int,
        event: String,
        mutable: Boolean = false,
    ): PendingIntent {
        val intent = Intent(context, UNotificationReceiver::class.java).setAction(action).putExtra(EXTRA_EVENT, event)
        // Replies need a mutable intent: the system writes the typed text into it.
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or if (mutable && Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getBroadcast(context, code, intent, flags)
    }

    fun show(
        context: Context,
        request: Map<*, *>,
    ): Boolean {
        val manager = manager(context)
        if (!manager.areNotificationsEnabled()) return false
        val id = (request["id"] as? Number)?.toInt() ?: 0
        val payload = request["payload"]
        val title = request["title"] as? String
        val body = request["body"] as? String
        val builder =
            NotificationCompat.Builder(context, channelFor(context, request))
                .setSmallIcon(smallIcon(context))
                .setContentTitle(title)
                .setContentText(body)
                .setPriority(priority(request["importance"] as? String))
                .setAutoCancel(request["autoCancel"] != false)
                .setOngoing(request["ongoing"] == true)
                .setVisibility(visibility(request["visibility"] as? String))
        (request["subtitle"] as? String)?.let { builder.setSubText(it) }
        (request["color"] as? Number)?.let { builder.setColor(it.toInt()) }
        (request["badge"] as? Number)?.let { builder.setNumber(it.toInt()) }
        (request["category"] as? String)?.let { builder.setCategory(if (it == "message") NotificationCompat.CATEGORY_MESSAGE else it) }
        (request["timeoutMs"] as? Number)?.let { builder.setTimeoutAfter(it.toLong()) }
        (request["when"] as? Number)?.let {
            builder.setWhen(it.toLong()).setShowWhen(true)
            if (request["chronometer"] == true) builder.setUsesChronometer(true)
        }
        if (request["silent"] == true) builder.setSilent(true)
        (request["group"] as? String)?.let {
            builder.setGroup(it)
            if (request["groupSummary"] == true) builder.setGroupSummary(true)
        }
        (request["progress"] as? Map<*, *>)?.let {
            builder.setProgress((it["max"] as? Number)?.toInt() ?: 100, (it["value"] as? Number)?.toInt() ?: 0, it["indeterminate"] == true)
            builder.setOnlyAlertOnce(true)
        }
        val large = bitmap(request["largeIcon"] as? String)
        large?.let { builder.setLargeIcon(it) }
        val picture = bitmap(request["image"] as? String)
        val lines = (request["lines"] as? List<*>)?.mapNotNull { it as? String }.orEmpty()
        when {
            picture != null -> builder.setStyle(NotificationCompat.BigPictureStyle().bigPicture(picture).setSummaryText(body).also { if (large == null) it.bigLargeIcon(null as Bitmap?) })
            lines.isNotEmpty() -> builder.setStyle(NotificationCompat.InboxStyle().also { style -> lines.forEach { style.addLine(it) } }.setSummaryText(body))
            body != null && body.length > 40 -> builder.setStyle(NotificationCompat.BigTextStyle().bigText(body))
        }
        val tap = activityIntent(context, id, eventJson("tap", id, null, payload))
        builder.setContentIntent(tap)
        builder.setDeleteIntent(broadcast(context, ACTION_DISMISS, id, eventJson("dismiss", id, null, payload)))
        if (request["fullScreen"] == true && tap != null && (Build.VERSION.SDK_INT < 34 || manager.canUseFullScreenIntent())) builder.setFullScreenIntent(tap, true)
        (request["actions"] as? List<*>)?.forEachIndexed { index, raw ->
            val action = raw as? Map<*, *> ?: return@forEachIndexed
            val actionId = "${action["id"]}"
            val label = "${action["title"] ?: actionId}"
            val code = id * 31 + index + 1
            val event = eventJson(if (action["input"] == true) "reply" else "action", id, actionId, payload)
            val intent =
                when {
                    action["input"] == true -> broadcast(context, ACTION_BUTTON, code, event, mutable = true)
                    action["foreground"] == true -> activityIntent(context, code, event)
                    else -> broadcast(context, ACTION_BUTTON, code, event)
                } ?: return@forEachIndexed
            val compat = NotificationCompat.Action.Builder(0, label, intent)
            if (action["input"] == true) {
                compat.addRemoteInput(RemoteInput.Builder(INPUT_KEY).setLabel(action["inputPlaceholder"] as? String ?: label).build())
                compat.setAllowGeneratedReplies(true)
            }
            builder.addAction(compat.build())
        }
        return try {
            manager.notify(id, builder.build())
            true
        } catch (_: Exception) {
            false
        }
    }

    // -------------------------------------------------------------------------
    // Schedules
    // -------------------------------------------------------------------------

    fun schedules(context: Context): MutableMap<String, JSONObject> {
        val all = JSONObject(prefs(context).getString(KEY_SCHEDULES, "{}"))
        return all.keys().asSequence().associateWith { all.getJSONObject(it) }.toMutableMap()
    }

    private fun saveSchedules(
        context: Context,
        map: Map<String, JSONObject>,
    ) {
        prefs(context).edit().putString(KEY_SCHEDULES, JSONObject(map as Map<*, *>).toString()).apply()
    }

    private fun alarmIntent(
        context: Context,
        id: Int,
    ) = PendingIntent.getBroadcast(
        context,
        id,
        Intent(context, UNotificationReceiver::class.java).setAction(ACTION_FIRE).setData(Uri.parse("u-notify://$id")).putExtra("id", id),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    fun schedule(
        context: Context,
        record: JSONObject,
    ): Boolean {
        val id = record.getJSONObject("request").optInt("id")
        // Repeats are computed from the first date, so "the 31st" never drifts to the 28th.
        if (!record.has("anchor")) record.put("anchor", record.getLong("at"))
        val next = nextFire(record) ?: return false.also { remove(context, id) }
        record.put("at", next)
        saveSchedules(context, schedules(context).apply { put("$id", record) })
        return arm(context, id, next, record.optBoolean("exact", true))
    }

    // Exact when allowed (Android 12+ needs "Alarms & reminders"), otherwise within a few minutes.
    private fun arm(
        context: Context,
        id: Int,
        at: Long,
        exact: Boolean,
    ): Boolean {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = alarmIntent(context, id)
        return try {
            if (exact && (Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms())) {
                alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
            } else {
                alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
            }
            true
        } catch (_: SecurityException) {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
            true
        }
    }

    fun remove(
        context: Context,
        id: Int,
    ) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(alarmIntent(context, id))
        saveSchedules(context, schedules(context).apply { remove("$id") })
    }

    fun removeAll(context: Context) {
        schedules(context).keys.forEach { remove(context, it.toInt()) }
    }

    /** Re-arms every schedule (after boot, update or a clock / time-zone change). */
    fun restore(context: Context) {
        schedules(context).values.forEach { schedule(context, it) }
    }

    fun fire(
        context: Context,
        id: Int,
    ) {
        val record = schedules(context)["$id"] ?: return
        val request = toMap(record.getJSONObject("request")).mapValues { (_, v) -> unwrap(v) }
        show(context, request)
        if (record.optString("repeat", "none") == "none") {
            remove(context, id)
        } else {
            // nextFire steps past "now", so a late alarm never fires the same occurrence twice.
            schedule(context, record)
        }
    }

    private fun unwrap(value: Any?): Any? =
        when (value) {
            is JSONObject -> toMap(value).mapValues { (_, v) -> unwrap(v) }
            is JSONArray -> (0 until value.length()).map { unwrap(value.opt(it)?.takeIf { v -> v != JSONObject.NULL }) }
            else -> value
        }

    /** The first fire time after now, in the device time zone; monthly / yearly in Gregorian or Persian. */
    fun nextFire(record: JSONObject): Long? {
        val repeat = record.optString("repeat", "none")
        val at = record.getLong("at")
        val now = System.currentTimeMillis()
        if (repeat == "none") return if (at > now) at else null
        val anchor = record.optLong("anchor", at)
        val locale = if (record.optString("calendar") == "persian") android.icu.util.ULocale("fa_IR@calendar=persian") else android.icu.util.ULocale.getDefault()
        val calendar = android.icu.util.Calendar.getInstance(android.icu.util.TimeZone.getDefault(), locale)
        val field =
            when (repeat) {
                "minute" -> android.icu.util.Calendar.MINUTE
                "hourly" -> android.icu.util.Calendar.HOUR_OF_DAY
                "daily" -> android.icu.util.Calendar.DAY_OF_MONTH
                "weekly" -> android.icu.util.Calendar.WEEK_OF_YEAR
                "monthly" -> android.icu.util.Calendar.MONTH
                else -> android.icu.util.Calendar.YEAR
            }
        // k-th occurrence from the anchor: ICU clamps each one to its month on its own.
        val period =
            when (repeat) {
                "minute" -> 60_000L
                "hourly" -> 3_600_000L
                "daily" -> 86_400_000L
                "weekly" -> 604_800_000L
                "monthly" -> 31L * 86_400_000L
                else -> 366L * 86_400_000L
            }
        var k = maxOf(0L, (now - anchor) / period - 1).toInt()
        while (true) {
            calendar.timeInMillis = anchor
            calendar.add(field, k)
            if (calendar.timeInMillis > now) return calendar.timeInMillis
            k++
        }
    }

    fun createGroup(
        context: Context,
        id: String,
        name: String,
    ) {
        if (Build.VERSION.SDK_INT >= 26) manager(context).createNotificationChannelGroup(NotificationChannelGroup(id, name))
    }
}
