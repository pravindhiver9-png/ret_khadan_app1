import 'package:flutter/material.dart';
import 'pdf.dart';
import 'store.dart';
import 'ui.dart';

typedef Row_ = List<String> Function(Map<String, dynamic> r, int i);
typedef Str_ = String Function(Map<String, dynamic> r);

class ET {
  final String key, title;
  final IconData icon;
  final List<FD> Function() fields;
  final List<String> cols;
  final List<double> w;
  final Row_ row;
  final Str_ tt, ts;
  final Hook? hook;
  ET(this.key, this.title, this.icon, this.fields, this.cols, this.w, this.row, this.tt, this.ts, {this.hook});
}

FD _date() => FD('date', 'दिनांक', 'date', req: true);
FD _time() => FD('time', 'समय (वैकल्पिक)', 'time');
FD _amt([String l = 'राशि (₹)']) => FD('amount', l, 'num', req: true);
String _a(Map r) => rs(nv(r['amount']));
String _n(dynamic x) => '${x ?? ''}'.trim().isEmpty ? '-' : '$x';
String _t(Map r) => '${r['time'] ?? ''}'.isEmpty ? '-' : tShow(r['time']);

List<ET> ets = [
  ET(
    'jcb', 'JCB', Icons.construction,
    () {
      List<String> ppl(Map<String, dynamic> v) => S.names('jcbPeople');
      return [
        FD('company', 'JCB कंपनी / नाम', 'sug', req: true, opts: (v) => S.names('jcbCo')),
        FD('owner', 'JCB मालिक का नाम', 'text'),
        FD('op1', 'पहला ऑपरेटर', 'sug', opts: ppl),
        FD('op2', 'दूसरा ऑपरेटर', 'sug', opts: ppl),
        FD('op3', 'तीसरा ऑपरेटर', 'sug', opts: ppl),
        FD('h1', 'पहला हेल्पर', 'sug', opts: ppl),
        FD('h2', 'दूसरा हेल्पर', 'sug', opts: ppl),
        FD('kind', 'खर्च का प्रकार', 'pick', req: true, opts: (v) => ['JCB Service', 'Operator Personal', 'JCB किराया']),
        _amt(),
        FD('paid', 'किसको पैसा दिया', 'multi', opts: (v) => [
              if ('${v['owner'] ?? ''}'.trim().isNotEmpty) 'JCB मालिक',
              for (final k in ['op1', 'op2', 'op3']) if ('${v[k] ?? ''}'.trim().isNotEmpty) 'ऑपरेटर: ${v[k]}',
              for (final k in ['h1', 'h2']) if ('${v[k] ?? ''}'.trim().isNotEmpty) 'हेल्पर: ${v[k]}',
            ]),
        _date(), _time(),
      ];
    },
    ['क्र.', 'JCB', 'मालिक', 'प्रकार', 'किसे दिया', 'राशि'],
    [24, 70, 70, 80, 130, 50],
    (r, i) => ['${i + 1}', '${r['company']}', _n(r['owner']), _n(r['kind']), ((r['paid'] ?? []) as List).isEmpty ? '-' : ((r['paid']) as List).join(', '), _a(r)],
    (r) => '${r['company']} · ${r['kind']}',
    (r) => ((r['paid'] ?? []) as List).join(', '),
    hook: (k, v, set) {
      if (k == 'company') {
        final o = S.metaMap('jcbOwners')['${v['company']}'];
        if (o != null) set('owner', o);
      }
    },
  ),
  ET(
    'diesel', 'Diesel', Icons.local_gas_station,
    () => [_date(), _time(), FD('litre', 'डीजल की मात्रा (लीटर)', 'num', req: true), FD('who', 'डीजल लाने वाले का नाम', 'sug', opts: (v) => S.names('diesel')), _amt()],
    ['क्र.', 'समय', 'लीटर', 'लाने वाला', 'राशि'],
    [24, 60, 60, 150, 60],
    (r, i) => ['${i + 1}', _t(r), '${r['litre']}', _n(r['who']), _a(r)],
    (r) => '${r['litre']} लीटर',
    (r) => 'लाने वाला: ${_n(r['who'])}',
  ),
  ET(
    'media', 'Media', Icons.mic,
    () => [_date(), _time(), FD('people', 'लोग', 'people'), _amt('कुल राशि (₹)')],
    ['क्र.', 'समय', 'लोग (नाम / चैनल)', 'राशि'],
    [24, 60, 280, 60],
    (r, i) => ['${i + 1}', _t(r), _people(r), _a(r)],
    (r) => '${r['cnt'] ?? 1} लोग आए',
    (r) => _people(r),
  ),
  ET(
    'khana', 'Khana', Icons.restaurant,
    () => [_date(), _time(), _amt(), FD('market', 'बाज़ार / विवरण', 'text')],
    ['क्र.', 'समय', 'बाज़ार', 'राशि'],
    [24, 70, 250, 70],
    (r, i) => ['${i + 1}', _t(r), _n(r['market']), _a(r)],
    (r) => 'खाना',
    (r) => _n(r['market']),
  ),
  ET(
    'besharam', 'बेशरम वाला', Icons.local_shipping,
    () => [
      _date(), _time(),
      FD('vehicle', 'वाहन नंबर', 'sug', req: true, opts: (v) => S.vehicleNames()),
      FD('owner', 'मालिक का नाम', 'text'),
      _amt('कुल खर्च राशि (₹)'),
      FD('paid', 'भुगतान की गई राशि (₹)', 'num'),
      FD('balance', 'बाकी Balance (₹)', 'num'),
    ],
    ['क्र.', 'गाड़ी', 'मालिक', 'कुल', 'दिया', 'बाकी'],
    [24, 90, 110, 55, 55, 55],
    (r, i) => ['${i + 1}', '${r['vehicle']}', _n(r['owner']), _a(r), rs(nv(r['paid'])), rs(nv(r['amount']) - nv(r['paid']))],
    (r) => '${r['vehicle']} · ${_n(r['owner'])}',
    (r) => 'दिया ${rs(nv(r['paid']))} · बाकी ${rs(nv(r['amount']) - nv(r['paid']))}',
    hook: (k, v, set) {
      vehHook(k, v, set, drivers: false);
      if (k == 'amount' || k == 'paid') set('balance', fmtN(nv(v['amount']) - nv(v['paid'])));
    },
  ),
  ET(
    'majduri', 'मजदूरी', Icons.engineering,
    () => [_date(), _time(), _amt()],
    ['क्र.', 'समय', 'राशि'],
    [30, 120, 80],
    (r, i) => ['${i + 1}', _t(r), _a(r)],
    (r) => 'मजदूरी',
    (r) => _t(r),
  ),
  ET(
    'gaon', 'गाँव फंड', Icons.account_balance,
    () => [_date(), _time(), FD('name', 'नाम', 'text', req: true), _amt()],
    ['क्र.', 'समय', 'नाम', 'राशि'],
    [24, 70, 250, 70],
    (r, i) => ['${i + 1}', _t(r), _n(r['name']), _a(r)],
    (r) => '${r['name']}',
    (r) => 'गाँव फंड · ${_t(r)}',
  ),
  ET(
    'other', 'अन्य खर्च', Icons.more_horiz,
    () => [_date(), _time(), FD('name', 'नाम', 'text', req: true), FD('village', 'गाँव का नाम', 'text'), _amt(), FD('post', 'पद का नाम (यदि हो)', 'text')],
    ['क्र.', 'समय', 'नाम', 'गाँव', 'पद', 'राशि'],
    [24, 55, 110, 90, 80, 55],
    (r, i) => ['${i + 1}', _t(r), _n(r['name']), _n(r['village']), _n(r['post']), _a(r)],
    (r) => '${r['name']}',
    (r) => '${_n(r['village'])} · ${_n(r['post'])}',
  ),
];

