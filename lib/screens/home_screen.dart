import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../services/cycle_calculator.dart';
import '../theme/luna_theme.dart';
import '../models/models.dart';
import 'log_screen.dart';
import 'companion_chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final phase = state.currentPhase;
    final phaseColor = LunaTheme.phaseColor(phase.name);
    final isActivePeriod = state.currentCycle != null && state.currentCycle!.endDate == null;

    return Scaffold(
      backgroundColor: LunaTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: LunaTheme.surface,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(), style: GoogleFonts.nunito(fontSize: 13, color: LunaTheme.text2, fontWeight: FontWeight.w600)),
                Text(state.userName.isNotEmpty ? '${state.userName} 💜' : 'Luna 💜',
                    style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: LunaTheme.text)),
              ],
            ),
            actions: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanionChatScreen())),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: LunaTheme.surfaceV, shape: BoxShape.circle),
                  child: Center(child: Text(state.companionEmoji, style: const TextStyle(fontSize: 20))),
                ),
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PhaseCard(phase: phase, phaseColor: phaseColor, state: state, isActivePeriod: isActivePeriod),
                    const SizedBox(height: 16),
                    _MoodCard(state: state),
                    const SizedBox(height: 16),
                    Text('Tip of the day 💡', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 15)),
                    const SizedBox(height: 8),
                    _TipCard(state: state),
                    const SizedBox(height: 16),
                    _StatsGrid(state: state),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final CyclePhase phase;
  final Color phaseColor;
  final AppState state;
  final bool isActivePeriod;
  const _PhaseCard({required this.phase, required this.phaseColor, required this.state, required this.isActivePeriod});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [phaseColor.withOpacity(.85), phaseColor.withOpacity(.55)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: phaseColor.withOpacity(.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(phase.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(phase.label, style: GoogleFonts.nunito(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  if (state.currentCycleDay > 0)
                    Text('Cycle day ${state.currentCycleDay}',
                        style: GoogleFonts.nunito(color: Colors.white.withOpacity(.85), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          if (isActivePeriod && state.currentCycleDay > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: Colors.white.withOpacity(.25), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🩸', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text('Period day', style: GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  Text('${state.currentCycleDay}', style: GoogleFonts.nunito(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                  Text(' of ${state.periodLength}', style: GoogleFonts.nunito(color: Colors.white.withOpacity(.8), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(CycleCalculator.phaseDescription(phase),
              style: GoogleFonts.nunito(color: Colors.white.withOpacity(.9), fontSize: 13, height: 1.5)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () async { isActivePeriod ? await state.endPeriod() : await state.startPeriod(); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.25), borderRadius: BorderRadius.circular(14)),
                child: Center(
                  child: Text(
                    isActivePeriod ? '✓ Stop recording' : '🩸 Start period',
                    style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final AppState state;
  const _MoodCard({required this.state});
  static const _moods = [
    {'e': '😣', 'l': 'Terrible'},
    {'e': '😔', 'l': 'Bad'},
    {'e': '😐', 'l': 'Ok'},
    {'e': '😊', 'l': 'Good'},
    {'e': '🥰', 'l': 'Great'},
  ];

  @override
  Widget build(BuildContext context) {
    final current = state.todayLog?.mood;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How do you feel today?', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _moods.asMap().entries.map((e) {
              final sel = current == e.key + 1;
              return GestureDetector(
                onTap: () async {
                  final ex = state.todayLog;
                  await state.saveDayLog(DayLog(id: ex?.id, date: DateTime.now(), mood: e.key + 1, energy: ex?.energy, pain: ex?.pain, symptoms: ex?.symptoms ?? [], notes: ex?.notes));
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: sel ? LunaTheme.primary.withOpacity(.15) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: sel ? LunaTheme.primary : Colors.transparent, width: 2),
                      ),
                      child: Text(e.value['e']!, style: TextStyle(fontSize: sel ? 28 : 24)),
                    ),
                    const SizedBox(height: 4),
                    Text(e.value['l']!, style: GoogleFonts.nunito(fontSize: 9, color: sel ? LunaTheme.primary : LunaTheme.text3, fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final AppState state;
  const _TipCard({required this.state});

  static const _tipDetails = {
    CyclePhase.menstrual: {'icon': '🥬', 'title': 'Iron & Vitamin C', 'label': 'Nutrition', 'labelColor': 0xFF81C784, 'body': 'During menstruation, the body loses iron. Consume iron-rich foods (spinach, lentils, meat) paired with vitamin C for optimal absorption.', 'source': 'Mayo Clinic'},
    CyclePhase.follicular: {'icon': '⚡', 'title': 'Peak energy phase', 'label': 'Fitness', 'labelColor': 0xFF7986CB, 'body': 'Rising estrogen boosts your energy and strength. This is the best time for high-intensity workouts and new challenges.', 'source': 'ACOG'},
    CyclePhase.ovulation: {'icon': '🌸', 'title': 'Fertility window', 'label': 'Health', 'labelColor': 0xFFE6C14F, 'body': 'You are at your most fertile. LH surge triggers ovulation 24-36 hours before egg release. Signs include clear stretchy discharge.', 'source': 'ACOG'},
    CyclePhase.luteal: {'icon': '🥛', 'title': 'Calcium reduces PMS', 'label': 'Nutrition', 'labelColor': 0xFF81C784, 'body': 'Studies show 1200mg calcium daily reduces PMS symptoms — mood swings, bloating, irritability — by up to 48% over two months.', 'source': 'NCBI Study'},
    CyclePhase.unknown: {'icon': '💜', 'title': 'Track your cycle', 'label': 'Getting started', 'labelColor': 0xFFE8A4B8, 'body': 'Log your period start date to unlock personalized tips and predictions for your unique cycle.', 'source': 'Luna'},
  };

  @override
  Widget build(BuildContext context) {
    final t = _tipDetails[state.currentPhase] ?? _tipDetails[CyclePhase.unknown]!;
    final labelColor = Color(t['labelColor'] as int);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(t['icon'] as String, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t['title'] as String, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: LunaTheme.text)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: labelColor.withOpacity(.2), borderRadius: BorderRadius.circular(6)),
                    child: Text(t['label'] as String, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: labelColor)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(t['body'] as String, style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 13, height: 1.5)),
          const SizedBox(height: 8),
          Text('📚 ${t['source']}', style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final AppState state;
  const _StatsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final nextPeriod = state.nextPeriod;
    final cycleDay = state.currentCycleDay;
    return Row(
      children: [
        if (cycleDay > 0) ...[
          Expanded(child: _StatCard(icon: '📅', value: '$cycleDay', unit: 'period day', label: 'of ${state.periodLength}', color: LunaTheme.menstrual)),
          const SizedBox(width: 10),
        ],
        if (nextPeriod != null)
          Expanded(child: _StatCard(icon: '🌹', value: '${nextPeriod.difference(DateTime.now()).inDays}', unit: 'days', label: 'Next period', color: LunaTheme.secondary)),
        if (cycleDay <= 0 && nextPeriod == null)
          Expanded(child: _StatCard(icon: '🌙', value: '—', unit: 'days', label: 'Log a period', color: LunaTheme.primary)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon, value, unit, label;
  final Color color;
  const _StatCard({required this.icon, required this.value, required this.unit, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: LunaTheme.surfaceV, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: color, fontSize: 22)),
          Text(unit, style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 11, fontWeight: FontWeight.w600)),
          Text(label, style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 10)),
        ],
      ),
    );
  }
}
