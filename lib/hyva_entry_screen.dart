import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'main.dart';

class HyvaEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? existingEntry;
  const HyvaEntryScreen({super.key, this.existingEntry});

  @override
  State<HyvaEntryScreen> createState() => _HyvaEntryScreenState();
}

class _HyvaEntryScreenState extends State<HyvaEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Controllers
  final _loadingRateCtrl = TextEditingController();
  final _khadanCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _royaltyAmountCtrl = TextEditingController(text: '0');
  final _onlineReceiverCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  final _dalalCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // Royalty Sub-form Controllers
  bool _royaltyRequired = false;
  int _nextRoyaltyKramank = 1;
  TimeOfDay _royaltyTime = TimeOfDay.now();
  final _ghanMeterCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _royaltyCutterCtrl = TextEditingController();
  final _royaltyReceiverCtrl = TextEditingController();
  String? _royaltyPhotoPath;

  // Selections & Saved Lists
  String _paymentMode = 'Cash'; // Cash | Online
  String _paymentStatus = 'Paid'; // Paid | Partial | Balance | Free
  String? _hyvaPhotoPath;
  double _currentDailyRate = 0;

  List<String> _savedKhadans = [];
  List> _savedVehicles = [];
  List> _vehicleDrivers = [];
  List<String> _savedDalals = [];
  List<String> _savedDestinations = [];
  List<String> _savedCutters = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final db = await AppDatabase.instance.database;

    // Load Master Lists
    _savedKhadans = await _getMasterList(db, 'khadan');
    _savedDalals = await _getMasterList(db, 'dalal');
    _savedDestinations = await _getMasterList(db, 'destination');
    _savedCutters = await _getMasterList(db, 'cutter');

    _savedVehicles = await db.query('vehicles', orderBy: 'vehicle_no ASC');

    // Load Daily Loading Rate for selected date
    await _loadDailyRateForDate(_selectedDate);

    // Load Next Royalty Kramank
    final maxRes = await db.rawQuery(
      'SELECT COALESCE(MAX(royalty_kramank), 0) + 1 as next_no FROM royalty_entries',
    );
    _nextRoyaltyKramank = (maxRes.first['next_no'] as int?) ?? 1;

    if (mounted) setState(() {});
  }

  Future<List<String>> _getMasterList(Database db, String type) async {
    final rows = await db.query(
      'master_lists',
      where: 'list_type = ?',
      whereArgs: [type],
      orderBy: 'item_value ASC',
    );
    return rows.map((e) => e['item_value'].toString()).toList();
  }

  Future<void> _saveMasterItem(Database db, String type, String value) async {
    final v = value.trim();
    if (v.isEmpty) return;
    await db.insert(
      'master_lists',
      {'list_type': type, 'item_value': v},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _loadDailyRateForDate(DateTime date) async {
    final db = await AppDatabase.instance.database;
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final res = await db.query(
      'daily_rates',
      where: 'date_key = ?',
      whereArgs: [dateKey],
    );
    if (res.isNotEmpty) {
      _currentDailyRate = (res.first['loading_rate'] as num).toDouble();
      _loadingRateCtrl.text = _currentDailyRate.toStringAsFixed(0);
    } else {
      _currentDailyRate = 0;
      _loadingRateCtrl.clear();
    }
  }

  Future<void> _onVehicleSelected(String vehicleNo) async {
    final db = await AppDatabase.instance.database;
    final vMatch = _savedVehicles.where(
      (v) => v['vehicle_no'].toString().toLowerCase() == vehicleNo.toLowerCase(),
    );
    if (vMatch.isNotEmpty) {
      _ownerCtrl.text = vMatch.first['owner_name'].toString();
    }
    _vehicleDrivers = await db.query(
      'drivers',
      where: 'LOWER(vehicle_no) = ?',
      whereArgs: [vehicleNo.toLowerCase()],
    );
    setState(() {});
  }

  void _recalculateBalance() {
    final amt = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (_paymentStatus == 'Paid' || _paymentStatus == 'Free') {
      _balanceCtrl.text = '0';
    } else if (_paymentStatus == 'Balance') {
      _balanceCtrl.text = amt.toStringAsFixed(0);
    } else if (_paymentStatus == 'Partial') {
      // If user edits received/balance, keep valid
      final currentBal = double.tryParse(_balanceCtrl.text.trim()) ?? 0;
      if (currentBal > amt) {
        _balanceCtrl.text = amt.toStringAsFixed(0);
      }
    }
    setState(() {});
  }

  Future<String?> _pickAndSaveImage(ImageSource source, String prefix) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75);
    if (picked == null) return null;

    final docDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(docDir.path, 'OfflinePhotos'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = await File(picked.path).copy(p.join(mediaDir.path, fileName));
    return savedFile.path;
  }

  /// Loading Rate Change Rule: Only This Entry vs Always
  Future<bool> _confirmLoadingRateChangeIfNeeded(double enteredRate) async {
    final db = await AppDatabase.instance.database;
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // First entry of the day: save as today's daily rate automatically
    if (_currentDailyRate == 0 && enteredRate > 0) {
      await db.insert(
        'daily_rates',
        {'date_key': dateKey, 'loading_rate': enteredRate},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _currentDailyRate = enteredRate;
      return true;
    }

    if (enteredRate != _currentDailyRate) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.sandBeige,
          title: Text(
            lang.tr('Loading Rate बदला गया', 'Loading Rate Changed'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            lang.tr(
              'पुराना Daily Rate: ₹${_currentDailyRate.toStringAsFixed(0)}\nनया Rate: ₹${enteredRate.toStringAsFixed(0)}\n\nआप इसे कैसे लागू करना चाहते हैं?',
              'Old Daily Rate: ₹${_currentDailyRate.toStringAsFixed(0)}\nNew Rate: ₹${enteredRate.toStringAsFixed(0)}\n\nHow do you want to apply this?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'only_this'),
              child: Text(lang.tr('सिर्फ इस गाड़ी के लिए', 'Only This Entry')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.earthBrown,
                foregroundColor: AppColors.white,
              ),
              onPressed: () => Navigator.pop(ctx, 'always'),
              child: Text(lang.tr('हमेशा के लिए (Always)', 'Always (Future Entries)')),
            ),
          ],
        ),
      );

      if (choice == null) return false;
      if (choice == 'always') {
        await db.insert(
          'daily_rates',
          {'date_key': dateKey, 'loading_rate': enteredRate},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        _currentDailyRate = enteredRate;
      }
    }
    return true;
  }

  /// Step 21-23: Preview -> Edit -> Save
  Future<void> _openPreviewAndSave() async {
    if (!_formKey.currentState!.validate()) return;

    final enteredRate = double.tryParse(_loadingRateCtrl.text.trim()) ?? 0;
    final ok = await _confirmLoadingRateChangeIfNeeded(enteredRate);
    if (!ok || !mounted) return;

    final dateStr = DateFormat('dd MMM yyyy').format(_selectedDate);
    final timeStr = _selectedTime.format(context);
    final amt = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final royaltyAmt = double.tryParse(_royaltyAmountCtrl.text.trim()) ?? 0;
    final balAmt = _paymentStatus == 'Free' || _paymentStatus == 'Paid'
        ? 0.0
        : (double.tryParse(_balanceCtrl.text.trim()) ?? 0);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sandBeige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang.tr('एंट्री प्रीव्यू (जांच लें)', 'Entry Preview'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              _previewRow(lang.tr('दिनांक / समय', 'Date / Time'), '$dateStr • $timeStr'),
              _previewRow(lang.tr('खदान का नाम', 'Khadan Name'), _khadanCtrl.text),
              _previewRow(lang.tr('गाड़ी नंबर', 'Vehicle No'), _vehicleCtrl.text.toUpperCase()),
              _previewRow(lang.tr('मालिक का नाम', 'Owner Name'), _ownerCtrl.text),
              _previewRow(lang.tr('ड्राइवर', 'Driver'), '${_driverCtrl.text} (${_mobileCtrl.text})'),
              _previewRow(lang.tr('Loading Rate', 'Loading Rate'), '₹${enteredRate.toStringAsFixed(0)}'),
              _previewRow(lang.tr('अंतिम तय Amount', 'Final Amount'), '₹${amt.toStringAsFixed(0)}'),
              _previewRow(lang.tr('Royalty Amount', 'Royalty Amount'), '₹${royaltyAmt.toStringAsFixed(0)}'),
              _previewRow(lang.tr('भुगतान माध्यम', 'Payment Mode'), _paymentMode),
              _previewRow(lang.tr('स्थिति (Status)', 'Status'), '$_paymentStatus (Balance: ₹${balAmt.toStringAsFixed(0)})'),
              if (_dalalCtrl.text.isNotEmpty)
                _previewRow(lang.tr('दलाल', 'Dalal'), _dalalCtrl.text),
              if (_royaltyRequired)
                _previewRow(
                  lang.tr('रॉयल्टी विवरण', 'Royalty Details'),
                  '#$_nextRoyaltyKramank • ${_ghanMeterCtrl.text} m³ → ${_destinationCtrl.text}',
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(lang.tr('Edit करें', 'Edit')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.earthBrown,
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(lang.tr('पुष्टि करें और Save', 'Confirm & Save')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _saveToDatabase(
        dateStr: dateStr,
        timeStr: timeStr,
        loadingRate: enteredRate,
        amount: amt,
        royaltyAmount: royaltyAmt,
        balanceAmount: balAmt,
      );
    }
  }

  Widget _previewRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(val)),
        ],
      ),
    );
  }

  Future<void> _saveToDatabase({
    required String dateStr,
    required String timeStr,
    required double loadingRate,
    required double amount,
    required double royaltyAmount,
    required double balanceAmount,
  }) async {
    final db = await AppDatabase.instance.database;
    final vehicleNo = _vehicleCtrl.text.trim().toUpperCase();
    final ownerName = _ownerCtrl.text.trim();
    final driverName = _driverCtrl.text.trim();
    final mobileNo = _mobileCtrl.text.trim();
    final khadanName = _khadanCtrl.text.trim();

    // Save/Update Master Data for future auto-fill
    await _saveMasterItem(db, 'khadan', khadanName);
    await _saveMasterItem(db, 'dalal', _dalalCtrl.text);

    await db.insert(
      'vehicles',
      {'vehicle_no': vehicleNo, 'owner_name': ownerName},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final existingDriver = await db.query(
      'drivers',
      where: 'LOWER(vehicle_no) = ? AND LOWER(driver_name) = ?',
      whereArgs: [vehicleNo.toLowerCase(), driverName.toLowerCase()],
    );
    if (existingDriver.isEmpty) {
      await db.insert('drivers', {
        'vehicle_no': vehicleNo,
        'driver_name': driverName,
        'mobile_no': mobileNo,
      });
    } else {
      await db.update(
        'drivers',
        {'mobile_no': mobileNo},
        where: 'id = ?',
        whereArgs: [existingDriver.first['id']],
      );
    }

    // Insert Hyva Entry
    final hyvaId = await db.insert('hyva_entries', {
      'entry_date': dateStr,
      'entry_time': timeStr,
      'loading_rate': loadingRate,
      'khadan_name': khadanName,
      'vehicle_no': vehicleNo,
      'owner_name': ownerName,
      'driver_name': driverName,
      'mobile_no': mobileNo,
      'amount': amount,
      'royalty_amount': royaltyAmount,
      'payment_mode': _paymentMode,
      'online_receiver': _paymentMode == 'Online' ? _onlineReceiverCtrl.text.trim() : null,
      'payment_status': _paymentStatus,
      'balance_amount': balanceAmount,
      'dalal_name': _dalalCtrl.text.trim(),
      'note': _noteCtrl.text.trim(),
      'photo_path': _hyvaPhotoPath,
    });

    // If Royalty Checked, create Linked Royalty Entry
    if (_royaltyRequired && mounted) {
      await _saveMasterItem(db, 'destination', _destinationCtrl.text);
      await _saveMasterItem(db, 'cutter', _royaltyCutterCtrl.text);

      final royaltyId = await db.insert('royalty_entries', {
        'royalty_kramank': _nextRoyaltyKramank,
        'entry_date': dateStr,
        'entry_time': _royaltyTime.format(context),
        'khadan_name': khadanName,
        'ghan_meter': double.tryParse(_ghanMeterCtrl.text.trim()) ?? 0,
        'destination': _destinationCtrl.text.trim(),
        'royalty_cutter': _royaltyCutterCtrl.text.trim(),
        'royalty_receiver': _royaltyReceiverCtrl.text.trim(),
        'vehicle_no': vehicleNo,
        'owner_name': ownerName,
        'driver_name': driverName,
        'mobile_no': mobileNo,
        'amount': royaltyAmount,
        'photo_path': _royaltyPhotoPath,
        'hyva_entry_id': hyvaId,
      });

      await db.update(
        'hyva_entries',
        {'royalty_id': royaltyId},
        where: 'id = ?',
        whereArgs: [hyvaId],
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang.tr('हाइवा एंट्री सफलतापूर्वक सेव हो गई!', 'Hyva Entry Saved Successfully!'),
        ),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.desertSand,
        foregroundColor: AppColors.charcoal,
        title: Text(lang.tr('हाइवा एंट्री फॉर्म', 'Hyva Entry Form')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Date & Time
            _sectionCard([
              Text(
                lang.tr('1. तारीख और समय', '1. Date & Time'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          _selectedDate = picked;
                          await _loadDailyRateForDate(picked);
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(_selectedTime.format(context)),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (picked != null) {
                          setState(() => _selectedTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ]),

            // 2. Khadan Name & Loading Rate
            _sectionCard([
              _autocompleteInput(
                controller: _khadanCtrl,
                label: lang.tr('खदान का नाम *', 'Khadan Name *'),
                options: _savedKhadans,
                required: true,
              ),
              const SizedBox(height: 12),
              _textInput(
                controller: _loadingRateCtrl,
                label: lang.tr('Loading Rate (₹) *', 'Loading Rate (₹) *'),
                keyboardType: TextInputType.number,
                required: true,
              ),
            ]),

            // 3, 4, 5, 6. Vehicle, Owner, Driver, Mobile
            _sectionCard([
              _autocompleteInput(
                controller: _vehicleCtrl,
                label: lang.tr('गाड़ी नंबर (Vehicle No) *', 'Vehicle Number *'),
                options: _savedVehicles.map((e) => e['vehicle_no'].toString()).toList(),
                required: true,
                onSelected: _onVehicleSelected,
                onChanged: (val) => _onVehicleSelected(val),
              ),
              const SizedBox(height: 12),
              _textInput(
                controller: _ownerCtrl,
                label: lang.tr('गाड़ी मालिक का नाम *', 'Owner Name *'),
                required: true,
              ),
              const SizedBox(height: 12),
              _autocompleteInput(
                controller: _driverCtrl,
                label: lang.tr('ड्राइवर का नाम *', 'Driver Name *'),
                options: _vehicleDrivers.map((e) => e['driver_name'].toString()).toList(),
                required: true,
                onSelected: (dName) {
                  final match = _vehicleDrivers.where(
                    (d) => d['driver_name'].toString().toLowerCase() == dName.toLowerCase(),
                  );
                  if (match.isNotEmpty) {
                    _mobileCtrl.text = match.first['mobile_no'].toString();
                  }
                },
              ),
              const SizedBox(height: 12),
              _textInput(
                controller: _mobileCtrl,
                label: lang.tr('ड्राइवर मोबाइल नंबर *', 'Driver Mobile Number *'),
                keyboardType: TextInputType.phone,
                required: true,
              ),
            ]),

            // 7, 8, 9. Final Amount, Royalty Checkbox & Royalty Amount
            _sectionCard([
              _textInput(
                controller: _amountCtrl,
                label: lang.tr('अंतिम तय Loading Amount (₹) *', 'Final Loading Amount (₹) *'),
                keyboardType: TextInputType.number,
                required: true,
                onChanged: (_) => _recalculateBalance(),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.earthBrown,
                title: Text(
                  lang.tr('रॉयल्टी चाहिए? (Royalty Required?)', 'Royalty Required?'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                value: _royaltyRequired,
                onChanged: (val) {
                  setState(() {
                    _royaltyRequired = val ?? false;
                    _royaltyTime = _selectedTime;
                  });
                },
              ),
              if (_royaltyRequired) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.sandBeige,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.naturalSand),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${lang.tr('रॉयल्टी क्रमांक', 'Royalty Serial No')}: #$_nextRoyaltyKramank',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.earthBrown,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _textInput(
                        controller: _ghanMeterCtrl,
                        label: lang.tr('खनिज की मात्रा (घन मीटर / m³) *', 'Quantity (Cubic Meter / m³) *'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        required: _royaltyRequired,
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.schedule, size: 18),
                        label: Text(
                          '${lang.tr('रॉयल्टी काटने का समय', 'Royalty Time')}: ${_royaltyTime.format(context)}',
                        ),
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: _royaltyTime,
                          );
                          if (t != null) setState(() => _royaltyTime = t);
                        },
                      ),
                      const SizedBox(height: 10),
                      _autocompleteInput(
                        controller: _destinationCtrl,
                        label: lang.tr('कहाँ जाएगी (Destination) *', 'Destination *'),
                        options: _savedDestinations,
                        required: _royaltyRequired,
                      ),
                      const SizedBox(height: 10),
                      _autocompleteInput(
                        controller: _royaltyCutterCtrl,
                        label: lang.tr('रॉयल्टी काटने वाले का नाम *', 'Royalty Issuer Name *'),
                        options: _savedCutters,
                        required: _royaltyRequired,
                      ),
                      const SizedBox(height: 10),
                      _textInput(
                        controller: _royaltyReceiverCtrl,
                        label: lang.tr('रॉयल्टी प्राप्तकर्ता का नाम (Optional)', 'Royalty Receiver (Optional)'),
                      ),
                      const SizedBox(height: 8),
                      _photoPickerRow(
                        label: lang.tr('रॉयल्टी फोटो (Optional)', 'Royalty Photo (Optional)'),
                        photoPath: _royaltyPhotoPath,
                        onPicked: (path) => setState(() => _royaltyPhotoPath = path),
                        prefix: 'royalty',
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _textInput(
                controller: _royaltyAmountCtrl,
                label: lang.tr('Royalty Amount (₹)', 'Royalty Amount (₹)'),
                keyboardType: TextInputType.number,
              ),
            ]),

            // 10, 11, 12. Payment Mode & Status
            _sectionCard([
              Text(
                lang.tr('भुगतान का माध्यम (Payment Mode)', 'Payment Mode'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Cash', label: Text('Cash')),
                  ButtonSegment(value: 'Online', label: Text('Online')),
                ],
                selected: {_paymentMode},
                onSelectionChanged: (s) => setState(() => _paymentMode = s.first),
              ),
              if (_paymentMode == 'Online') ...[
                const SizedBox(height: 12),
                _textInput(
                  controller: _onlineReceiverCtrl,
                  label: lang.tr('किसको Online किया? *', 'Online Payment Receiver *'),
                  required: _paymentMode == 'Online',
                ),
              ],
              const SizedBox(height: 14),
              Text(
                lang.tr('भुगतान की स्थिति (Payment Status)', 'Payment Status'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Paid', 'Partial', 'Balance', 'Free'].map((status) {
                  return ChoiceChip(
                    label: Text(status),
                    selected: _paymentStatus == status,
                    selectedColor: AppColors.naturalSand,
                    onSelected: (_) {
                      _paymentStatus = status;
                      if (status == 'Partial') {
                        _balanceCtrl.clear();
                      } else {
                        _recalculateBalance();
                      }
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
              if (_paymentStatus == 'Partial' || _paymentStatus == 'Balance') ...[
                const SizedBox(height: 12),
                if (_paymentStatus == 'Partial')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _textInput(
                      controller: TextEditingController(),
                      label: lang.tr('प्राप्त रकम लिखें (₹)', 'Received Amount (₹)'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        final total = double.tryParse(_amountCtrl.text.trim()) ?? 0;
                        final rec = double.tryParse(val.trim()) ?? 0;
                        final rem = (total - rec).clamp(0, total);
                        _balanceCtrl.text = rem.toStringAsFixed(0);
                      },
                    ),
                  ),
                _textInput(
                  controller: _balanceCtrl,
                  label: lang.tr('बाकी Balance Amount (₹)', 'Balance Amount (₹)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ]),

            // 13, 14, 15. Dalal, Note, Hyva Photo
            _sectionCard([
              _autocompleteInput(
                controller: _dalalCtrl,
                label: lang.tr('गाड़ी भेजने वाले दलाल का नाम (Optional)', 'Dalal Name (Optional)'),
                options: _savedDalals,
              ),
              const SizedBox(height: 12),
              _textInput(
                controller: _noteCtrl,
                label: _paymentStatus == 'Free'
                    ? lang.tr('Note (FREE का कारण लिखें) *', 'Note (Reason for FREE) *')
                    : lang.tr('Note / अतिरिक्त जानकारी', 'Note / Additional Info'),
                required: _paymentStatus == 'Free',
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              _photoPickerRow(
                label: lang.tr('हाइवा फोटो (Optional)', 'Hyva Photo (Optional)'),
                photoPath: _hyvaPhotoPath,
                onPicked: (path) => setState(() => _hyvaPhotoPath = path),
                prefix: 'hyva',
              ),
            ]),

            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.earthBrown,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _openPreviewAndSave,
                child: Text(
                  lang.tr('Preview देखें और Save करें', 'Preview & Save'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.desertSand,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.naturalSand.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _textInput({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
              ? lang.tr('यह जानकारी आवश्यक है', 'This field is required')
              : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _autocompleteInput({
    required TextEditingController controller,
    required String label,
    required List<String> options,
    bool required = false,
    ValueChanged<String>? onSelected,
    ValueChanged<String>? onChanged,
  }) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return options;
        return options.where(
          (o) => o.toLowerCase().contains(textEditingValue.text.toLowerCase()),
        );
      },
      onSelected: (selection) {
        controller.text = selection;
        if (onSelected != null) onSelected(selection);
      },
      fieldViewBuilder: (ctx, textCtrl, focusNode, onFieldSubmitted) {
        textCtrl.addListener(() {
          if (controller.text != textCtrl.text) {
            controller.text = textCtrl.text;
            if (onChanged != null) onChanged(textCtrl.text);
          }
        });
        return TextFormField(
          controller: textCtrl,
          focusNode: focusNode,
          validator: required
              ? (v) => (v == null || v.trim().isEmpty)
                  ? lang.tr('यह जानकारी आवश्यक है', 'This field is required')
                  : null
              : null,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: AppColors.white,
            suffixIcon: const Icon(Icons.arrow_drop_down),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  Widget _photoPickerRow({
    required String label,
    required String? photoPath,
    required ValueChanged<String?> onPicked,
    required String prefix,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        IconButton(
          tooltip: 'Camera',
          icon: const Icon(Icons.camera_alt, color: AppColors.earthBrown),
          onPressed: () async {
            final path = await _pickAndSaveImage(ImageSource.camera, prefix);
            if (path != null) onPicked(path);
          },
        ),
        IconButton(
          tooltip: 'Gallery',
          icon: const Icon(Icons.photo_library, color: AppColors.earthBrown),
          onPressed: () async {
            final path = await _pickAndSaveImage(ImageSource.gallery, prefix);
            if (path != null) onPicked(path);
          },
        ),
        if (photoPath != null)
          IconButton(
            tooltip: 'Delete Photo',
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => onPicked(null),
          ),
      ],
    );
  }
}
