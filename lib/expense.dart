import 'package:flutter/material.dart';
import 'pdf.dart';
import 'store.dart';
import 'ui.dart';

typedef Row_ = List<String> Function(Map<String, dynamic> r, int i);
typedef Str_ = String Function(Map<String, dynamic> r);

class ET {
  final String key, titleHi, titleEn;
  final IconData icon;
  final List<FD> Function() fields;
  final List<String> Function() cols;
  final List<double> w;
  final Row_ row;
  final Str_ tt, ts;
  final Hook? hook;
  ET(this.key, this.titleHi, this.titleEn, this.icon, this.fields, this.cols, this.w, this.row, this.tt, this.ts, {this.hook});
  String get title => S.tr(titleHi, titleEn);
}

FD _date() => FD('date', S.tr('दिनांक', 'Date'), 'date', req: true);
FD _time() => FD('time', S.tr('समय (वैकल्पिक)', 'Time (Optional)'), 'time');
FD _amt([String? l]) => FD('amount', l ?? S.tr('राशि (₹)', 'Amount (₹)'), 'num', req: true);
String _a(Map r) => rs(nv(r['amount']));
String _n(dynamic x) => '${x ?? ''}'.trim().isEmpty ? '-' : '$x';
String _t(Map r) => '${r['time'] ?? ''}'.isEmpty ? '-' : tShow(r['time']);

