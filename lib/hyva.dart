import 'package:flutter/material.dart';
import 'pdf.dart';
import 'store.dart';
import 'ui.dart';

Future<void> askDailyRate(BuildContext ctx) async {
  final t = dkey(DateTime.now());
  if ((S.d['rates'] as Map)[t] != null) return;
  final c = TextEditingController(text: '${S.d['defRate']}');
  await showDialog(
    context: ctx,
    barrierDismissible: false,
    builder: (dc) => AlertDialog(
      title: const Text('आज की लोडिंग दर'),
      content: TextField(controller: c, keyboardType: TextInputType.number, decoration: dec('लोडिंग दर (₹)')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dc), child: const Text('बाद में')),
        FilledButton(
          onPressed: () {
            if (c.text.trim().isNotEmpty) {
              (S.d['rates'] as Map)[t] = c.text.trim();
              S.d['defRate'] = c.text.trim();
              S.save();
            }
            Navigator.pop(dc);
          },
          child: const Text('सेव'),
        ),
      ],
    ),
  );
}

bool _st(Map v, List<String> s) => s.contains(v['status']);

List<FD> hyvaFields() => [
      FD('date', 'दिनांक', 'date', req: true),
      FD('time', 'समय', 'time', req: true),
      FD('rate', 'लोडिंग दर (₹)', 'num'),
      FD('vehicle', 'गाड़ी नंबर', 'sug', req: true, opts: (v) => S.vehicleNames()),
      FD('owner', 'गाड़ी मालिक का नाम', 'text', req: true),
      FD('driver', 'ड्राइवर का नाम', 'sug', opts: (v) => S.driversOf(v['vehicle'] ?? '').map((e) => '${e['n']}').toList()),
      FD('mobile', 'ड्राइवर मोबाइल नंबर', 'phone'),
      FD('amount', 'अंतिम तय रकम – Amount (₹)', 'num', req: true),
      FD('roy', 'रॉयल्टी चाहिए?', 'check'),
      FD('r_sec', 'रॉयल्टी विवरण', 'sec', show: (v) => v['roy'] == true),
      FD('r_mine', 'खदान का नाम', 'sug', show: (v) => v['roy'] == true, opts: (v) => S.names('mine')),
      FD('r_qty', 'खनिज की मात्रा (घन मीटर m³)', 'num', req: true, show: (v) => v['roy'] == true),
      FD('r_time', 'रॉयल्टी काटने का समय', 'time', req: true, show: (v) => v['roy'] == true),
      FD('r_dest', 'कहाँ जाएगी (Destination)', 'sug', req: true, show: (v) => v['roy'] == true, opts: (v) => S.names('dest')),
      FD('r_giver', 'रॉयल्टी काटने वाले का नाम', 'sug', show: (v) => v['roy'] == true, opts: (v) => S.names('cutter')),
      FD('r_recv', 'रॉयल्टी प्राप्तकर्ता का नाम (वैकल्पिक)', 'sug', show: (v) => v['roy'] == true, opts: (v) => S.names('recv')),
      FD('r_photo', 'रॉयल्टी फोटो (वैकल्पिक)', 'photo', show: (v) => v['roy'] == true),
      FD('r_amount', 'रॉयल्टी रकम (₹)', 'num', req: true, show: (v) => v['roy'] == true),
      FD('mode', 'भुगतान का माध्यम', 'pick', req: true, opts: (v) => ['Cash', 'Online']),
      FD('onlineTo', 'किसको Online किया?', 'text', show: (v) => v['mode'] == 'Online'),
      FD('status', 'भुगतान की स्थिति', 'pick', req: true, opts: (v) => ['Paid', 'Partial', 'Balance', 'Free']),
      FD('received', 'प्राप्त रकम (₹)', 'num', show: (v) => _st(v, ['Partial'])),
      FD('balance', 'बाकी रकम – Balance (₹)', 'num', show: (v) => _st(v, ['Partial', 'Balance'])),
      FD('dalal', 'गाड़ी भेजने वाले का नाम (वैकल्पिक)', 'sug', opts: (v) => S.names('dalal')),
      FD('note', 'नोट (FREE हो तो कारण ज़रूर लिखें)', 'note'),
      FD('photo', 'हाइवा फोटो (वैकल्पिक)', 'photo'),
    ];

