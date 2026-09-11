package com.bytemeter.network.services

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import androidx.core.graphics.createBitmap
import androidx.core.graphics.drawable.IconCompat
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

class NotificationIconHelper(private val context: Context) {
    private val density = context.resources.displayMetrics.density
    private val multiplier = 24f * density / 96f

    private val paintValue by lazy {
        Paint().apply {
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textSize = 72f * multiplier
            color = Color.WHITE
            textAlign = Paint.Align.CENTER
            letterSpacing = -0.02f
            isSubpixelText = true
            isAntiAlias = true
        }
    }

    private val paintUnit by lazy {
        Paint().apply {
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textSize = 46f * multiplier
            color = Color.WHITE
            textAlign = Paint.Align.CENTER
            letterSpacing = -0.02f
            isSubpixelText = true
            isAntiAlias = true
        }
    }

    private val paintSeparate by lazy {
        Paint().apply {
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textSize = 54f * multiplier
            color = Color.WHITE
            textAlign = Paint.Align.RIGHT
            letterSpacing = -0.02f
            isSubpixelText = true
            isAntiAlias = true
        }
    }

    private val height = (96 * multiplier).toInt().coerceAtLeast(1)
    private var bitmap: Bitmap = createBitmap(height, height, Bitmap.Config.ARGB_8888)
    private val bitmapMutex = Mutex()

    suspend fun createIcon(speed: String, unit: String): IconCompat {
        bitmapMutex.withLock {
            if (bitmap.height != height || bitmap.width != height) {
                bitmap = createBitmap(height, height, Bitmap.Config.ARGB_8888)
            } else {
                bitmap.eraseColor(Color.TRANSPARENT)
            }

            val canvas = Canvas(bitmap)
            canvas.drawText(speed, 48f * multiplier, 54f * multiplier, paintValue)
            canvas.drawText(unit, 48f * multiplier, 94f * multiplier, paintUnit)

            return IconCompat.createWithBitmap(bitmap.copy(Bitmap.Config.ARGB_8888, false))
        }
    }

    suspend fun createIconSeparate(speed1: String, speed2: String): IconCompat {
        bitmapMutex.withLock {
            if (bitmap.height != height || bitmap.width != height) {
                bitmap = createBitmap(height, height, Bitmap.Config.ARGB_8888)
            } else {
                bitmap.eraseColor(Color.TRANSPARENT)
            }

            val canvas = Canvas(bitmap)
            val str1 = if (speed1.length >= 5) speed1.replace(" ", "") else speed1
            val str2 = if (speed2.length >= 5) speed2.replace(" ", "") else speed2

            canvas.drawText(str1, 96f * multiplier, 48f * multiplier, paintSeparate)
            canvas.drawText(str2, 96f * multiplier, 96f * multiplier, paintSeparate)

            return IconCompat.createWithBitmap(bitmap.copy(Bitmap.Config.ARGB_8888, false))
        }
    }
}
