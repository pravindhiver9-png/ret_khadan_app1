import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';
import 'export_service.dart';
import 'royalty_entry_screen.dart';

class HyvaListHubScreen extends StatelessWidget {
  const HyvaListHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.desertSand,
          foregroundColor: AppColors.charcoal,
          title: Text(lang.tr('Hyva Entry List & Statement', 'Hyva Entry List')),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.earthBrown,
            tabs: [
              Tab(text: lang.tr('Date Wise', 'Date Wise')),
              Tab(text: lang.tr('Monthly', 'Monthly')),
              Tab(text: lang.tr('All Entries', 'All Entries')),
              Tab(text: lang.tr('Owner Wise Statement', 'Owner Wise')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _HyvaFilteredList(mode: 'date'),
            _HyvaFilteredList(mode: 'month'),
            _HyvaFilteredList(mode: 'all'),
            OwnerWiseHyvaStatementTab(),
          ],
        ),
      ),
    );
  }
}

class _HyvaFilteredList extends StatefulWidget {
  final String mode;
  const _HyvaFilteredList({required this.mode});

  @override
  State<_HyvaFilteredList> createState() => _HyvaFilteredListState();
}

class _HyvaFilteredListState extends State<_HyvaFilteredList> {
  DateTime selectedDate = DateTime.now();
  RowList rows = <RowMap>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await AppDatabase.instance.database;
    final all = await db.query('hyva_entries', orderBy: 'id DESC');
    if (widget.mode == 'date') {
      final dStr = DateFormat('dd MMM yyyy').format(selectedDate);
      rows = all.where((e) => e['entry_date'] == dStr).toList();
    } else if (widget.mode == 'month') {
      final mStr = DateFormat('MMM yyyy').format(selectedDate);
      rows = all.where((e) => e['entry_date'].toString().endsWith(mStr)).toList();
    } else {
      rows = all;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filterLabel = widget.mode == 'date'
        ? DateFormat('dd MMM yyyy').format(selectedDate)
        : widget.mode == 'month'
            ? DateFormat('MMMM yyyy').format(selectedDate)
            : 'All Records';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              if (widget.mode != 'all')
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(filterLabel),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (d != null) {
                      selectedDate = d;
                      _load();
                    }
                  },
                ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.earthBrown,
                  foregroundColor: AppColors.white,
                ),
                onPressed: () => ExportService.exportHyvaPdf(
                  rows,
                  mode: widget.mode,
                  headerSubtitle: filterLabel,
                ),
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('PDF'),
              ),
            ],
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(child: Text(lang.tr('कोई एंट्री नहीं मिली', 'No entries found')))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: rows.length,
                  itemBuilder: (ctx, i) {
                    final r = rows[i];
                    return Card(
                      color: AppColors.white,
                      child: ListTile(
                        title: Text(
                          '${i + 1}. ${r['vehicle_no']} • ${r['owner_name']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${r['entry_date']} | Driver: ${r['driver_name']} (${r['mobile_no']})\nStatus: ${r['payment_status']} | Bal: ₹${r['balance_amount']}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final db = await AppDatabase.instance.database;
                            await db.delete('hyva_entries', where: 'id = ?', whereArgs: [r['id']]);
                            _load();
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class OwnerWiseHyvaStatementTab extends StatefulWidget {
  const OwnerWiseHyvaStatementTab({super.key});

  @override
  State<OwnerWiseHyvaStatementTab> createState() => _OwnerWiseHyvaStatementTabState();
}

class _OwnerWiseHyvaStatementTabState extends State<OwnerWiseHyvaStatementTab> {
  Map<String, RowList> byOwner = <String, RowList>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await AppDatabase.instance.database;
    final all = await db.query('hyva_entries', orderBy: 'id DESC');
    final map = <String, RowList>{};
    for (final r in all) {
      final owner = r['owner_name'].toString();
      map.putIfAbsent(owner, () => <RowMap>[]).add(r);
    }
    setState(() => byOwner = map);
  }

  @override
  Widget build(BuildContext context) {
    final owners = byOwner.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: owners.length,
      itemBuilder: (ctx, i) {
        final owner = owners[i];
        final list = byOwner[owner]!;
        double totalAmt = 0;
        double totalBal = 0;
        for (final item in list) {
          if (item['payment_status'] != 'Free') {
            totalAmt += ((item['amount'] as num?) ?? 0).toDouble();
            totalBal += ((item['balance_amount'] as num?) ?? 0).toDouble();
          }
        }
        return Card(
          color: AppColors.white,
          child: ListTile(
            title: Text(owner, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'कुल गाड़ियाँ: ${list.length} | कुल राशि: ₹${totalAmt.toStringAsFixed(0)} | बाकी Balance: ₹${totalBal.toStringAsFixed(0)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: AppColors.earthBrown),
              onPressed: () => ExportService.exportHyvaPdf(
                list,
                mode: 'owner',
                headerSubtitle: 'Owner Statement: $owner',
              ),
            ),
          ),
        );
      },
    );
  }
}

class RoyaltyListHubScreen extends StatelessWidget {
  const RoyaltyListHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.desertSand,
          foregroundColor: AppColors.charcoal,
          title: Text(lang.tr('Royalty Entry List', 'Royalty Entry List')),
          bottom: TabBar(
            labelColor: AppColors.earthBrown,
            tabs: [
              Tab(text: lang.tr('Date Wise', 'Date Wise')),
              Tab(text: lang.tr('Monthly', 'Monthly')),
              Tab(text: lang.tr('All Entries', 'All Entries')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RoyaltyFilteredList(mode: 'date'),
            _RoyaltyFilteredList(mode: 'month'),
            _RoyaltyFilteredList(mode: 'all'),
          ],
        ),
      ),
    );
  }
}

