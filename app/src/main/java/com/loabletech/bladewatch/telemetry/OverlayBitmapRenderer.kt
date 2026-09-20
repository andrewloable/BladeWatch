package net.bladewatch.app.telemetry

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Typeface
import net.bladewatch.app.logging.DaemonLogger
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Telemetry overlay renderer: solid PNG icons tinted via alpha extraction, dark semi-transparent
 * background, white text, coloured icons.
 *
 * Performance: every geometry object (Rect, RectF, Date) and every ColorFilter is pre-allocated
 * and reused across frames. This runs per recorded frame, so an allocation here is GC pressure
 * on the recording path.
 */
class OverlayBitmapRenderer {

    private val logger: DaemonLogger = DaemonLogger.getInstance("OverlayRenderer")
    private val doubleBuffer = OverlayDoubleBuffer(WIDTH, HEIGHT)

    private val bgPaint = mp(Color.argb(160, 0, 0, 0), Paint.Style.FILL, 0f)
    private val speedPaint = mp(Color.WHITE, Paint.Style.FILL, 48f)
    private val unitPaint = mp(0xFFCCCCCC.toInt(), Paint.Style.FILL, 18f)
    private val gearPaint = mp(Color.WHITE, Paint.Style.FILL, 48f)
    private val iconPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
    private val labelPaint = mp(0xFFCCCCCC.toInt(), Paint.Style.FILL, 13f)
    private val timePaint = mp(Color.WHITE, Paint.Style.FILL, 20f)
    private val gpsPaint = mp(Color.WHITE, Paint.Style.FILL, 15f)