String _people(Map r) {
  final ps = ((r['people'] ?? []) as List).take((r['cnt'] ?? 1) as int);
  final s = ps.where((p) => '${p['n']}${p['c']}'.trim().isNotEmpty).map((p) => '${_n(p['n'])} (${_n(p['c'])})').join(', ');
  return s.isEmpty ? '${r['cnt'] ?? 1} लोग' : s;
}

Future<void> openExpense(BuildContext ctx, ET t, [Map<String, dynamic>? old]) async {
  final init = <String, dynamic>{...?old};
  if (old == null) init.addAll({'date': dkey(DateTime.now()), 'time': tnow(), 'cnt': 1});
  await Navigator.push(
    ctx,
    MaterialPageRoute(
      builder: (_) => FormPage(
        title: '${t.title} खर्च',
        fields: t.fields(),
        init: init,
        hook: t.hook,
        onSave: (c, v) async {
          final r = Map<String, dynamic>.from(v);
          r['type'] = t.key;
          if (t.key == 'jcb') {
            S.addName('jcbCo', r['company']);
            S.metaMap('jcbOwners')['${r['company']}'] = '${r['owner'] ?? ''}';
            for (final k in ['op1', 'op2', 'op3', 'h1', 'h2']) {
              S.addName('jcbPeople', r[k]);
            }
          }
          if (t.key == 'diesel') S.addName('diesel', r['who']);
          if (t.key == 'besharam') {
            r['vehicle'] = '${r['vehicle']}'.trim().toUpperCase();
            S.saveVehicle(r['vehicle'], r['owner'], '', '');
          }
          await S.upsert('expense', r);
          return null;
        },
      ),
    ),
  );
}

