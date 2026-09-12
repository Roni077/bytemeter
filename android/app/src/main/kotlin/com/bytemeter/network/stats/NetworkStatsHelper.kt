package com.bytemeter.network.stats

import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.net.ConnectivityManager
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit
import kotlinx.coroutines.withContext

class NetworkStatsHelper(private val context: Context) {
    private val networkStatsManager = context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
    private val binderSemaphore = Semaphore(4)

    suspend fun queryDeviceSummary(
        networkType: Int,
        subscriberId: String?,
        startTime: Long,
        endTime: Long
    ): Map<String, Long> = withContext(Dispatchers.IO) {
        val netType = mapNetworkType(networkType)
        try {
            val bucket = networkStatsManager.querySummaryForDevice(netType, subscriberId, startTime, endTime)
            mapOf(
                "upload" to bucket.txBytes.coerceAtLeast(0L),
                "download" to bucket.rxBytes.coerceAtLeast(0L),
                "total" to (bucket.txBytes + bucket.rxBytes).coerceAtLeast(0L)
            )
        } catch (e: Exception) {
            Log.e(TAG, "querySummaryForDevice error", e)
            mapOf("upload" to 0L, "download" to 0L, "total" to 0L)
        }
    }

    suspend fun queryAppBuckets(
        networkType: Int,
        subscriberId: String?,
        startTime: Long,
        endTime: Long
    ): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        val netType = mapNetworkType(networkType)
        val uidMap = mutableMapOf<Int, Pair<Long, Long>>() // uid -> (upload, download)

        try {
            val summary = networkStatsManager.querySummary(netType, subscriberId, startTime, endTime)
            val bucket = NetworkStats.Bucket()
            while (summary.hasNextBucket()) {
                summary.getNextBucket(bucket)
                val current = uidMap[bucket.uid] ?: Pair(0L, 0L)
                uidMap[bucket.uid] = Pair(
                    current.first + bucket.txBytes.coerceAtLeast(0L),
                    current.second + bucket.rxBytes.coerceAtLeast(0L)
                )
            }
            summary.close()
        } catch (e: Exception) {
            Log.e(TAG, "queryAppBuckets summary error", e)
        }

        val deviceTotal = try {
            val totalBucket = networkStatsManager.querySummaryForDevice(netType, subscriberId, startTime, endTime)
            Pair(totalBucket.txBytes.coerceAtLeast(0L), totalBucket.rxBytes.coerceAtLeast(0L))
        } catch (e: Exception) {
            Log.e(TAG, "queryAppBuckets device total error", e)
            null
        }

        if (deviceTotal != null) {
            val totalUidUpload = uidMap.values.sumOf { it.first }
            val totalUidDownload = uidMap.values.sumOf { it.second }

            val diffUpload = (deviceTotal.first - totalUidUpload).coerceAtLeast(0L)
            val diffDownload = (deviceTotal.second - totalUidDownload).coerceAtLeast(0L)

            if (diffUpload > 0 || diffDownload > 0) {
                val currentOther = uidMap[UID_OTHER_USERS] ?: Pair(0L, 0L)
                uidMap[UID_OTHER_USERS] = Pair(
                    currentOther.first + diffUpload,
                    currentOther.second + diffDownload
                )
            }
        }

