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
  int _selectedIdx = 0;

  List<_TabDef> _buildTabs(bool contra) => [
    _TabDef('🏠', 'Home',      const HomeScreen()),
    _TabDef('📅', 'Calendar',  const CalendarScreen()),
    if (contra) _TabDef('💊', 'Contra', const ContraScreen()),
    _TabDef('📊', 'History',   const HistoryScreen()),
    _TabDef('💡', 'Tips',      const TipsScreen()),
    _TabDef('💗', 'Log',       const LogScreen()),
    _TabDef('📝', 'Journal',   const JournalScreen()),
    _TabDef('🩺', 'Medical',   const MedicalScreen()),
    _TabDef('🔔', 'Reminders', const RemindersScreen()),
    _TabDef('👩', 'Profile',   const SettingsScreen()),
  ];

  bool _prevContra = false;

  void _select(int i) {
    if (i == _selectedIdx) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedIdx = i);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // When contra gets enabled, jump to its tab
    if (state.contraEnabled && !_prevContra) {
      _prevContra = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final tabs = _buildTabs(true);
          final contraIdx = tabs.indexWhere((t) => t.label == 'Contra');
          if (contraIdx != -1) setState(() => _selectedIdx = contraIdx);
        }
      });
    } else if (!state.contraEnabled) {
      _prevContra = false;
    }
    final tabs = _buildTabs(state.contraEnabled);
    final safeIdx = _selectedIdx.clamp(0, tabs.length - 1);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        child: KeyedSubtree(
          key: ValueKey(safeIdx),
          child: tabs[safeIdx].screen,
        ),
      ),
      bottomNavigationBar: _ScrollableNavBar(
        tabs: tabs,
        selectedIdx: safeIdx,
        onSelect: _select,
      ),
    );
  }
}

// ── Scrollable nav bar ────────────────────────────────────────────────────────
class _ScrollableNavBar extends StatefulWidget {
  final List<_TabDef> tabs;
  final int selectedIdx;
  final ValueChanged<int> onSelect;

  const _ScrollableNavBar({
    required this.tabs,
    required this.selectedIdx,
    required this.onSelect,
  });

  @override
  State<_ScrollableNavBar> createState() => _ScrollableNavBarState();
}

class _ScrollableNavBarState extends State<_ScrollableNavBar> {
  late final ScrollController _scrollCtrl;

  // Width of each tab item
  static const double _itemW = 72.0;
  static const double _itemH = 62.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ScrollableNavBar old) {
    super.didUpdateWidget(old);
    // Smoothly scroll selected item into center view
    if (widget.selectedIdx != old.selectedIdx) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  void _scrollToSelected() {
    if (!_scrollCtrl.hasClients) return;
    final screenW = _scrollCtrl.position.viewportDimension;
    final targetOffset = widget.selectedIdx * _itemW - screenW / 2 + _itemW / 2;
    _scrollCtrl.animateTo(
      targetOffset.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      height: _itemH + bottomPad + 1,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: LunaTheme.primary.withOpacity(.10),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top border line
          Container(height: 0.8, color: LunaTheme.primary.withOpacity(.12)),

          // Scrollable row of tabs
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: bottomPad),
              itemCount: widget.tabs.length,
              itemBuilder: (_, i) {
                final tab = widget.tabs[i];
                final active = i == widget.selectedIdx;
                return GestureDetector(
                  onTap: () => widget.onSelect(i),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: _itemW,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with animated pill bg
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          padding: EdgeInsets.symmetric(
                            horizontal: active ? 14 : 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? LunaTheme.primary.withOpacity(.14)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            tab.emoji,
                            style: TextStyle(fontSize: active ? 24 : 21),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Label
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                            color: active ? LunaTheme.primary : LunaTheme.text3,
                          ),
                          child: Text(tab.label, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