List<ET> ets = [
  ET(
    'jcb',
    'JCB',
    'JCB',
    Icons.construction,
    () => [
      FD('jcbName', S.tr('JCB / कंपनी का नाम', 'JCB / Company Name'), 'capWords', req: true),
      FD('kind', S.tr('किस लिए', 'Purpose'), 'pick', req: true, opts: (v) => ['Personal', 'Servicing', 'Other']),
      FD('paidToRole', S.tr('किसको दिया गया था', 'Paid To'), 'pick', req: true, opts: (v) => ['Owner', 'Operator', 'Helper']),
      FD('paidToName', S.tr('व्यक्ति का नाम', 'Person Name'), 'capWords'),
      _amt(),
      _date(),
      _time(),
      FD('note', S.tr('नोट (वैकल्पिक)', 'Note (Optional)'), 'note'),
    ],
    () => [S.tr('क्र.', '#'), 'JCB', S.tr('किस लिए', 'Purpose'), S.tr('किसको दिया', 'Paid To'), S.tr('राशि', 'Amount')],
    [28, 95, 85, 110, 62],
    (r, i) => [
      '${i + 1}',
      '${r['jcbName'] ?? r['company'] ?? '-'}',
      _n(r['kind']),
      '${_n(r['paidToRole'])}${_n(r['paidToName']) != '-' ? ' (${r['paidToName']})' : ''}',
      _a(r),
    ],
    (r) => '${r['jcbName'] ?? r['company'] ?? '-'} · ${_n(r['kind'])}',
    (r) => '${_n(r['paidToRole'])}${_n(r['paidToName']) != '-' ? ': ${r['paidToName']}' : ''} · ${_t(r)}',
  ),
  ET(
    'diesel',
    'डीजल',
    'Diesel',
    Icons.local_gas_station,
    () => [
      _date(),
      _time(),
      FD('litre', S.tr('डीजल की मात्रा (लीटर)', 'Diesel Quantity (Litre)'), 'num', req: true),
      FD('who', S.tr('डीजल लाने वाले का नाम', 'Brought By'), 'sug', opts: (v) => S.names('diesel')),
      _amt(),
    ],
    () => [S.tr('क्र.', '#'), S.tr('समय', 'Time'), S.tr('लीटर', 'Litre'), S.tr('लाने वाला', 'Brought By'), S.tr('राशि', 'Amount')],
    [24, 60, 60, 150, 60],
    (r, i) => ['${i + 1}', _t(r), '${r['litre']}', _n(r['who']), _a(r)],
    (r) => '${r['litre']} ${S.tr('लीटर', 'Litre')}',
    (r) => '${S.tr('लाने वाला', 'By')}: ${_n(r['who'])}',
  ),
  ET(
    'media',
    'मीडिया',
    'Media',
    Icons.mic,
    () => [_date(), _time(), FD('people', S.tr('लोग', 'People'), 'people'), _amt(S.tr('कुल राशि (₹)', 'Total Amount (₹)'))],
    () => [S.tr('क्र.', '#'), S.tr('समय', 'Time'), S.tr('लोग (नाम / चैनल)', 'People (Name / Channel)'), S.tr('राशि', 'Amount')],
    [24, 60, 280, 60],
    (r, i) => ['${i + 1}', _t(r), _people(r), _a(r)],
    (r) => '${r['cnt'] ?? 1} ${S.tr('लोग आए', 'People')}',
    (r) => _people(r),
  ),
  ET(
    'khana',
    'खाना',
    'Food / Khana',
    Icons.restaurant,
    () => [_date(), _time(), _amt(), FD('market', S.tr('बाज़ार / विवरण', 'Market / Details'), 'text')],
    () => [S.tr('क्र.', '#'), S.tr('समय', 'Time'), S.tr('बाज़ार', 'Market'), S.tr('राशि', 'Amount')],
    [24, 70, 250, 70],
    (r, i) => ['${i + 1}', _t(r), _n(r['market']), _a(r)],
    (r) => S.tr('खाना', 'Food'),
    (r) => _n(r['market']),
  ),
  ET(
    'besharam',
    'बेशरम वाला',
    'Besharam Wala',
    Icons.local_shipping,
    () => [
      _date(),
      _time(),
      FD('supplierName', S.tr('सप्लायर का नाम', 'Supplier Name'), 'sug', opts: (v) => S.suppliers().map((e) => '${e['name']}').toList()),
      FD('vehicle', S.tr('वाहन नंबर', 'Vehicle No.'), 'cap', req: true),
      FD('owner', S.tr('मालिक का नाम', 'Owner Name'), 'capWords'),
      FD('trip', S.tr('ट्रिप संख्या', 'Trip Count'), 'num', req: true),
      _amt(S.tr('कुल खर्च राशि (₹)', 'Total Expense (₹)')),
      FD('paid', S.tr('भुगतान की गई राशि (₹)', 'Paid Amount (₹)'), 'num'),
      FD('balance', S.tr('बाकी Balance (₹)', 'Balance (₹)'), 'num'),
      FD('payStatus', S.tr('भुगतान स्थिति', 'Payment Status'), 'pick', req: true, opts: (v) => ['Paid', 'Partial', 'Balance']),
    ],
    () => [S.tr('क्र.', '#'), S.tr('गाड़ी', 'Vehicle'), S.tr('ट्रिप', 'Trip'), S.tr('कुल', 'Total'), S.tr('दिया', 'Paid'), S.tr('बाकी', 'Balance')],
    [24, 86, 40, 56, 56, 56],
    (r, i) => [
      '${i + 1}',
      '${r['vehicle']}',
      '${r['trip'] ?? 1}',
      _a(r),
      rs(nv(r['paid'])),
      rs(nv(r['amount']) - nv(r['paid'])),
    ],
    (r) => '${r['vehicle']} · ${_n(r['supplierName'] ?? r['owner'])} (${S.tr('ट्रिप', 'Trip')}: ${r['trip'] ?? 1})',
    (r) => '${r['payStatus'] ?? ''} · ${S.tr('दिया', 'Paid')} ${rs(nv(r['paid']))} · ${S.tr('बाकी', 'Bal')} ${rs(nv(r['amount']) - nv(r['paid']))}',
    hook: (k, v, set) {
      if (k == 'supplierName') {
        final sup = S.suppliers().cast<Map<String, dynamic>?>().firstWhere(
              (e) => '${e?['name']}'.toLowerCase() == '${v['supplierName']}'.trim().toLowerCase(),
              orElse: () => null,
            );
        if (sup != null) {
          set('vehicle', '${sup['vehicle'] ?? ''}');
          set('owner', '${sup['name'] ?? ''}');
        }
      }
      vehHook(k, v, set, drivers: false);
      if (k == 'payStatus') {
        final a = nv(v['amount']);
        if (v['payStatus'] == 'Paid') {
          set('paid', fmtN(a));
          set('balance', '0');
        } else if (v['payStatus'] == 'Balance') {
          set('paid', '0');
          set('balance', fmtN(a));
        }
      }
      if (k == 'amount' || k == 'paid') {
        set('balance', fmtN(nv(v['amount']) - nv(v['paid'])));
      }
    },
  ),
  ET(
    'majduri',
    'मजदूरी',
    'Wages / Majduri',
    Icons.engineering,
    () => [_date(), _time(), _amt()],
    () => [S.tr('क्र.', '#'), S.tr('समय', 'Time'), S.tr('राशि', 'Amount')],
    [30, 120, 80],
    (r, i) => ['${i + 1}', _t(r), _a(r)],
    (r) => S.tr('मजदूरी', 'Wages'),
    (r) => _t(r),
  ),
  ET(
    'gaon',
    'गाँव फंड',
    'Village Fund',
    Icons.account_balance,
    () => [_date(), _time(), FD('name', S.tr('नाम', 'Name'), 'capWords', req: true), _amt()],
    () => [S.tr('क्र.', '#'), S.tr('समय', 'Time'), S.tr('नाम', 'Name'), S.tr('राशि', 'Amount')],
    [24, 70, 250, 70],
    (r, i) => ['${i + 1}', _t(r), _n(r['name']), _a(r)],
    (r) => '${r['name']}',
    (r) => '${S.tr('गाँव फंड', 'Village Fund')} · ${_t(r)}',
  ),
  ET(
    'other',
    'अन्य खर्च',
    'Other Expense',
    Icons.more_horiz,
    () => [
      _date(),
      _time(),
      FD('name', S.tr('नाम', 'Name'), 'capWords', req: true),
      FD('village', S.tr('गाँव का नाम', 'Village Name'), 'capWords'),
      _amt(),
      FD('post', S.tr('पद का नाम (यदि हो)', 'Designation (If any)'), 'capWords'),
    ],
    () => [S.tr('क्र.', '#'), S.tr('समय', 'Time'), S.tr('नाम', 'Name'), S.tr('गाँव', 'Village'), S.tr('पद', 'Post'), S.tr('राशि', 'Amount')],
    [24, 55, 110, 90, 80, 55],
    (r, i) => ['${i + 1}', _t(r), _n(r['name']), _n(r['village']), _n(r['post']), _a(r)],
    (r) => '${r['name']}',
    (r) => '${_n(r['village'])} · ${_n(r['post'])}',
  ),
];

