import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static Future<pw.ThemeData> _loadHindiPdfTheme() async {
    final regularData = await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/NotoSansDevanagari-Bold.ttf');
    final regularFont = pw.Font.ttf(regularData);
    final boldFont = pw.Font.ttf(boldData);
    return pw.ThemeData.withFont(base: regularFont, bold: boldFont);
  }

  /// Hyva PDF: 9 Exact Columns + Date-wise once at top + Page Break per Date in Monthly/All
  static Future<void> exportHyvaPdf(
    List> rows, {
    required String mode,
    required String headerSubtitle,
  }) async {
    final theme = await _loadHindiPdfTheme();
    final pdf = pw.Document(theme: theme);

    final grouped = <String, List>>{};
    for (final r in rows) {
      final d = r['entry_date'].toString();
      grouped.putIfAbsent(d, () => []).add(r);
    }

    if (grouped.isEmpty) {
      grouped[headerSubtitle] = [];
    }

    for (final entry in grouped.entries) {
      final dateHeading = entry.key;
      final list = entry.value;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) => [
            pw.Text(
              'Ret Khadan Management - Hyva Report',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              mode == 'date' ? 'दिनांक: $dateHeading' : '$headerSubtitle | दिनांक: $dateHeading',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headers: [
                'क्र.',
                'Vehicle No',
                'Owner Name',
                'Driver Name',
                'Mobile No',
                'Amount',
                'Dalal Name',
                'Status',
                'Partial / Bal',
              ],
              data: List.generate(list.length, (i) {
                final r = list[i];
                final status = r['payment_status'].toString();
                final balText = (status == 'Partial' || status == 'Balance')
                    ? '₹${r['balance_amount']}'
                    : '-';
                return [
                  '${i + 1}',
                  r['vehicle_no'] ?? '',
                  r['owner_name'] ?? '',
                  r['driver_name'] ?? '',
                  r['mobile_no'] ?? '',
                  '₹${r['amount']}',
                  r['dalal_name'] ?? '-',
                  status,
                  balText,
                ];
              }),
            ),
          ],
        ),
      );
    }

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Hyva_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Royalty PDF: 12 Exact Fields + Page Break per Date in Monthly/All
  static Future<void> exportRoyaltyPdf(
    List> rows, {
    required String mode,
    required String headerSubtitle,
  }) async {
    final theme = await _loadHindiPdfTheme();
    final pdf = pw.Document(theme: theme);

    final grouped = <String, List>>{};
    for (final r in rows) {
      final d = r['entry_date'].toString();
      grouped.putIfAbsent(d, () => []).add(r);
    }

    if (grouped.isEmpty) grouped[headerSubtitle] = [];

    for (final entry in grouped.entries) {
      final dateHeading = entry.key;
      final list = entry.value;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          orientation: pw.PageOrientation.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (ctx) => [
            pw.Text(
              'Ret Khadan Management - Royalty Report',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('दिनांक: $dateHeading ($headerSubtitle)', style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headers: [
                'क्र.',
                'समय',
                'घन मी.',
                'Vehicle',
                'Owner',
                'Driver',
                'Mobile',
                'प्राप्तकर्ता',
                'कहाँ जाएगी',
                'देने वाला',
                'Amount',
              ],
              data: list.map((r) {
                return [
                  '#${r['royalty_kramank']}',
                  r['entry_time'] ?? '',
                  '${r['ghan_meter']}',
                  r['vehicle_no'] ?? '',
                  r['owner_name'] ?? '',
                  r['driver_name'] ?? '',
                  r['mobile_no'] ?? '',
                  r['royalty_receiver'] ?? '-',
                  r['destination'] ?? '',
                  r['royalty_cutter'] ?? '',
                  '₹${r['amount']}',
                ];
              }).toList(),
            ),
          ],
        ),
      );
    }

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Royalty_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Kharch PDF
  static Future<void> exportKharchPdf(
    String title,
    List> rows,
    String subtitle,
  ) async {
    final theme = await _loadHindiPdfTheme();
    final pdf = pw.Document(theme: theme);
    final total = rows.fold<double>(0, (s, e) => s + ((e['amount'] as num?) ?? 0).toDouble());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text(subtitle, style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['क्र.', 'दिनांक', 'विवरण / नाम / वाहन', 'राशि (₹)'],
            data: List.generate(rows.length, (i) {
              final r = rows[i];
              final desc = '${r['person_name'] ?? ''} ${r['vehicle_no'] ?? ''} ${r['sub_type'] ?? ''}'.trim();
              return ['${i + 1}', r['entry_date'] ?? '', desc, '₹${r['amount']}'];
            }),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'कुल खर्च: ₹${total.toStringAsFixed(0)}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${title.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Excel Export & Share
  static Future<void> exportToExcel(String sheetTitle, List> rows) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    if (rows.isNotEmpty) {
      final keys = rows.first.keys.toList();
      sheet.appendRow(keys.map((k) => TextCellValue(k)).toList());
      for (final row in rows) {
        sheet.appendRow(keys.map((k) => TextCellValue('${row[k] ?? ''}')).toList());
      }
    }

    final dir = await getTemporaryDirectory();
    final filePath = p.join(dir.path, '${sheetTitle.replaceAll(' ', '_')}.xlsx');
    final bytes = excel.encode();
    if (bytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: sheetTitle);
    }
  }
}
