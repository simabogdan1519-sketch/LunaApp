import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'luna.db');
    return openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('CREATE TABLE IF NOT EXISTS cycles (id INTEGER PRIMARY KEY AUTOINCREMENT, startDate TEXT NOT NULL, endDate TEXT, cycleLength INTEGER DEFAULT 28, periodLength INTEGER DEFAULT 5)');
      await db.execute('CREATE TABLE IF NOT EXISTS day_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT UNIQUE NOT NULL, mood INTEGER, energy INTEGER, pain INTEGER, basalTemp REAL, symptoms TEXT, notes TEXT)');
      await db.execute('CREATE TABLE IF NOT EXISTS journal_entries (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, title TEXT, content TEXT, mood INTEGER, activities TEXT)');
      await db.execute('CREATE TABLE IF NOT EXISTS contra_brands (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type TEXT, startDate TEXT NOT NULL, endDate TEXT, rating INTEGER DEFAULT 3, notes TEXT)');
      await db.execute('CREATE TABLE IF NOT EXISTS pill_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT UNIQUE NOT NULL, taken INTEGER DEFAULT 0, time TEXT)');
    });
  }

  // ── Cycles ──────────────────────────────────────────────────────────────────
  Future<int> insertCycle(CycleEntry c) async {
    final map = c.toMap();
    map.remove('id');
    return (await db).insert('cycles', map);
  }

  Future<List<CycleEntry>> getCycles() async {
    final rows = await (await db).query('cycles', orderBy: 'startDate DESC');
    return rows.map(CycleEntry.fromMap).toList();
  }

  Future<void> updateCycle(CycleEntry c) async {
    final map = c.toMap();
    await (await db).update('cycles', map, where: 'id=?', whereArgs: [c.id]);
  }

  Future<void> deleteCycle(int id) async {
    await (await db).delete('cycles', where: 'id=?', whereArgs: [id]);
  }

  // ── Day Logs ─────────────────────────────────────────────────────────────────
  Future<void> upsertDayLog(DayLog log) async {
    final d = await db;
    final dateStr = log.date.toIso8601String().split('T')[0];
    final existing = await d.query('day_logs', where: 'date=?', whereArgs: [dateStr]);
    
    final map = {
      'date': dateStr,
      'mood': log.mood,
      'energy': log.energy,
      'pain': log.pain,
      'basalTemp': log.basalTemp,
      'symptoms': log.symptoms.join(','),
      'notes': log.notes,
    };

    if (existing.isEmpty) {
      await d.insert('day_logs', map);
    } else {
      await d.update('day_logs', map, where: 'date=?', whereArgs: [dateStr]);
    }
  }

  Future<DayLog?> getDayLog(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final rows = await (await db).query('day_logs', where: 'date=?', whereArgs: [dateStr]);
    return rows.isEmpty ? null : DayLog.fromMap(rows.first);
  }

  // ── Journal ──────────────────────────────────────────────────────────────────
  Future<int> insertJournal(JournalEntry e) async {
    final map = e.toMap();
    map.remove('id');
    return (await db).insert('journal_entries', map);
  }

  Future<List<JournalEntry>> getJournalEntries() async {
    final rows = await (await db).query('journal_entries', orderBy: 'date DESC');
    return rows.map(JournalEntry.fromMap).toList();
  }

  Future<void> deleteJournal(int id) async {
    await (await db).delete('journal_entries', where: 'id=?', whereArgs: [id]);
  }

  // ── Contra brands ────────────────────────────────────────────────────────────
  Future<int> insertBrand(ContraceptiveBrand b) async {
    final map = b.toMap();
    map.remove('id');
    return (await db).insert('contra_brands', map);
  }

  Future<List<ContraceptiveBrand>> getBrands() async {
    final rows = await (await db).query('contra_brands', orderBy: 'startDate DESC');
    return rows.map(ContraceptiveBrand.fromMap).toList();
  }

  Future<void> updateBrand(ContraceptiveBrand b) async {
    await (await db).update('contra_brands', b.toMap(), where: 'id=?', whereArgs: [b.id]);
  }

  Future<void> deleteBrand(int id) async {
    await (await db).delete('contra_brands', where: 'id=?', whereArgs: [id]);
  }

  // ── Pill logs ────────────────────────────────────────────────────────────────
  Future<void> upsertPillLog(PillLog log) async {
    final d = await db;
    final dateStr = log.date.toIso8601String().split('T')[0];
    final existing = await d.query('pill_logs', where: 'date=?', whereArgs: [dateStr]);
    final map = {'date': dateStr, 'taken': log.taken ? 1 : 0, 'time': log.time};
    if (existing.isEmpty) {
      await d.insert('pill_logs', map);
    } else {
      await d.update('pill_logs', map, where: 'date=?', whereArgs: [dateStr]);
    }
  }

  Future<List<PillLog>> getPillLogs(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String().split('T')[0];
    final rows = await (await db).query('pill_logs', where: 'date >= ?', whereArgs: [cutoff], orderBy: 'date DESC');
    return rows.map(PillLog.fromMap).toList();
  }
}
