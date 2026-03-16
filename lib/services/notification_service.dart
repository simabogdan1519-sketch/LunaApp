import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/models.dart';

// ── Mesaje de la companion ────────────────────────────────────────────────────
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
  'Nu uita de pastilă! Eu te urmăresc — sănătatea ta contează 🌸',
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
  final combined =
      '${reminder.title} ${reminder.note ?? ''}'.toLowerCase();
  List<String> pool;
  if (combined.contains('pill') || combined.contains('pastil') ||
      combined.contains('contra')) {
    pool = _pillMessages;
  } else if (combined.contains('water') || combined.contains('apa') ||
      combined.contains('hidrat')) {
    pool = _waterMessages;
  } else if (combined.contains('sleep') || combined.contains('somn') ||
      combined.contains('bed') || combined.contains('magnesium')) {
    pool = _sleepMessages;
  } else if (combined.contains('exercise') || combined.contains('exercit') ||
      combined.contains('kegel') || combined.contains('sport')) {
    pool = _exerciseMessages;
  } else {
    final hour = int.tryParse(reminder.time.split(':')[0]) ?? 12;
    pool = hour < 12
        ? _morningMessages
        : hour >= 20
            ? _eveningMessages
            : _generalMessages;
  }
  return pool[(reminder.id ?? 0) % pool.length];
}

// ── Companion emoji → drawable ────────────────────────────────────────────────
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

    // Set up timezone - use UTC as safe fallback, avoids local tz lookup issues
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC); // we'll offset manually using device DateTime

    const androidSettings =
        AndroidInitializationSettings('ic_luna_notif'); // no @ prefix here
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  // Check if permission is already granted (Android 13+)
  Future<bool> hasPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.areNotificationsEnabled();
      return granted ?? false;
    }
    return true;
  }

  // Request permission
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  // Sync all reminders - cancel old, schedule enabled ones
  Future<void> syncReminders(
    List<AppReminder> reminders, {
    String companionEmoji = '🌙',
    String companionName = 'Luna',
  }) async {
    await init();
    await _plugin.cancelAll();
    for (final r in reminders) {
      if (r.enabled && r.id != null) {
        try {
          await _scheduleReminder(r,
              companionEmoji: companionEmoji, companionName: companionName);
        } catch (e) {
          // log but don't crash if one reminder fails
          print('Notification schedule error for ${r.title}: $e');
        }
      }
    }
  }

  Future<void> cancelOne(int reminderId) async {
    await init();
    await _plugin.cancel(reminderId);
  }

  Future<void> _scheduleReminder(
    AppReminder reminder, {
    String companionEmoji = '🌙',
    String companionName = 'Luna',
  }) async {
    final parts = reminder.time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final message = _pickMessage(reminder);
    final title = '$companionEmoji $companionName';
    final iconName = _companionIcon(companionEmoji);

    final androidDetails = AndroidNotificationDetails(
      'luna_reminders',
      'Luna Reminders',
      channelDescription: 'Reminders from your Luna companion',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        message,
        contentTitle: title,
        summaryText: reminder.title,
      ),
      color: const Color(0xFFE57FA0),
      largeIcon: DrawableResourceAndroidBitmap(iconName),
      // smallIcon uses the icon field — this shows in the status bar
    );

    final details = NotificationDetails(android: androidDetails);

    // Build the next scheduled time using local DateTime (avoids tz lookup issues)
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // Convert to TZDateTime in UTC offset matching device local time
    final offset = now.timeZoneOffset;
    final tzScheduled = tz.TZDateTime.utc(
      scheduled.year, scheduled.month, scheduled.day,
      scheduled.hour, scheduled.minute,
    ).subtract(offset); // adjust for local tz

    switch (reminder.type) {
      case 'daily':
        await _plugin.zonedSchedule(
          reminder.id!,
          title,
          message,
          tzScheduled,
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
          tzScheduled,
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
          tzScheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
        );
        break;
    }
  }
}
