import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const mon = ['जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'];
const wk = ['सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'];

num nv(dynamic x) => x is num ? x : (num.tryParse('${x ?? ''}'.replaceAll(',', '').trim()) ?? 0);
String fmtN(num n) => n == n.roundToDouble() ? n.round().toString() : n.toStringAsFixed(2);

String rs(num x) {
  final neg = x < 0;
  var s = x.abs().round().toString();
  if (s.length > 3) {
    final last = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    s = '${parts.join(',')},$last';
  }
  return '${neg ? '-' : ''}₹$s';
}

String two(int n) => n.toString().padLeft(2, '0');
String dkey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
DateTime dparse(dynamic k) {
  final p = '$k'.split('-');
  if (p.length != 3) return DateTime.now();
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}
String dShow(dynamic k) {
  final d = dparse(k);
  return '${d.day} ${mon[d.month - 1]} ${d.year}';
}
String tnow() => '${two(DateTime.now().hour)}:${two(DateTime.now().minute)}';
String tShow(dynamic t) {
  final s = '${t ?? ''}';
  final p = s.split(':');
  if (p.length != 2) return '';
  var h = int.tryParse(p[0]) ?? 0;
  final ap = h >= 12 ? 'PM' : 'AM';
  h = h % 12 == 0 ? 12 : h % 12;
  return '$h:${p[1]} $ap';
}

class Store extends ChangeNotifier {
  late SharedPreferences sp;
  Map<String, dynamic> d = {};

  Future<void> init() async {
    sp = await SharedPreferences.getInstance();
    final s = sp.getString('data');
    if (s != null) {
      try {
        d = Map<String, dynamic>.from(jsonDecode(s));
      } catch (_) {}
    }
    _fix();
  }

  void _fix() {
    for (final k in ['hyva', 'royalty', 'expense', 'bpay']) {
      d.putIfAbsent(k, () => <dynamic>[]);
    }
    for (final k in ['rates', 'vehicles', 'names', 'meta']) {
      d.putIfAbsent(k, () => <String, dynamic>{});
    }
    d.putIfAbsent('seq', () => 0);
    d.putIfAbsent('defRate', () => '');
  }

  Future<void> save() async {
    await sp.setString('data', jsonEncode(d));
    notifyListeners();
  }

  List<Map<String, dynamic>> list(String k) => (d[k] as List).map((e) => e as Map<String, dynamic>).toList();
  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> upsert(String k, Map<String, dynamic> r) async {
    r['id'] ??= newId();
    final l = d[k] as List;
    final i = l.indexWhere((e) => e['id'] == r['id']);
    if (i >= 0) {
      l[i] = r;
    } else {
      l.insert(0, r);
    }
    await save();
  }

  Future<void> remove(String k, String id) async {
    (d[k] as List).removeWhere((e) => e['id'] == id);
    if (k == 'hyva') (d['royalty'] as List).removeWhere((e) => e['hyvaId'] == id);
    await save();
  }

  List<String> names(String g) => List<String>.from(((d['names'] as Map)[g] ?? []) as List);
  void addName(String g, dynamic v) {
    final s = '${v ?? ''}'.trim();
    if (s.isEmpty) return;
    final m = d['names'] as Map;
    final l = List<String>.from((m[g] ?? []) as List);
    if (!l.contains(s)) {
      l.add(s);
      l.sort();
      m[g] = l;
    }
  }

  Map metaMap(String g) {
    final m = d['meta'] as Map;
    return (m[g] ??= <String, dynamic>{}) as Map;
  }

  List<String> vehicleNames() => (d['vehicles'] as Map).keys.cast<String>().toList()..sort();
  Map? vehicle(dynamic n) => (d['vehicles'] as Map)['$n'.trim().toUpperCase()] as Map?;
  List<Map> driversOf(dynamic n) {
    final v = vehicle(n);
    return v == null ? [] : (v['drivers'] as List).cast<Map>();
  }

  void saveVehicle(dynamic num_, dynamic owner, dynamic driver, dynamic mobile) {
    final n = '$num_'.trim().toUpperCase();
    if (n.isEmpty) return;
    final m = d['vehicles'] as Map;
    final v = (m[n] ?? {'owner': '', 'drivers': []}) as Map;
    if ('${owner ?? ''}'.trim().isNotEmpty) v['owner'] = '$owner'.trim();
    final dn = '${driver ?? ''}'.trim();
    if (dn.isNotEmpty) {
      final ds = v['drivers'] as List;
      final i = ds.indexWhere((e) => e['n'] == dn);
      final mob = '${mobile ?? ''}'.trim();
      if (i >= 0) {
        if (mob.isNotEmpty) ds[i]['m'] = mob;
      } else {
        ds.add({'n': dn, 'm': mob});
      }
    }
    m[n] = v;
  }

  String rateFor(String date) => '${(d['rates'] as Map)[date] ?? d['defRate'] ?? ''}';
  String takeSerial() {
    d['seq'] = (d['seq'] as int) + 1;
    return 'R-${d['seq'].toString().padLeft(4, '0')}';
  }

  String export() => jsonEncode(d);
  Future<void> restore(String s) async {
    d = Map<String, dynamic>.from(jsonDecode(s));
    _fix();
    await save();
  }

  Future<String> keepPhoto(String src) async {
    final dir = await getApplicationDocumentsDirectory();
    final p = '${dir.path}/photo_${newId()}.jpg';
    await File(src).copy(p);
    return p;
  }
}

final S = Store();
