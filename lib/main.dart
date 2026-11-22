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
  runApp(MaterialApp(
    title: 'रेत खदान प्रबंधन',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    home: const Home(),
  ));
}

class Home extends StatelessWidget {
  const Home({super.key});

  Widget stat(IconData i, String l, String v) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: neo(r: 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(i, color: kBrown),
            const SizedBox(height: 6),
            Text(l, style: const TextStyle(color: kBrown, fontSize: 14)),
            const SizedBox(height: 2),
            FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700))),
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
          ]..sort((a, b) => '${b['id']}'.compareTo('${a['id']}'));
          return Scaffold(
            body: Stack(children: [
              Positioned.fill(child: Image.asset('assets/images/app_bg.jpg', fit: BoxFit.cover, cacheWidth: 900)),
              const Positioned.fill(child: ColoredBox(color: Color(0xB3F3E9D7))),
              SafeArea(
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  Row(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.asset('assets/icon/app_icon.png', width: 58, height: 58, cacheWidth: 200, errorBuilder: (_, __, ___) => const Icon(Icons.local_shipping, size: 40))),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Ret Khadan Management', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                        Text('रेत खदान प्रबंधन', style: TextStyle(color: kBrown)),
                      ]),
                    ),
                    IconButton(icon: const Icon(Icons.settings, color: kBrown), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupPage()))),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(24)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('नमस्कार!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      const Text('आज का हिसाब', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('${wk[now.weekday - 1]} · ${dShow(t)}', style: const TextStyle(color: kBrown, fontSize: 15)),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  const Text('आज का कारोबार', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(children: [stat(Icons.local_shipping_outlined, 'कुल हाइवा', '${hy.length}'), const SizedBox(width: 14), stat(Icons.receipt_long_outlined, 'कुल रॉयल्टी', rs(roT))]),
                  const SizedBox(height: 14),
                  Row(children: [stat(Icons.account_balance_wallet_outlined, 'कुल खर्च', rs(exT)), const SizedBox(width: 14), stat(Icons.payments_outlined, 'शेष राशि', rs(roT - exT))]),
                  const SizedBox(height: 22),
                  const Text('मुख्य एंट्री', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: bigBtn('हाइवा एंट्री', Icons.local_shipping_outlined, () async { await askDailyRate(context); if (context.mounted) openHyva(context); })),
                    const SizedBox(width: 14),
                    Expanded(child: bigBtn('रॉयल्टी एंट्री', Icons.receipt_long_outlined, () => openRoyalty(context))),
                  ]),
                  const SizedBox(height: 14),
                  bigBtn('खर्च एंट्री', Icons.account_balance_wallet_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseHome())), dark: false),
                  const SizedBox(height: 22),
                  const Text('हाल की एंट्री', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (recent.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('अभी कोई एंट्री नहीं'))),
                  for (final r in recent.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: neo(r: 20),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(
                                r['_k'] == 'expense' ? '${ets.firstWhere((e) => e.key == r['type'], orElse: () => ets.last).title} खर्च' : '${r['vehicle']}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                              ),
                              Text(
                                '${r['date'] == t ? 'आज' : dShow(r['date'])} · ${r['_k'] == 'hyva' ? 'हाइवा' : r['_k'] == 'royalty' ? 'रॉयल्टी ${r['qty']} m³' : 'खर्च एंट्री'}',
                                style: const TextStyle(color: kBrown, fontSize: 13),
                              ),
                            ]),
                          ),
                          Text(rs(nv(r['amount'])), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        ]),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    TextButton.icon(icon: const Icon(Icons.bar_chart), label: const Text('रिपोर्ट देखें'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsPage()))),
                    TextButton.icon(icon: const Icon(Icons.backup), label: const Text('बैकअप एवं Restore'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupPage()))),
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
  @override
  Widget build(BuildContext context) => Pg(
        'रिपोर्ट / लिस्ट',
        ListView(padding: const EdgeInsets.all(16), children: [
          bigBtn('Hyva Entry List', Icons.local_shipping_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HyvaList()))),
          const SizedBox(height: 14),
          bigBtn('Royalty Entry List', Icons.receipt_long_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoyaltyList()))),
          const SizedBox(height: 14),
          bigBtn('Kharch List', Icons.account_balance_wallet_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseHome()))),
          const SizedBox(height: 14),
          bigBtn('Owner Wise Hyva Statement', Icons.groups, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerPage())), dark: false),
        ]),
      );
}

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});
  @override
  Widget build(BuildContext context) => Pg(
        'बैकअप एवं Restore',
        ListView(padding: const EdgeInsets.all(16), children: [
          const Text('सारा डेटा सिर्फ आपके फोन में सेव है। बदलने / uninstall से पहले बैकअप ज़रूर बनाएँ। (फोटो बैकअप फाइल में शामिल नहीं हैं।)'),
          const SizedBox(height: 16),
          bigBtn('बैकअप बनाओ और शेयर करो', Icons.upload_file, () => guard(context, () async {
                final dir = await getTemporaryDirectory();
                final p = '${dir.path}/RetKhadan_backup_${dkey(DateTime.now())}.json';
                await File(p).writeAsString(S.export());
                await Share.shareXFiles([XFile(p)], text: 'Ret Khadan backup');
              })),
          const SizedBox(height: 14),
          bigBtn('Restore (बैकअप फाइल चुनें)', Icons.download, () => guard(context, () async {
                final f = await FilePicker.platform.pickFiles(type: FileType.any);
                if (f == null || f.files.single.path == null) return;
                final txt = await File(f.files.single.path!).readAsString();
                if (!context.mounted) return;
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dc) => AlertDialog(
                    title: const Text('Restore करें?'),
                    content: const Text('अभी का सारा डेटा बदलकर बैकअप वाला डेटा आ जाएगा।'),
                    actions: [TextButton(onPressed: () => Navigator.pop(dc, false), child: const Text('नहीं')), FilledButton(onPressed: () => Navigator.pop(dc, true), child: const Text('हाँ, Restore'))],
                  ),
                );
                if (ok == true) {
                  await S.restore(txt);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore हो गया')));
                }
              }), dark: false),
        ]),
      );
}
