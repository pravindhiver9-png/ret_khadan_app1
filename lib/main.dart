import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuarryApp());
}

const ink = Color(0xFF202529);
const muted = Color(0xFF747B80);
const canvas = Color(0xFFF0F1F3);
const green = Color(0xFF557B68);
const softGreen = Color(0xFFE2ECE6);

// ---------- helpers ----------
double _n(dynamic v) => (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;
String money(double n) => '₹${n.toStringAsFixed(0)}';
String fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String today() => fmt(DateTime.now());

BoxDecoration softPanel({double radius = 20}) => BoxDecoration(
      color: canvas,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(color: Colors.white.withValues(alpha: .95), offset: const Offset(-5, -5), blurRadius: 12),
        BoxShadow(color: const Color(0xFFBFC3C8).withValues(alpha: .65), offset: const Offset(5, 5), blurRadius: 13),
      ],
    );

InputDecoration deco(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: canvas,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withValues(alpha: .8))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: green, width: 1.2)),
    );

Widget field(String label, TextEditingController c,
        {TextInputType type = TextInputType.text, String? hint, ValueChanged<String>? onChanged}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        onChanged: onChanged,
        decoration: deco(label, hint: hint),
      ),
    );

Widget dd(String label, String value, List<String> items, ValueChanged<String?> onChanged) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: onChanged,
        decoration: deco(label),
      ),
    );

Widget dateButton(BuildContext context, DateTime d, ValueChanged<DateTime> onPick) => OutlinedButton.icon(
      onPressed: () async {
        final p = await showDatePicker(context: context, initialDate: d, firstDate: DateTime(2020), lastDate: DateTime(2100));
        if (p != null) onPick(p);
      },
      icon: const Icon(Icons.calendar_today),
      label: Text(fmt(d)),
    );

Widget saveButton(BuildContext context, VoidCallback onTap) => SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.check_rounded),
        label: const Text('सेव करें'),
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );

Widget rowText(String a, String b) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(a, style: const TextStyle(color: muted))),
        Text(b, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );

void snack(BuildContext context, String s) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

// ---------- app ----------
class QuarryApp extends StatelessWidget {
  const QuarryApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'रेत खदान',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(seedColor: green, surface: canvas),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(backgroundColor: canvas, foregroundColor: ink, elevation: 0),
      ),
      home: const HomeShell(),
    );
  }
}

