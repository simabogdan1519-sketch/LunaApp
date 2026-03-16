import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/models.dart';

// ── Mesaje de la companion ────────────────────────────────────────────────────
// Notificările arată ca mesaje de la companion-ul Lunei
const _companionName = 'Luna 🌙';

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
  '💊 Nu uita de pastilă! Eu te urmăresc — sănătatea ta contează 🌸',
  'Hey! E ora pilulei 💊 Consecvența e cheia — tu ești incredibilă! 💜',
  '🌸 Reminder prietenos: pastila ta de azi! Nu o sări 💊',
  'Pastilă time! 💊 Îți doresc o zi frumoasă ✨',
];

const _waterMessages = [
  '💧 Ai băut suficientă apă azi? Hidratarea îți susține echilibrul hormonal!',
  'Hey! Un pahar mare de apă te ajută mai mult decât crezi 💧🌸',
  '💧 Corpul tău are nevoie de apă! 2.5L pe zi pentru o hormonală fericită 🌙',
  'Hidratare reminder! 💧 Tu și corpul tău merită apă curată ✨',
];

const _sleepMessages = [
  '🌙 E timpul să te pregătești de somn. Somnul bun = hormoni fericiți 💜',
  'Pregătește-te de odihnă 🌙✨ Corpul tău se regenerează noaptea!',
  '😴 Ora de somn se apropie! Pune telefonul jos și odihnește-te bine 🌸',
  'Noapte bună! 🌙 Corpul tău lucrează din greu pentru tine — lasă-l să se odihnească 💜',
];

const _exerciseMessages = [
  '🏃‍♀️ Mișcarea reduce crampele și îmbunătățește starea de spirit! Hai, o poți face!',
  'Exercițiu time! 🌸 Chiar și 15 minute de mers îți fac bine hormonilor 💜',
  '💪 Corpul tău e puternic! Un pic de mișcare azi? Eu te susțin 🌙',
  '🏃‍♀️ Hey! Nu uita de exercițiile de azi — te vei simți mult mai bine după!',
];

const _generalMessages = [
  'Hei, eu sunt Luna 🌙 Nu uita să ai grijă de tine azi! 💜',
  'Reminder de la mine: tu ești prioritatea! 🌸 Cum te simți?',
  '💜 Corpul tău îți vorbește — ascultă-l! Deschide Luna să loghezi.',
  '🌙 Un reminder prietenos că sănătatea ta contează. Eu sunt aici! ✨',
];

String _pickMessage(AppReminder reminder) {
  final title = reminder.title.toLowerCase();
  final note = (reminder.note ?? '').toLowerCase();
  final combined = '$title $note';

  List<String> pool;
  if (combined.contains('pill') || combined.contains('pastil') || combined.contains('contra')) {
    pool = _pillMessages;
  } else if (combined.contains('water') || combined.contains('apa') || combined.contains('hidrat')) {
    pool = _waterMessages;
  } else if (combined.contains('sleep') || combined.contains('somn') || combined.contains('bed') || combined.contains('magnesium')) {
    pool = _sleepMessages;
  } else if (combined.contains('exercise') || combined.contains('exercit') || combined.contains('kegel') || combined.contains('sport')) {
    pool = _exerciseMessages;
  } else {
    // Pick based on time of day
    final hour = int.tryParse(reminder.time.split(':')[0]) ?? 12;
    if (hour < 12) {
      pool = _morningMessages;
    } else if (hour >= 20) {
      pool = _eveningMessages;
    } else {
      pool = _generalMessages;
    }
  }

  // Use reminder id as seed for variety but not pure random (consistent per reminder)
  final idx = (reminder.id ?? 0) % pool.length;
  return pool[idx];
}

// ── Companion emoji → drawable icon name ─────────────────────────────────────
String _companionIcon(String emoji) {
  switch (emoji) {
    case '🐱': return '@drawable/ic_companion_cat';
    case '🦊': return '@drawable/ic_companion_fox';
    case '🐰': return '@drawable/ic_companion_rabbit';
    case '🐻': return '@drawable/ic_companion_bear';
    case '🦄': return '@drawable/ic_companion_unicorn';
    case '🐼': return '@drawable/ic_companion_panda';
    case '🦋': return '@drawable/ic_companion_butterfly';
    case '🌸': return '@drawable/ic_companion_bloom';
    case '🌙': return '@drawable/ic_companion_moon';
    case '⭐': return '@drawable/ic_companion_star';
    case '🌺': return '@drawable/ic_companion_rose';
    case '🐝': return '@drawable/ic_companion_bee';
    default:   return '@drawable/ic_luna_notif';
  }
}

// ── NotificationService ───────────────────────────────────────────────────────
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_luna_notif');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  // Request permission (Android 13+)
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  // Schedule or cancel all reminders
  Future<void> syncReminders(List<AppReminder> reminders, {String companionEmoji = '🌙', String companionName = 'Luna'}) async {
    await init();
    // Cancel all existing scheduled notifications
    await _plugin.cancelAll();
    // Re-schedule only enabled ones
    for (final r in reminders) {
      if (r.enabled && r.id != null) {
        await _scheduleReminder(r, companionEmoji: companionEmoji, companionName: companionName);
      }
    }
  }

  Future<void> scheduleOne(AppReminder reminder, {String companionEmoji = '🌙', String companionName = 'Luna'}) async {
    await init();
    if (!reminder.enabled || reminder.id == null) return;
    await _scheduleReminder(reminder);
  }

  Future<void> cancelOne(int reminderId) async {
    await init();
    // Each reminder uses a base notif ID = reminderId * 10
    // We cancel the base and a few offsets to be safe
    for (int i = 0; i < 10; i++) {
      await _plugin.cancel(reminderId * 10 + i);
    }
  }

  Future<void> _scheduleReminder(AppReminder reminder, {String companionEmoji = '🌙', String companionName = 'Luna'}) async {
    final parts = reminder.time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final message = _pickMessage(reminder);
    final notifId = reminder.id! * 10;
    final title = '$companionEmoji $companionName';

    final iconName = _companionIcon(companionEmoji);
    final androidDetails = AndroidNotificationDetails(
      'luna_reminders',
      'Luna Reminders',
      channelDescription: 'Reminders from your Luna companion',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(message),
      color: const Color(0xFFE57FA0), // LunaTheme.primary
      largeIcon: DrawableResourceAndroidBitmap(iconName),
      icon: iconName,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = tz.TZDateTime.now(tz.local);

    switch (reminder.type) {
      case 'daily':
        // Schedule repeating daily at given time
        var scheduledDate = tz.TZDateTime(
            tz.local, now.year, now.month, now.day, hour, minute);
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
        await _plugin.zonedSchedule(
          notifId,
          title,
          message,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // repeat daily
        );
        break;

      case 'weekly':
        // Schedule repeating weekly at given time
        var scheduledDate = tz.TZDateTime(
            tz.local, now.year, now.month, now.day, hour, minute);
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 7));
        }
        await _plugin.zonedSchedule(
          notifId,
          title,
          message,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        break;

      case 'one_time':
        // Schedule once at next occurrence of this time
        var scheduledDate = tz.TZDateTime(
            tz.local, now.year, now.month, now.day, hour, minute);
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
        await _plugin.zonedSchedule(
          notifId,
          title,
          message,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        break;
    }
  }
}
