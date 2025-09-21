import 'package:hive_flutter/hive_flutter.dart';

part 'activity.g.dart';

@HiveType(typeId: 0)
class Activity {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final int durationSeconds;

  @HiveField(4)
  final String? notes;

  @HiveField(5)
  final DateTime timestamp;

  Activity({
    required this.id,
    required this.name,
    required this.category,
    required this.durationSeconds,
    this.notes,
    required this.timestamp,
  });

  // Helper method to format duration as HH:MM:SS
  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  // Helper method to get category display name
  String get categoryDisplayName {
    switch (category) {
      case 'useful':
        return 'Useful';
      case 'wasted':
        return 'Wasted';
      default:
        return category;
    }
  }

  @override
  String toString() {
    return 'Activity(id: $id, name: $name, category: $category, '
           'durationSeconds: $durationSeconds, notes: $notes, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Activity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
