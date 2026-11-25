import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'pdf.dart';
import 'store.dart';

const kBg = Color(0xFFF3E9D7), kCard = Color(0xFFE3D1B3), kAcc = Color(0xFFC5A77D), kBrown = Color(0xFF8B6B48), kTxt = Color(0xFF45413A);

ThemeData appTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'Noto',
      scaffoldBackgroundColor: kBg,
      colorScheme: ColorScheme.fromSeed(seedColor: kBrown).copyWith(primary: kBrown, surface: kBg),
      textTheme: ThemeData.light().textTheme.apply(bodyColor: kTxt, displayColor: kTxt, fontFamily: 'Noto'),
    );

BoxDecoration neo({double r = 20, Color c = Colors.white}) => BoxDecoration(
      color: c,
      borderRadius: BorderRadius.circular(r),
      boxShadow: const [
        BoxShadow(color: Color(0x33A38B66), blurRadius: 12, offset: Offset(4, 4)),
        BoxShadow(color: Color(0xCCFFFFFF), blurRadius: 12, offset: Offset(-4, -4)),
      ],
    );

InputDecoration dec({Widget? suffix, String? hint}) {
  OutlineInputBorder b(Color c, double w) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0x8845413A), fontSize: 13),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: b(Colors.transparent, 0),
    enabledBorder: b(const Color(0x28000000), 1),
    focusedBorder: b(kBrown, 1.5),
  );
}

Widget aboveBox(String heading, Widget box, {bool req = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 5),
            child: Text(
              req ? '$heading *' : heading,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kBrown),
            ),
          ),
          box,
        ],
      ),
    );

Widget bigBtn(String t, IconData i, VoidCallback f, {bool dark = true, String? subtitle}) => InkWell(
      onTap: f,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(color: dark ? kBrown : kCard, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 28, color: dark ? Colors.white : kBrown),
          const SizedBox(height: 8),
          Text(
            t,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: dark ? Colors.white : kTxt, fontWeight: dark ? FontWeight.w500 : FontWeight.w700),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: dark ? const Color(0xFFEFE4D0) : kBrown),
            ),
          ],
        ]),
      ),
    );

class Pg extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? fab;
  const Pg(this.title, this.body, {super.key, this.actions, this.fab});
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          backgroundColor: kBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: actions,
        ),
        floatingActionButton: fab,
        body: Stack(children: [
          Positioned.fill(child: Image.asset('assets/images/app_bg.jpg', fit: BoxFit.cover, cacheWidth: 900)),
          const Positioned.fill(child: ColoredBox(color: Color(0xB3F3E9D7))),
          SafeArea(child: body),
        ]),
      );
}

class FD {
  final String k, label, t;
  final bool req;
  final String? hint;
  final List<String> Function(Map<String, dynamic> v)? opts;
  final bool Function(Map<String, dynamic> v)? show;
  FD(this.k, this.label, this.t, {this.req = false, this.hint, this.opts, this.show});
}

typedef Hook = void Function(String k, Map<String, dynamic> v, void Function(String, dynamic) set);

void vehHook(String k, Map<String, dynamic> v, void Function(String, dynamic) set, {bool drivers = true}) {
  if (k == 'vehicle') {
    final upper = '${v['vehicle'] ?? ''}'.toUpperCase();
    if (upper != '${v['vehicle'] ?? ''}') set('vehicle', upper);
    final vh = S.vehicle(upper);
    if (vh != null) {
      if ('${vh['owner'] ?? ''}'.isNotEmpty) set('owner', vh['owner']);
      if ('${vh['tyre'] ?? ''}'.isNotEmpty && (v['tyre'] == null || '${v['tyre']}'.isEmpty)) {
        set('tyre', vh['tyre']);
      }
      final ds = vh['drivers'] as List;
      if (drivers && ds.isNotEmpty) {
        set('driver', ds.first['n']);
        set('mobile', ds.first['m']);
      }
    }
  }
  if (k == 'driver') {
    for (final d in S.driversOf(v['vehicle'] ?? '')) {
      if (d['n'] == v['driver'] && '${d['m']}'.isNotEmpty) set('mobile', d['m']);
    }
  }
}

