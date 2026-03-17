import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/models.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _p = FlutterLocalNotificationsPlugin();

  Future<void> init(String tzName) async {
    tz_data.initializeTimeZones();
    try { tz.setLocalLocation(tz.getLocation(tzName)); } catch (_) {}
    await _p.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (_) {},
    );
    await _p
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'luna_reminders',
          'Luna Reminders',
          description: 'Reminders from your Luna companion',
          importance: Importance.high,
          playSound: true,
        ));
  }

  tz.TZDateTime _nextInstance(String time, String tzName) {
    try { tz.setLocalLocation(tz.getLocation(tzName)); } catch (_) {}
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
    await _p.cancelAll();
    for (final r in reminders) {
      if (!r.enabled) continue;
      await _p.zonedSchedule(
        r.id.hashCode,
        '$emoji $name',
        r.title,
        _nextInstance(r.time, tzName),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'luna_reminders',
            'Luna Reminders',
            channelDescription: 'Reminders from your Luna companion',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> sendTest(String tzName,
      {String emoji = '🌸', String name = 'Luna'}) async {
    await _p.show(
      99999,
      '$emoji $name',
      'Notificările funcționează! Vei primi reminder-ele la orele setate 💜',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'luna_reminders',
          'Luna Reminders',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
    );
  }

  Future<void> cancelOne(int id) async {
    await _p.cancel(id.hashCode);
  }

  Future<bool> hasPermission(String tzName) async {
    final android = _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  Future<void> requestPermission(String tzName) async {
    final android = _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<String> debugSchedule(AppReminder r, String tzName) async {
    final fire = _nextInstance(r.time, tzName);
    final now = tz.TZDateTime.now(tz.local);
    final diff = fire.difference(now);
    return 'tz=${tz.local.name}\nnow=$now\nfire=$fire\nin ${diff.inHours}h ${diff.inMinutes % 60}m';
  }
}
