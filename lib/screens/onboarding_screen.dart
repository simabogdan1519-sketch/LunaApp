import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_state.dart';
import '../theme/luna_theme.dart';
import 'main_scaffold.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;
  static const int _total = 4;

  final _nameCtrl = TextEditingController();
  int _cycleLen = 28;
  int _periodLen = 5;
  String _language = 'English';
  String _companion = '🐱';
  bool _saving = false;

  final _companions = [
    {'e': '🐱', 'n': 'Luna'}, {'e': '🦊', 'n': 'Foxy'}, {'e': '🐰', 'n': 'Bunny'},
    {'e': '🐻', 'n': 'Bear'}, {'e': '🦄', 'n': 'Star'}, {'e': '🐼', 'n': 'Panda'},
    {'e': '🦋', 'n': 'Flutter'}, {'e': '🌸', 'n': 'Bloom'}, {'e': '🌙', 'n': 'Moon'},
    {'e': '⭐', 'n': 'Stella'}, {'e': '🌺', 'n': 'Rose'}, {'e': '🐝', 'n': 'Bee'},
  ];
  final _langs = ['English', 'Română', 'Français', 'Deutsch', 'Español', 'Italiano', 'Português'];

  void _next() => setState(() => _page++);
  void _back() => setState(() => _page--);

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // 1. Save to SharedPreferences directly — most reliable
      final p = await SharedPreferences.getInstance();
      final name = _nameCtrl.text.trim().isEmpty ? 'Friend' : _nameCtrl.text.trim();
      final compName = _companions.firstWhere((c) => c['e'] == _companion, orElse: () => {'n': 'Luna'})['n']!;
      
      await p.setString('userName', name);
      await p.setInt('cycleLength', _cycleLen);
      await p.setInt('periodLength', _periodLen);
      await p.setString('language', _language);
      await p.setString('companionEmoji', _companion);
      await p.setString('companionName', compName);
      await p.setBool('contraEnabled', false);
      await p.setString('pillReminderTime', '08:00');
      await p.setBool('onboarded', true); // mark done BEFORE navigating

      // 2. Update the live AppState so UI reflects values immediately
      if (mounted) {
        final state = context.read<AppState>();
        state.userName = name;
        state.cycleLength = _cycleLen;
        state.periodLength = _periodLen;
        state.language = _language;
        state.companionEmoji = _companion;
        state.companionName = compName;
      }

      // 3. Navigate
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScaffold()));
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LunaTheme.surface,
      body: SafeArea(
        child: Column(children: [
          const SizedBox(height: 24),
          // Step dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_total, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _page ? 28 : 8, height: 8,
              decoration: BoxDecoration(
                color: i <= _page ? LunaTheme.primary : LunaTheme.surfaceV,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
          const SizedBox(height: 8),
          // Page
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: KeyedSubtree(key: ValueKey(_page), child: _buildPage()),
            ),
          ),
          // Nav buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
            child: Row(children: [
              if (_page > 0)
                TextButton(
                  onPressed: _back,
                  child: Text('← Back', style: GoogleFonts.nunito(color: LunaTheme.text2, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              const Spacer(),
              GestureDetector(
                onTap: _saving ? null : (_page < _total - 1 ? _next : _finish),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _saving ? [LunaTheme.text3, LunaTheme.text3] : [LunaTheme.primary, LunaTheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: LunaTheme.primary.withOpacity(.35), blurRadius: 14, offset: const Offset(0, 5))],
                  ),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          _page < _total - 1 ? 'Continue →' : 'Start! 🌙',
                          style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildPage() {
    switch (_page) {
      case 0: return _PageWelcome(ctrl: _nameCtrl);
      case 1: return _PageCycle(cycleLen: _cycleLen, periodLen: _periodLen,
          onCycle: (v) => setState(() => _cycleLen = v), onPeriod: (v) => setState(() => _periodLen = v));
      case 2: return _PageLang(selected: _language, langs: _langs, onSelect: (l) => setState(() => _language = l));
      case 3: return _PageCompanion(selected: _companion, companions: _companions, onSelect: (e) => setState(() => _companion = e));
      default: return const SizedBox();
    }
  }
}

class _PageWelcome extends StatelessWidget {
  final TextEditingController ctrl;
  const _PageWelcome({required this.ctrl});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
    child: Column(children: [
      const SizedBox(height: 8),
      Container(
        width: 110, height: 110,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [LunaTheme.primary, LunaTheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: LunaTheme.primary.withOpacity(.4), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: const Center(child: Text('🌙', style: TextStyle(fontSize: 52))),
      ),
      const SizedBox(height: 24),
      Text('Welcome to Luna', style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w900, color: LunaTheme.text)),
      const SizedBox(height: 6),
      Text('Your personal cycle companion', style: GoogleFonts.nunito(fontSize: 14, color: LunaTheme.text2)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        _Pill('🔒 Private'), _Pill('☁️ No cloud'), _Pill('🚫 No ads'),
      ]),
      const SizedBox(height: 32),
      TextField(
        controller: ctrl,
        decoration: const InputDecoration(hintText: "Your name (optional)", prefixIcon: Icon(Icons.person_outline, color: LunaTheme.primary)),
        textCapitalization: TextCapitalization.words,
        style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
      ),
    ]),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: LunaTheme.surfaceV, borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: LunaTheme.text2)),
  );
}

class _PageCycle extends StatelessWidget {
  final int cycleLen, periodLen;
  final ValueChanged<int> onCycle, onPeriod;
  const _PageCycle({required this.cycleLen, required this.periodLen, required this.onCycle, required this.onPeriod});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(height: 16),
      const Text('📅', style: TextStyle(fontSize: 60)),
      const SizedBox(height: 12),
      Text('Your cycle', style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w900, color: LunaTheme.text)),
      const SizedBox(height: 4),
      Text('Easy to change later in Settings', style: GoogleFonts.nunito(fontSize: 13, color: LunaTheme.text3)),
      const SizedBox(height: 28),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('🔄 Cycle length', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: LunaTheme.text)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: LunaTheme.primary.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
              child: Text('$cycleLen days', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.primary)),
            ),
          ]),
          Slider(value: cycleLen.toDouble(), min: 21, max: 35, divisions: 14, activeColor: LunaTheme.primary, onChanged: (v) => onCycle(v.round())),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('🩸 Period length', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: LunaTheme.text)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: LunaTheme.menstrual.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
              child: Text('$periodLen days', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.menstrual)),
            ),
          ]),
          Slider(value: periodLen.toDouble(), min: 2, max: 8, divisions: 6, activeColor: LunaTheme.menstrual, onChanged: (v) => onPeriod(v.round())),
        ]),
      ),
    ]),
  );
}

