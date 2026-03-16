import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../theme/luna_theme.dart';
import '../models/models.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  bool _writing = false;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  int? _mood;
  bool _saving = false;

  Future<void> _save() async {
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write something first!')));
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await context.read<AppState>().addJournalEntry(JournalEntry(
        date: DateTime.now(),
        title: _titleCtrl.text.trim().isEmpty ? DateFormat('MMMM d, yyyy').format(DateTime.now()) : _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        mood: _mood,
        activities: [],
      ));
      _titleCtrl.clear();
      _contentCtrl.clear();
      setState(() { _mood = null; _writing = false; _saving = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Journal entry saved! 📖', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: LunaTheme.primary,
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error saving: $e'), backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<AppState>().journalEntries;
    return Scaffold(
      backgroundColor: LunaTheme.surface,
      appBar: AppBar(
        title: Text('📓 Journal', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text)),
        actions: [
          if (!_writing)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => setState(() => _writing = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: LunaTheme.primary, borderRadius: BorderRadius.circular(14)),
                  child: Text('+ New', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
        ],
      ),
      body: _writing ? _buildEditor() : _buildList(entries),
    );
  }

  Widget _buildEditor() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _titleCtrl,
        decoration: const InputDecoration(hintText: 'Title (optional)'),
        style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: TextField(
          controller: _contentCtrl,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: "Write your thoughts...",
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
          ),
          style: GoogleFonts.nunito(fontSize: 14, height: 1.6),
        ),
      ),
      const SizedBox(height: 16),
      Text('Mood', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text)),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ['😣','😔','😐','😊','🥰'].asMap().entries.map((e) {
          final sel = _mood == e.key + 1;
          return GestureDetector(
            onTap: () => setState(() => _mood = e.key + 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: sel ? LunaTheme.primary.withOpacity(.15) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: sel ? LunaTheme.primary : Colors.transparent, width: 2),
              ),
              child: Text(e.value, style: TextStyle(fontSize: sel ? 30 : 24)),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: GestureDetector(
          onTap: () => setState(() => _writing = false),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: LunaTheme.surfaceV, borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text('Cancel', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: LunaTheme.text2))),
          ),
        )),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: GestureDetector(
          onTap: _saving ? null : _save,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [LunaTheme.primary, LunaTheme.secondary]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Save entry 📖', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
        )),
      ]),
      const SizedBox(height: 32),
    ]),
  );

  Widget _buildList(List<JournalEntry> entries) {
    if (entries.isEmpty) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('📓', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('No entries yet', style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _writing = true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(color: LunaTheme.primary, borderRadius: BorderRadius.circular(20)),
            child: Text('Write your first entry', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    ));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (ctx, i) {
        final e = entries[i];
        return Dismissible(
          key: ValueKey(e.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => context.read<AppState>().deleteJournalEntry(e.id!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (e.mood != null) Text(['😣','😔','😐','😊','🥰'][e.mood! - 1], style: const TextStyle(fontSize: 18)),
                if (e.mood != null) const SizedBox(width: 8),
                Expanded(child: Text(e.title, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 14), overflow: TextOverflow.ellipsis)),
                Text(DateFormat('MMM d').format(e.date), style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 11)),
              ]),
              const SizedBox(height: 6),
              Text(e.content, style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 13, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
        );
      },
    );
  }
}
