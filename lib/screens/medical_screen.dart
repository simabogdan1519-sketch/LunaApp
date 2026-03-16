import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../theme/luna_theme.dart';
import '../models/models.dart';

class MedicalScreen extends StatelessWidget {
  const MedicalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: LunaTheme.surface,
      appBar: AppBar(
        title: Text('🩺 Medical', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showAddSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: LunaTheme.primary, borderRadius: BorderRadius.circular(14)),
                child: Text('+ Add', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
      body: state.medicalRecords.isEmpty
          ? _empty(context)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.upcomingMedical.isNotEmpty) ...[
                  _sectionTitle('📅 Upcoming'),
                  ...state.upcomingMedical.take(3).map((r) => _RecordCard(record: r, onDelete: () => state.deleteMedicalRecord(r.id!), onEdit: () => _showEditSheet(context, r), upcoming: true)),
                  const SizedBox(height: 16),
                ],
                _sectionTitle('📋 All records'),
                ...state.medicalRecords.map((r) => _RecordCard(record: r, onDelete: () => state.deleteMedicalRecord(r.id!), onEdit: () => _showEditSheet(context, r), upcoming: false)),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _empty(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('🩺', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 12),
      Text('No medical records', style: GoogleFonts.nunito(color: LunaTheme.text, fontWeight: FontWeight.w800, fontSize: 18)),
      const SizedBox(height: 6),
      Text('Track check-ups, tests, and results', style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 13)),
      const SizedBox(height: 12),
      Text('💡 Recommended checks:', style: GoogleFonts.nunito(color: LunaTheme.text2, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      ..._recommendedChecks.map((c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text('• $c', style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 12)),
      )),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: () => _showAddSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [LunaTheme.primary, LunaTheme.secondary]), borderRadius: BorderRadius.circular(22)),
          child: Text('+ Add first record', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
        ),
      ),
    ],
  ));

  static const _recommendedChecks = [
    'Pap smear (every 3 years, age 25–65)', 'Pelvic exam (annual)', 'Breast exam (annual)',
    'STI screening (annually if sexually active)', 'Blood pressure check', 'Thyroid panel',
    'Iron & ferritin levels', 'Vitamin D', 'HPV vaccine (age 9–26)',
  ];

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text, fontSize: 15)),
  );

  void _showAddSheet(BuildContext context) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(value: context.read<AppState>(), child: _AddMedicalSheet()),
  );

  void _showEditSheet(BuildContext context, MedicalRecord record) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(value: context.read<AppState>(), child: _AddMedicalSheet(editing: record)),
  );
}

class _RecordCard extends StatelessWidget {
  final MedicalRecord record;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool upcoming;
  const _RecordCard({required this.record, required this.onDelete, required this.onEdit, required this.upcoming});

  Color get _typeColor {
    switch (record.result?.toLowerCase()) {
      case 'normal': return LunaTheme.follicular;
      case 'abnormal': return LunaTheme.menstrual;
      case 'pending': return LunaTheme.ovulation;
      default: return LunaTheme.primary;
    }
  }

