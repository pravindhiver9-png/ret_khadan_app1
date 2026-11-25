import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const mon = ['जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'];
const monEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const wk = ['सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'];
const wkEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const tyreSizes = ['10 Tyre', '12 Tyre', '14 Tyre', '16 Tyre'];

String capFirst(dynamic raw) {
  final s = '${raw ?? ''}'.trim();
  if (s.isEmpty) return '';
  return s[0].toUpperCase() + s.substring(1);
}

String capWords(dynamic raw) {
  final s = '${raw ?? ''}'.trim();
  if (s.isEmpty) return '';
  return s
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

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
  if (S.isEn) return '${d.day} ${monEn[d.month - 1]} ${d.year}';
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
  bool skipNextLock = false;
  DateTime? lastPauseAt;

  bool get isEn => d['lang'] == 'en';
  String tr(String hi, String en) => isEn ? en : hi;
  String get mpin => '${d['mpin'] ?? ''}';
  String get activeThekedarId => '${d['activeThekedar'] ?? ''}';

  Map<String, dynamic>? get activeThekedar {
    final list = thekedars();
    if (list.isEmpty) return null;
    final id = activeThekedarId;
    return list.firstWhere((e) => '${e['id']}' == id, orElse: () => list.first);
  }

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
    for (final k in ['hyva', 'royalty', 'expense', 'bpay', 'thekedars', 'jcbs', 'suppliers']) {
      d.putIfAbsent(k, () => <dynamic>[]); }
    for (final k in ['rates', 'vehicles', 'names', 'meta']) {
      d.putIfAbsent(k, () => <String, dynamic>{}); }
    d.putIfAbsent('seq', () => 0);
    d.putIfAbsent('lang', () => 'hi');
    d.putIfAbsent('mpin', () => '');
    d.putIfAbsent('activeThekedar', () => '');
    d.putIfAbsent('defRate', () => '');
  }

  Future<void> save() async {
    await sp.setString('data', jsonEncode(d));
    notifyListeners();
  }

  Future<void> setLang(String code) async {
    d['lang'] = code == 'en' ? 'en' : 'hi';
    await save();
  }

  Future<void> setMpin(String pin) async {
    d['mpin'] = pin.trim();
    await save();
  }

  List<Map<String, dynamic>> list(String k) => (d[k] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> upsert(String k, Map<String, dynamic> r) async {
    r['id'] ??= newId();
    final tk = activeThekedar;
    if (tk != null) {
      r['thekedarId'] ??= tk['id'];
      r['thekedarName'] ??= tk['name'];
      r['khadanName'] ??= tk['khadan'];
    }
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

  List<Map<String, dynamic>> thekedars() => list('thekedars');

  Future<void> saveThekedar(Map<String, dynamic> t, {bool setActive = true}) async {
    t['id'] ??= newId();
    t['name'] = capWords(t['name']);
    t['mobile'] = '${t['mobile'] ?? ''}'.trim();
    t['address'] = capFirst(t['address']);
    t['khadan'] = capWords(t['khadan']);
    final l = d['thekedars'] as List;
    final idx = l.indexWhere((e) => e['id'] == t['id']);
    if (idx >= 0) {
      l[idx] = t;
    } else {
      l.add(t);
    }
    if (setActive) d['activeThekedar'] = t['id'];
    await save();
  }

  Future<void> selectThekedar(String id) async {
    d['activeThekedar'] = id;
    await save();
  }

  Future<void> removeThekedar(String id) async {
    final l = d['thekedars'] as List;
    l.removeWhere((e) => '${e['id']}' == id);
    if ('${d['activeThekedar'] ?? ''}' == id) {
      d['activeThekedar'] = l.isNotEmpty ? '${l.first['id']}' : '';
    }
    await save();
  }

  List<Map<String, dynamic>> jcbs() => list('jcbs');
  Future<void> saveJcb(Map<String, dynamic> item) async {
    item['id'] ??= newId();
    item['company'] = capWords(item['company']);
    final ops = ((item['operators'] ?? []) as List).map((e) => capWords(e)).where((e) => e.isNotEmpty).toList();
    final hps = ((item['helpers'] ?? []) as List).map((e) => capWords(e)).where((e) => e.isNotEmpty).toList();
    item['operators'] = ops;
    item['helpers'] = hps;
    final l = d['jcbs'] as List;
    final idx = l.indexWhere((e) => e['id'] == item['id']);
    if (idx >= 0) {
      l[idx] = item;
    } else {
      l.insert(0, item);
    }
    await save();
  }

  List<Map<String, dynamic>> suppliers() => list('suppliers');
  Future<void> saveSupplier(Map<String, dynamic> sup) async {
    sup['id'] ??= newId();
    sup['name'] = capWords(sup['name']);
    sup['vehicle'] = '${sup['vehicle'] ?? ''}'.trim().toUpperCase();
    sup['driver'] = capWords(sup['driver']);
    sup['mobile'] = '${sup['mobile'] ?? ''}'.trim();
    sup['village'] = capWords(sup['village']);
    saveVehicle(sup['vehicle'], sup['name'], sup['driver'], sup['mobile'], '');
    final l = d['suppliers'] as List;
    final idx = l.indexWhere((e) => e['id'] == sup['id']);
    if (idx >= 0) {
      l[idx] = sup;
    } else {
      l.insert(0, sup);
    }
    await save();
  }

  List<String> names(String g) => List<String>.from(((d['names'] as Map)[g] ?? []) as List);
  void addName(String g, dynamic v) {
    final s = capWords(v);
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

  void saveVehicle(dynamic num_, dynamic owner, dynamic driver, dynamic mobile, [dynamic tyre]) {
    final n = '$num_'.trim().toUpperCase();
    if (n.isEmpty) return;
    final m = d['vehicles'] as Map;
    final v = (m[n] ?? {'owner': '', 'drivers': [], 'tyre': '12 Tyre'}) as Map;
    if ('${owner ?? ''}'.trim().isNotEmpty) v['owner'] = capWords(owner);
    if ('${tyre ?? ''}'.trim().isNotEmpty) v['tyre'] = '${tyre}'.trim();
    final dn = capWords(driver);
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

  String tyreRateKey(String date, String tyre) => '$date|$tyre';

  String rateFor(String date, [String? tyre]) {
    final rates = d['rates'] as Map;
    final ty = (tyre ?? '').trim();
    if (ty.isNotEmpty) {
      final tk = tyreRateKey(date, ty);
      if (rates[tk] != null && '${rates[tk]}'.trim().isNotEmpty) return '${rates[tk]}';
      final defTy = '${metaMap('tyreRates')[ty] ?? ''}';
      if (defTy.trim().isNotEmpty) return defTy;
    }
    return '${rates[date] ?? d['defRate'] ?? ''}';
  }

  Future<void> setTyreRate(String date, String tyre, String rate, {bool saveDefault = true}) async {
    final clean = rate.trim();
    if (clean.isEmpty) return;
    final rates = d['rates'] as Map;
    rates[tyreRateKey(date, tyre)] = clean;
    if (saveDefault) {
      metaMap('tyreRates')[tyre] = clean;
      d['defRate'] = clean;
    }
    await save();
  }

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
