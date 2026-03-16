import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'database_service.dart';
import 'cycle_calculator.dart';

class AppState extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  String _userName = '';
  int _cycleLength = 28;
  int _periodLength = 5;
  String _language = 'English';
  String _companionEmoji = '🐱';
  String _companionName = 'Luna';
  bool _contraEnabled = false;
  String _pillReminderTime = '08:00';

  // Getters
  String get userName => _userName;
  int get cycleLength => _cycleLength;
  int get periodLength => _periodLength;
  String get language => _language;
  String get companionEmoji => _companionEmoji;
  String get companionName => _companionName;
  bool get contraEnabled => _contraEnabled;
  String get pillReminderTime => _pillReminderTime;

  // Setters that notify
  set userName(String v) { _userName = v; notifyListeners(); }
  set cycleLength(int v) { _cycleLength = v; notifyListeners(); }
  set periodLength(int v) { _periodLength = v; notifyListeners(); }
  set language(String v) { _language = v; notifyListeners(); }
  set companionEmoji(String v) { _companionEmoji = v; notifyListeners(); }
  set companionName(String v) { _companionName = v; notifyListeners(); }
  set contraEnabled(bool v) { _contraEnabled = v; notifyListeners(); }
  set pillReminderTime(String v) { _pillReminderTime = v; notifyListeners(); }

  List<CycleEntry> cycles = [];
  List<JournalEntry> journalEntries = [];
  List<ContraceptiveBrand> contraBrands = [];
  List<PillLog> pillLogs = [];
  DayLog? todayLog;

  CycleEntry? get currentCycle => cycles.isNotEmpty ? cycles.first : null;

  CyclePhase get currentPhase {
    if (currentCycle == null) return CyclePhase.unknown;
    final day = CycleCalculator.getCycleDay(currentCycle!.startDate, DateTime.now());
    return CycleCalculator.getPhaseForDay(day, _cycleLength, _periodLength);
  }

  int get currentCycleDay {
    if (currentCycle == null) return 0;
    return CycleCalculator.getCycleDay(currentCycle!.startDate, DateTime.now());
  }

  DateTime? get nextPeriod => CycleCalculator.predictNextPeriod(currentCycle);
  DateTime? get nextOvulation => CycleCalculator.predictOvulation(currentCycle);
  List<DateTime> get fertileWindow => CycleCalculator.fertileWindow(currentCycle);
  int get pillStreak => CycleCalculator.calcStreak(pillLogs);
  ContraceptiveBrand? get currentBrand => contraBrands.isNotEmpty ? contraBrands.first : null;

  Future<void> init() async {
    await _loadPrefs();
    await loadAll();
  }

  Future<void> loadAll() async {
    cycles = await _db.getCycles();
    journalEntries = await _db.getJournalEntries();
    contraBrands = await _db.getBrands();
    pillLogs = await _db.getPillLogs(90);
    todayLog = await _db.getDayLog(DateTime.now());
    notifyListeners();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _userName = p.getString('userName') ?? '';
    _cycleLength = p.getInt('cycleLength') ?? 28;
    _periodLength = p.getInt('periodLength') ?? 5;
    _language = p.getString('language') ?? 'English';
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
    await p.setString('companionEmoji', _companionEmoji);
    await p.setString('companionName', _companionName);
    await p.setBool('contraEnabled', _contraEnabled);
    await p.setString('pillReminderTime', _pillReminderTime);
    notifyListeners();
  }

  // ── Cycle actions ────────────────────────────────────────────────────────────
  Future<void> startPeriod() async {
    await _db.insertCycle(CycleEntry(startDate: DateTime.now(), cycleLength: _cycleLength, periodLength: _periodLength));
    await loadAll();
  }

  Future<void> endPeriod() async {
    if (currentCycle == null) return;
    final updated = CycleEntry(id: currentCycle!.id, startDate: currentCycle!.startDate, endDate: DateTime.now(), cycleLength: _cycleLength, periodLength: _periodLength);
    await _db.updateCycle(updated);
    await loadAll();
  }

  Future<void> addPastCycle(DateTime startDate, DateTime endDate) async {
    final length = endDate.difference(startDate).inDays;
    final periodLen = _periodLength;
    await _db.insertCycle(CycleEntry(startDate: startDate, endDate: endDate, cycleLength: length, periodLength: periodLen));
    await loadAll();
  }

  Future<void> deleteCycle(int id) async {
    await _db.deleteCycle(id);
    await loadAll();
  }

  // ── Log / Journal ────────────────────────────────────────────────────────────
  Future<void> saveDayLog(DayLog log) async {
    await _db.upsertDayLog(log);
    todayLog = await _db.getDayLog(DateTime.now());
    notifyListeners();
  }

  Future<void> addJournalEntry(JournalEntry entry) async {
    await _db.insertJournal(entry);
    journalEntries = await _db.getJournalEntries();
    notifyListeners();
  }

  Future<void> deleteJournalEntry(int id) async {
    await _db.deleteJournal(id);
    journalEntries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ── Contra ───────────────────────────────────────────────────────────────────
  Future<void> addBrand(ContraceptiveBrand brand) async {
    if (contraBrands.isNotEmpty && contraBrands.first.endDate == null) {
      final prev = contraBrands.first;
      await _db.updateBrand(prev.copyWith(endDate: DateTime.now()));
    }
    await _db.insertBrand(brand);
    await loadAll();
  }

  Future<void> deleteBrand(int id) async {
    await _db.deleteBrand(id);
    contraBrands.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  Future<void> logPill(DateTime date, bool taken) async {
    await _db.upsertPillLog(PillLog(date: date, taken: taken, time: _pillReminderTime));
    pillLogs = await _db.getPillLogs(90);
    notifyListeners();
  }

  bool isPillTakenToday() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return pillLogs.any((l) => l.date.toIso8601String().split('T')[0] == today && l.taken);
  }

  void setCompanion(String emoji, String name) {
    _companionEmoji = emoji;
    _companionName = name;
    savePrefs();
    notifyListeners();
  }

  List<String> getCompanionTips() {
    switch (currentPhase) {
      case CyclePhase.menstrual: return ['💗 Warm tea + heating pad = magic combo today! 🍵', '🥬 Your body is losing iron. Try spinach with lemon juice!', '😴 Rest is productive today. Be kind to yourself.', '🍫 Dark chocolate (70%+) has magnesium that relaxes muscles!'];
      case CyclePhase.follicular: return ['⚡ Your energy is rising! Great week for new goals.', '🎨 Estrogen is boosting your creativity right now!', '💪 Best week for strength training — go for it!'];
      case CyclePhase.ovulation: return ['🌸 You\'re at your most confident! Schedule important talks.', '💃 Peak energy week! Plan social events.'];
      case CyclePhase.luteal: return ['🌙 Not "too sensitive" — it\'s biology. You\'re valid! 💜', '🥛 1200mg calcium daily reduces PMS by 48%!', '🚶 A 30-min walk does more for mood than a nap.'];
      default: return ['💜 Log your period start date to get personalized tips!'];
    }
  }
}
