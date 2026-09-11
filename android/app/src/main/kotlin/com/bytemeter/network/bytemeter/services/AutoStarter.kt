package com.bytemeter.network.bytemeter.services

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AutoStarter : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.i(TAG, "Received broadcast action: $action")
        if (action == Intent.ACTION_BOOT_COMPLETED || action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            try {
                ByteMeterForegroundService.start(context)
                Log.i(TAG, "ByteMeterForegroundService auto-started successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to auto-start ByteMeterForegroundService on boot", e)
            }
        }
    }

    companion object {
        private const val TAG = "AutoStarter"
    }
}
