# Manual Activity Timer Module - Setup Instructions

## Overview
A complete manual activity timer module for the Dailio productivity tracker app, built with Flutter, Riverpod, and Hive.

## Features Implemented
- ✅ Start/Stop timer with button
- ✅ Real-time elapsed time display in HH:MM:SS format  
- ✅ Save dialog on timer stop with:
  - Activity name input (required)
  - Category selection: "Useful" or "Wasted" 
  - Optional notes (multiline)
- ✅ Local storage with Hive database
- ✅ Riverpod state management
- ✅ Material 3 responsive UI

## File Structure Created

```
lib/
├── main.dart                           # App entry point with Hive initialization
├── models/
│   ├── activity.dart                   # Activity model with Hive annotations
│   └── activity.g.dart                 # Generated Hive adapter
├── services/
│   ├── timer_providers.dart            # Riverpod timer state management
│   └── activity_service.dart           # Hive database operations + providers
├── screens/
│   └── timer_screen.dart               # Main timer UI screen
└── widgets/
    └── activity_save_dialog.dart       # Activity save dialog
```

## Dependencies Added

The following dependencies were added to `pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^2.4.9    # State management
  hive_flutter: ^1.1.0        # Local database
  uuid: ^4.2.1                # Unique ID generation

dev_dependencies:
  hive_generator: ^2.0.1      # Code generation
  build_runner: ^2.4.7        # Build tool
```

## Activity Database Schema

```dart
Activity {
  id: String (UUID),           # Unique identifier
  name: String,               # Activity name (e.g., "Reading", "Social Media")
  category: String,           # "useful" or "wasted" 
  durationSeconds: int,       # Duration in seconds
  notes: String?,             # Optional notes
  timestamp: DateTime         # When the activity was completed
}
```

## Timer States

```dart
enum TimerState {
  idle,      # Ready to start
  running,   # Timer is active
  stopped    # Timer stopped, ready to save
}
```

## Setup Instructions

### 1. Run the Build Command
After all files are created, generate the Hive adapter:

```bash
flutter packages pub run build_runner build
```

### 2. Initialize Hive in main.dart
The main.dart file has been configured with:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register adapters (after running build_runner)
  Hive.registerAdapter(ActivityAdapter());
  
  runApp(const ProviderScope(child: MyApp()));
}
```

### 3. Run the App
```bash
flutter run
```

## Usage

1. **Start Timer**: Tap the "Start" button to begin timing an activity
2. **Monitor Progress**: Watch the elapsed time display update in real-time
3. **Stop Timer**: Tap "Stop" when the activity is complete
4. **Save Activity**: Fill out the dialog:
   - Enter activity name (required)
   - Select category: Useful or Wasted
   - Add optional notes
   - Tap "Save"
5. **Reset**: Use "Reset" button to clear the timer

## Key Providers Available

- `timerProvider` - Main timer state and controls
- `activityServiceProvider` - Database operations
- `allActivitiesProvider` - All saved activities
- `todaysActivitiesProvider` - Activities from today
- `totalUsefulTimeTodayProvider` - Total useful time today
- `totalWastedTimeTodayProvider` - Total wasted time today

## Extending the Module

### Adding New Categories
In `activity_save_dialog.dart`, update the `_categories` list:

```dart
final List<String> _categories = ['useful', 'wasted', 'neutral', 'learning'];
```

### Adding Statistics
Use the provided activity service providers to build charts and statistics screens.

### Export/Import Data
Extend `ActivityService` with methods to export activities to JSON or CSV.

## Material 3 Design Features

- Clean, modern interface with proper elevation and colors
- Responsive layout that works on different screen sizes
- Proper color theming for light/dark modes
- Accessible button styling and typography
- Status indicators with color-coded states

The timer module is now fully functional and ready for integration into your productivity tracker app!