import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../theme/luna_theme.dart';
import '../models/models.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: LunaTheme.surface,
      appBar: AppBar(
        title: Text('📊 History & Charts', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showAddCycleDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: LunaTheme.primary, borderRadius: BorderRadius.circular(14)),
                child: Text('+ Cycle', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
      body: state.cycles.isEmpty
          ? _EmptyState(onAdd: () => _showAddCycleDialog(context))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _CycleStatsCard(cycles: state.cycles),
                const SizedBox(height: 16),
                _CycleLengthChart(cycles: state.cycles),
                const SizedBox(height: 16),
                _PeriodLengthChart(cycles: state.cycles),
                const SizedBox(height: 16),
                _PastCyclesList(cycles: state.cycles, onDelete: (id) => state.deleteCycle(id), onEdit: (c) => _showEditCycleDialog(context, c), onAdd: () => _showAddCycleDialog(context)),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  void _showEditCycleDialog(BuildContext context, CycleEntry cycle) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppState>(),
        child: _AddCycleSheet(editing: cycle),
      ),
    );
  }

  void _showAddCycleDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppState>(),
        child: _AddCycleSheet(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('📊', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 12),
      Text('No cycles yet', style: GoogleFonts.nunito(color: LunaTheme.text, fontWeight: FontWeight.w800, fontSize: 18)),
      const SizedBox(height: 6),
      Text('Add past cycles to see stats & charts', style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 13)),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [LunaTheme.primary, LunaTheme.secondary]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text('+ Add a past cycle', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
        ),
      ),
    ],
  ));
}

// ── Add Cycle Bottom Sheet ────────────────────────────────────────────────────
class _AddCycleSheet extends StatefulWidget {
  final CycleEntry? editing;
  const _AddCycleSheet({this.editing});
  @override
  State<_AddCycleSheet> createState() => _AddCycleSheetState();
}

class _AddCycleSheetState extends State<_AddCycleSheet> {
  DateTime? _start, _end;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _start = widget.editing!.startDate;
      _end   = widget.editing!.endDate;
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (now.subtract(const Duration(days: 30))) : (_start ?? now),
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: LunaTheme.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isStart ? _start = picked : _end = picked);
  }

  Future<void> _save() async {
    if (_start == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick a start date')));
      return;
    }
    if (_end != null && !_end!.isAfter(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End date must be after start date')));
      return;
    }
    setState(() => _saving = true);
    if (widget.editing != null) {
      // When editing: period end = _end, cycle length from user settings
      final state = context.read<AppState>();
      final bleedingDays = _end != null
          ? _end!.difference(_start!).inDays.clamp(1, 14)
          : widget.editing!.periodLength;
      final updated = CycleEntry(
        id: widget.editing!.id,
        startDate: _start!,
        endDate: _end,
        cycleLength: state.cycleLength,  // use current user setting
        periodLength: bleedingDays,
      );
      await state.updateCycle(updated);
    } else {
      await context.read<AppState>().addPastCycle(_start!, _end);
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.editing != null ? 'Cycle updated! 💜' : 'Cycle added! 💜',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: LunaTheme.primary,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    final hasStart = _start != null;
    final hasEnd = _end != null;
    final days = (hasStart && hasEnd) ? _end!.difference(_start!).inDays : null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: LunaTheme.surfaceV, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Add past cycle', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: LunaTheme.text)),
          const SizedBox(height: 6),
          Text('Pick when your period started. End date is optional — if left empty, your default period length will be used.', style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 13)),
          const SizedBox(height: 24),
          // Start date
          _DatePickerRow(
            label: '🩸 Period started',
            value: hasStart ? fmt.format(_start!) : 'Tap to pick',
            hasValue: hasStart,
            onTap: () => _pickDate(true),
          ),
          const SizedBox(height: 12),
          // End date
          _DatePickerRow(
            label: '✅ Period ended (optional)',
            value: hasEnd ? fmt.format(_end!) : 'Tap to pick',
            hasValue: hasEnd,
            onTap: () => _pickDate(false),
          ),
          // Length preview
          if (days != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: LunaTheme.surfaceV, borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _MiniStat('$days', 'cycle days'),
                Container(width: 1, height: 30, color: LunaTheme.text3.withOpacity(.3)),
                _MiniStat(fmt.format(_start!), 'started'),
                Container(width: 1, height: 30, color: LunaTheme.text3.withOpacity(.3)),
                _MiniStat(fmt.format(_end!), 'ended'),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [LunaTheme.primary, LunaTheme.secondary]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('Save cycle 💜', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final String label, value;
  final bool hasValue;
  final VoidCallback onTap;
  const _DatePickerRow({required this.label, required this.value, required this.hasValue, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasValue ? LunaTheme.primary.withOpacity(.08) : LunaTheme.surfaceV,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hasValue ? LunaTheme.primary.withOpacity(.4) : Colors.transparent),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: LunaTheme.text2)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: hasValue ? LunaTheme.primary : LunaTheme.text3)),
        ])),
        Icon(Icons.calendar_today_outlined, color: hasValue ? LunaTheme.primary : LunaTheme.text3, size: 18),
      ]),
    ),
  );
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  const _MiniStat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.primary, fontSize: 13)),
    Text(label, style: GoogleFonts.nunito(fontSize: 10, color: LunaTheme.text2)),
  ]);
}

