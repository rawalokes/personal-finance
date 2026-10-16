package np.paisa.paisa

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Telephony
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray

/**
 * Phone SMS for the Transaction Inbox (spec §6 step 1).
 *
 * Only messages from approved senders (Settings → Banks & wallets and each
 * account's SMS sender) are kept. Masking, parsing and every decision happen
 * in Dart; this side only hands over sender, text and time.
 */
object SmsBridge {
    private const val PREFS = "paisa_sms"
    private const val KEY_SENDERS = "trusted_senders"
    private const val CHANNEL_ID = "sms_review"
    const val EXTRA_OPEN_INBOX = "open_inbox"

    /** Set while the Flutter side listens; live messages go straight to it. */
    @Volatile var sink: EventChannel.EventSink? = null

    /** True while Paisa is on screen (no notification needed then). */
    @Volatile var foreground = false

    fun hasPermission(context: Context): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED

    fun permissions(): Array<String> {
        val list = mutableListOf(Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS)
        if (Build.VERSION.SDK_INT >= 33) list.add(Manifest.permission.POST_NOTIFICATIONS)
        return list.toTypedArray()
    }

    private fun norm(s: String): String = s.uppercase().filter { it.isLetterOrDigit() }

    fun setTrustedSenders(context: Context, senders: List<String>) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_SENDERS, JSONArray(senders).toString()).apply()
    }

    fun trustedSenders(context: Context): List<String> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_SENDERS, null) ?: return emptyList()
        val arr = JSONArray(raw)
        return (0 until arr.length()).map { norm(arr.getString(it)) }.filter { it.isNotEmpty() }
    }

    /**
     * The sender is an approved ID, or one behind a two-letter operator
     * prefix ("AD-NABIL_ALERT"). Same rule as Dart's senderMatches().
     */
    fun isTrusted(sender: String, trusted: List<String>): Boolean {
        val s = norm(sender)
        if (s.isEmpty()) return false
        return trusted.any { n ->
            s == n || (s.length == n.length + 2 && s.endsWith(n) && s[0].isLetter() && s[1].isLetter())
        }
    }

    private val amount = Regex("(?i)(?<![A-Za-z])(NPR|NRs|Rs)\\.?\\s*\\d|\\d\\s*(NPR|NRs)\\b")
    private val movement = Regex(
        "(?i)debited|credited|paid|received|withdrawn|withdrawal|refunded|reversed|transferred|deposited|used for|loaded|transaction of|debit of|payment of",
    )
    private val notMoney = Regex("(?i)\\bOTP\\b|one[- ]time password|verification code|\\boffers?\\b|T&C|apply now|will be (refunded|reversed|credited|debited)")

    /** Worth a "needs review" notification: it looks like money moved. */
    fun looksLikeTransaction(body: String): Boolean =
        amount.containsMatchIn(body) && movement.containsMatchIn(body) && !notMoney.containsMatchIn(body)

    private fun toMap(sender: String, body: String, timestamp: Long, id: String?): Map<String, Any?> =
        mapOf("sender" to sender, "body" to body, "timestamp" to timestamp, "id" to id)

    /** Messages on the phone from trusted senders since [since] (ms). */
    fun readInbox(context: Context, since: Long, senders: List<String>): List<Map<String, Any?>> {
        if (!hasPermission(context)) return emptyList()
        val trusted = senders.map { norm(it) }.filter { it.isNotEmpty() }
        val out = mutableListOf<Map<String, Any?>>()
        val cursor = context.contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            arrayOf(Telephony.Sms._ID, Telephony.Sms.ADDRESS, Telephony.Sms.BODY, Telephony.Sms.DATE, Telephony.Sms.DATE_SENT),
            "${Telephony.Sms.DATE} >= ?",
            arrayOf(since.toString()),
            "${Telephony.Sms.DATE} ASC",
        ) ?: return out
        cursor.use { c ->
            while (c.moveToNext()) {
                val address = c.getString(1) ?: continue
                if (!isTrusted(address, trusted)) continue
                val sent = c.getLong(4)
                // date_sent is the service-centre time, the same as a live
                // broadcast reports, so one message is never imported twice.
                val time = if (sent > 0) sent else c.getLong(3)
                out.add(toMap(address, c.getString(2) ?: "", time, c.getLong(0).toString()))
            }
        }
        return out
    }

    fun notifyReview(context: Context) {
        val manager = NotificationManagerCompat.from(context)
        if (!manager.areNotificationsEnabled()) return
        if (Build.VERSION.SDK_INT >= 26) {
            val channel = NotificationChannel(CHANNEL_ID, "Transactions to review", NotificationManager.IMPORTANCE_DEFAULT)
            channel.description = "Bank and wallet SMS waiting in the Transaction Inbox"
            context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
        val open = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_OPEN_INBOX, true)
        }
        val pending = PendingIntent.getActivity(context, 0, open, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        // No amounts or merchants on the lock screen.
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_sms)
            .setContentTitle("New transaction needs your review")
            .setContentText("Open Paisa to confirm it. Nothing is saved until you do.")
            .setAutoCancel(true)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setContentIntent(pending)
            .build()
        try {
            manager.notify(4821, notification)
        } catch (_: SecurityException) {
            // Notifications not allowed: the inbox still has the message.
        }
    }

    /**
     * From [SmsReceiver]. The text is never stored here: while Paisa runs it
     * goes straight to Dart (which masks it); otherwise Paisa reads it from
     * the phone's inbox the next time it opens.
     */
    fun onReceived(context: Context, sender: String, body: String, timestamp: Long) {
        if (!isTrusted(sender, trustedSenders(context))) return
        sink?.success(toMap(sender, body, timestamp, null))
        if (!foreground && looksLikeTransaction(body)) notifyReview(context)
    }
}

/** Registered in the manifest so SMS arrive even when Paisa is closed. */
class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val parts = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
        // Long messages arrive in parts; join them per sender.
        parts.filterNotNull().groupBy { it.originatingAddress ?: "" }.forEach { (sender, msgs) ->
            if (sender.isEmpty()) return@forEach
            val body = msgs.joinToString("") { it.messageBody ?: "" }
            SmsBridge.onReceived(context, sender, body, msgs.first().timestampMillis)
        }
    }
}