  String get _typeIcon {
    switch (record.type) {
      case 'checkup': return '🩺';
      case 'blood_test': return '🩸';
      case 'ultrasound': return '🔬';
      case 'vaccine': return '💉';
      case 'dentist': return '🦷';
      case 'other': return '📋';
      default: return '🩺';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.delete_outline, color: Colors.red.shade400),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: upcoming ? Border.all(color: LunaTheme.primary.withOpacity(.3)) : null,
        ),
        child: Row(children: [
          Text(_typeIcon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(record.title, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text)),
            Row(children: [
              Text(fmt.format(record.date), style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 11)),
              if (record.nextDue != null) ...[
                Text(' · next: ${fmt.format(record.nextDue!)}', style: GoogleFonts.nunito(color: LunaTheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ]),
            if (record.notes != null && record.notes!.isNotEmpty)
              Text(record.notes!, style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (record.result != null) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _typeColor.withOpacity(.15), borderRadius: BorderRadius.circular(8)),
              child: Text(record.result!, style: GoogleFonts.nunito(color: _typeColor, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onEdit,
              child: Icon(Icons.edit_outlined, size: 16, color: LunaTheme.primary),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _AddMedicalSheet extends StatefulWidget {
  final MedicalRecord? editing;
  const _AddMedicalSheet({this.editing});
  @override
  State<_AddMedicalSheet> createState() => _AddMedicalSheetState();
}

class _AddMedicalSheetState extends State<_AddMedicalSheet> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'checkup';
  String? _result;
  DateTime _date = DateTime.now();
  DateTime? _nextDue;
  bool _saving = false;

  static const _types = {'checkup': '🩺 Check-up', 'blood_test': '🩸 Blood test', 'ultrasound': '🔬 Ultrasound / Imaging', 'vaccine': '💉 Vaccine', 'dentist': '🦷 Dentist', 'other': '📋 Other'};
  static const _results = ['normal', 'abnormal', 'pending'];

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _type    = e.type;
      _result  = e.result;
      _date    = e.date;
      _nextDue = e.nextDue;
      if (e.notes != null) _notesCtrl.text = e.notes!;
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    final rec = MedicalRecord(
      id: widget.editing?.id,
      date: _date, type: _type,
      title: _titleCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      result: _result,
      nextDue: _nextDue,
    );
    if (widget.editing != null) {
      await context.read<AppState>().updateMedicalRecord(rec);
    } else {
      await context.read<AppState>().addMedicalRecord(rec);
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.editing != null ? 'Record updated! 🩺' : 'Record saved! 🩺',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: LunaTheme.primary,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: LunaTheme.surfaceV, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(widget.editing != null ? 'Edit medical record' : 'Add medical record', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w900, color: LunaTheme.text)),
          const SizedBox(height: 16),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'e.g. Annual check-up, Pap smear...'), style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Text('Type', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: LunaTheme.text2)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: _types.entries.map((e) {
            final sel = _type == e.key;
            return GestureDetector(
              onTap: () => setState(() => _type = e.key),
              child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: sel ? LunaTheme.primary : LunaTheme.surfaceV, borderRadius: BorderRadius.circular(16)),
                child: Text(e.value, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.white : LunaTheme.text2)),
              ),
            );
          }).toList()),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _DateRow('📅 Date', fmt.format(_date), () async {
              final p = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime.now(),
                builder: (c, w) => Theme(data: Theme.of(c).copyWith(colorScheme: ColorScheme.light(primary: LunaTheme.primary)), child: w!));
              if (p != null) setState(() => _date = p);
            })),
            const SizedBox(width: 10),
            Expanded(child: _DateRow('🔔 Next due', _nextDue != null ? fmt.format(_nextDue!) : 'Optional', () async {
              final p = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 365)), firstDate: DateTime.now(), lastDate: DateTime(2035),
                builder: (c, w) => Theme(data: Theme.of(c).copyWith(colorScheme: ColorScheme.light(primary: LunaTheme.primary)), child: w!));
              if (p != null) setState(() => _nextDue = p);
            })),
          ]),
          const SizedBox(height: 16),
          Text('Result', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: LunaTheme.text2)),
          const SizedBox(height: 8),
          Row(children: _results.map((r) {
            final sel = _result == r;
            final colors = {'normal': LunaTheme.follicular, 'abnormal': LunaTheme.menstrual, 'pending': LunaTheme.ovulation};
            return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
              onTap: () => setState(() => _result = sel ? null : r),
              child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: sel ? colors[r]!.withOpacity(.15) : LunaTheme.surfaceV, borderRadius: BorderRadius.circular(14), border: Border.all(color: sel ? colors[r]! : Colors.transparent)),
                child: Text(r, style: GoogleFonts.nunito(color: sel ? colors[r]! : LunaTheme.text2, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ));
          }).toList()),
          const SizedBox(height: 16),
          TextField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Notes (optional)')),
          const SizedBox(height: 20),
          GestureDetector(onTap: _saving ? null : _save, child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [LunaTheme.primary, LunaTheme.secondary]), borderRadius: BorderRadius.circular(20)),
            child: Center(child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Save record', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white))),
          )),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  const _DateRow(this.label, this.value, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: LunaTheme.surfaceV, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.nunito(fontSize: 11, color: LunaTheme.text2, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(value, style: GoogleFonts.nunito(fontSize: 13, color: LunaTheme.primary, fontWeight: FontWeight.w900)),
    ]),
  ));
}
