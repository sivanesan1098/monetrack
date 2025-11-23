package com.monetrack.monetrack

import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class NotificationService : NotificationListenerService() {
    companion object {
        const val TAG = "NotificationService"
        const val ACTION_NOTIFICATION_RECEIVED = "com.monetrack.monetrack.NOTIFICATION_RECEIVED"
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            val packageName = sbn.packageName
            val extras = sbn.notification.extras
            val title = extras.getString("android.title")
            val text = extras.getCharSequence("android.text")?.toString()

            Log.d(TAG, "Notification received from: $packageName, Title: $title, Text: $text")

            if (text != null) {
                val intent = Intent(ACTION_NOTIFICATION_RECEIVED)
                intent.putExtra("package", packageName)
                intent.putExtra("title", title)
                intent.putExtra("text", text)
                intent.setPackage(this.packageName) // Restrict to our app
                sendBroadcast(intent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing notification", e)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // Ignore
    }
}
