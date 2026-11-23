import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'expense.dart';
import 'hyva.dart';
import 'pdf.dart';
import 'royalty.dart';
import 'store.dart';
import 'ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await S.init();
  runApp(const RetKhadanApp());
}

class RetKhadanApp extends StatelessWidget {
  const RetKhadanApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (_, __) => MaterialApp(
          title: S.tr('रेत खदान प्रबंधन', 'Ret Khadan Management'),
          debugShowCheckedModeBanner: false,
          theme: appTheme(),
          home: const LockGate(),
        ),
      );
}

class LockGate extends StatefulWidget {
  const LockGate({super.key});
  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> {
  bool unlocked = false;
  final pinCtl = TextEditingController();
  final confirmCtl = TextEditingController();
  String? err;

  bool get isFirstTime => S.mpin.isEmpty;

  @override
  void dispose() {
    pinCtl.dispose();
    confirmCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final p1 = pinCtl.text.trim();
    if (p1.length < 4) {
      setState(() => err = S.tr('कम से कम 4 अंकों का MPIN डालें', 'Enter at least 4-digit MPIN'));
      return;
    }
    if (isFirstTime) {
      final p2 = confirmCtl.text.trim();
      if (p1 != p2) {
        setState(() => err = S.tr('दोनों MPIN मेल नहीं खा रहे हैं', 'MPIN does not match'));
        return;
      }
      await S.setMpin(p1);
      setState(() => unlocked = true);
    } else {
      if (p1 != S.mpin) {
        setState(() => err = S.tr('गलत MPIN', 'Incorrect MPIN'));
        return;
      }
      setState(() => unlocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (unlocked) return const Home();
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: Image.asset('assets/images/app_bg.jpg', fit: BoxFit.cover, cacheWidth: 900)),
        const Positioned.fill(child: ColoredBox(color: Color(0xB3F3E9D7))),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: neo(r: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ChoiceChip(
                          label: Text(S.isEn ? 'हिन्दी' : 'English'),
                          selected: false,
                          onSelected: (_) => S.setLang(S.isEn ? 'hi' : 'en'),
                        ),
                      ],
                    ),
                    const Icon(Icons.lock_outline, size: 42, color: kBrown),
                    const SizedBox(height: 8),
                    Text(
                      isFirstTime ? S.tr('नया MPIN सेट करें', 'Set New MPIN') : S.tr('MPIN दर्ज करें', 'Enter MPIN'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFirstTime
                          ? S.tr('पहली बार ऐप खोल रहे हैं — सुरक्षा के लिए MPIN बनाएँ', 'First time setup — create an MPIN to lock app')
                          : S.tr('ऐप खोलने के लिए अपना MPIN डालें', 'Enter your MPIN to unlock'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: kBrown),
                    ),
                    const SizedBox(height: 18),
                    aboveBox(
                      S.tr('MPIN', 'MPIN'),
                      TextField(
                        controller: pinCtl,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 6,
                        textInputAction: isFirstTime ? TextInputAction.next : TextInputAction.done,
                        decoration: dec(),
                        onSubmitted: (_) {
                          if (!isFirstTime) _submit();
                        },
                      ),
                      req: true,
                    ),
                    if (isFirstTime)
                      aboveBox(
                        S.tr('MPIN कन्फर्म करें', 'Confirm MPIN'),
                        TextField(
                          controller: confirmCtl,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 6,
                          textInputAction: TextInputAction.done,
                          decoration: dec(),
                          onSubmitted: (_) => _submit(),
                        ),
                        req: true,
                      ),
                    if (err != null) ...[
                      Text(err!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 10),
                    ],
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: kBrown, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: _submit,
                      child: Text(isFirstTime ? S.tr('MPIN सेव करें और खोलें', 'Save MPIN & Unlock') : S.tr('अनलॉक करें', 'Unlock'), style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  Widget stat(IconData i, String l, String v) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: neo(r: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(i, color: kBrown),
            const SizedBox(height: 5),
            Text(l, style: const TextStyle(color: kBrown, fontSize: 13)),
            const SizedBox(height: 2),
            FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700))),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (_, __) {
          final now = DateTime.now();
          final t = dkey(now);
          final hy = S.list('hyva').where((r) => r['date'] == t).toList();
          final ro = S.list('royalty').where((r) => r['date'] == t).toList();
          final ex = S.list('expense').where((r) => r['date'] == t).toList();
          final roT = ro.fold<num>(0, (a, r) => a + nv(r['amount']));
          final exT = ex.fold<num>(0, (a, r) => a + nv(r['amount']));

          final recent = <Map<String, dynamic>>[
            for (final r in S.list('hyva')) {...r, '_k': 'hyva'},
            for (final r in S.list('royalty')) {...r, '_k': 'royalty'},
            for (final r in S.list('expense')) {...r, '_k': 'expense'},
          ]
            ..sort((a, b) => '${b['id']}'.compareTo('${a['id']}'))
            ..take(10);
          final recent10 = recent.toList();

          final activeTk = S.activeThekedar;
          final dayLabel = S.isEn ? wkEn[now.weekday - 1] : wk[now.weekday - 1];

          return Scaffold(
            body: Stack(children: [
              Positioned.fill(child: Image.asset('assets/images/app_bg.jpg', fit: BoxFit.cover, cacheWidth: 900)),
              const Positioned.fill(child: ColoredBox(color: Color(0xB3F3E9D7))),
              SafeArea(
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset('assets/icon/app_icon.png', width: 54, height: 54, cacheWidth: 200, errorBuilder: (_, __, ___) => const Icon(Icons.local_shipping, size: 38)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(S.tr('रेत खदान प्रबंधन', 'Ret Khadan Management'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(
                          activeTk != null ? '${activeTk['khadan'] ?? ''} · ${S.tr('ठेकेदार', 'Contractor')}: ${activeTk['name'] ?? ''}' : S.tr('ठेकेदार सेट नहीं है', 'No active contractor'),
                          style: const TextStyle(color: kBrown, fontSize: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]),
                    ),
                    TextButton(
                      onPressed: () => S.setLang(S.isEn ? 'hi' : 'en'),
                      child: Text(S.isEn ? 'हिन्दी' : 'EN', style: const TextStyle(fontWeight: FontWeight.w700, color: kBrown)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: kBrown),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(S.tr('नमस्कार!', 'Welcome!'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(S.tr('आज का हिसाब', "Today's Summary"), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('$dayLabel · ${dShow(t)}', style: const TextStyle(color: kBrown, fontSize: 14)),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: kBrown),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => openTyreRateDialog(context, onlyIfUnset: false),
                    icon: const Icon(Icons.speed, color: kBrown),
                    label: Text(
                      '${S.tr('आज का लोडिंग दर', "Today's Loading Rate")} (10/12/14/16 Tyre)',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: kTxt),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(S.tr('आज का कारोबार', "Today's Business"), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(children: [
                    stat(Icons.local_shipping_outlined, S.tr('कुल हाइवा', 'Total Hyva'), '${hy.length}'),
                    const SizedBox(width: 12),
                    stat(Icons.receipt_long_outlined, S.tr('कुल रॉयल्टी', 'Total Royalty'), rs(roT)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    stat(Icons.account_balance_wallet_outlined, S.tr('कुल खर्च', 'Total Expense'), rs(exT)),
                    const SizedBox(width: 12),
                    stat(Icons.payments_outlined, S.tr('शेष राशि', 'Balance'), rs(roT - exT)),
                  ]),
                  const SizedBox(height: 20),
                  Text(S.tr('मुख्य एंट्री', 'Main Entry'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: bigBtn(
                        S.tr('हाइवा एंट्री', 'Hyva Entry'),
                        Icons.local_shipping_outlined,
                        () async {
                          await openTyreRateDialog(context, onlyIfUnset: true);
                          if (context.mounted) openHyva(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: bigBtn(
                        S.tr('रॉयल्टी एंट्री', 'Royalty Entry'),
                        Icons.receipt_long_outlined,
                        () => openRoyalty(context),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  bigBtn(
                    S.tr('खर्च एंट्री', 'Expense Entry'),
                    Icons.account_balance_wallet_outlined,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseHome())),
                    dark: false,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(S.tr('हाल की एंट्री', 'Recent Entries'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                      Text('${recent10.length}/10', style: const TextStyle(color: kBrown, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 375,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0x66E3D1B3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x448B6B48)),
                    ),
                    child: recent10.isEmpty
                        ? Center(child: Text(S.tr('अभी कोई एंट्री नहीं', 'No entries yet')))
                        : ListView.builder(
                            itemCount: recent10.length,
                            itemBuilder: (_, idx) {
                              final r = recent10[idx];
                              final kind = r['_k'];
                              final titleText = kind == 'expense'
                                  ? '${ets.firstWhere((e) => e.key == r['type'], orElse: () => ets.last).title} ${S.tr('खर्च', 'Exp')}'
                                  : '${r['vehicle'] ?? '-'}';
                              final subText = '${r['date'] == t ? S.tr('आज', 'Today') : dShow(r['date'])} · ${kind == 'hyva' ? S.tr('हाइवा', 'Hyva') : kind == 'royalty' ? '${S.tr('रॉयल्टी', 'Royalty')} ${r['qty']} m³' : S.tr('खर्च एंट्री', 'Expense')}';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  decoration: neo(r: 16),
                                  child: Row(children: [
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(titleText, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                        Text(subText, style: const TextStyle(color: kBrown, fontSize: 12)),
                                      ]),
                                    ),
                                    Text(rs(nv(r['amount'])), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  ]),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    TextButton.icon(
                      icon: const Icon(Icons.bar_chart),
                      label: Text(S.tr('रिपोर्ट मेनू', 'Reports Menu')),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsPage())),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.backup),
                      label: Text(S.tr('बैकअप एवं Restore', 'Backup & Restore')),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupPage())),
                    ),
                  ]),
                ]),
              ),
            ]),
          );
        },
      );
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  Future<void> _exportAllRoyaltyExcel(BuildContext ctx) async {
    final rows = S.list('royalty').map((r) => [
      dShow(r['date']),
      tShow(r['time']),
      '${r['royaltyNo'] ?? r['serial'] ?? ''}',
      '${r['vehicle'] ?? ''}',
      '${r['owner'] ?? ''}',
      '${r['qty'] ?? ''}',
      '${r['dest'] ?? ''}',
      fmtN(nv(r['amount'])),
    ]).toList();
    if (rows.isEmpty) return;
    await guard(ctx, () => shareCsv('royalty_all', [S.tr('दिनांक', 'Date'), S.tr('समय', 'Time'), S.tr('रॉयल्टी क्र.', 'Royalty No.'), S.tr('गाड़ी', 'Vehicle'), S.tr('मालिक', 'Owner'), 'm³', S.tr('गंतव्य', 'Destination'), S.tr('रकम', 'Amount')], rows));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (_, __) => Pg(
          S.tr('रिपोर्ट मेनू', 'Reports Menu'),
          ListView(padding: const EdgeInsets.all(16), children: [
            bigBtn(S.tr('हाइवा एंट्री रिपोर्ट', 'Hyva Entry Report'), Icons.local_shipping_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HyvaList()))),
            const SizedBox(height: 12),
            bigBtn(S.tr('रॉयल्टी एंट्री रिपोर्ट', 'Royalty Entry Report'), Icons.receipt_long_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoyaltyList()))),
            const SizedBox(height: 12),
            bigBtn(S.tr('मालिक वार हाइवा स्टेटमेंट', 'Owner Wise Hyva Statement'), Icons.groups, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerPage())), dark: false),
            const SizedBox(height: 12),
            bigBtn(S.tr('खर्च स्टेटमेंट (सभी खर्च)', 'Expense Statement (All)'), Icons.summarize, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpStatement())), dark: false),
            const SizedBox(height: 12),
            bigBtn('${S.tr('बेशरम वाला', 'Besharam Wala')} Balance Statement', Icons.account_balance_wallet, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BesharamBal())), dark: false),
            const SizedBox(height: 18),
            Text(S.tr('हर एक खर्च की अलग रिपोर्ट (PDF / Excel)', 'Individual Expense Reports'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kBrown)),
            const SizedBox(height: 10),
            for (final t in ets)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: neo(r: 16),
                  child: Row(children: [
                    Icon(t.icon, color: kBrown),
                    const SizedBox(width: 10),
                    Expanded(child: Text('${t.title} ${S.tr('रिपोर्ट', 'Report')}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                    IconButton(
                      tooltip: 'Open List & PDF/Excel',
                      icon: const Icon(Icons.open_in_new, color: kBrown),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseList(t))),
                    ),
                  ]),
                ),
              ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () => _exportAllRoyaltyExcel(context),
              icon: const Icon(Icons.table_chart),
              label: Text(S.tr('सभी रॉयल्टी Excel एक्सपोर्ट', 'Export All Royalty Excel')),
            ),
          ]),
        ),
      );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final nameCtl = TextEditingController();
  final mobCtl = TextEditingController();
  final addrCtl = TextEditingController();
  final khadanCtl = TextEditingController();

  @override
  void dispose() {
    nameCtl.dispose();
    mobCtl.dispose();
    addrCtl.dispose();
    khadanCtl.dispose();
    super.dispose();
  }

  Future<void> _addThekedar() async {
    if (nameCtl.text.trim().isEmpty || khadanCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.tr('ठेकेदार और खदान का नाम भरें', 'Enter contractor and khadan name'))));
      return;
    }
    await S.saveThekedar({
      'name': nameCtl.text,
      'mobile': mobCtl.text,
      'address': addrCtl.text,
      'khadan': khadanCtl.text,
    }, setActive: true);
    nameCtl.clear();
    mobCtl.clear();
    addrCtl.clear();
    khadanCtl.clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.tr('ठेकेदार सेव और सक्रिय किया गया', 'Contractor saved & activated'))));
  }

  Future<void> _changeMpinDialog() async {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    await showDialog(
      context: context,
      builder: (dc) => AlertDialog(
        title: Text(S.tr('MPIN बदलें', 'Change MPIN')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          aboveBox(S.tr('नया MPIN', 'New MPIN'), TextField(controller: c1, keyboardType: TextInputType.number, obscureText: true, maxLength: 6, textInputAction: TextInputAction.next, decoration: dec())),
          aboveBox(S.tr('कन्फर्म MPIN', 'Confirm MPIN'), TextField(controller: c2, keyboardType: TextInputType.number, obscureText: true, maxLength: 6, textInputAction: TextInputAction.done, decoration: dec())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dc), child: Text(S.tr('रद्द करें', 'Cancel'))),
          FilledButton(
            onPressed: () async {
              if (c1.text.trim().length >= 4 && c1.text.trim() == c2.text.trim()) {
                await S.setMpin(c1.text.trim());
                if (dc.mounted) Navigator.pop(dc);
              }
            },
            child: Text(S.tr('सेव', 'Save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (_, __) {
          final list = S.thekedars();
          final active = S.activeThekedar;
          return Pg(
            S.tr('सेटिंग्स', 'Settings'),
            ListView(padding: const EdgeInsets.all(16), children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: neo(r: 18),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(S.tr('भाषा / Language', 'Language / भाषा'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Row(children: [
                    ChoiceChip(label: const Text('हिन्दी'), selected: !S.isEn, onSelected: (_) => S.setLang('hi')),
                    const SizedBox(width: 8),
                    ChoiceChip(label: const Text('English'), selected: S.isEn, onSelected: (_) => S.setLang('en')),
                  ]),
                ]),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: neo(r: 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(S.tr('सक्रिय ठेकेदार चुनें', 'Select Active Contractor'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: kBrown)),
                  const SizedBox(height: 8),
                  if (list.isEmpty)
                    Text(S.tr('अभी कोई ठेकेदार नहीं जुड़ा है', 'No contractor added yet'), style: const TextStyle(fontSize: 13))
                  else
                    for (final tk in list)
                      RadioListTile<String>(
                        value: '${tk['id']}',
                        groupValue: '${active?['id'] ?? ''}',
                        title: Text('${tk['name']} · ${tk['khadan']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${tk['mobile'] ?? ''} · ${tk['address'] ?? ''}', style: const TextStyle(fontSize: 12)),
                        onChanged: (val) {
                          if (val != null) S.selectThekedar(val);
                        },
                      ),
                ]),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: neo(r: 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(S.tr('नया ठेकेदार जोड़ें', 'Add New Contractor'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: kBrown)),
                  const SizedBox(height: 10),
                  aboveBox(S.tr('ठेकेदार का नाम', 'Contractor Name'), TextField(controller: nameCtl, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next, decoration: dec()), req: true),
                  aboveBox(S.tr('मोबाइल नंबर', 'Mobile Number'), TextField(controller: mobCtl, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next, decoration: dec())),
                  aboveBox(S.tr('पता (Address)', 'Address'), TextField(controller: addrCtl, textCapitalization: TextCapitalization.sentences, textInputAction: TextInputAction.next, decoration: dec())),
                  aboveBox(S.tr('खदान का नाम', 'Khadan Name'), TextField(controller: khadanCtl, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.done, decoration: dec()), req: true),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: kBrown, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: _addThekedar,
                    icon: const Icon(Icons.person_add),
                    label: Text(S.tr('ठेकेदार सेव करें', 'Save Contractor')),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _changeMpinDialog,
                icon: const Icon(Icons.lock_reset),
                label: Text(S.tr('MPIN बदलें', 'Change MPIN')),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupPage())),
                icon: const Icon(Icons.backup),
                label: Text(S.tr('बैकअप एवं Restore', 'Backup & Restore')),
              ),
            ]),
          );
        },
      );
}

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});
  @override
  Widget build(BuildContext context) => Pg(
        S.tr('बैकअप एवं Restore', 'Backup & Restore'),
        ListView(padding: const EdgeInsets.all(16), children: [
          Text(S.tr('सारा डेटा सिर्फ आपके फोन में सेव है। बदलने / uninstall से पहले बैकअप ज़रूर बनाएँ। (फोटो बैकअप फाइल में शामिल नहीं हैं।)', 'All data is stored locally on your device. Create a backup before changing devices or uninstalling.')),
          const SizedBox(height: 16),
          bigBtn(
            S.tr('बैकअप बनाओ और शेयर करो', 'Create & Share Backup'),
            Icons.upload_file,
            () => guard(context, () async {
              final dir = await getTemporaryDirectory();
              final p = '${dir.path}/RetKhadan_backup_${dkey(DateTime.now())}.json';
              await File(p).writeAsString(S.export());
              await Share.shareXFiles([XFile(p)], text: 'Ret Khadan backup');
            }),
          ),
          const SizedBox(height: 14),
          bigBtn(
            S.tr('Restore (बैकअप फाइल चुनें)', 'Restore (Pick Backup File)'),
            Icons.download,
            () => guard(context, () async {
              final f = await FilePicker.platform.pickFiles(type: FileType.any);
              if (f == null || f.files.single.path == null) return;
              final txt = await File(f.files.single.path!).readAsString();
              if (!context.mounted) return;
              final ok = await showDialog<bool>(
                context: context,
                builder: (dc) => AlertDialog(
                  title: Text(S.tr('Restore करें?', 'Restore Backup?')),
                  content: Text(S.tr('अभी का सारा डेटा बदलकर बैकअप वाला डेटा आ जाएगा।', 'Current data will be replaced by the backup file.')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dc, false), child: Text(S.tr('नहीं', 'No'))),
                    FilledButton(onPressed: () => Navigator.pop(dc, true), child: Text(S.tr('हाँ, Restore', 'Yes, Restore'))),
                  ],
                ),
              );
              if (ok == true) {
                await S.restore(txt);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.tr('Restore हो गया', 'Restored successfully'))));
              }
            }),
            dark: false,
          ),
        ]),
      );
}
