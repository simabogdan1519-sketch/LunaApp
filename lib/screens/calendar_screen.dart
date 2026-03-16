import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../services/cycle_calculator.dart';
import '../theme/luna_theme.dart';
import '../models/models.dart';

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
      appBar: AppBar(title: Text('📅 Calendar', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text))),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focused,
            selectedDayPredicate: (d) => isSameDay(d, _selected),
            onDaySelected: (s, f) => setState(() { _selected = s; _focused = f; }),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (ctx, day, _) => _buildDay(state, day, false),
              todayBuilder: (ctx, day, _) => _buildDay(state, day, true),
              selectedBuilder: (ctx, day, _) => _buildDay(state, day, false, selected: true),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false, titleCentered: true,
              titleTextStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16, color: LunaTheme.text),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
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

  Widget _buildDay(AppState state, DateTime day, bool isToday, {bool selected = false}) {
    if (state.currentCycle == null) {
      return Center(
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isToday ? LunaTheme.primary.withOpacity(.2) : selected ? LunaTheme.primary : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(child: Text('${day.day}', style: GoogleFonts.nunito(color: selected ? Colors.white : LunaTheme.text, fontWeight: isToday ? FontWeight.w900 : FontWeight.w600))),
        ),
      );
    }
    final cycleDay = CycleCalculator.getCycleDay(state.currentCycle!.startDate, day);
    final phase = CycleCalculator.getPhaseForDay(cycleDay, state.cycleLength, state.periodLength);
    final phaseColor = LunaTheme.phaseColor(phase.name);
    final isPeriod = cycleDay > 0 && cycleDay <= state.periodLength;
    final inCycle = cycleDay > 0 && cycleDay <= state.cycleLength;

    return Center(
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: selected ? LunaTheme.primary : inCycle ? phaseColor.withOpacity(.2) : Colors.transparent,
          shape: BoxShape.circle,
          border: isToday ? Border.all(color: LunaTheme.primary, width: 2) : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (inCycle && cycleDay <= state.cycleLength)
                Text(isPeriod ? '🩸' : '', style: const TextStyle(fontSize: 8)),
              Text('${day.day}', style: GoogleFonts.nunito(color: selected ? Colors.white : inCycle ? phaseColor : LunaTheme.text, fontWeight: FontWeight.w700, fontSize: 12)),
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
    if (state.currentCycle == null) return Center(child: Text('No cycle data', style: GoogleFonts.nunito(color: LunaTheme.text2)));
    final cycleDay = CycleCalculator.getCycleDay(state.currentCycle!.startDate, day);
    final phase = CycleCalculator.getPhaseForDay(cycleDay, state.cycleLength, state.periodLength);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('EEEE, MMM d').format(day), style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16, color: LunaTheme.text)),
          const SizedBox(height: 8),
          if (cycleDay > 0 && cycleDay <= state.cycleLength) ...[
            Text('🩸 Cycle day $cycleDay of ${state.cycleLength}', style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 13)),
            const SizedBox(height: 4),
            Text('${phase.emoji} ${phase.label}', style: GoogleFonts.nunito(color: LunaTheme.phaseColor(phase.name), fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(CycleCalculator.phaseDescription(phase), style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 12, height: 1.5)),
          ] else
            Text('Outside current cycle', style: GoogleFonts.nunito(color: LunaTheme.text3)),
        ],
      ),
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
          _LegItem(color: LunaTheme.menstrual, label: '🩸 Period'),
          _LegItem(color: LunaTheme.follicular, label: '🌱 Follicular'),
          _LegItem(color: LunaTheme.ovulation, label: '🌸 Ovulation'),
          _LegItem(color: LunaTheme.luteal, label: '🌙 Luteal'),
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
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.nunito(fontSize: 11, color: LunaTheme.text2, fontWeight: FontWeight.w600)),
    ]);
  }
}
