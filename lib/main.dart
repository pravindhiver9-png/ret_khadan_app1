import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'hyva_entry_screen.dart';
import 'royalty_entry_screen.dart';
import 'kharch_module_screen.dart';
import 'lists_and_statements_screen.dart';

typedef RowMap = Map<String, dynamic>;
typedef RowList = List<RowMap>;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;
  await BackupService.runDailyAutoBackupIfNeeded();
  runApp(const RetKhadanApp());
}

class AppColors {
  static const sandBeige = Color(0xFFF3E9D7);
  static const desertSand = Color(0xFFE3D1B3);
  static const naturalSand = Color(0xFFC5A77D);
  static const earthBrown = Color(0xFF8B6B48);
  static const charcoal = Color(0xFF45413A);
  static const white = Color(0xFFFFFFFF);
}

class LanguageProvider extends ChangeNotifier {
  bool isHindi = true;
  String tr(String hi, String en) => isHindi ? hi : en;

  void toggleLanguage() {
    isHindi = !isHindi;
    notifyListeners();
  }
}

final lang = LanguageProvider();

class RetKhadanApp extends StatelessWidget {
  const RetKhadanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: lang,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Ret Khadan Management',
          theme: ThemeData(
            fontFamily: 'NotoDevanagari',
            scaffoldBackgroundColor: AppColors.sandBeige,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.earthBrown,
              primary: AppColors.earthBrown,
              surface: AppColors.desertSand,
              onSurface: AppColors.charcoal,
            ),
            useMaterial3: true,
          ),
          home: const MpinGateScreen(),
        );
      },
    );
  }
}

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'ret_khadan.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE master_lists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            list_type TEXT NOT NULL,
            item_value TEXT NOT NULL,
            UNIQUE(list_type, item_value)
          )
        ''');

        await db.execute('''
          CREATE TABLE daily_rates (
            date_key TEXT PRIMARY KEY,
            loading_rate REAL NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE vehicles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vehicle_no TEXT UNIQUE NOT NULL,
            owner_name TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE drivers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vehicle_no TEXT NOT NULL,
            driver_name TEXT NOT NULL,
            mobile_no TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE jcb_masters (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            jcb_name TEXT UNIQUE NOT NULL,
            owner_name TEXT NOT NULL,
            op1 TEXT,
            op2 TEXT,
            op3 TEXT,
            helper1 TEXT,
            helper2 TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE hyva_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_date TEXT NOT NULL,
            entry_time TEXT NOT NULL,
            loading_rate REAL NOT NULL,
            khadan_name TEXT NOT NULL,
            vehicle_no TEXT NOT NULL,
            owner_name TEXT NOT NULL,
            driver_name TEXT NOT NULL,
            mobile_no TEXT NOT NULL,
            amount REAL NOT NULL,
            royalty_amount REAL NOT NULL DEFAULT 0,
            payment_mode TEXT NOT NULL,
            online_receiver TEXT,
            payment_status TEXT NOT NULL,
            balance_amount REAL NOT NULL DEFAULT 0,
            dalal_name TEXT,
            note TEXT,
            photo_path TEXT,
            royalty_id INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE royalty_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            royalty_kramank INTEGER NOT NULL,
            entry_date TEXT NOT NULL,
            entry_time TEXT NOT NULL,
            khadan_name TEXT NOT NULL,
            ghan_meter REAL NOT NULL,
            destination TEXT NOT NULL,
            royalty_cutter TEXT NOT NULL,
            royalty_receiver TEXT,
            vehicle_no TEXT NOT NULL,
            owner_name TEXT NOT NULL,
            driver_name TEXT NOT NULL,
            mobile_no TEXT NOT NULL,
            amount REAL NOT NULL,
            photo_path TEXT,
            hyva_entry_id INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            entry_date TEXT NOT NULL,
            entry_time TEXT,
            amount REAL NOT NULL,
            paid_amount REAL NOT NULL DEFAULT 0,
            balance_amount REAL NOT NULL DEFAULT 0,
            payment_status TEXT,
            paid_date TEXT,
            vehicle_no TEXT,
            owner_name TEXT,
            person_name TEXT,
            village_name TEXT,
            designation TEXT,
            sub_type TEXT,
            quantity REAL,
            extra_json TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE besharam_payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            expense_id INTEGER NOT NULL,
            vehicle_no TEXT NOT NULL,
            owner_name TEXT NOT NULL,
            paid_amount REAL NOT NULL,
            payment_date TEXT NOT NULL,
            payment_mode TEXT NOT NULL,
            note TEXT
          )
        ''');
      },
    );
    return _db!;
  }
}

class BackupService {
  static const _lastBackupKey = 'last_auto_backup_date';

  static Future<File?> runDailyAutoBackupIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = prefs.getString(_lastBackupKey);
    if (lastDate == todayKey) return null;
    return createBackupNow(todayKey: todayKey);
  }

  static Future<File> createBackupNow({String? todayKey}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = todayKey ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dbPath = await getDatabasesPath();
    final sourceFile = File(p.join(dbPath, 'ret_khadan.db'));

    final appDocDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(appDocDir.path, 'AutoBackups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final backupFile = File(p.join(backupDir.path, 'ret_khadan_backup_$key.db'));
    if (await sourceFile.exists()) {
      await sourceFile.copy(backupFile.path);
    }
    await prefs.setString(_lastBackupKey, key);
    return backupFile;
  }

  static Future<List<File>> listBackups() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(appDocDir.path, 'AutoBackups'));
    if (!await backupDir.exists()) return <File>[];
    final files = backupDir.listSync().whereType<File>().toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  static Future<void> restoreFromBackup(File backupFile) async {
    final dbPath = await getDatabasesPath();
    final targetPath = p.join(dbPath, 'ret_khadan.db');
    await backupFile.copy(targetPath);
  }
}

class MpinGateScreen extends StatefulWidget {
  const MpinGateScreen({super.key});

  @override
  State<MpinGateScreen> createState() => _MpinGateScreenState();
}

class _MpinGateScreenState extends State<MpinGateScreen> {
  static const _mpinKey = 'saved_user_mpin';
  String? _savedMpin;
  String _firstEnteredPin = '';
  bool _isConfirmingNewPin = false;
  final TextEditingController _pinController = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadMpin();
  }

  Future<void> _loadMpin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedMpin = prefs.getString(_mpinKey);
    });
  }

  Future<void> _handleSubmit() async {
    final code = _pinController.text.trim();
    if (code.length < 4) {
      setState(() {
        _errorText = lang.tr(
          'कृपया कम से कम 4 अंकों का MPIN दर्ज करें',
          'Please enter at least a 4-digit MPIN',
        );
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    if (_savedMpin == null) {
      if (!_isConfirmingNewPin) {
        setState(() {
          _firstEnteredPin = code;
          _isConfirmingNewPin = true;
          _errorText = null;
          _pinController.clear();
        });
      } else {
        if (code == _firstEnteredPin) {
          await prefs.setString(_mpinKey, code);
          _goHome();
        } else {
          setState(() {
            _isConfirmingNewPin = false;
            _firstEnteredPin = '';
            _pinController.clear();
            _errorText = lang.tr(
              'MPIN मेल नहीं खाया, फिर से सेट करें',
              'MPIN did not match, please set again',
            );
          });
        }
      }
    } else {
      if (code == _savedMpin) {
        _goHome();
      } else {
        setState(() {
          _errorText = lang.tr('गलत MPIN', 'Incorrect MPIN');
          _pinController.clear();
        });
      }
    }
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFirstTime = _savedMpin == null;
    final title = isFirstTime
        ? (_isConfirmingNewPin
            ? lang.tr('MPIN की पुष्टि करें', 'Confirm Your MPIN')
            : lang.tr('नया MPIN बनाएं', 'Create New MPIN'))
        : lang.tr('MPIN दर्ज करें', 'Enter MPIN');

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.desertSand,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.naturalSand),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: lang.toggleLanguage,
                        child: Text(
                          lang.isHindi ? 'English' : 'हिन्दी',
                          style: const TextStyle(
                            color: AppColors.earthBrown,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.lock_outline, size: 48, color: AppColors.earthBrown),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, letterSpacing: 8),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.white,
                      counterText: '',
                      errorText: _errorText,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.earthBrown,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _handleSubmit,
                      child: Text(
                        isFirstTime
                            ? (_isConfirmingNewPin
                                ? lang.tr('सेव करें', 'Save MPIN')
                                : lang.tr('आगे बढ़ें', 'Continue'))
                            : lang.tr('अनलॉक करें', 'Unlock'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  int totalHyvaToday = 0;
  double totalRoyaltyToday = 0;
  double totalExpenseToday = 0;
  RowList recentItems = <RowMap>[];

  @override
  void initState() {
    super.initState();
    _loadTodaySummary();
  }

  Future<void> _loadTodaySummary() async {
    final db = await AppDatabase.instance.database;
    final todayStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    final hyvaRes = await db.rawQuery(
      'SELECT COUNT(*) as cnt, COALESCE(SUM(royalty_amount), 0) as r_sum FROM hyva_entries WHERE entry_date = ?',
      [todayStr],
    );
    final expRes = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as e_sum FROM expenses WHERE entry_date = ?',
      [todayStr],
    );

    final recentHyva = await db.query(
      'hyva_entries',
      orderBy: 'id DESC',
      limit: 5,
    );

    setState(() {
      totalHyvaToday = (hyvaRes.first['cnt'] as int?) ?? 0;
      totalRoyaltyToday = ((hyvaRes.first['r_sum'] as num?) ?? 0).toDouble();
      totalExpenseToday = ((expRes.first['e_sum'] as num?) ?? 0).toDouble();
      recentItems = recentHyva;
    });
  }

  double get netRemaining => totalRoyaltyToday - totalExpenseToday;

  Future<void> _openRestoreDialog() async {
    final files = await BackupService.listBackups();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sandBeige,
        title: Text(lang.tr('बैकअप एवं Restore', 'Backup & Restore')),
        content: SizedBox(
          width: double.maxFinite,
          child: files.isEmpty
              ? Text(lang.tr('कोई बैकअप फाइल नहीं मिली', 'No backup files found'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: files.length,
                  itemBuilder: (_, i) {
                    final f = files[i];
                    return ListTile(
                      title: Text(p.basename(f.path), style: const TextStyle(fontSize: 13)),
                      trailing: TextButton(
                        onPressed: () async {
                          await BackupService.restoreFromBackup(f);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          _loadTodaySummary();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                lang.tr('डेटा Restore हो गया!', 'Data Restored!'),
                              ),
                            ),
                          );
                        },
                        child: const Text('Restore'),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.earthBrown,
              foregroundColor: AppColors.white,
            ),
            onPressed: () async {
              await BackupService.createBackupNow();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(lang.tr('नया बैकअप बन गया', 'New Backup Created'))),
              );
            },
            child: Text(lang.tr('अभी बैकअप बनाएं', 'Backup Now')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE • dd MMMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.desertSand,
        foregroundColor: AppColors.charcoal,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ret Khadan Management',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              lang.tr('रेत खदान प्रबंधन', 'Sand Mine Operations'),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: lang.tr('भाषा बदलें', 'Switch Language'),
            onPressed: () {
              lang.toggleLanguage();
              setState(() {});
            },
            icon: const Icon(Icons.translate),
          ),
          IconButton(
            tooltip: lang.tr('बैकअप एवं Restore', 'Backup & Restore'),
            onPressed: _openRestoreDialog,
            icon: const Icon(Icons.backup_outlined),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.sandBeige,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.earthBrown),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    lang.tr('मेनू / Menu', 'Menu'),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    lang.tr('रेत खदान प्रबंधन', 'Ret Khadan Management'),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping, color: AppColors.earthBrown),
              title: Text(lang.tr('1. Hyva Entry List & Statement', '1. Hyva Entry List & Statement')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HyvaListHubScreen()),
                ).then((_) => _loadTodaySummary());
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: AppColors.earthBrown),
              title: Text(lang.tr('2. Royalty Entry List', '2. Royalty Entry List')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RoyaltyListHubScreen()),
                ).then((_) => _loadTodaySummary());
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: AppColors.earthBrown),
              title: Text(lang.tr('3. Kharch List & Statement', '3. Kharch List & Statement')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KharchHubScreen()),
                ).then((_) => _loadTodaySummary());
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTodaySummary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.desertSand,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.tr('नमस्कार!', 'Namaskar!')),
                  const SizedBox(height: 4),
                  Text(
                    lang.tr('आज का हिसाब', "Today's Summary"),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(formattedDate, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              lang.tr('आज का कारोबार', "Today's Business"),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                _StatCard(
                  title: lang.tr('कुल हाइवा', 'Total Hyva'),
                  value: '$totalHyvaToday',
                  icon: Icons.local_shipping_outlined,
                ),
                _StatCard(
                  title: lang.tr('कुल रॉयल्टी', 'Total Royalty'),
                  value: '₹${totalRoyaltyToday.toStringAsFixed(0)}',
                  icon: Icons.receipt_outlined,
                ),
                _StatCard(
                  title: lang.tr('कुल खर्च', 'Total Expense'),
                  value: '₹${totalExpenseToday.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                _StatCard(
                  title: lang.tr('शेष राशि', 'Remaining'),
                  value: '₹${netRemaining.toStringAsFixed(0)}',
                  icon: Icons.payments_outlined,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              lang.tr('मुख्य एंट्री', 'Quick Actions'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.earthBrown,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HyvaEntryScreen()),
                      ).then((_) => _loadTodaySummary());
                    },
                    icon: const Icon(Icons.local_shipping),
                    label: Text(lang.tr('हाइवा एंट्री', 'Hyva Entry')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.earthBrown,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RoyaltyEntryScreen()),
                      ).then((_) => _loadTodaySummary());
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: Text(lang.tr('रॉयल्टी एंट्री', 'Royalty Entry')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.desertSand,
                  foregroundColor: AppColors.charcoal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KharchHubScreen()),
                  ).then((_) => _loadTodaySummary());
                },
                icon: const Icon(Icons.account_balance_wallet),
                label: Text(lang.tr('खर्च एंट्री', 'Expense Entry')),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              lang.tr('हाल की एंट्री', 'Recent Entries'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (recentItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(lang.tr('अभी कोई एंट्री नहीं है', 'No entries yet')),
              )
            else
              ...recentItems.map(
                (item) => Card(
                  color: AppColors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      '${item['vehicle_no']} • ${item['owner_name']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${item['entry_date']} • ${item['khadan_name']} • ${item['payment_status']}',
                    ),
                    trailing: Text(
                      '₹${item['amount']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.naturalSand.withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.earthBrown, size: 22),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.charcoal)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}
