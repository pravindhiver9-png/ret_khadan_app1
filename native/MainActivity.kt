package com.retkhadan.ret_khadan

import android.graphics.*
import android.graphics.pdf.PdfDocument
import android.text.TextPaint
import android.text.TextUtils
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.FileOutputStream

// Native PDF engine: Hindi sahi shape hota hai aur PDF me text asli text (selectable) rehta hai.
class MainActivity : FlutterActivity() {

    // ---- PDF me jaane wale pixels (kam karo to PDF chhota, zyada karo to zoom me saaf) ----
    private val BG_W = 900
    private val BG_H = 1273
    private val ICON_PX = 128

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ret/pdf")
            .setMethodCallHandler { call, result ->
                if (call.method == "make") {
                    try {
                        @Suppress("UNCHECKED_CAST")
                        makePdf(call.arguments as Map<String, Any?>)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("pdf", e.toString(), null)
                    }
                } else result.notImplemented()
            }
    }

    // Image ko shuru se hi chhota karke kholta hai (memory bhi bachti hai)
    private fun small(assetKey: String, w: Int, h: Int): Bitmap {
        val o = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        assets.open(assetKey).use { BitmapFactory.decodeStream(it, null, o) }
        var s = 1
        while (o.outWidth / (s * 2) >= w && o.outHeight / (s * 2) >= h) s *= 2
        val opts = BitmapFactory.Options().apply { inSampleSize = s }
        val big = assets.open(assetKey).use { BitmapFactory.decodeStream(it, null, opts) }!!
        val out = Bitmap.createScaledBitmap(big, w, h, true)
        if (out !== big) big.recycle()
        return out
    }

    // Rang ke last 2 bits hata deta hai: dikhne me farq nahi, par PDF bahut chhota ho jata hai
    private fun quant(b: Bitmap): Bitmap {
        val px = IntArray(b.width * b.height)
        b.getPixels(px, 0, b.width, 0, 0, b.width, b.height)
        for (i in px.indices) {
            val p = px[i]
            val r = ((p shr 16) and 0xFC) or 0x02
            val g = ((p shr 8) and 0xFC) or 0x02
            val bl = (p and 0xFC) or 0x02
            px[i] = (0xFF shl 24) or (r shl 16) or (g shl 8) or bl
        }
        val out = Bitmap.createBitmap(b.width, b.height, Bitmap.Config.ARGB_8888)
        out.setPixels(px, 0, b.width, 0, 0, b.width, b.height)
        b.recycle()
        return out
    }

    private fun makePdf(a: Map<String, Any?>) {
        val loader = FlutterInjector.instance().flutterLoader()
        fun asset(p: String) = loader.getLookupKeyForAsset(p)

        val reg = Typeface.createFromAsset(assets, asset("assets/fonts/NotoSansDevanagari-Regular.ttf"))
        val bold = Typeface.createFromAsset(assets, asset("assets/fonts/NotoSansDevanagari-Bold.ttf"))
        val bg = quant(small(asset("assets/images/pdf_bg.jpg"), BG_W, BG_H))
        val icon = small(asset("assets/icon/app_icon.png"), ICON_PX, ICON_PX)

        fun tp(face: Typeface, size: Float, color: String) = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = face; textSize = size; this.color = Color.parseColor(color)
        }
        val pTitle = tp(bold, 17f, "#45413A")
        val pSub = tp(reg, 10f, "#6B6354")
        val pHead = tp(bold, 13f, "#8B6B48")
        val pTh = tp(bold, 9.5f, "#FFFFFF")
        val pTd = tp(reg, 9.5f, "#45413A")
        val pNote = tp(bold, 11f, "#45413A")
        val pPg = tp(reg, 9f, "#8B6B48")
        val imgPaint = Paint(Paint.FILTER_BITMAP_FLAG)
        val thPaint = Paint().apply { color = Color.parseColor("#8B6B48") }
        val linePaint = Paint().apply { color = Color.parseColor("#C5A77D"); strokeWidth = 0.6f }
        val fillA = Paint().apply { color = Color.argb(215, 255, 255, 255) }
        val fillB = Paint().apply { color = Color.argb(170, 243, 233, 215) }

        val path = a["path"] as String
        val title = a["title"] as String
        val sub = a["sub"] as String
        val sections = a["sections"] as List<*>

        val W = 595; val H = 842
        val L = 40f; val CW = 515f; val TOP = 140f; val LIM = 765f
        val doc = PdfDocument()
        var pageNo = 0
        var page: PdfDocument.Page? = null
        var cv: Canvas? = null

        fun newPage(heading: String, cont: Boolean): Float {
            page?.let { doc.finishPage(it) }
            pageNo++
            page = doc.startPage(PdfDocument.PageInfo.Builder(W, H, pageNo).create())
            cv = page!!.canvas
            cv!!.drawBitmap(bg, null, RectF(0f, 0f, W.toFloat(), H.toFloat()), imgPaint)
            // icon: left side (38x38 point)
            cv!!.drawBitmap(icon, null, RectF(L, TOP - 24f, L + 38f, TOP + 14f), imgPaint)
            // title / subtitle icon ke right me
            val tx = L + 48f
            cv!!.drawText(title, tx, TOP - 4f, pTitle)
            cv!!.drawText(sub, tx, TOP + 12f, pSub)
            // heading (tarikh / naam) left se
            cv!!.drawText(if (cont) "$heading (जारी)" else heading, L, TOP + 40f, pHead)
            cv!!.drawText("पृष्ठ $pageNo", W / 2f - 15f, 815f, pPg)
            return TOP + 52f
        }

        fun cut(s: String, p: TextPaint, w: Float): String =
            TextUtils.ellipsize(s, p, w, TextUtils.TruncateAt.END).toString()

        fun header(cols: List<String>, cw: List<Float>, y: Float): Float {
            cv!!.drawRect(L, y, L + CW, y + 22f, thPaint)
            var x = L
            for (j in cw.indices) {
                cv!!.drawText(cut(cols.getOrElse(j) { "" }, pTh, cw[j] - 8f), x + 4f, y + 15f, pTh)
                x += cw[j]
            }
            return y + 22f
        }

        for (s in sections) {
            val m = s as Map<*, *>
            val heading = m["heading"].toString()
            val cols = (m["cols"] as List<*>).map { it.toString() }
            val ws = (m["w"] as List<*>).map { (it as Number).toFloat() }
            val rows = (m["rows"] as List<*>).map { r -> (r as List<*>).map { it.toString() } }
            val notes = (m["notes"] as List<*>).map { it.toString() }
            val total = ws.sum()
            val cw = ws.map { it / total * CW }

            var y = newPage(heading, false)
            y = header(cols, cw, y)
            for ((i, r) in rows.withIndex()) {
                val nl = r.maxOfOrNull { it.split("\n").size } ?: 1
                val h = nl * 12.5f + 8f
                if (y + h > LIM) {
                    y = newPage(heading, true)
                    y = header(cols, cw, y)
                }
                cv!!.drawRect(L, y, L + CW, y + h, if (i % 2 == 0) fillA else fillB)
                var x = L
                for (j in cw.indices) {
                    val cell = r.getOrElse(j) { "" }
                    cell.split("\n").forEachIndexed { k, line ->
                        cv!!.drawText(cut(line, pTd, cw[j] - 8f), x + 4f, y + 12f + k * 12.5f, pTd)
                    }
                    x += cw[j]
                }
                cv!!.drawLine(L, y + h, L + CW, y + h, linePaint)
                y += h
            }
            y += 8f
            for (n in notes) {
                if (y + 18f > LIM) { y = newPage(heading, true) }
                cv!!.drawText(n, L + 4f, y + 12f, pNote)
                y += 18f
            }
        }
        page?.let { doc.finishPage(it) }
        FileOutputStream(path).use { doc.writeTo(it) }
        doc.close()
        bg.recycle()
        icon.recycle()
    }
}
