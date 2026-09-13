package com.bytemeter.network

import com.bytemeter.network.bridge.ByteMeterPlatformBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

class MainActivity : FlutterActivity() {
    private val activityScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var platformBridge: ByteMeterPlatformBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        platformBridge = ByteMeterPlatformBridge(applicationContext, activityScope).apply {
            register(flutterEngine.dartExecutor.binaryMessenger)
        }
        handleIntent(intent)
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: android.content.Intent?) {
        if (intent?.getBooleanExtra(com.bytemeter.network.services.ByteMeterForegroundService.EXTRA_OPEN_NOTIFICATION_SETTINGS, false) == true) {
            platformBridge?.notifyOpenNotificationSettings()
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        platformBridge?.unregister()
        platformBridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        platformBridge?.unregister()
        platformBridge = null
        activityScope.cancel()
        super.onDestroy()
    }
}