class ExpenseList extends StatelessWidget {
  final ET t;
  const ExpenseList(this.t, {super.key});
  @override
  Widget build(BuildContext context) => RecordList(
        title: '${t.title} खर्च सूची',
        pdfName: 'kharch_${t.key}',
        source: () => S.list('expense').where((r) => r['type'] == t.key).toList(),
        cols: t.cols,
        w: t.w,
        row: t.row,
        notes: (l) => ['कुल खर्च: ${rs(l.fold<num>(0, (a, r) => a + nv(r['amount'])))}'],
        tTitle: t.tt,
        tSub: t.ts,
        tAmt: _a,
        edit: (r) => openExpense(context, t, r),
        del: (r) => S.remove('expense', r['id']),
      );
}

class ExpenseHome extends StatelessWidget {
  const ExpenseHome({super.key});
  @override
  Widget build(BuildContext context) => Pg(
        'खर्च',
        ListView(padding: const EdgeInsets.all(16), children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [for (final t in ets) bigBtn(t.title, t.icon, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseList(t))))],
          ),
          const SizedBox(height: 14),
          bigBtn('खर्च स्टेटमेंट', Icons.summarize, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpStatement())), dark: false),
          const SizedBox(height: 12),
          bigBtn('बेशरम वाला Balance Statement', Icons.account_balance_wallet, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BesharamBal())), dark: false),
        ]),
      );
}

// ---------------- Expense statement ----------------
class ExpStatement extends StatefulWidget {
  const ExpStatement({super.key});
  @override
  State<ExpStatement> createState() => _ES();
}

class _ES extends State<ExpStatement> {
  final rng = Rng();

  Map<String, Map<String, num>> data() {
    final m = <String, Map<String, num>>{};
    for (final r in S.list('expense')) {
      if (!rng.ok(r['date'])) continue;
      final d = m.putIfAbsent('${r['date']}', () => {});
      d['${r['type']}'] = (d['${r['type']}'] ?? 0) + nv(r['amount']);
    }
    return m;
  }

  num tot(Map<String, num> d) => d.values.fold<num>(0, (a, b) => a + b);

  Sec daySec(String k, Map<String, num> d) =>
      Sec(dShow(k), ['खर्च का प्रकार', 'राशि'], const [300, 100], [for (final t in ets) [t.title, rs(d[t.key] ?? 0)]], ['कुल खर्च: ${rs(tot(d))}']);