class _RoyaltyFilteredList extends StatefulWidget {
  final String mode;
  const _RoyaltyFilteredList({required this.mode});

  @override
  State<_RoyaltyFilteredList> createState() => _RoyaltyFilteredListState();
}

class _RoyaltyFilteredListState extends State<_RoyaltyFilteredList> {
  DateTime selectedDate = DateTime.now();
  RowList rows = <RowMap>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await AppDatabase.instance.database;
    final all = await db.query('royalty_entries', orderBy: 'id DESC');
    if (widget.mode == 'date') {
      final dStr = DateFormat('dd MMM yyyy').format(selectedDate);
      rows = all.where((e) => e['entry_date'] == dStr).toList();
    } else if (widget.mode == 'month') {
      final mStr = DateFormat('MMM yyyy').format(selectedDate);
      rows = all.where((e) => e['entry_date'].toString().endsWith(mStr)).toList();
    } else {
      rows = all;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.mode == 'date'
        ? DateFormat('dd MMM yyyy').format(selectedDate)
        : widget.mode == 'month'
            ? DateFormat('MMMM yyyy').format(selectedDate)
            : 'All Royalty Records';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              if (widget.mode != 'all')
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(label),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (d != null) {
                      selectedDate = d;
                      _load();
                    }
                  },
                ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.earthBrown,
                  foregroundColor: AppColors.white,
                ),
                onPressed: () => ExportService.exportRoyaltyPdf(
                  rows,
                  mode: widget.mode,
                  headerSubtitle: label,
                ),
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('PDF'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.desertSand,
                  foregroundColor: AppColors.charcoal,
                ),
                onPressed: () => ExportService.exportToExcel('Royalty_$label', rows),
                icon: const Icon(Icons.table_chart, size: 18),
                label: const Text('Excel'),
              ),
            ],
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(child: Text(lang.tr('कोई रॉयल्टी एंट्री नहीं है', 'No royalty entries')))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: rows.length,
                  itemBuilder: (ctx, i) {
                    final r = rows[i];
                    return Card(
                      color: AppColors.white,
                      child: ListTile(
                        title: Text(
                          '#${r['royalty_kramank']} • ${r['vehicle_no']} (${r['ghan_meter']} m³)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${r['entry_date']} ${r['entry_time']} → ${r['destination']}\nAmount: ₹${r['amount']}',
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
                                    builder: (_) => RoyaltyEntryScreen(existingRoyalty: r),
                                  ),
                                ).then((_) => _load());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final db = await AppDatabase.instance.database;
                                await db.delete('royalty_entries', where: 'id = ?', whereArgs: [r['id']]);
                                _load();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
