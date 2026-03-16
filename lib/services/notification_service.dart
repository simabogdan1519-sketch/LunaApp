import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/models.dart';

// ── Mesaje companion ──────────────────────────────────────────────────────────
const _morningMessages = [
  '☀️ Bună dimineața! Cum te simți azi? Ia un moment pentru tine 💜',
  '🌸 O nouă zi, un nou început! Nu uita să ai grijă de tine 💜',
  '✨ Dimineața e perfectă pentru a-ți nota cum te simți 📝',
  '☀️ Corpul tău merită atenție azi — eu sunt aici dacă ai nevoie 💜',
];
const _eveningMessages = [
  '🌙 Ia 2 minute să îți loghezi ziua — tu și corpul tău merități asta 💜',
  '🌸 Cum a fost ziua? Nu uita să îți notezi simptomele!',
  '🌙 Înainte de somn, ia un moment pentru tine ✨',
  '💜 E ora să îți oferi un moment de grijă. Deschide Luna!',
];
const _pillMessages = [
  '💊 Nu uita de pastilă! Sănătatea ta contează 🌸',
  '💊 E ora pilulei! Consecvența e cheia 💜',
  '🌸 Reminder prietenos: pastila ta de azi! Nu o sări 💊',
  '💊 Pastilă time! Îți doresc o zi frumoasă ✨',
];
const _waterMessages = [
  '💧 Ai băut suficientă apă azi? Hidratarea îți susține echilibrul hormonal!',
  '💧 Un pahar mare de apă te ajută mai mult decât crezi 🌸',
  '🌙 Corpul tău are nevoie de apă! 2.5L pe zi 💧',
  '💧 Hidratare reminder! Tu și corpul tău merități apă curată ✨',
];
const _sleepMessages = [
  '🌙 E timpul să te pregătești de somn. Somnul bun = hormoni fericiți 💜',
  '🌙 Pregătește-te de odihnă ✨ Corpul tău se regenerează noaptea!',
  '😴 Ora de somn se apropie! Pune telefonul jos și odihnește-te bine',
  '🌙 Noapte bună! Corpul tău lucrează din greu — lasă-l să se odihnească 💜',
];
const _exerciseMessages = [
  '🏃‍♀️ Mișcarea reduce crampele și îmbunătățește starea de spirit! Hai!',
  '💜 Chiar și 15 minute de mers îți fac bine hormonilor 🌸',
  '💪 Corpul tău e puternic! Un pic de mișcare azi?',
  '🏃‍♀️ Nu uita de exercițiile de azi — te vei simți mult mai bine după!',
];
const _generalMessages = [
  '💜 Nu uita să ai grijă de tine azi!',
  '🌸 Reminder de la Luna: tu ești prioritatea! Cum te simți?',
  '💜 Corpul tău îți vorbește — ascultă-l! Deschide Luna să loghezi.',
  '🌙 Un reminder prietenos că sănătatea ta contează. Eu sunt aici! ✨',
];

String _pickMessage(AppReminder reminder) {
  final combined = '${reminder.title} ${reminder.note ?? ''}'.toLowerCase();
  List<String> pool;
  if (combined.contains('pill') || combined.contains('pastil') || combined.contains('contra')) {
    pool = _pillMessages;
  } else if (combined.contains('water') || combined.contains('apa') || combined.contains('hidrat')) {
    pool = _waterMessages;
  } else if (combined.contains('sleep') || combined.contains('somn') || combined.contains('magnesium')) {
    pool = _sleepMessages;
  } else if (combined.contains('exercise') || combined.contains('exercit') || combined.contains('kegel') || combined.contains('sport')) {
    pool = _exerciseMessages;
  } else {
    final hour = int.tryParse(reminder.time.split(':')[0]) ?? 12;
    pool = hour < 12 ? _morningMessages : hour >= 20 ? _eveningMessages : _generalMessages;
  }
  return pool[(reminder.id ?? 0) % pool.length];
}

// ── NotificationService ───────────────────────────────────────────────────────
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      final now = DateTime.now();
      final offsetMs = now.timeZoneOffset.inMilliseconds;
      // Find a timezone matching the device's current UTC offset
      tz.Location? found;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == offsetMs) {
          found = loc;
          break;
        }
      }
      tz.setLocalLocation(found ?? tz.UTC);
    } catch (_) {}

    try {
      // '@mipmap/ic_launcher' = app icon, always exists, no custom drawable needed
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(settings);
    } catch (_) {}

    _initialized = true;
  }

  Future<bool> hasPermission() async {
    try {
      await init();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? true;
    } catch (_) { return true; }
  }

  Future<bool> requestPermission() async {
    try {
      await init();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? true;
    } catch (_) { return true; }
  }

  Future<void> syncReminders(
    List<AppReminder> reminders, {
    String companionEmoji = '🌙',
    String companionName = 'Luna',
  }) async {
    await init();
    try { await _plugin.cancelAll(); } catch (_) {}
    for (final r in reminders) {
      if (r.enabled && r.id != null) {
        try {
          await _scheduleOne(r, companionEmoji: companionEmoji, companionName: companionName);
        } catch (e) {
          print('[Luna notifications] error scheduling ${r.title}: $e');
        }
      }
    }
  }

  Future<void> cancelOne(int id) async {
    try { await _plugin.cancel(id); } catch (_) {}
  }

  // Public: send immediate test notification
  Future<void> sendTest({String companionEmoji = '🌙', String companionName = 'Luna'}) async {
    await init();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'luna_reminders', 'Luna Reminders',
        channelDescription: 'Reminders from your Luna companion',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(
      9999,
      '$companionEmoji $companionName',
      '🌸 Bună! Notificările funcționează! Vei primi reminder-ele la timp 💜',
      details,
    );
  }

  Future<void> _scheduleOne(
    AppReminder reminder, {
    String companionEmoji = '🌙',
    String companionName = 'Luna',
  }) async {
    final parts = reminder.time.split(':');
    final hour   = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final title   = '$companionEmoji $companionName';
    final message = _pickMessage(reminder);

    final androidDetails = AndroidNotificationDetails(
      'luna_reminders',
      'Luna Reminders',
      channelDescription: 'Reminders from your Luna companion',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(message),
    );
    final details = NotificationDetails(android: androidDetails);

    // Next occurrence of HH:mm in local time
    final now  = DateTime.now();
    var next   = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    final tzNext = tz.TZDateTime.from(next, tz.local);

    switch (reminder.type) {
      case 'daily':
        await _plugin.zonedSchedule(
          reminder.id!, title, message, tzNext, details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        break;
      case 'weekly':
        await _plugin.zonedSchedule(
          reminder.id!, title, message, tzNext, details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        break;
      default: // one_time
        await _plugin.zonedSchedule(
          reminder.id!, title, message, tzNext, details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
        );
        break;
    }
  }
}
