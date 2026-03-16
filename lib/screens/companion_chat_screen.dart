import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_state.dart';
import '../theme/luna_theme.dart';
import '../models/models.dart';

// ── Huge response library ─────────────────────────────────────────────────────
class _Replies {
  static final _rng = Random();
  static String pick(List<String> list) => list[_rng.nextInt(list.length)];

  static const tired = [
    '💜 Fatigue is so real and valid. Your body works incredibly hard every single day.\n\nTry: a 10-min walk outside (natural light boosts serotonin!), iron-rich snack, or just give yourself full permission to rest. 🌿',
    '😴 Low energy can be a sign your body needs more support right now.\n\nDuring the luteal phase, progesterone naturally makes you sleepier. Magnesium glycinate before bed can work wonders! ✨',
    '🌙 Rest is productive too. Your body does enormous repair work while you sleep.\n\nIf you\'re tired a lot, check your iron levels — low ferritin is incredibly common and very treatable. 🩸',
    '💫 Honour the tiredness. It\'s your body speaking.\n\nHydration, a protein-rich snack, and 20 minutes of sunlight can shift energy levels more than you\'d expect! ☀️',
    '🍃 Even a short nap (10-20 min) can restore alertness without making you groggy.\n\nAlso: are you drinking enough water? Mild dehydration often feels like exhaustion! 💧',
    '🌸 During your period, your body loses iron — which is a key energy carrier. Pair iron-rich foods with Vitamin C to boost absorption by up to 3x. 🍊',
  ];

  static const pain = [
    '🌹 I\'m so sorry you\'re hurting. Pain is exhausting.\n\nA heating pad at 40°C has been shown to be as effective as ibuprofen for menstrual cramps (BMJ). Try it for 20 min! 🔥',
    '💊 Some science-backed options:\n• Ibuprofen (anti-inflammatory, take with food)\n• Heat therapy\n• Magnesium for muscle relaxation\n• Gentle yoga — especially child\'s pose and pigeon pose 🧘',
    '🫖 Ginger tea has real evidence behind it for cramp relief (NCBI 2009 study). Steep 1 tsp fresh ginger for 5 min, add honey. You deserve comfort! 💛',
    '🌿 Gentle movement can actually help! Walking increases blood flow and releases endorphins which are your body\'s natural pain relief.\n\nEven 10 minutes can make a difference. 🚶',
    '🍫 Dark chocolate (>70% cacao) contains magnesium which relaxes uterine muscles. It\'s not just a craving — it\'s your body being smart! Plus it boosts serotonin 💜',
    '🧘 Try this: lie on your back, place a pillow under your knees. Deep belly breathing activates the parasympathetic system and reduces pain perception. 5 slow breaths. 💆',
  ];

  static const cycle = []; // built dynamically in code

  static const mood = [
    '💜 How you feel matters. Your emotional health is as important as your physical health.\n\nDuring certain phases, your brain chemistry literally changes — what you\'re feeling is real, not "just hormones". 🧠',
    '🌸 Oestrogen is linked to serotonin and dopamine — so as it rises and falls across your cycle, your mood follows. You\'re not imagining it!\n\nKeep tracking — you\'ll start to see your own patterns. ✨',
    '🤗 Some phases are naturally harder than others. The luteal phase (last 2 weeks) often brings more emotional sensitivity.\n\nThat\'s valid. Plan lighter social commitments then if you can! 🌙',
    '💫 Your feelings are data, not flaws. Logging your mood daily builds self-awareness that\'s genuinely powerful over time. 📊',
    '🌿 If mood dips feel intense or predictable, that might be PMDD — worth mentioning to your doctor. You deserve support. 💜',
  ];

  static const food = [
    '🥦 Cruciferous vegetables (broccoli, cauliflower, Brussels sprouts) help your liver metabolise oestrogen more efficiently. Great for the luteal phase! 💚',
    '🐟 Omega-3 fatty acids (salmon, sardines, walnuts, flaxseed) reduce prostaglandins — the compounds that cause cramps. Try to eat them regularly! 🌊',
    '🫘 Lentils, beans, and chickpeas are high in iron AND fibre. Perfect during your period week — iron replenishment with happy digestion! 💛',
    '🥬 Magnesium-rich foods: spinach, pumpkin seeds, dark chocolate, almonds, avocado. Magnesium supports sleep, reduces PMS, and relaxes muscles. ✨',
    '🍊 Vitamin C dramatically increases iron absorption. Always pair iron-rich foods with something citrus — squeeze lemon on your spinach! 🍋',
    '🌰 Seed cycling: flaxseeds + pumpkin seeds in the follicular phase, sunflower + sesame seeds in the luteal phase. Supports natural hormone balance! 🌱',
  ];