class LocalStore {
  static const _key = 'quarry_records_v1';
  static Future<List>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> save(List> rows) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(rows));
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  bool loading = true;
  List> records = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final data = await LocalStore.load();
    if (!mounted) return;
    setState(() {
      records = data;
      loading = false;
    });
  }

  Future<void> _save(Map<String, dynamic> row) async {
    setState(() => records.insert(0, row));
    await LocalStore.save(records);
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    setState(() => records.remove(row));
    await LocalStore.save(records);
  }

  Iterable> _of(String t) => records.where((e) => e['type'] == t);

  double get sales => _of('hyva').fold(0.0, (s, e) => s + _n(e['total']));
  double get received => _of('hyva').fold(0.0, (s, e) => s + _n(e['paid']));
  double get pending => (sales - received).clamp(0, double.infinity).toDouble();
  double get wages => _of('attendance').fold(0.0, (s, e) => s + _n(e['wage']));
  double get otherExpenses => _of('expense').fold(0.0, (s, e) => s + _n(e['amount']));
  double get expenses => wages + otherExpenses;
  int get trips => _of('hyva').length;
  int get todayTrips => _of('hyva').where((e) => e['date'] == today()).length;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _dashboard(),
      _recordList('Hyva एंट्री', Icons.local_shipping, ['hyva'], FloatingActionButton.extended(
        backgroundColor: ink, foregroundColor: Colors.white, onPressed: _hyvaForm,
        icon: const Icon(Icons.add), label: const Text('नई एंट्री'))),
      _recordList('दैनिक खर्च', Icons.receipt_long, ['expense', 'attendance'], FloatingActionButton.extended(
        backgroundColor: ink, foregroundColor: Colors.white, onPressed: _expenseForm,
        icon: const Icon(Icons.add), label: const Text('खर्च जोड़ें'))),
      _accounts(),
      _more(),
    ];
    return Scaffold(
      body: SafeArea(child: loading ? const Center(child: CircularProgressIndicator()) : pages[tab]),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _bottomBar() => Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: softPanel(radius: 28),
        child: Row(children: [
          _nav('होम', Icons.home_rounded, 0),
          _nav('एंट्री', Icons.local_shipping_rounded, 1),
          _nav('खर्च', Icons.receipt_long_rounded, 2),
          _nav('हिसाब', Icons.menu_book_rounded, 3),
          _nav('मेन्यू', Icons.menu_rounded, 4),
        ]),
      );

  Widget _nav(String label, IconData icon, int index) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => tab = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: tab == index
                ? BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 9, offset: const Offset(3, 4))],
                  )
                : null,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 21, color: tab == index ? Colors.white : ink),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: tab == index ? FontWeight.w600 : FontWeight.w400, color: tab == index ? Colors.white : muted)),
            ]),
          ),
        ),
      );

  Widget _dashboard() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 22), children: [
        Row(children: [
          Container(width: 56, height: 56, decoration: softPanel(radius: 18), child: const Icon(Icons.landscape_rounded, size: 30, color: ink)),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('श्री गणेश रेत खदान', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: ink)),
              SizedBox(height: 3),
              Text('खदान प्रबंधन प्रणाली', style: TextStyle(color: muted, fontSize: 13)),
            ]),
          ),
          Container(
            decoration: softPanel(radius: 22),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: const Row(children: [Icon(Icons.calendar_today_rounded, size: 16), SizedBox(width: 7), Text('आज', style: TextStyle(fontWeight: FontWeight.w500))]),
          ),
        ]),
        const SizedBox(height: 22),
        Row(children: [
          const Icon(Icons.event, size: 18, color: muted),
          const SizedBox(width: 8),
          Text(today(), style: const TextStyle(color: muted, fontSize: 14)),
        ]),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.55,
          children: [
            _metric(Icons.local_shipping_rounded, '$todayTrips', 'आज की Hyva एंट्री'),
            _metric(Icons.grain_rounded, money(sales), 'कुल बिक्री'),
            _metric(Icons.local_gas_station_rounded, money(expenses), 'कुल खर्च'),
            _metric(Icons.trending_up_rounded, money(sales - expenses), 'शुद्ध बचत'),
          ],
        ),
        const SizedBox(height: 25),
        _sectionTitle('त्वरित कार्यवाही', 'सभी देखें', () => setState(() => tab = 4)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: .82,
          children: [
            _quick(Icons.local_shipping_rounded, 'नई Hyva\nएंट्री', _hyvaForm),
            _quick(Icons.groups_rounded, 'मजदूर\nहाजिरी', _attendance),
            _quick(Icons.receipt_long_rounded, 'खर्च\nजोड़ें', _expenseForm),
            _quick(Icons.assessment_rounded, 'रिपोर्ट\nदेखें', () => setState(() => tab = 3)),
          ],
        ),
        const SizedBox(height: 24),
        _sectionTitle('आज की गतिविधियां', 'और देखें', () => setState(() => tab = 1)),
        const SizedBox(height: 10),
        if (records.isEmpty)
          _empty('अभी कोई एंट्री नहीं है', 'नई Hyva, खर्च या मजदूर हाजिरी जोड़ने पर रिकॉर्ड यहाँ दिखेंगे।', Icons.inbox_rounded)
        else
          ...records.take(5).map(_activityTile),
        const SizedBox(height: 22),
        _sectionTitle('खदान का सारांश', 'हिसाब', () => setState(() => tab = 3)),
        const SizedBox(height: 10),
        Container(
          decoration: softPanel(radius: 22),
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('अभी तक का रिकॉर्ड', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 14),
            _summaryLine('कुल Hyva एंट्री', '$trips'),
            _summaryLine('कुल बिक्री', money(sales)),
            _summaryLine('कुल खर्च', money(expenses)),
            _summaryLine('शुद्ध बचत', money(sales - expenses)),
          ]),
        ),
      ]),
    );
  }

  Widget _metric(IconData icon, String value, String label) => Container(
        decoration: softPanel(radius: 22),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: muted, size: 22),
          const SizedBox(height: 9),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: ink)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 12, color: muted)),
        ]),
      );

  Widget _quick(IconData icon, String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: softPanel(radius: 20),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 26, color: ink),
            const SizedBox(height: 9),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: ink, height: 1.3)),
          ]),
        ),
      );

  Widget _sectionTitle(String title, String action, VoidCallback onTap) => Row(children: [
        Container(width: 4, height: 24, decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ink))),
        TextButton(onPressed: onTap, child: Text(action, style: const TextStyle(color: muted))),
      ]);

  IconData _iconFor(dynamic type) => type == 'hyva'
      ? Icons.local_shipping_rounded
      : (type == 'attendance' || type == 'labourPay')
          ? Icons.groups_rounded
          : Icons.receipt_long_rounded;

  String _titleFor(Map<String, dynamic> e) {
    switch (e['type']) {
      case 'hyva':
        return '${e['vehicle'] ?? 'Hyva'}';
      case 'attendance':
        return 'हाजिरी • ${e['name'] ?? ''}';
      case 'labourPay':
        return '${e['kind'] ?? 'भुगतान'} • ${e['name'] ?? ''}';
      default:
        return 'खर्च • ${e['category'] ?? ''}';
    }
  }

  String _subFor(Map<String, dynamic> e) {
    switch (e['type']) {
      case 'hyva':
        return '${e['details'] ?? e['sand'] ?? ''}';
      case 'attendance':
        return '${e['work'] ?? ''}';
      default:
        return '${e['description'] ?? ''}';
    }
  }

  double _amountFor(Map<String, dynamic> e) {
    switch (e['type']) {
      case 'hyva':
        return _n(e['total']);
      case 'attendance':
        return _n(e['wage']);
      default:
        return _n(e['amount']);
    }
  }

  Widget _activityTile(Map<String, dynamic> e) => Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(13),
        decoration: softPanel(radius: 17),
        child: Row(children: [
          Icon(_iconFor(e['type']), color: muted, size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_titleFor(e), style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('${_subFor(e)} • ${money(_amountFor(e))}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 12)),
            ]),
          ),
          Text(e['date'] ?? '', style: const TextStyle(color: muted, fontSize: 11)),
        ]),
      );

  Widget _recordList(String title, IconData icon, List<String> types, Widget fab) {
    final rows = records.where((e) => types.contains(e['type'])).toList();
    return _pageScaffold(title, icon, [
      if (rows.isEmpty) _empty('अभी कोई रिकॉर्ड नहीं', 'नई एंट्री जोड़ने के लिए नीचे दिए बटन का उपयोग करें।', icon),
      ...rows.map(_recordCard),
    ], fab);
  }

  Widget _recordCard(Map<String, dynamic> e) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: softPanel(radius: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(_titleFor(e), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
            Text(e['date'] ?? '', style: const TextStyle(color: muted, fontSize: 12)),
          ]),
          const SizedBox(height: 7),
          Text(_subFor(e), style: const TextStyle(color: muted)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(money(_amountFor(e)), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
            IconButton(onPressed: () => _editRecord(e), icon: const Icon(Icons.edit_outlined)),
            IconButton(onPressed: () => _confirmDelete(e), icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
          ]),
        ]),
      );

  Widget _accounts() => _pageScaffold('हिसाब-किताब', Icons.menu_book_rounded, [
        _summaryCard('कुल बिक्री', money(sales), Icons.trending_up),
        _summaryCard('मिला हुआ भुगतान', money(received), Icons.payments_outlined),
        _summaryCard('बाकी लेना', money(pending), Icons.hourglass_bottom_rounded),
        _summaryCard('मजदूरी (हाजिरी)', money(wages), Icons.groups_rounded),
        _summaryCard('अन्य खर्च', money(otherExpenses), Icons.receipt_long),
        _summaryCard('कुल खर्च', money(expenses), Icons.local_gas_station_rounded),
        _summaryCard('शुद्ध बचत', money(sales - expenses), Icons.account_balance_wallet),
        if (records.isEmpty)
          _empty('रिपोर्ट तैयार है', 'अभी कोई रिकॉर्ड नहीं है। एंट्री जोड़ने के बाद यहाँ हिसाब दिखाई देगा।', Icons.bar_chart_rounded),
      ]);

  Widget _summaryCard(String title, String value, IconData icon) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(17),
        decoration: softPanel(radius: 20),
        child: Row(children: [
          Icon(icon, color: muted),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        ]),
      );

  Widget _more() => _pageScaffold('अन्य सुविधाएं', Icons.grid_view_rounded, [
        _menuItem(Icons.groups_rounded, 'मजदूर हाजिरी', 'मजदूर जोड़ें, शिफ्ट और मजदूरी', _attendance),
        _menuItem(Icons.payments_outlined, 'मजदूर भुगतान', 'भुगतान और एडवांस का हिसाब', _labourPayment),
        _menuItem(Icons.account_balance_wallet_outlined, 'मजदूर का हिसाब', 'हर मजदूर की कमाई, भुगतान और बाकी', _labourLedger),
        _menuItem(Icons.file_download_outlined, 'Excel / PDF Export', 'रिपोर्ट एक्सपोर्ट', _exportInfo),
        _menuItem(Icons.settings_outlined, 'सेटिंग', 'खदान और ऐप सेटिंग', _settingsInfo),
      ]);

  Widget _menuItem(IconData icon, String title, String sub, VoidCallback action) => InkWell(
        onTap: action,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: softPanel(radius: 18),
          child: Row(children: [
            Icon(icon, size: 25),
            const SizedBox(width: 13),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(sub, style: const TextStyle(color: muted, fontSize: 12)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: muted),
          ]),
        ),
      );

  Widget _pageScaffold(String title, IconData icon, List<Widget> children, [Widget? fab]) => Scaffold(
        backgroundColor: canvas,
        appBar: AppBar(
          title: Row(children: [
            Icon(icon, size: 22),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          ]),
        ),
        body: ListView(padding: const EdgeInsets.all(18), children: children),
        floatingActionButton: fab,
      );

  Widget _empty(String title, String sub, IconData icon) => Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
        decoration: softPanel(radius: 22),
        child: Column(children: [
          Icon(icon, size: 42, color: const Color(0xFF9AA0A4)),
          const SizedBox(height: 13),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12, height: 1.5)),
        ]),
      );

  Widget _summaryLine(String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(a, style: const TextStyle(color: muted))),
          Text(b, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      );

  // ---------- forms ----------
  Future<void> _openForm(Widget form) async {
    final f = await showModalBottomSheet>(
      context: context, isScrollControlled: true, backgroundColor: canvas, builder: (_) => form);
    if (f != null) await _save(f);
  }

  Future<void> _hyvaForm() => _openForm(const HyvaForm());
  Future<void> _expenseForm() => _openForm(const ExpenseForm());
  Future<void> _attendance() => _openForm(const AttendanceForm());
  Future<void> _labourPayment() => _openForm(const LabourPaymentForm());

  void _labourLedger() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LabourLedgerPage(records: records)));
  }

  void _exportInfo() => snack(context, 'Export सुविधा अगले चरण में जोड़ी जाएगी। अभी रिकॉर्ड फोन में सुरक्षित रहते हैं।');
  void _settingsInfo() => snack(context, 'खदान का नाम और अन्य सेटिंग अगले चरण में जोड़ी जाएंगी।');

  Future<void> _confirmDelete(Map<String, dynamic> e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('रिकॉर्ड हटाएं?'),
        content: const Text('यह रिकॉर्ड स्थायी रूप से हट जाएगा।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('रद्द करें')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('हटाएं')),
        ],
      ),
    );
    if (ok == true) await _delete(e);
  }

  Future<void> _editRecord(Map<String, dynamic> e) async {
    final hasAmount = e['type'] == 'expense' || e['type'] == 'labourPay';
    final desc = TextEditingController(text: '${e['description'] ?? e['details'] ?? ''}');
    final amt = TextEditingController(text: hasAmount ? _n(e['amount']).toStringAsFixed(0) : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('संपादित करें'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: desc, decoration: const InputDecoration(labelText: 'विवरण')),
          if (hasAmount)
            TextField(controller: amt, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'रकम (₹)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('रद्द')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('सेव')),
        ],
      ),
    );
    if (ok != true) return;
    e['description'] = desc.text;
    if (e['type'] == 'hyva') e['details'] = desc.text;
    if (hasAmount) {
      final a = double.tryParse(amt.text) ?? 0;
      if (a > 0) e['amount'] = a;
    }
    await LocalStore.save(records);
    if (mounted) setState(() {});
  }
}

