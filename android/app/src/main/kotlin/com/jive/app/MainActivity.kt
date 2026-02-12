package com.jive.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.jive.app/stream"
    private val METHOD_CHANNEL = "com.jive.app/methods" // New channel for methods
    private var eventSink: EventChannel.EventSink? = null
    private var pendingEvent: Map<String, Any?>? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Setup EventChannel (Stream)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    pendingEvent?.let { payload ->
                        events?.success(payload)
                        pendingEvent = null
                    }
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )

        // 2. Setup MethodChannel (Function Calls)
        io.flutter.plugin.common.MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Could not open notification settings.", null)
                    }
                }
                "openAccessibilitySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Could not open accessibility settings.", null)
                    }
                }
                "openOverlaySettings" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Could not open overlay settings.", null)
                    }
                }
                "openAppDetails" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Could not open app details.", null)
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Could not open battery optimization settings.", null)
                    }
                }
                "getAutoPermissionStatus" -> {
                    val data = mapOf(
                        "notification" to isNotificationAccessEnabled(),
                        "accessibility" to isAccessibilityServiceEnabled(),
                        "overlay" to isOverlayPermissionGranted(),
                        "battery" to isIgnoringBatteryOptimizations()
                    )
                    result.success(data)
                }
                else -> result.notImplemented()
            }
        }
    }

    private val transactionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == "com.jive.app.NEW_TRANSACTION") {
                val source = intent.getStringExtra("source")
                val amount = intent.getStringExtra("amount")
                val rawText = intent.getStringExtra("raw_text")
                val type = intent.getStringExtra("type")
                val metadata = intent.getStringExtra("metadata")
                val timestamp = intent.getLongExtra("timestamp", System.currentTimeMillis())
                val packageName = intent.getStringExtra("package_name")

                Log.i("JiveAuto", "Capture: source=$source amount=$amount type=$type ts=$timestamp")

                val data = mapOf(
                    "source" to source,
                    "amount" to amount,
                    "raw_text" to rawText,
                    "type" to type,
                    "metadata" to metadata,
                    "timestamp" to timestamp,
                    "package_name" to packageName
                )

                sendEvent(data)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter("com.jive.app.NEW_TRANSACTION")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val isDebuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
            val flags = if (isDebuggable) {
                Context.RECEIVER_EXPORTED
            } else {
                Context.RECEIVER_NOT_EXPORTED
            }
            registerReceiver(transactionReceiver, filter, flags)
        } else {
            registerReceiver(transactionReceiver, filter)
        }
        maybeHandleAutoDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        maybeHandleAutoDeepLink(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(transactionReceiver)
    }

    private fun isNotificationAccessEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        ) ?: return false
        return enabled.contains(packageName)
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val serviceId = "${packageName}/${JiveAccessibilityService::class.java.name}"
        return enabled.contains(serviceId)
    }

    private fun isOverlayPermissionGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return true
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }

    private fun maybeHandleAutoDeepLink(intent: Intent?) {
        val uri = intent?.data ?: return
        if (uri.scheme != "jive") return
        val isAuto = uri.host == "auto" || uri.path == "/auto"
        if (!isAuto) return

        val source = uri.getQueryParameter("source") ?: uri.getQueryParameter("app") ?: "Shortcut"
        val amount = uri.getQueryParameter("amount") ?: uri.getQueryParameter("money") ?: "0"
        val rawText =
            uri.getQueryParameter("raw_text")
                ?: uri.getQueryParameter("text")
                ?: uri.getQueryParameter("note")
                ?: ""
        val type = uri.getQueryParameter("type") ?: ""
        val ts = uri.getQueryParameter("timestamp")?.toLongOrNull() ?: System.currentTimeMillis()

        Log.i("JiveAuto", "DeepLink: source=$source amount=$amount type=$type ts=$ts uri=$uri")
        val payload = mapOf(
            "source" to source,
            "amount" to amount,
            "raw_text" to rawText,
            "type" to type,
            "timestamp" to ts
        )
        sendEvent(payload)
    }

    private fun sendEvent(payload: Map<String, Any?>) {
        runOnUiThread {
            val sink = eventSink
            if (sink != null) {
                sink.success(payload)
            } else {
                pendingEvent = payload
            }
        }
    }
}
