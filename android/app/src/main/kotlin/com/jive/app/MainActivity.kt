package com.jive.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
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
            if (call.method == "openNotificationSettings") {
                try {
                    val intent = Intent(android.provider.Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "Could not open settings.", null)
                }
            } else {
                result.notImplemented()
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
