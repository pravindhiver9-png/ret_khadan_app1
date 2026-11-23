import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'store.dart';
import 'ui.dart';

const _ch = MethodChannel('ret/pdf');

class Sec {
  final String heading;
  final List<String> cols;
  final List<double> w;
  final List<List<String>> rows;
  final List<String> notes;
  Sec(this.heading, this.cols, this.w, this.rows, [this.notes = const []]);
  Map<String, dynamic> toMap() => {'heading': heading, 'cols': cols, 'w': w, 'rows': rows, 'notes': notes};
}

String buildPdfHeaderTitle(String fallbackTitle) {
  final tk = S.activeThekedar;
  final khadan = '${tk?['khadan'] ?? ''}'.trim();
  final thekedar = '${tk?['name'] ?? ''}'.trim();
  if (khadan.isNotEmpty && thekedar.isNotEmpty) {
    return '$khadan  —  ${S.tr('ठेकेदार', 'Contractor')}: $thekedar';
  }
  if (khadan.isNotEmpty) return khadan;
  if (thekedar.isNotEmpty) return '$fallbackTitle · ${S.tr('ठेकेदार', 'Contractor')}: $thekedar';
  return fallbackTitle;
}

String buildPdfHeaderSub(String sub) {
  final tk = S.activeThekedar;
  final parts = <String>[];
  if (sub.trim().isNotEmpty) parts.add(sub.trim());
  final mob = '${tk?['mobile'] ?? ''}'.trim();
  final addr = '${tk?['address'] ?? ''}'.trim();
  final extra = [if (mob.isNotEmpty) mob, if (addr.isNotEmpty) addr].join(' · ');
  if (extra.isNotEmpty) parts.add(extra);
  return parts.join('  |  ');
}

Future<String> generatePdfFile(String name, String title, String sub, List<Sec> secs) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$name.pdf';
  final headerTitle = buildPdfHeaderTitle(title);
  final headerSub = buildPdfHeaderSub(sub);
  await _ch.invokeMethod('make', {
    'path': path,
    'title': headerTitle,
    'sub': headerSub,
    'margin': 16.0,
    'theme': {
      'bg': '#F3E9D7',
      'card': '#E3D1B3',
      'accent': '#C5A77D',
      'primary': '#8B6B48',
      'text': '#45413A',
    },
    'sections': secs.map((s) => s.toMap()).toList(),
  });
  return path;
}

Future<void> openPdfPreview(BuildContext context, {required String name, required String title, required String sub, required List<Sec> secs}) async {
  await guard(context, () async {
    final path = await generatePdfFile(name, title, sub, secs);
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PdfPreviewPage(
          filePath: path,
          reportTitle: title,
          headerTitle: buildPdfHeaderTitle(title),
          headerSub: buildPdfHeaderSub(sub),
          secs: secs,
        ),
      ),
    );
  });
}

class _PdfPreviewPage extends StatelessWidget {
  final String filePath;
  final String reportTitle;
  final String headerTitle;
  final String headerSub;
  final List<Sec> secs;
  const _PdfPreviewPage({
    required this.filePath,
    required this.reportTitle,
    required this.headerTitle,
    required this.headerSub,
    required this.secs,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    return Pg(
      S.tr('PDF प्रीव्यू', 'PDF Preview'),
      Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kAcc, width: 1.4),
                    boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        headerTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: kTxt, letterSpacing: 0.4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reportTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kBrown),
                      ),
                      if (headerSub.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          headerSub,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF6A6257)),
                        ),
                      ],
                      const Divider(color: kAcc, thickness: 1.2, height: 18),
                      for (final sec in secs) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(8)),
                          child: Text(sec.heading, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kTxt)),
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFFF3E9D7)),
                            columnSpacing: 14,
                            horizontalMargin: 8,
                            dataRowMinHeight: 32,
                            dataRowMaxHeight: 54,
                            columns: [for (final c in sec.cols) DataColumn(label: Text(c, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kBrown)))],
                            rows: [
                              for (final r in sec.rows)
                                DataRow(
                                  cells: [
                                    for (var i = 0; i < sec.cols.length; i++)
                                      DataCell(Text(i < r.length ? r[i] : '-', style: const TextStyle(fontSize: 12, color: kTxt))),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        if (sec.notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFFAF5EC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x448B6B48))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [for (final n in sec.notes) Text(n, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: kTxt))],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            color: kCard,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: Text(S.tr('बंद करें', 'Close')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: kBrown, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () async {
                      if (!file.existsSync()) {
                        await generatePdfFile(filePath.split('/').last.replaceAll('.pdf', ''), reportTitle, headerSub, secs);
                      }
                      await Share.shareXFiles([XFile(file.path)], text: headerTitle);
                    },
                    icon: const Icon(Icons.share),
                    label: Text(S.tr('शेयर / सेव PDF', 'Share / Save PDF'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> sharePdf(String name, String title, String sub, List<Sec> secs) async {
  final path = await generatePdfFile(name, title, sub, secs);
  await Share.shareXFiles([XFile(path)], text: buildPdfHeaderTitle(title));
}

Future<void> shareCsv(String name, List<String> cols, List<List<String>> rows) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$name.csv';
  String esc(String s) => '"${s.replaceAll('"', '""').replaceAll('\n', ' ')}"';
  final txt = '\uFEFF${[cols, ...rows].map((r) => r.map(esc).join(',')).join('\r\n')}';
  await File(path).writeAsString(txt);
  await Share.shareXFiles([XFile(path)], text: name);
}

Future<void> guard(BuildContext c, Future<void> Function() f) async {
  try {
    await f();
  } catch (e) {
    if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('${S.tr('गड़बड़ी', 'Error')}: $e')));
  }
}
