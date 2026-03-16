import '../models/models.dart';

class CycleCalculator {
  static CyclePhase getPhaseForDay(int cycleDay, int cycleLength, int periodLength) {
    if (cycleDay <= 0) return CyclePhase.unknown;
    final ovulationDay = cycleLength - 14;
    if (cycleDay <= periodLength) return CyclePhase.menstrual;
    if (cycleDay < ovulationDay) return CyclePhase.follicular;
    if (cycleDay == ovulationDay) return CyclePhase.ovulation;
    return CyclePhase.luteal;
  }

  static int getCycleDay(DateTime cycleStart, DateTime date) {
    return date.difference(cycleStart).inDays + 1;
  }

  static DateTime? predictNextPeriod(CycleEntry? c) {
    if (c == null) return null;
    return c.startDate.add(Duration(days: c.cycleLength));
  }

  static DateTime? predictOvulation(CycleEntry? c) {
    if (c == null) return null;
    return c.startDate.add(Duration(days: c.cycleLength - 14 - 1));
  }

  static List<DateTime> fertileWindow(CycleEntry? c) {
    if (c == null) return [];
    final ov = predictOvulation(c)!;
    return List.generate(6, (i) => ov.subtract(Duration(days: 5 - i)));
  }

  static String phaseDescription(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual: return 'Your body is shedding the uterine lining. Rest, stay hydrated, and be gentle with yourself.';
      case CyclePhase.follicular: return 'Estrogen is rising! Energy increases. Great time for new projects and workouts.';
      case CyclePhase.ovulation: return 'Peak fertility window. You may feel more confident and social today.';
      case CyclePhase.luteal: return 'Progesterone rises then drops. You may feel more introspective. Self-care is key.';
      case CyclePhase.unknown: return 'Log your period start date to see your phase predictions.';
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