  Future<void> pdf() async {
    final m = data();
    if (m.isEmpty) return;
    final ks = m.keys.toList()..sort();
    final secs = <Sec>[];
    if (ks.length > 1) {
      secs.add(Sec('सारांश – दिनांकवार कुल खर्च', ['दिनांक', 'कुल खर्च'], const [300, 100], [for (final k in ks) [dShow(k), rs(tot(m[k]!))]], ['कुल योग: ${rs(m.values.fold<num>(0, (a, d) => a + tot(d)))}']));
    }
    for (final k in ks) {
      secs.add(daySec(k, m[k]!));
    }
    await guard(context, () => sharePdf('expense_statement_${rng.tag}', 'खर्च स्टेटमेंट', rng.sub, secs));
  }

  Future<void> csv() async {
    final m = data();
    final ks = m.keys.toList()..sort();
    if (ks.isEmpty) return;
    await guard(context, () => shareCsv('expense_statement_${rng.tag}', ['दिनांक', for (final t in ets) t.title, 'कुल'], [for (final k in ks) [dShow(k), for (final t in ets) fmtN(m[k]![t.key] ?? 0), fmtN(tot(m[k]!))]]));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (_, __) {
          final m = data();
          final ks = m.keys.toList()..sort((a, b) => b.compareTo(a));
          return Pg(
            'खर्च स्टेटमेंट',
            Column(children: [
              RngBar(rng, () => setState(() {})),
              Expanded(
                child: ks.isEmpty
                    ? const Center(child: Text('कोई रिकॉर्ड नहीं'))
                    : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
                        for (final k in ks)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => showDialog(
                                context: context,
                                builder: (dc) => AlertDialog(
                                  title: Text(dShow(k)),
                                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                                    for (final t in ets) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t.title), Text(rs(m[k]![t.key] ?? 0))]),
                                    const Divider(),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('कुल खर्च', style: TextStyle(fontWeight: FontWeight.w700)), Text(rs(tot(m[k]!)), style: const TextStyle(fontWeight: FontWeight.w700))]),
                                  ]),
                                  actions: [
                                    TextButton(onPressed: () => guard(context, () => sharePdf('expense_$k', 'खर्च स्टेटमेंट', dShow(k), [daySec(k, m[k]!)])), child: const Text('इस दिन का PDF')),
                                    TextButton(onPressed: () => Navigator.pop(dc), child: const Text('बंद करें')),
                                  ],
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: neo(r: 18),
                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text(dShow(k), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                  Text(rs(tot(m[k]!)), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                ]),
                              ),
                            ),
                          ),
                      ]),
              ),
            ]),
            actions: [
              IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: pdf),
              IconButton(icon: const Icon(Icons.table_chart), onPressed: csv),
            ],
          );
        },
      );
}

// ---------------- Besharam balance statement ----------------
class BesharamBal extends StatelessWidget {
  const BesharamBal({super.key});

  Map<String, Map<String, dynamic>> calc() {
    final m = <String, Map<String, dynamic>>{};
    Map<String, dynamic> g(String v) => m.putIfAbsent(v, () => {'owner': '', 'total': 0.0, 'paid': 0.0, 'last': '', 'hist': <List<String>>[]});
    for (final r in S.list('expense').where((r) => r['type'] == 'besharam')) {
      final x = g('${r['vehicle']}');
      x['owner'] = '${r['owner'] ?? ''}';
      x['total'] += nv(r['amount']).toDouble();
      x['paid'] += nv(r['paid']).toDouble();
      if ('${r['date']}'.compareTo(x['last']) > 0 && nv(r['paid']) > 0) x['last'] = '${r['date']}';
      x['hist'].add(['${r['date']}', 'खर्च ${rs(nv(r['amount']))}${nv(r['paid']) > 0 ? ' / दिया ${rs(nv(r['paid']))}' : ''}']);
    }
    for (final p in S.list('bpay')) {
      final x = g('${p['vehicle']}');
      x['paid'] += nv(p['amount']).toDouble();
      if ('${p['date']}'.compareTo(x['last']) > 0) x['last'] = '${p['date']}';
      x['hist'].add(['${p['date']}', 'भुगतान ${rs(nv(p['amount']))} (${p['mode']})${'${p['note'] ?? ''}'.isEmpty ? '' : ' - ${p['note']}'}']);
    }
    return m;
  }