Future<void> openHyva(BuildContext ctx, [Map<String, dynamic>? old]) async {
  final isNew = old == null;
  final init = <String, dynamic>{...?old};
  if (isNew) {
    final t = dkey(DateTime.now());
    init.addAll({'date': t, 'time': tnow(), 'rate': S.rateFor(t), 'rate0': S.rateFor(t), 'status': 'Paid', 'mode': 'Cash', 'roy': false});
  } else {
    final o = old!;
    init['rate0'] = o['rate'];
    final lk = S.list('royalty').where((x) => x['hyvaId'] == o['id']).toList();
    if (lk.isNotEmpty) {
      final x = lk.first;
      init.addAll({'roy': true, 'r_mine': x['mine'], 'r_qty': x['qty'], 'r_time': x['time'], 'r_dest': x['dest'], 'r_giver': x['giver'], 'r_recv': x['receiver'], 'r_photo': x['photo'], 'r_amount': x['amount']});
    }
  }
  await Navigator.push(
    ctx,
    MaterialPageRoute(
      builder: (_) => FormPage(
        title: isNew ? 'हाइवा एंट्री' : 'हाइवा एडिट',
        fields: hyvaFields(),
        init: init,
        hook: (k, v, set) {
          vehHook(k, v, set);
          if (k == 'date' && isNew) {
            set('rate', S.rateFor('${v['date']}'));
            set('rate0', S.rateFor('${v['date']}'));
          }
          if (['amount', 'status', 'received'].contains(k)) {
            final a = nv(v['amount']);
            switch (v['status']) {
              case 'Paid':
                set('received', fmtN(a));
                set('balance', '0');
                break;
              case 'Partial':
                set('balance', fmtN(a - nv(v['received'])));
                break;
              case 'Balance':
                set('received', '0');
                set('balance', fmtN(a));
                break;
              case 'Free':
                set('received', '0');
                set('balance', '0');
                if ('${v['amount'] ?? ''}'.isEmpty) set('amount', '0');
                break;
            }
          }
        },
        onSave: _saveHyva,
      ),
    ),
  );
}

Future<String?> _saveHyva(BuildContext c, Map<String, dynamic> v) async {
  if (v['status'] == 'Free' && '${v['note'] ?? ''}'.trim().isEmpty) return 'FREE का कारण Note में लिखें';
  if ('${v['rate'] ?? ''}'.trim().isNotEmpty && nv(v['rate']) != nv(v['rate0'])) {
    final ch = await showDialog<String>(
      context: c,
      builder: (dc) => AlertDialog(
        title: const Text('लोडिंग दर बदली गई'),
        content: Text('नई दर ₹${v['rate']} कैसे लागू करें?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dc, 'one'), child: const Text('सिर्फ इस गाड़ी के लिए')),
          FilledButton(onPressed: () => Navigator.pop(dc, 'always'), child: const Text('हमेशा के लिए')),
        ],
      ),
    );
    if (ch == null) return 'लोडिंग दर का विकल्प चुनें';
    if (ch == 'always') {
      S.d['defRate'] = '${v['rate']}'.trim();
      (S.d['rates'] as Map)['${v['date']}'] = S.d['defRate'];
    }
  }
  final r = Map<String, dynamic>.from(v)..remove('rate0');
  final up = '${r['vehicle']}'.trim().toUpperCase();
  r['vehicle'] = up;
  r['id'] ??= S.newId();
  final rid = r['id'] as String;
  S.saveVehicle(up, r['owner'], r['driver'], r['mobile']);
  S.addName('dalal', r['dalal']);
  final old = S.list('royalty').where((x) => x['hyvaId'] == rid).toList();
  if (r['roy'] == true) {
    final ro = old.isNotEmpty ? old.first : <String, dynamic>{'hyvaId': rid, 'serial': S.takeSerial()};
    ro.addAll({
      'date': r['date'], 'time': r['r_time'], 'mine': r['r_mine'], 'qty': r['r_qty'], 'vehicle': up, 'owner': r['owner'],
      'driver': r['driver'], 'mobile': r['mobile'], 'receiver': r['r_recv'], 'dest': r['r_dest'], 'giver': r['r_giver'],
      'photo': r['r_photo'], 'amount': r['r_amount'],
    });
    S.addName('mine', r['r_mine']);
    S.addName('dest', r['r_dest']);
    S.addName('cutter', r['r_giver']);
    S.addName('recv', r['r_recv']);
    await S.upsert('royalty', ro);
  } else if (old.isNotEmpty) {
    (S.d['royalty'] as List).removeWhere((e) => e['hyvaId'] == rid);
  }
  await S.upsert('hyva', r);
  return null;
}

String _bal(Map r) => (r['status'] == 'Partial' || r['status'] == 'Balance') ? rs(nv(r['balance'])) : '-';
String _n(dynamic x) => '${x ?? ''}'.trim().isEmpty ? '-' : '$x';

const _cols = ['क्र.', 'गाड़ी नंबर', 'मालिक', 'ड्राइवर', 'मोबाइल', 'राशि', 'भेजने वाला', 'स्थिति', 'बाकी'];
const _w = <double>[24, 70, 62, 56, 58, 44, 46, 40, 44];

List<String> hyvaRow(Map<String, dynamic> r, int i) =>
    ['${i + 1}', '${r['vehicle']}', _n(r['owner']), _n(r['driver']), _n(r['mobile']), rs(nv(r['amount'])), _n(r['dalal']), '${r['status']}', _bal(r)];

List<String> hyvaNotes(List> l) {
  final nf = l.where((r) => r['status'] != 'Free');
  return ['कुल राशि: ${rs(nf.fold<num>(0, (a, r) => a + nv(r['amount'])))}   |   कुल बाकी: ${rs(nf.fold<num>(0, (a, r) => a + nv(r['balance'])))}   |   गाड़ियाँ: ${l.length}'];
}