String _people(Map r) {
  final ps = ((r['people'] ?? []) as List).take((r['cnt'] ?? 1) as int);
  final s = ps.where((p) => '${p['n']}${p['c']}'.trim().isNotEmpty).map((p) => '${_n(p['n'])} (${_n(p['c'])})').join(', ');
  return s.isEmpty ? '${r['cnt'] ?? 1} ${S.tr('लोग', 'People')}' : s;
}

Future<void> openExpense(BuildContext ctx, ET t, [Map<String, dynamic>? old]) async {
  final init = <String, dynamic>{...?old};
  if (old == null) init.addAll({'date': dkey(DateTime.now()), 'time': tnow(), 'cnt': 1});
  await Navigator.push(
    ctx,
    MaterialPageRoute(
      builder: (_) => FormPage(
        title: '${t.title} ${S.tr('खर्च', 'Expense')}',
        fields: t.fields(),
        init: init,
        hook: t.hook,
        onSave: (c, v) async {
          final r = Map<String, dynamic>.from(v);
          r['type'] = t.key;
          if (t.key == 'jcb') {
            r['jcbName'] = capWords(r['jcbName']);
            r['paidToName'] = capWords(r['paidToName']);
          }
          if (t.key == 'diesel') S.addName('diesel', r['who']);
          if (t.key == 'besharam') {
            r['vehicle'] = '${r['vehicle'] ?? ''}'.trim().toUpperCase();
            r['owner'] = capWords(r['owner']);
            r['supplierName'] = capWords(r['supplierName']);
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
        title: '${t.title} ${S.tr('खर्च सूची', 'Expense List')}',
        pdfName: 'kharch_${t.key}',
        source: () => S.list('expense').where((r) => r['type'] == t.key).toList(),
        cols: t.cols(),
        w: t.w,
        row: t.row,
        notes: (l) => ['${S.tr('कुल खर्च', 'Total Expense')}: ${rs(l.fold<num>(0, (a, r) => a + nv(r['amount'])))}'],
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
        S.tr('खर्च', 'Expenses'),
        ListView(padding: const EdgeInsets.all(16), children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.32,
            children: [
              for (final t in ets)
                bigBtn(
                  t.title,
                  t.icon,
                  () {
                    if (t.key == 'jcb') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const JcbButtonPage()));
                    } else if (t.key == 'besharam') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BesharamSupplierPage()));
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseList(t)));
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
          bigBtn(S.tr('खर्च स्टेटमेंट', 'Expense Statement'), Icons.summarize, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpStatement())), dark: false),
          const SizedBox(height: 12),
          bigBtn(S.tr('बेशरम वाला Balance Statement', 'Besharam Wala Balance Statement'), Icons.account_balance_wallet, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BesharamBal())), dark: false),
        ]),
      );
}

class JcbButtonPage extends StatefulWidget {
  const JcbButtonPage({super.key});
  @override
  State<JcbButtonPage> createState() => _JcbButtonPageState();
}

