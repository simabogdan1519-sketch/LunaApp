import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../services/cycle_calculator.dart';
import '../theme/luna_theme.dart';
import '../models/models.dart';

class ContraScreen extends StatefulWidget {
  const ContraScreen({super.key});
  @override
  State<ContraScreen> createState() => _ContraScreenState();
}

class _ContraScreenState extends State<ContraScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LunaTheme.surface,
      appBar: AppBar(
        title: Text('💊 Contraceptive', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text)),
        bottom: TabBar(
          controller: _tabs,
          labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800),
          labelColor: LunaTheme.primary,
          unselectedLabelColor: LunaTheme.text3,
          indicatorColor: LunaTheme.primary,
          tabs: const [Tab(text: 'Today'), Tab(text: 'Brands'), Tab(text: 'Tips')],
        ),
      ),
      body: TabBarView(controller: _tabs, children: const [_TodayTab(), _BrandsTab(), _TipsTab()]),
    );
  }
}

class _TodayTab extends StatelessWidget {
  const _TodayTab();
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final takenToday = state.isPillTakenToday();
    final streak = state.pillStreak;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [LunaTheme.primary, LunaTheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(children: [
            Text(takenToday ? '✅' : '💊', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(takenToday ? 'Taken today!' : 'Take your pill', style: GoogleFonts.nunito(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('Scheduled: ${state.pillReminderTime}', style: GoogleFonts.nunito(color: Colors.white.withOpacity(.8), fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: GestureDetector(
                  onTap: () => state.logPill(DateTime.now(), true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Text('✅ Taken', style: GoogleFonts.nunito(color: LunaTheme.primary, fontWeight: FontWeight.w800))),
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: () => state.logPill(DateTime.now(), false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(.2), borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Text('❌ Missed', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800))),
                  ),
                )),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _StatMini(value: '🔥 $streak', label: 'day streak', color: LunaTheme.ovulation)),
          const SizedBox(width: 10),
          Expanded(child: _StatMini(value: '${CycleCalculator.calcAdherence(state.pillLogs, 30).round()}%', label: 'this month', color: LunaTheme.follicular)),
        ]),
        const SizedBox(height: 16),
        Text('Last 7 days', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text)),
        const SizedBox(height: 8),
        _MiniCalendar(pillLogs: state.pillLogs),
      ],
    );
  }
}

class _StatMini extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatMini({required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text(value, style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: color, fontSize: 18)),
        Text(label, style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 11)),
      ]),
    );
  }
}

class _MiniCalendar extends StatelessWidget {
  final List<PillLog> pillLogs;
  const _MiniCalendar({required this.pillLogs});
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final d = today.subtract(Duration(days: 6 - i));
        final dStr = d.toIso8601String().split('T')[0];
        final log = pillLogs.where((l) => l.date.toIso8601String().split('T')[0] == dStr).firstOrNull;
        Color bg = LunaTheme.surfaceV;
        if (log != null) bg = log.taken ? LunaTheme.follicular.withOpacity(.3) : LunaTheme.menstrual.withOpacity(.3);
        return Column(children: [
          Text(DateFormat('E').format(d).substring(0, 1), style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 10)),
          const SizedBox(height: 4),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Center(child: Text(log == null ? '?' : log.taken ? '✅' : '❌', style: const TextStyle(fontSize: 14))),
          ),
          Text('${d.day}', style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 10)),
        ]);
      }),
    );
  }
}

class _BrandsTab extends StatefulWidget {
  const _BrandsTab();
  @override
  State<_BrandsTab> createState() => _BrandsTabState();
}

class _BrandsTabState extends State<_BrandsTab> {
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'Combined pill';
  int _rating = 3;
  bool _showForm = false;

