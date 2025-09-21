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

  @HiveField(6)
  final bool isTracked;

  @HiveField(7)
  final DateTime? startTime;

  @HiveField(8)
  final DateTime? endTime;

  Activity({
    required this.id,
    required this.name,
    required this.category,
    required this.durationSeconds,
    this.notes,
    required this.timestamp,
    this.isTracked = false,
    this.startTime,
    this.endTime,
  });

  // Factory constructor for creating Activity with current timestamp
  factory Activity.create({
    required String id,
    required String name,
    required String category,
    required int durationSeconds,
    String? notes,
    bool isTracked = false,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return Activity(
      id: id,
      name: name,
      category: category,
      durationSeconds: durationSeconds,
      notes: notes,
      timestamp: DateTime.now(),
      isTracked: isTracked,
      startTime: startTime,
      endTime: endTime,
    );
  }

  // Factory constructor for auto-tracked activities
  factory Activity.tracked({
    required String id,
    required String name,
    required DateTime startTime,
    required DateTime endTime,
    String? category,
    String? notes,
  }) {
    final duration = endTime.difference(startTime);
    return Activity(
      id: id,
      name: name,
      category: category ?? 'Auto-tracked',
      durationSeconds: duration.inSeconds,
      notes: notes,
      timestamp: startTime,
      isTracked: true,
      startTime: startTime,
      endTime: endTime,
    );
  }

  // Copy with method for immutability
  Activity copyWith({
    String? id,
    String? name,
    String? category,
    int? durationSeconds,
    String? notes,
    DateTime? timestamp,
    bool? isTracked,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      isTracked: isTracked ?? this.isTracked,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  // Get computed duration from start/end times if available
  Duration get duration {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    return Duration(seconds: durationSeconds);
  }

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
    switch (category.toLowerCase()) {
      case 'useful':
        return 'Useful';
      case 'wasted':
        return 'Wasted';
      case 'neutral':
        return 'Neutral';
      default:
        return category;
    }
  }

  // Helper to get date only (without time)
  DateTime get dateOnly {
    return DateTime(timestamp.year, timestamp.month, timestamp.day);
  }

  // Helper to check if activity is from today
  bool get isToday {
    final now = DateTime.now();
    return dateOnly == DateTime(now.year, now.month, now.day);
  }

  // Helper to get duration in minutes
  double get durationInMinutes {
    return durationSeconds / 60.0;
  }

  // Helper to get duration in hours
  double get durationInHours {
    return durationSeconds / 3600.0;
  }

  // Convert to JSON for debugging/export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'durationSeconds': durationSeconds,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
      'isTracked': isTracked,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  // Create from JSON
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      durationSeconds: json['durationSeconds'] as int,
      notes: json['notes'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isTracked: json['isTracked'] as bool? ?? false,
      startTime: json['startTime'] != null 
          ? DateTime.parse(json['startTime'] as String) 
          : null,
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime'] as String) 
          : null,
    );
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