// ---------- labour ledger ----------
class LabourLedgerPage extends StatelessWidget {
  final List> records;
  const LabourLedgerPage({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final earned = <String, double>{};
    final paid = <String, double>{};
    for (final e in records) {
      final name = '${e['name'] ?? ''}'.trim();
      if (name.isEmpty) continue;
      if (e['type'] == 'attendance') earned[name] = (earned[name] ?? 0) + _n(e['wage']);
      if (e['type'] == 'labourPay') paid[name] = (paid[name] ?? 0) + _n(e['amount']);
    }
    final names = {...earned.keys, ...paid.keys}.toList()..sort();
    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(title: const Text('मजदूर का हिसाब', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600))),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        if (names.isEmpty)
          Container(
            padding: const EdgeInsets.all(30),
            decoration: softPanel(radius: 22),
            child: const Text('अभी कोई मजदूर रिकॉर्ड नहीं है।', textAlign: TextAlign.center, style: TextStyle(color: muted)),
          ),
        ...names.map((n) {
          final ea = earned[n] ?? 0, pa = paid[n] ?? 0, bal = ea - pa;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: softPanel(radius: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              rowText('कुल मजदूरी', money(ea)),
              rowText('भुगतान / एडवांस', money(pa)),
              rowText(bal >= 0 ? 'बाकी देना' : 'एडवांस ज्यादा', money(bal.abs())),
            ]),
          );
        }),
      ]),
    );
  }
}

