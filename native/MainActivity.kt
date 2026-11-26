package com.retkhadan.ret_khadan

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import kotlin.math.max
import kotlin.math.min

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
                val boundsOpts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                assets.open(assetPath).use { s -> BitmapFactory.decodeStream(s, null, boundsOpts) }
                val maxDim = max(boundsOpts.outWidth, boundsOpts.outHeight)
                var sample = 1
                while (maxDim / sample > 1100) {
                    sample *= 2
                }
                val decodeOpts = BitmapFactory.Options().apply {
                    inSampleSize = sample
                    inPreferredConfig = Bitmap.Config.RGB_565
                }
                val rawBmp = assets.open(assetPath).use { s -> BitmapFactory.decodeStream(s, null, decodeOpts) }
                if (rawBmp != null) {
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

    private fun drawPageBackground(canvas: Canvas, bgBmp: Bitmap?, bgPaint: Paint, overlayPaint: Paint, headerBand: Paint, footerBand: Paint) {
        canvas.drawColor(Color.parseColor("#F8EFE0"))
        if (bgBmp != null) {
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
        canvas.drawRect(0f, 0f, 595f, 10f, headerBand)
        canvas.drawRect(0f, 832f, 595f, 842f, footerBand)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ret/pdf").setMethodCallHandler { call, result ->
            if (call.method == "make") {
                try {
                    val args = call.arguments as? Map<*, *>
                    val outPath = args?.get("path")?.toString() ?: ""
                    val titleRaw = args?.get("title")?.toString() ?: "Ret Khadaan"
                    val sub = args?.get("sub")?.toString() ?: ""
                    val margin = ((args?.get("margin") as? Number)?.toFloat() ?: 14f).coerceIn(10f, 22f)
                    val sections = (args?.get("sections") as? List<*>) ?: emptyList<Any>()

                    val doc = PdfDocument()
                    var pageNum = 1
                    var pageInfo = PdfDocument.PageInfo.Builder(595, 842, pageNum).create()
                    var page = doc.startPage(pageInfo)
                    var canvas: Canvas = page.canvas

                    val bgBmp = loadPdfBgBitmap5BitStyle()
                    val bgPaint = Paint().apply {
                        alpha = 52
                        isFilterBitmap = true
                    }
                    val overlayPaint = Paint().apply {
                        color = Color.parseColor("#9AF8EFE0")
                    }
                    val headerBand = Paint().apply { color = Color.parseColor("#8B5E34") }
                    val footerBand = Paint().apply { color = Color.parseColor("#A97944") }
                    drawPageBackground(canvas, bgBmp, bgPaint, overlayPaint, headerBand, footerBand)

                    val titlePillPaint = Paint().apply {
                        color = Color.parseColor("#FCEFD9")
                        isAntiAlias = true
                    }
                    val titlePillStroke = Paint().apply {
                        color = Color.parseColor("#B88A58")
                        style = Paint.Style.STROKE
                        strokeWidth = 1.4f
                        isAntiAlias = true
                    }
                    val mainTitlePaint = Paint().apply {
                        color = Color.parseColor("#4A2E16")
                        textSize = 18.5f
                        isAntiAlias = true
                        typeface = Typeface.create(Typeface.SERIF, Typeface.BOLD)
                        textAlign = Paint.Align.CENTER
                    }
                    val khadanTitlePaint = Paint().apply {
                        color = Color.parseColor("#7A4B22")
                        textSize = 14f
                        isAntiAlias = true
                        typeface = Typeface.create(Typeface.SERIF, Typeface.BOLD)
                        textAlign = Paint.Align.CENTER
                    }
                    val smallThekedarPaint = Paint().apply {
                        color = Color.parseColor("#5B4632")
                        textSize = 9.5f
                        isAntiAlias = true
                        textAlign = Paint.Align.CENTER
                    }
                    val secPaint = Paint().apply {
                        color = Color.parseColor("#6F4723")
                        textSize = 11.5f
                        isAntiAlias = true
                        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                    }
                    val colPillPaint = Paint().apply {
                        color = Color.parseColor("#966437")
                        isAntiAlias = true
                    }
                    val colTextPaint = Paint().apply {
                        color = Color.WHITE
                        textSize = 7.8f
                        isAntiAlias = true
                        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                        textAlign = Paint.Align.CENTER
                    }
                    val oddRowPaint = Paint().apply {
                        color = Color.parseColor("#CCFFF8EC")
                    }
                    val evenRowPaint = Paint().apply {
                        color = Color.parseColor("#CCF7E4C4")
                    }
                    val cellTextPaint = Paint().apply {
                        color = Color.parseColor("#3D2D1E")
                        textSize = 8.0f
                        isAntiAlias = true
                        textAlign = Paint.Align.CENTER
                    }
                    val notePaint = Paint().apply {
                        color = Color.parseColor("#4A2E16")
                        textSize = 10f
                        isAntiAlias = true
                        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                    }

                    val titleLines = titleRaw.split("\n").map { it.trim() }.filter { it.isNotEmpty() }
                    val line1 = titleLines.firstOrNull() ?: "Ret Khadaan"
                    val line2 = titleLines.drop(1).joinToString(" · ")

                    var y = margin + 12f
                    val pillTop = y
                    val pillBottom = if (line2.isNotEmpty()) y + 48f else y + 28f
                    val pillRect = RectF(margin + 75f, pillTop, 595f - margin - 75f, pillBottom)
                    canvas.drawRoundRect(pillRect, 14f, 14f, titlePillPaint)
                    canvas.drawRoundRect(pillRect, 14f, 14f, titlePillStroke)
                    canvas.drawText(line1, 595f / 2f, pillTop + 19f, mainTitlePaint)
                    if (line2.isNotEmpty()) {
                        canvas.drawText(line2, 595f / 2f, pillTop + 39f, khadanTitlePaint)
                    }
                    y = pillBottom + 14f
                    if (sub.isNotEmpty()) {
                        for (sLine in sub.split("\n")) {
                            canvas.drawText(sLine.trim(), 595f / 2f, y, smallThekedarPaint)
                            y += 12f
                        }
                    }
                    y += 4f

                    fun ensureSpace(needed: Float) {
                        if (y + needed > 842f - margin - 8f) {
                            doc.finishPage(page)
                            pageNum += 1
                            pageInfo = PdfDocument.PageInfo.Builder(595, 842, pageNum).create()
                            page = doc.startPage(pageInfo)
                            canvas = page.canvas
                            drawPageBackground(canvas, bgBmp, bgPaint, overlayPaint, headerBand, footerBand)
                            y = margin + 18f
                        }
                    }

                    val usableW = 595f - (margin * 2f)

                    for (secAny in sections) {
                        val sec = secAny as? Map<*, *> ?: continue
                        val heading = sec["heading"]?.toString() ?: ""
                        if (heading.isNotEmpty()) {
                            ensureSpace(22f)
                            canvas.drawText(heading, margin, y, secPaint)
                            y += 12f
                        }
                        val cols = ((sec["cols"] as? List<*>)?.map { it?.toString() ?: "" } ?: emptyList())
                        val rawWidths = ((sec["w"] as? List<*>)?.map { (it as? Number)?.toFloat() ?: 50f } ?: emptyList())
                        val rows = ((sec["rows"] as? List<*>)?.map { rAny -> (rAny as? List<*>)?.map { it?.toString()?.replace("\n", " ") ?: "" } ?: emptyList() } ?: emptyList())

                        if (cols.isNotEmpty()) {
                            ensureSpace(28f)
                            val totalW = rawWidths.sum().coerceAtLeast(1f)
                            val colWidths = if (rawWidths.size == cols.size) {
                                rawWidths.map { (it / totalW) * usableW }
                            } else {
                                List(cols.size) { usableW / cols.size }
                            }

                            var cx = margin
                            for (i in cols.indices) {
                                val cw = colWidths[i]
                                val rect = RectF(cx + 1.2f, y, cx + cw - 1.2f, y + 22f)
                                canvas.drawRoundRect(rect, 6f, 6f, colPillPaint)
                                canvas.drawText(cols[i], cx + cw / 2f, y + 14f, colTextPaint)
                                cx += cw
                            }
                            y += 25f

                            for (rIdx in rows.indices) {
                                ensureSpace(20f)
                                val rowCells = rows[rIdx]
                                val rowRect = RectF(margin, y, margin + usableW, y + 18f)
                                canvas.drawRect(rowRect, if (rIdx % 2 == 0) oddRowPaint else evenRowPaint)
                                var rx = margin
                                for (cIdx in cols.indices) {
                                    val cw = colWidths[cIdx]
                                    val cellVal = if (cIdx < rowCells.size) rowCells[cIdx] else "-"
                                    val maxChars = max(3, ((cw - 5f) / 4.2f).toInt())
                                    val shown = if (cellVal.length > maxChars) cellVal.substring(0, min(cellVal.length, maxChars - 1)) + "…" else cellVal
                                    canvas.drawText(shown, rx + cw / 2f, y + 12f, cellTextPaint)
                                    rx += cw
                                }
                                y += 18f
                            }
                            y += 6f
                        }

                        val notes = (sec["notes"] as? List<*>) ?: emptyList<Any>()
                        for (nAny in notes) {
                            val noteStr = nAny?.toString() ?: ""
                            if (noteStr.isNotEmpty()) {
                                ensureSpace(16f)
                                canvas.drawText(noteStr, margin + 2f, y + 6f, notePaint)
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
