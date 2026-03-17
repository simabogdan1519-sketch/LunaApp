import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';

// Top-level callback required by WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // Show the notification immediately when WorkManager fires
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ));
      await plugin.show(
        inputData?['id'] as int? ?? 0,
        inputData?['title'] as String? ?? '🌸 Luna',
        inputData?['body'] as String? ?? 'Reminder de la Luna 💜',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'luna_reminders',
            'Luna Reminders',
            channelDescription: 'Reminders from your Luna companion',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
        ),
      );
    } catch (e) {
      // ignore
    }
    return Future.value(true);
  });
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _p = FlutterLocalNotificationsPlugin();

  Future<void> init(String tzName) async {
    await _p.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (_) {},
    );
    await _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'luna_reminders',
          'Luna Reminders',
          description: 'Reminders from your Luna companion',
          importance: Importance.high,
          playSound: true,
        ));
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  // Calculate seconds until next occurrence of HH:mm
  int _secondsUntil(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = DateTime.now();
    var fire = DateTime(now.year, now.month, now.day, hour, minute);
    if (!fire.isAfter(now)) fire = fire.add(const Duration(days: 1));
    return fire.difference(now).inSeconds;
  }

  Future<void> syncReminders(List<AppReminder> reminders, String tzName,
      {String emoji = '🌸', String name = 'Luna'}) async {
    // Cancel all existing WorkManager tasks
    await Workmanager().cancelAll();

    for (final r in reminders) {
      if (!r.enabled) continue;

      final delay = _secondsUntil(r.time);
      final title = '$emoji $name';
      final body = r.title;

      // Schedule with WorkManager - registers a periodic daily task
      // with an initial delay calculated to fire at the right time
      await Workmanager().registerPeriodicTask(
        'reminder_${r.id}',
        'luna_reminder',
        frequency: const Duration(hours: 24),
        initialDelay: Duration(seconds: delay),
        inputData: {
          'id': r.id.hashCode,
          'title': title,
          'body': body,
        },
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 1),
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

  Future<bool> hasPermission(String tzName) async {
    final android = _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  Future<void> requestPermission(String tzName) async {
    final android = _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  // Debug: returns info about next scheduled reminder
  Future<String> debugSchedule(AppReminder r, String tzName) async {
    final delay = _secondsUntil(r.time);
    final hours = delay ~/ 3600;
    final mins = (delay % 3600) ~/ 60;
    final now = DateTime.now();
    final fire = now.add(Duration(seconds: delay));
    return 'WorkManager task\nnow=$now\nfire=$fire\nin ${hours}h ${mins}m';
  }
}