  static const sleep = [
    '😴 Progesterone in the luteal phase can actually make you sleepier — but also disrupts deep sleep quality. It\'s a paradox!\n\nKeep your bedroom cool (18°C is ideal) and stick to consistent sleep times. 🌙',
    '🌙 Melatonin production requires darkness. Try blue-light blocking glasses or Night Mode 2 hours before bed — it makes a real difference! 📱',
    '🛁 A warm bath 1-2 hours before bed drops your core temperature as you cool down — which is actually the signal that triggers sleep onset. Try it! 💤',
    '🌿 Magnesium glycinate (200-400mg) before bed improves sleep quality AND reduces PMS. One of the most evidence-backed supplements. ✨',
    '☕ Caffeine has a half-life of ~5-6 hours. A coffee at 2pm means half of it is still in your system at 8pm. Try cutting off at 1pm if sleep is an issue! 🕐',
    '🧘 4-7-8 breathing: inhale for 4 counts, hold for 7, exhale for 8. Activates the parasympathetic nervous system and can help you fall asleep faster. Try it now! 💆',
  ];

  static const exercise = [
    '💪 During the follicular phase (after period ends), oestrogen peaks — this is your strongest, most energetic phase. PERFECT for high-intensity workouts and PBs! 🏋️',
    '🧘 In the luteal phase, shift to yoga, pilates, or long walks. Your body runs hotter, recovers slower, and needs more gentleness. Work with it, not against it! 🌿',
    '🏃 Even 20 minutes of moderate cardio releases endorphins that can genuinely reduce period pain. The hardest part is starting! ✨',
    '🌊 Swimming is incredible during your period — water pressure actually reduces flow, and the cool water soothes inflammation. Many swimmers report reduced cramps! 💙',
    '🤸 Pelvic floor exercises (Kegels) take 5 minutes a day and have huge long-term benefits: reduced cramps, better bladder control, improved core stability. Worth it! 💜',
    '🚶 A 10-minute walk after meals improves insulin sensitivity, which helps with hormonal balance and PMS. Simple and effective! ☀️',
  ];

  static const stress = [
    '🧠 Cortisol (the stress hormone) can suppress ovulation and disrupt cycle timing. If your cycle suddenly changes, stress is often a factor worth examining. 💜',
    '🌿 5 minutes of deep breathing can measurably reduce cortisol levels. Try box breathing: 4 counts in, 4 hold, 4 out, 4 hold. Repeat 4 times. 🌬️',
    '📵 Doomscrolling before bed spikes cortisol and disrupts melatonin. Try a 30-min phone-free window before sleep — even just a few days shows results! 🌙',
    '🛁 Baths, gentle music, candles — these aren\'t indulgences. They activate the rest-and-digest system that counteracts chronic stress. You deserve care! 🕯️',
    '🌸 Adaptogens like ashwagandha and rhodiola have evidence for reducing stress perception. Worth researching and discussing with your doctor! ✨',
    '✍️ Writing about stressors for just 15 minutes can reduce their mental load significantly (James Pennebaker\'s research). Your journal is a stress tool! 📓',
  ];

  static String greetingFor(String name, String phase, String companionEmoji, String tip) {
    final greetings = [
      'Hi $name! $companionEmoji\n\nI\'m here for you. You\'re in your $phase right now.\n\n$tip',
      'Hey $name! 🌙\n\nReady to take care of yourself today? You\'re in your $phase.\n\n$tip',
      'Hello $name! $companionEmoji\n\nHow\'s your day going? You\'re in your $phase — here\'s something useful:\n\n$tip',
      'Welcome back $name! 💜\n\nYou\'re on day ${DateTime.now().day % 5 + 1} of your $phase. \n\n$tip',
    ];
    return pick(greetings);
  }
}

