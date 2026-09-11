package com.bytemeter.network.services

import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.TrafficStats
import android.os.Build
import android.util.Log
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException
import java.util.concurrent.ConcurrentHashMap

class TrafficSnapshotManager(
    private val context: Context,
    dispatcher: CoroutineDispatcher = Dispatchers.IO
) : AutoCloseable {
    private val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    @Volatile private var useFallback: Boolean = TrafficStats.getTotalTxBytes() == TrafficStats.UNSUPPORTED.toLong()
    private val activeInterfaceNames = ConcurrentHashMap<Network, String>()
    val interfaces: Set<String> get() = activeInterfaceNames.values.toSet()
    private val scope: CoroutineScope = CoroutineScope(dispatcher + SupervisorJob())

    private val callback = object : ConnectivityManager.NetworkCallback() {
        override fun onLinkPropertiesChanged(network: Network, linkProperties: LinkProperties) {
            val name = linkProperties.interfaceName
            if (name == null) {
                activeInterfaceNames.remove(network)
            } else {
                activeInterfaceNames[network] = name
            }
        }

        override fun onLost(network: Network) {
            activeInterfaceNames.remove(network)
        }
    }

    init {
        try {
            connectivityManager.allNetworks.forEach { network ->
                connectivityManager.getLinkProperties(network)?.interfaceName?.let { name ->
                    activeInterfaceNames[network] = name
                }
            }
            val request = NetworkRequest.Builder()
                .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                .build()
            connectivityManager.registerNetworkCallback(request, callback)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register network callback", e)
        }
    }

    override fun close() {
        scope.cancel()
        runCatching {
            connectivityManager.unregisterNetworkCallback(callback)
        }.onFailure { Log.e(TAG, "Error unregistering network callback", it) }
    }

    fun setForceFallback(force: Boolean) {
        useFallback = force || TrafficStats.getTotalTxBytes() == TrafficStats.UNSUPPORTED.toLong()
    }

    suspend fun getTrafficSnapshot(): TrafficSnapshot {
        return if (useFallback) {
            try {
                fallbackUpdateSnapshot()
            } catch (e: Exception) {
                when (e) {
                    is IOException, is NumberFormatException, is SecurityException -> {
                        Log.e(TAG, "Fallback IO error, switching to regular update", e)
                        useFallback = false
                        regularUpdateSnapshot()
                    }
                    else -> throw e
                }
            }
        } else {
            regularUpdateSnapshot()
        }
    }

    private suspend fun regularUpdateSnapshot(): TrafficSnapshot = withContext(Dispatchers.IO) {
        val inter = interfaces
        return@withContext if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && inter.isNotEmpty()) {
            TrafficSnapshot(
                up = inter.sumOf { TrafficStats.getTxBytes(it).coerceAtLeast(0L) },
                down = inter.sumOf { TrafficStats.getRxBytes(it).coerceAtLeast(0L) },
                interfaces = inter
            )
        } else {
            TrafficSnapshot(
                up = TrafficStats.getTotalTxBytes().coerceAtLeast(0L),
                down = TrafficStats.getTotalRxBytes().coerceAtLeast(0L),
                interfaces = inter
            )
        }
    }

    private suspend fun fallbackUpdateSnapshot(): TrafficSnapshot = withContext(Dispatchers.IO) {
        val mobileUp = mobileTxFile.readLongOrZero()
        val mobileDown = mobileRxFile.readLongOrZero()
        val wifiUp = wifiTxFile.readLongOrZero() + ethTxFile.readLongOrZero()
        val wifiDown = wifiRxFile.readLongOrZero() + ethRxFile.readLongOrZero()
        return@withContext TrafficSnapshot(
            up = mobileUp + wifiUp,
            down = mobileDown + wifiDown,
            interfaces = interfaces
        )
    }

    private fun File.readLongOrZero(): Long = runCatching {
        if (canRead()) readText().trim().toLong() else 0L
    }.getOrDefault(0L)

    companion object {
        private const val TAG = "TrafficSnapshotManager"
        private val mobileRxFile: File by lazy { File("/sys/class/net/rmnet0/statistics/rx_bytes") }
        private val mobileTxFile: File by lazy { File("/sys/class/net/rmnet0/statistics/tx_bytes") }
        private val wifiRxFile: File by lazy { File("/sys/class/net/wlan0/statistics/rx_bytes") }
        private val wifiTxFile: File by lazy { File("/sys/class/net/wlan0/statistics/tx_bytes") }
        private val ethRxFile: File by lazy { File("/sys/class/net/eth0/statistics/rx_bytes") }
        private val ethTxFile: File by lazy { File("/sys/class/net/eth0/statistics/tx_bytes") }

        suspend fun doesFallbackWork(): Boolean = withContext(Dispatchers.IO) {
            mobileRxFile.canRead() || wifiRxFile.canRead() || ethRxFile.canRead()
        }
    }
}