class FormPage extends StatefulWidget {
  final String title;
  final List<FD> fields;
  final Map<String, dynamic> init;
  final Hook? hook;
  final Future<String?> Function(BuildContext c, Map<String, dynamic> v) onSave;
  const FormPage({super.key, required this.title, required this.fields, required this.init, required this.onSave, this.hook});
  @override
  State<FormPage> createState() => _FS();
}

class _FS extends State<FormPage> {
  late Map<String, dynamic> v;
  final c = <String, TextEditingController>{};
  final fn = <String, FocusNode>{};

  @override
  void initState() {
    super.initState();
    v = Map<String, dynamic>.from(widget.init);
  }

  @override
  void dispose() {
    for (final x in c.values) {
      x.dispose();
    }
    for (final x in fn.values) {
      x.dispose();
    }
    super.dispose();
  }

  TextEditingController ctl(String k) => c.putIfAbsent(k, () => TextEditingController(text: '${v[k] ?? ''}'));
  FocusNode fnode(String k) => fn.putIfAbsent(k, () => FocusNode());

  void set(String k, dynamic val) {
    v[k] = val;
    final t = c[k];
    if (t != null && t.text != '${val ?? ''}') {
      t.value = TextEditingValue(
        text: '${val ?? ''}',
        selection: TextSelection.collapsed(offset: '${val ?? ''}'.length),
      );
    }
  }

  void change(String k, dynamic val) => setState(() {
        v[k] = val;
        widget.hook?.call(k, v, set);
      });

  bool vis(FD f) => f.show == null || f.show!(v);

  String valText(FD f) {
    final x = v[f.k];
    if (f.t == 'date') return dShow(x);
    if (f.t == 'time') return tShow(x);
    if (f.t == 'check') return x == true ? S.tr('हाँ', 'Yes') : S.tr('नहीं', 'No');
    if (f.t == 'multi') return ((x ?? []) as List).join(', ');
    if (f.t == 'people') return ((v['people'] ?? []) as List).take((v['cnt'] ?? 1) as int).map((p) => '${p['n']} (${p['c']})').join('; ');
    if (f.t == 'photo') return x == null || '$x'.isEmpty ? S.tr('नहीं', 'No') : S.tr('है', 'Attached');
    return '${x ?? ''}';
  }

