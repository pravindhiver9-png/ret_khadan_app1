import 'package:flutter/material.dart';
import 'store.dart';
import 'ui.dart';

List<FD> royFields() => [
      FD('royaltyNo', S.tr('रॉयल्टी क्रमांक', 'Royalty Book No.'), 'text', req: true, hint: S.tr('रॉयल्टी बुक का क्रमांक लिखें', 'Enter royalty serial / book no.')),
      FD('serial', S.tr('सिस्टम क्रमांक', 'System Serial'), 'info'),
      FD('date', S.tr('दिनांक', 'Date'), 'date', req: true),
      FD('time', S.tr('समय', 'Time'), 'time', req: true),
      FD('mine', S.tr('खदान का नाम', 'Mine Name'), 'sug', opts: (v) => S.names('mine')),
      FD('tyre', S.tr('टायर', 'Tyre'), 'pick', opts: (v) => tyreSizes),
      FD('qty', S.tr('खनिज की मात्रा (घन मीटर m³)', 'Quantity (m³)'), 'num', req: true),
      FD('vehicle', S.tr('गाड़ी नंबर', 'Vehicle No.'), 'cap', req: true),
      FD('owner', S.tr('गाड़ी मालिक का नाम', 'Owner Name'), 'capWords'),
      FD('driver', S.tr('ड्राइवर का नाम', 'Driver Name'), 'sug', opts: (v) => S.driversOf(v['vehicle'] ?? '').map((e) => '${e['n']}').toList()),
      FD('mobile', S.tr('ड्राइवर मोबाइल नंबर', 'Driver Mobile'), 'phone'),
      FD('receiver', S.tr('रॉयल्टी प्राप्तकर्ता का नाम (वैकल्पिक)', 'Receiver Name (Optional)'), 'sug', opts: (v) => S.names('recv')),
      FD('dest', S.tr('कहाँ जाएगी (Destination)', 'Destination'), 'sug', req: true, opts: (v) => S.names('dest')),
      FD('giver', S.tr('रॉयल्टी देने / काटने वाले का नाम', 'Royalty Issuer'), 'sug', opts: (v) => S.names('cutter')),
      FD('amount', S.tr('रॉयल्टी रकम (₹)', 'Royalty Amount (₹)'), 'num', req: true),
      FD('photo', S.tr('फोटो (वैकल्पिक)', 'Photo (Optional)'), 'photo'),
    ];

Future<void> openRoyalty(BuildContext ctx, [Map<String, dynamic>? old]) async {
  final init = <String, dynamic>{...?old};
  if (old == null) {
    init['date'] = dkey(DateTime.now());
    init['time'] = tnow();
    init['tyre'] = '12 Tyre';
  }
  await Navigator.push(
    ctx,
    MaterialPageRoute(
      builder: (_) => FormPage(
        title: old == null ? S.tr('रॉयल्टी एंट्री', 'Royalty Entry') : S.tr('रॉयल्टी एडिट', 'Edit Royalty'),
        fields: royFields(),
        init: init,
        hook: (k, v, set) => vehHook(k, v, set),
        onSave: (c, v) async {
          final r = Map<String, dynamic>.from(v);
          r['vehicle'] = '${r['vehicle'] ?? ''}'.trim().toUpperCase();
          r['royaltyNo'] = '${r['royaltyNo'] ?? ''}'.trim().toUpperCase();
          r['owner'] = capWords(r['owner']);
          r['driver'] = capWords(r['driver']);
          r['serial'] ??= S.takeSerial();
          S.saveVehicle(r['vehicle'], r['owner'], r['driver'], r['mobile'], r['tyre']);
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
  final int initialMode;
  final DateTime? initialDate;
  const RoyaltyList({super.key, this.initialMode = 2, this.initialDate});
  @override
  Widget build(BuildContext context) => RecordList(
        title: S.tr('रॉयल्टी एंट्री लिस्ट', 'Royalty Entry List'),
        pdfName: 'royalty',
        initialMode: initialMode,
        initialDate: initialDate,
        source: () => S.list('royalty'),
        cols: [
          S.tr('रॉयल्टी क्र.', 'Royalty No.'),
          S.tr('समय', 'Time'),
          'm³',
          S.tr('गाड़ी / मालिक', 'Vehicle / Owner'),
          S.tr('ड्राइवर / मोबाइल', 'Driver / Mobile'),
          S.tr('प्राप्तकर्ता / देने वाला', 'Receiver / Issuer'),
          S.tr('गंतव्य', 'Destination'),
          S.tr('रकम', 'Amount'),
        ],
        w: const [52, 38, 32, 88, 84, 88, 58, 48],
        row: (r, i) => [
          '${r['royaltyNo'] ?? r['serial'] ?? ''}',
          tShow(r['time']),
          '${r['qty'] ?? ''}',
          '${_d(r['vehicle'])}\n${_d(r['owner'])}',
          '${_d(r['driver'])}\n${_d(r['mobile'])}',
          '${_d(r['receiver'])}\n${_d(r['giver'])}',
          _d(r['dest']),
          rs(nv(r['amount'])),
        ],
        notes: (l) => [
          '${S.tr('कुल रॉयल्टी', 'Total Royalty')}: ${rs(l.fold<num>(0, (a, r) => a + nv(r['amount'])))}   |   ${S.tr('कुल मात्रा', 'Total Qty')}: ${fmtN(l.fold<num>(0, (a, r) => a + nv(r['qty'])))} m³'
        ],
        tTitle: (r) => '${_d(r['royaltyNo'] ?? r['serial'])}  ·  ${_d(r['vehicle'])}',
        tSub: (r) => '${r['qty']} m³ · ${_d(r['dest'])}${r['hyvaId'] != null ? ' · ${S.tr('हाइवा से', 'From Hyva')}' : ''}',
        tAmt: (r) => rs(nv(r['amount'])),
        edit: (r) => openRoyalty(context, r),
        del: (r) => S.remove('royalty', r['id']),
      );
}