class _JcbButtonPageState extends State<JcbButtonPage> {
  Future<void> _addJcbDialog() async {
    final coCtl = TextEditingController();
    final op1Ctl = TextEditingController();
    final op2Ctl = TextEditingController();
    final hp1Ctl = TextEditingController();
    final extraOps = <TextEditingController>[];
    final extraHps = <TextEditingController>[];

    await showDialog(
      context: context,
      builder: (dc) => StatefulBuilder(
        builder: (sc, setSt) => AlertDialog(
          title: Text(S.tr('JCB जोड़ें', 'Add JCB')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                aboveBox(S.tr('कंपनी का नाम', 'Company Name'), TextField(controller: coCtl, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next, decoration: dec())),
                aboveBox(S.tr('पहला ऑपरेटर', '1st Operator'), TextField(controller: op1Ctl, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next, decoration: dec())),
                aboveBox(S.tr('दूसरा ऑपरेटर', '2nd Operator'), TextField(controller: op2Ctl, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next, decoration: dec())),
                for (var i = 0; i < extraOps.length; i++)
                  aboveBox(
                    '${S.tr('अतिरिक्त ऑपरेटर', 'Extra Operator')} ${i + 3}',
                    TextField(controller: extraOps[i], textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next, decoration: dec()),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setSt(() => extraOps.add(TextEditingController())),
                    icon: const Icon(Icons.add),
                    label: Text(S.tr('नया ऑपरेटर जोड़ें', 'Add New Operator')),
                  ),
                ),
                aboveBox(S.tr('पहला हेल्पर', '1st Helper'), TextField(controller: hp1Ctl, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next, decoration: dec())),
                for (var i = 0; i < extraHps.length; i++)
                  aboveBox(
                    '${S.tr('अतिरिक्त हेल्पर', 'Extra Helper')} ${i + 2}',
                    TextField(controller: extraHps[i], textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next, decoration: dec()),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setSt(() => extraHps.add(TextEditingController())),
                    icon: const Icon(Icons.add),
                    label: Text(S.tr('नया हेल्पर जोड़ें', 'Add New Helper')),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dc), child: Text(S.tr('रद्द करें', 'Cancel'))),
            FilledButton(
              onPressed: () async {
                final co = capWords(coCtl.text);
                if (co.isEmpty) return;
                final ops = [op1Ctl.text, op2Ctl.text, for (final c in extraOps) c.text].map(capWords).where((e) => e.isNotEmpty).toList();
                final hps = [hp1Ctl.text, for (final c in extraHps) c.text].map(capWords).where((e) => e.isNotEmpty).toList();
                await S.saveJcb({'company': co, 'operators': ops, 'helpers': hps});
                if (dc.mounted) Navigator.pop(dc);
              },
              child: Text(S.tr('सेव करें', 'Save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openJcbEntry(Map<String, dynamic> jcb) async {
    final co = '${jcb['company']}';
    final ops = ((jcb['operators'] ?? []) as List).map((e) => '$e').toList();
    final hps = ((jcb['helpers'] ?? []) as List).map((e) => '$e').toList();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormPage(
          title: '$co · ${S.tr('खर्च एंट्री', 'Expense Entry')}',
          fields: [
            FD('date', S.tr('दिनांक', 'Date'), 'date', req: true),
            FD('amount', S.tr('राशि (₹)', 'Amount (₹)'), 'num', req: true),
            FD('paidToRole', S.tr('किसको दिया गया था', 'Paid To'), 'pick', req: true, opts: (v) => ['Owner', 'Operator', 'Helper']),
            FD(
              'paidToName',
              S.tr('व्यक्ति चुनें / लिखें', 'Select / Enter Person'),
              'sug',
              show: (v) => v['paidToRole'] == 'Operator' || v['paidToRole'] == 'Helper',
              opts: (v) => v['paidToRole'] == 'Operator' ? ops : hps,
            ),
            FD('kind', S.tr('किस लिए', 'Purpose'), 'pick', req: true, opts: (v) => ['Personal', 'Servicing', 'Other']),
            FD('note', S.tr('नोट (वैकल्पिक)', 'Note (Optional)'), 'note'),
          ],
          init: {'date': dkey(DateTime.now()), 'time': tnow(), 'jcbId': jcb['id'], 'jcbName': co, 'paidToRole': 'Operator', 'kind': 'Servicing'},
          onSave: (c, v) async {
            final r = Map<String, dynamic>.from(v);
            r['type'] = 'jcb';
            r['jcbId'] = jcb['id'];
            r['jcbName'] = co;
            r['paidToName'] = capWords(r['paidToName']);
            await S.upsert('expense', r);
            return null;
          },
        ),
      ),
    );
  }

  void _openJcbSheet(Map<String, dynamic> jcb, List<Map<String, dynamic>> recs) {
    final co = '${jcb['company']}';
    final total = recs.fold<num>(0, (a, r) => a + nv(r['amount']));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBg,
      builder: (bc) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('$co  (${S.tr('कुल खर्च', 'Total')}: ${rs(total)})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kBrown)),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kBrown, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  Navigator.pop(bc);
                  _openJcbEntry(jcb);
                },
                icon: const Icon(Icons.add),
                label: Text(S.tr('नई JCB खर्च एंट्री करें', 'Add JCB Expense')),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(bc);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => _SingleJcbHistoryPage(jcb: jcb)));
                },
                icon: const Icon(Icons.list_alt),
                label: Text('${S.tr('खर्च लिस्ट देखें', 'View Expense List')} (${recs.length})'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(bc);
                  final sec = Sec(
                    '$co (${S.tr('कुल खर्च', 'Total')}: ${rs(total)})',
                    [S.tr('क्र.', '#'), S.tr('दिनांक', 'Date'), S.tr('किस लिए', 'Purpose'), S.tr('किसको दिया', 'Paid To'), S.tr('राशि', 'Amount')],
                    const [28, 80, 85, 115, 65],
                    [
                      for (var i = 0; i < recs.length; i++)
                        [
                          '${i + 1}',
                          dShow(recs[i]['date']),
                          _n(recs[i]['kind']),
                          '${_n(recs[i]['paidToRole'])}${_n(recs[i]['paidToName']) != '-' ? ' (${recs[i]['paidToName']})' : ''}',
                          rs(nv(recs[i]['amount'])),
                        ]
                    ],
                    ['${S.tr('कुल खर्च', 'Total Expense')}: ${rs(total)}'],
                  );
                  openPdfPreview(context, name: 'jcb_$co', title: '$co · JCB ${S.tr('खर्च रिपोर्ट', 'Expense Report')}', sub: S.tr('सभी एंट्री', 'All Entries'), secs: [sec]);
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(S.tr('PDF प्रीव्यू और बनाएं', 'PDF Preview & Generate')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (_, __) {
          final jcbList = S.jcbs();
          final allExp = S.list('expense').where((r) => r['type'] == 'jcb').toList();
          return Pg(
            'JCB ${S.tr('खर्च', 'Expenses')}',
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (jcbList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: Text(S.tr('नीचे + बटन से JCB जोड़ें', 'Tap + below to add a JCB'), style: const TextStyle(color: kBrown, fontSize: 15))),
                  ),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    for (final j in jcbList) ...[
                      Builder(builder: (_) {
                        final recs = allExp.where((e) => e['jcbId'] == j['id'] || '${e['jcbName']}'.toLowerCase() == '${j['company']}'.toLowerCase()).toList();
                        final sum = recs.fold<num>(0, (a, r) => a + nv(r['amount']));
                        return bigBtn(
                          '${j['company']}',
                          Icons.construction,
                          () => _openJcbSheet(j, recs),
                          dark: true,
                          subtitle: '${S.tr('कुल खर्च', 'Total')}: ${rs(sum)}',
                        );
                      }),
                    ],
                  ],
                ),
              ],
            ),
            fab: FloatingActionButton.extended(
              backgroundColor: kBrown,
              foregroundColor: Colors.white,
              onPressed: _addJcbDialog,
              icon: const Icon(Icons.add),
              label: Text(S.tr('JCB जोड़ें', 'Add JCB')),
            ),
          );
        },
      );
}