  Future<void> submit() async {
    for (final f in widget.fields) {
      if (vis(f) && f.req && '${v[f.k] ?? ''}'.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${f.label} ${S.tr('भरें', 'is required')}')));
        return;
      }
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dc) => AlertDialog(
        title: Text(S.tr('प्रीव्यू', 'Preview')),
        content: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final f in widget.fields)
              if (vis(f) && f.t != 'sec' && f.t != 'info' && valText(f).trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '${f.label}: ', style: const TextStyle(color: kBrown)),
                    TextSpan(text: valText(f), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ])),
                ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dc, false), child: Text(S.tr('संपादित करें', 'Edit'))),
          FilledButton(onPressed: () => Navigator.pop(dc, true), child: Text(S.tr('सेव करें', 'Save'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final err = await widget.onSave(context, v);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      Navigator.pop(context, true);
    }
  }

  Future<void> pickPhoto(String k, ImageSource s) async {
    S.skipNextLock = true;
    try {
      final x = await ImagePicker().pickImage(source: s, imageQuality: 70, maxWidth: 1600);
      if (x == null) return;
      final p = await S.keepPhoto(x.path);
      change(k, p);
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        S.skipNextLock = false;
      });
    }
  }

  String _formatTyped(FD f, String raw) {
    if (f.t == 'cap') return raw.toUpperCase();
    if (f.t == 'capWords' && raw.isNotEmpty) {
      return raw
          .split(' ')
          .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
          .join(' ');
    }
    if (f.t == 'text' && raw.isNotEmpty) {
      return raw[0].toUpperCase() + raw.substring(1);
    }
    return raw;
  }

  Widget field(FD f) {
    switch (f.t) {
      case 'sec':
        return Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Text(f.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: kBrown)),
        );
      case 'info':
        return aboveBox(
          f.label,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: neo(c: kCard, r: 14),
            child: Text('${v[f.k] ?? S.tr('सेव करने पर अपने-आप बनेगा', 'Auto-generated on save')}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          req: f.req,
        );
      case 'text':
      case 'cap':
      case 'capWords':
      case 'num':
      case 'phone':
      case 'note':
        final isNote = f.t == 'note';
        return aboveBox(
          f.label,
          TextField(
            controller: ctl(f.k),
            keyboardType: f.t == 'num'
                ? const TextInputType.numberWithOptions(decimal: true)
                : f.t == 'phone'
                    ? TextInputType.phone
                    : isNote
                        ? TextInputType.multiline
                        : TextInputType.text,
            textCapitalization: f.t == 'cap'
                ? TextCapitalization.characters
                : (f.t == 'capWords' || f.t == 'text')
                    ? TextCapitalization.sentences
                    : TextCapitalization.none,
            textInputAction: isNote ? TextInputAction.newline : TextInputAction.next,
            maxLines: isNote ? 3 : 1,
            decoration: dec(hint: f.hint),
            onChanged: (s) {
              final fmt = _formatTyped(f, s);
              if (fmt != s) {
                set(f.k, fmt);
              } else {
                v[f.k] = fmt;
              }
              widget.hook?.call(f.k, v, set);
            },
          ),
          req: f.req,
        );
      case 'sug':
        return aboveBox(
          f.label,
          RawAutocomplete<String>(
            textEditingController: ctl(f.k),
            focusNode: fnode(f.k),
            optionsBuilder: (tv) {
              final o = f.opts!(v);
              final q = tv.text.trim().toLowerCase();
              return q.isEmpty ? o : o.where((e) => e.toLowerCase().contains(q));
            },
            onSelected: (s) => change(f.k, f.t == 'cap' ? s.toUpperCase() : capWords(s)),
            fieldViewBuilder: (ctx, tc, fnode, _) => TextField(
              controller: tc,
              focusNode: fnode,
              textCapitalization: f.k == 'vehicle' ? TextCapitalization.characters : TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: dec(suffix: const Icon(Icons.arrow_drop_down), hint: f.hint),
              onChanged: (s) {
                final val = f.k == 'vehicle' ? s.toUpperCase() : s;
                if (val != s) set(f.k, val);
                change(f.k, val);
              },
            ),
            optionsViewBuilder: (ctx, onSel, options) => Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 220, maxWidth: MediaQuery.of(ctx).size.width - 32),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: [for (final o in options) ListTile(dense: true, title: Text(o), onTap: () => onSel(o))],
                  ),
                ),
              ),
            ),
          ),
          req: f.req,
        );
      case 'date':
        return aboveBox(
          f.label,
          InkWell(
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: dparse(v[f.k]), firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (d != null) change(f.k, dkey(d));
            },
            child: InputDecorator(decoration: dec(suffix: const Icon(Icons.calendar_today, size: 20)), child: Text(dShow(v[f.k]))),
          ),
          req: f.req,
        );
      case 'time':
        final has = '${v[f.k] ?? ''}'.isNotEmpty;
        return aboveBox(
          f.label,
          InkWell(
            onTap: () async {
              final p = '${v[f.k] ?? tnow()}'.split(':');
              final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])));
              if (t != null) change(f.k, '${two(t.hour)}:${two(t.minute)}');
            },
            child: InputDecorator(
              decoration: dec(
                  suffix: has && !f.req
                      ? IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => change(f.k, ''))
                      : const Icon(Icons.access_time, size: 20)),
              child: Text(has ? tShow(v[f.k]) : '—'),
            ),
          ),
          req: f.req,
        );
      case 'pick':
        return aboveBox(
          f.label,
          Wrap(spacing: 8, runSpacing: 6, children: [
            for (final o in f.opts!(v)) ChoiceChip(label: Text(o), selected: v[f.k] == o, onSelected: (_) => change(f.k, o)),
          ]),
          req: f.req,
        );
      case 'multi':
        final o = f.opts!(v);
        final sel = List<String>.from((v[f.k] ?? []) as List);
        return aboveBox(
          f.label,
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (o.isEmpty) Text(S.tr('पहले ऊपर नाम भरें', 'Enter names above first'), style: const TextStyle(fontSize: 13)),
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (final x in o)
                FilterChip(
                  label: Text(x),
                  selected: sel.contains(x),
                  onSelected: (b) {
                    b ? sel.add(x) : sel.remove(x);
                    change(f.k, sel);
                  },
                ),
            ]),
          ]),
          req: f.req,
        );
      case 'check':
        return aboveBox(
          f.label,
          Container(
            decoration: neo(r: 14),
            child: CheckboxListTile(
              value: v[f.k] == true,
              title: Text(f.label, style: const TextStyle(fontWeight: FontWeight.w700)),
              onChanged: (b) => change(f.k, b == true),
            ),
          ),
        );
      case 'photo':
        final p = '${v[f.k] ?? ''}';
        return aboveBox(
          f.label,
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              TextButton.icon(onPressed: () => pickPhoto(f.k, ImageSource.camera), icon: const Icon(Icons.photo_camera), label: Text(S.tr('कैमरा', 'Camera'))),
              TextButton.icon(onPressed: () => pickPhoto(f.k, ImageSource.gallery), icon: const Icon(Icons.photo_library), label: Text(S.tr('गैलरी', 'Gallery'))),
            ]),
            if (p.isNotEmpty && File(p).existsSync())
              Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(p), height: 80, width: 80, fit: BoxFit.cover, cacheWidth: 200)),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => change(f.k, '')),
              ]),
          ]),
        );
      case 'people':
        final cnt = (v['cnt'] ?? 1) as int;
        final ps = (v['people'] ??= <dynamic>[]) as List;
        while (ps.length < cnt) {
          ps.add({'n': '', 'c': ''});
        }
        return aboveBox(
          f.label,
          Column(children: [
            aboveBox(
              S.tr('कितने लोग आए', 'Number of People'),
              DropdownButtonFormField<int>(
                value: cnt,
                decoration: dec(),
                items: [for (var i = 1; i <= 15; i++) DropdownMenuItem(value: i, child: Text('$i'))],
                onChanged: (x) => change('cnt', x ?? 1),
              ),
            ),
            for (var i = 0; i < cnt; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(
                    child: aboveBox(
                      '${S.tr('नाम', 'Name')} ${i + 1}',
                      TextFormField(
                        key: ValueKey('pn$i'),
                        initialValue: '${ps[i]['n']}',
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: dec(hint: S.tr('वैकल्पिक', 'Optional')),
                        onChanged: (s) => ps[i]['n'] = capWords(s),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: aboveBox(
                      S.tr('चैनल / प्रेस', 'Channel / Press'),
                      TextFormField(
                        key: ValueKey('pc$i'),
                        initialValue: '${ps[i]['c']}',
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: dec(),
                        onChanged: (s) => ps[i]['c'] = capWords(s),
                      ),
                    ),
                  ),
                ]),
              ),
          ]),
        );
    }
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) => Pg(
        widget.title,
        ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
          for (final f in widget.fields)
            if (vis(f)) field(f),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: submit,
            icon: const Icon(Icons.visibility),
            label: Text(S.tr('प्रीव्यू देखें', 'See Preview'), style: const TextStyle(fontSize: 17)),
          ),
        ]),
      );
}

