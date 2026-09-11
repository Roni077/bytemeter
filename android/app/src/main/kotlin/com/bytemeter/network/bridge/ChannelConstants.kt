package com.bytemeter.network.bridge

object ChannelConstants {
    const val METHOD_CHANNEL_NAME = "com.bytemeter/bridge"
    const val EVENT_CHANNEL_NAME = "com.bytemeter/speed_stream"

    // Permission Methods
    const val HAS_USAGE_PERMISSION = "hasUsagePermission"
    const val REQUEST_USAGE_PERMISSION = "requestUsagePermission"
    const val IS_IGNORING_BATTERY_OPTIMIZATIONS = "isIgnoringBatteryOptimizations"
    const val REQUEST_IGNORE_BATTERY_OPTIMIZATIONS = "requestIgnoreBatteryOptimizations"

    // Service Lifecycle & Configuration
    const val START_FOREGROUND_SERVICE = "startForegroundService"
    const val STOP_FOREGROUND_SERVICE = "stopForegroundService"
    const val IS_SERVICE_RUNNING = "isServiceRunning"
    const val UPDATE_SERVICE_SETTINGS = "updateServiceSettings"

    // Network Statistics Queries
    const val QUERY_DEVICE_SUMMARY = "queryDeviceSummary"
    const val QUERY_APP_BUCKETS = "queryAppBuckets"
    const val QUERY_HOURLY_BUCKETS = "queryHourlyBuckets"

    // App List & Launcher
    const val GET_INSTALLED_APPS = "getInstalledApps"
    const val LAUNCH_APP = "launchApp"

    // Hardware Keystore Crypto
    const val ENCRYPT_SUBSCRIBER_ID = "encryptSubscriberId"
    const val DECRYPT_SUBSCRIBER_ID = "decryptSubscriberId"
    const val HASH_SUBSCRIBER_ID = "hashSubscriberId"
}