// ---------- form frame ----------
class FormFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const FormFrame({super.key, required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(context).viewInsets.bottom + 22),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFB8BDC1), borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            ...children,
          ]),
        ),
      );
}

// ---------- Hyva form ----------
class HyvaForm extends StatefulWidget {
  const HyvaForm({super.key});
  @override
  State<HyvaForm> createState() => _HyvaFormState();
}

class _HyvaFormState extends State<HyvaForm> {
  final vehicle = TextEditingController(), tyre = TextEditingController(), owner = TextEditingController(),
      driver = TextEditingController(), mobile = TextEditingController(), sandAmount = TextEditingController(),
      royaltyQty = TextEditingController(), royaltyAmount = TextEditingController(), online = TextEditingController(),
      cash = TextEditingController(), receiver = TextEditingController(), sender = TextEditingController();
  DateTime date = DateTime.now();
  TimeOfDay time = TimeOfDay.now();
  String sand = 'Medium';

  double get total => (double.tryParse(sandAmount.text) ?? 0) + (double.tryParse(royaltyAmount.text) ?? 0);
  double get paid => (double.tryParse(online.text) ?? 0) + (double.tryParse(cash.text) ?? 0);
  void _upd(String _) => setState(() {});

  @override
  Widget build(BuildContext context) => FormFrame(title: 'नई Hyva एंट्री', children: [
        field('गाड़ी नंबर', vehicle, hint: 'जैसे CG 04 AB 1234'),
        Row(children: [
          Expanded(child: field('टायर', tyre, hint: '10 / 12 / 14')),
          const SizedBox(width: 8),
          Expanded(child: field('मोबाइल नंबर', mobile, type: TextInputType.phone)),
        ]),
        field('मालिक का नाम', owner),
        field('ड्राइवर का नाम', driver),
        Row(children: [
          Expanded(child: dateButton(context, date, (d) => setState(() => date = d))),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final t = await showTimePicker(context: context, initialTime: time);
                if (t != null) setState(() => time = t);
              },
              icon: const Icon(Icons.access_time),
              label: Text(time.format(context)),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        dd('रेत का प्रकार', sand, ['Medium', 'Medium Fine', 'Fine Plaster'], (v) => setState(() => sand = v!)),
        field('रेत की रकम (₹)', sandAmount, type: TextInputType.number, onChanged: _upd),
        const Text('Royalty', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: field('Quantity', royaltyQty, type: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(child: field('Amount (₹)', royaltyAmount, type: TextInputType.number, onChanged: _upd)),
        ]),
        field('Online Payment (₹)', online, type: TextInputType.number, onChanged: _upd),
        field('Cash Payment (₹)', cash, type: TextInputType.number, onChanged: _upd),
        field('Online Receiver', receiver),
        field('Sender', sender),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: softPanel(radius: 15),
          child: Column(children: [
            rowText('कुल रकम', money(total)),
            rowText('कुल भुगतान', money(paid)),
            rowText('बाकी', money((total - paid).clamp(0, double.infinity).toDouble())),
            rowText('स्थिति', paid >= total && total > 0 ? 'जमा' : 'बाकी'),
          ]),
        ),
        const SizedBox(height: 16),
        saveButton(context, () {
          if (vehicle.text.trim().isEmpty) {
            snack(context, 'गाड़ी नंबर जरूरी है');
            return;
          }
          if (total <= 0) {
            snack(context, 'रेत या royalty की रकम डालें');
            return;
          }
          Navigator.pop(context, {
            'type': 'hyva',
            'date': fmt(date),
            'time': time.format(context),
            'vehicle': vehicle.text.trim(),
            'tyre': tyre.text,
            'owner': owner.text,
            'driver': driver.text,
            'mobile': mobile.text,
            'sand': sand,
            'sandAmount': sandAmount.text,
            'royaltyQty': royaltyQty.text,
            'royaltyAmount': royaltyAmount.text,
            'online': online.text,
            'cash': cash.text,
            'receiver': receiver.text,
            'sender': sender.text,
            'total': total,
            'paid': paid,
            'details': '$sand • ${driver.text} • ${time.format(context)}',
          });
        }),
      ]);
}

