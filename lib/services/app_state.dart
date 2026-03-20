import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'notification_service.dart';
import 'database_service.dart';
import 'cycle_calculator.dart';
import 'insights_engine.dart';

class AppState extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  String _userName = '';
  int _cycleLength = 28;
  final _notif = NotificationService();
  int _periodLength = 5;
  String _language = 'English';
  String? _profilePhotoPath;
  String _timezone = 'Europe/Bucharest';
  String _companionEmoji = '🐱';
  String _companionName = 'Luna';
  bool _contraEnabled = false;
  String _pillReminderTime = '08:00';

  String get userName => _userName;
  int get cycleLength => _cycleLength;
  int get periodLength => _periodLength;
  String get language => _language;
  String? get profilePhotoPath => _profilePhotoPath;
  String get timezone => _timezone;
  String get companionEmoji => _companionEmoji;
  String get companionName => _companionName;
  bool get contraEnabled => _contraEnabled;
  String get pillReminderTime => _pillReminderTime;

  set userName(String v) { _userName = v; notifyListeners(); }
  set cycleLength(int v) { _cycleLength = v; notifyListeners(); }
  set periodLength(int v) { _periodLength = v; notifyListeners(); }
  set language(String v) { _language = v; notifyListeners(); }
  set profilePhotoPath(String? v) { _profilePhotoPath = v; notifyListeners(); }
  void setTimezone(String v) { _timezone = v; savePrefs(); notifyListeners(); _syncNotifications(); }
  set companionEmoji(String v) { _companionEmoji = v; notifyListeners(); }
  set companionName(String v) { _companionName = v; notifyListeners(); }
  set contraEnabled(bool v) { _contraEnabled = v; notifyListeners(); }
  set pillReminderTime(String v) { _pillReminderTime = v; notifyListeners(); }

  List<CycleEntry> cycles = [];
  List<DayLog> allDayLogs = [];
  List<JournalEntry> journalEntries = [];
  List<ContraceptiveBrand> contraBrands = [];
  List<PillLog> pillLogs = [];
  List<MedicalRecord> medicalRecords = [];
  List<AppReminder> reminders = [];
  DayLog? todayLog;

  // ── Smart computed properties ─────────────────────────────────────────────

  CycleEntry? get currentCycle => cycles.isNotEmpty ? cycles.first : null;

  int get smartCycleLength => CycleCalculator.avgCycleLength(cycles, _cycleLength);
  int get smartPeriodLength => CycleCalculator.avgPeriodLength(cycles, _periodLength);

  CyclePhase get currentPhase {
    if (currentCycle == null) return CyclePhase.unknown;
    final day = CycleCalculator.getCycleDay(currentCycle!.startDate, DateTime.now());
    return CycleCalculator.getPhaseForDay(day, smartCycleLength, smartPeriodLength);
  }

  int get currentCycleDay {
    if (currentCycle == null) return 0;
    return CycleCalculator.getCycleDay(currentCycle!.startDate, DateTime.now());
  }

  DateTime? get nextPeriod => CycleCalculator.predictNextPeriodSmart(cycles, _cycleLength);
  DateTime? get nextOvulation => CycleCalculator.predictOvulationSmart(cycles, _cycleLength);
  List<DateTime> get fertileWindow => CycleCalculator.fertileWindowSmart(cycles, _cycleLength);
  List<DateTime> get nextThreePeriods => CycleCalculator.predictNextPeriods(cycles, _cycleLength);
  bool get isCycleRegular => CycleCalculator.isCycleRegular(cycles);

  List<UpcomingEvent> get upcomingEvents => CycleCalculator.getUpcomingEvents(cycles, smartCycleLength, smartPeriodLength);

  List<PersonalInsight> get insights => InsightsEngine.generateInsights(allDayLogs, currentPhase, cycles, currentCycleDay);

  int get pillStreak => CycleCalculator.calcStreak(pillLogs);
  ContraceptiveBrand? get currentBrand => contraBrands.isNotEmpty ? contraBrands.first : null;

  List<MedicalRecord> get upcomingMedical {
    final now = DateTime.now();
    return medicalRecords.where((r) => r.nextDue != null && r.nextDue!.isAfter(now)).toList()
      ..sort((a, b) => a.nextDue!.compareTo(b.nextDue!));
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async { await _loadPrefs(); await loadAll(); await _syncNotifications(); }

  String lastNotifError = '';
  String lastNotifLog = '';

  Future<void> _syncNotifications() async {
    try {
      lastNotifLog = 'Syncing ${reminders.length} reminders, tz=$_timezone...';
      notifyListeners();
      await _notif.syncReminders(reminders, _timezone, emoji: _companionEmoji, name: _companionName);
      // Also schedule medical nextDue notifications
      await _notif.syncMedicalReminders(medicalRecords, _timezone);
      lastNotifLog = 'OK — ${reminders.where((r)=>r.enabled).length} active reminders scheduled';
      lastNotifError = '';
    } catch (e, st) {
      lastNotifError = e.toString();
      lastNotifLog = 'ERROR: $e';
      print('[Luna notif ERROR] $e\n$st');
    }
    notifyListeners();
  }

  Future<void> loadAll() async {
    cycles = await _db.getCycles();
    allDayLogs = await _db.getAllDayLogs();
    journalEntries = await _db.getJournalEntries();
    contraBrands = await _db.getBrands();
    pillLogs = await _db.getPillLogs(90);
    medicalRecords = await _db.getMedicalRecords();
    reminders = await _db.getReminders();
    todayLog = await _db.getDayLog(DateTime.now());
    notifyListeners();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _userName = p.getString('userName') ?? '';
    _cycleLength = p.getInt('cycleLength') ?? 28;
    _periodLength = p.getInt('periodLength') ?? 5;
    _language = p.getString('language') ?? 'English';
    _profilePhotoPath = p.getString('profilePhotoPath');
    _timezone = p.getString('timezone') ?? 'Europe/Bucharest';
    _companionEmoji = p.getString('companionEmoji') ?? '🐱';
    _companionName = p.getString('companionName') ?? 'Luna';
    _contraEnabled = p.getBool('contraEnabled') ?? false;
    _pillReminderTime = p.getString('pillReminderTime') ?? '08:00';
    notifyListeners();
  }

  Future<void> savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('userName', _userName);
    await p.setInt('cycleLength', _cycleLength);
    await p.setInt('periodLength', _periodLength);
    await p.setString('language', _language);
    if (_profilePhotoPath != null) await p.setString('profilePhotoPath', _profilePhotoPath!);
    await p.setString('timezone', _timezone);
    await p.setString('companionEmoji', _companionEmoji);
    await p.setString('companionName', _companionName);
    await p.setBool('contraEnabled', _contraEnabled);
    await p.setString('pillReminderTime', _pillReminderTime);
    notifyListeners();
  }

  // ── Cycles ────────────────────────────────────────────────────────────────

  Future<void> startPeriod() async {
    await _db.insertCycle(CycleEntry(startDate: DateTime.now(), cycleLength: _cycleLength, periodLength: _periodLength));
    await loadAll();
  }

  Future<void> endPeriod() async {
    if (currentCycle == null) return;
    await _db.updateCycle(CycleEntry(id: currentCycle!.id, startDate: currentCycle!.startDate, endDate: DateTime.now(), cycleLength: _cycleLength, periodLength: _periodLength));
    await loadAll();
  }

  Future<void> addPastCycle(DateTime startDate, DateTime endDate) async {
    // periodLength = actual days of bleeding (endDate - startDate)
    // cycleLength = full cycle length from user settings
    final bleedingDays = endDate.difference(startDate).inDays.clamp(1, 14);
    await _db.insertCycle(CycleEntry(
      startDate: startDate,
      endDate: endDate,
      cycleLength: _cycleLength,   // use user's cycle length setting
      periodLength: bleedingDays,  // actual period duration
    ));
    await loadAll();
  }

  Future<void> updateCycle(CycleEntry c) async {
    await _db.updateCycle(c);
    await loadAll();
  }

  Future<void> deleteCycle(int id) async { await _db.deleteCycle(id); await loadAll(); }

  // ── Logs ──────────────────────────────────────────────────────────────────

  Future<void> saveDayLog(DayLog log) async {
    await _db.upsertDayLog(log);
    todayLog = await _db.getDayLog(DateTime.now());
    allDayLogs = await _db.getAllDayLogs();
    notifyListeners();
  }

  Future<void> addJournalEntry(JournalEntry entry) async {
    await _db.insertJournal(entry);
    journalEntries = await _db.getJournalEntries();
    notifyListeners();
  }

  Future<void> updateJournalEntry(JournalEntry entry) async {
    await _db.updateJournal(entry);
    journalEntries = await _db.getJournalEntries();
    notifyListeners();
  }

  Future<void> deleteJournalEntry(int id) async {
    await _db.deleteJournal(id);
    journalEntries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> deleteDayLog(DateTime date) async {
    await _db.deleteDayLog(date);
    allDayLogs.removeWhere((l) => l.date.toIso8601String().split('T')[0] == date.toIso8601String().split('T')[0]);
    notifyListeners();
  }

  // ── Contra ────────────────────────────────────────────────────────────────

  Future<void> addBrand(ContraceptiveBrand brand) async {
    if (contraBrands.isNotEmpty && contraBrands.first.endDate == null) {
      await _db.updateBrand(contraBrands.first.copyWith(endDate: DateTime.now()));
    }
    await _db.insertBrand(brand);
    await loadAll();
  }

  Future<void> deleteBrand(int id) async { await _db.deleteBrand(id); contraBrands.removeWhere((b) => b.id == id); notifyListeners(); }

  Future<void> logPill(DateTime date, bool taken) async {
    await _db.upsertPillLog(PillLog(date: date, taken: taken, time: _pillReminderTime));
    pillLogs = await _db.getPillLogs(90);
    notifyListeners();
  }

  bool isPillTakenToday() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return pillLogs.any((l) => l.date.toIso8601String().split('T')[0] == today && l.taken);
  }

  void setCompanion(String emoji, String name) { _companionEmoji = emoji; _companionName = name; savePrefs(); notifyListeners(); _syncNotifications(); }

  // ── Medical ───────────────────────────────────────────────────────────────

  Future<void> addMedicalRecord(MedicalRecord r) async {
    await _db.insertMedical(r);
    medicalRecords = await _db.getMedicalRecords();
    notifyListeners();
  }

  Future<void> updateMedicalRecord(MedicalRecord r) async {
    await _db.updateMedical(r);
    medicalRecords = await _db.getMedicalRecords();
    notifyListeners();
  }

  Future<void> deleteMedicalRecord(int id) async { await _db.deleteMedical(id); medicalRecords.removeWhere((r) => r.id == id); notifyListeners(); }

  // ── Reminders ─────────────────────────────────────────────────────────────

  Future<bool> checkNotificationPermission() => _notif.hasPermission(_timezone);
  Future<void> requestNotificationPermission() => _notif.requestPermission(_timezone);

  Future<void> addReminder(AppReminder r) async {
    await _db.insertReminder(r);
    reminders = await _db.getReminders();
    notifyListeners();
    _syncNotifications();
  }

  Future<void> toggleReminder(AppReminder r) async {
    final updated = AppReminder(id: r.id, title: r.title, type: r.type, time: r.time, enabled: !r.enabled, note: r.note, nextDue: r.nextDue);
    await _db.updateReminder(updated);
    reminders = await _db.getReminders();
    notifyListeners();
    _syncNotifications();
  }

  Future<void> updateReminder(AppReminder r) async {
    await _db.updateReminder(r);
    reminders = await _db.getReminders();
    notifyListeners();
    _syncNotifications();
  }

  Future<void> deleteReminder(int id) async { await _db.deleteReminder(id); reminders.removeWhere((r) => r.id == id); notifyListeners(); _notif.cancelOne(id); }

  List<String> getCompanionTips() {
    switch (currentPhase) {
      case CyclePhase.menstrual: return ['💗 Warm tea + heating pad = magic combo today! 🍵', '🥬 Your body is losing iron. Try spinach with lemon juice!', '😴 Rest is productive today. Be kind to yourself.', '🍫 Dark chocolate (70%+) has magnesium that relaxes muscles!', '🧘 Child\'s pose for 10 min can ease cramps.', '💧 Drink more water — it actually reduces bloating!'];
      case CyclePhase.follicular: return ['⚡ Your energy is rising! Great week for new goals.', '🎨 Estrogen is boosting your creativity right now!', '💪 Best week for strength training — go for it!', '🧠 Schedule your most important tasks this week!', '🌿 Flaxseeds daily support your hormone balance now.'];
      case CyclePhase.ovulation: return ['🌸 You\'re at your most confident! Schedule important talks.', '💃 Peak energy week! Plan social events.', '🌡️ Watch for ovulation signs today!', '💬 Your communication is at its best — speak up!'];
      case CyclePhase.luteal: return ['🌙 Not "too sensitive" — it\'s biology. You\'re valid! 💜', '🥛 1200mg calcium daily reduces PMS by 48%!', '🚶 A 30-min walk does more for mood than a nap.', '🎧 Calm music lowers cortisol by 12%!', '🫘 Complex carbs boost serotonin naturally.', '🧘 This is your introspective, detail-oriented phase.'];
      default: return ['💜 Log your period start date to get personalized tips!'];
    }
  }
}
