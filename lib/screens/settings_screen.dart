import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/app_state.dart';
import '../theme/luna_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = context.read<AppState>().userName;
  }

  final List<String> _languages = ['English', 'Română', 'Français', 'Deutsch', 'Español', 'Italiano', 'Português'];
  final List<Map<String, String>> _timezones = [
    {'v': 'Europe/Bucharest', 'l': '🇷🇴 România — Europe/Bucharest'},
    {'v': 'Europe/London',    'l': '🇬🇧 UK — Europe/London'},
    {'v': 'Europe/Paris',     'l': '🇫🇷 France/Belgium — Europe/Paris'},
    {'v': 'Europe/Berlin',    'l': '🇩🇪 Germany/Austria — Europe/Berlin'},
    {'v': 'Europe/Madrid',    'l': '🇪🇸 Spain — Europe/Madrid'},
    {'v': 'Europe/Rome',      'l': '🇮🇹 Italy — Europe/Rome'},
    {'v': 'Europe/Athens',    'l': '🇬🇷 Greece — Europe/Athens'},
    {'v': 'Europe/Kiev',      'l': '🇺🇦 Ukraine — Europe/Kiev'},
    {'v': 'Europe/Moscow',    'l': '🇷🇺 Russia — Europe/Moscow'},
    {'v': 'America/New_York', 'l': '🇺🇸 Eastern US — America/New_York'},
    {'v': 'America/Chicago',  'l': '🇺🇸 Central US — America/Chicago'},
    {'v': 'America/Los_Angeles','l':'🇺🇸 Pacific US — America/Los_Angeles'},
    {'v': 'America/Sao_Paulo','l': '🇧🇷 Brazil — America/Sao_Paulo'},
    {'v': 'Asia/Dubai',       'l': '🇦🇪 Dubai — Asia/Dubai'},
    {'v': 'Asia/Kolkata',     'l': '🇮🇳 India — Asia/Kolkata'},
    {'v': 'Asia/Singapore',   'l': '🇸🇬 Singapore — Asia/Singapore'},
    {'v': 'Asia/Tokyo',       'l': '🇯🇵 Japan — Asia/Tokyo'},
    {'v': 'Australia/Sydney', 'l': '🇦🇺 Australia — Australia/Sydney'},
  ];

  final List<Map<String, String>> _companions = [
    {'e': '🐱', 'n': 'Luna'}, {'e': '🦊', 'n': 'Foxy'}, {'e': '🐰', 'n': 'Bunny'},
    {'e': '🐻', 'n': 'Bear'}, {'e': '🦄', 'n': 'Star'}, {'e': '🐼', 'n': 'Panda'},
    {'e': '🦋', 'n': 'Flutter'}, {'e': '🌸', 'n': 'Bloom'}, {'e': '🌙', 'n': 'Moon'},
    {'e': '⭐', 'n': 'Stella'}, {'e': '🌺', 'n': 'Rose'}, {'e': '🐝', 'n': 'Bee'},
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: LunaTheme.surface,
      body: ListView(
        children: [
          // Profile header — gradient background with woman avatar
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [LunaTheme.primary, LunaTheme.secondary],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 28),
            child: Column(children: [
              // Avatar circle — tappable to pick photo
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (picked != null) {
                    context.read<AppState>().profilePhotoPath = picked.path;
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: ClipOval(
                        child: context.watch<AppState>().profilePhotoPath != null
                          ? Image.file(File(context.watch<AppState>().profilePhotoPath!), fit: BoxFit.cover, width: 80, height: 80)
                          : const Center(child: Text('👩', style: TextStyle(fontSize: 40))),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 26, height: 26,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Center(child: Text('📷', style: TextStyle(fontSize: 13))),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                state.userName.isNotEmpty ? state.userName : 'Your Name',
                style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                'Using Luna · ${state.cycles.length} cycles tracked',
                style: GoogleFonts.nunito(fontSize: 12, color: Colors.white.withOpacity(.8), fontWeight: FontWeight.w600),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Name
              _SectionTitle('👩 Profile'),
              _Card(child: Row(children: [
                Expanded(child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(hintText: 'Your name'),
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                )),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    state.userName = _nameCtrl.text.trim().isEmpty ? 'Friend' : _nameCtrl.text.trim();
                    await state.savePrefs();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Saved! 💜', style: GoogleFonts.nunito()), backgroundColor: LunaTheme.primary, duration: const Duration(seconds: 2)));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(color: LunaTheme.primary, borderRadius: BorderRadius.circular(14)),
                    child: Text('Save', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ])),
              const SizedBox(height: 16),
              // Cycle settings
              _SectionTitle('🔄 My cycle'),
              _Card(child: Column(children: [
                _SliderRow('🔄 Cycle length', state.cycleLength, 21, 35, LunaTheme.primary, (v) { state.cycleLength = v; state.savePrefs(); setState(() {}); }),
                const Divider(height: 20),
                _SliderRow('🩸 Period length', state.periodLength, 2, 8, LunaTheme.menstrual, (v) { state.periodLength = v; state.savePrefs(); setState(() {}); }),
              ])),
              const SizedBox(height: 16),
              // Language
              _SectionTitle('🌍 Language'),
              _Card(child: Wrap(
                spacing: 8, runSpacing: 8,
                children: _languages.map((l) {
                  final sel = state.language == l;
                  return GestureDetector(
                    onTap: () { state.language = l; state.savePrefs(); setState(() {}); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? LunaTheme.primary : LunaTheme.surfaceV,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(l, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: sel ? Colors.white : LunaTheme.text2, fontSize: 13)),
                    ),
                  );
                }).toList(),
              )),
              const SizedBox(height: 16),
              // Companion
              const SizedBox(height: 16),
              _SectionTitle('🕐 Timezone for notifications'),
              _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Select your timezone so notifications arrive at the correct time.',
                    style: GoogleFonts.nunito(color: LunaTheme.text2, fontSize: 12)),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: state.timezone,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: GoogleFonts.nunito(color: LunaTheme.text, fontWeight: FontWeight.w700, fontSize: 13),
                  items: _timezones.map((t) => DropdownMenuItem(
                    value: t['v'],
                    child: Text(t['l']!),
                  )).toList(),
                  onChanged: (v) { if (v != null) state.setTimezone(v); },
                ),
              ])),
              _SectionTitle('🐾 My companion'),
              _Card(child: Wrap(
                spacing: 10, runSpacing: 10,
                children: _companions.map((c) {
                  final sel = state.companionEmoji == c['e'];
                  return GestureDetector(
                    onTap: () => state.setCompanion(c['e']!, c['n']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: sel ? LunaTheme.primary.withOpacity(.15) : LunaTheme.surfaceV,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: sel ? LunaTheme.primary : Colors.transparent, width: 2),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(c['e']!, style: const TextStyle(fontSize: 24)),
                        Text(c['n']!, style: GoogleFonts.nunito(fontSize: 10, color: sel ? LunaTheme.primary : LunaTheme.text2, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  );
                }).toList(),
              )),
              const SizedBox(height: 16),
              // Contraceptive toggle
              _SectionTitle('💡 Tips & gestures'),
              _Card(child: Column(children: [
                _TipRow('👈 Swipe left on a card', 'Delete entries in Journal, Medical & History'),
                const Divider(height: 1),
                _TipRow('👆 Tap a card', 'Open or edit any entry'),
                const Divider(height: 1),
                _TipRow('📋 Log → View tab', 'See what you logged today'),
                const Divider(height: 1),
                _TipRow('📅 Calendar', 'Tap a day to see cycle details & daily log'),
              ])),
              const SizedBox(height: 8),
              _SectionTitle('💊 Contraceptive tracker'),
              _Card(child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Enable pill tracking', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text)),
                  Text('Adds pill log & brands tab', style: GoogleFonts.nunito(color: LunaTheme.text3, fontSize: 12)),
                ])),
                Switch(value: state.contraEnabled, onChanged: (v) { state.contraEnabled = v; state.savePrefs(); }, activeColor: LunaTheme.primary),
              ])),
              if (state.contraEnabled) ...[
                const SizedBox(height: 12),
                _Card(child: GestureDetector(
                  onTap: () async {
                    final parts = state.pillReminderTime.split(':');
                    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
                    if (picked != null) {
                      state.pillReminderTime = '${picked.hour.toString().padLeft(2,'0')}:${picked.minute.toString().padLeft(2,'0')}';
                      state.savePrefs(); setState(() {});
                    }
                  },
                  child: Row(children: [
                    const Text('⏰', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Pill reminder', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: LunaTheme.text)),
                      Text(state.pillReminderTime, style: GoogleFonts.nunito(color: LunaTheme.primary, fontWeight: FontWeight.w900, fontSize: 18)),
                    ]),
                    const Spacer(),
                    Icon(Icons.edit_outlined, color: LunaTheme.text3, size: 18),
                  ]),
                )),
              ],
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String action, description;
  const _TipRow(this.action, this.description);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
    child: Row(children: [
      SizedBox(width: 160, child: Text(action, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13, color: LunaTheme.text))),
      Expanded(child: Text(description, style: GoogleFonts.nunito(fontSize: 12, color: LunaTheme.text2))),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: LunaTheme.text, fontSize: 15)),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: child,
  );
}

class _SliderRow extends StatelessWidget {
  final String label;
  final int value, min, max;
  final Color color;
  final ValueChanged<int> onChanged;
  const _SliderRow(this.label, this.value, this.min, this.max, this.color, this.onChanged);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.nunito(color: LunaTheme.text, fontWeight: FontWeight.w700)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(.15), borderRadius: BorderRadius.circular(10)),
          child: Text('$value days', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: color)),
        ),
      ]),
      Slider(value: value.toDouble(), min: min.toDouble(), max: max.toDouble(), divisions: max - min, activeColor: color, onChanged: (v) => onChanged(v.round())),
    ],
  );
}