        uidMap.map { (uid, usage) ->
            mapOf(
                "uid" to uid,
                "upload" to usage.first,
                "download" to usage.second,
                "total" to (usage.first + usage.second),
                "startTime" to startTime,
                "endTime" to endTime
            )
        }
    }

    suspend fun queryHourlyBuckets(
        networkType: Int,
        subscriberId: String?,
        startTime: Long,
        endTime: Long,
        uid: Int?
    ): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        val netType = mapNetworkType(networkType)
        val result = mutableListOf<Map<String, Any>>()

        if (uid != null && uid != UID_ALL) {
            try {
                val details = networkStatsManager.queryDetailsForUid(netType, subscriberId, startTime, endTime, uid)
                val bucket = NetworkStats.Bucket()
                while (details.hasNextBucket()) {
                    details.getNextBucket(bucket)
                    result.add(
                        mapOf(
                            "uid" to bucket.uid,
                            "upload" to bucket.txBytes.coerceAtLeast(0L),
                            "download" to bucket.rxBytes.coerceAtLeast(0L),
                            "total" to (bucket.txBytes + bucket.rxBytes).coerceAtLeast(0L),
                            "startTime" to bucket.startTimeStamp,
                            "endTime" to bucket.endTimeStamp
                        )
                    )
                }
                details.close()
            } catch (e: Exception) {
                Log.e(TAG, "queryHourlyBuckets for uid error", e)
            }
        } else {
            val twoHoursMs = 2 * 60 * 60 * 1000L
            coroutineScope {
                val slots = (startTime until endTime step twoHoursMs).toList()
                val deferredList = slots.map { slotStart ->
                    val slotEnd = (slotStart + twoHoursMs).coerceAtMost(endTime)
                    async {
                        binderSemaphore.withPermit {
                            try {
                                val bucket = networkStatsManager.querySummaryForDevice(netType, subscriberId, slotStart, slotEnd)
                                mapOf(
                                    "uid" to UID_ALL,
                                    "upload" to bucket.txBytes.coerceAtLeast(0L),
                                    "download" to bucket.rxBytes.coerceAtLeast(0L),
                                    "total" to (bucket.txBytes + bucket.rxBytes).coerceAtLeast(0L),
                                    "startTime" to slotStart,
                                    "endTime" to slotEnd
                                )
                            } catch (e: Exception) {
                                mapOf(
                                    "uid" to UID_ALL,
                                    "upload" to 0L,
                                    "download" to 0L,
                                    "total" to 0L,
                                    "startTime" to slotStart,
                                    "endTime" to slotEnd
                                )
                            }
                        }
                    }
                }
                result.addAll(deferredList.awaitAll())
            }
        }

        result
    }

    suspend fun queryCombinedTimeline(
        subscriberId: String?,
        startTime: Long,
        endTime: Long
    ): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        val oneDayMs = 24 * 60 * 60 * 1000L
        val days = (startTime until endTime step oneDayMs).toList()

        coroutineScope {
            days.map { dayStart ->
                val dayEnd = (dayStart + oneDayMs).coerceAtMost(endTime)
                async {
                    binderSemaphore.withPermit {
                        val mobile = try {
                            val b = networkStatsManager.querySummaryForDevice(
                                ConnectivityManager.TYPE_MOBILE,
                                subscriberId,
                                dayStart,
                                dayEnd
                            )
                            Pair(b.txBytes.coerceAtLeast(0L), b.rxBytes.coerceAtLeast(0L))
                        } catch (e: Exception) {
                            Pair(0L, 0L)
                        }

                        val wifi = try {
                            val b = networkStatsManager.querySummaryForDevice(
                                ConnectivityManager.TYPE_WIFI,
                                null,
                                dayStart,
                                dayEnd
                            )
                            Pair(b.txBytes.coerceAtLeast(0L), b.rxBytes.coerceAtLeast(0L))
                        } catch (e: Exception) {
                            Pair(0L, 0L)
                        }

                        mapOf<String, Any>(
                            "startTime" to dayStart,
                            "endTime" to dayEnd,
                            "cellUpload" to mobile.first,
                            "cellDownload" to mobile.second,
                            "cellTotal" to (mobile.first + mobile.second),
                            "wifiUpload" to wifi.first,
                            "wifiDownload" to wifi.second,
                            "wifiTotal" to (wifi.first + wifi.second)
                        )
                    }
                }
            }.awaitAll()
        }
    }

    private fun mapNetworkType(type: Int): Int {
        return when (type) {
            0 -> ConnectivityManager.TYPE_MOBILE
            1 -> ConnectivityManager.TYPE_WIFI
            else -> ConnectivityManager.TYPE_MOBILE
        }
    }

    companion object {
        private const val TAG = "NetworkStatsHelper"
        const val UID_ALL = -100
        const val UID_UNKNOWN = -99
        const val UID_OTHER_USERS = -98
        const val UID_TETHERING = -5
        const val UID_REMOVED = -4
    }
}
