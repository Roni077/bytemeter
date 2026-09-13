package com.bytemeter.network.bridge

import android.Manifest
import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.bytemeter.network.crypto.CryptoManager
import com.bytemeter.network.services.ByteMeterForegroundService
import com.bytemeter.network.services.TrafficSnapshot
import com.bytemeter.network.stats.AppListHelper
import com.bytemeter.network.stats.NetworkStatsHelper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class ByteMeterPlatformBridge(
    private val context: Context,
    private val scope: CoroutineScope
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val networkStatsHelper = NetworkStatsHelper(context)
    private val appListHelper = AppListHelper(context)
    private val mainHandler = Handler(Looper.getMainLooper())
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null

    fun register(messenger: BinaryMessenger) {
        val channel = MethodChannel(messenger, ChannelConstants.METHOD_CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        methodChannel = channel

        val events = EventChannel(messenger, ChannelConstants.EVENT_CHANNEL_NAME)
        events.setStreamHandler(this)
        eventChannel = events
    }

    fun unregister() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        clearActiveSink()
    }

    fun notifyOpenNotificationSettings() {
        mainHandler.post {
            methodChannel?.invokeMethod("openNotificationSettings", null)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            ChannelConstants.HAS_USAGE_PERMISSION -> {
                result.success(hasUsagePermission())
            }
            ChannelConstants.REQUEST_USAGE_PERMISSION -> {
                requestUsagePermission()
                result.success(true)
            }
            ChannelConstants.IS_IGNORING_BATTERY_OPTIMIZATIONS -> {
                result.success(isIgnoringBatteryOptimizations())
            }
            ChannelConstants.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS -> {
                requestIgnoreBatteryOptimizations()
                result.success(true)
            }
            ChannelConstants.HAS_NOTIFICATION_PERMISSION -> {
                result.success(hasNotificationPermission())
            }
            ChannelConstants.REQUEST_NOTIFICATION_PERMISSION -> {
                requestNotificationPermission()
                result.success(true)
            }
            ChannelConstants.HAS_PHONE_PERMISSION -> {
                result.success(hasPhonePermission())
            }
            ChannelConstants.REQUEST_PHONE_PERMISSION -> {
                requestPhonePermission()
                result.success(true)
            }
            ChannelConstants.START_FOREGROUND_SERVICE -> {
                ByteMeterForegroundService.start(context)
                result.success(true)
            }
            ChannelConstants.STOP_FOREGROUND_SERVICE -> {
                ByteMeterForegroundService.stop(context)
                result.success(true)
            }
            ChannelConstants.IS_SERVICE_RUNNING -> {
                result.success(ByteMeterForegroundService.isRunning)
            }
            ChannelConstants.UPDATE_SERVICE_SETTINGS -> {
                val inBits = call.argument<Boolean>("inBits")
                val separateUpDown = call.argument<Boolean>("separateUpDown")
                val metric1000 = call.argument<Boolean>("metric1000")
                val aodMode = call.argument<Boolean>("aodMode")
                val speedThresholdKb = call.argument<Number>("speedThresholdKb")?.toLong()
                val forceFallback = call.argument<Boolean>("forceFallback")

                ByteMeterForegroundService.instance?.updateSettings(
                    bits = inBits,
                    separate = separateUpDown,
                    metric1000 = metric1000,
                    aod = aodMode,
                    thresholdKb = speedThresholdKb,
                    forceFallback = forceFallback
                )
                result.success(true)
            }
            ChannelConstants.QUERY_DEVICE_SUMMARY -> {
                val networkType = call.argument<Int>("networkType") ?: 0
                val subscriberId = call.argument<String>("subscriberId")
                val startTime = call.argument<Number>("startTime")?.toLong() ?: 0L
                val endTime = call.argument<Number>("endTime")?.toLong() ?: System.currentTimeMillis()

                scope.launch {
                    val summary = networkStatsHelper.queryDeviceSummary(networkType, subscriberId, startTime, endTime)
                    withContext(Dispatchers.Main) {
                        result.success(summary)
                    }
                }
            }
            ChannelConstants.QUERY_APP_BUCKETS -> {
                val networkType = call.argument<Int>("networkType") ?: 0
                val subscriberId = call.argument<String>("subscriberId")
                val startTime = call.argument<Number>("startTime")?.toLong() ?: 0L
                val endTime = call.argument<Number>("endTime")?.toLong() ?: System.currentTimeMillis()

                scope.launch {
                    val buckets = networkStatsHelper.queryAppBuckets(networkType, subscriberId, startTime, endTime)
                    withContext(Dispatchers.Main) {
                        result.success(buckets)
                    }
                }
            }
            ChannelConstants.QUERY_HOURLY_BUCKETS -> {
                val networkType = call.argument<Int>("networkType") ?: 0
                val subscriberId = call.argument<String>("subscriberId")
                val startTime = call.argument<Number>("startTime")?.toLong() ?: 0L
                val endTime = call.argument<Number>("endTime")?.toLong() ?: System.currentTimeMillis()
                val uid = call.argument<Int>("uid")

                scope.launch {
                    val hourly = networkStatsHelper.queryHourlyBuckets(networkType, subscriberId, startTime, endTime, uid)
                    withContext(Dispatchers.Main) {
                        result.success(hourly)
                    }
                }
            }
            ChannelConstants.GET_INSTALLED_APPS -> {
                scope.launch {
                    val apps = appListHelper.getInstalledApps()
                    withContext(Dispatchers.Main) {
                        result.success(apps)
                    }
                }
            }
            ChannelConstants.GET_APP_ICON -> {
                val packageName = call.argument<String>("packageName") ?: ""
                scope.launch {
                    val iconBytes = appListHelper.getAppIcon(packageName)
                    withContext(Dispatchers.Main) {
                        result.success(iconBytes)
                    }
                }
            }
            ChannelConstants.QUERY_COMBINED_TIMELINE -> {
                val subscriberId = call.argument<String>("subscriberId")
                val startTime = call.argument<Number>("startTime")?.toLong() ?: 0L
                val endTime = call.argument<Number>("endTime")?.toLong() ?: System.currentTimeMillis()

                scope.launch {
                    val timeline = networkStatsHelper.queryCombinedTimeline(subscriberId, startTime, endTime)
                    withContext(Dispatchers.Main) {
                        result.success(timeline)
                    }
                }
            }
            ChannelConstants.LAUNCH_APP -> {
                val packageName = call.argument<String>("packageName") ?: ""
                val launched = appListHelper.launchApp(packageName)
                result.success(launched)
            }
            ChannelConstants.ENCRYPT_SUBSCRIBER_ID -> {
                val id = call.argument<String>("id") ?: ""
                scope.launch {
                    try {
                        val encrypted = CryptoManager.encrypt(id)
                        withContext(Dispatchers.Main) {
                            result.success(encrypted)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("CRYPTO_ERROR", e.message, null)
                        }
                    }
                }
            }
            ChannelConstants.DECRYPT_SUBSCRIBER_ID -> {
                val encrypted = call.argument<String>("encrypted") ?: ""
                scope.launch {
                    try {
                        val decrypted = CryptoManager.decrypt(encrypted)
                        withContext(Dispatchers.Main) {
                            result.success(decrypted)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("CRYPTO_ERROR", e.message, null)
                        }
                    }
                }
            }
            ChannelConstants.HASH_SUBSCRIBER_ID -> {
                val id = call.argument<String>("id") ?: ""
                scope.launch {
                    try {
                        val hash = CryptoManager.hashIdentifier(id)
                        withContext(Dispatchers.Main) {
                            result.success(hash)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("CRYPTO_ERROR", e.message, null)
                        }
                    }
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        activeEventSink = events
    }

    override fun onCancel(arguments: Any?) {
        activeEventSink = null
    }

    private fun hasUsagePermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsagePermission() {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open usage access settings", e)
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            powerManager.isIgnoringBatteryOptimizations(context.packageName)
        } else {
            true
        }
    }

    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to request ignore battery optimizations", e)
            }
        }
    }

    private fun hasNotificationPermission(): Boolean {
        return NotificationManagerCompat.from(context).areNotificationsEnabled()
    }

    private fun requestNotificationPermission() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                    putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
            } else {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.fromParts("package", context.packageName, null)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open notification settings", e)
        }
    }

    private fun hasPhonePermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_PHONE_STATE
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestPhonePermission() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", context.packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open application details settings", e)
        }
    }

    companion object {
        private const val TAG = "ByteMeterPlatformBridge"
        @Volatile private var activeEventSink: EventChannel.EventSink? = null
        private val mainHandler = Handler(Looper.getMainLooper())

        fun clearActiveSink() {
            activeEventSink = null
        }

        fun emitSpeedSnapshot(snapshot: TrafficSnapshot) {
            if (activeEventSink == null) return
            val payload = snapshot.toMap()
            mainHandler.post {
                try {
                    val sink = activeEventSink ?: return@post
                    sink.success(payload)
                } catch (e: Exception) {
                    Log.e(TAG, "Error emitting speed snapshot to EventChannel", e)
                }
            }
        }
    }
}