// ---------- Expense form ----------
class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key});
  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final amount = TextEditingController(), desc = TextEditingController();
  String category = 'डीजल', mode = 'Cash';
  DateTime date = DateTime.now();

  @override
  Widget build(BuildContext context) => FormFrame(title: 'दैनिक खर्च', children: [
        dd('खर्च का प्रकार', category, ['डीजल', 'मजदूरी', 'मशीन मरम्मत', 'गाड़ी खर्च', 'खाना-पानी', 'मशीन किराया', 'अन्य'], (v) => setState(() => category = v!)),
        field('विवरण', desc, hint: 'खर्च किसलिए हुआ?'),
        field('रकम (₹)', amount, type: TextInputType.number),
        dd('भुगतान माध्यम', mode, ['Cash', 'Online'], (v) => setState(() => mode = v!)),
        dateButton(context, date, (d) => setState(() => date = d)),
        const SizedBox(height: 12),
        saveButton(context, () {
          final a = double.tryParse(amount.text) ?? 0;
          if (a <= 0) {
            snack(context, 'सही रकम डालें');
            return;
          }
          Navigator.pop(context, {
            'type': 'expense',
            'date': fmt(date),
            'category': category,
            'description': desc.text,
            'amount': a,
            'mode': mode,
          });
        }),
      ]);
}

