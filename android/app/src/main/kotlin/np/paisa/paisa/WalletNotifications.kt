package np.paisa.paisa

import android.app.Notification
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationManagerCompat
import org.json.JSONArray
import org.json.JSONObject

/**
 * eSewa and Khalti app notifications, and eSewa/Khalti emails as Gmail
 * shows them, for the Transaction Inbox. Every other notification is
 * ignored. Like SMS, parsing and every decision happen in Dart.
 */
object WalletNotifications {
    private const val PREFS = "paisa_sms"
    private const val KEY_QUEUE = "queued_notifications"
    private const val MAX_QUEUED = 100
    private const val GMAIL = "com.google.android.gm"

    /** The sender ID a notification stands for, or null to ignore it. */
    fun senderFor(packageName: String, title: String): String? {
        val pkg = packageName.lowercase()
        if (pkg == GMAIL) {
            // Gmail's title is who the email is from.
            val from = title.lowercase()
            return when {
                "esewa" in from -> "eSewa"
                "khalti" in from -> "Khalti"
                else -> null
            }
        }
        return when {
            "esewa" in pkg -> "eSewa"
            "khalti" in pkg -> "Khalti"
            else -> null
        }
    }

    fun hasAccess(context: Context): Boolean =
        NotificationManagerCompat.getEnabledListenerPackages(context).contains(context.packageName)

    fun openAccessSettings(context: Context) {
        val component = ComponentName(context, WalletNotificationListener::class.java)
        val direct = if (Build.VERSION.SDK_INT >= 30) {
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS)
                .putExtra(Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME, component.flattenToString())
        } else {
            null
        }
        val list = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        for (intent in listOfNotNull(direct, list)) {
            try {
                context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return
            } catch (_: Exception) {
                // Some phones lack the detail screen; try the list.
            }
        }
    }

    fun openAppSettings(context: Context) {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", context.packageName, null))
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    private val balance = Regex("(?i)(bal\\w*\\.?(?:\\s+(?:amt|amount|is|of))?\\.?\\s*[:\\-]?\\s*(?:NPR|NRs\\.?|Rs\\.?)?\\s*)\\d[\\d,]*(?:\\.\\d+)?")
    private val longNumber = Regex("\\b\\d{4,}(\\d{4})\\b")

    /** Rough mask for the short time a notification waits in the queue; Dart masks again. */
    fun roughMask(text: String): String =
        longNumber.replace(balance.replace(text) { "${it.groupValues[1]}●●●●●●" }) { "##${it.groupValues[1]}" }

    private fun text(n: Notification): Pair<String, String> {
        val e = n.extras
        val title = e.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim() ?: ""
        val body = (e.getCharSequence(Notification.EXTRA_BIG_TEXT) ?: e.getCharSequence(Notification.EXTRA_TEXT))
            ?.toString()?.trim() ?: ""
        return title to body
    }

    fun onPosted(context: Context, sbn: StatusBarNotification) {
        val n = sbn.notification ?: return
        if (n.flags and Notification.FLAG_GROUP_SUMMARY != 0) return
        if (n.flags and Notification.FLAG_ONGOING_EVENT != 0) return
        val (title, body) = text(n)
        val sender = senderFor(sbn.packageName, title) ?: return
        if (!SmsBridge.isTrusted(sender, SmsBridge.trustedSenders(context))) return
        // Wallet apps put the event in the title ("Payment Successful"); for
        // Gmail the title is only who it's from.
        val message = when {
            sbn.packageName == GMAIL -> body
            title.isEmpty() || body.startsWith(title) -> body
            else -> "$title. $body"
        }
        if (message.isBlank()) return
        val time = if (n.`when` > 0) n.`when` else sbn.postTime
        val id = "n:${sbn.packageName}:${sbn.key}:$time:${message.hashCode()}"
        val live = SmsBridge.sink
        if (live != null) {
            live.success(mapOf("sender" to sender, "body" to message, "timestamp" to time, "id" to id))
        } else {
            enqueue(context, sender, roughMask(message), time, id)
        }
        if (!SmsBridge.foreground && SmsBridge.looksLikeTransaction(message)) SmsBridge.notifyReview(context)
    }

    @Synchronized
    private fun enqueue(context: Context, sender: String, body: String, time: Long, id: String) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val queue = JSONArray(prefs.getString(KEY_QUEUE, "[]"))
        queue.put(JSONObject().put("sender", sender).put("body", body).put("timestamp", time).put("id", id))
        val kept = JSONArray()
        for (i in maxOf(0, queue.length() - MAX_QUEUED) until queue.length()) kept.put(queue.get(i))
        prefs.edit().putString(KEY_QUEUE, kept.toString()).apply()
    }

    /** Notifications that came while Paisa was closed; removed once taken. */
    @Synchronized
    fun take(context: Context): List<Map<String, Any?>> {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val queue = JSONArray(prefs.getString(KEY_QUEUE, "[]"))
        prefs.edit().remove(KEY_QUEUE).apply()
        return (0 until queue.length()).map { i ->
            val o = queue.getJSONObject(i)
            mapOf("sender" to o.getString("sender"), "body" to o.getString("body"), "timestamp" to o.getLong("timestamp"), "id" to o.getString("id"))
        }
    }
}

/** Turned on by the user in Android's Notification access screen. */
class WalletNotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            WalletNotifications.onPosted(applicationContext, sbn)
        } catch (_: Exception) {
            // A malformed notification must never crash the listener.
        }
    }
}
