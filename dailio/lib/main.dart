import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/activity.dart';
import 'screens/timer_screen.dart';
import 'repositories/activity_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Hive
    await Hive.initFlutter();
    
    // Register adapters (after running build_runner)
    Hive.registerAdapter(ActivityAdapter());
    
    // Initialize the activity repository
    final repository = ActivityRepository();
    await repository.init();
    
    runApp(const ProviderScope(child: MyApp()));
  } catch (error) {
    // Handle initialization errors
    debugPrint('Error initializing app: $error');
    
    // Run a minimal error app
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: const Text('Close App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dailio - Activity Timer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TimerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Don't forget to add dependencies in pubspec.yaml:
// dependencies:
//   flutter:
//     sdk: flutter
//   flutter_riverpod: ^2.4.9
//   hive: ^2.2.3
//   hive_flutter: ^1.1.0
//   
// dev_dependencies:
//   build_runner: ^2.4.6
//   hive_generator: ^2.0.1

// Generate Hive adapters by running:
// flutter pub run build_runner build