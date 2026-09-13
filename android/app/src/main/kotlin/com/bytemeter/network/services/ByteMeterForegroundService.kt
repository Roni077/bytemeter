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
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.bytemeter.network.MainActivity
import com.bytemeter.network.R
import com.bytemeter.network.bridge.ByteMeterPlatformBridge
import com.bytemeter.network.stats.NetworkStatsHelper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.Calendar
import java.util.Locale

class ByteMeterForegroundService : Service() {
    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var tickerJob: Job? = null

    private lateinit var notificationManager: NotificationManager
    private lateinit var trafficSnapshotManager: TrafficSnapshotManager
    private lateinit var notificationIconHelper: NotificationIconHelper
    private lateinit var networkStatsHelper: NetworkStatsHelper

    private var inBits: Boolean = false
    private var separateUpDown: Boolean = false
    private var isMetric1000: Boolean = false
    private var aodMode: Boolean = false
    private var speedThresholdKb: Long = -1L
    private var silentChannelActive: Boolean = false

    private lateinit var openAppPendingIntent: PendingIntent
    private lateinit var openSettingsPendingIntent: PendingIntent
    private var todayMobileBytes: Long = 0L
    private var todayWifiBytes: Long = 0L
    private var usageTickCounter: Int = DATA_UPDATE_FREQ

    private var lastTitle: String? = null
    private var lastContent: String? = null
    private var lastIcon: androidx.core.graphics.drawable.IconCompat? = null
    private var lastIsSilent: Boolean? = null
    private var lastDownStr: String? = null
    private var lastUpStr: String? = null
    private var lastMobileStr: String? = null
    private var lastWifiStr: String? = null

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
        networkStatsHelper = NetworkStatsHelper(applicationContext)
        openAppPendingIntent = createOpenAppPendingIntent()
        openSettingsPendingIntent = createOpenSettingsPendingIntent()

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        isMetric1000 = prefs.getBoolean("flutter.metric_base_1000", false)
        inBits = prefs.getBoolean("flutter.speed_unit_bits", false)
        aodMode = prefs.getBoolean("flutter.aod_mode_enabled", false)
        val thresholdVal: Long = try {
            prefs.getLong("flutter.silent_speed_threshold_kb", -1L)
        } catch (_: ClassCastException) {
            try {
                prefs.getInt("flutter.silent_speed_threshold_kb", -1).toLong()
            } catch (_: Exception) {
                -1L
            }
        } catch (_: Exception) {
            -1L
        }
        speedThresholdKb = thresholdVal

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
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
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

        val powerManager = getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
        val isInteractive = powerManager?.isInteractive ?: true
        if (isInteractive || aodMode) {
            startTicker()
        }
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
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        notificationManager.cancel(NOTIFICATION_ID)
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

                if (usageTickCounter >= DATA_UPDATE_FREQ) {
                    updateTodayUsage()
                    usageTickCounter = 0
                } else {
                    usageTickCounter++
                }

                ByteMeterPlatformBridge.emitSpeedSnapshot(delta)

