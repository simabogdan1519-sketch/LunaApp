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

  // ── Core logic: which cycle does a day belong to? ─────────────────────────
  // Returns (cycleEntry, cycleDay) or null if day is outside all cycles.
  // Uses endDate when available, otherwise startDate + cycleLength.
  // Never bleeds into adjacent cycles.
  static _CycleMatch? _matchCycle(List<CycleEntry> cycles, DateTime day,
      int smartCycleLen, int smartPeriodLen) {
    // Normalise to date-only for comparison
    final d = DateTime(day.year, day.month, day.day);

    for (final cycle in cycles) {
      final start = DateTime(
          cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);

      // Determine the *exclusive* end of this cycle:
      // If endDate exists → use it (period ended on that day, but cycle spans
      //   until the next period = start + cycleLength stored or smart avg).
      // We keep this simple: a cycle "owns" days from start (inclusive) to
      // start + cycleLen (exclusive), where cycleLen = endDate-startDate is
      // the PERIOD length; the full cycle length is separate.
      // Actually the correct model: cycleLength field stores the full cycle
      // length (e.g. 28). Period ends at endDate. So this cycle owns:
      //   [startDate, startDate + cycleLength)
      // cycleLength must be a realistic full cycle (>10 days) to be trusted
      final cycleLen = (cycle.cycleLength >= 10 && cycle.cycleLength <= 60)
          ? cycle.cycleLength
          : smartCycleLen;

      // periodLength: use stored value if sensible, else endDate-startDate, else smart
      int actualPeriodLen;
      if (cycle.endDate != null) {
        final fromDates = cycle.endDate!.difference(cycle.startDate).inDays.clamp(1, 14);
        actualPeriodLen = (cycle.periodLength >= 1 && cycle.periodLength <= 14)
            ? cycle.periodLength
            : fromDates;
      } else {
        actualPeriodLen = (cycle.periodLength >= 1 && cycle.periodLength <= 14)
            ? cycle.periodLength
            : smartPeriodLen;
      }

      final cycleEnd = start.add(Duration(days: cycleLen));

      if (!d.isBefore(start) && d.isBefore(cycleEnd)) {
        final cycleDay = d.difference(start).inDays + 1;
        return _CycleMatch(
          cycle: cycle,
          cycleDay: cycleDay,
          cycleLen: cycleLen,
          periodLen: actualPeriodLen,
          predicted: false,
        );
      }
    }
    return null;
  }

  static _CycleMatch? _matchPredicted(List<DateTime> futurePeriods,
      DateTime day, int smartCycleLen, int smartPeriodLen) {
    final d = DateTime(day.year, day.month, day.day);
    for (final start in futurePeriods) {
      final s = DateTime(start.year, start.month, start.day);
      final end = s.add(Duration(days: smartCycleLen));
      if (!d.isBefore(s) && d.isBefore(end)) {
        final cycleDay = d.difference(s).inDays + 1;
        return _CycleMatch(
          cycle: null,
          cycleDay: cycleDay,
          cycleLen: smartCycleLen,
          periodLen: smartPeriodLen,
          predicted: true,
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: LunaTheme.surface,
      appBar: AppBar(
        title: Text('📅 Calendar',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900, color: LunaTheme.text)),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2018, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focused,
            selectedDayPredicate: (d) => isSameDay(d, _selected),
            onDaySelected: (s, f) =>
                setState(() { _selected = s; _focused = f; }),
            onPageChanged: (f) => setState(() { _focused = f; }),
            calendarBuilders: CalendarBuilders(
              defaultBuilder:  (ctx, day, _) => _buildDay(state, day, false),
              todayBuilder:    (ctx, day, _) => _buildDay(state, day, true),
              selectedBuilder: (ctx, day, _) =>
                  _buildDay(state, day, false, selected: true),
              outsideBuilder:  (ctx, day, _) =>
                  _buildDay(state, day, false, outside: true),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(Icons.chevron_left_rounded,
                  color: LunaTheme.primary),
              rightChevronIcon: Icon(Icons.chevron_right_rounded,
                  color: LunaTheme.primary),
              titleTextStyle: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: LunaTheme.text),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: true,
              outsideTextStyle:
                  GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 12),
              weekendTextStyle: GoogleFonts.nunito(color: LunaTheme.text),
              defaultTextStyle: GoogleFonts.nunito(color: LunaTheme.text),
            ),
          ),
          _CalendarLegend(),
          if (_selected != null) ...[
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [
                  _DayDetail(
                    state: state,
                    day: _selected!,
                    onDeleteCycle: (id) async {
                      await context.read<AppState>().deleteCycle(id);
                      setState(() => _selected = null);
                    },
                  ),
                  _DayLogSummary(state: state, day: _selected!),
                ]),
              ),
            ),
          ] else ...[
            const Divider(height: 1),
            _UpcomingEventsPanel(state: state),
          ],
        ],
      ),
    );
  }

  Widget _buildDay(AppState state, DateTime day, bool isToday,
      {bool selected = false, bool outside = false}) {
    final match = _matchCycle(state.cycles, day,
            state.smartCycleLength, state.smartPeriodLength) ??
        _matchPredicted(state.nextThreePeriods, day,
            state.smartCycleLength, state.smartPeriodLength);

    Color? phaseColor;
    bool isPeriod = false;

    if (match != null) {
      final phase = CycleCalculator.getPhaseForDay(
          match.cycleDay, match.cycleLen, match.periodLen);
      phaseColor = LunaTheme.phaseColor(phase.name);
      if (match.predicted) phaseColor = phaseColor.withOpacity(.55);
      isPeriod = match.cycleDay <= match.periodLen;
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected
              ? LunaTheme.primary
              : phaseColor != null
                  ? phaseColor.withOpacity(outside ? .06 : .18)
                  : Colors.transparent,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: LunaTheme.primary, width: 2)
              : null,
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
                  fontWeight:
                      isToday || selected ? FontWeight.w900 : FontWeight.w600,
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

// ── Simple data class ─────────────────────────────────────────────────────────
class _CycleMatch {
  final CycleEntry? cycle;
  final int cycleDay, cycleLen, periodLen;
  final bool predicted;
  const _CycleMatch({
    required this.cycle,
    required this.cycleDay,
    required this.cycleLen,
    required this.periodLen,
    required this.predicted,
  });
}

// ── Day detail panel ──────────────────────────────────────────────────────────
class _DayDetail extends StatelessWidget {
  final AppState state;
  final DateTime day;
  final ValueChanged<int> onDeleteCycle;

  const _DayDetail({
    required this.state,
    required this.day,
    required this.onDeleteCycle,
  });

  @override
  Widget build(BuildContext context) {
    final match =
        _CalendarScreenState._matchCycle(state.cycles, day,
                state.smartCycleLength, state.smartPeriodLength) ??
            _CalendarScreenState._matchPredicted(state.nextThreePeriods, day,
                state.smartCycleLength, state.smartPeriodLength);

    if (match == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text('No cycle data for this day.',
            style: GoogleFonts.nunito(color: LunaTheme.text3)),
      );
    }

    final phase = CycleCalculator.getPhaseForDay(
        match.cycleDay, match.cycleLen, match.periodLen);
    final fmt = DateFormat('EEEE, MMMM d');
    final fmtShort = DateFormat('MMM d, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Date header
        Text(fmt.format(day),
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: LunaTheme.text)),
        const SizedBox(height: 6),

        // Predicted badge
        if (match.predicted)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: LunaTheme.primary.withOpacity(.12),
                borderRadius: BorderRadius.circular(8)),
            child: Text('🔮 Predicted',
                style: GoogleFonts.nunito(
                    color: LunaTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),

        // Cycle day
        Text('Cycle day ${match.cycleDay} of ${match.cycleLen}',
            style:
                GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 13)),
        const SizedBox(height: 4),

        // Phase
        Text('${phase.emoji} ${phase.label}',
            style: GoogleFonts.nunito(
                color: LunaTheme.phaseColor(phase.name),
                fontWeight: FontWeight.w700,
                fontSize: 15)),
        const SizedBox(height: 6),
        Text(CycleCalculator.phaseDescription(phase),
            style: GoogleFonts.nunito(
                color: LunaTheme.text2, fontSize: 13, height: 1.6)),

        // Cycle info + delete (only for real cycles, not predicted)
        if (!match.predicted && match.cycle != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cycle started',
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: LunaTheme.text3)),
                      Text(fmtShort.format(match.cycle!.startDate),
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800,
                              color: LunaTheme.text)),
                      if (match.cycle!.endDate != null) ...[
                        const SizedBox(height: 4),
                        Text('Period ended',
                            style: GoogleFonts.nunito(
                                fontSize: 11, color: LunaTheme.text3)),
                        Text(fmtShort.format(match.cycle!.endDate!),
                            style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w800,
                                color: LunaTheme.text)),
                      ],
                    ]),
              ),
              // Delete this cycle
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: Colors.red[300]),
                onPressed: () => _confirmDelete(context, match.cycle!),
                tooltip: 'Delete this cycle',
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  void _confirmDelete(BuildContext context, CycleEntry cycle) async {
    final fmt = DateFormat('MMM d, yyyy');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete cycle?',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(
            'Cycle starting ${fmt.format(cycle.startDate)} will be permanently deleted.',
            style: GoogleFonts.nunito()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete',
                  style: TextStyle(color: Colors.red[400]))),
        ],
      ),
    );
    if (confirm == true) onDeleteCycle(cycle.id!);
  }
}

