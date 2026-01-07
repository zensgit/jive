package com.jive.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.jive.app/stream"
    private val METHOD_CHANNEL = "com.jive.app/methods" // New channel for methods
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Setup EventChannel (Stream)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )

        // 2. Setup MethodChannel (Function Calls)
        io.flutter.plugin.common.MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            fun openSettings(intent: Intent) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                val resolved = intent.resolveActivity(packageManager)
                if (resolved == null) {
                    result.error("UNAVAILABLE", "Settings screen not available.", null)
                    return
                }
                startActivity(intent)
                result.success(true)
            }

            fun startIfResolvable(intent: Intent): Boolean {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                val resolved = intent.resolveActivity(packageManager)
                if (resolved == null) return false
                startActivity(intent)
                return true
            }

            fun openVendorPermissionSettings(): Boolean {
                val manufacturer = (Build.MANUFACTURER ?: "").lowercase()
                val brand = (Build.BRAND ?: "").lowercase()
                val target = "$manufacturer $brand"
                val pkg = packageName

                val intents = mutableListOf<Intent>()

                if (target.contains("xiaomi") || target.contains("redmi")) {
                    intents.add(
                        Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                            setClassName(
                                "com.miui.securitycenter",
                                "com.miui.permcenter.permissions.PermissionsEditorActivity"
                            )
                            putExtra("extra_pkgname", pkg)
                        }
                    )
                    intents.add(
                        Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                            setClassName(
                                "com.miui.securitycenter",
                                "com.miui.permcenter.permissions.AppPermissionsEditorActivity"
                            )
                            putExtra("extra_pkgname", pkg)
                        }
                    )
                } else if (target.contains("oppo") || target.contains("realme") || target.contains("oneplus")) {
                    intents.add(
                        Intent().apply {
                            setClassName(
                                "com.coloros.safecenter",
                                "com.coloros.safecenter.permission.PermissionManagerActivity"
                            )
                            putExtra("packageName", pkg)
                        }
                    )
                    intents.add(
                        Intent().apply {
                            setClassName(
                                "com.coloros.safecenter",
                                "com.coloros.safecenter.permission.singlepage.PermissionSinglePageActivity"
                            )
                            putExtra("packageName", pkg)
                        }
                    )
                    intents.add(
                        Intent().apply {
                            setClassName(
                                "com.oppo.safe",
                                "com.oppo.safe.permission.PermissionAppListActivity"
                            )
                            putExtra("packageName", pkg)
                        }
                    )
                } else if (target.contains("vivo") || target.contains("iqoo")) {
                    intents.add(
                        Intent().apply {
                            setClassName(
                                "com.vivo.permissionmanager",
                                "com.vivo.permissionmanager.activity.SoftPermissionDetailActivity"
                            )
                            putExtra("packagename", pkg)
                        }
                    )
                    intents.add(
                        Intent().apply {
                            setClassName(
                                "com.vivo.permissionmanager",
                                "com.vivo.permissionmanager.activity.PermissionManagerActivity"
                            )
                            putExtra("packagename", pkg)
                        }
                    )
                    intents.add(
                        Intent().apply {
                            setClassName(
                                "com.iqoo.secure",
                                "com.iqoo.secure.ui.phoneoptimize.SoftwareManagerActivity"
                            )
                        }
                    )
                } else {
                    return false
                }

                for (intent in intents) {
                    if (startIfResolvable(intent)) return true
                }
                return false
            }

            try {
                when (call.method) {
                    "openNotificationSettings" -> {
                        openSettings(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    }
                    "openAccessibilitySettings" -> {
                        openSettings(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    }
                    "openOverlaySettings" -> {
                        val uri = Uri.fromParts("package", packageName, null)
                        openSettings(
                            Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                uri
                            ).putExtra("packageName", packageName)
                        )
                    }
                    "openAppDetailsSettings" -> {
                        val uri = Uri.fromParts("package", packageName, null)
                        openSettings(
                            Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                uri
                            ).putExtra("packageName", packageName)
                        )
                    }
                    "openVendorSettings" -> {
                        result.success(openVendorPermissionSettings())
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("UNAVAILABLE", "Could not open settings.", null)
            }
        }
    }

    private val transactionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == "com.jive.app.NEW_TRANSACTION") {
                val source = intent.getStringExtra("source")
                val amount = intent.getStringExtra("amount")
                val rawText = intent.getStringExtra("raw_text")

                val data = mapOf(
                    "source" to source,
                    "amount" to amount,
                    "raw_text" to rawText,
                    "timestamp" to System.currentTimeMillis()
                )
                
                // Send to Flutter
                runOnUiThread {
                    eventSink?.success(data)
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter("com.jive.app.NEW_TRANSACTION")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            registerReceiver(transactionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(transactionReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(transactionReceiver)
    }
}
