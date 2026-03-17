import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/models.dart';

const _pill    = ['💊 Nu uita de pastilă! 🌸', '💊 E ora pilulei! 💜', '💊 Pastila de azi — nu o sări! 🌸', '💊 Pastilă time! ✨'];
const _water   = ['💧 Ai băut suficientă apă azi?', '💧 Un pahar mare de apă 🌸', '💧 2.5L pe zi 🌙', '💧 Hidratare reminder! ✨'];
const _sleep   = ['🌙 Pregătește-te de somn 💜', '🌙 Odihnește-te bine ✨', '😴 Ora de somn! 🌙', '🌙 Noapte bună! 💜'];
const _exercise= ['🏃‍♀️ Mișcarea reduce crampele!', '💜 15 minute de mers îți fac bine 🌸', '💪 Un pic de mișcare azi?', '🏃‍♀️ Te vei simți mai bine după! 💪'];
const _morning = ['☀️ Bună dimineața! Cum te simți? 💜', '🌸 O nouă zi! Ai grijă de tine 💜', '✨ Notează cum te simți azi 📝', '☀️ Corpul tău merită atenție 💜'];
const _evening = ['🌙 Loghează-ți ziua 💜', '🌸 Notează-ți simptomele!', '🌙 Un moment pentru tine ✨', '💜 Cum a fost ziua?'];
const _general = ['💜 Ai grijă de tine azi!', '🌸 Tu ești prioritatea!', '💜 Ascultă-ți corpul!', '🌙 Sănătatea ta contează ✨'];

String _msg(AppReminder r) {
  final txt = '${r.title} ${r.note ?? ''}'.toLowerCase();
  List<String> p;
  if (txt.contains('pill') || txt.contains('pastil') || txt.contains('contra')) p = _pill;
  else if (txt.contains('water') || txt.contains('apa') || txt.contains('hidrat')) p = _water;
  else if (txt.contains('sleep') || txt.contains('somn') || txt.contains('magnesiu')) p = _sleep;
  else if (txt.contains('exercit') || txt.contains('sport') || txt.contains('kegel')) p = _exercise;
  else {
    final h = int.tryParse(r.time.split(':')[0]) ?? 12;
    p = h < 12 ? _morning : h >= 20 ? _evening : _general;
  }
  return p[(r.id ?? 0) % p.length];
}

class NotificationService {
  static final _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _p = FlutterLocalNotificationsPlugin();
  bool _tzReady = false;

  void _initTz(String tzName) {
    if (!_tzReady) {
      try { tz_data.initializeTimeZones(); } catch (_) {}
      _tzReady = true;
    }
    try {
      final loc = tz.getLocation(tzName);
      tz.setLocalLocation(loc);
    } catch (_) {
      // fallback: match by UTC offset
      try {
        final offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
        for (final loc in tz.timeZoneDatabase.locations.values) {
          if (loc.currentTimeZone.offset == offsetMs) {
            tz.setLocalLocation(loc);
            return;
          }
        }
      } catch (_) {}
    }
  }

  Future<void> init({String timezone = 'Europe/Bucharest'}) async {
    _initTz(timezone);
    try {
      await _p.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ));
    } catch (_) {}
  }

  Future<bool> hasPermission() async {
    try {
      await init();
      return await _p.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.areNotificationsEnabled() ?? true;
    } catch (_) { return true; }
  }

  Future<void> requestPermission() async {
    try {
      await init();
      await _p.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    } catch (_) {}
  }

  Future<void> sendTest({String companionEmoji = '🌙', String companionName = 'Luna', String timezone = 'Europe/Bucharest'}) async {
    await init(timezone: timezone);
    await _p.show(9999, '$companionEmoji $companionName',
      '🌸 Notificările funcționează! Vei primi reminder-ele la timp 💜',
      const NotificationDetails(android: AndroidNotificationDetails(
        'luna_reminders', 'Luna Reminders',
        importance: Importance.high, priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      )),
    );
  }

  Future<void> syncReminders(List<AppReminder> reminders, {
    String companionEmoji = '🌙',
    String companionName = 'Luna',
    String timezone = 'Europe/Bucharest',
  }) async {
    await init(timezone: timezone);
    try { await _p.cancelAll(); } catch (_) {}
    for (final r in reminders) {
      if (r.enabled && r.id != null) {
        try { await _schedule(r, companionEmoji, companionName); }
        catch (e) { print('[notif] ${r.title}: $e'); }
      }
    }
  }

  Future<void> cancelOne(int id) async {
    try { await _p.cancel(id); } catch (_) {}
  }

  Future<void> _schedule(AppReminder r, String emoji, String name) async {
    final parts = r.time.split(':');
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

    // Compute next fire using pure Dart milliseconds — no tz math needed
    final now  = DateTime.now();
    var   next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    // fromMillisecondsSinceEpoch with tz.local set correctly above
    final tzFire = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.local, next.millisecondsSinceEpoch,
    );

    switch (r.type) {
      case 'daily':
        await _p.zonedSchedule(r.id!, title, body, tzFire, det,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        break;
      case 'weekly':
        await _p.zonedSchedule(r.id!, title, body, tzFire, det,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        break;
      default:
        await _p.zonedSchedule(r.id!, title, body, tzFire, det,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
        );
        break;
    }
  }
}
