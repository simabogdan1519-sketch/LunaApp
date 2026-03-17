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

// ── Today Tab ─────────────────────────────────────────────────────────────────
class _TodayTab extends StatelessWidget {
  const _TodayTab();

  void _showBackfillSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BackfillSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final takenToday = state.isPillTakenToday();
    final streak = state.pillStreak;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Main card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [LunaTheme.primary, LunaTheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(children: [
            Text(takenToday ? '✅' : '💊', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(takenToday ? 'Taken today!' : 'Take your pill',
                style: GoogleFonts.nunito(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('Scheduled: ${state.pillReminderTime}',
                style: GoogleFonts.nunito(color: Colors.white.withOpacity(.8), fontSize: 13)),
            const SizedBox(height: 16),
            Row(children: [
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
            ]),
          ]),
        ),
        const SizedBox(height: 12),

        // Backfill button
        GestureDetector(
          onTap: () => _showBackfillSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: LunaTheme.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: LunaTheme.primary.withOpacity(.2)),
            ),
            child: Row(children: [
              const Text('📅', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Adaugă zile din trecut', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 13)),
                Text('Ai uitat să loghezi? Adaugă rapid', style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 11)),
              ])),
              Icon(Icons.chevron_right, color: LunaTheme.primary, size: 20),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Stats
        Row(children: [
          Expanded(child: _StatMini(value: '🔥 $streak', label: 'day streak', color: LunaTheme.ovulation)),
          const SizedBox(width: 10),
          Expanded(child: _StatMini(
            value: '${CycleCalculator.calcAdherence(state.pillLogs, 30).round()}%',
            label: 'this month',
            color: LunaTheme.follicular,
          )),
        ]),
        const SizedBox(height: 16),
        Text('Last 30 days', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text)),
        const SizedBox(height: 8),
        _FullCalendar(pillLogs: state.pillLogs),
      ],
    );
  }
}

// ── Backfill Sheet ────────────────────────────────────────────────────────────
class _BackfillSheet extends StatefulWidget {
  const _BackfillSheet();
  @override
  State<_BackfillSheet> createState() => _BackfillSheetState();
}

class _BackfillSheetState extends State<_BackfillSheet> {
  // day offset → null=unknown, true=taken, false=missed
  final Map<int, bool> _status = {};

  @override
  void initState() {
    super.initState();
    // Pre-fill from existing logs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final logs = context.read<AppState>().pillLogs;
      final today = DateTime.now();
      for (int i = 1; i <= 30; i++) {
        final d = today.subtract(Duration(days: i));
        final dStr = d.toIso8601String().split('T')[0];
        final log = logs.where((l) => l.date.toIso8601String().split('T')[0] == dStr).firstOrNull;
        if (log != null) setState(() => _status[i] = log.taken);
      }
    });
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final today = DateTime.now();
    for (final entry in _status.entries) {
      final date = today.subtract(Duration(days: entry.key));
      await state.logPill(date, entry.value);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20, left: 20, right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('📅 Adaugă zile din trecut', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text, fontSize: 18)),
          Text('Apasă pe fiecare zi pentru a marca dacă ai luat pastila',
              style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 340,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 6, childAspectRatio: 0.75,
              ),
              itemCount: 30,
              itemBuilder: (ctx, i) {
                final offset = 30 - i; // 30 days ago ... 1 day ago
                final d = today.subtract(Duration(days: offset));
                final status = _status[offset];
                Color bg;
                String emoji;
                if (status == null) { bg = LunaTheme.surfaceV; emoji = '?'; }
                else if (status) { bg = LunaTheme.follicular.withOpacity(.25); emoji = '✅'; }
                else { bg = LunaTheme.menstrual.withOpacity(.2); emoji = '❌'; }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (status == null) _status[offset] = true;
                      else if (status) _status[offset] = false;
                      else _status.remove(offset);
                    });
                  },
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(DateFormat('E').format(d).substring(0, 1),
                        style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 9)),
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 13))),
                    ),
                    Text('${d.day}', style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 9)),
                  ]),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _Legend(color: LunaTheme.follicular.withOpacity(.25), label: '✅ Luat'),
            const SizedBox(width: 16),
            _Legend(color: LunaTheme.menstrual.withOpacity(.2), label: '❌ Sărit'),
            const SizedBox(width: 16),
            _Legend(color: LunaTheme.surfaceV, label: '? Necunoscut'),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: LunaTheme.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _save,
              child: Text('Salvează', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 10)),
  ]);
}

