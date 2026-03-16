import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../services/cycle_calculator.dart';
import '../theme/luna_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: LunaTheme.surface,
      appBar: AppBar(
        title: Text('📅 Calendar', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text)),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2018, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focused,
            selectedDayPredicate: (d) => isSameDay(d, _selected),
            onDaySelected: (s, f) => setState(() { _selected = s; _focused = f; }),
            onPageChanged: (f) => setState(() { _focused = f; }),
            calendarBuilders: CalendarBuilders(
              defaultBuilder:  (ctx, day, _) => _buildDay(state, day, false),
              todayBuilder:    (ctx, day, _) => _buildDay(state, day, true),
              selectedBuilder: (ctx, day, _) => _buildDay(state, day, false, selected: true),
              outsideBuilder:  (ctx, day, _) => _buildDay(state, day, false, outside: true),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon:  Icon(Icons.chevron_left_rounded,  color: LunaTheme.primary),
              rightChevronIcon: Icon(Icons.chevron_right_rounded, color: LunaTheme.primary),
              titleTextStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16, color: LunaTheme.text),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: true,
              outsideTextStyle: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 12),
              weekendTextStyle: GoogleFonts.nunito(color: LunaTheme.text),
              defaultTextStyle: GoogleFonts.nunito(color: LunaTheme.text),
            ),
          ),
          _CalendarLegend(),
          if (_selected != null) ...[
            const Divider(height: 1),
            Expanded(child: _DayDetail(state: state, day: _selected!)),
          ],
        ],
      ),
    );
  }

  Widget _buildDay(AppState state, DateTime day, bool isToday, {bool selected = false, bool outside = false}) {
    // Find phase across ALL cycles, not just current
    Color? phaseColor;
    bool isPeriod = false;

    for (final cycle in state.cycles) {
      final cycleLen = cycle.cycleLength > 0 ? cycle.cycleLength : state.smartCycleLength;
      final periodLen = cycle.periodLength > 0 ? cycle.periodLength : state.smartPeriodLength;
      final cycleDay = CycleCalculator.getCycleDay(cycle.startDate, day);
      if (cycleDay > 0 && cycleDay <= cycleLen) {
        final phase = CycleCalculator.getPhaseForDay(cycleDay, cycleLen, periodLen);
        phaseColor = LunaTheme.phaseColor(phase.name);
        isPeriod = cycleDay <= periodLen;
        break;
      }
    }

    // Also predict future cycles
    if (phaseColor == null) {
      for (final future in state.nextThreePeriods) {
        final cycleDay = CycleCalculator.getCycleDay(future, day);
        if (cycleDay > 0 && cycleDay <= state.smartCycleLength) {
          final phase = CycleCalculator.getPhaseForDay(cycleDay, state.smartCycleLength, state.smartPeriodLength);
          phaseColor = LunaTheme.phaseColor(phase.name).withOpacity(.55);
          isPeriod = cycleDay <= state.smartPeriodLength;
          break;
        }
      }
    }

    final textColor = selected
        ? Colors.white
        : outside
            ? LunaTheme.text3
            : phaseColor != null
                ? phaseColor.withOpacity(1)
                : LunaTheme.text;

    return Center(
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: selected
              ? LunaTheme.primary
              : phaseColor != null
                  ? phaseColor.withOpacity(outside ? .08 : .18)
                  : Colors.transparent,
          shape: BoxShape.circle,
          border: isToday ? Border.all(color: LunaTheme.primary, width: 2) : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isPeriod && !outside)
                const Text('🩸', style: TextStyle(fontSize: 7, height: 1)),
              Text(
                '${day.day}',
                style: GoogleFonts.nunito(
                  color: textColor,
                  fontWeight: isToday || selected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayDetail extends StatelessWidget {
  final AppState state;
  final DateTime day;
  const _DayDetail({required this.state, required this.day});

  @override
  Widget build(BuildContext context) {
    // Find which cycle this day belongs to
    for (final cycle in state.cycles) {
      final cycleLen = cycle.cycleLength > 0 ? cycle.cycleLength : state.smartCycleLength;
      final periodLen = cycle.periodLength > 0 ? cycle.periodLength : state.smartPeriodLength;
      final cycleDay = CycleCalculator.getCycleDay(cycle.startDate, day);
      if (cycleDay > 0 && cycleDay <= cycleLen) {
        final phase = CycleCalculator.getPhaseForDay(cycleDay, cycleLen, periodLen);
        return _DetailCard(day: day, cycleDay: cycleDay, cycleLen: cycleLen, phase: phase, predicted: false);
      }
    }
    // Future prediction?
    for (final future in state.nextThreePeriods) {
      final cycleDay = CycleCalculator.getCycleDay(future, day);
      if (cycleDay > 0 && cycleDay <= state.smartCycleLength) {
        final phase = CycleCalculator.getPhaseForDay(cycleDay, state.smartCycleLength, state.smartPeriodLength);
        return _DetailCard(day: day, cycleDay: cycleDay, cycleLen: state.smartCycleLength, phase: phase, predicted: true);
      }
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text('No cycle data for this day.', style: GoogleFonts.nunito(color: LunaTheme.text3)),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final DateTime day;
  final int cycleDay, cycleLen;
  final dynamic phase;
  final bool predicted;
  const _DetailCard({required this.day, required this.cycleDay, required this.cycleLen, required this.phase, required this.predicted});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(DateFormat('EEEE, MMMM d').format(day),
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16, color: LunaTheme.text)),
        if (predicted)
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: LunaTheme.primary.withOpacity(.12), borderRadius: BorderRadius.circular(8)),
            child: Text('Predicted', style: GoogleFonts.nunito(color: LunaTheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: 8),
        Text('Cycle day $cycleDay of $cycleLen', style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 13)),
        const SizedBox(height: 4),
        Text('${phase.emoji} ${phase.label}',
            style: GoogleFonts.nunito(color: LunaTheme.phaseColor(phase.name), fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 6),
        Text(CycleCalculator.phaseDescription(phase),
            style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 13, height: 1.6)),
      ]),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Wrap(
        spacing: 14, runSpacing: 6,
        children: [
          _LegItem(color: LunaTheme.menstrual,  label: '🩸 Period'),
          _LegItem(color: LunaTheme.follicular, label: '🌱 Follicular'),
          _LegItem(color: LunaTheme.ovulation,  label: '🌸 Ovulation'),
          _LegItem(color: LunaTheme.luteal,     label: '🌙 Luteal'),
          _LegItem(color: LunaTheme.primary.withOpacity(.4), label: '🔮 Predicted'),
        ],
      ),
    );
  }
}

class _LegItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.nunito(fontSize: 11, color: LunaTheme.text2, fontWeight: FontWeight.w600)),
  ]);
}
