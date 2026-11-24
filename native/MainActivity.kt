package com.retkhadan.ret_khadan

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import kotlin.math.max

class MainActivity : FlutterActivity() {
    private fun loadPdfBgBitmap5BitStyle(): Bitmap? {
        val loader = io.flutter.FlutterInjector.instance().flutterLoader()
        val candidates = listOf(
            "assets/images/pdf_bg.jpg",
            "assets/images/pdf_bg.png",
            "assets/images/app_bg.jpg",
            "assets/images/app_bg.png"
        )
        for (relPath in candidates) {
            try {
                val assetPath = loader.getLookupKeyForAsset(relPath)
                // First decode bounds to keep size compact and avoid tearing/banding
                val boundsOpts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                assets.open(assetPath).use { s -> BitmapFactory.decodeStream(s, null, boundsOpts) }
                val maxDim = max(boundsOpts.outWidth, boundsOpts.outHeight)
                var sample = 1
                while (maxDim / sample > 1200) {
                    sample *= 2
                }
                // RGB_565 uses compact 5-6-5 channel representation (low memory/size) while keeping smooth tones
                val decodeOpts = BitmapFactory.Options().apply {
                    inSampleSize = sample
                    inPreferredConfig = Bitmap.Config.RGB_565
                }
                val rawBmp = assets.open(assetPath).use { s -> BitmapFactory.decodeStream(s, null, decodeOpts) }
                if (rawBmp != null) {
                    // Apply subtle 5-bit (32-level per channel) quantization with dither/smoothness so it stays lightweight without tearing
                    val w = rawBmp.width
                    val h = rawBmp.height
                    val pixels = IntArray(w * h)
                    rawBmp.getPixels(pixels, 0, w, 0, 0, w, h)
                    for (i in pixels.indices) {
                        val p = pixels[i]
                        val r = ((Color.red(p) ushr 3) * 255) / 31
                        val g = ((Color.green(p) ushr 3) * 255) / 31
                        val b = ((Color.blue(p) ushr 3) * 255) / 31
                        pixels[i] = Color.rgb(r, g, b)
                    }
                    val outBmp = Bitmap.createBitmap(w, h, Bitmap.Config.RGB_565)
                    outBmp.setPixels(pixels, 0, w, 0, 0, w, h)
                    rawBmp.recycle()
                    return outBmp
                }
            } catch (_: Exception) {
            }
        }
        return null
    }

    private fun drawPageBackground(canvas: Canvas, bgBmp: Bitmap?, bgPaint: Paint, overlayPaint: Paint) {
        canvas.drawColor(Color.parseColor("#F3E9D7"))
        if (bgBmp != null) {
            // Center-crop / aspect-cover draw into A4 (595x842) so image never stretches/tears
            val pw = 595f
            val ph = 842f
            val bw = bgBmp.width.toFloat()
            val bh = bgBmp.height.toFloat()
            val scale = max(pw / bw, ph / bh)
            val dw = bw * scale
            val dh = bh * scale
            val left = ((pw - dw) / 2f).toInt()
            val top = ((ph - dh) / 2f).toInt()
            canvas.drawBitmap(bgBmp, null, Rect(left, top, left + dw.toInt(), top + dh.toInt()), bgPaint)
            canvas.drawRect(0f, 0f, pw, ph, overlayPaint)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ret/pdf").setMethodCallHandler { call, result ->
            if (call.method == "make") {
                try {
                    val args = call.arguments as? Map<*, *>
                    val outPath = args?.get("path")?.toString() ?: ""
                    val title = args?.get("title")?.toString() ?: "Report"
                    val sub = args?.get("sub")?.toString() ?: ""
                    val margin = ((args?.get("margin") as? Number)?.toFloat() ?: 16f).coerceIn(10f, 24f)
                    val sections = (args?.get("sections") as? List<*>) ?: emptyList<Any>()

                    val doc = PdfDocument()
                    var pageNum = 1
                    var pageInfo = PdfDocument.PageInfo.Builder(595, 842, pageNum).create()
                    var page = doc.startPage(pageInfo)
                    var canvas: Canvas = page.canvas

                    val bgBmp = loadPdfBgBitmap5BitStyle()
                    val bgPaint = Paint().apply {
                        alpha = 46
                        isFilterBitmap = true
                    }
                    val overlayPaint = Paint().apply {
                        color = Color.parseColor("#A6F3E9D7")
                    }
                    drawPageBackground(canvas, bgBmp, bgPaint, overlayPaint)

                    val titlePaint = Paint().apply {
                        color = Color.parseColor("#45413A")
                        textSize = 17f
                        isAntiAlias = true
                        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                        textAlign = Paint.Align.CENTER
                    }
                    val subPaint = Paint().apply {
                        color = Color.parseColor("#8B6B48")
                        textSize = 11f
                        isAntiAlias = true
                        textAlign = Paint.Align.CENTER
                    }
                    val secPaint = Paint().apply {
                        color = Color.parseColor("#8B6B48")
                        textSize = 12.5f
                        isAntiAlias = true
                        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                    }
                    val bodyPaint = Paint().apply {
                        color = Color.parseColor("#45413A")
                        textSize = 10.5f
                        isAntiAlias = true
                    }
                    val linePaint = Paint().apply {
                        color = Color.parseColor("#C5A77D")
                        strokeWidth = 1.2f
                    }

                    var y = margin + 22f
                    canvas.drawText(title, 595f / 2f, y, titlePaint)
                    y += 18f
                    if (sub.isNotEmpty()) {
                        canvas.drawText(sub, 595f / 2f, y, subPaint)
                        y += 16f
                    }
                    canvas.drawLine(margin, y, 595f - margin, y, linePaint)
                    y += 18f

                    fun ensureSpace(needed: Float) {
                        if (y + needed > 842f - margin) {
                            doc.finishPage(page)
                            pageNum += 1
                            pageInfo = PdfDocument.PageInfo.Builder(595, 842, pageNum).create()
                            page = doc.startPage(pageInfo)
                            canvas = page.canvas
                            drawPageBackground(canvas, bgBmp, bgPaint, overlayPaint)
                            y = margin + 20f
                        }
                    }

                    for (secAny in sections) {
                        val sec = secAny as? Map<*, *> ?: continue
                        val heading = sec["heading"]?.toString() ?: ""
                        if (heading.isNotEmpty()) {
                            ensureSpace(24f)
                            canvas.drawText(heading, margin, y, secPaint)
                            y += 16f
                        }
                        val rows = (sec["rows"] as? List<*>) ?: emptyList<Any>()
                        for (rAny in rows) {
                            ensureSpace(16f)
                            val cells = (rAny as? List<*>)?.map { it?.toString()?.replace("\n", " ") ?: "" } ?: emptyList()
                            canvas.drawText(cells.joinToString(" | "), margin + 4f, y, bodyPaint)
                            y += 15f
                        }
                        val notes = (sec["notes"] as? List<*>) ?: emptyList<Any>()
                        for (nAny in notes) {
                            val noteStr = nAny?.toString() ?: ""
                            if (noteStr.isNotEmpty()) {
                                ensureSpace(16f)
                                canvas.drawText(noteStr, margin + 4f, y, secPaint)
                                y += 15f
                            }
                        }
                        y += 10f
                    }

                    doc.finishPage(page)
                    bgBmp?.recycle()
                    val outFile = File(outPath)
                    outFile.parentFile?.mkdirs()
                    FileOutputStream(outFile).use { fos -> doc.writeTo(fos) }
                    doc.close()
                    result.success(outPath)
                } catch (e: Exception) {
                    result.error("PDF_ERR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