  String status(Map x) => x['paid'] <= 0 ? 'Unpaid' : (x['total'] - x['paid'] <= 0 ? 'Paid' : 'Partial');

  Sec sec(String v, Map x) {
    final h = (x['hist'] as List<List<String>>)..sort((a, b) => a[0].compareTo(b[0]));
    final bal = x['total'] - x['paid'];
    return Sec(
      'वाहन: $v  (${_n(x['owner'])})',
      ['दिनांक', 'विवरण'],
      const [120, 380],
      [for (final e in h) [dShow(e[0]), e[1]]],
      ['कुल खर्च: ${rs(x['total'])}   कुल भुगतान: ${rs(x['paid'])}   बाकी: ${rs(bal)}', 'स्थिति: ${status(x)}${status(x) == 'Paid' && x['last'] != '' ? '   Paid Date: ${dShow(x['last'])}' : ''}'],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (_, __) {
          final m = calc();
          final ks = m.keys.toList()..sort();
          return Pg(
            'बेशरम वाला Balance',
            ListView(padding: const EdgeInsets.all(16), children: [
              if (ks.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('कोई रिकॉर्ड नहीं'))),
              for (final v in ks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => _hist(context, v, m[v]!),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: neo(r: 18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('$v · ${_n(m[v]!['owner'])}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('कुल ${rs(m[v]!['total'])} · भुगतान ${rs(m[v]!['paid'])}', style: const TextStyle(color: kBrown)),
                        Text('बाकी ${rs(m[v]!['total'] - m[v]!['paid'])} · ${status(m[v]!)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
            ]),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: ks.isEmpty ? null : () => guard(context, () => sharePdf('besharam_balance', 'बेशरम वाला Balance Statement', 'सभी वाहन', [for (final v in ks) sec(v, m[v]!)])),
              ),
            ],
            fab: FloatingActionButton.extended(
              backgroundColor: kBrown,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.payments),
              label: const Text('भुगतान जोड़ें'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FormPage(
                    title: 'बाकी भुगतान एंट्री',
                    fields: [
                      FD('vehicle', 'वाहन नंबर', 'sug', req: true, opts: (v) => m.keys.toList()),
                      FD('owner', 'मालिक का नाम', 'text'),
                      FD('amount', 'भुगतान राशि (₹)', 'num', req: true),
                      FD('date', 'भुगतान दिनांक', 'date', req: true),
                      FD('mode', 'भुगतान का माध्यम', 'pick', req: true, opts: (v) => ['Cash', 'Online']),
                      FD('note', 'नोट (वैकल्पिक)', 'note'),
                    ],
                    init: {'date': dkey(DateTime.now()), 'mode': 'Cash'},
                    hook: (k, v, set) => vehHook(k, v, set, drivers: false),
                    onSave: (c, v) async {
                      final r = Map<String, dynamic>.from(v);
                      r['vehicle'] = '${r['vehicle']}'.trim().toUpperCase();
                      await S.upsert('bpay', r);
                      return null;
                    },
                  ),
                ),
              ),
            ),
          );
        },
      );

  void _hist(BuildContext c, String v, Map x) {
    final pays = S.list('bpay').where((p) => '${p['vehicle']}' == v).toList();
    showDialog(
      context: c,
      builder: (dc) => AlertDialog(
        title: Text(v),
        content: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final e in ([...(x['hist'] as List<List<String>>)]..sort((a, b) => b[0].compareTo(a[0])))) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text('${dShow(e[0])}\n${e[1]}')),
            if (pays.isNotEmpty) const Divider(),
            for (final p in pays)
              Row(children: [
                Expanded(child: Text('${dShow(p['date'])} · ${rs(nv(p['amount']))}')),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { await S.remove('bpay', p['id']); if (dc.mounted) Navigator.pop(dc); }),
              ]),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => guard(c, () => sharePdf('besharam_$v', 'बेशरम वाला Balance Statement', v, [sec(v, x)])), child: const Text('PDF')),
          TextButton(onPressed: () => Navigator.pop(dc), child: const Text('बंद करें')),
        ],
      ),
    );
  }
}
