import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_state.dart';
import '../theme/luna_theme.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'log_screen.dart';
import 'journal_screen.dart';
import 'tips_screen.dart';
import 'history_screen.dart';
import 'contra_screen.dart';
import 'settings_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final tabs = [
      const HomeScreen(),
      const CalendarScreen(),
      const LogScreen(),
      const JournalScreen(),
      const TipsScreen(),
      const HistoryScreen(),
      if (state.contraEnabled) const ContraScreen(),
      const SettingsScreen(),
    ];

    final navItems = [
      const BottomNavigationBarItem(icon: Text('🏠', style: TextStyle(fontSize: 20)), label: 'Home'),
      const BottomNavigationBarItem(icon: Text('📅', style: TextStyle(fontSize: 20)), label: 'Calendar'),
      const BottomNavigationBarItem(icon: Text('💗', style: TextStyle(fontSize: 20)), label: 'Log'),
      const BottomNavigationBarItem(icon: Text('📝', style: TextStyle(fontSize: 20)), label: 'Journal'),
      const BottomNavigationBarItem(icon: Text('💡', style: TextStyle(fontSize: 20)), label: 'Tips'),
      const BottomNavigationBarItem(icon: Text('📊', style: TextStyle(fontSize: 20)), label: 'History'),
      if (state.contraEnabled) const BottomNavigationBarItem(icon: Text('💊', style: TextStyle(fontSize: 20)), label: 'Contra'),
      const BottomNavigationBarItem(icon: Text('👩', style: TextStyle(fontSize: 20)), label: 'Profile'),
    ];

    final safeIdx = _idx >= tabs.length ? 0 : _idx;

    return Scaffold(
      body: tabs[safeIdx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIdx,
        onTap: (i) => setState(() => _idx = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: LunaTheme.primary,
        unselectedItemColor: LunaTheme.text3,
        selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 10),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 10),
        items: navItems,
      ),
    );
  }
}