// ── Legend ────────────────────────────────────────────────────────────────────
class _CalendarLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          _LegItem(color: LunaTheme.menstrual, label: '🩸 Period'),
          _LegItem(color: LunaTheme.follicular, label: '🌱 Follicular'),
          _LegItem(color: LunaTheme.ovulation, label: '🌸 Ovulation'),
          _LegItem(color: LunaTheme.luteal, label: '🌙 Luteal'),
          _LegItem(
              color: LunaTheme.primary.withOpacity(.4),
              label: '🔮 Predicted'),
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
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 9,
            height: 9,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 11,
                color: LunaTheme.text2,
                fontWeight: FontWeight.w600)),
      ]);
}

// ── Day log summary panel ─────────────────────────────────────────────────────
class _DayLogSummary extends StatelessWidget {
  final AppState state;
  final DateTime day;
  const _DayLogSummary({required this.state, required this.day});

  @override
  Widget build(BuildContext context) {
    // Find log for this day
    DayLog? log;
    try {
      log = state.allDayLogs.firstWhere((l) =>
          l.date.year == day.year && l.date.month == day.month && l.date.day == day.day);
    } catch (_) {}

    if (log == null) return const SizedBox.shrink();

    final moodEmojis = ['', '😣','😔','😐','😊','🥰'];
    final moodLabels = ['', 'Terrible','Bad','Ok','Good','Great'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LunaTheme.primary.withOpacity(.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LunaTheme.primary.withOpacity(.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📋 Daily Log', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 13)),
        const SizedBox(height: 10),
        Row(children: [
          if (log.mood != null) ...[
            Text(moodEmojis[log.mood!], style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(moodLabels[log.mood!], style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: LunaTheme.text, fontSize: 13)),
            const SizedBox(width: 16),
          ],
          if (log.energy != null) ...[
            Text('⚡', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text('${log.energy}/5', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: LunaTheme.text, fontSize: 13)),
            const SizedBox(width: 16),
          ],
          if (log.pain != null) ...[
            Text('🤕', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text('${log.pain}/5', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: LunaTheme.text, fontSize: 13)),
          ],
        ]),
        if (log.symptoms.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 4,
            children: log.symptoms.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: LunaTheme.primary.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
              child: Text(s, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: LunaTheme.primary)),
            )).toList(),
          ),
        ],
        if (log.notes != null && log.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(log.notes!, style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 12, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ]),
    );
  }
}

