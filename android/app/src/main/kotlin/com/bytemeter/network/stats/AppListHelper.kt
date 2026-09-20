package com.bytemeter.network.stats

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.util.Log
import androidx.core.content.res.ResourcesCompat
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream

class AppListHelper(private val context: Context) {
    private val packageManager: PackageManager = context.packageManager
    private val iconCache = android.util.LruCache<String, ByteArray>(256)
    private val failedPackages = java.util.Collections.newSetFromMap(java.util.concurrent.ConcurrentHashMap<String, Boolean>())
    private val iconSemaphore = Semaphore(6)

    suspend fun getInstalledApps(): List<Map<String, Any?>> = withContext(Dispatchers.IO) {
        val installedApps = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(0L))
            } else {
                @Suppress("DEPRECATION")
                packageManager.getInstalledApplications(0)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error querying installed applications", e)
            emptyList<ApplicationInfo>()
        }

        val appList = installedApps.map { appInfo ->
            val label = try {
                appInfo.loadLabel(packageManager).toString()
            } catch (e: Exception) {
                appInfo.packageName
            }
            val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

            mapOf(
                "uid" to appInfo.uid,
                "packageName" to appInfo.packageName,
                "label" to label,
                "iconBytes" to null,
                "isSpecial" to false,
                "isSystemApp" to isSystemApp
            )
        }.distinctBy { it["packageName"] }.toMutableList()

        val specialApps = listOf(
            mapOf("uid" to NetworkStatsHelper.UID_ALL, "packageName" to "system.all_apps", "label" to "All Apps", "iconBytes" to null, "isSpecial" to true, "isSystemApp" to true),
            mapOf("uid" to NetworkStatsHelper.UID_TETHERING, "packageName" to "system.tethering", "label" to "Tethering & Hotspot", "iconBytes" to null, "isSpecial" to true, "isSystemApp" to true),
            mapOf("uid" to NetworkStatsHelper.UID_REMOVED, "packageName" to "system.removed_apps", "label" to "Removed Apps", "iconBytes" to null, "isSpecial" to true, "isSystemApp" to true),
            mapOf("uid" to NetworkStatsHelper.UID_OTHER_USERS, "packageName" to "system.other_users", "label" to "Other Users", "iconBytes" to null, "isSpecial" to true, "isSystemApp" to true),
            mapOf("uid" to NetworkStatsHelper.UID_UNKNOWN, "packageName" to "system.unknown", "label" to "Unknown Services", "iconBytes" to null, "isSpecial" to true, "isSystemApp" to true)
        )

        specialApps + appList
    }

    suspend fun getAppInfoByUid(uid: Int): Map<String, Any?> = withContext(Dispatchers.IO) {
        when (uid) {
            NetworkStatsHelper.UID_ALL -> mapOf("uid" to uid, "packageName" to "system.all_apps", "label" to "All Apps", "iconBytes" to null, "isSpecial" to true, "isSystemApp" to true)
            NetworkStatsHelper.UID_TETHERING -> mapOf("uid" to uid, "packageName" to "system.tethering", "label" to "Tethering & Hotspot", "iconBytes" to null, "isSpecial" to true, "isSystemApp" to true)
            NetworkStatsHelper.UID_REMOVED -> mapOf("uid" to uid, "packageName" to "system.removed_apps", "label" to "Removed Apps", "iconBytes" to null, "isSpecial" to true, "isSystemApp" to true)
            NetworkStatsHelper.UID_OTHER_USERS -> mapOf("uid" to uid, "packageName" to "system.other_users", "label" to "Other Users", "iconBytes" to null, "isSpecial" to true, "isSystemApp" to true)
            NetworkStatsHelper.UID_UNKNOWN -> mapOf("uid" to uid, "packageName" to "system.unknown", "label" to "Unknown Services", "iconBytes" to null, "isSpecial" to true, "isSystemApp" to true)
            else -> {
                val packages = try {
                    packageManager.getPackagesForUid(uid)
                } catch (e: Exception) {
                    null
                }
                if (!packages.isNullOrEmpty()) {
                    val pkg = packages[0]
                    val appInfo = try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            packageManager.getApplicationInfo(pkg, PackageManager.ApplicationInfoFlags.of(0L))
                        } else {
                            @Suppress("DEPRECATION")
                            packageManager.getApplicationInfo(pkg, 0)
                        }
                    } catch (e: Exception) {
                        null
                    }
                    val label = appInfo?.loadLabel(packageManager)?.toString() ?: pkg
                    val isSystemApp = appInfo?.let { (it.flags and ApplicationInfo.FLAG_SYSTEM) != 0 } ?: false
                    mapOf(
                        "uid" to uid,
                        "packageName" to pkg,
                        "label" to label,
                        "iconBytes" to null,
                        "isSpecial" to false,
                        "isSystemApp" to isSystemApp
                    )
                } else {
                    mapOf(
                        "uid" to uid,
                        "packageName" to "uid_$uid",
                        "label" to "UID $uid",
                        "iconBytes" to null,
                        "isSpecial" to (uid < 0),
                        "isSystemApp" to (uid < 0)
                    )
                }
            }
        }
    }

    suspend fun getAppIcon(packageName: String): ByteArray? = withContext(Dispatchers.IO) {
        if (packageName.isEmpty() || packageName.startsWith("system.") || packageName.startsWith("uid_")) {
            return@withContext null
        }
        if (failedPackages.contains(packageName)) {
            return@withContext null
        }
        iconCache.get(packageName)?.let { return@withContext it }

        iconSemaphore.withPermit {
            iconCache.get(packageName)?.let { return@withPermit it }

            try {
                val drawable: Drawable = try {
                    packageManager.getApplicationIcon(packageName)
                } catch (_: Exception) {
                    val appInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        packageManager.getApplicationInfo(packageName, PackageManager.ApplicationInfoFlags.of(0L))
                    } else {
                        @Suppress("DEPRECATION")
                        packageManager.getApplicationInfo(packageName, 0)
                    }
                    appInfo.loadIcon(packageManager)
                }

                val bytes = drawableToPngByteArray(drawable)
                if (bytes != null) {
                    iconCache.put(packageName, bytes)
                } else {
                    failedPackages.add(packageName)
                }
                bytes
            } catch (e: Exception) {
                failedPackages.add(packageName)
                null
            }
        }
    }

    fun launchApp(packageName: String): Boolean {
        return try {
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch app $packageName", e)
            false
        }
    }

    private fun drawableToPngByteArray(drawable: Drawable): ByteArray? {
        return try {
            val targetSize = 128
            val bmp = Bitmap.createBitmap(targetSize, targetSize, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)

            val stream = ByteArrayOutputStream()
            bmp.compress(Bitmap.CompressFormat.PNG, 100, stream)
            bmp.recycle()
            stream.toByteArray()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to convert drawable to PNG", e)
            null
        }
    }

    companion object {
        private const val TAG = "AppListHelper"
    }
}