class _SingleJcbHistoryPage extends StatelessWidget {
  final Map<String, dynamic> jcb;
  const _SingleJcbHistoryPage({required this.jcb});

  @override
  Widget build(BuildContext context) {
    final co = '${jcb['company']}';
    return RecordList(
      title: '$co · ${S.tr('खर्च लिस्ट', 'Expense List')}',
      pdfName: 'jcb_list_$co',
      source: () => S.list('expense').where((r) => r['type'] == 'jcb' && (r['jcbId'] == jcb['id'] || '${r['jcbName']}'.toLowerCase() == co.toLowerCase())).toList(),
      cols: [S.tr('क्र.', '#'), S.tr('किस लिए', 'Purpose'), S.tr('किसको दिया', 'Paid To'), S.tr('राशि', 'Amount')],
      w: const [30, 100, 140, 75],
      row: (r, i) => [
        '${i + 1}',
        _n(r['kind']),
        '${_n(r['paidToRole'])}${_n(r['paidToName']) != '-' ? ' (${r['paidToName']})' : ''}',
        _a(r),
      ],
      notes: (l) => ['${S.tr('कुल खर्च', 'Total Expense')}: ${rs(l.fold<num>(0, (a, r) => a + nv(r['amount'])))}'],
      tTitle: (r) => '${_n(r['kind'])} · ${_a(r)}',
      tSub: (r) => '${S.tr('किसको दिया', 'Paid To')}: ${_n(r['paidToRole'])}${_n(r['paidToName']) != '-' ? ' (${r['paidToName']})' : ''}',
      tAmt: _a,
      edit: (r) async {
        await openExpense(context, ets.firstWhere((e) => e.key == 'jcb'), r);
      },
      del: (r) => S.remove('expense', r['id']),
    );
  }
}

class BesharamSupplierPage extends StatefulWidget {
  const BesharamSupplierPage({super.key});
  @override
  State<BesharamSupplierPage> createState() => _BesharamSupplierPageState();
}

