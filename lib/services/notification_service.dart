import 'package:flutter/material.dart' show Color, TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/models.dart';

// ── Mesaje companion ──────────────────────────────────────────────────────────
const _morningMessages = [
  'Bună dimineața! ☀️ Cum te simți azi? Ia un moment să te conectezi cu corpul tău 💜',
  'O nouă zi, un nou început 🌸 Nu uita să ai grijă de tine!',
  'Hey! Dimineața e perfectă pentru a-ți nota cum te simți 📝✨',
  'Bună! ☀️ Corpul tău merită atenție azi — eu sunt aici dacă ai nevoie 💜',
];
const _eveningMessages = [
  'Seara bună 🌙 Ia 2 minute să îți loghezi ziua — tu și corpul tău merită asta 💜',
  'Hey, cum a fost ziua? 🌸 Nu uita să îți notezi simptomele!',
  'Înainte de somn, ia un moment pentru tine 🌙✨ Cum te-ai simțit azi?',
  'E ora să îți oferi un moment de grijă 💜 Deschide Luna și loghează-ți ziua!',
];
const _pillMessages = [
  'Nu uita de pastilă! Sănătatea ta contează 🌸',
  'E ora pilulei 💊 Consecvența e cheia — tu ești incredibilă! 💜',
  'Reminder prietenos: pastila ta de azi! Nu o sări 💊',
  'Pastilă time! 💊 Îți doresc o zi frumoasă ✨',
];
const _waterMessages = [
  'Ai băut suficientă apă azi? Hidratarea îți susține echilibrul hormonal! 💧',
  'Un pahar mare de apă te ajută mai mult decât crezi 💧🌸',
  'Corpul tău are nevoie de apă! 2.5L pe zi pentru o hormonală fericită 🌙',
  'Hidratare reminder! 💧 Tu și corpul tău merită apă curată ✨',
];
const _sleepMessages = [
  'E timpul să te pregătești de somn. Somnul bun = hormoni fericiți 💜',
  'Pregătește-te de odihnă 🌙✨ Corpul tău se regenerează noaptea!',
  'Ora de somn se apropie! Pune telefonul jos și odihnește-te bine 😴',
  'Noapte bună! 🌙 Corpul tău lucrează din greu — lasă-l să se odihnească 💜',
];
const _exerciseMessages = [
  'Mișcarea reduce crampele și îmbunătățește starea de spirit! Hai, o poți face! 🏃‍♀️',
  'Chiar și 15 minute de mers îți fac bine hormonilor 💜',
  'Corpul tău e puternic! Un pic de mișcare azi? Eu te susțin 🌙',
  'Nu uita de exercițiile de azi — te vei simți mult mai bine după! 💪',
];
const _generalMessages = [
  'Nu uita să ai grijă de tine azi! 💜',
  'Reminder de la mine: tu ești prioritatea! 🌸 Cum te simți?',
  'Corpul tău îți vorbește — ascultă-l! Deschide Luna să loghezi 💜',
  'Un reminder prietenos că sănătatea ta contează. Eu sunt aici! 🌙',
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

String _companionIcon(String emoji) {
  switch (emoji) {
    case '🐱': return 'ic_companion_cat';
    case '🦊': return 'ic_companion_fox';
    case '🐰': return 'ic_companion_rabbit';
    case '🐻': return 'ic_companion_bear';
    case '🦄': return 'ic_companion_unicorn';
    case '🐼': return 'ic_companion_panda';
    case '🦋': return 'ic_companion_butterfly';
    case '🌸': return 'ic_companion_bloom';
    case '🌙': return 'ic_companion_moon';
    case '⭐': return 'ic_companion_star';
    case '🌺': return 'ic_companion_rose';
    case '🐝': return 'ic_companion_bee';
    default:   return 'ic_luna_notif';
  }
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
      // Detect device local timezone by name
      final tzName = DateTime.now().timeZoneName;
      try {
        tz.setLocalLocation(tz.getLocation(tzName));
      } catch (_) {
        // fallback: manually compute offset from UTC
        final offsetHours = DateTime.now().timeZoneOffset.inHours;
        // find a tz that matches the offset
        final loc = tz.timeZoneDatabase.locations.values.firstWhere(
          (l) => l.currentTimeZone.offset == DateTime.now().timeZoneOffset.inMilliseconds,
          orElse: () => tz.UTC,
        );
        tz.setLocalLocation(loc);
      }
    } catch (_) {}

    try {
      const androidSettings = AndroidInitializationSettings('ic_luna_notif');
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
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
    } catch (_) {}
    return true;
  }

  Future<bool> requestPermission() async {
    try {
      await init();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
    } catch (_) {}
    return true;
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
          await _scheduleReminder(r,
              companionEmoji: companionEmoji, companionName: companionName);
        } catch (e) {
          print('Schedule error for ${r.title}: $e');
        }
      }
    }
  }

  Future<void> cancelOne(int reminderId) async {
    try {
      await init();
      await _plugin.cancel(reminderId);
    } catch (_) {}
  }

  AndroidNotificationDetails _buildAndroidDetails(
      AppReminder reminder, String companionEmoji, String companionName) {
    final icon = _companionIcon(companionEmoji);
    final message = _pickMessage(reminder);
    return AndroidNotificationDetails(
      'luna_reminders',
      'Luna Reminders',
      channelDescription: 'Reminders from your Luna companion',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        message,
        contentTitle: '$companionEmoji $companionName',
        summaryText: reminder.title,
      ),
      color: const Color(0xFFE57FA0),
      largeIcon: DrawableResourceAndroidBitmap(icon),
    );
  }

  Future<void> _scheduleReminder(
    AppReminder reminder, {
    String companionEmoji = '🌙',
    String companionName = 'Luna',
  }) async {
    final parts = reminder.time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final title = '$companionEmoji $companionName';
    final message = _pickMessage(reminder);
    final androidDetails = _buildAndroidDetails(reminder, companionEmoji, companionName);
    final details = NotificationDetails(android: androidDetails);

    // Build next fire time using pure Dart DateTime (no tz library needed)
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute, 0);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    // Convert to TZDateTime using the local location set in init()
    final tzNext = tz.TZDateTime.from(next, tz.local);

    switch (reminder.type) {
      case 'daily':
        await _plugin.zonedSchedule(
          reminder.id!,
          title,
          message,
          tzNext,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        break;

      case 'weekly':
        await _plugin.zonedSchedule(
          reminder.id!,
          title,
          message,
          tzNext,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        break;

      case 'one_time':
      default:
        await _plugin.zonedSchedule(
          reminder.id!,
          title,
          message,
          tzNext,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
        );
        break;
    }
  }
}
