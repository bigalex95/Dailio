# Dailio

A Flutter time tracker that records what you do during the day, labels it as useful or wasted time, and charts the result. Time can be tracked manually with a timer or, on desktop and Android, automatically from the foreground application.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Flutter](https://img.shields.io/badge/Flutter-Dart%203.8-02569B)

<!-- TODO: screenshots (timer screen, statistics screen, settings screen) -->

## Features

- Manual timer (HH:MM:SS). On stop, a dialog saves the activity with a name, a category (useful or wasted) and optional notes.
- Auto-tracking of the foreground application at a configurable interval, with a platform permission flow.
- Statistics screen: daily bar chart, weekly pie chart and trend line chart (fl_chart).
- CSV export of all activities or a date range.
- Settings: auto-tracking toggle and interval, dark mode, default category, export options, reset.
- Local-only storage; no account and no network access.

Auto-tracking support by platform (native code in the platform folders):

| Platform | Mechanism | Permission |
|---|---|---|
| Android | UsageStatsManager (Kotlin) | Usage Access |
| macOS | NSWorkspace (Swift) | Accessibility |
| Windows | Win32 API (C++) | none |
| Linux | X11 (C++) | none (X11 session) |
| iOS, Web | not supported | n/a |

Details and per-platform setup: [docs/auto-tracking.md](docs/auto-tracking.md).

## Architecture

- State management: Riverpod (`flutter_riverpod`); providers in `lib/providers` and `lib/services/timer_providers.dart`.
- Storage: Hive (`hive_flutter`), a single `Activity` box wrapped by `ActivityRepository`. The adapter is generated with `build_runner` (`activity.g.dart` is committed).
- Native bridge: a `MethodChannel` named `dailio/foreground_app` used by `ForegroundAppService` (`getForegroundApp`, `checkPermissions`, `requestPermissions`).
- Settings: `shared_preferences`.

## Getting started

Prerequisites: Flutter SDK with Dart `^3.8.1`. The Flutter project lives in `dailio/`.

```bash
cd dailio
flutter pub get
flutter run -d <device>        # e.g. linux, windows, macos, android, chrome
```

If you change `lib/models/activity.dart`, regenerate the adapter:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Project structure

```
dailio/
  lib/
    main.dart            entry point, Hive init
    models/              Activity (Hive), stats
    repositories/        ActivityRepository (Hive box)
    providers/           Riverpod providers (settings, charts, auto-tracker)
    services/            timer, export, foreground-app, tracking services
    screens/             timer, stats, settings
    widgets/             save dialog, charts, status widgets
  android/ ios/ linux/ macos/ windows/ web/    platform runners (native detectors)
docs/
  timer-module.md        manual timer module notes
  auto-tracking.md       auto-tracking setup per platform
```

## Status and roadmap

Early version (`0.1.0`), personal project. Known gaps:

- There are no automated tests yet.
- `lib/screens/database_test_screen.dart` and `lib/widgets/mock_data_helper.dart` are development helpers still reachable from the UI.
- The Android application id is still the template `com.example.dailio`.
- `lib/services/ml_service.dart` is an empty placeholder.
- Planned, not implemented: alarms, to-do lists, notes and daily challenges. The app is currently a time tracker only.

## License

MIT, see [LICENSE](LICENSE).