// ── Upcoming events panel (shown when no day is selected) ─────────────────────
class _UpcomingEventsPanel extends StatelessWidget {
  final AppState state;
  const _UpcomingEventsPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final next = state.nextThreePeriods;
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🔮 Upcoming', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text, fontSize: 15)),
        const SizedBox(height: 10),
        if (next.isEmpty)
          Text('Add cycles to see predictions', style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 13))
        else
          ...next.take(3).map((p) {
            final daysUntil = p.startDate.difference(DateTime(now.year, now.month, now.day)).inDays;
            final label = daysUntil == 0 ? 'Today'
                : daysUntil == 1 ? 'Tomorrow'
                : 'In $daysUntil days';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: LunaTheme.menstrual.withOpacity(.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LunaTheme.menstrual.withOpacity(.2)),
              ),
              child: Row(children: [
                Text('🩸', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Period expected', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 13)),
                  Text(DateFormat('MMMM d, yyyy').format(p.startDate),
                      style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 12)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: LunaTheme.menstrual.withOpacity(.15), borderRadius: BorderRadius.circular(10)),
                  child: Text(label, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.menstrual, fontSize: 11)),
                ),
              ]),
            );
          }),
        const SizedBox(height: 12),
        // Ovulation prediction
        if (state.nextOvulation != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: LunaTheme.ovulation.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LunaTheme.ovulation.withOpacity(.2)),
            ),
            child: Row(children: [
              Text('🌸', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Ovulation window', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 13)),
                Text(DateFormat('MMMM d, yyyy').format(state.nextOvulation!),
                    style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 12)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: LunaTheme.ovulation.withOpacity(.15), borderRadius: BorderRadius.circular(10)),
                child: Text('Fertile', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.ovulation, fontSize: 11)),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}