// ---------- Attendance form ----------
const workOptions = {
  'Day': 1.0,
  'Night': 1.0,
  'Half Day': 0.5,
  'Half Night': 0.5,
  'Full Day + Half Night': 1.5,
  'Day + Night': 2.0,
  'Half Day + Half Night': 1.0,
  'Absent': 0.0,
  'Holiday': 0.0,
};

class AttendanceForm extends StatefulWidget {
  const AttendanceForm({super.key});
  @override
  State<AttendanceForm> createState() => _AttendanceFormState();
}

class _AttendanceFormState extends State<AttendanceForm> {
  final name = TextEditingController(), daily = TextEditingController();
  String work = 'Day';
  DateTime date = DateTime.now();
  double get wage => (double.tryParse(daily.text) ?? 0) * (workOptions[work] ?? 1);

  @override
  Widget build(BuildContext context) => FormFrame(title: 'मजदूर हाजिरी', children: [
        field('मजदूर का नाम', name, hint: 'मजदूर का नाम'),
        field('दिहाड़ी (₹)', daily, type: TextInputType.number, hint: 'एक दिन की दिहाड़ी', onChanged: (_) => setState(() {})),
        dd('आज का काम / शिफ्ट', work, workOptions.keys.toList(), (v) => setState(() => work = v!)),
        dateButton(context, date, (d) => setState(() => date = d)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(14), decoration: softPanel(), child: rowText('आज की मजदूरी', money(wage))),
        const SizedBox(height: 12),
        saveButton(context, () {
          if (name.text.trim().isEmpty || daily.text.trim().isEmpty) {
            snack(context, 'नाम और दिहाड़ी जरूरी है');
            return;
          }
          Navigator.pop(context, {
            'type': 'attendance',
            'date': fmt(date),
            'name': name.text.trim(),
            'dailyRate': double.tryParse(daily.text) ?? 0,
            'work': work,
            'wage': wage,
          });
        }),
      ]);
}