class _BesharamSupplierPageState extends State<BesharamSupplierPage> {
  Future<void> _addSupplierDialog() async {
    final nameCtl = TextEditingController();
    final vehCtl = TextEditingController();
    final drvCtl = TextEditingController();
    final mobCtl = TextEditingController();
    final vilCtl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dc) => AlertDialog(
        title: Text(S.tr('सप्लायर जोड़ें', 'Add Supplier')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              aboveBox(S.tr('नाम (सप्लायर नाम)', 'Supplier Name'), TextField(controller: nameCtl, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next, decoration: dec()), req: true),
              aboveBox(
                S.tr('वाहन नंबर', 'Vehicle No.'),
                TextField(
                  controller: vehCtl,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration: dec(),
                  onChanged: (s) {
                    final u = s.toUpperCase();
                    if (u != s) vehCtl.value = TextEditingValue(text: u, selection: TextSelection.collapsed(offset: u.length));
                  },
                ),
                req: true,
              ),
              aboveBox(S.tr('ड्राइवर का नाम', 'Driver Name'), TextField(controller: drvCtl, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next, decoration: dec())),
              aboveBox(S.tr('मोबाइल नंबर', 'Mobile Number'), TextField(controller: mobCtl, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next, decoration: dec())),
              aboveBox(S.tr('गाँव का नाम (वैकल्पिक)', 'Village Name (Optional)'), TextField(controller: vilCtl, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.done, decoration: dec())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dc), child: Text(S.tr('रद्द करें', 'Cancel'))),
          FilledButton(
            onPressed: () async {
              if (nameCtl.text.trim().isEmpty || vehCtl.text.trim().isEmpty) return;
              await S.saveSupplier({
                'name': nameCtl.text,
                'vehicle': vehCtl.text,
                'driver': drvCtl.text,
                'mobile': mobCtl.text,
                'village': vilCtl.text,
              });
              if (dc.mounted) Navigator.pop(dc);
            },
            child: Text(S.tr('सेव करें', 'Save')),
          ),
        ],
      ),
    );
  }

  Future<void> _openSupplierEntry(Map<String, dynamic> sup) async {
    final supName = '${sup['name']}';
    final veh = '${sup['vehicle']}'.toUpperCase();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormPage(
          title: '$supName ($veh)',
          fields: [
            FD('date', S.tr('दिनांक', 'Date'), 'date', req: true),
            FD('time', S.tr('समय', 'Time'), 'time', req: true),
            FD('trip', S.tr('ट्रिप (Trip)', 'Trip'), 'num', req: true),
            FD('amount', S.tr('राशि (Amount ₹)', 'Amount (₹)'), 'num', req: true),
            FD('paid', S.tr('भुगतान की गई राशि (₹)', 'Paid Amount (₹)'), 'num'),
            FD('balance', S.tr('बाकी (Balance ₹)', 'Balance (₹)'), 'num'),
            FD('payStatus', S.tr('भुगतान स्थिति', 'Payment Status'), 'pick', req: true, opts: (v) => ['Paid', 'Partial', 'Balance']),
          ],
          init: {
            'date': dkey(DateTime.now()),
            'time': tnow(),
            'supplierId': sup['id'],
            'supplierName': supName,
            'vehicle': veh,
            'owner': supName,
            'trip': '1',
            'payStatus': 'Balance',
            'paid': '0',
            'balance': '0',
          },
          hook: (k, v, set) {
            final amt = nv(v['amount']);
            if (k == 'payStatus') {
              if (v['payStatus'] == 'Paid') {
                set('paid', fmtN(amt));
                set('balance', '0');
              } else if (v['payStatus'] == 'Balance') {
                set('paid', '0');
                set('balance', fmtN(amt));
              }
            }
            if (k == 'amount' || k == 'paid') {
              set('balance', fmtN(nv(v['amount']) - nv(v['paid'])));
            }
          },
          onSave: (c, v) async {
            final r = Map<String, dynamic>.from(v);
            r['type'] = 'besharam';
            r['supplierId'] = sup['id'];
            r['supplierName'] = supName;
            r['vehicle'] = veh;
            r['owner'] = supName;
            await S.upsert('expense', r);
            return null;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (_, __) {
          final sups = S.suppliers();
          final exp = S.list('expense').where((r) => r['type'] == 'besharam').toList();
          return Pg(
            '${S.tr('बेशरम वाला', 'Besharam Wala')} · ${S.tr('सप्लायर', 'Suppliers')}',
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (sups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: Text(S.tr('नीचे + बटन से सप्लायर जोड़ें', 'Tap + below to add supplier'), style: const TextStyle(color: kBrown, fontSize: 15))),
                  ),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    for (final sp in sups) ...[
                      Builder(builder: (_) {
                        final rows = exp.where((e) => e['supplierId'] == sp['id'] || '${e['vehicle']}'.toUpperCase() == '${sp['vehicle']}'.toUpperCase()).toList();
                        final totBal = rows.fold<num>(0, (a, r) => a + (nv(r['amount']) - nv(r['paid'])));
                        return bigBtn(
                          '${sp['name']}',
                          Icons.local_shipping,
                          () => _openSupplierEntry(sp),
                          dark: false,
                          subtitle: '${sp['vehicle']} · ${S.tr('बाकी', 'Bal')}: ${rs(totBal)}',
                        );
                      }),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BesharamBal())),
                  icon: const Icon(Icons.account_balance_wallet),
                  label: Text(S.tr('Balance Statement देखें', 'View Balance Statement')),
                ),
              ],
            ),
            fab: FloatingActionButton.extended(
              backgroundColor: kBrown,
              foregroundColor: Colors.white,
              onPressed: _addSupplierDialog,
              icon: const Icon(Icons.add),
              label: Text(S.tr('सप्लायर जोड़ें', 'Add Supplier')),
            ),
          );
        },
      );
}

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

  Sec daySec(String k, Map<String, num> d) => Sec(
        dShow(k),
        [S.tr('खर्च का प्रकार', 'Expense Type'), S.tr('राशि', 'Amount')],
        const [300, 100],
        [for (final t in ets) [t.title, rs(d[t.key] ?? 0)]],
        ['${S.tr('कुल खर्च', 'Total Expense')}: ${rs(tot(d))}'],
      );

  List<Sec> _buildSecs(Map<String, Map<String, num>> m) {
    final ks = m.keys.toList()..sort();
    final secs = <Sec>[];
    if (ks.length > 1) {
      secs.add(Sec(
        S.tr('सारांश – दिनांकवार कुल खर्च', 'Summary – Date-wise Total'),
        [S.tr('दिनांक', 'Date'), S.tr('कुल खर्च', 'Total')],
        const [300, 100],
        [for (final k in ks) [dShow(k), rs(tot(m[k]!))]],
        ['${S.tr('कुल योग', 'Grand Total')}: ${rs(m.values.fold<num>(0, (a, d) => a + tot(d)))}'],
      ));
    }
    for (final k in ks) {
      secs.add(daySec(k, m[k]!));
    }
    return secs;
  }

  Future<void> pdf() async {
    final m = data();
    if (m.isEmpty) return;
    await openPdfPreview(context, name: 'expense_statement_${rng.tag}', title: S.tr('खर्च स्टेटमेंट', 'Expense Statement'), sub: rng.sub, secs: _buildSecs(m));
  }

  Future<void> csv() async {
    final m = data();
    final ks = m.keys.toList()..sort();
    if (ks.isEmpty) return;
    await guard(
      context,
      () => shareCsv(
        'expense_statement_${rng.tag}',
        [S.tr('दिनांक', 'Date'), for (final t in ets) t.title, S.tr('कुल', 'Total')],
        [for (final k in ks) [dShow(k), for (final t in ets) fmtN(m[k]![t.key] ?? 0), fmtN(tot(m[k]!))]],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (_, __) {
          final m = data();
          final ks = m.keys.toList()..sort((a, b) => b.compareTo(a));
          return Pg(
            S.tr('खर्च स्टेटमेंट', 'Expense Statement'),
            Column(children: [
              RngBar(rng, () => setState(() {})),
              Expanded(
                child: ks.isEmpty
                    ? Center(child: Text(S.tr('कोई रिकॉर्ड नहीं', 'No records')))
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
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Text(S.tr('कुल खर्च', 'Total Expense'), style: const TextStyle(fontWeight: FontWeight.w700)),
                                      Text(rs(tot(m[k]!)), style: const TextStyle(fontWeight: FontWeight.w700)),
                                    ]),
                                  ]),
                                  actions: [
                                    TextButton(onPressed: () => openPdfPreview(context, name: 'expense_$k', title: S.tr('खर्च स्टेटमेंट', 'Expense Statement'), sub: dShow(k), secs: [daySec(k, m[k]!)]), child: Text(S.tr('इस दिन का PDF', 'Day PDF'))),
                                    TextButton(onPressed: () => Navigator.pop(dc), child: Text(S.tr('बंद करें', 'Close'))),
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

class BesharamBal extends StatelessWidget {
  const BesharamBal({super.key});

  Map<String, Map<String, dynamic>> calc() {
    final m = <String, Map<String, dynamic>>{};
    Map<String, dynamic> g(String v) => m.putIfAbsent(v, () => {'owner': '', 'total': 0.0, 'paid': 0.0, 'last': '', 'hist': <List<String>>[]});
    for (final r in S.list('expense').where((r) => r['type'] == 'besharam')) {
      final x = g('${r['vehicle']}');
      x['owner'] = '${r['supplierName'] ?? r['owner'] ?? ''}';
      x['total'] += nv(r['amount']).toDouble();
      x['paid'] += nv(r['paid']).toDouble();
      if ('${r['date']}'.compareTo(x['last']) > 0 && nv(r['paid']) > 0) x['last'] = '${r['date']}';
      x['hist'].add(['${r['date']}', '${S.tr('ट्रिप', 'Trip')} ${r['trip'] ?? 1} · ${S.tr('खर्च', 'Exp')} ${rs(nv(r['amount']))}${nv(r['paid']) > 0 ? ' / ${S.tr('दिया', 'Paid')} ${rs(nv(r['paid']))}' : ''}']);
    }
    for (final p in S.list('bpay')) {
      final x = g('${p['vehicle']}');
      x['paid'] += nv(p['amount']).toDouble();
      if ('${p['date']}'.compareTo(x['last']) > 0) x['last'] = '${p['date']}';
      x['hist'].add(['${p['date']}', '${S.tr('भुगतान', 'Payment')} ${rs(nv(p['amount']))} (${p['mode']})${'${p['note'] ?? ''}'.isEmpty ? '' : ' - ${p['note']}'}']);
    }
    return m;
  }

  String status(Map x) => x['paid'] <= 0 ? 'Unpaid' : (x['total'] - x['paid'] <= 0 ? 'Paid' : 'Partial');

  Sec sec(String v, Map x) {
    final h = (x['hist'] as List<List<String>>)..sort((a, b) => a[0].compareTo(b[0]));
    final bal = x['total'] - x['paid'];
    return Sec(
      '${S.tr('वाहन', 'Vehicle')}: $v  (${_n(x['owner'])})',
      [S.tr('दिनांक', 'Date'), S.tr('विवरण', 'Details')],
      const [120, 380],
      [for (final e in h) [dShow(e[0]), e[1]]],
      [
        '${S.tr('कुल खर्च', 'Total')}: ${rs(x['total'])}   ${S.tr('कुल भुगतान', 'Paid')}: ${rs(x['paid'])}   ${S.tr('बाकी', 'Balance')}: ${rs(bal)}',
        '${S.tr('स्थिति', 'Status')}: ${status(x)}${status(x) == 'Paid' && x['last'] != '' ? '   Paid Date: ${dShow(x['last'])}' : ''}',
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (_, __) {
          final m = calc();
          final ks = m.keys.toList()..sort();
          return Pg(
            '${S.tr('बेशरम वाला', 'Besharam Wala')} Balance',
            ListView(padding: const EdgeInsets.all(16), children: [
              if (ks.isEmpty) Padding(padding: const EdgeInsets.all(30), child: Center(child: Text(S.tr('कोई रिकॉर्ड नहीं', 'No records')))),
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
                        Text('${S.tr('कुल', 'Total')} ${rs(m[v]!['total'])} · ${S.tr('भुगतान', 'Paid')} ${rs(m[v]!['paid'])}', style: const TextStyle(color: kBrown)),
                        Text('${S.tr('बाकी', 'Bal')} ${rs(m[v]!['total'] - m[v]!['paid'])} · ${status(m[v]!)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
            ]),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: ks.isEmpty
                    ? null
                    : () => openPdfPreview(
                          context,
                          name: 'besharam_balance',
                          title: '${S.tr('बेशरम वाला', 'Besharam Wala')} Balance Statement',
                          sub: S.tr('सभी वाहन', 'All Vehicles'),
                          secs: [for (final v in ks) sec(v, m[v]!)],
                        ),
              ),
            ],
            fab: FloatingActionButton.extended(
              backgroundColor: kBrown,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.payments),
              label: Text(S.tr('भुगतान जोड़ें', 'Add Payment')),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FormPage(
                    title: S.tr('बाकी भुगतान एंट्री', 'Balance Payment Entry'),
                    fields: [
                      FD('vehicle', S.tr('वाहन नंबर', 'Vehicle No.'), 'sug', req: true, opts: (v) => m.keys.toList()),
                      FD('owner', S.tr('मालिक / सप्लायर नाम', 'Owner / Supplier'), 'capWords'),
                      FD('amount', S.tr('भुगतान राशि (₹)', 'Payment Amount (₹)'), 'num', req: true),
                      FD('date', S.tr('भुगतान दिनांक', 'Payment Date'), 'date', req: true),
                      FD('mode', S.tr('भुगतान का माध्यम', 'Payment Mode'), 'pick', req: true, opts: (v) => ['Cash', 'Online']),
                      FD('note', S.tr('नोट (वैकल्पिक)', 'Note (Optional)'), 'note'),
                    ],
                    init: {'date': dkey(DateTime.now()), 'mode': 'Cash'},
                    hook: (k, v, set) => vehHook(k, v, set, drivers: false),
                    onSave: (c, v) async {
                      final r = Map<String, dynamic>.from(v);
                      r['vehicle'] = '${r['vehicle'] ?? ''}'.trim().toUpperCase();
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
            for (final e in ([...(x['hist'] as List<List<String>>)]..sort((a, b) => b[0].compareTo(a[0]))))
              Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text('${dShow(e[0])}\n${e[1]}')),
            if (pays.isNotEmpty) const Divider(),
            for (final p in pays)
              Row(children: [
                Expanded(child: Text('${dShow(p['date'])} · ${rs(nv(p['amount']))}')),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await S.remove('bpay', p['id']);
                    if (dc.mounted) Navigator.pop(dc);
                  },
                ),
              ]),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => openPdfPreview(
              c,
              name: 'besharam_$v',
              title: '${S.tr('बेशरम वाला', 'Besharam Wala')} Balance Statement',
              sub: v,
              secs: [sec(v, x)],
            ),
            child: const Text('PDF'),
          ),
          TextButton(onPressed: () => Navigator.pop(dc), child: Text(S.tr('बंद करें', 'Close'))),
        ],
      ),
    );
  }
}

class AllExpensesList extends StatelessWidget {
  final int initialMode;
  final DateTime? initialDate;
  const AllExpensesList({super.key, this.initialMode = 2, this.initialDate});

  ET _etOf(Map<String, dynamic> r) => ets.firstWhere((e) => e.key == r['type'], orElse: () => ets.last);

  @override
  Widget build(BuildContext context) => RecordList(
        title: S.tr('सभी खर्च सूची', 'All Expenses List'),
        pdfName: 'expense_all',
        initialMode: initialMode,
        initialDate: initialDate,
        source: () => S.list('expense'),
        cols: [S.tr('क्र.', '#'), S.tr('प्रकार', 'Type'), S.tr('विवरण', 'Details'), S.tr('समय', 'Time'), S.tr('राशि', 'Amount')],
        w: const [24, 80, 175, 55, 65],
        row: (r, i) {
          final et = _etOf(r);
          return ['${i + 1}', et.title, '${et.tt(r)} (${et.ts(r)})', _t(r), _a(r)];
        },
        notes: (l) => ['${S.tr('कुल खर्च', 'Total Expense')}: ${rs(l.fold<num>(0, (a, r) => a + nv(r['amount'])))}'],
        tTitle: (r) {
          final et = _etOf(r);
          return '${et.title} · ${et.tt(r)}';
        },
        tSub: (r) => _etOf(r).ts(r),
        tAmt: _a,
        edit: (r) async {
          if (r == null) {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseHome()));
          } else {
            await openExpense(context, _etOf(r), r);
          }
        },
        del: (r) => S.remove('expense', r['id']),
      );
}
