import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_state.dart';
import '../theme/luna_theme.dart';
import '../models/models.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});
  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final e = context.read<AppState>().todayLog;
      if (e != null) {
        _mood = e.mood;
        _energy = e.energy;
        _pain = e.pain;
        _symptoms.addAll(e.symptoms);
        _notesCtrl.text = e.notes ?? '';
        if (e.basalTemp != null) _tempCtrl.text = e.basalTemp.toString();
      }
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Log saved! 💜', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: LunaTheme.primary,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e', style: GoogleFonts.nunito()),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LunaTheme.surface,
      appBar: AppBar(
        title: Text("📝 Today's Log", style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _saving ? null : _save,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: _saving ? LunaTheme.text3 : LunaTheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Save', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                    border: Border.all(color: on ? LunaTheme.primary : Colors.transparent),
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
          const SizedBox(height: 16),
          // Delete today's log button — only shown if log already saved
          Consumer<AppState>(
            builder: (ctx, state, _) => state.todayLog != null
              ? TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: ctx,
                      builder: (_) => AlertDialog(
                        title: Text('Delete today\'s log?', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
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
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Log deleted'), backgroundColor: Colors.grey),
                      );
                    }
                  },
                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red[300], size: 18),
                  label: Text('Delete today\'s log',
                      style: GoogleFonts.nunito(color: Colors.red[300], fontSize: 13, fontWeight: FontWeight.w600)),
                )
              : const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
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
