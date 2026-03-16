import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../services/cycle_calculator.dart';
import '../services/insights_engine.dart';
import '../theme/luna_theme.dart';
import '../models/models.dart';
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
            pinned: true, backgroundColor: LunaTheme.surface, elevation: 0,
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_greeting(), style: GoogleFonts.nunito(fontSize: 13, color: LunaTheme.text2, fontWeight: FontWeight.w600)),
              Text(state.userName.isNotEmpty ? '${state.userName} 💜' : 'Luna 💜',
                  style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: LunaTheme.text)),
            ]),
            actions: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanionChatScreen())),
                child: Container(
                  margin: const EdgeInsets.only(right: 16), width: 40, height: 40,
                  decoration: BoxDecoration(color: LunaTheme.surfaceV, shape: BoxShape.circle),
                  child: Center(child: Text(state.companionEmoji, style: const TextStyle(fontSize: 20))),
                ),
              ),
            ],
          ),
          SliverList(delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _PhaseCard(phase: phase, phaseColor: phaseColor, state: state, isActivePeriod: isActivePeriod),
                const SizedBox(height: 14),
                _UpcomingEventsRow(state: state),
                const SizedBox(height: 14),
                _MoodCard(state: state),
                const SizedBox(height: 14),
                _InsightsCard(state: state),
                const SizedBox(height: 14),
                Text('Tip of the day 💡', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 15)),
                const SizedBox(height: 8),
                _TipCard(state: state),
                const SizedBox(height: 14),
                _StatsRow(state: state),
              ]),
            ),
          ])),
        ],
      ),
    );
  }
}

// ── Phase Card ────────────────────────────────────────────────────────────────
class _PhaseCard extends StatelessWidget {
  final CyclePhase phase; final Color phaseColor; final AppState state; final bool isActivePeriod;
  const _PhaseCard({required this.phase, required this.phaseColor, required this.state, required this.isActivePeriod});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [phaseColor.withOpacity(.85), phaseColor.withOpacity(.55)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: phaseColor.withOpacity(.3), blurRadius: 16, offset: const Offset(0, 6))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(phase.emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(phase.label, style: GoogleFonts.nunito(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          if (state.currentCycleDay > 0)
            Text('Cycle day ${state.currentCycleDay}', style: GoogleFonts.nunito(color: Colors.white.withOpacity(.85), fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const Spacer(),
        if (state.cycles.length >= 2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(.2), borderRadius: BorderRadius.circular(10)),
            child: Text('~${state.smartCycleLength}d avg', style: GoogleFonts.nunito(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
      ]),
      if (isActivePeriod && state.currentCycleDay > 0) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(color: Colors.white.withOpacity(.25), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('🩸', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text('Period day', style: GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Text('${state.currentCycleDay}', style: GoogleFonts.nunito(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            Text(' of ${state.smartPeriodLength}', style: GoogleFonts.nunito(color: Colors.white.withOpacity(.8), fontSize: 12)),
          ]),
        ),
      ],
      const SizedBox(height: 10),
      Text(CycleCalculator.phaseDescription(phase), style: GoogleFonts.nunito(color: Colors.white.withOpacity(.9), fontSize: 13, height: 1.5)),
      const SizedBox(height: 14),
      GestureDetector(
        onTap: () async => isActivePeriod ? await state.endPeriod() : await state.startPeriod(),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(color: Colors.white.withOpacity(.25), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(isActivePeriod ? '✓ Stop recording' : '🩸 Start period',
            style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
        ),
      ),
    ]),
  );
}

// ── Upcoming Events Row ───────────────────────────────────────────────────────
class _UpcomingEventsRow extends StatelessWidget {
  final AppState state;
  const _UpcomingEventsRow({required this.state});
  @override
  Widget build(BuildContext context) {
    final events = state.upcomingEvents;
    if (events.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Coming up 📍', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 15)),
      const SizedBox(height: 8),
      ...events.take(3).map((e) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Text(e.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.title, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 13)),
            Text(e.subtitle, style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: e.daysUntil == 0 ? LunaTheme.menstrual.withOpacity(.15) : LunaTheme.primary.withOpacity(.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(e.daysUntil == 0 ? 'Today' : e.daysUntil == 1 ? 'Tomorrow' : 'In ${e.daysUntil}d',
              style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w900,
                color: e.daysUntil == 0 ? LunaTheme.menstrual : LunaTheme.primary)),
          ),
        ]),
      )),
    ]);
  }
}

// ── Mood Card ─────────────────────────────────────────────────────────────────
class _MoodCard extends StatelessWidget {
  final AppState state;
  const _MoodCard({required this.state});
  static const _moods = [{'e':'😣','l':'Terrible'},{'e':'😔','l':'Bad'},{'e':'😐','l':'Ok'},{'e':'😊','l':'Good'},{'e':'🥰','l':'Great'}];
  @override
  Widget build(BuildContext context) {
    final current = state.todayLog?.mood;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How do you feel today?', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 14)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: _moods.asMap().entries.map((e) {
          final sel = current == e.key + 1;
          return GestureDetector(
            onTap: () async {
              final ex = state.todayLog;
              await state.saveDayLog(DayLog(id: ex?.id, date: DateTime.now(), mood: e.key + 1, energy: ex?.energy, pain: ex?.pain, symptoms: ex?.symptoms ?? [], notes: ex?.notes));
            },
            child: Column(children: [
              AnimatedContainer(duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: sel ? LunaTheme.primary.withOpacity(.15) : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: sel ? LunaTheme.primary : Colors.transparent, width: 2)),
                child: Text(e.value['e']!, style: TextStyle(fontSize: sel ? 28 : 24))),
              const SizedBox(height: 4),
              Text(e.value['l']!, style: GoogleFonts.nunito(fontSize: 9, color: sel ? LunaTheme.primary : LunaTheme.text3, fontWeight: FontWeight.w700)),
            ]),
          );
        }).toList()),
      ]),
    );
  }
}

