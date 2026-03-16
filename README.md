<div align="center">

<img src="icons/mipmap-xxxhdpi/ic_launcher.png" width="110" alt="Luna" />

# 🌙 Luna

**Feminine health tracker — private, smart, ad-free**

[![Flutter](https://img.shields.io/badge/Flutter-3.19-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-7.0%2B-3DDC84?style=flat-square&logo=android&logoColor=white)](https://android.com)
[![Build](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?style=flat-square&logo=github-actions&logoColor=white)](/.github/workflows/build.yml)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20local-C8827A?style=flat-square)](#-privacy)
[![License](https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square)](LICENSE)

*100% local · No account · No ads · No cloud · Works offline*

<br/>

<img src="preview_banner.png" alt="Luna screenshots" width="100%"/>

</div>

---

## What is Luna?

Luna is an Android app for tracking your menstrual cycle and feminine health. It learns from your history to give increasingly accurate predictions, and analyses your daily logs to surface personal patterns like *"you feel better on days with yoga."*

Everything lives on your device in a local SQLite database — no server, no login, no data ever leaves your phone.

---

## Features

### 🔮 Smart predictions
Luna calculates your **personal average** from all your logged cycles — not a fixed 28-day assumption. As you log more, predictions get sharper.

- Next **3 periods** predicted in advance
- Ovulation & fertile window based on your real data
- Cycle regularity indicator — detects variability over time
- Upcoming events appear as countdown cards on home:
  *"Period in 3 days" · "Ovulation tomorrow" · "Fertile window starts in 2 days"*

### ✨ Personal insights engine
Luna scans all your logs and surfaces invisible patterns as cards:

> *"You tend to feel better on days with Yoga and Walking"*
> *"Fatigue is common for you in the luteal phase — plan lighter tasks today"*
> *"Your last 4 cycles show variability — worth mentioning at your next check-up"*

### 📝 Daily log

| What | Options |
|---|---|
| **Mood** | 5-level emoji scale |
| **Energy & Pain** | Animated bar selectors (1–5) |
| **Symptoms** | 16 options — cramps, bloating, headache, fatigue, nausea, backache, breast pain, mood swings, acne, insomnia, cravings, spotting, irritability, brain fog, joint pain, hot flashes |
| **BBT** | Basal body temperature |
| **Notes** | Free text |

### 📅 Calendar
Full monthly view with **phase colours**: 🔴 Menstrual · 🟢 Follicular · 🟡 Ovulation · 🔵 Luteal. Tap any day for the log and phase description.

### 📊 History & charts
- Cycle length chart (last 8 cycles) + period length chart
- Stats: total cycles · average · shortest · longest
- Add past cycles to backfill history for better averages
- Swipe-to-delete any cycle

### 💡 Tips library — 60+ science-backed tips
Rotating daily, matched to your current phase. Sources cited: ACOG · Mayo Clinic · NCBI · NHS · Harvard Health.

| Phase | Sample tips |
|---|---|
| 🔴 Menstrual | Iron + Vit C absorption · Heat therapy = ibuprofen (BMJ) · Ginger reduces cramping |
| 🟢 Follicular | Estrogen = cognitive peak · Best week for strength training · Seed cycling |
| 🟡 Ovulation | LH surge signs · 6-day fertile window · Peak athletic performance |
| 🔵 Luteal | Calcium reduces PMS 48% (NCBI) · Magnesium for sleep · Serotonin foods |

### 🩺 Medical records
Track appointments, tests, results with next-due-date alerts. Built-in list of recommended periodic checks (Pap smear, thyroid, iron, Vitamin D…).

### 🔔 Reminders
Quick-add presets + fully custom reminders (name, time, daily/weekly/once). Toggle on/off, swipe-to-delete.

### 📓 Journal
Titled entries with mood tags, sorted chronologically.

### 💊 Contraceptive tracker *(optional, enable in Profile)*
Daily pill log with streak counter · brand history · adherence stats.

### 🐱 Companion chat
12 companion options (🐱 🦊 🐰 🐻 🦄 🐼 🦋 🌸 🌙 ⭐ 🌺 🐝) with phase-aware responses.

### 🌍 7 Languages
🇬🇧 English · 🇷🇴 Română · 🇫🇷 Français · 🇩🇪 Deutsch · 🇪🇸 Español · 🇮🇹 Italiano · 🇵🇹 Português

---

## Navigation

Swipe left/right **on the bottom bar** to switch groups. Animated pill-dots show your position; tap them to jump directly.

```
Group 1 — Daily     🏠 Home   💗 Log   📅 Calendar   📝 Journal
Group 2 — Health    💡 Tips   📊 History   🩺 Medical   🔔 Reminders
Group 3 — More      💊 Contra (optional)   👩 Profile
```

---

## Architecture

```
lib/
├── main.dart
├── models/models.dart            CycleEntry · DayLog · JournalEntry
│                                 MedicalRecord · AppReminder · PillLog
├── services/
│   ├── app_state.dart            ChangeNotifier — single source of truth
│   ├── database_service.dart     SQLite, 7 tables, v2 migration
│   ├── cycle_calculator.dart     Predictions · phase logic · upcoming events
│   └── insights_engine.dart      Pattern analysis · 60+ tip pool
├── theme/luna_theme.dart
├── l10n/app_strings.dart         7 languages
└── screens/                      13 screens
```

**State:** Provider · **DB:** SQLite (sqflite) · **Font:** Nunito · **No internet required**

---

## Dependencies

| Package | Purpose |
|---|---|
| `provider ^6.0.0` | State management |
| `sqflite ^2.3.0` | Local SQLite database |
| `shared_preferences ^2.2.0` | Settings & onboarding |
| `google_fonts ^6.1.0` | Nunito typeface |
| `table_calendar ^3.0.9` | Calendar widget |
| `fl_chart ^0.66.0` | History charts |
| `intl ^0.19.0` | Date formatting |

---

## 🔒 Privacy

| Luna does | Luna never does |
|---|---|
| ✅ Stores everything on-device | ❌ Cloud sync |
| ✅ Works 100% offline | ❌ Account or login |
| ✅ Zero analytics or tracking | ❌ Ads or purchases |
| ✅ Delete all data from Settings | ❌ Sell or share data |

---

## Build

### GitHub Actions — no local Flutter needed

1. Fork this repo
2. **Actions → Build Luna APK → Run workflow**
3. Download `luna-apk` from Artifacts *(valid 30 days)*

### Local

```bash
flutter pub get
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

---

## Roadmap

- [ ] Push notifications for reminders
- [ ] Home screen widget — period countdown
- [ ] Export data as CSV
- [ ] Dark mode
- [ ] Symptom heatmap view
- [ ] Tablet layout

---

## License

MIT

---

<div align="center">

Built with Flutter · Android 7.0+ · Made with 💜

*Luna does not provide medical advice. Consult a healthcare professional for medical decisions.*

</div>
