import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'main.dart';

class RoyaltyEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? existingRoyalty;
  const RoyaltyEntryScreen({super.key, this.existingRoyalty});

  @override
  State<RoyaltyEntryScreen> createState() => _RoyaltyEntryScreenState();
}

class _RoyaltyEntryScreenState extends State<RoyaltyEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  int _kramank = 1;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final _khadanCtrl = TextEditingController();
  final _ghanMeterCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _receiverCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _cutterCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _photoPath;

  List<String> _savedKhadans = [];
  List> _savedVehicles = [];
  List> _vehicleDrivers = [];
  List<String> _savedDestinations = [];
  List<String> _savedCutters = [];
  List<String> _savedReceivers = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final db = await AppDatabase.instance.database;
    _savedKhadans = await _getMaster(db, 'khadan');
    _savedDestinations = await _getMaster(db, 'destination');
    _savedCutters = await _getMaster(db, 'cutter');
    _savedReceivers = await _getMaster(db, 'royalty_receiver');
    _savedVehicles = await db.query('vehicles', orderBy: 'vehicle_no ASC');

    if (widget.existingRoyalty != null) {
      final e = widget.existingRoyalty!;
      _kramank = e['royalty_kramank'] as int;
      _khadanCtrl.text = e['khadan_name']?.toString() ?? '';
      _ghanMeterCtrl.text = e['ghan_meter']?.toString() ?? '';
      _vehicleCtrl.text = e['vehicle_no']?.toString() ?? '';
      _ownerCtrl.text = e['owner_name']?.toString() ?? '';
      _driverCtrl.text = e['driver_name']?.toString() ?? '';
      _mobileCtrl.text = e['mobile_no']?.toString() ?? '';
      _receiverCtrl.text = e['royalty_receiver']?.toString() ?? '';
      _destinationCtrl.text = e['destination']?.toString() ?? '';
      _cutterCtrl.text = e['royalty_cutter']?.toString() ?? '';
      _amountCtrl.text = e['amount']?.toString() ?? '';
      _photoPath = e['photo_path']?.toString();
    } else {
      final maxRes = await db.rawQuery(
        'SELECT COALESCE(MAX(royalty_kramank), 0) + 1 as next_no FROM royalty_entries',
      );
      _kramank = (maxRes.first['next_no'] as int?) ?? 1;
    }

    if (mounted) setState(() {});
  }

  Future<List<String>> _getMaster(Database db, String type) async {
    final rows = await db.query(
      'master_lists',
      where: 'list_type = ?',
      whereArgs: [type],
      orderBy: 'item_value ASC',
    );
    return rows.map((e) => e['item_value'].toString()).toList();
  }

  Future<void> _saveMaster(Database db, String type, String value) async {
    if (value.trim().isEmpty) return;
    await db.insert(
      'master_lists',
      {'list_type': type, 'item_value': value.trim()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _onVehicleSelected(String vNo) async {
    final db = await AppDatabase.instance.database;
    final match = _savedVehicles.where(
      (v) => v['vehicle_no'].toString().toLowerCase() == vNo.toLowerCase(),
    );
    if (match.isNotEmpty) {
      _ownerCtrl.text = match.first['owner_name'].toString();
    }
    _vehicleDrivers = await db.query(
      'drivers',
      where: 'LOWER(vehicle_no) = ?',
      whereArgs: [vNo.toLowerCase()],
    );
    setState(() {});
  }

  Future<void> _pickPhoto(ImageSource src) async {
    final picked = await ImagePicker().pickImage(source: src, imageQuality: 75);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'OfflinePhotos'));
    if (!await folder.exists()) await folder.create(recursive: true);
    final saved = await File(picked.path).copy(
      p.join(folder.path, 'royalty_${DateTime.now().millisecondsSinceEpoch}.jpg'),
    );
    setState(() => _photoPath = saved.path);
  }

  Future<void> _previewAndSave() async {
    if (!_formKey.currentState!.validate()) return;

    final dateStr = DateFormat('dd MMM yyyy').format(_selectedDate);
    final timeStr = _selectedTime.format(context);

    final ok = await showModalBottomSheet<bool>(
      context: context,
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
                lang.tr('रॉयल्टी प्रीव्यू (जांच लें)', 'Royalty Preview'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Text('${lang.tr('क्रमांक', 'Serial No')}: #$_kramank'),
              Text('${lang.tr('तारीख / समय', 'Date / Time')}: $dateStr • $timeStr'),
              Text('${lang.tr('खदान', 'Khadan')}: ${_khadanCtrl.text}'),
              Text('${lang.tr('घन मीटर', 'Ghan Meter')}: ${_ghanMeterCtrl.text} m³'),
              Text('${lang.tr('गाड़ी नंबर', 'Vehicle')}: ${_vehicleCtrl.text.toUpperCase()}'),
              Text('${lang.tr('मालिक', 'Owner')}: ${_ownerCtrl.text}'),
              Text('${lang.tr('ड्राइवर', 'Driver')}: ${_driverCtrl.text} (${_mobileCtrl.text})'),
              Text('${lang.tr('कहाँ जाएगी', 'Destination')}: ${_destinationCtrl.text}'),
              Text('${lang.tr('देने वाला', 'Issuer')}: ${_cutterCtrl.text}'),
              Text('${lang.tr('रकम', 'Amount')}: ₹${_amountCtrl.text}'),
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
                      child: Text(lang.tr('Save करें', 'Save')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (ok != true) return;

    final db = await AppDatabase.instance.database;
    final vNo = _vehicleCtrl.text.trim().toUpperCase();
    final oName = _ownerCtrl.text.trim();
    final dName = _driverCtrl.text.trim();
    final mNo = _mobileCtrl.text.trim();

    await _saveMaster(db, 'khadan', _khadanCtrl.text);
    await _saveMaster(db, 'destination', _destinationCtrl.text);
    await _saveMaster(db, 'cutter', _cutterCtrl.text);
    await _saveMaster(db, 'royalty_receiver', _receiverCtrl.text);

    await db.insert(
      'vehicles',
      {'vehicle_no': vNo, 'owner_name': oName},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final data = {
      'royalty_kramank': _kramank,
      'entry_date': dateStr,
      'entry_time': timeStr,
      'khadan_name': _khadanCtrl.text.trim(),
      'ghan_meter': double.tryParse(_ghanMeterCtrl.text.trim()) ?? 0,
      'destination': _destinationCtrl.text.trim(),
      'royalty_cutter': _cutterCtrl.text.trim(),
      'royalty_receiver': _receiverCtrl.text.trim(),
      'vehicle_no': vNo,
      'owner_name': oName,
      'driver_name': dName,
      'mobile_no': mNo,
      'amount': double.tryParse(_amountCtrl.text.trim()) ?? 0,
      'photo_path': _photoPath,
    };

    if (widget.existingRoyalty != null) {
      await db.update(
        'royalty_entries',
        data,
        where: 'id = ?',
        whereArgs: [widget.existingRoyalty!['id']],
      );
    } else {
      await db.insert('royalty_entries', data);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(lang.tr('रॉयल्टी सेव हो गई!', 'Royalty Saved!'))),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.desertSand,
        foregroundColor: AppColors.charcoal,
        title: Text(lang.tr('रॉयल्टी एंट्री फॉर्म', 'Royalty Entry Form')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.desertSand,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lang.tr('रॉयल्टी क्रमांक', 'Royalty Serial No')}: #$_kramank',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.earthBrown,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (d != null) setState(() => _selectedDate = d);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time, size: 18),
                          label: Text(_selectedTime.format(context)),
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (t != null) setState(() => _selectedTime = t);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _autoField(_khadanCtrl, lang.tr('खदान का नाम *', 'Khadan Name *'), _savedKhadans, true),
                  const SizedBox(height: 12),
                  _field(
                    _ghanMeterCtrl,
                    lang.tr('खनिज की मात्रा (घन मीटर / m³) *', 'Quantity (m³) *'),
                    keyboard: const TextInputType.numberWithOptions(decimal: true),
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _autoField(
                    _vehicleCtrl,
                    lang.tr('गाड़ी नंबर *', 'Vehicle Number *'),
                    _savedVehicles.map((e) => e['vehicle_no'].toString()).toList(),
                    true,
                    onSelected: _onVehicleSelected,
                  ),
                  const SizedBox(height: 12),
                  _field(_ownerCtrl, lang.tr('गाड़ी मालिक का नाम', 'Owner Name')),
                  const SizedBox(height: 12),
                  _autoField(
                    _driverCtrl,
                    lang.tr('ड्राइवर का नाम *', 'Driver Name *'),
                    _vehicleDrivers.map((e) => e['driver_name'].toString()).toList(),
                    true,
                    onSelected: (name) {
                      final m = _vehicleDrivers.where(
                        (d) => d['driver_name'].toString().toLowerCase() == name.toLowerCase(),
                      );
                      if (m.isNotEmpty) _mobileCtrl.text = m.first['mobile_no'].toString();
                    },
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _mobileCtrl,
                    lang.tr('ड्राइवर मोबाइल नंबर *', 'Driver Mobile *'),
                    keyboard: TextInputType.phone,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _autoField(
                    _receiverCtrl,
                    lang.tr('रॉयल्टी प्राप्तकर्ता का नाम (Optional)', 'Royalty Receiver (Optional)'),
                    _savedReceivers,
                    false,
                  ),
                  const SizedBox(height: 12),
                  _autoField(
                    _destinationCtrl,
                    lang.tr('कहाँ जाएगी (Destination) *', 'Destination *'),
                    _savedDestinations,
                    true,
                  ),
                  const SizedBox(height: 12),
                  _autoField(
                    _cutterCtrl,
                    lang.tr('रॉयल्टी देने/काटने वाले का नाम *', 'Royalty Issuer Name *'),
                    _savedCutters,
                    true,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _amountCtrl,
                    lang.tr('रॉयल्टी रकम (Amount ₹) *', 'Royalty Amount (₹) *'),
                    keyboard: TextInputType.number,
                    required: true,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: Text(lang.tr('रॉयल्टी फोटो (Optional)', 'Royalty Photo'))),
                      IconButton(
                        icon: const Icon(Icons.camera_alt, color: AppColors.earthBrown),
                        onPressed: () => _pickPhoto(ImageSource.camera),
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo_library, color: AppColors.earthBrown),
                        onPressed: () => _pickPhoto(ImageSource.gallery),
                      ),
                      if (_photoPath != null)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _photoPath = null),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.earthBrown,
                  foregroundColor: AppColors.white,
                ),
                onPressed: _previewAndSave,
                child: Text(
                  lang.tr('Preview देखें और Save करें', 'Preview & Save'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    TextInputType keyboard = TextInputType.text,
    bool required = false,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      validator: required
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

  Widget _autoField(
    TextEditingController ctrl,
    String label,
    List<String> options,
    bool required, {
    ValueChanged<String>? onSelected,
  }) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: ctrl.text),
      optionsBuilder: (val) => val.text.isEmpty
          ? options
          : options.where((e) => e.toLowerCase().contains(val.text.toLowerCase())),
      onSelected: (s) {
        ctrl.text = s;
        if (onSelected != null) onSelected(s);
      },
      fieldViewBuilder: (ctx, tc, fn, _) {
        tc.addListener(() {
          if (ctrl.text != tc.text) ctrl.text = tc.text;
        });
        return TextFormField(
          controller: tc,
          focusNode: fn,
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? lang.tr('आवश्यक है', 'Required') : null
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
}
