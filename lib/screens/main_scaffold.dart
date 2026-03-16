import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'medical_screen.dart';
import 'reminders_screen.dart';
import 'contra_screen.dart';
import 'settings_screen.dart';

class _TabDef {
  final String emoji, label;
  final Widget Function() build;
  const _TabDef(this.emoji, this.label, this.build);
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _groupIdx = 0;
  int _tabIdx   = 0;

  late PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  List<List<_TabDef>> _buildGroups(bool contra) => [
    [
      _TabDef('🏠', 'Home',     () => const HomeScreen()),
      _TabDef('💗', 'Log',      () => const LogScreen()),
      _TabDef('📅', 'Calendar', () => const CalendarScreen()),
      _TabDef('📝', 'Journal',  () => const JournalScreen()),
    ],
    [
      _TabDef('💡', 'Tips',      () => const TipsScreen()),
      _TabDef('📊', 'History',   () => const HistoryScreen()),
      _TabDef('🩺', 'Medical',   () => const MedicalScreen()),
      _TabDef('🔔', 'Reminders', () => const RemindersScreen()),
    ],
    [
      if (contra) _TabDef('💊', 'Contra',  () => const ContraScreen()),
      _TabDef('👩', 'Profile',  () => const SettingsScreen()),
    ],
  ];

  void _onNavTap(int tabInGroup) {
    HapticFeedback.lightImpact();
    setState(() => _tabIdx = tabInGroup);
  }

  void _onGroupChanged(int g) {
    HapticFeedback.lightImpact();
    setState(() { _groupIdx = g; _tabIdx = 0; });
  }

  void _jumpToGroup(int g) {
    _pageCtrl.animateToPage(g, duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final groups = _buildGroups(state.contraEnabled).where((g) => g.isNotEmpty).toList();
    final safeG = _groupIdx.clamp(0, groups.length - 1);
    final group = groups[safeG];
    final safeT = _tabIdx.clamp(0, group.length - 1);

    return Scaffold(
      body: PageView.builder(
        controller: _pageCtrl,
        onPageChanged: _onGroupChanged,
        itemCount: groups.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (_, gi) {
          // Each page shows the currently selected tab for that group
          final g = groups[gi];
          final t = (gi == safeG ? safeT : 0).clamp(0, g.length - 1);
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey('$gi-$t'),
              child: g[t].build(),
            ),
          );
        },
      ),
      bottomNavigationBar: _LunaNavBar(
        groups: groups,
        currentGroup: safeG,
        currentTab: safeT,
        onTabTap: _onNavTap,
        onDotTap: _jumpToGroup,
      ),
    );
  }
}

// ── Custom bottom nav ──────────────────────────────────────────────────────────
class _LunaNavBar extends StatelessWidget {
  final List<List<_TabDef>> groups;
  final int currentGroup, currentTab;
  final ValueChanged<int> onTabTap, onDotTap;
  const _LunaNavBar({required this.groups, required this.currentGroup, required this.currentTab, required this.onTabTap, required this.onDotTap});

  @override
  Widget build(BuildContext context) {
    final group = groups[currentGroup];
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: LunaTheme.primary.withOpacity(.08), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Swipe dots ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Left group label hint
                _SwipeHint(show: currentGroup > 0, direction: 'left'),
                const SizedBox(width: 8),
                ...groups.asMap().entries.map((e) {
                  final active = e.key == currentGroup;
                  return GestureDetector(
                    onTap: () => onDotTap(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active ? LunaTheme.primary : LunaTheme.primary.withOpacity(.22),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                _SwipeHint(show: currentGroup < groups.length - 1, direction: 'right'),
              ],
            ),
          ),

          // ── Tab row ───────────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(4, 2, 4, bottomPad + 6),
            child: Row(
              children: group.asMap().entries.map((e) {
                final active = e.key == currentTab;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTabTap(e.key),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: EdgeInsets.symmetric(horizontal: active ? 16 : 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: active ? LunaTheme.primary.withOpacity(.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(e.value.emoji, style: TextStyle(fontSize: active ? 23 : 20)),
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.nunito(
                            fontSize: 10.5,
                            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                            color: active ? LunaTheme.primary : LunaTheme.text3,
                          ),
                          child: Text(e.value.label),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Tiny animated arrow hint showing swipe direction
class _SwipeHint extends StatelessWidget {
  final bool show;
  final String direction;
  const _SwipeHint({required this.show, required this.direction});
  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    duration: const Duration(milliseconds: 250),
    opacity: show ? 0.35 : 0,
    child: Icon(
      direction == 'left' ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
      color: LunaTheme.primary,
      size: 16,
    ),
  );
}
