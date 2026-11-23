package com.retkhadan.ret_khadan

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ret/pdf").setMethodCallHandler { call, result ->
            if (call.method == "make") {
                try {
                    val args = call.arguments as? Map<*, *>
                    val outPath = args?.get("path")?.toString() ?: ""
                    val title = args?.get("title")?.toString() ?: "Report"
                    val sub = args?.get("sub")?.toString() ?: ""
                    val sections = (args?.get("sections") as? List<*>) ?: emptyList<Any>()

                    val doc = PdfDocument()
                    val pageInfo = PdfDocument.PageInfo.Builder(595, 842, 1).create()
                    val page = doc.startPage(pageInfo)
                    val canvas: Canvas = page.canvas

                    val titlePaint = Paint().apply {
                        color = Color.parseColor("#45413A")
                        textSize = 18f
                        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                    }
                    val subPaint = Paint().apply {
                        color = Color.parseColor("#8B6B48")
                        textSize = 12f
                    }
                    val bodyPaint = Paint().apply {
                        color = Color.parseColor("#45413A")
                        textSize = 11f
                    }

                    var y = 42f
                    canvas.drawText(title, 24f, y, titlePaint)
                    y += 20f
                    if (sub.isNotEmpty()) {
                        canvas.drawText(sub, 24f, y, subPaint)
                        y += 22f
                    }

                    for (secAny in sections) {
                        val sec = secAny as? Map<*, *> ?: continue
                        val heading = sec["heading"]?.toString() ?: ""
                        if (heading.isNotEmpty()) {
                            canvas.drawText(heading, 24f, y, titlePaint.apply { textSize = 13f })
                            y += 18f
                        }
                        val rows = (sec["rows"] as? List<*>) ?: emptyList<Any>()
                        for (rAny in rows) {
                            val cells = (rAny as? List<*>)?.map { it?.toString()?.replace("\n", " ") ?: "" } ?: emptyList()
                            canvas.drawText(cells.joinToString(" | "), 28f, y, bodyPaint)
                            y += 16f
                            if (y > 790f) break
                        }
                        y += 10f
                        if (y > 790f) break
                    }

                    doc.finishPage(page)
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
