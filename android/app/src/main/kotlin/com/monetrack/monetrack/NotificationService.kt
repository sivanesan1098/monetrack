package com.monetrack.monetrack

import android.content.Context
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
        val packageName = sbn.packageName
        val extras = sbn.notification.extras
        val title = extras.getString("android.title")
        val text = extras.getCharSequence("android.text")?.toString()

        Log.d(TAG, "Notification received from: $packageName, Title: $title, Text: $text")

        if (title != null && text != null) {
            val data = mapOf(
                "package" to packageName,
                "title" to title,
                "text" to text
            )
            
            // Broadcast to UI if alive
            broadcastNotification(data)
            
            // Save to SharedPreferences for Background Service
            saveToPreferences(packageName, title, text)
        }
    }

    private fun saveToPreferences(packageName: String, title: String, text: String) {
        try {
            // Use the default Flutter SharedPreferences file
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val key = "flutter.pending_notifications" // Flutter adds "flutter." prefix to keys
            
            // Read existing list
            val existingSet = prefs.getStringSet(key, null) ?: emptySet()
            val newList = existingSet.toMutableSet()
            
            // Format: package|||title|||text
            // Using a delimiter that is unlikely to be in the text
            val entry = "$packageName|||$title|||$text"
            newList.add(entry)
            
            // Save back
            // Note: StringSet in SharedPreferences has quirks, better to remove and add
            val editor = prefs.edit()
            editor.remove(key)
            editor.putStringSet(key, newList)
            editor.apply()
            
            println("Monetrack: Saved notification to prefs: $title")
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun broadcastNotification(notificationData: Map<String, Any?>) {
        try {
            val intent = Intent(ACTION_NOTIFICATION_RECEIVED)
            notificationData.forEach { (key, value) ->
                when (value) {
                    is String -> intent.putExtra(key, value)
                    // Add other types if needed, e.g., Int, Boolean
                }
            }
            sendBroadcast(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error processing notification", e)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // Ignore
    }
}
