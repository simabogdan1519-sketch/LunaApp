import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_state.dart';
import '../theme/luna_theme.dart';
import '../models/models.dart';

class CompanionChatScreen extends StatefulWidget {
  const CompanionChatScreen({super.key});
  @override
  State<CompanionChatScreen> createState() => _CompanionChatScreenState();
}

class _CompanionChatScreenState extends State<CompanionChatScreen> {
  final _scrollCtrl = ScrollController();
  final List<_Msg> _messages = [];
  bool _showJournalForm = false;
  final _journalCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendGreeting());
  }

  void _sendGreeting() {
    final state = context.read<AppState>();
    final tips = state.getCompanionTips();
    final tip = tips[DateTime.now().hour % tips.length];
    final name = state.userName.isNotEmpty ? state.userName : 'friend';
    setState(() {
      _messages.add(_Msg(text: 'Hi $name! ${state.companionEmoji}\n\nI\'m ${state.companionName}, your cycle companion!\n\n$tip', isCompanion: true));
    });
  }

  void _sendQuickAction(String action) {
    final state = context.read<AppState>();
    setState(() { _messages.add(_Msg(text: action, isCompanion: false)); });
    String response = '';
    switch (action) {
      case '📊 My cycle':
        response = state.currentCycle != null
            ? '🌙 You\'re on Day ${state.currentCycleDay} — ${state.currentPhase.label}\n\n${state.nextPeriod != null ? "📅 Next period: around ${state.nextPeriod!.day}/${state.nextPeriod!.month}" : ""}'
            : '💜 You haven\'t logged a period start yet. Go to Home and tap "Start period" when it begins!';
        break;
      case '💡 Tip for today':
        final tips = state.getCompanionTips();
        response = tips[DateTime.now().day % tips.length];
        break;
      case '😴 I\'m tired':
        response = '💜 Fatigue is valid and real! During ${state.currentPhase.label}, energy changes are normal.\n\nTry: 10 min walk, iron-rich food, or just rest — you\'ve earned it! 🌿';
        break;
      case '😣 I\'m in pain':
        response = '🌹 I\'m sorry you\'re hurting. A heating pad at 40°C is as effective as mild pain relief (Mayo Clinic).\n\nAlso try: gentle yoga, magnesium, or dark chocolate! 🍫';
        break;
      case '📓 Add journal':
        setState(() { _showJournalForm = true; });
        response = '📖 Tell me about your day! Write what\'s on your mind ↓';
        break;
    }
    if (response.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() { _messages.add(_Msg(text: response, isCompanion: true)); });
        _scrollToBottom();
      });
    }
  }

  Future<void> _saveJournal() async {
    if (_journalCtrl.text.isEmpty) return;
    await context.read<AppState>().addJournalEntry(JournalEntry(
      date: DateTime.now(),
      title: 'Chat entry',
      content: _journalCtrl.text,
    ));
    setState(() {
      _messages.add(_Msg(text: _journalCtrl.text, isCompanion: false));
      _showJournalForm = false;
      _messages.add(_Msg(text: '✨ Saved to your journal! Writing is so powerful for wellbeing. 💜', isCompanion: true));
    });
    _journalCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: LunaTheme.surfaceV,
      appBar: AppBar(
        backgroundColor: LunaTheme.surface,
        leading: const BackButton(),
        title: Row(children: [
          Text(state.companionEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(state.companionName, style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text, fontSize: 16)),
            Text('Your cycle companion', style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 11)),
          ]),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                return _Bubble(msg: msg.text, companionEmoji: state.companionEmoji, isCompanion: msg.isCompanion);
              },
            ),
          ),
          if (_showJournalForm) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Expanded(child: TextField(controller: _journalCtrl, decoration: const InputDecoration(hintText: 'Write your thoughts...'), maxLines: 2)),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.send, color: LunaTheme.primary), onPressed: _saveJournal),
            ]),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: ['📊 My cycle', '💡 Tip for today', '😴 I\'m tired', '😣 I\'m in pain', '📓 Add journal'].map((a) =>
                GestureDetector(
                  onTap: () => _sendQuickAction(a),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: LunaTheme.surfaceV, borderRadius: BorderRadius.circular(20)),
                    child: Text(a, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: LunaTheme.text2)),
                  ),
                ),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool isCompanion;
  _Msg({required this.text, required this.isCompanion});
}

class _Bubble extends StatelessWidget {
  final String msg, companionEmoji;
  final bool isCompanion;
  const _Bubble({required this.msg, required this.companionEmoji, required this.isCompanion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isCompanion ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isCompanion) ...[
            Text(companionEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCompanion ? Colors.white : LunaTheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isCompanion ? 4 : 18),
                  bottomRight: Radius.circular(isCompanion ? 18 : 4),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Text(msg, style: GoogleFonts.nunito(color: isCompanion ? LunaTheme.text : Colors.white, fontSize: 14, height: 1.5, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
