class CycleEntry {
  final int? id;
  final DateTime startDate;
  final DateTime? endDate;
  final int cycleLength;
  final int periodLength;

  CycleEntry({this.id, required this.startDate, this.endDate, this.cycleLength = 28, this.periodLength = 5});

  Map<String, dynamic> toMap() => {
    'id': id, 'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'cycleLength': cycleLength, 'periodLength': periodLength,
  };

  factory CycleEntry.fromMap(Map<String, dynamic> m) => CycleEntry(
    id: m['id'], startDate: DateTime.parse(m['startDate']),
    endDate: m['endDate'] != null ? DateTime.parse(m['endDate']) : null,
    cycleLength: m['cycleLength'] ?? 28, periodLength: m['periodLength'] ?? 5,
  );
}

class DayLog {
  final int? id;
  final DateTime date;
  final int? mood;
  final int? energy;
  final int? pain;
  final double? basalTemp;
  final List<String> symptoms;
  final String? notes;

  DayLog({this.id, required this.date, this.mood, this.energy, this.pain, this.basalTemp, this.symptoms = const [], this.notes});

  Map<String, dynamic> toMap() => {
    'id': id, 'date': date.toIso8601String().split('T')[0],
    'mood': mood, 'energy': energy, 'pain': pain,
    'basalTemp': basalTemp, 'symptoms': symptoms.join(','), 'notes': notes,
  };

  factory DayLog.fromMap(Map<String, dynamic> m) => DayLog(
    id: m['id'], date: DateTime.parse(m['date']),
    mood: m['mood'], energy: m['energy'], pain: m['pain'],
    basalTemp: m['basalTemp']?.toDouble(),
    symptoms: m['symptoms'] != null && (m['symptoms'] as String).isNotEmpty
        ? (m['symptoms'] as String).split(',') : [],
    notes: m['notes'],
  );
}

class JournalEntry {
  final int? id;
  final DateTime date;
  final String title;
  final String content;
  final int? mood;
  final List<String> activities;

  JournalEntry({this.id, required this.date, required this.title, required this.content, this.mood, this.activities = const []});

  Map<String, dynamic> toMap() => {
    'id': id, 'date': date.toIso8601String(), 'title': title,
    'content': content, 'mood': mood, 'activities': activities.join(','),
  };

  factory JournalEntry.fromMap(Map<String, dynamic> m) => JournalEntry(
    id: m['id'], date: DateTime.parse(m['date']),
    title: m['title'] ?? '', content: m['content'] ?? '', mood: m['mood'],
    activities: m['activities'] != null && (m['activities'] as String).isNotEmpty
        ? (m['activities'] as String).split(',') : [],
  );
}

class ContraceptiveBrand {
  final int? id;
  final String name;
  final String type;
  final DateTime startDate;
  final DateTime? endDate;
  final int rating;
  final String notes;

  ContraceptiveBrand({this.id, required this.name, required this.type, required this.startDate, this.endDate, this.rating = 3, this.notes = ''});

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'type': type,
    'startDate': startDate.toIso8601String().split('T')[0],
    'endDate': endDate?.toIso8601String().split('T')[0],
    'rating': rating, 'notes': notes,
  };

  factory ContraceptiveBrand.fromMap(Map<String, dynamic> m) => ContraceptiveBrand(
    id: m['id'], name: m['name'] ?? '', type: m['type'] ?? 'Combined pill',
    startDate: DateTime.parse(m['startDate']),
    endDate: m['endDate'] != null ? DateTime.parse(m['endDate']) : null,
    rating: m['rating'] ?? 3, notes: m['notes'] ?? '',
  );
}

class PillLog {
  final int? id;
  final DateTime date;
  final bool taken;
  final String? time;

  PillLog({this.id, required this.date, required this.taken, this.time});

  Map<String, dynamic> toMap() => {
    'id': id, 'date': date.toIso8601String().split('T')[0],
    'taken': taken ? 1 : 0, 'time': time,
  };

  factory PillLog.fromMap(Map<String, dynamic> m) => PillLog(
    id: m['id'], date: DateTime.parse(m['date']),
    taken: m['taken'] == 1, time: m['time'],
  );
}

enum CyclePhase { menstrual, follicular, ovulation, luteal, unknown }

extension CyclePhaseExt on CyclePhase {
  String get label {
    switch (this) {
      case CyclePhase.menstrual: return 'Menstrual phase';
      case CyclePhase.follicular: return 'Follicular phase';
      case CyclePhase.ovulation: return 'Ovulation';
      case CyclePhase.luteal: return 'Luteal phase';
      case CyclePhase.unknown: return 'Unknown';
    }
  }
  String get emoji {
    switch (this) {
      case CyclePhase.menstrual: return '🌹';
      case CyclePhase.follicular: return '🌱';
      case CyclePhase.ovulation: return '🌸';
      case CyclePhase.luteal: return '🌙';
      case CyclePhase.unknown: return '🔮';
    }
  }
}

extension ContraceptiveBrandExt on ContraceptiveBrand {
  ContraceptiveBrand copyWith({DateTime? endDate}) => ContraceptiveBrand(
    id: id, name: name, type: type, startDate: startDate,
    endDate: endDate ?? this.endDate, rating: rating, notes: notes,
  );
}

// ── Medical Records ──────────────────────────────────────────────────────────

class MedicalRecord {
  final int? id;
  final DateTime date;
  final String type;      // checkup, test, ultrasound, etc
  final String title;
  final String? notes;
  final String? result;   // normal, abnormal, pending
  final DateTime? nextDue;

  MedicalRecord({this.id, required this.date, required this.type, required this.title, this.notes, this.result, this.nextDue});

  Map<String, dynamic> toMap() => {
    'id': id, 'date': date.toIso8601String().split('T')[0], 'type': type,
    'title': title, 'notes': notes, 'result': result,
    'nextDue': nextDue?.toIso8601String().split('T')[0],
  };

  factory MedicalRecord.fromMap(Map<String, dynamic> m) => MedicalRecord(
    id: m['id'], date: DateTime.parse(m['date']), type: m['type'] ?? 'checkup',
    title: m['title'] ?? '', notes: m['notes'], result: m['result'],
    nextDue: m['nextDue'] != null ? DateTime.parse(m['nextDue']) : null,
  );
}

// ── Reminders ────────────────────────────────────────────────────────────────

class AppReminder {
  final int? id;
  final String title;
  final String type;    // daily, weekly, cycle_relative, one_time
  final String time;    // HH:mm
  final bool enabled;
  final String? note;
  final DateTime? nextDue;

  AppReminder({this.id, required this.title, required this.type, required this.time, this.enabled = true, this.note, this.nextDue});

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'type': type, 'time': time,
    'enabled': enabled ? 1 : 0, 'note': note,
    'nextDue': nextDue?.toIso8601String().split('T')[0],
  };

  factory AppReminder.fromMap(Map<String, dynamic> m) => AppReminder(
    id: m['id'], title: m['title'] ?? '', type: m['type'] ?? 'daily',
    time: m['time'] ?? '08:00', enabled: (m['enabled'] ?? 1) == 1,
    note: m['note'], nextDue: m['nextDue'] != null ? DateTime.parse(m['nextDue']) : null,
  );
}
