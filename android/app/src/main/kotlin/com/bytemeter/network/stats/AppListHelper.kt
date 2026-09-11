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
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream

class AppListHelper(private val context: Context) {
    private val packageManager: PackageManager = context.packageManager

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

        val appList = installedApps.distinctBy { it.uid }.map { appInfo ->
            async {
                val label = try {
                    appInfo.loadLabel(packageManager).toString()
                } catch (e: Exception) {
                    appInfo.packageName
                }

                val iconBytes = try {
                    val drawable = packageManager.getApplicationIcon(appInfo)
                    drawableToPngByteArray(drawable)
                } catch (e: Exception) {
                    null
                }

                mapOf(
                    "uid" to appInfo.uid,
                    "packageName" to appInfo.packageName,
                    "label" to label,
                    "iconBytes" to iconBytes,
                    "isSpecial" to false
                )
            }
        }.awaitAll().toMutableList()

        val specialApps = listOf(
            mapOf("uid" to NetworkStatsHelper.UID_ALL, "packageName" to "system.all_apps", "label" to "All Apps", "iconBytes" to null, "isSpecial" to true),
            mapOf("uid" to NetworkStatsHelper.UID_TETHERING, "packageName" to "system.tethering", "label" to "Tethering & Hotspot", "iconBytes" to null, "isSpecial" to true),
            mapOf("uid" to NetworkStatsHelper.UID_REMOVED, "packageName" to "system.removed_apps", "label" to "Removed Apps", "iconBytes" to null, "isSpecial" to true),
            mapOf("uid" to NetworkStatsHelper.UID_OTHER_USERS, "packageName" to "system.other_users", "label" to "Other Users", "iconBytes" to null, "isSpecial" to true),
            mapOf("uid" to NetworkStatsHelper.UID_UNKNOWN, "packageName" to "system.unknown", "label" to "Unknown Services", "iconBytes" to null, "isSpecial" to true)
        )

        specialApps + appList
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
            val bitmap = when (drawable) {
                is BitmapDrawable -> drawable.bitmap
                else -> {
                    val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
                    val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
                    val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    val canvas = Canvas(bmp)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    bmp
                }
            }
            val scaledBitmap = if (bitmap.width > 96 || bitmap.height > 96) {
                Bitmap.createScaledBitmap(bitmap, 96, 96, true)
            } else {
                bitmap
            }
            val stream = ByteArrayOutputStream()
            scaledBitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
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