// ── Screen ───────────────────────────────────────────────────────────────────
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
  final _customCtrl  = TextEditingController();
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendGreeting());
  }

  void _sendGreeting() {
    final state = context.read<AppState>();
    final tips = state.getCompanionTips();
    final tip  = _Replies.pick(tips);
    final name = state.userName.isNotEmpty ? state.userName : 'friend';
    final phase = state.currentPhase.label;
    _addCompanion(_Replies.greetingFor(name, phase, state.companionEmoji, tip));
  }

  void _addUser(String text) => setState(() => _messages.add(_Msg(text: text, isCompanion: false)));

  void _addCompanion(String text) {
    setState(() { _typing = true; });
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() { _typing = false; _messages.add(_Msg(text: text, isCompanion: true)); });
      _scrollToBottom();
    });
  }

  void _respond(String action) {
    _addUser(action);
    final state = context.read<AppState>();

    switch (action) {
      case '📊 My cycle':
        final resp = state.currentCycle != null
            ? '🌙 You\'re on cycle day ${state.currentCycleDay} — ${state.currentPhase.emoji} ${state.currentPhase.label}\n\n'
              '${state.nextPeriod != null ? "📅 Next period expected: ${state.nextPeriod!.day}/${state.nextPeriod!.month}/${state.nextPeriod!.year}\n\n" : ""}'
              '${state.isCycleRegular ? "✅ Your cycle is regular — great!" : "📊 Some variability in your cycle — totally normal!"}'
            : '💜 No cycle data yet! Go to Home and tap "Start period" when it begins.\n\nOnce you\'ve logged a few cycles, I\'ll give you much more personalised info! 🌸';
        _addCompanion(resp);
        break;
      case '💡 Tip for today':
        final tips = state.getCompanionTips();
        _addCompanion(_Replies.pick(tips));
        break;
      case '😴 I\'m tired':
        _addCompanion(_Replies.pick(_Replies.tired));
        break;
      case '😣 I\'m in pain':
        _addCompanion(_Replies.pick(_Replies.pain));
        break;
      case '🍎 Nutrition tips':
        _addCompanion(_Replies.pick(_Replies.food));
        break;
      case '💤 Sleep tips':
        _addCompanion(_Replies.pick(_Replies.sleep));
        break;
      case '🏃 Exercise tips':
        _addCompanion(_Replies.pick(_Replies.exercise));
        break;
      case '😰 I\'m stressed':
        _addCompanion(_Replies.pick(_Replies.stress));
        break;
      case '🌸 Mood support':
        _addCompanion(_Replies.pick(_Replies.mood));
        break;
      case '📓 Add journal':
        setState(() => _showJournalForm = true);
        _addCompanion('📖 I\'m listening. Write whatever\'s on your mind — no judgment! ↓');
        break;
    }
  }

  Future<void> _saveJournal() async {
    if (_journalCtrl.text.trim().isEmpty) return;
    await context.read<AppState>().addJournalEntry(JournalEntry(
      date: DateTime.now(),
      title: 'Chat entry ${DateTimeStr.now()}',
      content: _journalCtrl.text.trim(),
    ));
    _addUser(_journalCtrl.text.trim());
    setState(() => _showJournalForm = false);
    _journalCtrl.clear();
    final saved = ['✨ Saved to your journal! Writing is such a powerful tool for self-awareness. 💜',
      '📓 Entry saved! Every word you write is an act of self-care. 🌸',
      '💌 Your thoughts are now safely in your journal. Keep going! ✨'];
    _addCompanion(_Replies.pick(saved));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final quickActions = [
      '📊 My cycle', '💡 Tip for today', '😴 I\'m tired', '😣 I\'m in pain',
      '🍎 Nutrition tips', '💤 Sleep tips', '🏃 Exercise tips',
      '😰 I\'m stressed', '🌸 Mood support', '📓 Add journal',
    ];

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
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (_typing && i == _messages.length) {
                  return _TypingBubble(emoji: state.companionEmoji);
                }
                final msg = _messages[i];
                return _Bubble(msg: msg.text, companionEmoji: state.companionEmoji, isCompanion: msg.isCompanion);
              },
            ),
          ),

          // Journal form
          if (_showJournalForm)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _journalCtrl,
                  decoration: InputDecoration(
                    hintText: 'Write your thoughts...',
                    hintStyle: GoogleFonts.nunito(color: LunaTheme.text3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                )),
                const SizedBox(width: 8),
                Column(children: [
                  IconButton(icon: Icon(Icons.send_rounded, color: LunaTheme.primary), onPressed: _saveJournal),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                      onPressed: () => setState(() => _showJournalForm = false)),
                ]),
              ]),
            ),

          // Quick action chips — scrollable
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: quickActions.map((a) => GestureDetector(
                  onTap: () => _respond(a),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: LunaTheme.surfaceV,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: LunaTheme.primary.withOpacity(.2)),
                    ),
                    child: Text(a, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: LunaTheme.text2)),
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DateTimeStr {
  static String now() {
    final n = DateTime.now();
    return '${n.day}/${n.month} ${n.hour}:${n.minute.toString().padLeft(2,'0')}';
  }
}

class _Msg { final String text; final bool isCompanion; _Msg({required this.text, required this.isCompanion}); }

class _TypingBubble extends StatelessWidget {
  final String emoji;
  const _TypingBubble({required this.emoji});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 24)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (int i = 0; i < 3; i++)
            Container(margin: const EdgeInsets.symmetric(horizontal: 2), width: 6, height: 6, decoration: BoxDecoration(color: LunaTheme.primary.withOpacity(.5), shape: BoxShape.circle)),
        ]),
      ),
    ]),
  );
}

class _Bubble extends StatelessWidget {
  final String msg, companionEmoji;
  final bool isCompanion;
  const _Bubble({required this.msg, required this.companionEmoji, required this.isCompanion});
  @override
  Widget build(BuildContext context) => Padding(
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
                topLeft:     const Radius.circular(18),
                topRight:    const Radius.circular(18),
                bottomLeft:  Radius.circular(isCompanion ? 4 : 18),
                bottomRight: Radius.circular(isCompanion ? 18 : 4),
              ),
            ),
            child: Text(msg, style: GoogleFonts.nunito(
              color: isCompanion ? LunaTheme.text : Colors.white,
              fontSize: 14, height: 1.5, fontWeight: FontWeight.w600,
            )),
          ),
        ),
      ],
    ),
  );
}