class Rng {
  int mode = 2;
  DateTime date = DateTime.now();
  int m = DateTime.now().month, y = DateTime.now().year;
  bool ok(dynamic k) {
    if (mode == 2) return true;
    final d = dparse(k);
    return mode == 0 ? dkey(date) == '$k' : (d.month == m && d.year == y);
  }

  String get sub => mode == 0
      ? '${S.tr('तारीख', 'Date')}: ${dShow(dkey(date))}'
      : mode == 1
          ? '${S.tr('माह', 'Month')}: ${S.isEn ? monEn[m - 1] : mon[m - 1]} $y'
          : S.tr('सभी रिकॉर्ड', 'All Records');
  String get tag => mode == 0 ? 'date' : mode == 1 ? 'month' : 'all';
}

class RngBar extends StatelessWidget {
  final Rng r;
  final VoidCallback onChange;
  const RngBar(this.r, this.onChange, {super.key});
  @override
  Widget build(BuildContext c) {
    final names = [S.tr('तारीख वार', 'By Date'), S.tr('मासिक', 'Monthly'), S.tr('सभी', 'All')];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                  label: Text(names[i]),
                  selected: r.mode == i,
                  onSelected: (_) {
                    r.mode = i;
                    onChange();
                  }),
            ),
        ]),
        if (r.mode == 0)
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(dShow(dkey(r.date))),
            onPressed: () async {
              final d = await showDatePicker(context: c, initialDate: r.date, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (d != null) {
                r.date = d;
                onChange();
              }
            },
          ),
        if (r.mode == 1)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            DropdownButton<int>(
                value: r.m,
                items: [for (var i = 1; i <= 12; i++) DropdownMenuItem(value: i, child: Text(S.isEn ? monEn[i - 1] : mon[i - 1]))],
                onChanged: (x) {
                  r.m = x ?? r.m;
                  onChange();
                }),
            const SizedBox(width: 16),
            DropdownButton<int>(
                value: r.y,
                items: [for (var i = 2020; i <= 2050; i++) DropdownMenuItem(value: i, child: Text('$i'))],
                onChanged: (x) {
                  r.y = x ?? r.y;
                  onChange();
                }),
          ]),
      ]),
    );
  }
}

