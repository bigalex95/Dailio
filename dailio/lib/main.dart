import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/activity.dart';
import 'screens/timer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register adapters (after running build_runner)
  Hive.registerAdapter(ActivityAdapter());
  
  runApp(const ProviderScope(child: MyApp()));
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