                launch(Dispatchers.Main) {
                    updateNotificationWithDelta(delta)
                }
            }
        }
    }

    private fun getStartOfDayMillis(): Long {
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    private suspend fun updateTodayUsage() {
        try {
            val start = getStartOfDayMillis()
            val end = System.currentTimeMillis()
            val mobileSummary = networkStatsHelper.queryDeviceSummary(
                networkType = android.net.ConnectivityManager.TYPE_MOBILE,
                subscriberId = null,
                startTime = start,
                endTime = end
            )
            val wifiSummary = networkStatsHelper.queryDeviceSummary(
                networkType = android.net.ConnectivityManager.TYPE_WIFI,
                subscriberId = null,
                startTime = start,
                endTime = end
            )
            todayMobileBytes = mobileSummary["total"] ?: 0L
            todayWifiBytes = wifiSummary["total"] ?: 0L
        } catch (e: Exception) {
            Log.e(TAG, "Error querying today network usage for notification", e)
        }
    }

    private fun formatDataSize(bytes: Long, isMetric: Boolean): String {
        val divisor = if (isMetric) 1000.0 else 1024.0
        val k = divisor
        val m = k * divisor
        val g = m * divisor
        val t = g * divisor

        val value = bytes.toDouble()
        return when {
            value >= t -> String.format(Locale.US, "%.1f TB", value / t)
            value >= g -> String.format(Locale.US, "%.1f GB", value / g)
            value >= m -> {
                if (value >= 100 * m) {
                    String.format(Locale.US, "%.0f MB", value / m)
                } else {
                    String.format(Locale.US, "%.1f MB", value / m)
                }
            }
            value >= k -> {
                if (value >= 100 * k) {
                    String.format(Locale.US, "%.0f KB", value / k)
                } else {
                    String.format(Locale.US, "%.1f KB", value / k)
                }
            }
            else -> "$bytes B"
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

        val downStr = "${speedDownFormatted.first} ${speedDownFormatted.second}"
        val upStr = "${speedUpFormatted.first} ${speedUpFormatted.second}"
        val mobileStr = formatDataSize(todayMobileBytes, isMetric1000)
        val wifiStr = formatDataSize(todayWifiBytes, isMetric1000)

        val title = "▲ $upStr  ▼ $downStr"
        val content = "Active: ${if (delta.interfaces.isEmpty()) "None" else delta.interfaces.joinToString(", ")}"

        val currentTotalKb = totalBytes / 1024
        val isSilent = speedThresholdKb > 0 && currentTotalKb < speedThresholdKb
        silentChannelActive = isSilent

        val smallIcon = try {
            if (separateUpDown) {
                val upPart = formatRateCompact(if (inBits) delta.up * 8 else delta.up, inBits, divisor)
                val downPart = formatRateCompact(if (inBits) delta.down * 8 else delta.down, inBits, divisor)
                notificationIconHelper.createIconSeparate(upPart, downPart)
            } else {
                notificationIconHelper.createIcon(speedNum, speedUnit)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error rendering dynamic notification icon, falling back to static icon", e)
            androidx.core.graphics.drawable.IconCompat.createWithResource(this, R.drawable.notification)
        }

        if (title == lastTitle && content == lastContent && smallIcon == lastIcon && isSilent == lastIsSilent &&
            downStr == lastDownStr && upStr == lastUpStr && mobileStr == lastMobileStr && wifiStr == lastWifiStr) {
            return
        }
        lastTitle = title
        lastContent = content
        lastIcon = smallIcon
        lastIsSilent = isSilent
        lastDownStr = downStr
        lastUpStr = upStr
        lastMobileStr = mobileStr
        lastWifiStr = wifiStr

        val expandedViews = RemoteViews(packageName, R.layout.notification_speed_expanded).apply {
            setTextViewText(R.id.tv_down_speed, downStr)
            setTextViewText(R.id.tv_up_speed, upStr)
            setTextViewText(R.id.tv_mobile_usage, mobileStr)
            setTextViewText(R.id.tv_wifi_usage, wifiStr)
            setOnClickPendingIntent(R.id.btn_notification_settings, openSettingsPendingIntent)
        }

        val collapsedViews = RemoteViews(packageName, R.layout.notification_speed_collapsed).apply {
            setTextViewText(R.id.tv_down_speed_collapsed, downStr)
            setTextViewText(R.id.tv_up_speed_collapsed, upStr)
            setTextViewText(R.id.tv_mobile_usage_collapsed, mobileStr)
            setTextViewText(R.id.tv_wifi_usage_collapsed, wifiStr)
        }

        val notification = NotificationCompat.Builder(
            this,
            if (isSilent) CHANNEL_ID_SILENT else CHANNEL_ID_DEFAULT
        )
            .setSmallIcon(smallIcon)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(collapsedViews)
            .setCustomBigContentView(expandedViews)
            .setContentTitle(title)
            .setContentText(content)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(openAppPendingIntent)
            .setPriority(if (isSilent) NotificationCompat.PRIORITY_MIN else NotificationCompat.PRIORITY_LOW)
            .build()

        try {
            notificationManager.notify(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.e(TAG, "Error posting updated notification", e)
        }
    }

    private fun buildNotification(
        speedText: String,
        unitText: String,
        title: String,
        content: String
    ): Notification {
        val initialSpeed = "$speedText $unitText"
        val expandedViews = RemoteViews(packageName, R.layout.notification_speed_expanded).apply {
            setTextViewText(R.id.tv_down_speed, initialSpeed)
            setTextViewText(R.id.tv_up_speed, initialSpeed)
            setTextViewText(R.id.tv_mobile_usage, "0 MB")
            setTextViewText(R.id.tv_wifi_usage, "0 MB")
            setOnClickPendingIntent(R.id.btn_notification_settings, openSettingsPendingIntent)
        }

        val collapsedViews = RemoteViews(packageName, R.layout.notification_speed_collapsed).apply {
            setTextViewText(R.id.tv_down_speed_collapsed, initialSpeed)
            setTextViewText(R.id.tv_up_speed_collapsed, initialSpeed)
            setTextViewText(R.id.tv_mobile_usage_collapsed, "0 MB")
            setTextViewText(R.id.tv_wifi_usage_collapsed, "0 MB")
        }

        return NotificationCompat.Builder(this, CHANNEL_ID_DEFAULT)
            .setSmallIcon(R.drawable.notification)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(collapsedViews)
            .setCustomBigContentView(expandedViews)
            .setContentTitle(title)
            .setContentText(content)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(openAppPendingIntent)
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

    private fun createOpenSettingsPendingIntent(): PendingIntent {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_OPEN_NOTIFICATION_SETTINGS, true)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getActivity(this, 1, launchIntent, flags)
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
        private const val DATA_UPDATE_FREQ = 4

        const val EXTRA_OPEN_NOTIFICATION_SETTINGS = "extra_open_notification_settings"
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
