import 'package:flutter/material.dart';
import 'pdf.dart';
import 'store.dart';
import 'ui.dart';

Future<void> openTyreRateDialog(BuildContext ctx, {bool onlyIfUnset = false}) async {
  final today = dkey(DateTime.now());
  if (onlyIfUnset) {
    final anySet = tyreSizes.any((t) => '${(S.d['rates'] as Map)[S.tyreRateKey(today, t)] ?? ''}'.trim().isNotEmpty);
    if (anySet) return;
  }

  final controllers = {
    for (final t in tyreSizes) t: TextEditingController(text: S.rateFor(today, t)),
  };

  await showDialog(
    context: ctx,
    barrierDismissible: !onlyIfUnset,
    builder: (dc) => AlertDialog(
      title: Text('${S.tr('आज की लोडिंग दर', "Today's Loading Rate")} (${dShow(today)})'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in tyreSizes) ...[
              aboveBox(
                '$t ${S.tr('दर (₹)', 'Rate (₹)')}',
                TextField(
                  controller: controllers[t],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: dec(hint: '₹'),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dc), child: Text(S.tr('बंद करें', 'Close'))),
        FilledButton(
          onPressed: () async {
            for (final t in tyreSizes) {
              final val = controllers[t]!.text.trim();
              if (val.isNotEmpty) {
                await S.setTyreRate(today, t, val, saveDefault: true);
              }
            }
            if (dc.mounted) Navigator.pop(dc);
          },
          child: Text(S.tr('सेव करें', 'Save')),
        ),
      ],
    ),
  );
}

bool _st(Map v, List<String> s) => s.contains(v['status']);

List<FD> hyvaFields() => [
      FD('date', S.tr('दिनांक', 'Date'), 'date', req: true),
      FD('time', S.tr('समय', 'Time'), 'time', req: true),
      FD('tyre', S.tr('टायर चुनें', 'Select Tyre'), 'pick', req: true, opts: (v) => tyreSizes),
      FD('rate', S.tr('लोडिंग दर (₹)', 'Loading Rate (₹)'), 'num'),
      FD('vehicle', S.tr('गाड़ी नंबर', 'Vehicle No.'), 'cap', req: true),
      FD('owner', S.tr('गाड़ी मालिक का नाम', 'Owner Name'), 'capWords', req: true),
      FD('driver', S.tr('ड्राइवर का नाम', 'Driver Name'), 'sug', opts: (v) => S.driversOf(v['vehicle'] ?? '').map((e) => '${e['n']}').toList()),
      FD('mobile', S.tr('ड्राइवर मोबाइल नंबर', 'Driver Mobile'), 'phone'),
      FD('amount', S.tr('अंतिम तय रकम – Amount (₹)', 'Final Amount (₹)'), 'num', req: true),
      FD('roy', S.tr('रॉयल्टी चाहिए?', 'Royalty Required?'), 'check'),
      FD('r_sec', S.tr('रॉयल्टी विवरण', 'Royalty Details'), 'sec', show: (v) => v['roy'] == true),
      FD('r_no', S.tr('रॉयल्टी क्रमांक', 'Royalty Book No.'), 'text', req: true, show: (v) => v['roy'] == true, hint: S.tr('रॉयल्टी बुक का क्रमांक लिखें', 'Enter royalty serial no.')),
      FD('r_mine', S.tr('खदान का नाम', 'Mine Name'), 'sug', show: (v) => v['roy'] == true, opts: (v) => S.names('mine')),
      FD('r_qty', S.tr('खनिज की मात्रा (घन मीटर m³)', 'Quantity (m³)'), 'num', req: true, show: (v) => v['roy'] == true),
      FD('r_time', S.tr('रॉयल्टी काटने का समय', 'Royalty Time'), 'time', req: true, show: (v) => v['roy'] == true),
      FD('r_dest', S.tr('कहाँ जाएगी (Destination)', 'Destination'), 'sug', req: true, show: (v) => v['roy'] == true, opts: (v) => S.names('dest')),
      FD('r_giver', S.tr('रॉयल्टी काटने वाले का नाम', 'Royalty Issuer'), 'sug', show: (v) => v['roy'] == true, opts: (v) => S.names('cutter')),
      FD('r_recv', S.tr('रॉयल्टी प्राप्तकर्ता का नाम (वैकल्पिक)', 'Receiver Name (Optional)'), 'sug', show: (v) => v['roy'] == true, opts: (v) => S.names('recv')),
      FD('r_photo', S.tr('रॉयल्टी फोटो (वैकल्पिक)', 'Royalty Photo (Optional)'), 'photo', show: (v) => v['roy'] == true),
      FD('r_amount', S.tr('रॉयल्टी रकम (₹)', 'Royalty Amount (₹)'), 'num', req: true, show: (v) => v['roy'] == true),
      FD('mode', S.tr('भुगतान का माध्यम', 'Payment Mode'), 'pick', req: true, opts: (v) => ['Cash', 'Online']),
      FD('onlineTo', S.tr('किसको Online किया?', 'Online Paid To'), 'capWords', show: (v) => v['mode'] == 'Online'),
      FD('status', S.tr('भुगतान की स्थिति', 'Payment Status'), 'pick', req: true, opts: (v) => ['Paid', 'Partial', 'Balance', 'Free']),
      FD('received', S.tr('प्राप्त रकम (₹)', 'Received Amount (₹)'), 'num', show: (v) => _st(v, ['Partial'])),
      FD('balance', S.tr('बाकी रकम – Balance (₹)', 'Balance Amount (₹)'), 'num', show: (v) => _st(v, ['Partial', 'Balance'])),
      FD('dalal', S.tr('भेजने वाले का नाम (वैकल्पिक)', 'Sender / Bhejne Wala (Optional)'), 'sug', opts: (v) => S.names('dalal')),
      FD('note', S.tr('नोट (FREE हो तो कारण ज़रूर लिखें)', 'Note (Reason mandatory if FREE)'), 'note'),
      FD('photo', S.tr('हाइवा फोटो (वैकल्पिक)', 'Hyva Photo (Optional)'), 'photo'),
    ];