// ── Stats helpers ─────────────────────────────────────────────────────────────
class _StatMini extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatMini({required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      Text(value, style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: color, fontSize: 18)),
      Text(label, style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 11)),
    ]),
  );
}

// ── Full 30-day calendar grid ─────────────────────────────────────────────────
class _FullCalendar extends StatelessWidget {
  final List<PillLog> pillLogs;
  const _FullCalendar({required this.pillLogs});
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 4, childAspectRatio: 0.75,
      ),
      itemCount: 30,
      itemBuilder: (ctx, i) {
        final offset = 29 - i;
        final d = today.subtract(Duration(days: offset));
        final dStr = d.toIso8601String().split('T')[0];
        final log = pillLogs.where((l) => l.date.toIso8601String().split('T')[0] == dStr).firstOrNull;
        Color bg = LunaTheme.surfaceV;
        if (log != null) bg = log.taken ? LunaTheme.follicular.withOpacity(.25) : LunaTheme.menstrual.withOpacity(.2);
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Text(DateFormat('E').format(d).substring(0, 1),
              style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 9)),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Center(child: Text(log == null ? '·' : log.taken ? '✅' : '❌',
                style: TextStyle(fontSize: log == null ? 16 : 12))),
          ),
          Text('${d.day}', style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 9)),
        ]);
      },
    );
  }
}

// ── Brands Tab ────────────────────────────────────────────────────────────────
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
      name: _nameCtrl.text, type: _type, startDate: DateTime.now(), rating: _rating,
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Brand name (e.g. Yasmin)')),
              const SizedBox(height: 12),
              Text('Type', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: LunaTheme.text2, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _types.map((t) {
                final on = _type == t;
                return GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: on ? LunaTheme.primary : LunaTheme.surfaceV, borderRadius: BorderRadius.circular(20)),
                    child: Text(t, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: on ? Colors.white : LunaTheme.text2)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 12),
              Text('Rating: ${'⭐' * _rating}${'☆' * (5 - _rating)}', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: LunaTheme.text2, fontSize: 13)),
              Slider(value: _rating.toDouble(), min: 1, max: 5, divisions: 4, activeColor: LunaTheme.ovulation, onChanged: (v) => setState(() => _rating = v.round())),
              const SizedBox(height: 8),
              Text('Side effects', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: LunaTheme.text2, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _sideEffects.map((s) {
                final on = _selectedEffects.contains(s);
                return GestureDetector(
                  onTap: () => setState(() => on ? _selectedEffects.remove(s) : _selectedEffects.add(s)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: on ? LunaTheme.primary : LunaTheme.surfaceV, borderRadius: BorderRadius.circular(20)),
                    child: Text(s, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: on ? Colors.white : LunaTheme.text2)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 12),
              TextField(controller: _notesCtrl, decoration: const InputDecoration(hintText: 'Additional notes'), maxLines: 2),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('Save brand'))),
            ]),
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
  Widget build(BuildContext context) => Dismissible(
    key: Key('brand_${brand.id}'),
    direction: DismissDirection.endToStart,
    background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.delete, color: Colors.white)),
    onDismissed: (_) { if (brand.id != null) context.read<AppState>().deleteBrand(brand.id!); },
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
      ]),
    ),
  );
}

// ── Tips Tab ──────────────────────────────────────────────────────────────────
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
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: _tips.map((t) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t['icon']!, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t['title']!, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 14)),
          const SizedBox(height: 4),
          Text(t['body']!, style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 12, height: 1.5)),
        ])),
      ]),
    )).toList(),
  );
}
