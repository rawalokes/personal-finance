package np.paisa.paisa

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity: required by local_auth for fingerprint unlock.
class MainActivity : FlutterFragmentActivity() {
    private var pendingPermission: MethodChannel.Result? = null
    private var openInbox = false

    private val askSms = registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {
        pendingPermission?.success(SmsBridge.hasPermission(this))
        pendingPermission = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        openInbox = intent?.getBooleanExtra(SmsBridge.EXTRA_OPEN_INBOX, false) == true
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.getBooleanExtra(SmsBridge.EXTRA_OPEN_INBOX, false)) openInbox = true
    }

    override fun onResume() {
        super.onResume()
        SmsBridge.foreground = true
    }

    override fun onPause() {
        SmsBridge.foreground = false
        super.onPause()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // Settings → Security → "Block screenshots": FLAG_SECURE also blanks
        // the app in the recent-apps list.
        MethodChannel(messenger, "paisa/screen_security")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        if (call.arguments == true) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Transaction Inbox: bank and wallet SMS (SmsBridge.kt).
        MethodChannel(messenger, "paisa/sms").setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermission" -> result.success(SmsBridge.hasPermission(this))
                "requestPermission" -> {
                    if (SmsBridge.hasPermission(this)) {
                        result.success(true)
                    } else {
                        pendingPermission?.success(false)
                        pendingPermission = result
                        askSms.launch(SmsBridge.permissions())
                    }
                }
                "readInbox" -> {
                    val since = (call.argument<Number>("since") ?: 0).toLong()
                    val senders = call.argument<List<String>>("senders") ?: emptyList()
                    // Reading the SMS database can be slow on old phones.
                    Thread {
                        val list = try { SmsBridge.readInbox(this, since, senders) } catch (_: Exception) { emptyList() }
                        runOnUiThread { result.success(list) }
                    }.start()
                }
                "setTrustedSenders" -> {
                    @Suppress("UNCHECKED_CAST")
                    SmsBridge.setTrustedSenders(this, (call.arguments as? List<String>) ?: emptyList())
                    result.success(null)
                }
                "notificationAccess" -> result.success(WalletNotifications.hasAccess(this))
                "openNotificationAccess" -> {
                    WalletNotifications.openAccessSettings(this)
                    result.success(null)
                }
                "takeNotifications" -> result.success(WalletNotifications.take(this))
                "openAppSettings" -> {
                    try { WalletNotifications.openAppSettings(this) } catch (_: Exception) {}
                    result.success(null)
                }
                "takeOpenInbox" -> {
                    result.success(openInbox)
                    openInbox = false
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(messenger, "paisa/sms_events").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                SmsBridge.sink = events
            }

            override fun onCancel(arguments: Any?) {
                SmsBridge.sink = null
            }
        })
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        SmsBridge.sink = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
