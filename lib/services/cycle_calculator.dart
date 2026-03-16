import '../models/models.dart';

class CycleCalculator {

  // ── Smart predictions from history ──────────────────────────────────────────

  /// Average cycle length from past cycles (uses stored cycleLength field)
  static int avgCycleLength(List<CycleEntry> cycles, int fallback) {
    final withLength = cycles.where((c) => c.cycleLength > 10).toList();
    if (withLength.isEmpty) return fallback;
    final lengths = withLength.map((c) => c.cycleLength).toList();
    return (lengths.reduce((a, b) => a + b) / lengths.length).round();
  }

  /// Average period length from past cycles (uses periodLength field or endDate-startDate)
  static int avgPeriodLength(List<CycleEntry> cycles, int fallback) {
    final completed = cycles.where((c) => c.endDate != null).toList();
    if (completed.isEmpty) return fallback;
    final lengths = completed.map((c) {
      // Use periodLength field if sensible, otherwise compute from dates
      if (c.periodLength > 0 && c.periodLength <= 14) return c.periodLength;
      return c.endDate!.difference(c.startDate).inDays.clamp(1, 14);
    }).toList();
    return (lengths.reduce((a, b) => a + b) / lengths.length).round();
  }

  /// Predict next 3 periods using smart average
  static List<DateTime> predictNextPeriods(List<CycleEntry> cycles, int userCycleLength) {
    if (cycles.isEmpty) return [];
    final avgLen = avgCycleLength(cycles, userCycleLength);
    final lastStart = cycles.first.startDate;
    return List.generate(3, (i) => lastStart.add(Duration(days: avgLen * (i + 1))));
  }

  /// Cycle variability (standard deviation)
  static double cycleVariability(List<CycleEntry> cycles) {
    final completed = cycles.where((c) => c.endDate != null).toList();
    if (completed.length < 2) return 0;
    final lengths = completed.map((c) => c.endDate!.difference(c.startDate).inDays.toDouble()).toList();
    final avg = lengths.reduce((a, b) => a + b) / lengths.length;
    final variance = lengths.map((l) => (l - avg) * (l - avg)).reduce((a, b) => a + b) / lengths.length;
    return variance > 0 ? variance : 0;
  }

  static bool isCycleRegular(List<CycleEntry> cycles) => cycleVariability(cycles) < 16; // <4 day std dev

  // ── Phase logic ──────────────────────────────────────────────────────────────

  static CyclePhase getPhaseForDay(int cycleDay, int cycleLength, int periodLength) {
    if (cycleDay <= 0) return CyclePhase.unknown;
    final ovulationDay = cycleLength - 14;
    if (cycleDay <= periodLength) return CyclePhase.menstrual;
    if (cycleDay < ovulationDay - 1) return CyclePhase.follicular;
    if (cycleDay >= ovulationDay - 1 && cycleDay <= ovulationDay + 1) return CyclePhase.ovulation;
    return CyclePhase.luteal;
  }

  static int getCycleDay(DateTime cycleStart, DateTime date) {
    return date.difference(cycleStart).inDays + 1;
  }

  static DateTime? predictNextPeriod(CycleEntry? c) {
    if (c == null) return null;
    return c.startDate.add(Duration(days: c.cycleLength));
  }

  static DateTime? predictNextPeriodSmart(List<CycleEntry> cycles, int fallbackLength) {
    if (cycles.isEmpty) return null;
    final avg = avgCycleLength(cycles, fallbackLength);
    return cycles.first.startDate.add(Duration(days: avg));
  }

  static DateTime? predictOvulation(CycleEntry? c) {
    if (c == null) return null;
    return c.startDate.add(Duration(days: c.cycleLength - 14 - 1));
  }

  static DateTime? predictOvulationSmart(List<CycleEntry> cycles, int fallbackLength) {
    if (cycles.isEmpty) return null;
    final avg = avgCycleLength(cycles, fallbackLength);
    return cycles.first.startDate.add(Duration(days: avg - 15));
  }

  static List<DateTime> fertileWindow(CycleEntry? c) {
    if (c == null) return [];
    final ov = predictOvulation(c)!;
    return List.generate(6, (i) => ov.subtract(Duration(days: 5 - i)));
  }

