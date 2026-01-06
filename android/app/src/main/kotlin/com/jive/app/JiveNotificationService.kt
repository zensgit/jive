package com.jive.app

import android.app.Notification
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import java.util.regex.Pattern

class JiveNotificationService : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        val notification = sbn.notification
        val extras = notification.extras

        // Get title and text content
        val title = extras.getString(Notification.EXTRA_TITLE) ?: "No Title"
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: "No Text"

        Log.d("JiveTracker", "Captured: [$packageName] $title : $text")

        // DEBUG MODE: Broadcast EVERYTHING to Flutter
        // This helps us see what the raw notification text looks like.
        val intent = Intent("com.jive.app.NEW_TRANSACTION")
        intent.putExtra("source", packageName) // Use package name as source
        intent.putExtra("amount", "0.00")      // Placeholder
        intent.putExtra("raw_text", "[$title] $text")
        sendBroadcast(intent)
    }

    // private fun parseAndBroadcast... (Commmented out for debug)
    /*
    private fun parseAndBroadcast(source: String, content: String) {
        // ...
    }
    */
}
