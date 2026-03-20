import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_state.dart';
import '../services/notification_service.dart';
import '../theme/luna_theme.dart';
import '../models/models.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  static const _presets = [
    {'title': 'Log daily symptoms', 'type': 'daily', 'time': '20:00', 'note': 'Take 2 min to log how you feel today'},
    {'title': 'Take pill', 'type': 'daily', 'time': '08:00', 'note': 'Don\'t forget your contraceptive pill'},
    {'title': 'Drink water (2.5L)', 'type': 'daily', 'time': '12:00', 'note': 'Hydration supports hormonal balance'},
    {'title': 'Magnesium before bed', 'type': 'daily', 'time': '21:00', 'note': '200-400mg magnesium glycinate for sleep & PMS'},
    {'title': 'Weekly journal entry', 'type': 'weekly', 'time': '19:00', 'note': 'Reflect on the week and how you felt'},
    {'title': 'Pelvic floor exercises', 'type': 'daily', 'time': '07:00', 'note': '3 sets of 10 Kegel exercises'},
    {'title': 'Iron supplement (period week)', 'type': 'daily', 'time': '09:00', 'note': 'Take with vitamin C for better absorption'},
    {'title': 'Annual gynaecologist', 'type': 'one_time', 'time': '09:00', 'note': 'Annual check-up reminder'},
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: LunaTheme.surface,
      appBar: AppBar(
        title: Text('🔔 Reminders', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showAddSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: LunaTheme.primary, borderRadius: BorderRadius.circular(14)),
                child: Text('+ New', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PermissionBanner(),
          if (state.reminders.isNotEmpty) ...[
            _sectionTitle('My reminders'),
            ...state.reminders.map((r) => _ReminderTile(reminder: r,
              onToggle: () => state.toggleReminder(r),
              onDelete: () => state.deleteReminder(r.id!),
              onEdit:   () => _showEditSheet(context, r),
            )),
            const SizedBox(height: 20),
          ],
          _sectionTitle('✨ Quick add'),
          ...(_presets.map((p) => _PresetTile(preset: p, onAdd: () async {
            await state.addReminder(AppReminder(
              title: p['title']!, type: p['type']!, time: p['time']!, note: p['note'],
            ));
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Added: ${p['title']}', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              backgroundColor: LunaTheme.primary, duration: const Duration(seconds: 2),
            ));
          }))),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text, fontSize: 15)),
  );


  void _showAddSheet(BuildContext context) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(value: context.read<AppState>(), child: _AddReminderSheet()),
  );

  void _showEditSheet(BuildContext context, AppReminder reminder) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(value: context.read<AppState>(), child: _AddReminderSheet(editing: reminder)),
  );
}

class _PermissionBanner extends StatefulWidget {
  @override
  State<_PermissionBanner> createState() => _PermissionBannerState();
}

class _PermissionBannerState extends State<_PermissionBanner> {
  bool _hasNotifPermission = true;
  bool _hasExactAlarm = true;

  @override
  void initState() { super.initState(); _check(); }

  Future<void> _check() async {
    final notif = await context.read<AppState>().checkNotificationPermission();
    if (mounted) setState(() { _hasNotifPermission = notif; _hasExactAlarm = true; });
  }

  @override
  Widget build(BuildContext context) {
    // Banner 1: no notification permission
    if (!_hasNotifPermission) {
      return _Banner(
        emoji: '🔔',
        title: 'Activează notificările',
        body: 'Permite notificările ca Luna să îți trimită reminder-e 💜',
        buttonLabel: 'Permite',
        color: LunaTheme.primary,
        onTap: () async {
          await context.read<AppState>().requestNotificationPermission();
          _check();
        },
      );
    }

    return const SizedBox.shrink();
  }
}

class _Banner extends StatelessWidget {
  final String emoji, title, body, buttonLabel;
  final Color color;
  final VoidCallback onTap;
  const _Banner({required this.emoji, required this.title, required this.body, required this.buttonLabel, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(.25)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: color, fontSize: 13))),
      ]),
      const SizedBox(height: 4),
      Text(body, style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 11, height: 1.4)),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          child: Text(buttonLabel, style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      ),
    ]),
  );
}

class _ReminderTile extends StatelessWidget {
  final AppReminder reminder;
  final VoidCallback onToggle, onDelete, onEdit;
  const _ReminderTile({required this.reminder, required this.onToggle, required this.onDelete, required this.onEdit});

