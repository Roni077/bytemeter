package com.bytemeter.network.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.bytemeter.network.MainActivity
import com.bytemeter.network.R
import com.bytemeter.network.bridge.ByteMeterPlatformBridge
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.Locale

class ByteMeterForegroundService : Service() {
    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var tickerJob: Job? = null

    private lateinit var notificationManager: NotificationManager
    private lateinit var trafficSnapshotManager: TrafficSnapshotManager
    private lateinit var notificationIconHelper: NotificationIconHelper

    private var inBits: Boolean = false
    private var separateUpDown: Boolean = false
    private var isMetric1000: Boolean = false
    private var aodMode: Boolean = false
    private var speedThresholdKb: Long = -1L
    private var silentChannelActive: Boolean = false

    private val screenStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_ON -> {
                    startTicker()
                }
                Intent.ACTION_SCREEN_OFF -> {
                    if (!aodMode) {
                        tickerJob?.cancel()
                        tickerJob = null
                    }
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        isRunning = true
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        trafficSnapshotManager = TrafficSnapshotManager(applicationContext)
        notificationIconHelper = NotificationIconHelper(applicationContext)

        createNotificationChannels()

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        ContextCompat.registerReceiver(
            this,
            screenStateReceiver,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED
        )

        val initialNotification = buildNotification(
            speedText = "0",
            unitText = if (inBits) "Kb/s" else "KB/s",
            title = "ByteMeter Active",
            content = "Monitoring network speed..."
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    initialNotification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(NOTIFICATION_ID, initialNotification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start foreground service", e)
        }

        startTicker()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let { handleIntentSettings(it) }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        isRunning = false
        instance = null
        try {
            unregisterReceiver(screenStateReceiver)
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering screen receiver", e)
        }
        tickerJob?.cancel()
        serviceScope.cancel()
        trafficSnapshotManager.close()
        super.onDestroy()
    }

    private fun handleIntentSettings(intent: Intent) {
        if (intent.hasExtra(EXTRA_IN_BITS)) inBits = intent.getBooleanExtra(EXTRA_IN_BITS, inBits)
        if (intent.hasExtra(EXTRA_SEPARATE_UP_DOWN)) separateUpDown = intent.getBooleanExtra(EXTRA_SEPARATE_UP_DOWN, separateUpDown)
        if (intent.hasExtra(EXTRA_METRIC_1000)) isMetric1000 = intent.getBooleanExtra(EXTRA_METRIC_1000, isMetric1000)
        if (intent.hasExtra(EXTRA_AOD_MODE)) aodMode = intent.getBooleanExtra(EXTRA_AOD_MODE, aodMode)
        if (intent.hasExtra(EXTRA_SPEED_THRESHOLD_KB)) speedThresholdKb = intent.getLongExtra(EXTRA_SPEED_THRESHOLD_KB, speedThresholdKb)
        if (intent.hasExtra(EXTRA_FORCE_FALLBACK)) {
            val force = intent.getBooleanExtra(EXTRA_FORCE_FALLBACK, false)
            trafficSnapshotManager.setForceFallback(force)
        }
    }

    fun updateSettings(
        bits: Boolean?,
        separate: Boolean?,
        metric1000: Boolean?,
        aod: Boolean?,
        thresholdKb: Long?,
        forceFallback: Boolean?
    ) {
        bits?.let { inBits = it }
        separate?.let { separateUpDown = it }
        metric1000?.let { isMetric1000 = it }
        aod?.let { aodMode = it }
        thresholdKb?.let { speedThresholdKb = it }
        forceFallback?.let { trafficSnapshotManager.setForceFallback(it) }
    }

    private fun startTicker() {
        if (tickerJob?.isActive == true) return
        tickerJob = serviceScope.launch(Dispatchers.IO) {
            var lastSnapshot = trafficSnapshotManager.getTrafficSnapshot()

            while (true) {
                delay(1000)
                val currentSnapshot = trafficSnapshotManager.getTrafficSnapshot()
                val delta = currentSnapshot - lastSnapshot
                lastSnapshot = currentSnapshot

                ByteMeterPlatformBridge.emitSpeedSnapshot(delta)

                launch(Dispatchers.Main) {
                    updateNotificationWithDelta(delta)
                }
            }
        }
    }

    private suspend fun updateNotificationWithDelta(delta: TrafficSnapshot) {
        val divisor = if (isMetric1000) 1000.0 else 1024.0
        val totalBytes = delta.total
        val totalBits = totalBytes * 8

        val displayValue = if (inBits) totalBits else totalBytes
        val formattedSpeed = formatRate(displayValue, inBits, divisor)
        val speedUpFormatted = formatRate(if (inBits) delta.up * 8 else delta.up, inBits, divisor)
        val speedDownFormatted = formatRate(if (inBits) delta.down * 8 else delta.down, inBits, divisor)

        val speedNum = formattedSpeed.first
        val speedUnit = formattedSpeed.second

        val title = "▲ $speedUpFormatted  ▼ $speedDownFormatted"
        val content = "Active: ${if (delta.interfaces.isEmpty()) "None" else delta.interfaces.joinToString(", ")}"

        val currentTotalKb = totalBytes / 1024
        val isSilent = speedThresholdKb > 0 && currentTotalKb < speedThresholdKb
        silentChannelActive = isSilent

        val smallIcon = if (separateUpDown) {
            val upPart = formatRateCompact(if (inBits) delta.up * 8 else delta.up, inBits, divisor)
            val downPart = formatRateCompact(if (inBits) delta.down * 8 else delta.down, inBits, divisor)
            notificationIconHelper.createIconSeparate(upPart, downPart)
        } else {
            notificationIconHelper.createIcon(speedNum, speedUnit)
        }

        val notification = NotificationCompat.Builder(
            this,
            if (isSilent) CHANNEL_ID_SILENT else CHANNEL_ID_DEFAULT
        )
            .setSmallIcon(smallIcon)
            .setContentTitle(title)
            .setContentText(content)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(createOpenAppPendingIntent())
            .setPriority(if (isSilent) NotificationCompat.PRIORITY_MIN else NotificationCompat.PRIORITY_LOW)
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun buildNotification(
        speedText: String,
        unitText: String,
        title: String,
        content: String
    ): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID_DEFAULT)
            .setSmallIcon(R.drawable.notification)
            .setContentTitle(title)
            .setContentText(content)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(createOpenAppPendingIntent())
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createOpenAppPendingIntent(): PendingIntent {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getActivity(this, 0, launchIntent, flags)
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val defaultChannel = NotificationChannel(
                CHANNEL_ID_DEFAULT,
                "Speed Indicator",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows live upload and download speed in the status bar"
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
                setSound(null, null)
            }

            val silentChannel = NotificationChannel(
                CHANNEL_ID_SILENT,
                "Speed Indicator (Silent)",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "Silent channel when speed is below configured threshold"
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
                setSound(null, null)
            }

            notificationManager.createNotificationChannel(defaultChannel)
            notificationManager.createNotificationChannel(silentChannel)
        }
    }