class _PageLang extends StatelessWidget {
  final String selected;
  final List<String> langs;
  final ValueChanged<String> onSelect;
  const _PageLang({required this.selected, required this.langs, required this.onSelect});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🌍', style: TextStyle(fontSize: 60)),
      const SizedBox(height: 12),
      Text('Choose language', style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w900, color: LunaTheme.text)),
      const SizedBox(height: 28),
      Wrap(
        spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
        children: langs.map((l) {
          final sel = l == selected;
          return GestureDetector(
            onTap: () => onSelect(l),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: sel ? LunaTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: sel ? LunaTheme.primary : LunaTheme.surfaceV),
                boxShadow: sel ? [BoxShadow(color: LunaTheme.primary.withOpacity(.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
              ),
              child: Text(l, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: sel ? Colors.white : LunaTheme.text, fontSize: 14)),
            ),
          );
        }).toList(),
      ),
    ]),
  );
}

class _PageCompanion extends StatelessWidget {
  final String selected;
  final List<Map<String, String>> companions;
  final ValueChanged<String> onSelect;
  const _PageCompanion({required this.selected, required this.companions, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    final sel = companions.firstWhere((c) => c['e'] == selected, orElse: () => {'e': selected, 'n': 'Luna'});
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(selected, key: ValueKey(selected), style: const TextStyle(fontSize: 64)),
        ),
        Text(sel['n'] ?? '', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: LunaTheme.primary)),
        const SizedBox(height: 4),
        Text('Pick your companion', style: GoogleFonts.nunito(fontSize: 14, color: LunaTheme.text2)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
          children: companions.map((c) {
            final isSel = c['e'] == selected;
            return GestureDetector(
              onTap: () => onSelect(c['e']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSel ? LunaTheme.primary.withOpacity(.12) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSel ? LunaTheme.primary : LunaTheme.surfaceV, width: isSel ? 2 : 1),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(c['e']!, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(c['n']!, style: GoogleFonts.nunito(fontSize: 10, color: isSel ? LunaTheme.primary : LunaTheme.text2, fontWeight: FontWeight.w700)),
                ]),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }
}