  String get _typeLabel {
    switch (reminder.type) {
      case 'daily': return 'Daily';
      case 'weekly': return 'Weekly';
      case 'one_time': return 'Once';
      default: return reminder.type;
    }
  }

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey(reminder.id),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(16)),
      child: Icon(Icons.delete_outline, color: Colors.red.shade400),
    ),
    onDismissed: (_) => onDelete(),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: reminder.enabled ? LunaTheme.primary.withOpacity(.12) : LunaTheme.surfaceV, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text('🔔', style: TextStyle(fontSize: 20, color: reminder.enabled ? null : const Color(0xFFBBBBBB)))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(reminder.title, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: reminder.enabled ? LunaTheme.text : LunaTheme.text3)),
          Row(children: [
            Text(reminder.time, style: GoogleFonts.nunito(color: LunaTheme.primary, fontWeight: FontWeight.w900, fontSize: 13)),
            const SizedBox(width: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: LunaTheme.surfaceV, borderRadius: BorderRadius.circular(6)),
              child: Text(_typeLabel, style: GoogleFonts.nunito(fontSize: 10, color: LunaTheme.text2, fontWeight: FontWeight.w600))),
          ]),
        ])),
        IconButton(
          icon: Icon(Icons.edit_outlined, size: 18, color: LunaTheme.primary),
          onPressed: onEdit,
          tooltip: 'Edit',
        ),
        Switch(value: reminder.enabled, onChanged: (_) => onToggle(), activeColor: LunaTheme.primary),
      ]),
    ),
  );
}

class _PresetTile extends StatelessWidget {
  final Map<String, String> preset;
  final VoidCallback onAdd;
  const _PresetTile({required this.preset, required this.onAdd});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(preset['title']!, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 13)),
        Text('${preset['time']} · ${preset['type'] == 'daily' ? 'Daily' : preset['type'] == 'weekly' ? 'Weekly' : 'Once'}', style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 11)),
      ])),
      GestureDetector(onTap: onAdd, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: LunaTheme.primary.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
        child: Text('+ Add', style: GoogleFonts.nunito(color: LunaTheme.primary, fontWeight: FontWeight.w800, fontSize: 12)),
      )),
    ]),
  );
}

class _AddReminderSheet extends StatefulWidget {
  final AppReminder? editing;
  const _AddReminderSheet({this.editing});
  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'daily';
  String _time = '08:00';
  bool _saving = false;

  Future<void> _pickTime() async {
    final parts = _time.split(':');
    final p = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      builder: (c, w) => Theme(data: Theme.of(c).copyWith(colorScheme: ColorScheme.light(primary: LunaTheme.primary)), child: w!));
    if (p != null) setState(() => _time = '${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}');
  }

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _titleCtrl.text = widget.editing!.title;
      _type = widget.editing!.type;
      _time = widget.editing!.time;
      if (widget.editing!.note != null) _noteCtrl.text = widget.editing!.note!;
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    if (_saving) return;
    setState(() => _saving = true);
    final r = AppReminder(
      id: widget.editing?.id,
      title: _titleCtrl.text.trim(),
      type: _type,
      time: _time,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      enabled: widget.editing?.enabled ?? true,
    );
    if (widget.editing != null) {
      await context.read<AppState>().updateReminder(r);
    } else {
      await context.read<AppState>().addReminder(r);
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.editing != null ? 'Reminder updated! 🔔' : 'Reminder set! 🔔',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: LunaTheme.primary,
      ));
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: LunaTheme.surfaceV, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text(widget.editing != null ? 'Edit reminder' : 'New reminder', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w900, color: LunaTheme.text)),
        const SizedBox(height: 16),
        TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Reminder name'), style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: GestureDetector(onTap: _pickTime, child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: LunaTheme.surfaceV, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('⏰ Time', style: GoogleFonts.nunito(fontSize: 11, color: LunaTheme.text2, fontWeight: FontWeight.w700)),
              Text(_time, style: GoogleFonts.nunito(fontSize: 18, color: LunaTheme.primary, fontWeight: FontWeight.w900)),
            ]),
          ))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🔁 Repeat', style: GoogleFonts.nunito(fontSize: 11, color: LunaTheme.text2, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            ...['daily', 'weekly', 'one_time'].map((t) => GestureDetector(
              onTap: () => setState(() => _type = t),
              child: Row(children: [
                Radio<String>(value: t, groupValue: _type, onChanged: (v) => setState(() => _type = v!), activeColor: LunaTheme.primary, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                Text(t == 'daily' ? 'Daily' : t == 'weekly' ? 'Weekly' : 'Once', style: GoogleFonts.nunito(fontSize: 12, color: LunaTheme.text2)),
              ]),
            )),
          ])),
        ]),
        const SizedBox(height: 12),
        TextField(controller: _noteCtrl, decoration: const InputDecoration(hintText: 'Note (optional)')),
        const SizedBox(height: 20),
        GestureDetector(onTap: _saving ? null : _save, child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [LunaTheme.primary, LunaTheme.secondary]), borderRadius: BorderRadius.circular(20)),
          child: Center(child: Text('Set reminder 🔔', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white))),
        )),
        const SizedBox(height: 8),
      ]),
    ),
  );
}