class HyvaList extends StatelessWidget {
  const HyvaList({super.key});
  @override
  Widget build(BuildContext context) => RecordList(
        title: 'हाइवा एंट्री लिस्ट',
        pdfName: 'hyva',
        source: () => S.list('hyva'),
        cols: _cols,
        w: _w,
        row: hyvaRow,
        notes: hyvaNotes,
        tTitle: (r) => '${r['vehicle']}',
        tSub: (r) => '${_n(r['owner'])} · ${r['status']}${_bal(r) != '-' ? ' · बाकी ${_bal(r)}' : ''}',
        tAmt: (r) => rs(nv(r['amount'])),
        edit: (r) => openHyva(context, r),
        del: (r) => S.remove('hyva', r['id']),
        extras: [
          IconButton(
            tooltip: 'Owner Wise Statement',
            icon: const Icon(Icons.groups),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerPage())),
          ),
        ],
      );
}

// ---------- Owner wise statement ----------
Map<String, List>> _byOwner() {
  final m = <String, List>>{};
  for (final r in S.list('hyva')) {
    m.putIfAbsent(_n(r['owner']), () => []).add(r);
  }
  return Map.fromEntries(m.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
}

Sec _ownerSec(String o, List> l) {
  final s = [...l]..sort((a, b) => '${a['date']}${a['time']}'.compareTo('${b['date']}${b['time']}'));
  return Sec(
    'मालिक: $o',
    ['क्र.', 'दिनांक', 'गाड़ी नंबर', 'ड्राइवर', 'मोबाइल', 'राशि', 'भेजने वाला', 'स्थिति', 'बाकी'],
    const [24, 62, 66, 56, 58, 44, 46, 40, 44],
    [for (var i = 0; i < s.length; i++) ['${i + 1}', dShow(s[i]['date']), '${s[i]['vehicle']}', _n(s[i]['driver']), _n(s[i]['mobile']), rs(nv(s[i]['amount'])), _n(s[i]['dalal']), '${s[i]['status']}', _bal(s[i])]],
    hyvaNotes(s),
  );
}

class OwnerPage extends StatelessWidget {
  const OwnerPage({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (_, __) {
          final m = _byOwner();
          return Pg(
            'Owner Wise Hyva Statement',
            m.isEmpty
                ? const Center(child: Text('कोई रिकॉर्ड नहीं'))
                : ListView(padding: const EdgeInsets.all(16), children: [
                    for (final e in m.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerDetail(e.key))),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: neo(r: 18),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                              const SizedBox(height: 4),
                              Text('कुल एंट्री ${e.value.length} · राशि ${rs(e.value.where((r) => r['status'] != 'Free').fold<num>(0, (a, r) => a + nv(r['amount'])))}', style: const TextStyle(color: kBrown)),
                              Text(
                                'Paid ${e.value.where((r) => r['status'] == 'Paid').length} · Partial ${e.value.where((r) => r['status'] == 'Partial').length} · Balance ${e.value.where((r) => r['status'] == 'Balance').length} · Free ${e.value.where((r) => r['status'] == 'Free').length}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text('बाकी: ${rs(e.value.where((r) => r['status'] != 'Free').fold<num>(0, (a, r) => a + nv(r['balance'])))}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      ),
                  ]),
            actions: [
              IconButton(
                tooltip: 'सभी मालिकों का PDF',
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => guard(context, () => sharePdf('hyva_owner_all', 'Owner Wise Hyva Statement', 'सभी मालिक', [for (final e in m.entries) _ownerSec(e.key, e.value)])),
              ),
            ],
          );
        },
      );
}

class OwnerDetail extends StatefulWidget {
  final String owner;
  const OwnerDetail(this.owner, {super.key});
  @override
  State<OwnerDetail> createState() => _OD();
}

class _OD extends State<OwnerDetail> {
  String f = 'सभी';
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (_, __) {
          final all = _byOwner()[widget.owner] ?? [];
          all.sort((a, b) => '${b['date']}${b['time']}'.compareTo('${a['date']}${a['time']}'));
          final l = f == 'सभी' ? all : all.where((r) => r['status'] == f).toList();
          return Pg(
            widget.owner,
            Column(children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(spacing: 8, children: [
                  for (final x in ['सभी', 'Paid', 'Partial', 'Balance', 'Free']) ChoiceChip(label: Text(x), selected: f == x, onSelected: (_) => setState(() => f = x)),
                ]),
              ),
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
                  for (final r in l)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: neo(r: 18),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${r['vehicle']} · ${dShow(r['date'])}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('${_n(r['driver'])} · ${r['status']}${_bal(r) != '-' ? ' · बाकी ${_bal(r)}' : ''}', style: const TextStyle(fontSize: 13, color: kBrown)),
                            ]),
                          ),
                          Text(rs(nv(r['amount'])), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  Text(hyvaNotes(all).first, style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => guard(context, () => sharePdf('hyva_owner', 'Owner Wise Hyva Statement', widget.owner, [_ownerSec(widget.owner, all)])),
              ),
            ],
          );
        },
      );
}