class RecordList extends StatefulWidget {
  final String title, pdfName;
  final List<Map<String, dynamic>> Function() source;
  final List<String> cols;
  final List<double> w;
  final List<String> Function(Map<String, dynamic> r, int i) row;
  final String Function(Map<String, dynamic> r) tTitle, tSub, tAmt;
  final Future<void> Function(Map<String, dynamic>? r) edit;
  final Future<void> Function(Map<String, dynamic> r) del;
  final List<String> Function(List<Map<String, dynamic>> recs)? notes;
  final List<Widget> extras;
  final int initialMode;
  final DateTime? initialDate;
  final void Function(BuildContext context, String dateKey, List<Map<String, dynamic>> dayRecs)? onDayTap;
  const RecordList({
    super.key,
    required this.title,
    required this.pdfName,
    required this.source,
    required this.cols,
    required this.w,
    required this.row,
    required this.tTitle,
    required this.tSub,
    required this.tAmt,
    required this.edit,
    required this.del,
    this.notes,
    this.extras = const [],
    this.initialMode = 2,
    this.initialDate,
    this.onDayTap,
  });
  @override
  State<RecordList> createState() => _RL();
}

class _RL extends State<RecordList> {
  late final Rng rng;

  @override
  void initState() {
    super.initState();
    rng = Rng()..mode = widget.initialMode;
    if (widget.initialDate != null) rng.date = widget.initialDate!;
  }

  int cmp(Map a, Map b) => '${b['date']} ${b['time'] ?? ''} ${b['id']}'.compareTo('${a['date']} ${a['time'] ?? ''} ${a['id']}');

  Map<String, List<Map<String, dynamic>>> groups(bool asc) {
    final l = widget.source().where((r) => rng.ok(r['date'])).toList()..sort(cmp);
    final dates = l.map((r) => '${r['date']}').toSet().toList()..sort();
    if (!asc) dates.sort((a, b) => b.compareTo(a));
    return {
      for (final d in dates) d: (l.where((r) => '${r['date']}' == d).toList()..sort(asc ? (a, b) => -cmp(a, b) : cmp)),
    };
  }

  List<Sec> _buildSecs() {
    final g = groups(true);
    return [
      for (final e in g.entries)
        Sec(dShow(e.key), widget.cols, widget.w, [for (var i = 0; i < e.value.length; i++) widget.row(e.value[i], i)], widget.notes?.call(e.value) ?? []),
    ];
  }