  static List<DateTime> fertileWindowSmart(List<CycleEntry> cycles, int fallbackLength) {
    if (cycles.isEmpty) return [];
    final ov = predictOvulationSmart(cycles, fallbackLength);
    if (ov == null) return [];
    return List.generate(6, (i) => ov.subtract(Duration(days: 5 - i)));
  }

  // ── Upcoming events (used for notifications & home display) ─────────────────

  static List<UpcomingEvent> getUpcomingEvents(List<CycleEntry> cycles, int cycleLen, int periodLen) {
    final events = <UpcomingEvent>[];
    if (cycles.isEmpty) return events;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final nextPeriod = predictNextPeriodSmart(cycles, cycleLen);
    final nextOv = predictOvulationSmart(cycles, cycleLen);
    final fertile = fertileWindowSmart(cycles, cycleLen);

    if (nextPeriod != null) {
      final daysUntil = nextPeriod.difference(today).inDays;
      if (daysUntil >= 0 && daysUntil <= 14) {
        events.add(UpcomingEvent(
          date: nextPeriod, daysUntil: daysUntil,
          type: EventType.period,
          title: daysUntil == 0 ? 'Period expected today' : daysUntil == 1 ? 'Period expected tomorrow' : 'Period in $daysUntil days',
          subtitle: 'Based on your ${cycles.length} logged cycles',
          emoji: '🩸',
        ));
      }
    }

    if (nextOv != null) {
      final daysUntil = nextOv.difference(today).inDays;
      if (daysUntil >= 0 && daysUntil <= 7) {
        events.add(UpcomingEvent(
          date: nextOv, daysUntil: daysUntil,
          type: EventType.ovulation,
          title: daysUntil == 0 ? 'Ovulation likely today' : daysUntil == 1 ? 'Ovulation tomorrow' : 'Ovulation in $daysUntil days',
          subtitle: 'Peak fertility window opening',
          emoji: '🌸',
        ));
      }
    }

    // Fertile window start
    if (fertile.isNotEmpty) {
      final fertileStart = fertile.first;
      final daysUntil = fertileStart.difference(today).inDays;
      if (daysUntil >= 1 && daysUntil <= 5) {
        events.add(UpcomingEvent(
          date: fertileStart, daysUntil: daysUntil,
          type: EventType.fertile,
          title: 'Fertile window in $daysUntil days',
          subtitle: 'Most fertile days approaching',
          emoji: '🌺',
        ));
      }
    }

    events.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    return events;
  }

  // ── Phase description ────────────────────────────────────────────────────────

  static String phaseDescription(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual: return 'Your body is shedding the uterine lining. Rest, stay hydrated, and be gentle with yourself. 💗';
      case CyclePhase.follicular: return 'Estrogen is rising — energy increases. Great time for new projects and strength training.';
      case CyclePhase.ovulation: return 'Peak fertility window. You may feel more confident, social and energetic today.';
      case CyclePhase.luteal: return 'Progesterone rises then drops. You may feel more introspective. Prioritise self-care.';
      case CyclePhase.unknown: return 'Log your period start date to unlock phase predictions.';
    }
  }

  static int calcStreak(List<PillLog> logs) {
    if (logs.isEmpty) return 0;
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < 90; i++) {
      final dStr = today.subtract(Duration(days: i)).toIso8601String().split('T')[0];
      final match = logs.where((l) => l.date.toIso8601String().split('T')[0] == dStr);
      if (match.isNotEmpty && match.first.taken) { streak++; }
      else if (i > 0) { break; }
    }
    return streak;
  }

  static double calcAdherence(List<PillLog> logs, int days) {
    if (logs.isEmpty) return 0;
    return (logs.where((l) => l.taken).length / days * 100).clamp(0, 100);
  }
}

enum EventType { period, ovulation, fertile, medical, reminder }

class UpcomingEvent {
  final DateTime date;
  final int daysUntil;
  final EventType type;
  final String title, subtitle, emoji;
  UpcomingEvent({required this.date, required this.daysUntil, required this.type, required this.title, required this.subtitle, required this.emoji});
}