    private fun formatRate(value: Long, inBits: Boolean, divisor: Double): Pair<String, String> {
        val k = divisor
        val m = k * divisor
        val g = m * divisor

        val unitSuffix = if (inBits) "b/s" else "B/s"

        return when {
            value >= g -> {
                val num = String.format(Locale.US, "%.1f", value / g)
                Pair(num, if (inBits) "Gb/s" else "GB/s")
            }
            value >= m -> {
                val num = String.format(Locale.US, "%.1f", value / m)
                Pair(num, if (inBits) "Mb/s" else "MB/s")
            }
            value >= k -> {
                val num = String.format(Locale.US, "%.0f", value / k)
                Pair(num, if (inBits) "Kb/s" else "KB/s")
            }
            else -> {
                Pair(value.toString(), unitSuffix)
            }
        }
    }

    private fun formatRateCompact(value: Long, inBits: Boolean, divisor: Double): String {
        val (num, unit) = formatRate(value, inBits, divisor)
        val unitLetter = unit.firstOrNull()?.toString() ?: ""
        return "$num$unitLetter"
    }

    companion object {
        private const val TAG = "ByteMeterService"
        const val NOTIFICATION_ID = 1001
        const val CHANNEL_ID_DEFAULT = "bytemeter_speed_channel"
        const val CHANNEL_ID_SILENT = "bytemeter_speed_channel_silent"

        const val EXTRA_IN_BITS = "extra_in_bits"
        const val EXTRA_SEPARATE_UP_DOWN = "extra_separate_up_down"
        const val EXTRA_METRIC_1000 = "extra_metric_1000"
        const val EXTRA_AOD_MODE = "extra_aod_mode"
        const val EXTRA_SPEED_THRESHOLD_KB = "extra_speed_threshold_kb"
        const val EXTRA_FORCE_FALLBACK = "extra_force_fallback"

        @Volatile var isRunning: Boolean = false
            private set

        @Volatile var instance: ByteMeterForegroundService? = null
            private set

        fun start(context: Context) {
            val intent = Intent(context, ByteMeterForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, ByteMeterForegroundService::class.java)
            context.stopService(intent)
        }
    }
}
