# Hydro — Water Reminder App (Flutter)

## Quick Setup

1. **Create a new Flutter project scaffold**, then copy our files in:
   ```bash
   cd E:/Coding
   flutter create --org com.hydro --project-name hydro_app hydro_scaffold
   ```

2. **Copy our source files** into the scaffold:
   - Copy `E:/Coding/HydroApp/lib/` → `E:/Coding/hydro_scaffold/lib/`
   - Copy `E:/Coding/HydroApp/pubspec.yaml` → `E:/Coding/hydro_scaffold/pubspec.yaml`
   - Merge `android/app/src/main/AndroidManifest.xml` from our version into the scaffold

3. **Install dependencies**:
   ```bash
   cd E:/Coding/hydro_scaffold
   flutter pub get
   ```

4. **Run**:
   ```bash
   flutter run
   ```

---

## Features
- **Clock UI** — Analog clock with a water-progress ring around the edge
- **Reminder scheduling** — Set how many minutes between reminders (15m–2h)
- **Active hours** — Only remind between your set hours (e.g., 07:00–22:00)
- **DND periods** — Multiple quiet windows (e.g., sleep time); reminders are skipped
- **Accept / Skip** — Notification actions + manual buttons on home screen
- **Daily goal** — Slider 500–5000 ml; app auto-calculates sessions & ml per session
- **Statistics** — Today & Yesterday tabs: progress bar, drank/skipped count, log list
- **1-day log retention** — Logs older than 2 days are automatically pruned

## Project Structure
```
lib/
├── main.dart               # Entry point, init notifications & provider
├── app.dart                # MaterialApp + bottom nav shell
├── models/
│   ├── water_log.dart      # WaterLog entity (drank / skipped)
│   ├── dnd_period.dart     # DND period model
│   └── app_settings.dart   # Settings model with computed properties
├── services/
│   ├── database_service.dart    # SQLite via sqflite
│   ├── settings_service.dart    # SharedPreferences persistence
│   └── notification_service.dart# flutter_local_notifications + scheduling
├── providers/
│   └── water_provider.dart      # ChangeNotifier — all app state
├── screens/
│   ├── home_screen.dart    # Clock + action buttons
│   ├── stats_screen.dart   # Today/Yesterday tabs
│   └── settings_screen.dart# Goal, interval, active hours, DND
├── widgets/
│   ├── clock_face.dart     # CustomPainter analog clock + progress ring
│   ├── stat_card.dart      # Reusable card + progress bar widget
│   ├── log_entry_tile.dart # Single log row in stats
│   └── dnd_period_tile.dart# DND period row in settings
└── theme/
    └── app_theme.dart      # Colors, ThemeData, Material 3
```

## Android Permissions (already in AndroidManifest.xml)
- `POST_NOTIFICATIONS` — show reminders
- `USE_EXACT_ALARM` / `SCHEDULE_EXACT_ALARM` — precise alarm timing
- `RECEIVE_BOOT_COMPLETED` — reschedule alarms after device restart