// ── Stats Card ────────────────────────────────────────────────────────────────
class _CycleStatsCard extends StatelessWidget {
  final List<CycleEntry> cycles;
  const _CycleStatsCard({required this.cycles});
  @override
  Widget build(BuildContext context) {
    final completed = cycles.where((c) => c.endDate != null).toList();
    if (completed.isEmpty) return const SizedBox.shrink();
    final lengths = completed.map((c) => c.endDate!.difference(c.startDate).inDays).toList();
    final avg = lengths.reduce((a, b) => a + b) / lengths.length;
    final minV = lengths.reduce((a, b) => a < b ? a : b);
    final maxV = lengths.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [LunaTheme.primary, LunaTheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _BigStat('${cycles.length}', 'cycles total', Colors.white),
        _BigStat(avg.toStringAsFixed(1), 'avg days', Colors.white),
        _BigStat('$minV', 'shortest', Colors.white),
        _BigStat('$maxV', 'longest', Colors.white),
      ]),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _BigStat(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
    Text(label, style: GoogleFonts.nunito(fontSize: 10, color: color.withOpacity(.8), fontWeight: FontWeight.w600)),
  ]);
}

// ── Charts ────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title; final Widget child;
  const _Card({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 14)),
      const SizedBox(height: 14), child,
    ]),
  );
}

class _CycleLengthChart extends StatelessWidget {
  final List<CycleEntry> cycles;
  const _CycleLengthChart({required this.cycles});
  @override
  Widget build(BuildContext context) {
    final data = cycles.reversed.take(8).toList();
    if (data.isEmpty) return const SizedBox.shrink();
    final lengths = data.map((c) => c.endDate != null ? c.endDate!.difference(c.startDate).inDays : c.cycleLength).toList();
    final maxLen = lengths.reduce((a, b) => a > b ? a : b).toDouble();
    return _Card(
      title: 'Cycle length history',
      child: SizedBox(
        height: 80,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: lengths.asMap().entries.map((e) {
            final h = maxLen > 0 ? (e.value / maxLen) * 70 : 8.0;
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${e.value}', style: GoogleFonts.nunito(fontSize: 9, color: LunaTheme.text3, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Container(height: h.clamp(8, 70), decoration: BoxDecoration(color: LunaTheme.primary, borderRadius: BorderRadius.circular(4))),
              ]),
            ));
          }).toList(),
        ),
      ),
    );
  }
}

class _PeriodLengthChart extends StatelessWidget {
  final List<CycleEntry> cycles;
  const _PeriodLengthChart({required this.cycles});
  @override
  Widget build(BuildContext context) {
    final data = cycles.reversed.take(8).toList();
    if (data.isEmpty) return const SizedBox.shrink();
    final lengths = data.map((c) => c.periodLength).toList();
    final maxLen = lengths.reduce((a, b) => a > b ? a : b).toDouble();
    return _Card(
      title: 'Period length history',
      child: SizedBox(
        height: 70,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: lengths.asMap().entries.map((e) {
            final h = maxLen > 0 ? (e.value / maxLen) * 60 : 8.0;
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${e.value}d', style: GoogleFonts.nunito(fontSize: 9, color: LunaTheme.text3, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Container(height: h.clamp(8, 60), decoration: BoxDecoration(color: LunaTheme.menstrual, borderRadius: BorderRadius.circular(4))),
              ]),
            ));
          }).toList(),
        ),
      ),
    );
  }
}