  final List<String> _types = ['Combined pill', 'Mini pill', 'IUD copper', 'IUD hormonal', 'Implant', 'Patch', 'Ring', 'Injection', 'Condom', 'Other'];
  final List<String> _sideEffects = ['Nausea 🤢', 'Headaches 🤯', 'Mood changes 🎭', 'Weight change ⚖️', 'Spotting 🩸', 'Decreased libido 💔', 'Breast tenderness 💗', 'None ✨'];
  final Set<String> _selectedEffects = {};

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    await context.read<AppState>().addBrand(ContraceptiveBrand(
      name: _nameCtrl.text,
      type: _type,
      startDate: DateTime.now(),
      rating: _rating,
      notes: [_notesCtrl.text, ..._selectedEffects].where((s) => s.isNotEmpty).join(', '),
    ));
    _nameCtrl.clear(); _notesCtrl.clear();
    setState(() { _rating = 3; _selectedEffects.clear(); _showForm = false; });
  }

  @override
  Widget build(BuildContext context) {
    final brands = context.watch<AppState>().contraBrands;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(onPressed: () => setState(() => _showForm = !_showForm), icon: Icon(_showForm ? Icons.close : Icons.add), label: Text(_showForm ? 'Cancel' : 'Log new brand')),
        const SizedBox(height: 12),
        if (_showForm) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Brand name (e.g. Yasmin)')),
                const SizedBox(height: 12),
                Text('Type', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: LunaTheme.text2, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _types.map((t) {
                    final on = _type == t;
                    return GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: on ? LunaTheme.primary : LunaTheme.surfaceV,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(t, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: on ? Colors.white : LunaTheme.text2)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text('Rating: ${'⭐' * _rating}${'☆' * (5 - _rating)}', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: LunaTheme.text2, fontSize: 13)),
                Slider(value: _rating.toDouble(), min: 1, max: 5, divisions: 4, activeColor: LunaTheme.ovulation, onChanged: (v) => setState(() => _rating = v.round())),
                const SizedBox(height: 8),
                Text('Side effects', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: LunaTheme.text2, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _sideEffects.map((s) {
                    final on = _selectedEffects.contains(s);
                    return GestureDetector(
                      onTap: () => setState(() => on ? _selectedEffects.remove(s) : _selectedEffects.add(s)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: on ? LunaTheme.primary : LunaTheme.surfaceV,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(s, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: on ? Colors.white : LunaTheme.text2)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(controller: _notesCtrl, decoration: const InputDecoration(hintText: 'Additional notes'), maxLines: 2),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('Save brand'))),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (brands.isEmpty) Center(child: Padding(padding: const EdgeInsets.only(top: 40), child: Text('No brands logged yet', style: GoogleFonts.nunito(color: LunaTheme.text2)))),
        ...brands.map((b) => _BrandCard(brand: b)),
      ],
    );
  }
}

class _BrandCard extends StatelessWidget {
  final ContraceptiveBrand brand;
  const _BrandCard({required this.brand});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('brand_${brand.id}'),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.delete, color: Colors.white)),
      onDismissed: (_) { if (brand.id != null) context.read<AppState>().deleteBrand(brand.id!); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(brand.name, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 15))),
              Text('${'⭐' * brand.rating}${'☆' * (5 - brand.rating)}', style: const TextStyle(fontSize: 12)),
            ]),
            const SizedBox(height: 4),
            Text(brand.type, style: GoogleFonts.nunito(color: LunaTheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
            Text('Started: ${DateFormat('MMM d, yyyy').format(brand.startDate)}', style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 11)),
            if (brand.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(brand.notes, style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}

class _TipsTab extends StatelessWidget {
  const _TipsTab();
  static const _tips = [
    {'icon': '💊', 'title': 'Take at the same time daily', 'body': 'Taking the pill at the same time every day is crucial for effectiveness. Set a daily alarm as a reminder.'},
    {'icon': '🚫', 'title': 'Common interactions', 'body': 'Certain antibiotics (rifampicin), anticonvulsants, and St. John\'s Wort can reduce pill effectiveness. Always tell your doctor.'},
    {'icon': '🤒', 'title': 'If you vomit or have diarrhea', 'body': 'Vomiting within 2 hours of taking your pill means it may not have been absorbed. Take another one (NHS guidelines).'},
    {'icon': '⏰', 'title': 'Missed pill rules', 'body': 'Combined pill: <24h late = take it now, no extra protection needed. >24h late = take it, use condoms 7 days (NHS).'},
    {'icon': '🩺', 'title': 'Annual check-ups', 'body': 'Annual blood pressure checks are recommended for all pill users. Tell your GP about any new symptoms (ACOG).'},
    {'icon': '✨', 'title': 'Non-contraceptive benefits', 'body': 'Hormonal contraceptives can reduce acne, regulate periods, ease endometriosis and PCOS symptoms.'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _tips.map((t) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t['icon']!, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['title']!, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 14)),
                const SizedBox(height: 4),
                Text(t['body']!, style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 12, height: 1.5)),
              ],
            )),
          ],
        ),
      )).toList(),
    );
  }
}