  Future<void> pdf() async {
    final secs = _buildSecs();
    if (secs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.tr('कोई रिकॉर्ड नहीं मिला', 'No records found'))));
      return;
    }
    await openPdfPreview(context, name: '${widget.pdfName}_${rng.tag}', title: widget.title, sub: rng.sub, secs: secs);
  }

  Future<void> csv() async {
    final g = groups(true);
    final rows = <List<String>>[];
    for (final e in g.entries) {
      for (var i = 0; i < e.value.length; i++) {
        rows.add([dShow(e.key), ...widget.row(e.value[i], i)]);
      }
    }
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.tr('कोई रिकॉर्ड नहीं मिला', 'No records found'))));
      return;
    }
    await guard(context, () => shareCsv('${widget.pdfName}_${rng.tag}', [S.tr('दिनांक', 'Date'), ...widget.cols], rows));
  }

  void detail(Map<String, dynamic> r) {
    final cells = widget.row(r, 0);
    final p = '${r['photo'] ?? r['r_photo'] ?? ''}';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBg,
      builder: (bc) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${dShow(r['date'])}  ${tShow(r['time'])}', style: const TextStyle(color: kBrown, fontWeight: FontWeight.w700)),
            if ('${r['thekedarName'] ?? r['khadanName'] ?? ''}'.isNotEmpty)
              Text('${r['khadanName'] ?? ''} · ${S.tr('ठेकेदार', 'Contractor')}: ${r['thekedarName'] ?? ''}', style: const TextStyle(fontSize: 12, color: kBrown)),
            const SizedBox(height: 8),
            for (var j = 1; j < widget.cols.length; j++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text('${widget.cols[j]}: ${cells[j].replaceAll('\n', ' | ')}', style: const TextStyle(fontSize: 15)),
              ),
            if ('${r['note'] ?? ''}'.isNotEmpty) Text('${S.tr('नोट', 'Note')}: ${r['note']}'),
            if (p.isNotEmpty && File(p).existsSync()) Padding(padding: const EdgeInsets.only(top: 8), child: Image.file(File(p), height: 160, cacheWidth: 600)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: Text(S.tr('एडिट', 'Edit')),
                  onPressed: () async {
                    Navigator.pop(bc);
                    await widget.edit(r);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(S.tr('PDF / शेयर', 'PDF / Share')),
                  onPressed: () async {
                    Navigator.pop(bc);
                    final sec = Sec(
                      dShow(r['date']),
                      widget.cols,
                      widget.w,
                      [widget.row(r, 0)],
                      widget.notes?.call([r]) ?? [],
                    );
                    await openPdfPreview(
                      context,
                      name: '${widget.pdfName}_${r['id'] ?? 'entry'}',
                      title: widget.title,
                      sub: '${dShow(r['date'])} ${tShow(r['time'])}'.trim(),
                      secs: [sec],
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.delete),
                  label: Text(S.tr('डिलीट', 'Delete')),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: bc,
                      builder: (dc) => AlertDialog(
                        title: Text(S.tr('डिलीट करें?', 'Delete record?')),
                        content: Text(S.tr('यह रिकॉर्ड हमेशा के लिए हट जाएगा।', 'This record will be permanently removed.')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dc, false), child: Text(S.tr('नहीं', 'No'))),
                          FilledButton(onPressed: () => Navigator.pop(dc, true), child: Text(S.tr('हाँ, हटाएँ', 'Yes, Delete'))),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await widget.del(r);
                      if (bc.mounted) Navigator.pop(bc);
                    }
                  },
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: S,
        builder: (_, __) {
          final g = groups(false);
          return Pg(
            widget.title,
            Column(children: [
              RngBar(rng, () => setState(() {})),
              Expanded(
                child: g.isEmpty
                    ? Center(child: Text(S.tr('कोई रिकॉर्ड नहीं', 'No records')))
                    : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), children: [
                        for (final e in g.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                            child: InkWell(
                              onTap: widget.onDayTap == null ? null : () => widget.onDayTap!(context, e.key, e.value),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${dShow(e.key)}  (${e.value.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: kBrown)),
                                    if (widget.onDayTap != null)
                                      Row(mainAxisSize: MainAxisSize.min, children: [
                                        Text(S.tr('उस दिन की सभी एंट्री', 'View Day List'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kBrown)),
                                        const Icon(Icons.chevron_right, size: 18, color: kBrown),
                                      ]),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          for (final r in e.value)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () => detail(r),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: neo(r: 18),
                                  child: Row(children: [
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(widget.tTitle(r), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                        const SizedBox(height: 2),
                                        Text(widget.tSub(r), style: const TextStyle(fontSize: 13, color: kBrown)),
                                      ]),
                                    ),
                                    Text(widget.tAmt(r), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  ]),
                                ),
                              ),
                            ),
                        ],
                      ]),
              ),
            ]),
            actions: [
              ...widget.extras,
              IconButton(tooltip: 'PDF', icon: const Icon(Icons.picture_as_pdf), onPressed: pdf),
              IconButton(tooltip: 'Excel', icon: const Icon(Icons.table_chart), onPressed: csv),
            ],
            fab: FloatingActionButton.extended(
              backgroundColor: kBrown,
              foregroundColor: Colors.white,
              onPressed: () => widget.edit(null),
              icon: const Icon(Icons.add),
              label: Text(S.tr('नई एंट्री', 'New Entry')),
            ),
          );
        },
      );
}