// ---------- Labour payment form ----------
class LabourPaymentForm extends StatefulWidget {
  const LabourPaymentForm({super.key});
  @override
  State<LabourPaymentForm> createState() => _LabourPaymentFormState();
}

class _LabourPaymentFormState extends State<LabourPaymentForm> {
  final name = TextEditingController(), amount = TextEditingController(), note = TextEditingController();
  String kind = 'भुगतान', mode = 'Cash';
  DateTime date = DateTime.now();

  @override
  Widget build(BuildContext context) => FormFrame(title: 'मजदूर भुगतान / एडवांस', children: [
        field('मजदूर का नाम', name),
        dd('एंट्री का प्रकार', kind, ['भुगतान', 'एडवांस'], (v) => setState(() => kind = v!)),
        field('रकम (₹)', amount, type: TextInputType.number),
        dd('माध्यम', mode, ['Cash', 'Online'], (v) => setState(() => mode = v!)),
        field('नोट', note),
        dateButton(context, date, (d) => setState(() => date = d)),
        const SizedBox(height: 12),
        saveButton(context, () {
          final a = double.tryParse(amount.text) ?? 0;
          if (name.text.trim().isEmpty || a <= 0) {
            snack(context, 'नाम और सही रकम जरूरी है');
            return;
          }
          Navigator.pop(context, {
            'type': 'labourPay',
            'date': fmt(date),
            'name': name.text.trim(),
            'kind': kind,
            'amount': a,
            'mode': mode,
            'description': note.text,
          });
        }),
      ]);
