import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/models.dart';

class NotificationService {
  // Singleton — same instance everywhere in the app
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _p = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init(String tzName) async {
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Bucharest'));
    }
    if (_initialized) return;
    _initialized = true;

    await _p.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (_) {},
    );

    // Create notification channel with high importance
    await _p
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'luna_reminders',
          'Luna Reminders',
          description: 'Daily reminders from LunaApp',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ));
  }

  tz.TZDateTime _nextInstance(String time, String tzName) {
    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {}
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = tz.TZDateTime.now(tz.local);
    var fire = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!fire.isAfter(now)) fire = fire.add(const Duration(days: 1));
    return fire;
  }

  Future<void> syncReminders(List<AppReminder> reminders, String tzName,
      {String emoji = '🌸', String name = 'Luna'}) async {
    await init(tzName);
    await _p.cancelAll();

    for (final r in reminders) {
      if (!r.enabled) continue;
      final fire = _nextInstance(r.time, tzName);
      final id = r.id.hashCode.abs() % 100000;

      await _p.zonedSchedule(
        id,
        '$emoji $name',
        r.title,
        fire,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'luna_reminders',
            'Luna Reminders',
            channelDescription: 'Daily reminders from LunaApp',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> sendTest(String tzName,
      {String emoji = '🌸', String name = 'Luna'}) async {
    await init(tzName);
    await _p.show(
      99999,
      '$emoji $name',
      'Notificările funcționează! Vei primi reminder-ele la orele setate 💜',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'luna_reminders',
          'Luna Reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
    );
  }

  Future<void> syncMedicalReminders(List<MedicalRecord> records, String tzName) async {
    await init(tzName);
    for (int i = 50000; i < 50100; i++) { await _p.cancel(i); }
    int id = 50000;
    for (final r in records) {
      if (r.nextDue == null) continue;
      try { tz.setLocalLocation(tz.getLocation(tzName)); } catch (_) {}
      final now = tz.TZDateTime.now(tz.local);
      final due = tz.TZDateTime(tz.local,
          r.nextDue!.year, r.nextDue!.month, r.nextDue!.day, 9, 0);
      if (!due.isAfter(now)) continue;
      await _p.zonedSchedule(
        id++,
        '🩺 Medical reminder',
        '${r.title} is due today',
        due,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'luna_reminders', 'Luna Reminders',
            importance: Importance.max, priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelOne(int id) async {
    await _p.cancel(id.hashCode.abs() % 100000);
  }

  Future<bool> hasPermission(String tzName) async {
    await init(tzName);
    final android = _p.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  Future<void> requestPermission(String tzName) async {
    await init(tzName);
    final android = _p.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }
}