    private val dateFmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)
    private val timeFmt = SimpleDateFormat("HH:mm:ss", Locale.US)

    // Pre-extracted alpha masks (solid icons -> clean stencils)
    private var alphaPedal: Bitmap? = null
    private var alphaLeft: Bitmap? = null
    private var alphaRight: Bitmap? = null
    private var alphaBelt: Bitmap? = null

    // Pre-allocated geometry — reused every frame to avoid GC pressure.
    private val bgRect = RectF()
    private val iconSrcRect = Rect()
    private val iconDstRect = RectF()
    private val reusableDate = Date()

    // Cached filters keyed by colour: avoids an allocation per icon per frame.
    private val colorFilterCache = HashMap<Int, PorterDuffColorFilter>()

    init {
        // Typeface initialisation can fail in daemon mode on automotive BSPs where the font
        // system is not fully initialised (no Activity context). Typeface.create() may return
        // null on DiLink 5, and setTypeface() then NPEs reading the internal mStyle field.
        // Fall back to the default paints — no custom fonts beats crashing.
        try {
            Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)?.let {
                speedPaint.typeface = it
                speedPaint.setShadowLayer(4f, 0f, 0f, 0xAAFFFFFF.toInt())
            }
            Typeface.DEFAULT_BOLD?.let {
                gearPaint.typeface = it
                gearPaint.setShadowLayer(6f, 0f, 0f, 0xAAFFFFFF.toInt())
                labelPaint.typeface = it
            }
            Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)?.let { timePaint.typeface = it }
            logger.info("Font init OK")
        } catch (t: Throwable) {
            // Throwable, not Exception: native font init raises Errors too.
            logger.warn("Font init failed (will use defaults): " + t.message)
        }

        loadIcons()
    }

    private fun mp(color: Int, style: Paint.Style, ts: Float): Paint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            setColor(color)
            setStyle(style)
            if (ts > 0) textSize = ts
        }

    private fun loadIcons() {
        alphaPedal = loadAlpha("pedal.png")
        alphaLeft = loadAlpha("left-arrow.png")
        alphaRight = loadAlpha("right-arrow.png")
        alphaBelt = loadAlpha("seat-belt.png")
        logger.info(
            "Overlay icons: pedal=" + (alphaPedal != null) +
                " left=" + (alphaLeft != null) + " right=" + (alphaRight != null) +
                " belt=" + (alphaBelt != null)
        )
    }

    private fun loadAlpha(name: String): Bitmap? {
        try {
            val f = File(ICON_DIR + name)
            if (f.exists()) {
                val src = BitmapFactory.decodeFile(f.absolutePath)
                if (src != null) {
                    val alpha = src.extractAlpha()
                    src.recycle()
                    return alpha
                }
            }
            logger.warn("Icon not found: $name")
        } catch (e: Exception) {
            logger.warn("Icon load failed: $name " + e.message)
        }
        return null
    }

    /**
     * BladeWatch-y78o.5: [enabledFields] gates the main bar's content, field by field.
     *
     * Each field still occupies its ORIGINAL fixed layout slot whether drawn or not — `x`
     * advances by the same amount either way — so deselecting one field leaves every other
     * field exactly where it already was, rather than reflowing to fill the gap. An empty
     * [enabledFields] skips the main bar and its background entirely: no empty box.
     *
     * GPS lat/lon below is drawn through its own unconditional path, untouched by
     * [enabledFields] — see [OverlayField]'s doc comment for why.
     */
    fun renderFrame(snap: TelemetrySnapshot, fc: Int, enabledFields: Set<OverlayField>): Boolean {
        return try {
            val bmp = doubleBuffer.getBackForWriting()
            val c = Canvas(bmp!!)
            c.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)

            val blink = (fc / 3) % 2 == 0
            val barL = 200f
            val barR = 1080f
            val iy = ((HEIGHT - ICON_SIZE) / 2).toFloat()

            if (enabledFields.isNotEmpty()) {
                bgRect.set(barL, 2f, barR, 78f)
                c.drawRoundRect(bgRect, 14f, 14f, bgPaint)

                // LEFT TURN — fixed at the left edge of the bar
                if (enabledFields.contains(OverlayField.TURN_SIGNAL_LEFT)) {
                    drawIcon(
                        c, alphaLeft, barL + 10, iy,
                        if (snap.leftTurnSignal && blink) 0xFFFF8800.toInt() else 0xFF555555.toInt()
                    )
                }

                // RIGHT TURN — fixed at the right edge of the bar
                if (enabledFields.contains(OverlayField.TURN_SIGNAL_RIGHT)) {
                    drawIcon(
                        c, alphaRight, barR - ICON_SIZE - 10, iy,
                        if (snap.rightTurnSignal && blink) 0xFFFF8800.toInt() else 0xFF555555.toInt()
                    )
                }

                // Speed in the user's unit. snap.speedKmh is the canonical km/h value;
                // BydDataCollector.isMilesMode reflects the vehicle/user setting.
                var milesMode = false
                try {
                    val collector = net.bladewatch.app.byd.BydDataCollector.getInstance()
                    milesMode = collector != null && collector.isMilesMode
                } catch (ignored: Throwable) {
                    logger.debug("BydDataCollector.isMilesMode unavailable, using km/h")
                }
                val spd = if (milesMode) {
                    Math.round(snap.speedKmh * KM_TO_MI).toInt().toString()
                } else {
                    snap.speedKmh.toString()
                }
                val spdUnit = if (milesMode) "mph" else "km/h"

                val spdW = speedPaint.measureText(spd) + 4 + unitPaint.measureText(spdUnit)
                val gearW = 44f
                val brakeW = (ICON_SIZE + 8).toFloat()
                val accelW = (ICON_SIZE + 10).toFloat()
                val belt1W = (ICON_SIZE + 4).toFloat()
                val belt2W = (ICON_SIZE + 10).toFloat()
                val timeW = 100f
                val totalW = spdW + 8 + gearW + 8 + brakeW + accelW + belt1W + belt2W + timeW

                // Centre the content between the arrows. The layout formula — and hence every
                // field's fixed position — is unconditional: it does not depend on which fields
                // are enabled, exactly like the arrows and background above.
                val innerL = barL + ICON_SIZE + 24
                val innerR = barR - ICON_SIZE - 24
                var x = innerL + ((innerR - innerL) - totalW) / 2

                if (enabledFields.contains(OverlayField.SPEED)) {
                    c.drawText(spd, x, 54f, speedPaint)
                    c.drawText(spdUnit, x + speedPaint.measureText(spd) + 4, 54f, unitPaint)
                }
                x += spdW + 8

                if (enabledFields.contains(OverlayField.GEAR)) {
                    gearPaint.color = getGearColorForDarkBg(snap.gearMode)
                    c.drawText(snap.getGearChar().toString(), x, 54f, gearPaint)
                }
                x += gearW + 8

                if (enabledFields.contains(OverlayField.BRAKE_PEDAL)) {
                    val brakeCol =
                        if (snap.brakePedalPercent > 5) 0xFFFF2222.toInt() else 0xFF888888.toInt()
                    drawIcon(c, alphaPedal, x, iy, brakeCol)
                    labelPaint.color = brakeCol
                    val brkTxt =
                        if (snap.brakePedalPercent > 5) "B " + snap.brakePedalPercent + "%" else "B"
                    c.drawText(brkTxt, x, iy + ICON_SIZE + 14, labelPaint)
                }
                x += brakeW

                if (enabledFields.contains(OverlayField.ACCEL_PEDAL)) {
                    val accelCol =
                        if (snap.accelPedalPercent > 5) 0xFF22DD22.toInt() else 0xFF888888.toInt()
                    drawIcon(c, alphaPedal, x, iy, accelCol)
                    labelPaint.color = accelCol
                    val accTxt =
                        if (snap.accelPedalPercent > 5) "A " + snap.accelPedalPercent + "%" else "A"
                    c.drawText(accTxt, x, iy + ICON_SIZE + 14, labelPaint)
                }
                x += accelW

                if (enabledFields.contains(OverlayField.SEATBELT_DRIVER)) {
                    val dB = snap.seatbeltBuckled.isNotEmpty() && snap.seatbeltBuckled[0]
                    val dCol = if (dB) 0xFF22DD22.toInt()
                    else if (blink) 0xFFFF2222.toInt() else 0xFF552222.toInt()
                    drawIcon(c, alphaBelt, x, iy, dCol)
                    labelPaint.color = if (dB) 0xFF22DD22.toInt() else 0xFFFF2222.toInt()
                    c.drawText("D", x + ICON_SIZE / 2 - 4, iy + ICON_SIZE + 14, labelPaint)
                }
                x += belt1W

                if (enabledFields.contains(OverlayField.SEATBELT_PASSENGER)) {
                    val pB = snap.seatbeltBuckled.size > 1 && snap.seatbeltBuckled[1]
                    val pCol = if (pB) 0xFF22DD22.toInt()
                    else if (blink) 0xFFFF2222.toInt() else 0xFF552222.toInt()
                    drawIcon(c, alphaBelt, x, iy, pCol)
                    labelPaint.color = if (pB) 0xFF22DD22.toInt() else 0xFFFF2222.toInt()
                    c.drawText("P", x + ICON_SIZE / 2 - 3, iy + ICON_SIZE + 14, labelPaint)
                }
                x += belt2W

                if (enabledFields.contains(OverlayField.TIMESTAMP)) {
                    reusableDate.time = snap.timestampMs
                    timePaint.textSize = 16f
                    c.drawText(dateFmt.format(reusableDate), x, 34f, timePaint)
                    timePaint.textSize = 20f
                    c.drawText(timeFmt.format(reusableDate), x, 60f, timePaint)
                }
            }

            // GPS coordinates, burned into the footage in the empty region right of the main bar
            // (x 1080-1280). Omitted without a fix so a misleading 0,0 is never shown.
            //
            // BladeWatch-y78o.5: deliberately NOT gated by enabledFields — see OverlayField's
            // doc comment. Unconditional, exactly as before that issue.
            if (snap.hasGps) {
                val gx = barR + 8
                bgRect.set(gx - 6, 2f, WIDTH - 2f, 78f)
                c.drawRoundRect(bgRect, 12f, 12f, bgPaint)
                c.drawText("LAT " + String.format(Locale.US, "%.5f", snap.latitude), gx, 34f, gpsPaint)
                c.drawText("LON " + String.format(Locale.US, "%.5f", snap.longitude), gx, 60f, gpsPaint)
            }

            doubleBuffer.markBackReady()
            true
        } catch (e: Exception) {
            logger.error("Overlay render error", e)
            false
        }
    }

    /** Gear colours for a dark background — bright and readable. */
    private fun getGearColorForDarkBg(gearMode: Int): Int = when (gearMode) {
        1 -> 0xFFAAAAAA.toInt() // P -> light gray
        2 -> 0xFFFF4444.toInt() // R -> bright red
        3 -> 0xFF44AAFF.toInt() // N -> bright blue
        4 -> 0xFF44FF44.toInt() // D -> bright green
        5 -> 0xFFCC66FF.toInt() // M -> bright purple
        6 -> 0xFFFFAA44.toInt() // S -> bright orange
        else -> 0xFFFFFFFF.toInt()
    }

    /** Solid fill with a neon glow via setShadowLayer + SRC_IN, using cached ColorFilters. */
    private fun drawIcon(c: Canvas, alpha: Bitmap?, x: Float, y: Float, color: Int) {
        if (alpha == null) return
        iconPaint.colorFilter = getCachedColorFilter(color)
        iconPaint.setShadowLayer(8f, 0f, 0f, color) // neon glow
        iconSrcRect.set(0, 0, alpha.width, alpha.height)
        iconDstRect.set(x, y, x + ICON_SIZE, y + ICON_SIZE)
        c.drawBitmap(alpha, iconSrcRect, iconDstRect, iconPaint)
        iconPaint.colorFilter = null
        iconPaint.clearShadowLayer()
    }

    private fun getCachedColorFilter(color: Int): PorterDuffColorFilter =
        colorFilterCache.getOrPut(color) { PorterDuffColorFilter(color, PorterDuff.Mode.SRC_IN) }

    fun swapAndGetFront(): Bitmap? = doubleBuffer.swapAndGetFront()

    fun release() = doubleBuffer.release()

    private companion object {
        const val WIDTH = 1280
        const val HEIGHT = 80
        const val ICON_DIR = "/data/local/tmp/overlay/"
        const val ICON_SIZE = 40
        const val KM_TO_MI = 0.621371
    }
}
