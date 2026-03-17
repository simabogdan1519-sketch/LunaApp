import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/models.dart';

// Messages
const _pill    = ['💊 Nu uita de pastilă! 🌸', '💊 E ora pilulei! 💜', '💊 Pastila de azi 🌸', '💊 Pastilă time! ✨'];
const _water   = ['💧 Ai băut suficientă apă? 🌸', '💧 Un pahar de apă 💧', '💧 2.5L pe zi 🌙', '💧 Hidratare! ✨'];
const _sleep   = ['🌙 Pregătește-te de somn 💜', '🌙 Odihnește-te bine ✨', '😴 Ora de somn! 🌙', '🌙 Noapte bună! 💜'];
const _move    = ['🏃‍♀️ Mișcare azi? 💪', '💜 15 min de mers îți fac bine 🌸', '💪 Un pic de sport?', '🏃‍♀️ Te vei simți mai bine! 💪'];
const _morning = ['☀️ Bună dimineața! 💜', '🌸 O nouă zi! 💜', '✨ Cum te simți azi? 📝', '☀️ Corpul tău merită atenție 💜'];
const _evening = ['🌙 Loghează-ți ziua 💜', '🌸 Notează simptomele!', '🌙 Un moment pentru tine ✨', '💜 Cum a fost ziua?'];
const _general = ['💜 Ai grijă de tine!', '🌸 Tu ești prioritatea!', '💜 Ascultă-ți corpul!', '🌙 Sănătatea ta contează ✨'];

String _msg(AppReminder r) {
  final t = '${r.title} ${r.note ?? ''}'.toLowerCase();
  if (t.contains('pill') || t.contains('pastil') || t.contains('contra')) return _pill[(r.id ?? 0) % _pill.length];
  if (t.contains('water') || t.contains('apa') || t.contains('hidrat'))   return _water[(r.id ?? 0) % _water.length];
  if (t.contains('sleep') || t.contains('somn') || t.contains('magnesiu')) return _sleep[(r.id ?? 0) % _sleep.length];
  if (t.contains('exercit') || t.contains('sport') || t.contains('kegel')) return _move[(r.id ?? 0) % _move.length];
  final h = int.tryParse(r.time.split(':')[0]) ?? 12;
  final p = h < 12 ? _morning : h >= 20 ? _evening : _general;
  return p[(r.id ?? 0) % p.length];
}

class NotificationService {
  static final _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _p = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _det = NotificationDetails(
    android: AndroidNotificationDetails(
      'luna_reminders', 'Luna Reminders',
      channelDescription: 'Reminders from your Luna companion',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
  );

  Future<void> init() async {
    if (_ready) return;
    try { tz_data.initializeTimeZones(); tz.setLocalLocation(tz.UTC); } catch (_) {}
    try {
      await _p.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ));
    } catch (_) {}
    _ready = true;
  }

  Future<bool> hasPermission() async {
    try {
      await init();
      return await _p
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled() ?? true;
    } catch (_) { return true; }
  }

  Future<void> requestPermission() async {
    try {
      await init();
      await _p
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  // WORKS: immediate show
  Future<void> sendTest({String companionEmoji = '🌙', String companionName = 'Luna'}) async {
    await init();
    await _p.show(9999, '$companionEmoji $companionName',
      '🌸 Notificările funcționează! Vei primi reminder-ele la timp 💜', _det);
  }

  Future<void> syncReminders(List<AppReminder> reminders, {
    String companionEmoji = '🌙', String companionName = 'Luna', String timezone = '',
  }) async {
    await init();
    try { await _p.cancelAll(); } catch (_) {}
    for (final r in reminders) {
      if (r.enabled && r.id != null) {
        try { await _scheduleReminder(r, companionEmoji, companionName); }
        catch (e) { print('[notif] ${r.title}: $e'); }
      }
    }
  }

  Future<void> cancelOne(int id) async {
    try { await _p.cancel(id); } catch (_) {}
  }

  Future<void> _scheduleReminder(AppReminder r, String emoji, String name) async {
    final parts  = r.time.split(':');
    final hour   = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final title  = '$emoji $name';
    final body   = _msg(r);

    final det = NotificationDetails(android: AndroidNotificationDetails(
      'luna_reminders', 'Luna Reminders',
      channelDescription: 'Reminders from your Luna companion',
      importance: Importance.high, priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    ));

    // Compute next fire time entirely in Dart - no tz library math at all
    // We use UTC internally: the device local time "hour:minute" maps to a UTC ms value
    final now    = DateTime.now();                                          // local
    var   next   = DateTime(now.year, now.month, now.day, hour, minute);   // local
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    // Convert local DateTime to UTC ms - this is exact regardless of timezone
    final utcMs  = next.toUtc().millisecondsSinceEpoch;

    // Build a TZDateTime in UTC at the exact same instant
    // Because tz.local = UTC and we pass utcMs, the fire time is correct
    final tzFire = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, utcMs);

    switch (r.type) {
      case 'daily':
        await _p.zonedSchedule(r.id!, title, body, tzFire, det,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        break;
      case 'weekly':
        await _p.zonedSchedule(r.id!, title, body, tzFire, det,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        break;
      default:
        await _p.zonedSchedule(r.id!, title, body, tzFire, det,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        break;
    }
  }
}
