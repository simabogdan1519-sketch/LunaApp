import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/app_state.dart';
import 'theme/luna_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Init AppState FIRST, wait for it to load prefs
  final appState = AppState();
  await appState.init();

  // Request all required permissions at startup
  try {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      // 1. Notifications (Android 13+)
      await android.requestNotificationsPermission();
      // 2. Exact alarms (Android 12+ / Samsung)
      final canExact = await android.canScheduleExactNotifications() ?? false;
      if (!canExact) await android.requestExactAlarmsPermission();
    }
  } catch (_) {}

  final prefs = await SharedPreferences.getInstance();
  final onboarded = prefs.getBool('onboarded') ?? false;

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: LunaApp(onboarded: onboarded),
    ),
  );
}

class LunaApp extends StatelessWidget {
  final bool onboarded;
  const LunaApp({super.key, required this.onboarded});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luna',
      debugShowCheckedModeBanner: false,
      theme: LunaTheme.theme,
      home: onboarded ? const MainScaffold() : const OnboardingScreen(),
    );
  }
}
