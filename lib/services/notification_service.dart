import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/models.dart';

// ── Mesaje ────────────────────────────────────────────────────────────────────
const _pill = [
  '💊 Nu uita de pastilă! Sănătatea ta contează 🌸',
  '💊 E ora pilulei! Consecvența e cheia 💜',
  '💊 Pastila de azi — nu o sări! 🌸',
  '💊 Pastilă time! Îți doresc o zi frumoasă ✨',
];
const _water = [
  '💧 Ai băut suficientă apă azi? Hidratarea contează!',
  '💧 Un pahar mare de apă te ajută mai mult decât crezi 🌸',
  '💧 2.5L pe zi pentru hormoni fericiți 🌙',
  '💧 Hidratare reminder! Tu meriti apă curată ✨',
];
const _sleep = [
  '🌙 Pregătește-te de somn. Somnul bun = hormoni fericiți 💜',
  '🌙 Odihnește-te bine ✨ Corpul tău se regenerează noaptea!',
  '😴 Ora de somn! Pune telefonul jos 🌙',
  '🌙 Noapte bună! Lasă corpul să se odihnească 💜',
];
const _exercise = [
  '🏃‍♀️ Mișcarea reduce crampele! Hai, o poți face!',
  '💜 Chiar și 15 minute de mers îți fac bine 🌸',
  '💪 Un pic de mișcare azi?',
  '🏃‍♀️ Te vei simți mult mai bine după! 💪',
];
const _morning = [
  '☀️ Bună dimineața! Cum te simți azi? 💜',
  '🌸 O nouă zi! Nu uita să ai grijă de tine 💜',
  '✨ Dimineața e perfectă pentru a-ți nota cum te simți 📝',
  '☀️ Corpul tău merită atenție azi 💜',
];
const _evening = [
  '🌙 Ia 2 minute să îți loghezi ziua 💜',
  '🌸 Cum a fost ziua? Nu uita să îți notezi simptomele!',
  '🌙 Înainte de somn, ia un moment pentru tine ✨',
  '💜 E ora să îți oferi un moment de grijă!',
];
const _general = [
  '💜 Nu uita să ai grijă de tine azi!',
  '🌸 Tu ești prioritatea! Cum te simți?',
  '💜 Corpul tău îți vorbește — ascultă-l!',
  '🌙 Sănătatea ta contează. Eu sunt aici! ✨',
];

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

// ── NotificationService ───────────────────────────────────────────────────────
class NotificationService {
  static final _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _p = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channel = 'luna_reminders';
  static const _channelName = 'Luna Reminders';

  Future<void> init() async {
    if (_ready) return;
    try { tz_data.initializeTimeZones(); } catch (_) {}
    try {
      await _p.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
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

  NotificationDetails _details(String body) => NotificationDetails(
    android: AndroidNotificationDetails(
      _channel, _channelName,
      channelDescription: 'Reminders from your Luna companion',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
      icon: '@mipmap/ic_launcher',
    ),
  );

  // Immediate test
  Future<void> sendTest({String companionEmoji = '🌙', String companionName = 'Luna'}) async {
    await init();
    await _p.show(
      9999,
      '$companionEmoji $companionName',
      '🌸 Notificările funcționează! Vei primi reminder-ele la timp 💜',
      _details('🌸 Notificările funcționează! Vei primi reminder-ele la timp 💜'),
    );
  }

  Future<void> syncReminders(
    List<AppReminder> reminders, {
    String companionEmoji = '🌙',
    String companionName = 'Luna',
  }) async {
    await init();
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
    final parts  = r.time.split(':');
    final hour   = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final title  = '$emoji $name';
    final body   = _msg(r);
    final det    = _details(body);

    // Compute seconds until next HH:MM
    final now  = DateTime.now();
    var  next  = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    // ── KEY FIX: use tz.TZDateTime.local() which mirrors DateTime.now() ──────
    final tzNow  = tz.TZDateTime.now(tz.local);
    final diff   = next.difference(now);           // pure Dart diff, no tz
    final tzNext = tzNow.add(diff);                // apply diff to tz-aware now

    switch (r.type) {
      case 'daily':
        await _p.zonedSchedule(
          r.id!, title, body, tzNext, det,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        break;
      case 'weekly':
        await _p.zonedSchedule(
          r.id!, title, body, tzNext, det,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        break;
      default:
        await _p.zonedSchedule(
          r.id!, title, body, tzNext, det,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
        );
        break;
    }
  }
}
