import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  JournalEntry? _editing; // null = new, non-null = editing existing
  final _titleCtrl   = TextEditingController();
  final _contentCtrl = TextEditingController();
  int? _mood;
  bool _saving = false;

  void _openNew() {
    _editing = null;
    _titleCtrl.clear();
    _contentCtrl.clear();
    setState(() { _mood = null; _writing = true; });
  }

  void _openEdit(JournalEntry e) {
    _editing = e;
    _titleCtrl.text   = e.title;
    _contentCtrl.text = e.content;
    setState(() { _mood = e.mood; _writing = true; });
  }

  Future<void> _save() async {
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write something first!')));
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final state = context.read<AppState>();
      final title = _titleCtrl.text.trim().isEmpty
          ? DateFormat('MMMM d, yyyy').format(DateTime.now())
          : _titleCtrl.text.trim();
      if (_editing != null) {
        await state.updateJournalEntry(JournalEntry(
          id: _editing!.id,
          date: _editing!.date,
          title: title,
          content: _contentCtrl.text.trim(),
          mood: _mood,
          activities: [],
        ));
      } else {
        await state.addJournalEntry(JournalEntry(
          date: DateTime.now(),
          title: title,
          content: _contentCtrl.text.trim(),
          mood: _mood,
          activities: [],
        ));
      }
      _titleCtrl.clear(); _contentCtrl.clear();
      setState(() { _mood = null; _writing = false; _saving = false; _editing = null; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editing != null ? '✏️ Entry updated!' : '✨ Journal entry saved!'),
          backgroundColor: LunaTheme.primary),
      );
    } catch (_) { setState(() => _saving = false); }
  }

  void _delete(BuildContext ctx, JournalEntry e) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Delete entry?', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text('This can\'t be undone.', style: GoogleFonts.nunito()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete', style: TextStyle(color: Colors.red[400]))),
        ],
      ),
    );
    if (confirm == true && ctx.mounted) {
      await ctx.read<AppState>().deleteJournalEntry(e.id!);
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Entry deleted'), backgroundColor: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: LunaTheme.surface,
      appBar: AppBar(
        title: Text(_writing ? (_editing != null ? '✏️ Edit entry' : '📝 New entry') : '📓 Journal',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text)),
        actions: [
          if (!_writing)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: _openNew,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: LunaTheme.primary, borderRadius: BorderRadius.circular(14)),
                  child: Text('+ New', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
            ),
          if (_writing)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () => setState(() { _writing = false; _editing = null; }),
                child: Text('Cancel', style: GoogleFonts.nunito(color: LunaTheme.text2)),
              ),
            ),
        ],
      ),
      body: _writing ? _buildForm() : _buildList(state),
    );
  }

  Widget _buildForm() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _titleCtrl,
        style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 18, color: LunaTheme.text),
        decoration: InputDecoration(
          hintText: 'Title (optional)',
          hintStyle: GoogleFonts.nunito(color: LunaTheme.text3, fontWeight: FontWeight.w600),
          border: InputBorder.none,
        ),
      ),
      const Divider(),
      const SizedBox(height: 8),
      // Mood picker
      Text('How are you feeling?', style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 12)),
      const SizedBox(height: 8),
      Row(children: List.generate(5, (i) {
        final emojis = ['😣','😔','😐','😊','🥰'];
        final active = _mood == i + 1;
        return GestureDetector(
          onTap: () => setState(() => _mood = i + 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: active ? LunaTheme.primary.withOpacity(.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: active ? Border.all(color: LunaTheme.primary, width: 1.5) : null,
            ),
            child: Text(emojis[i], style: const TextStyle(fontSize: 24)),
          ),
        );
      })),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _contentCtrl,
          maxLines: null,
          minLines: 8,
          style: GoogleFonts.nunito(color: LunaTheme.text, fontSize: 15, height: 1.6),
          decoration: InputDecoration(
            hintText: 'Write your thoughts, feelings, or anything on your mind...',
            hintStyle: GoogleFonts.nunito(color: LunaTheme.text3),
            border: InputBorder.none,
          ),
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: LunaTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _saving
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : Text(_editing != null ? 'Update entry' : 'Save entry',
                  style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      ),
    ]),
  );

  Widget _buildList(AppState state) {
    final log = state.todayLog;
    final hasLog = log != null;
    final moodEmojisL = ['', '😣', '😔', '😐', '😊', '🥰'];

    if (state.journalEntries.isEmpty && !hasLog) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('📓', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('No entries yet', style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 16)),
        const SizedBox(height: 8),
        Text('Tap + New to write your first entry', style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 13)),
      ]));
    }
    return Column(children: [
      // Swipe tip banner
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showSwipeTip
          ? Container(
              key: const ValueKey('tip'),
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: LunaTheme.primary.withOpacity(.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LunaTheme.primary.withOpacity(.2)),
              ),
              child: Row(children: [
                const Text('👈', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(child: Text('Swipe left on an entry to delete it',
                    style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: LunaTheme.primary))),
                GestureDetector(
                  onTap: () => setState(() => _showSwipeTip = false),
                  child: Icon(Icons.close_rounded, size: 16, color: LunaTheme.text3),
                ),
              ]),
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
      ),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.journalEntries.length + (hasLog ? 1 : 0),
      itemBuilder: (ctx, i) {
        // First item = today's daily log summary (if exists)
        if (hasLog && i == 0) {
          final log = state.todayLog!;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [LunaTheme.primary, LunaTheme.secondary]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('📋', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text("Today's Log — ${DateFormat('MMM d').format(log.date)}",
                      style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  const Spacer(),
                  if (log.mood != null) Text(moodEmojisL[log.mood!], style: const TextStyle(fontSize: 18)),
                ]),
                if (log.symptoms.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(log.symptoms.take(4).join(' · '),
                      style: GoogleFonts.nunito(color: Colors.white70, fontSize: 12)),
                ],
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(log.notes!, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(color: Colors.white70, fontSize: 12, height: 1.4)),
                ],
              ]),
            ),
          );
        }
        final e = state.journalEntries[hasLog ? i - 1 : i];
        final moodEmojis = ['', '😣', '😔', '😐', '😊', '🥰'];
        return Dismissible(
          key: ValueKey(e.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.delete_outline_rounded, color: Colors.red[400]),
          ),
          confirmDismiss: (_) async {
            final confirm = await showDialog<bool>(
              context: ctx,
              builder: (_) => AlertDialog(
                title: Text('Delete entry?', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                content: Text('This can\'t be undone.', style: GoogleFonts.nunito()),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Delete', style: TextStyle(color: Colors.red[400]))),
                ],
              ),
            );
            return confirm == true;
          },
          onDismissed: (_) => ctx.read<AppState>().deleteJournalEntry(e.id!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Row(children: [
                if (e.mood != null && e.mood! > 0)
                  Text(moodEmojis[e.mood!], style: const TextStyle(fontSize: 16)),
                if (e.mood != null && e.mood! > 0) const SizedBox(width: 6),
                Expanded(child: Text(e.title, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text))),
              ]),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 4),
                Text(e.content, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 13, height: 1.5)),
                const SizedBox(height: 6),
                Text(DateFormat('MMM d, yyyy · HH:mm').format(e.date),
                    style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 11)),
              ]),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 18, color: LunaTheme.primary),
                  onPressed: () => _openEdit(e),
                  tooltip: 'Edit',
                ),
              ]),
              onTap: () => _openEdit(e),
            ),
          ),
        );
      },
    ))]);
  }
}
