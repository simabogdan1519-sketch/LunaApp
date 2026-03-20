import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../theme/luna_theme.dart';
import '../models/models.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});
  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  int? _mood, _energy, _pain;
  final Set<String> _symptoms = {};
  final _notesCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  final List<String> _symptomList = [
    'Cramps 🤕', 'Bloating 🫧', 'Headache 🤯', 'Fatigue 😴',
    'Nausea 🤢', 'Backache 🔙', 'Breast pain 💗', 'Mood swings 🎭',
    'Acne 😓', 'Insomnia 😶', 'Cravings 🍫', 'Spotting 🩸',
    'Irritability 😤', 'Brain fog 🌫️', 'Joint pain 🦵', 'Hot flashes 🔥',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _notesCtrl.dispose();
    _tempCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadFromState();
    }
  }

  void _loadFromState() {
    final e = context.read<AppState>().todayLog;
    if (e != null) {
      _mood = e.mood;
      _energy = e.energy;
      _pain = e.pain;
      _symptoms.clear();
      _symptoms.addAll(e.symptoms);
      _notesCtrl.text = e.notes ?? '';
      if (e.basalTemp != null) _tempCtrl.text = e.basalTemp.toString();
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final state = context.read<AppState>();
      await state.saveDayLog(DayLog(
        id: state.todayLog?.id,
        date: DateTime.now(),
        mood: _mood,
        energy: _energy,
        pain: _pain,
        basalTemp: _tempCtrl.text.trim().isNotEmpty ? double.tryParse(_tempCtrl.text.trim()) : null,
        symptoms: _symptoms.toList(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
      if (mounted) {
        _tab.animateTo(1);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Log saved! 💜', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: LunaTheme.primary,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: GoogleFonts.nunito()),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(BuildContext ctx) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text("Delete today's log?", style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text('All entries for today will be removed.', style: GoogleFonts.nunito()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete', style: TextStyle(color: Colors.red[400]))),
        ],
      ),
    );
    if (confirm == true && ctx.mounted) {
      await ctx.read<AppState>().deleteDayLog(DateTime.now());
      setState(() {
        _mood = null; _energy = null; _pain = null;
        _symptoms.clear(); _notesCtrl.clear(); _tempCtrl.clear();
        _loaded = false;
      });
      _tab.animateTo(0);
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Log deleted'), backgroundColor: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LunaTheme.surface,
      appBar: AppBar(
        backgroundColor: LunaTheme.surface, elevation: 0,
        title: Text("📝 Today's Log", style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text)),
        bottom: TabBar(
          controller: _tab,
          labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 13),
          labelColor: LunaTheme.primary,
          unselectedLabelColor: LunaTheme.text3,
          indicatorColor: LunaTheme.primary,
          tabs: const [Tab(text: '✏️ Log'), Tab(text: '👁️ View')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildLogTab(), _buildViewTab()],
      ),
    );
  }

  Widget _buildLogTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Section('😊 Mood', _EmojiPicker(
        emojis: const ['😣','😔','😐','😊','🥰'],
        labels: const ['Terrible','Bad','Ok','Good','Great'],
        selected: _mood, onSelect: (v) => setState(() => _mood = v),
      )),
      _Section('⚡ Energy', _BarPicker(value: _energy, color: LunaTheme.follicular, onChanged: (v) => setState(() => _energy = v))),
      _Section('🤕 Pain level', _BarPicker(value: _pain, color: LunaTheme.menstrual, onChanged: (v) => setState(() => _pain = v))),
      _Section('🩺 Symptoms', Wrap(
        spacing: 8, runSpacing: 8,
        children: _symptomList.map((s) {
          final on = _symptoms.contains(s);
          return GestureDetector(
            onTap: () => setState(() => on ? _symptoms.remove(s) : _symptoms.add(s)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: on ? LunaTheme.primary : LunaTheme.surfaceV,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(s, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: on ? Colors.white : LunaTheme.text2)),
            ),
          );
        }).toList(),
      )),
      _Section('🌡️ Basal temperature (°C)', TextField(
        controller: _tempCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(hintText: '36.5', prefixIcon: Icon(Icons.thermostat_outlined, color: LunaTheme.primary)),
      )),
      _Section('📝 Notes', TextField(
        controller: _notesCtrl, maxLines: 3,
        decoration: const InputDecoration(hintText: 'How are you feeling today?'),
      )),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _saving ? null : _save,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [LunaTheme.primary, LunaTheme.secondary]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text('Save log 💜', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ),
      ),
      const SizedBox(height: 24),
    ]),
  );

  Widget _buildViewTab() {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final log = state.todayLog;
        if (log == null) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('📋', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text("No log for today yet", style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 17, color: LunaTheme.text)),
              const SizedBox(height: 6),
              Text("Switch to ✏️ Log to add your daily entry", style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 13)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _tab.animateTo(0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(color: LunaTheme.primary, borderRadius: BorderRadius.circular(16)),
                  child: Text('Log now', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          );
        }

        final moodEmojis = ['', '😣','😔','😐','😊','🥰'];
        final moodLabels = ['', 'Terrible','Bad','Ok','Good','Great'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [LunaTheme.primary, LunaTheme.secondary]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                const Text('📋', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Today's Log", style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(DateFormat('EEEE, MMMM d').format(log.date),
                      style: GoogleFonts.nunito(color: Colors.white70, fontSize: 12)),
                ])),
                GestureDetector(
                  onTap: () { setState(() { _loaded = false; }); _loadFromState(); _tab.animateTo(0); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                    child: Text('✏️ Edit', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(children: [
              if (log.mood != null) _StatChip('😊 Mood', '${moodEmojis[log.mood!]} ${moodLabels[log.mood!]}'),
              if (log.mood != null) const SizedBox(width: 8),
              if (log.energy != null) _StatChip('⚡ Energy', '${'▓' * log.energy!}${'░' * (5 - log.energy!)}'),
              if (log.energy != null) const SizedBox(width: 8),
              if (log.pain != null) _StatChip('🤕 Pain', '${log.pain}/5'),
            ]),
            const SizedBox(height: 12),

            // Symptoms
            if (log.symptoms.isNotEmpty) ...[
              Text('🩺 Symptoms', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: log.symptoms.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: LunaTheme.primary.withOpacity(.1), borderRadius: BorderRadius.circular(16)),
                  child: Text(s, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: LunaTheme.primary)),
                )).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Basal temp
            if (log.basalTemp != null) ...[
              _InfoRow('🌡️ Basal temperature', '${log.basalTemp}°C'),
              const SizedBox(height: 8),
            ],

            // Notes
            if (log.notes != null && log.notes!.isNotEmpty) ...[
              Text('📝 Notes', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: LunaTheme.surfaceV, borderRadius: BorderRadius.circular(14)),
                child: Text(log.notes!, style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 14, height: 1.5)),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 8),
            // Delete button
            Center(
              child: TextButton.icon(
                onPressed: () => _delete(ctx),
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red[300], size: 18),
                label: Text("Delete today's log",
                    style: GoogleFonts.nunito(color: Colors.red[300], fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  const _StatChip(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: LunaTheme.surfaceV, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.nunito(fontSize: 10, color: LunaTheme.text3, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(value, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: LunaTheme.text)),
    ]),
  ));
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: LunaTheme.text2, fontSize: 13)),
    const Spacer(),
    Text(value, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 13)),
  ]);
}