Future<void> openHyva(BuildContext ctx, [Map<String, dynamic>? old]) async {
  final isNew = old == null;
  final init = <String, dynamic>{...?old};
  if (isNew) {
    final t = dkey(DateTime.now());
    const defTyre = '12 Tyre';
    final r = S.rateFor(t, defTyre);
    init.addAll({
      'date': t,
      'time': tnow(),
      'tyre': defTyre,
      'rate': r,
      'rate0': r,
      'status': 'Paid',
      'mode': 'Cash',
      'roy': false,
    });
  } else {
    final o = old!;
    init['tyre'] ??= '12 Tyre';
    init['rate0'] = o['rate'];
    final lk = S.list('royalty').where((x) => x['hyvaId'] == o['id']).toList();
    if (lk.isNotEmpty) {
      final x = lk.first;
      init.addAll({
        'roy': true,
        'r_no': x['royaltyNo'] ?? x['serial'] ?? '',
        'r_mine': x['mine'],
        'r_qty': x['qty'],
        'r_time': x['time'],
        'r_dest': x['dest'],
        'r_giver': x['giver'],
        'r_recv': x['receiver'],
        'r_photo': x['photo'],
        'r_amount': x['amount'],
      });
    }
  }
  await Navigator.push(
    ctx,
    MaterialPageRoute(
      builder: (_) => FormPage(
        title: isNew ? S.tr('हाइवा एंट्री', 'Hyva Entry') : S.tr('हाइवा एडिट', 'Edit Hyva'),
        fields: hyvaFields(),
        init: init,
        hook: (k, v, set) {
          vehHook(k, v, set);
          if ((k == 'date' || k == 'tyre') && isNew) {
            final newRate = S.rateFor('${v['date']}', '${v['tyre'] ?? ''}');
            set('rate', newRate);
            set('rate0', newRate);
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
  if (v['status'] == 'Free' && '${v['note'] ?? ''}'.trim().isEmpty) {
    return S.tr('FREE का कारण Note में लिखें', 'Please enter reason in Note for FREE');
  }
  final tyre = '${v['tyre'] ?? '12 Tyre'}';
  if ('${v['rate'] ?? ''}'.trim().isNotEmpty && nv(v['rate']) != nv(v['rate0'])) {
    final ch = await showDialog<String>(
      context: c,
      builder: (dc) => AlertDialog(
        title: Text(S.tr('लोडिंग दर बदली गई', 'Loading Rate Changed')),
        content: Text('${S.tr('नई दर', 'New rate')} ₹${v['rate']} ($tyre) ${S.tr('कैसे लागू करें?', 'how to apply?')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dc, 'one'), child: Text(S.tr('सिर्फ इस गाड़ी के लिए', 'Only this vehicle'))),
          FilledButton(onPressed: () => Navigator.pop(dc, 'always'), child: Text(S.tr('हमेशा के लिए', 'Always for $tyre'))),
        ],
      ),
    );
    if (ch == null) return S.tr('लोडिंग दर का विकल्प चुनें', 'Choose loading rate option');
    if (ch == 'always') {
      await S.setTyreRate('${v['date']}', tyre, '${v['rate']}', saveDefault: true);
    }
  }
  final r = Map<String, dynamic>.from(v)..remove('rate0');
  final up = '${r['vehicle'] ?? ''}'.trim().toUpperCase();
  r['vehicle'] = up;
  r['tyre'] = tyre;
  r['owner'] = capWords(r['owner']);
  r['driver'] = capWords(r['driver']);
  r['dalal'] = capWords(r['dalal']);
  r['id'] ??= S.newId();
  final rid = r['id'] as String;
  S.saveVehicle(up, r['owner'], r['driver'], r['mobile'], tyre);
  S.addName('dalal', r['dalal']);
  final old = S.list('royalty').where((x) => x['hyvaId'] == rid).toList();
  if (r['roy'] == true) {
    final rNo = '${r['r_no'] ?? ''}'.trim().toUpperCase();
    final ro = old.isNotEmpty ? old.first : <String, dynamic>{'hyvaId': rid, 'serial': S.takeSerial()};
    ro.addAll({
      'royaltyNo': rNo,
      'date': r['date'],
      'time': r['r_time'],
      'mine': r['r_mine'],
      'qty': r['r_qty'],
      'tyre': tyre,
      'vehicle': up,
      'owner': r['owner'],
      'driver': r['driver'],
      'mobile': r['mobile'],
      'receiver': r['r_recv'],
      'dest': r['r_dest'],
      'giver': r['r_giver'],
      'photo': r['r_photo'],
      'amount': r['r_amount'],
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

List<String> _cols() => [
      S.tr('क्र.', '#'),
      S.tr('गाड़ी / टायर', 'Vehicle / Tyre'),
      S.tr('मालिक', 'Owner'),
      S.tr('ड्राइवर', 'Driver'),
      S.tr('मोबाइल', 'Mobile'),
      S.tr('राशि', 'Amount'),
      S.tr('भेजने वाला', 'Sender'),
      S.tr('स्थिति', 'Status'),
      S.tr('बाकी', 'Balance'),
    ];
const _w = <double>[24, 72, 60, 54, 56, 44, 48, 38, 44];

List<String> hyvaRow(Map<String, dynamic> r, int i) => [
      '${i + 1}',
      '${r['vehicle']}\n${r['tyre'] ?? ''}',
      _n(r['owner']),
      _n(r['driver']),
      _n(r['mobile']),
      rs(nv(r['amount'])),
      _n(r['dalal']),
      '${r['status']}',
      _bal(r),
    ];

List<String> hyvaNotes(List<Map<String, dynamic>> l) {
  final nf = l.where((r) => r['status'] != 'Free');
  final freeCount = l.where((r) => r['status'] == 'Free').length;
  return [
    '${S.tr('कुल राशि', 'Total Amount')}: ${rs(nf.fold<num>(0, (a, r) => a + nv(r['amount'])))}   |   ${S.tr('कुल बाकी', 'Total Balance')}: ${rs(nf.fold<num>(0, (a, r) => a + nv(r['balance'])))}   |   ${S.tr('गाड़ियाँ', 'Vehicles')}: ${l.length} (${S.tr('फ्री', 'Free')}: $freeCount)'
  ];
}

class HyvaList extends StatelessWidget {
  const HyvaList({super.key});
  @override
  Widget build(BuildContext context) => RecordList(
        title: S.tr('हाइवा एंट्री लिस्ट', 'Hyva Entry List'),
        pdfName: 'hyva',
        source: () => S.list('hyva'),
        cols: _cols(),
        w: _w,
        row: hyvaRow,
        notes: hyvaNotes,
        tTitle: (r) => '${r['vehicle']}  (${r['tyre'] ?? '-'})',
        tSub: (r) => '${_n(r['owner'])} · ${S.tr('भेजने वाला', 'Sender')}: ${_n(r['dalal'])} · ${r['status']}${_bal(r) != '-' ? ' · ${S.tr('बाकी', 'Bal')} ${_bal(r)}' : ''}',
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

Map<String, List<Map<String, dynamic>>> _byOwner() {
  final m = <String, List<Map<String, dynamic>>>{};
  for (final r in S.list('hyva')) {
    m.putIfAbsent(_n(r['owner']), () => []).add(r);
  }
  return Map.fromEntries(m.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
}

List<Sec> _ownerSecs(String o, List<Map<String, dynamic>> l) {
  final s = [...l]..sort((a, b) => '${a['date']}${a['time']}'.compareTo('${b['date']}${b['time']}'));
  final balRows = s.where((r) => r['status'] == 'Partial' || r['status'] == 'Balance').toList();
  final freeRows = s.where((r) => r['status'] == 'Free').toList();
  final vehiclesList = s.map((r) => '${r['vehicle']} (${r['tyre'] ?? '-'})').toSet().join(', ');

  final secs = <Sec>[
    Sec(
      '${S.tr('मालिक', 'Owner')}: $o  |  ${S.tr('वाहन', 'Vehicles')}: $vehiclesList',
      [
        S.tr('क्र.', '#'),
        S.tr('दिनांक', 'Date'),
        S.tr('गाड़ी / टायर', 'Vehicle / Tyre'),
        S.tr('ड्राइवर', 'Driver'),
        S.tr('राशि', 'Amount'),
        S.tr('भेजने वाला', 'Sender'),
        S.tr('स्थिति', 'Status'),
        S.tr('बाकी', 'Balance'),
      ],
      const [24, 60, 74, 54, 46, 50, 42, 46],
      [
        for (var i = 0; i < s.length; i++)
          [
            '${i + 1}',
            dShow(s[i]['date']),
            '${s[i]['vehicle']}\n${s[i]['tyre'] ?? ''}',
            _n(s[i]['driver']),
            rs(nv(s[i]['amount'])),
            _n(s[i]['dalal']),
            '${s[i]['status']}',
            _bal(s[i]),
          ]
      ],
      hyvaNotes(s),
    ),
  ];

  if (balRows.isNotEmpty) {
    secs.add(Sec(
      '$o — ${S.tr('बाकी भुगतान विवरण (Balance / Partial)', 'Balance & Partial Details')}',
      [S.tr('दिनांक', 'Date'), S.tr('गाड़ी', 'Vehicle'), S.tr('कुल राशि', 'Total'), S.tr('प्राप्त', 'Received'), S.tr('बाकी', 'Balance'), S.tr('स्थिति', 'Status')],
      const [72, 85, 65, 65, 65, 58],
      [
        for (final r in balRows)
          [
            dShow(r['date']),
            '${r['vehicle']}',
            rs(nv(r['amount'])),
            rs(nv(r['received'])),
            rs(nv(r['balance'])),
            '${r['status']}',
          ]
      ],
      ['${S.tr('कुल बाकी राशि', 'Total Pending Balance')}: ${rs(balRows.fold<num>(0, (a, r) => a + nv(r['balance'])))}'],
    ));
  }

  if (freeRows.isNotEmpty) {
    secs.add(Sec(
      '$o — ${S.tr('फ्री वाहन विवरण (Free Vehicles)', 'Free Vehicles Details')}',
      [S.tr('दिनांक', 'Date'), S.tr('समय', 'Time'), S.tr('गाड़ी / टायर', 'Vehicle / Tyre'), S.tr('ड्राइवर', 'Driver'), S.tr('कारण / नोट', 'Reason / Note')],
      const [72, 55, 95, 75, 133],
      [
        for (final r in freeRows)
          [
            dShow(r['date']),
            tShow(r['time']),
            '${r['vehicle']} (${r['tyre'] ?? '-'})',
            _n(r['driver']),
            _n(r['note']),
          ]
      ],
      ['${S.tr('कुल फ्री गाड़ियाँ', 'Total Free Vehicles')}: ${freeRows.length}'],
    ));
  }

  return secs;
}

class OwnerPage extends StatelessWidget {
  const OwnerPage({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (_, __) {
          final m = _byOwner();
          return Pg(
            S.tr('मालिक वार हाइवा स्टेटमेंट', 'Owner Wise Hyva Statement'),
            m.isEmpty
                ? Center(child: Text(S.tr('कोई रिकॉर्ड नहीं', 'No records')))
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
                              Text(
                                '${S.tr('वाहन', 'Vehicles')}: ${e.value.map((r) => '${r['vehicle']}').toSet().join(', ')}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kTxt),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${S.tr('कुल एंट्री', 'Entries')} ${e.value.length} · ${S.tr('राशि', 'Amt')} ${rs(e.value.where((r) => r['status'] != 'Free').fold<num>(0, (a, r) => a + nv(r['amount'])))}',
                                style: const TextStyle(color: kBrown),
                              ),
                              Text(
                                'Paid ${e.value.where((r) => r['status'] == 'Paid').length} · Partial ${e.value.where((r) => r['status'] == 'Partial').length} · Balance ${e.value.where((r) => r['status'] == 'Balance').length} · Free ${e.value.where((r) => r['status'] == 'Free').length}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                '${S.tr('बाकी', 'Balance')}: ${rs(e.value.where((r) => r['status'] != 'Free').fold<num>(0, (a, r) => a + nv(r['balance'])))}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ]),
                          ),
                        ),
                      ),
                  ]),
            actions: [
              IconButton(
                tooltip: S.tr('सभी मालिकों का PDF', 'All Owners PDF'),
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: m.isEmpty
                    ? null
                    : () => openPdfPreview(
                          context,
                          name: 'hyva_owner_all',
                          title: S.tr('मालिक वार हाइवा स्टेटमेंट', 'Owner Wise Hyva Statement'),
                          sub: S.tr('सभी मालिक', 'All Owners'),
                          secs: [for (final e in m.entries) ..._ownerSecs(e.key, e.value)],
                        ),
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
  String selectedVehicle = 'सभी';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (_, __) {
          final all = (_byOwner()[widget.owner] ?? []).map((e) => Map<String, dynamic>.from(e)).toList()
            ..sort((a, b) => '${b['date']}${b['time']}'.compareTo('${a['date']}${b['time']}'));
          final vehs = ['सभी', ...{for (final r in all) '${r['vehicle']}'}];
          final balList = all.where((r) => r['status'] == 'Partial' || r['status'] == 'Balance').toList();
          final freeList = all.where((r) => r['status'] == 'Free').toList();

          final l = all.where((r) {
            final okV = selectedVehicle == 'सभी' || '${r['vehicle']}' == selectedVehicle;
            final okS = f == 'सभी' || r['status'] == f;
            return okV && okS;
          }).toList();

          return Pg(
            widget.owner,
            ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 28), children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: neo(c: kCard, r: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${S.tr('इस मालिक की गाड़ियाँ', 'Vehicles Under Owner')} (${vehs.length - 1})', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final vh in vehs)
                      ChoiceChip(
                        label: Text(vh == 'सभी' ? S.tr('सभी वाहन', 'All Vehicles') : vh),
                        selected: selectedVehicle == vh,
                        onSelected: (_) => setState(() => selectedVehicle = vh),
                      ),
                  ]),
                ]),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                for (final x in ['सभी', 'Paid', 'Partial', 'Balance', 'Free'])
                  ChoiceChip(
                    label: Text(x == 'सभी' ? S.tr('सभी स्थिति', 'All Status') : x),
                    selected: f == x,
                    onSelected: (_) => setState(() => f = x),
                  ),
              ]),
              const SizedBox(height: 10),
              for (final r in l)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: neo(r: 18),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${r['vehicle']} (${r['tyre'] ?? '-'}) · ${dShow(r['date'])}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('${_n(r['driver'])} · ${S.tr('भेजने वाला', 'Sender')}: ${_n(r['dalal'])} · ${r['status']}${_bal(r) != '-' ? ' · ${_bal(r)}' : ''}',
                              style: const TextStyle(fontSize: 13, color: kBrown)),
                          if (r['status'] == 'Free' && '${r['note'] ?? ''}'.isNotEmpty)
                            Text('${S.tr('कारण', 'Reason')}: ${r['note']}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      Text(rs(nv(r['amount'])), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: neo(r: 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    '${S.tr('बाकी भुगतान विवरण', 'Balance Payment Details')} (${rs(balList.fold<num>(0, (a, r) => a + nv(r['balance'])))})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kBrown),
                  ),
                  const SizedBox(height: 6),
                  if (balList.isEmpty)
                    Text(S.tr('कोई बाकी भुगतान नहीं', 'No balance payment pending'), style: const TextStyle(fontSize: 13))
                  else
                    for (final b in balList)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          '${dShow(b['date'])} · ${b['vehicle']} · ${b['status']} · ${S.tr('कुल', 'Total')} ${rs(nv(b['amount']))} / ${S.tr('प्राप्त', 'Recd')} ${rs(nv(b['received']))} / ${S.tr('बाकी', 'Bal')} ${rs(nv(b['balance']))}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                ]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: neo(r: 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    '${S.tr('फ्री वाहन विवरण', 'Free Vehicles Details')} (${freeList.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kBrown),
                  ),
                  const SizedBox(height: 6),
                  if (freeList.isEmpty)
                    Text(S.tr('कोई फ्री वाहन एंट्री नहीं', 'No free vehicle entries'), style: const TextStyle(fontSize: 13))
                  else
                    for (final fr in freeList)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          '${dShow(fr['date'])} · ${fr['vehicle']} (${fr['tyre'] ?? '-'}) · ${S.tr('कारण', 'Reason')}: ${_n(fr['note'])}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                ]),
              ),
              const SizedBox(height: 12),
              if (all.isNotEmpty) Text(hyvaNotes(all).first, style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => openPdfPreview(
                  context,
                  name: 'hyva_owner_${widget.owner}',
                  title: S.tr('मालिक वार हाइवा स्टेटमेंट', 'Owner Wise Hyva Statement'),
                  sub: widget.owner,
                  secs: _ownerSecs(widget.owner, all),
                ),
              ),
            ],
          );
        },
      );
}
