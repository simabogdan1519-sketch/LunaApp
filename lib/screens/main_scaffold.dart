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
  final Widget screen;
  const _TabDef(this.emoji, this.label, this.screen);
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _groupIdx = 0;
  int _tabIdx   = 0;

  List<List<_TabDef>> _buildGroups(bool contra) => [
    [
      _TabDef('🏠', 'Home',     const HomeScreen()),
      _TabDef('💗', 'Log',      const LogScreen()),
      _TabDef('📅', 'Calendar', const CalendarScreen()),
      _TabDef('📝', 'Journal',  const JournalScreen()),
    ],
    [
      _TabDef('💡', 'Tips',      const TipsScreen()),
      _TabDef('📊', 'History',   const HistoryScreen()),
      _TabDef('🩺', 'Medical',   const MedicalScreen()),
      _TabDef('🔔', 'Reminders', const RemindersScreen()),
    ],
    [
      if (contra) _TabDef('💊', 'Contra', const ContraScreen()),
      _TabDef('👩', 'Profile', const SettingsScreen()),
    ],
  ];

  void _goToGroup(int g, List<List<_TabDef>> groups) {
    final clamped = g.clamp(0, groups.length - 1);
    if (clamped == _groupIdx) return;
    HapticFeedback.lightImpact();
    setState(() { _groupIdx = clamped; _tabIdx = 0; });
  }

  void _onTabTap(int t) {
    HapticFeedback.lightImpact();
    setState(() => _tabIdx = t);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final groups = _buildGroups(state.contraEnabled)
        .where((g) => g.isNotEmpty).toList();
    final safeG = _groupIdx.clamp(0, groups.length - 1);
    final group  = groups[safeG];
    final safeT  = _tabIdx.clamp(0, group.length - 1);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        child: KeyedSubtree(
          key: ValueKey('$safeG-$safeT'),
          child: group[safeT].screen,
        ),
      ),
      bottomNavigationBar: _LunaNavBar(
        groups: groups,
        currentGroup: safeG,
        currentTab: safeT,
        onTabTap: _onTabTap,
        onSwipe: (dir) => _goToGroup(safeG + dir, groups),
        onDotTap: (g) {
          HapticFeedback.lightImpact();
          setState(() { _groupIdx = g; _tabIdx = 0; });
        },
      ),
    );
  }
}

// ── Nav bar cu swipe ──────────────────────────────────────────────────────────
class _LunaNavBar extends StatefulWidget {
  final List<List<_TabDef>> groups;
  final int currentGroup, currentTab;
  final ValueChanged<int> onTabTap, onDotTap;
  final ValueChanged<int> onSwipe; // -1 left, +1 right

  const _LunaNavBar({
    required this.groups,
    required this.currentGroup,
    required this.currentTab,
    required this.onTabTap,
    required this.onDotTap,
    required this.onSwipe,
  });

  @override
  State<_LunaNavBar> createState() => _LunaNavBarState();
}

class _LunaNavBarState extends State<_LunaNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  int _lastGroup = 0;

  @override
  void initState() {
    super.initState();
    _lastGroup = widget.currentGroup;
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slideAnim = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_LunaNavBar old) {
    super.didUpdateWidget(old);
    if (widget.currentGroup != old.currentGroup) {
      // Animate icons sliding in from correct direction
      final dir = widget.currentGroup > old.currentGroup ? 1.0 : -1.0;
      _slideAnim = Tween<Offset>(
        begin: Offset(dir * 0.35, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
      _slideCtrl.forward(from: 0);
      _lastGroup = widget.currentGroup;
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  static const double _kVelocityThreshold = 200;

  @override
  Widget build(BuildContext context) {
    final group    = widget.groups[widget.currentGroup];
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final vx = d.velocity.pixelsPerSecond.dx;
        if (vx.abs() > _kVelocityThreshold) {
          // swipe right (vx > 0) → previous group (-1)
          // swipe left  (vx < 0) → next group    (+1)
          widget.onSwipe(vx < 0 ? 1 : -1);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: LunaTheme.primary.withOpacity(.10),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Group dots ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // left chevron
                  _Chevron(
                    visible: widget.currentGroup > 0,
                    left: true,
                    onTap: () => widget.onSwipe(-1),
                  ),
                  const SizedBox(width: 6),
                  ...widget.groups.asMap().entries.map((e) {
                    final active = e.key == widget.currentGroup;
                    return GestureDetector(
                      onTap: () => widget.onDotTap(e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active
                              ? LunaTheme.primary
                              : LunaTheme.primary.withOpacity(.22),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 6),
                  // right chevron
                  _Chevron(
                    visible: widget.currentGroup < widget.groups.length - 1,
                    left: false,
                    onTap: () => widget.onSwipe(1),
                  ),
                ],
              ),
            ),

            // ── Tab icons — animate in on group change ──────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(4, 4, 4, bottomPad + 6),
              child: SlideTransition(
                position: _slideAnim,
                child: Row(
                  children: group.asMap().entries.map((e) {
                    final active = e.key == widget.currentTab;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onTabTap(e.key),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: EdgeInsets.symmetric(
                                horizontal: active ? 16 : 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? LunaTheme.primary.withOpacity(.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                e.value.emoji,
                                style: TextStyle(fontSize: active ? 23 : 20),
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: GoogleFonts.nunito(
                                fontSize: 10.5,
                                fontWeight: active
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: active
                                    ? LunaTheme.primary
                                    : LunaTheme.text3,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  final bool visible, left;
  final VoidCallback onTap;
  const _Chevron({required this.visible, required this.left, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: visible ? 0.45 : 0,
      child: Icon(
        left ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
        color: LunaTheme.primary,
        size: 18,
      ),
    ),
  );
}