// ── Past Cycles List ──────────────────────────────────────────────────────────
class _PastCyclesList extends StatelessWidget {
  final List<CycleEntry> cycles;
  final ValueChanged<int> onDelete;
  final ValueChanged<CycleEntry> onEdit;
  final VoidCallback onAdd;
  const _PastCyclesList({required this.cycles, required this.onDelete, required this.onEdit, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Past cycles',
      child: Column(children: [
        ...cycles.map((c) {
          final length = c.endDate != null ? c.endDate!.difference(c.startDate).inDays : null;
          final isActive = c.endDate == null;
          return Dismissible(
            key: ValueKey(c.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.delete_outline, color: Colors.red.shade400),
            ),
            confirmDismiss: (_) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('Delete cycle?', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                  content: Text(
                    'Cycle from ${DateFormat("MMM d, yyyy").format(c.startDate)} will be permanently deleted.',
                    style: GoogleFonts.nunito(),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Delete', style: TextStyle(color: Colors.red[400])),
                    ),
                  ],
                ),
              );
              return confirm == true;
            },
            onDismissed: (_) => onDelete(c.id!),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: isActive ? LunaTheme.menstrual : LunaTheme.primary, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(DateFormat('MMM d, yyyy').format(c.startDate), style: GoogleFonts.nunito(color: LunaTheme.text, fontWeight: FontWeight.w700, fontSize: 13)),
                    if (c.endDate != null)
                      Text('period ended ${DateFormat("MMM d").format(c.endDate!)}  •  ${c.endDate!.difference(c.startDate).inDays}d period', style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 11)),
                  ]),
                ),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  isActive
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: LunaTheme.menstrual.withOpacity(.15), borderRadius: BorderRadius.circular(8)),
                          child: Text('Active 🩸', style: GoogleFonts.nunito(color: LunaTheme.menstrual, fontSize: 11, fontWeight: FontWeight.w700)),
                        )
                      : Text('${c.cycleLength}d cycle', style: GoogleFonts.nunito(color: LunaTheme.text2, fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 16, color: LunaTheme.primary),
                    onPressed: () => onEdit(c),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),

                ]),
              ]),
            ),
          );
        }),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onAdd,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_circle_outline, color: LunaTheme.primary, size: 18),
            const SizedBox(width: 6),
            Text('Add past cycle', style: GoogleFonts.nunito(color: LunaTheme.primary, fontWeight: FontWeight.w800)),
          ]),
        ),
      ]),
    );
  }
}

// ── Mood trend chart ──────────────────────────────────────────────────────────
class _MoodTrendChart extends StatelessWidget {
  final List<DayLog> logs;
  const _MoodTrendChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    final recent = logs.where((l) => l.mood != null)
        .toList()..sort((a, b) => a.date.compareTo(b.date));
    final show = recent.length > 14 ? recent.sublist(recent.length - 14) : recent;
    if (show.isEmpty) return const SizedBox.shrink();

    final moodEmojis = ['', '😣','😔','😐','😊','🥰'];
    final moodColors = [Colors.transparent, Colors.red[300]!, Colors.orange[300]!,
        Colors.grey[400]!, Colors.green[300]!, Colors.pink[300]!];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('😊 Mood Trend (last ${show.length} days)',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text, fontSize: 15)),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: show.map((l) {
              final h = ((l.mood ?? 0) / 5 * 60).toDouble();
              return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(moodEmojis[l.mood!], style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: h.clamp(4, 60),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: moodColors[l.mood!].withOpacity(.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ]));
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(DateFormat('MMM d').format(show.first.date),
              style: GoogleFonts.nunito(fontSize: 10, color: LunaTheme.text3)),
          Text(DateFormat('MMM d').format(show.last.date),
              style: GoogleFonts.nunito(fontSize: 10, color: LunaTheme.text3)),
        ]),
        const SizedBox(height: 12),
        // Average mood
        Builder(builder: (_) {
          final avg = show.map((l) => l.mood!).reduce((a, b) => a + b) / show.length;
          final avgIdx = avg.round().clamp(1, 5);
          return Row(children: [
            Text('Average mood: ', style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 12)),
            Text(moodEmojis[avgIdx], style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(avg.toStringAsFixed(1), style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text, fontSize: 12)),
          ]);
        }),
      ]),
    );
  }
}

// ── Symptom frequency chart ───────────────────────────────────────────────────
class _SymptomFrequencyChart extends StatelessWidget {
  final List<DayLog> logs;
  const _SymptomFrequencyChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    // Count symptoms
    final Map<String, int> counts = {};
    for (final log in logs) {
      for (final s in log.symptoms) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return const SizedBox.shrink();

    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    final maxVal = top.first.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🩺 Top Symptoms', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text, fontSize: 15)),
        const SizedBox(height: 4),
        Text('Based on ${logs.length} logged days', style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 11)),
        const SizedBox(height: 14),
        ...top.map((e) {
          final pct = e.value / maxVal;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(e.key, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: LunaTheme.text))),
                Text('${e.value}x', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: LunaTheme.primary)),
              ]),
              const SizedBox(height: 4),
              Stack(children: [
                Container(height: 8, decoration: BoxDecoration(color: LunaTheme.surfaceV, borderRadius: BorderRadius.circular(4))),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: LunaTheme.primary.withOpacity(.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ]),
            ]),
          );
        }),
      ]),
    );
  }
}
