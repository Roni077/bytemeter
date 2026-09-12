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

    // Double-buffered ping-pong bitmaps & canvases to eliminate 1-Hz allocations
    private val bitmapA: Bitmap = createBitmap(height, height, Bitmap.Config.ARGB_8888)
    private val bitmapB: Bitmap = createBitmap(height, height, Bitmap.Config.ARGB_8888)
    private val canvasA: Canvas = Canvas(bitmapA)
    private val canvasB: Canvas = Canvas(bitmapB)
    private var useBufferA: Boolean = true

    private var lastSpeed: String? = null
    private var lastUnit: String? = null
    private var cachedIcon: IconCompat? = null

    private var lastSpeed1: String? = null
    private var lastSpeed2: String? = null
    private var cachedSeparateIcon: IconCompat? = null

    private val bitmapMutex = Mutex()

    suspend fun createIcon(speed: String, unit: String): IconCompat {
        bitmapMutex.withLock {
            if (speed == lastSpeed && unit == lastUnit && cachedIcon != null) {
                return cachedIcon!!
            }

            val targetBitmap = if (useBufferA) bitmapA else bitmapB
            val targetCanvas = if (useBufferA) canvasA else canvasB
            useBufferA = !useBufferA

            targetBitmap.eraseColor(Color.TRANSPARENT)
            targetCanvas.drawText(speed, 48f * multiplier, 54f * multiplier, paintValue)
            targetCanvas.drawText(unit, 48f * multiplier, 94f * multiplier, paintUnit)

            val icon = IconCompat.createWithBitmap(targetBitmap)
            lastSpeed = speed
            lastUnit = unit
            cachedIcon = icon
            return icon
        }
    }

    suspend fun createIconSeparate(speed1: String, speed2: String): IconCompat {
        bitmapMutex.withLock {
            if (speed1 == lastSpeed1 && speed2 == lastSpeed2 && cachedSeparateIcon != null) {
                return cachedSeparateIcon!!
            }

            val targetBitmap = if (useBufferA) bitmapA else bitmapB
            val targetCanvas = if (useBufferA) canvasA else canvasB
            useBufferA = !useBufferA

            targetBitmap.eraseColor(Color.TRANSPARENT)
            val str1 = if (speed1.length >= 5) speed1.replace(" ", "") else speed1
            val str2 = if (speed2.length >= 5) speed2.replace(" ", "") else speed2

            targetCanvas.drawText(str1, 96f * multiplier, 48f * multiplier, paintSeparate)
            targetCanvas.drawText(str2, 96f * multiplier, 96f * multiplier, paintSeparate)

            val icon = IconCompat.createWithBitmap(targetBitmap)
            lastSpeed1 = speed1
            lastSpeed2 = speed2
            cachedSeparateIcon = icon
            return icon
        }
    }
}
