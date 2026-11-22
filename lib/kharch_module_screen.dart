import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'main.dart';
import 'export_service.dart';

class KharchHubScreen extends StatelessWidget {
  const KharchHubScreen({super.key});

  static const List> categories = [
    {'key': 'JCB', 'hi': '1. JCB खर्च', 'en': '1. JCB Expense'},
    {'key': 'Diesel', 'hi': '2. Diesel खर्च', 'en': '2. Diesel Expense'},
    {'key': 'Media', 'hi': '3. Media खर्च', 'en': '3. Media Expense'},
    {'key': 'Khana', 'hi': '4. Khana खर्च', 'en': '4. Food Expense'},
    {'key': 'Besharam', 'hi': '5. बेशरम वाला', 'en': '5. Besharam Wala'},
    {'key': 'Majdoori', 'hi': '6. मजदूरी', 'en': '6. Labour / Majdoori'},
    {'key': 'GaonFund', 'hi': '7. गाँव फंड', 'en': '7. Village Fund'},
    {'key': 'Other', 'hi': '8. अन्य खर्च', 'en': '8. Other Expense'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.desertSand,
        foregroundColor: AppColors.charcoal,
        title: Text(lang.tr('खर्च मॉड्यूल (Expense)', 'Expense Module')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.1,
            ),
            itemCount: categories.length,
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.earthBrown,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KharchCategoryScreen(
                        categoryKey: cat['key']!,
                        title: lang.tr(cat['hi']!, cat['en']!),
                      ),
                    ),
                  );
                },
                child: Text(
                  lang.tr(cat['hi']!, cat['en']!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.desertSand,
              foregroundColor: AppColors.charcoal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CombinedExpenseStatementScreen()),
              );
            },
            icon: const Icon(Icons.summarize),
            label: Text(
              lang.tr('संयुक्त खर्च स्टेटमेंट (Expense Statement)', 'Combined Expense Statement'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.naturalSand,
              foregroundColor: AppColors.charcoal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BesharamBalanceStatementScreen()),
              );
            },
            icon: const Icon(Icons.account_balance),
            label: Text(
              lang.tr('बेशरम वाला Balance Statement', 'Besharam Wala Balance Statement'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class KharchCategoryScreen extends StatefulWidget {
  final String categoryKey;
  final String title;

  const KharchCategoryScreen({
    super.key,
    required this.categoryKey,
    required this.title,
  });

  @override
  State<KharchCategoryScreen> createState() => _KharchCategoryScreenState();
}

class _KharchCategoryScreenState extends State<KharchCategoryScreen> {
  List> entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await AppDatabase.instance.database;
    entries = await db.query(
      'expenses',
      where: 'category = ?',
      whereArgs: [widget.categoryKey],
      orderBy: 'id DESC',
    );
    if (mounted) setState(() {});
  }

  Future<void> _exportOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sandBeige,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: Text(lang.tr('Date Wise PDF', 'Date Wise PDF')),
            onTap: () async {
              Navigator.pop(ctx);
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked == null) return;
              final dStr = DateFormat('dd MMM yyyy').format(picked);
              final filtered = entries.where((e) => e['entry_date'] == dStr).toList();
              await ExportService.exportKharchPdf(widget.title, filtered, 'Date: $dStr');
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: Text(lang.tr('Monthly PDF', 'Monthly PDF')),
            onTap: () async {
              Navigator.pop(ctx);
              final mStr = DateFormat('MMM yyyy').format(DateTime.now());
              final filtered = entries
                  .where((e) => e['entry_date'].toString().endsWith(mStr))
                  .toList();
              await ExportService.exportKharchPdf(widget.title, filtered, 'Month: $mStr');
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: Text(lang.tr('All PDF', 'All PDF')),
            onTap: () async {
              Navigator.pop(ctx);
              await ExportService.exportKharchPdf(widget.title, entries, 'All Records');
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: Text(lang.tr('Excel Export / Share', 'Excel Export / Share')),
            onTap: () async {
              Navigator.pop(ctx);
              await ExportService.exportToExcel(widget.title, entries);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.desertSand,
        foregroundColor: AppColors.charcoal,
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'PDF / Excel',
            icon: const Icon(Icons.share),
            onPressed: _exportOptions,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.earthBrown,
        foregroundColor: AppColors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => KharchFormScreen(
                categoryKey: widget.categoryKey,
                title: widget.title,
              ),
            ),
          ).then((_) => _load());
        },
        icon: const Icon(Icons.add),
        label: Text(lang.tr('नई एंट्री', 'New Entry')),
      ),
      body: entries.isEmpty
          ? Center(child: Text(lang.tr('कोई रिकॉर्ड नहीं है', 'No records found')))
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: entries.length,
              itemBuilder: (ctx, i) {
                final item = entries[i];
                return Card(
                  color: AppColors.white,
                  child: ListTile(
                    title: Text(
                      '₹${item['amount']} • ${item['entry_date']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${item['person_name'] ?? ''} ${item['vehicle_no'] ?? ''} ${item['sub_type'] ?? ''} ${item['payment_status'] ?? ''}'
                          .trim(),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.earthBrown),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => KharchFormScreen(
                                  categoryKey: widget.categoryKey,
                                  title: widget.title,
                                  existing: item,
                                ),
                              ),
                            ).then((_) => _load());
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final db = await AppDatabase.instance.database;
                            await db.delete('expenses', where: 'id = ?', whereArgs: [item['id']]);
                            _load();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class KharchFormScreen extends StatefulWidget {
  final String categoryKey;
  final String title;
  final Map<String, dynamic>? existing;

  const KharchFormScreen({
    super.key,
    required this.categoryKey,
    required this.title,
    this.existing,
  });

  @override
  State<KharchFormScreen> createState() => _KharchFormScreenState();
}

class _KharchFormScreenState extends State<KharchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  final _amountCtrl = TextEditingController();
  final _paidCtrl = TextEditingController(text: '0');
  final _personCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  // JCB specific
  String _jcbSubType = 'JCB Service';
  String _jcbPaidTo = 'JCB मालिक';
  final _op1Ctrl = TextEditingController();
  final _op2Ctrl = TextEditingController();
  final _op3Ctrl = TextEditingController();
  final _h1Ctrl = TextEditingController();
  final _h2Ctrl = TextEditingController();

  // Media specific dynamic people
  int _mediaCount = 1;
  final List<TextEditingController> _mediaNames = [TextEditingController()];
  final List<TextEditingController> _mediaChannels = [TextEditingController()];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _amountCtrl.text = e['amount']?.toString() ?? '';
      _paidCtrl.text = e['paid_amount']?.toString() ?? '0';
      _personCtrl.text = e['person_name']?.toString() ?? '';
      _vehicleCtrl.text = e['vehicle_no']?.toString() ?? '';
      _ownerCtrl.text = e['owner_name']?.toString() ?? '';
      _villageCtrl.text = e['village_name']?.toString() ?? '';
      _designationCtrl.text = e['designation']?.toString() ?? '';
      _qtyCtrl.text = e['quantity']?.toString() ?? '';
    }
  }

  void _updateMediaRows(int count) {
    setState(() {
      _mediaCount = count;
      while (_mediaNames.length < count) {
        _mediaNames.add(TextEditingController());
        _mediaChannels.add(TextEditingController());
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = await AppDatabase.instance.database;

    final dateStr = DateFormat('dd MMM yyyy').format(_date);
    final timeStr = _time.format(context);
    final totalAmt = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final paidAmt = double.tryParse(_paidCtrl.text.trim()) ?? 0;
    final balAmt = (totalAmt - paidAmt).clamp(0, totalAmt);

    String status = 'Paid';
    if (widget.categoryKey == 'Besharam') {
      if (paidAmt <= 0) {
        status = 'Unpaid';
      } else if (paidAmt < totalAmt) {
        status = 'Partial';
      } else {
        status = 'Paid';
      }
    }

    final extraMap = <String, dynamic>{};
    if (widget.categoryKey == 'JCB') {
      extraMap['paid_to'] = _jcbPaidTo;
      extraMap['op1'] = _op1Ctrl.text.trim();
      extraMap['op2'] = _op2Ctrl.text.trim();
      extraMap['op3'] = _op3Ctrl.text.trim();
      extraMap['h1'] = _h1Ctrl.text.trim();
      extraMap['h2'] = _h2Ctrl.text.trim();

      await db.insert(
        'jcb_masters',
        {
          'jcb_name': _personCtrl.text.trim(),
          'owner_name': _ownerCtrl.text.trim(),
          'op1': _op1Ctrl.text.trim(),
          'op2': _op2Ctrl.text.trim(),
          'op3': _op3Ctrl.text.trim(),
          'helper1': _h1Ctrl.text.trim(),
          'helper2': _h2Ctrl.text.trim(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else if (widget.categoryKey == 'Media') {
      extraMap['people'] = List.generate(
        _mediaCount,
        (i) => {'name': _mediaNames[i].text.trim(), 'channel': _mediaChannels[i].text.trim()},
      );
    }

    final data = {
      'category': widget.categoryKey,
      'entry_date': dateStr,
      'entry_time': timeStr,
      'amount': totalAmt,
      'paid_amount': widget.categoryKey == 'Besharam' ? paidAmt : totalAmt,
      'balance_amount': widget.categoryKey == 'Besharam' ? balAmt : 0,
      'payment_status': status,
      'paid_date': status == 'Paid' ? dateStr : null,
      'vehicle_no': _vehicleCtrl.text.trim().toUpperCase(),
      'owner_name': _ownerCtrl.text.trim(),
      'person_name': _personCtrl.text.trim(),
      'village_name': _villageCtrl.text.trim(),
      'designation': _designationCtrl.text.trim(),
      'sub_type': widget.categoryKey == 'JCB' ? _jcbSubType : null,
      'quantity': double.tryParse(_qtyCtrl.text.trim()),
      'extra_json': jsonEncode(extraMap),
    };

    if (widget.existing != null) {
      await db.update('expenses', data, where: 'id = ?', whereArgs: [widget.existing!['id']]);
    } else {
      final expId = await db.insert('expenses', data);
      if (widget.categoryKey == 'Besharam' && paidAmt > 0) {
        await db.insert('besharam_payments', {
          'expense_id': expId,
          'vehicle_no': _vehicleCtrl.text.trim().toUpperCase(),
          'owner_name': _ownerCtrl.text.trim(),
          'paid_amount': paidAmt,
          'payment_date': dateStr,
          'payment_mode': 'Cash',
          'note': 'Initial Payment',
        });
      }
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.categoryKey;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.desertSand,
        foregroundColor: AppColors.charcoal,
        title: Text(widget.title),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(DateFormat('dd MMM yyyy').format(_date)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (d != null) setState(() => _date = d);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(_time.format(context)),
                    onPressed: () async {
                      final t = await showTimePicker(context: context, initialTime: _time);
                      if (t != null) setState(() => _time = t);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (k == 'JCB') ...[
              _box(_personCtrl, lang.tr('JCB कंपनी / नाम *', 'JCB Name *'), req: true),
              const SizedBox(height: 10),
              _box(_ownerCtrl, lang.tr('मालिक का नाम *', 'Owner Name *'), req: true),
              const SizedBox(height: 10),
              _box(_op1Ctrl, lang.tr('पहला ऑपरेटर', 'Operator 1')),
              const SizedBox(height: 10),
              _box(_op2Ctrl, lang.tr('दूसरा ऑपरेटर', 'Operator 2')),
              const SizedBox(height: 10),
              _box(_op3Ctrl, lang.tr('तीसरा ऑपरेटर', 'Operator 3')),
              const SizedBox(height: 10),
              _box(_h1Ctrl, lang.tr('पहला हेल्पर', 'Helper 1')),
              const SizedBox(height: 10),
              _box(_h2Ctrl, lang.tr('दूसरा हेल्पर', 'Helper 2')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _jcbSubType,
                decoration: InputDecoration(
                  labelText: lang.tr('खर्च का प्रकार', 'Expense Type'),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                items: ['JCB Service', 'Operator Personal', 'JCB किराया']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _jcbSubType = v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _jcbPaidTo,
                decoration: InputDecoration(
                  labelText: lang.tr('किसको पैसा दिया', 'Paid To'),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                items: ['JCB मालिक', 'ऑपरेटर', 'हेल्पर']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _jcbPaidTo = v!),
              ),
            ],

            if (k == 'Diesel') ...[
              _box(_qtyCtrl, lang.tr('डीजल की मात्रा (लीटर)', 'Diesel Litres'), num: true),
              const SizedBox(height: 10),
              _box(_personCtrl, lang.tr('डीजल लाने वाले का नाम', 'Brought By')),
            ],

            if (k == 'Media') ...[
              Row(
                children: [
                  Text(lang.tr('कितने लोग आए: ', 'Number of People: ')),
                  DropdownButton<int>(
                    value: _mediaCount,
                    items: List.generate(10, (i) => i + 1)
                        .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                        .toList(),
                    onChanged: (v) => _updateMediaRows(v ?? 1),
                  ),
                ],
              ),
              ...List.generate(
                _mediaCount,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(child: _box(_mediaNames[i], 'व्यक्ति ${i + 1} नाम')),
                      const SizedBox(width: 8),
                      Expanded(child: _box(_mediaChannels[i], 'चैनल / प्रेस ${i + 1}')),
                    ],
                  ),
                ),
              ),
            ],

            if (k == 'Khana') ...[
              _box(_personCtrl, lang.tr('बाज़ार / विवरण', 'Bazaar / Details')),
            ],

            if (k == 'Besharam') ...[
              _box(_vehicleCtrl, lang.tr('वाहन नंबर *', 'Vehicle No *'), req: true),
              const SizedBox(height: 10),
              _box(_ownerCtrl, lang.tr('मालिक का नाम *', 'Owner Name *'), req: true),
            ],

            if (k == 'GaonFund') ...[
              _box(_personCtrl, lang.tr('नाम *', 'Name *'), req: true),
            ],

            if (k == 'Other') ...[
              _box(_personCtrl, lang.tr('नाम *', 'Name *'), req: true),
              const SizedBox(height: 10),
              _box(_villageCtrl, lang.tr('गाँव का नाम', 'Village Name')),
              const SizedBox(height: 10),
              _box(_designationCtrl, lang.tr('पद का नाम (Optional)', 'Designation')),
            ],

            const SizedBox(height: 10),
            _box(
              _amountCtrl,
              k == 'Besharam'
                  ? lang.tr('कुल खर्च राशि (₹) *', 'Total Expense Amount (₹) *')
                  : lang.tr('राशि (₹) *', 'Amount (₹) *'),
              num: true,
              req: true,
            ),

            if (k == 'Besharam') ...[
              const SizedBox(height: 10),
              _box(
                _paidCtrl,
                lang.tr('भुगतान की गई राशि (₹)', 'Paid Amount (₹)'),
                num: true,
              ),
            ],

            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.earthBrown,
                  foregroundColor: AppColors.white,
                ),
                onPressed: _save,
                child: Text(lang.tr('Save करें', 'Save')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(TextEditingController c, String label, {bool num = false, bool req = false}) {
    return TextFormField(
      controller: c,
      keyboardType: num ? TextInputType.number : TextInputType.text,
      validator: req
          ? (v) => (v == null || v.trim().isEmpty) ? lang.tr('आवश्यक है', 'Required') : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Combined Expense Statement (Date-wise breakdown of all 8 categories)
class CombinedExpenseStatementScreen extends StatefulWidget {
  const CombinedExpenseStatementScreen({super.key});

  @override
  State<CombinedExpenseStatementScreen> createState() => _CombinedExpenseStatementScreenState();
}

class _CombinedExpenseStatementScreenState extends State<CombinedExpenseStatementScreen> {
  Map<String, List>> groupedByDate = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('expenses', orderBy: 'id DESC');
    final map = <String, List>>{};
    for (final r in rows) {
      final d = r['entry_date'].toString();
      map.putIfAbsent(d, () => []).add(r);
    }
    setState(() => groupedByDate = map);
  }

  @override
  Widget build(BuildContext context) {
    final dates = groupedByDate.keys.toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.desertSand,
        foregroundColor: AppColors.charcoal,
        title: Text(lang.tr('संयुक्त खर्च स्टेटमेंट', 'Expense Statement')),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: dates.length,
        itemBuilder: (ctx, i) {
          final date = dates[i];
          final items = groupedByDate[date]!;
          final dayTotal = items.fold<double>(
            0,
            (sum, e) => sum + ((e['amount'] as num?) ?? 0).toDouble(),
          );
          return Card(
            color: AppColors.white,
            child: ExpansionTile(
              title: Text('$date — ₹${dayTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              children: KharchHubScreen.categories.map((cat) {
                final catSum = items
                    .where((e) => e['category'] == cat['key'])
                    .fold<double>(0, (s, e) => s + ((e['amount'] as num?) ?? 0).toDouble());
                return ListTile(
                  dense: true,
                  title: Text(lang.tr(cat['hi']!, cat['en']!)),
                  trailing: Text('₹${catSum.toStringAsFixed(0)}'),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

/// Besharam Wala Dedicated Balance Statement + Partial/Full Installment Payment
class BesharamBalanceStatementScreen extends StatefulWidget {
  const BesharamBalanceStatementScreen({super.key});

  @override
  State<BesharamBalanceStatementScreen> createState() => _BesharamBalanceStatementScreenState();
}

class _BesharamBalanceStatementScreenState extends State<BesharamBalanceStatementScreen> {
  List> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await AppDatabase.instance.database;
    items = await db.query(
      'expenses',
      where: 'category = ?',
      whereArgs: ['Besharam'],
      orderBy: 'id DESC',
    );
    setState(() {});
  }

  Future<void> _addInstallment(Map<String, dynamic> exp) async {
    final payCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String mode = 'Cash';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sandBeige,
        title: Text('${exp['vehicle_no']} • ${exp['owner_name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('बाकी Balance: ₹${exp['balance_amount']}'),
            const SizedBox(height: 10),
            TextField(
              controller: payCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'भुगतान राशि (₹)',
                filled: true,
                fillColor: AppColors.white,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: mode,
              items: ['Cash', 'Online']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => mode = v!,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                filled: true,
                fillColor: AppColors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.earthBrown,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save Payment'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final addPay = double.tryParse(payCtrl.text.trim()) ?? 0;
    if (addPay <= 0) return;

    final db = await AppDatabase.instance.database;
    final total = ((exp['amount'] as num?) ?? 0).toDouble();
    final oldPaid = ((exp['paid_amount'] as num?) ?? 0).toDouble();
    final newPaid = (oldPaid + addPay).clamp(0, total);
    final newBal = (total - newPaid).clamp(0, total);
    final newStatus = newBal <= 0 ? 'Paid' : 'Partial';
    final todayStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    await db.insert('besharam_payments', {
      'expense_id': exp['id'],
      'vehicle_no': exp['vehicle_no'],
      'owner_name': exp['owner_name'],
      'paid_amount': addPay,
      'payment_date': todayStr,
      'payment_mode': mode,
      'note': noteCtrl.text.trim(),
    });

    await db.update(
      'expenses',
      {
        'paid_amount': newPaid,
        'balance_amount': newBal,
        'payment_status': newStatus,
        'paid_date': newStatus == 'Paid' ? todayStr : exp['paid_date'],
      },
      where: 'id = ?',
      whereArgs: [exp['id']],
    );

    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.desertSand,
        foregroundColor: AppColors.charcoal,
        title: Text(lang.tr('बेशरम वाला Balance Statement', 'Besharam Balance Statement')),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final e = items[i];
          final bal = ((e['balance_amount'] as num?) ?? 0).toDouble();
          return Card(
            color: AppColors.white,
            child: ListTile(
              title: Text('${e['vehicle_no']} • ${e['owner_name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'कुल: ₹${e['amount']} | जमा: ₹${e['paid_amount']} | बाकी: ₹$bal\nStatus: ${e['payment_status']}${e['paid_date'] != null ? ' (Paid: ${e['paid_date']})' : ''}',
              ),
              trailing: bal > 0
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.earthBrown,
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: () => _addInstallment(e),
                      child: const Text('Pay'),
                    )
                  : const Icon(Icons.check_circle, color: Colors.green),
            ),
          );
        },
      ),
    );
  }
}
