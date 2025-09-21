import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';

/// Service for exporting activities to various formats
class ExportService {
  final ActivityRepository _activityRepository;

  ExportService(this._activityRepository);

  /// Export all activities to CSV format
  /// Returns the file path if successful, null if failed
  Future<String?> exportActivitiesToCSV({
    DateTime? startDate,
    DateTime? endDate,
    String? fileName,
  }) async {
    try {
      // Request storage permission if needed (mainly for older Android versions)
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // Get activities from database
      final activities = await _getActivitiesForExport(startDate, endDate);

      if (activities.isEmpty) {
        throw Exception('No activities found to export');
      }

      // Generate CSV content
      final csvContent = await _generateCSVContent(activities);

      // Get export directory and save file
      final filePath = await _saveCSVFile(csvContent, fileName);

      debugPrint('Activities exported successfully to: $filePath');
      return filePath;

    } catch (e) {
      debugPrint('Failed to export activities: $e');
      return null;
    }
  }

  /// Export activities within a date range
  Future<String?> exportActivitiesByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? fileName,
  }) async {
    return exportActivitiesToCSV(
      startDate: startDate,
      endDate: endDate,
      fileName: fileName,
    );
  }

  /// Export activities for a specific category
  Future<String?> exportActivitiesByCategory(
    String category, {
    String? fileName,
  }) async {
    try {
      // Request storage permission if needed (mainly for older Android versions)
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // Get activities by category
      final activities = await _activityRepository.getActivitiesByCategory(category);

      if (activities.isEmpty) {
        throw Exception('No activities found for category: $category');
      }

      // Generate CSV content
      final csvContent = await _generateCSVContent(activities);

      // Save file with category name in filename
      final categoryFileName = fileName ?? 'dailio_activities_${category.toLowerCase()}.csv';
      final filePath = await _saveCSVFile(csvContent, categoryFileName);

      debugPrint('Activities for category "$category" exported to: $filePath');
      return filePath;

    } catch (e) {
      debugPrint('Failed to export activities by category: $e');
      return null;
    }
  }

  /// Get export statistics
  Future<Map<String, dynamic>> getExportStatistics() async {
    try {
      final allActivities = await _activityRepository.getAllActivities();
      final manualActivities = allActivities.where((a) => !a.isTracked).toList();
      final autoActivities = allActivities.where((a) => a.isTracked).toList();

      final categories = <String, int>{};
      for (final activity in allActivities) {
        categories[activity.category] = (categories[activity.category] ?? 0) + 1;
      }

      final totalDuration = allActivities.fold<Duration>(
        Duration.zero,
        (sum, activity) => sum + activity.duration,
      );

      return {
        'totalActivities': allActivities.length,
        'manualActivities': manualActivities.length,
        'autoTrackedActivities': autoActivities.length,
        'categories': categories,
        'totalDuration': totalDuration,
        'earliestActivity': allActivities.isNotEmpty 
            ? allActivities.map((a) => a.timestamp).reduce((a, b) => a.isBefore(b) ? a : b)
            : null,
        'latestActivity': allActivities.isNotEmpty
            ? allActivities.map((a) => a.timestamp).reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      };
    } catch (e) {
      debugPrint('Failed to get export statistics: $e');
      return {'error': e.toString()};
    }
  }

  // Private methods

  Future<bool> _requestStoragePermission() async {
    try {
      // For most platforms, no special permission is needed to write to Documents directory
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return true;
      }
      
      if (Platform.isAndroid) {
        // For modern Android (13+), scoped storage doesn't require permissions for app directories
        // For older Android, we'll try to write and handle any errors
        return true;
      } 
      
      if (Platform.isIOS) {
        // iOS doesn't need storage permission for app documents directory
        return true;
      }
      
      return true;
    } catch (e) {
      debugPrint('Failed to request storage permission: $e');
      return false;
    }
  }

  Future<List<Activity>> _getActivitiesForExport(DateTime? startDate, DateTime? endDate) async {
    if (startDate != null && endDate != null) {
      return await _activityRepository.getActivitiesByDateRange(startDate, endDate);
    } else if (startDate != null) {
      final now = DateTime.now();
      return await _activityRepository.getActivitiesByDateRange(startDate, now);
    } else if (endDate != null) {
      // Get all activities up to end date (this might be a large dataset)
      final allActivities = await _activityRepository.getAllActivities();
      return allActivities.where((a) => a.timestamp.isBefore(endDate) || a.timestamp.isAtSameMomentAs(endDate)).toList();
    } else {
      return await _activityRepository.getAllActivities();
    }
  }

  Future<String> _generateCSVContent(List<Activity> activities) async {
    // Define CSV headers
    const headers = [
      'ID',
      'Name',
      'Category',
      'Duration (seconds)',
      'Duration (formatted)',
      'Notes',
      'Date',
      'Start Time',
      'End Time',
      'Is Auto-tracked',
      'Timestamp (ISO)',
    ];

    // Convert activities to CSV rows
    final rows = <List<String>>[headers];

    for (final activity in activities) {
      final row = [
        activity.id,
        activity.name,
        activity.category,
        activity.durationSeconds.toString(),
        activity.formattedDuration,
        activity.notes ?? '',
        activity.dateOnly.toIso8601String().split('T')[0], // Date only
        activity.startTime?.toIso8601String() ?? '',
        activity.endTime?.toIso8601String() ?? '',
        activity.isTracked.toString(),
        activity.timestamp.toIso8601String(),
      ];
      rows.add(row);
    }

    // Convert to CSV string
    return const ListToCsvConverter().convert(rows);
  }

  Future<String> _saveCSVFile(String csvContent, String? fileName) async {
    // Generate filename if not provided
    final timestamp = DateTime.now().toIso8601String().split('T')[0];
    final defaultFileName = 'dailio_activities_$timestamp.csv';
    final finalFileName = fileName ?? defaultFileName;

    // Get appropriate directory for each platform
    Directory directory;
    if (Platform.isAndroid) {
      // Try to get Downloads directory, fallback to external storage
      try {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        directory = await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isIOS) {
      // iOS: Use app documents directory
      directory = await getApplicationDocumentsDirectory();
    } else {
      // Desktop platforms: Use downloads directory if available
      try {
        directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      } catch (e) {
        directory = await getApplicationDocumentsDirectory();
      }
    }

    // Create the file
    final file = File('${directory.path}/$finalFileName');
    await file.writeAsString(csvContent);

    return file.path;
  }

  /// Get available export formats
  List<String> getAvailableFormats() {
    return ['CSV']; // Can be extended to include JSON, Excel, etc.
  }

  /// Validate export parameters
  Map<String, String?> validateExportParameters({
    DateTime? startDate,
    DateTime? endDate,
    String? fileName,
  }) {
    final errors = <String, String?>{};

    if (startDate != null && endDate != null) {
      if (startDate.isAfter(endDate)) {
        errors['dateRange'] = 'Start date must be before end date';
      }
    }

    if (fileName != null && fileName.isNotEmpty) {
      // Check for invalid characters
      final invalidChars = RegExp(r'[<>:"/\\|?*]');
      if (invalidChars.hasMatch(fileName)) {
        errors['fileName'] = 'Filename contains invalid characters';
      }

      // Check length
      if (fileName.length > 100) {
        errors['fileName'] = 'Filename is too long (max 100 characters)';
      }
    }

    return errors;
  }
}