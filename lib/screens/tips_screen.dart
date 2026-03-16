import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_state.dart';
import '../services/cycle_calculator.dart';
import '../theme/luna_theme.dart';
import '../models/models.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  static const Map<CyclePhase, List<Map<String, String>>> _tips = {
    CyclePhase.menstrual: [
      {'title': 'Rest is productive', 'body': 'During menstruation, your body works hard. Prioritize sleep and gentle movement. ACOG recommends light exercise to ease cramping naturally.', 'icon': '😴'},
      {'title': 'Iron-rich foods', 'body': 'Replenish lost iron with spinach, lentils, and red meat. Pair with vitamin C for better absorption (ACOG nutrition guidelines).', 'icon': '🥬'},
      {'title': 'Heat therapy', 'body': 'A heating pad at 40°C provides relief comparable to ibuprofen for mild to moderate dysmenorrhea (Mayo Clinic).', 'icon': '🔥'},
      {'title': 'Hydration matters', 'body': 'Drink 8-10 glasses of water daily. Dehydration can worsen cramps and headaches during your period.', 'icon': '💧'},
    ],
    CyclePhase.follicular: [
      {'title': 'Energy is rising', 'body': 'Rising estrogen boosts serotonin. This is your most energetic phase — great for starting new projects and intense workouts.', 'icon': '⚡'},
      {'title': 'Strength training', 'body': 'Muscles respond better to resistance training in the follicular phase due to higher estrogen. Great time for PRs!', 'icon': '💪'},
      {'title': 'Eat for hormones', 'body': 'Fermented foods (yogurt, kimchi) support healthy estrogen metabolism. Flaxseeds help balance hormones naturally.', 'icon': '🥗'},
      {'title': 'Creativity boost', 'body': 'Estrogen enhances neural connectivity. Use this phase for brainstorming, creative projects and social connections.', 'icon': '🎨'},
    ],
    CyclePhase.ovulation: [
      {'title': 'Peak fertility window', 'body': 'The 24h after ovulation and 5 days before are your most fertile. LH surge occurs 24-36h before egg release (ACOG).', 'icon': '🌸'},
      {'title': 'Confidence peaks', 'body': 'Studies show women feel most confident and social during ovulation. Schedule important presentations or dates!', 'icon': '✨'},
      {'title': 'Watch for signs', 'body': 'Ovulation signs include clear stretchy discharge (like egg whites), mild pelvic pain (Mittelschmerz), and slight temp rise.', 'icon': '🌡️'},
    ],
    CyclePhase.luteal: [
      {'title': 'Progesterone phase', 'body': 'Progesterone rises then falls, which can cause PMS. You\'re not "too sensitive" — it\'s real biology. Be kind to yourself.', 'icon': '🌙'},
      {'title': 'Calcium reduces PMS', 'body': 'Studies show 1200mg calcium daily reduces PMS symptoms by 48%. Good sources: dairy, almonds, broccoli.', 'icon': '🥛'},
      {'title': 'Move gently', 'body': 'A 30-minute walk raises endorphins more effectively in this phase than vigorous exercise. Nature walks are ideal.', 'icon': '🚶'},
      {'title': 'Tryptophan foods', 'body': 'Sweet potatoes, oats, and turkey boost serotonin to counter mood dips. Magnesium (dark chocolate!) helps too.', 'icon': '🍫'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final phase = state.currentPhase;
    final phaseColor = LunaTheme.phaseColor(phase.name);
    final tips = _tips[phase] ?? _tips[CyclePhase.follicular]!;

    return Scaffold(
      backgroundColor: LunaTheme.surface,
      appBar: AppBar(title: Text('💡 Tips', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: phaseColor.withOpacity(.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: phaseColor.withOpacity(.3)),
            ),
            child: Row(
              children: [
                Text(phase.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(phase.label, style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: phaseColor, fontSize: 16)),
                    Text(CycleCalculator.phaseDescription(phase), style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 12, height: 1.4)),
                  ],
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...tips.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['icon']!, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['title']!, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(t['body']!, style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 12, height: 1.5)),
                  ],
                )),
              ],
            ),
          )),
          const SizedBox(height: 8),
          Center(child: Text('Based on ACOG & Mayo Clinic guidelines', style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 11))),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