class _Section extends StatelessWidget {
  final String title; final Widget child;
  const _Section(this.title, this.child);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 15)),
      const SizedBox(height: 10), child,
    ]),
  );
}

class _EmojiPicker extends StatelessWidget {
  final List<String> emojis, labels;
  final int? selected;
  final ValueChanged<int> onSelect;
  const _EmojiPicker({required this.emojis, required this.labels, required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: emojis.asMap().entries.map((e) {
      final sel = selected == e.key + 1;
      return GestureDetector(
        onTap: () => onSelect(e.key + 1),
        child: Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: sel ? LunaTheme.primary.withOpacity(.15) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: sel ? LunaTheme.primary : Colors.transparent, width: 2),
            ),
            child: Text(e.value, style: TextStyle(fontSize: sel ? 30 : 24)),
          ),
          const SizedBox(height: 4),
          Text(labels[e.key], style: GoogleFonts.nunito(fontSize: 9, color: sel ? LunaTheme.primary : LunaTheme.text3, fontWeight: FontWeight.w700)),
        ]),
      );
    }).toList(),
  );
}

class _BarPicker extends StatelessWidget {
  final int? value; final Color color; final ValueChanged<int> onChanged;
  const _BarPicker({required this.value, required this.color, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(5, (i) {
      final active = value != null && i < value!;
      return Expanded(child: GestureDetector(
        onTap: () => onChanged(i + 1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 14,
          decoration: BoxDecoration(color: active ? color : LunaTheme.surfaceV, borderRadius: BorderRadius.circular(7)),
        ),
      ));
    }),
  );
}
