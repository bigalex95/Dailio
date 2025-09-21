import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/export_service.dart';
import '../repositories/activity_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late ExportService _exportService;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _exportService = ExportService(ActivityRepository());
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto-Tracking Section
            _buildSectionCard(
              title: 'Auto-Tracking',
              icon: Icons.track_changes,
              children: [
                SwitchListTile(
                  title: const Text('Enable Auto-Tracking'),
                  subtitle: const Text('Automatically track foreground applications'),
                  value: settings.autoTrackingEnabled,
                  onChanged: (value) => settingsNotifier.toggleAutoTracking(value),
                ),
                if (settings.autoTrackingEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Tracking Interval'),
                    subtitle: Text('${settings.autoTrackingInterval} seconds'),
                    trailing: SizedBox(
                      width: 100,
                      child: DropdownButton<int>(
                        value: settings.autoTrackingInterval,
                        isExpanded: true,
                        items: [1, 3, 5, 10, 15, 30, 60].map((seconds) {
                          return DropdownMenuItem<int>(
                            value: seconds,
                            child: Text('${seconds}s'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            settingsNotifier.updateAutoTrackingInterval(value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // General Settings Section
            _buildSectionCard(
              title: 'General',
              icon: Icons.settings,
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark theme'),
                  value: settings.darkMode,
                  onChanged: (value) => settingsNotifier.toggleDarkMode(value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle: const Text('Show activity notifications'),
                  value: settings.showNotifications,
                  onChanged: (value) => settingsNotifier.toggleNotifications(value),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Default Category'),
                  subtitle: Text(settings.defaultCategory),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCategoryPicker(context, settingsNotifier, settings.defaultCategory),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Export Section
            _buildSectionCard(
              title: 'Data Export',
              icon: Icons.file_download,
              children: [
                SwitchListTile(
                  title: const Text('Include Notes in Export'),
                  subtitle: const Text('Export activity notes and descriptions'),
                  value: settings.exportIncludeNotes,
                  onChanged: (value) => settingsNotifier.toggleExportIncludeNotes(value),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Export Format'),
                  subtitle: Text(settings.exportFormat),
                  trailing: SizedBox(
                    width: 80,
                    child: DropdownButton<String>(
                      value: settings.exportFormat,
                      isExpanded: true,
                      items: settingsNotifier.getAvailableExportFormats().map((format) {
                        return DropdownMenuItem<String>(
                          value: format,
                          child: Text(format),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          settingsNotifier.updateExportFormat(value);
                        }
                      },
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export All Activities'),
                  subtitle: const Text('Download all activities as CSV'),
                  trailing: _isExporting 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                  onTap: _isExporting ? null : () => _exportAllActivities(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.date_range),
                  title: const Text('Export by Date Range'),
                  subtitle: const Text('Choose specific dates to export'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDateRangeExport(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Statistics Section
            _buildSectionCard(
              title: 'Statistics',
              icon: Icons.analytics,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Export Statistics'),
                  subtitle: const Text('View data summary and stats'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showExportStatistics(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Advanced Section
            _buildSectionCard(
              title: 'Advanced',
              icon: Icons.build,
              children: [
                ListTile(
                  leading: Icon(Icons.refresh, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Reset Settings'),
                  subtitle: const Text('Restore default settings'),
                  onTap: () => _showResetConfirmation(context, settingsNotifier),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, SettingsNotifier notifier, String currentCategory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Default Category'),
        content: SizedBox(
          width: double.minPositive,
          child: ListView(
            shrinkWrap: true,
            children: notifier.getAvailableCategories().map((category) {
              return RadioListTile<String>(
                title: Text(category),
                value: category,
                groupValue: currentCategory,
                onChanged: (value) {
                  if (value != null) {
                    notifier.updateDefaultCategory(value);
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAllActivities() async {
    setState(() => _isExporting = true);
    
    try {
      final filePath = await _exportService.exportActivitiesToCSV();
      
      if (filePath != null && mounted) {
        _showExportSuccessDialog(filePath);
      } else if (mounted) {
        _showExportErrorDialog('Failed to export activities');
      }
    } catch (e) {
      if (mounted) {
        _showExportErrorDialog('Export error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showDateRangeExport(BuildContext context) {
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Export Date Range'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(startDate?.toString().split(' ')[0] ?? 'Select start date'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => startDate = picked);
                  }
                },
              ),
              ListTile(
                title: const Text('End Date'),
                subtitle: Text(endDate?.toString().split(' ')[0] ?? 'Select end date'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: startDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => endDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: startDate != null && endDate != null
                ? () async {
                    Navigator.of(context).pop();
                    await _exportDateRange(startDate!, endDate!);
                  }
                : null,
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportDateRange(DateTime startDate, DateTime endDate) async {
    setState(() => _isExporting = true);
    
    try {
      final filePath = await _exportService.exportActivitiesByDateRange(startDate, endDate);
      
      if (filePath != null && mounted) {
        _showExportSuccessDialog(filePath);
      } else if (mounted) {
        _showExportErrorDialog('Failed to export activities for selected date range');
      }
    } catch (e) {
      if (mounted) {
        _showExportErrorDialog('Export error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _showExportStatistics(BuildContext context) async {
    final stats = await _exportService.getExportStatistics();
    
    if (!mounted) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Statistics'),
        content: SizedBox(
          width: double.maxFinite,
          child: stats.containsKey('error')
            ? Text('Error: ${stats['error']}')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow('Total Activities', '${stats['totalActivities']}'),
                  _buildStatRow('Manual Activities', '${stats['manualActivities']}'),
                  _buildStatRow('Auto-tracked Activities', '${stats['autoTrackedActivities']}'),
                  const SizedBox(height: 8),
                  const Text('Categories:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...(stats['categories'] as Map<String, int>).entries.map(
                    (entry) => _buildStatRow('  ${entry.key}', '${entry.value}'),
                  ),
                  const SizedBox(height: 8),
                  if (stats['totalDuration'] != null)
                    _buildStatRow('Total Duration', _formatDuration(stats['totalDuration'] as Duration)),
                  if (stats['earliestActivity'] != null)
                    _buildStatRow('Earliest Activity', _formatDate(stats['earliestActivity'] as DateTime)),
                  if (stats['latestActivity'] != null)
                    _buildStatRow('Latest Activity', _formatDate(stats['latestActivity'] as DateTime)),
                ],
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showExportSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activities have been exported successfully!'),
            const SizedBox(height: 8),
            const Text('File location:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            SelectableText(
              filePath,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExportErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Failed'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to their default values? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.resetToDefaults();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}