// ── Insights Card ─────────────────────────────────────────────────────────────
class _InsightsCard extends StatelessWidget {
  final AppState state;
  const _InsightsCard({required this.state});
  @override
  Widget build(BuildContext context) {
    final insights = state.insights;
    if (insights.isEmpty) return const SizedBox.shrink();
    final top = insights.first;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [LunaTheme.secondary.withOpacity(.15), LunaTheme.primary.withOpacity(.08)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LunaTheme.primary.withOpacity(.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(top.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(child: Text(top.title, style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text, fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: LunaTheme.primary.withOpacity(.12), borderRadius: BorderRadius.circular(8)),
            child: Text(top.type == InsightType.personal ? '✨ Personal' : '🔬 Science', style: GoogleFonts.nunito(fontSize: 10, color: LunaTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(top.body, style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 13, height: 1.5)),
        if (top.source != null) ...[
          const SizedBox(height: 6),
          Text('📚 ${top.source}', style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ]),
    );
  }
}

// ── Tip Card ──────────────────────────────────────────────────────────────────
class _TipCard extends StatelessWidget {
  final AppState state;
  const _TipCard({required this.state});
  static const _tipDetails = {
    CyclePhase.menstrual: {'icon':'🥬','title':'Iron & Vitamin C','label':'Nutrition','labelColor':0xFF81C784,'body':'During menstruation, the body loses iron. Consume iron-rich foods (spinach, lentils, meat) paired with vitamin C for optimal absorption.','source':'Mayo Clinic'},
    CyclePhase.follicular: {'icon':'⚡','title':'Peak energy phase','label':'Fitness','labelColor':0xFF7986CB,'body':'Rising estrogen boosts your energy and strength. Best week for high-intensity workouts and new challenges.','source':'ACOG'},
    CyclePhase.ovulation: {'icon':'🌸','title':'Fertility window','label':'Health','labelColor':0xFFE6C14F,'body':'You are at your most fertile. LH surge triggers ovulation 24–36 hours before egg release.','source':'ACOG'},
    CyclePhase.luteal: {'icon':'🥛','title':'Calcium reduces PMS','label':'Nutrition','labelColor':0xFF81C784,'body':'1200mg calcium daily reduces PMS symptoms — mood swings, bloating, irritability — by up to 48% over two months.','source':'NCBI Study'},
    CyclePhase.unknown: {'icon':'💜','title':'Track your cycle','label':'Getting started','labelColor':0xFFE8A4B8,'body':'Log your period start date to unlock personalized tips and predictions for your unique cycle.','source':'Luna'},
  };
  @override
  Widget build(BuildContext context) {
    final t = _tipDetails[state.currentPhase] ?? _tipDetails[CyclePhase.unknown]!;
    final labelColor = Color(t['labelColor'] as int);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(t['icon'] as String, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t['title'] as String, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: LunaTheme.text)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: labelColor.withOpacity(.2), borderRadius: BorderRadius.circular(6)),
              child: Text(t['label'] as String, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: labelColor))),
          ]),
        ]),
        const SizedBox(height: 10),
        Text(t['body'] as String, style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 13, height: 1.5)),
        const SizedBox(height: 8),
        Text('📚 ${t['source']}', style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final AppState state;
  const _StatsRow({required this.state});
  @override
  Widget build(BuildContext context) {
    final nextPeriod = state.nextPeriod;
    final cycleDay = state.currentCycleDay;
    final children = <Widget>[];
    if (cycleDay > 0) children.add(Expanded(child: _StatCard('📅', '$cycleDay', 'period day', 'of ${state.smartPeriodLength}', LunaTheme.menstrual)));
    if (nextPeriod != null) {
      final days = nextPeriod.difference(DateTime.now()).inDays;
      if (children.isNotEmpty) children.add(const SizedBox(width: 10));
      children.add(Expanded(child: _StatCard('🌹', '$days', 'days', 'next period', LunaTheme.secondary)));
    }
    if (state.nextOvulation != null) {
      final days = state.nextOvulation!.difference(DateTime.now()).inDays;
      if (days >= 0 && days <= 7) {
        if (children.isNotEmpty) children.add(const SizedBox(width: 10));
        children.add(Expanded(child: _StatCard('🌸', '$days', 'days', 'ovulation', LunaTheme.ovulation)));
      }
    }
    if (children.isEmpty) return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: LunaTheme.surfaceV, borderRadius: BorderRadius.circular(16)),
      child: Center(child: Text('🩸 Log your first period to see predictions', style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 12))),
    );
    return Row(children: children);
  }
}

class _StatCard extends StatelessWidget {
  final String icon, value, unit, label; final Color color;
  const _StatCard(this.icon, this.value, this.unit, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: LunaTheme.surfaceV, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      Text(icon, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 6),
      Text(value, style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: color, fontSize: 22)),
      Text(unit, style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 11, fontWeight: FontWeight.w600)),
      Text(label, style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 10)),
    ]),
  );
}
