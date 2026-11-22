import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

/// A4 PDF (pdf_bg background, Noto Devanagari font, selectable text) banao aur share karo.
Future<void> sharePdf(String name, String title, String sub, List<Sec> secs) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$name.pdf';
  await _ch.invokeMethod('make', {'path': path, 'title': title, 'sub': sub, 'sections': secs.map((s) => s.toMap()).toList()});
  await Share.shareXFiles([XFile(path)], text: title);
}

/// Excel me khulne wali CSV (UTF-8, Hindi sahi dikhega)
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
    if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('गड़बड़ी: $e')));
  }
}
