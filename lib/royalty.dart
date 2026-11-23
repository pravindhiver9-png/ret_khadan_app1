import 'package:flutter/material.dart';
import 'store.dart';
import 'ui.dart';

List<FD> royFields() => [
      FD('serial', 'रॉयल्टी क्रमांक', 'info'),
      FD('date', 'दिनांक', 'date', req: true),
      FD('time', 'समय', 'time', req: true),
      FD('mine', 'खदान का नाम', 'sug', opts: (v) => S.names('mine')),
      FD('qty', 'खनिज की मात्रा (घन मीटर m³)', 'num', req: true),
      FD('vehicle', 'गाड़ी नंबर', 'sug', req: true, opts: (v) => S.vehicleNames()),
      FD('owner', 'गाड़ी मालिक का नाम', 'text'),
      FD(
        'driver',
        'ड्राइवर का नाम',
        'sug',
        opts: (v) => S
            .driversOf(v['vehicle'] ?? '')
            .map((e) => '${e['n']}')
            .toList(),
      ),
      FD('mobile', 'ड्राइवर मोबाइल नंबर', 'phone'),
      FD(
        'receiver',
        'रॉयल्टी प्राप्तकर्ता का नाम (वैकल्पिक)',
        'sug',
        opts: (v) => S.names('recv'),
      ),
      FD(
        'dest',
        'कहाँ जाएगी (Destination)',
        'sug',
        req: true,
        opts: (v) => S.names('dest'),
      ),
      FD(
        'giver',
        'रॉयल्टी देने / काटने वाले का नाम',
        'sug',
        opts: (v) => S.names('cutter'),
      ),
      FD('amount', 'रॉयल्टी रकम (₹)', 'num', req: true),
      FD('photo', 'फोटो (वैकल्पिक)', 'photo'),
    ];

Future<void> openRoyalty(BuildContext ctx, [Map<String, dynamic>? old]) async {
  final init = <String, dynamic>{...?old};
  if (old == null) {
    init['date'] = dkey(DateTime.now());
    init['time'] = tnow();
  }
  await Navigator.push(
    ctx,
    MaterialPageRoute(
      builder: (_) => FormPage(
        title: old == null ? 'रॉयल्टी एंट्री' : 'रॉयल्टी एडिट',
        fields: royFields(),
        init: init,
        hook: (k, v, set) => vehHook(k, v, set),
        onSave: (c, v) async {
          final r = Map<String, dynamic>.from(v);
          r['vehicle'] = '${r['vehicle']}'.trim().toUpperCase();
          r['serial'] ??= S.takeSerial();
          S.saveVehicle(r['vehicle'], r['owner'], r['driver'], r['mobile']);
          S.addName('mine', r['mine']);
          S.addName('recv', r['receiver']);
          S.addName('dest', r['dest']);
          S.addName('cutter', r['giver']);
          await S.upsert('royalty', r);
          return null;
        },
      ),
    ),
  );
}

String _d(dynamic x) => '${x ?? ''}'.trim().isEmpty ? '-' : '$x';

class RoyaltyList extends StatelessWidget {
  const RoyaltyList({super.key});

  @override
  Widget build(BuildContext context) => RecordList(
        title: 'रॉयल्टी एंट्री लिस्ट',
        pdfName: 'royalty',
        source: () => S.list('royalty'),
        cols: const <String>[
          'क्रमांक',
          'समय',
          'm³',
          'गाड़ी / मालिक',
          'ड्राइवर / मोबाइल',
          'प्राप्तकर्ता / देने वाला',
          'कहाँ जाएगी',
          'रकम',
        ],
        w: const <double>[44, 38, 32, 92, 88, 92, 62, 48],
        row: (r, i) => <String>[
          '${r['serial'] ?? ''}',
          tShow(r['time']),
          '${r['qty'] ?? ''}',
          '${_d(r['vehicle'])}\n${_d(r['owner'])}',
          '${_d(r['driver'])}\n${_d(r['mobile'])}',
          '${_d(r['receiver'])}\n${_d(r['giver'])}',
          _d(r['dest']),
          rs(nv(r['amount'])),
        ],
        notes: (List> l) => [
          'कुल रॉयल्टी: ${rs(l.fold<num>(0, (a, r) => a + nv(r['amount'])))}   |   कुल मात्रा: ${fmtN(l.fold<num>(0, (a, r) => a + nv(r['qty'])))} m³'
        ],
        tTitle: (r) => '${r['serial']}  ·  ${r['vehicle']}',
        tSub: (r) =>
            '${r['qty']} m³ · ${_d(r['dest'])}${r['hyvaId'] != null ? ' · हाइवा से' : ''}',
        tAmt: (r) => rs(nv(r['amount'])),
        edit: (r) => openRoyalty(context, r),
        del: (r) => S.remove('royalty', r['id']),
      );
}
