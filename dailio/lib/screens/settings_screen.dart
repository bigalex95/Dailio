import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auto_tracker_provider.dart';
import '../services/foreground_app_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Map<String, dynamic>? _platformInfo;
  bool _isLoadingPlatformInfo = false;

  @override
  void initState() {
    super.initState();
    _loadPlatformInfo();
  }

  Future<void> _loadPlatformInfo() async {
    setState(() {
      _isLoadingPlatformInfo = true;
    });

    try {
      final service = ForegroundAppService();
      final info = await service.getPlatformInfo();
      setState(() {
        _platformInfo = info;
      });
    } catch (e) {
      debugPrint('Failed to load platform info: $e');
    } finally {
      setState(() {
        _isLoadingPlatformInfo = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final service = ForegroundAppService();
      final shouldOpenSettings = await service.requestPermissions();
      
      if (shouldOpenSettings && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please grant accessibility permissions in System Preferences > Security & Privacy > Privacy > Accessibility',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final autoTrackerState = ref.watch(autoTrackerProvider);
    final autoTrackerNotifier = ref.read(autoTrackerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Auto-tracking section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_mode,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Auto-Tracking',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Auto-tracking toggle
                  SwitchListTile(
                    title: const Text('Enable Auto-Tracking'),
                    subtitle: Text(
                      autoTrackerState.isEnabled
                          ? 'Automatically track foreground applications'
                          : 'Manual activity tracking only',
                    ),
                    value: autoTrackerState.isEnabled,
                    onChanged: (_) => autoTrackerNotifier.toggleTracking(),
                  ),
                  
                  // Current status
                  if (autoTrackerState.isEnabled) ...[
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        autoTrackerState.isTracking
                            ? Icons.play_circle_filled
                            : Icons.pause_circle_filled,
                        color: autoTrackerState.isTracking
                            ? Colors.green
                            : Colors.orange,
                      ),
                      title: Text(
                        autoTrackerState.isTracking
                            ? 'Currently Tracking'
                            : 'Tracking Paused',
                      ),
                      subtitle: autoTrackerState.currentAppName != null
                          ? Text('Current app: ${autoTrackerState.currentAppName}')
                          : const Text('No app detected'),
                    ),
                  ],
                  
                  // Error display
                  if (autoTrackerState.errorMessage != null) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.error, color: Colors.red),
                      title: const Text('Error'),
                      subtitle: Text(autoTrackerState.errorMessage!),
                      trailing: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => autoTrackerNotifier.startTracking(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Platform information section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getPlatformIcon(),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Platform Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isLoadingPlatformInfo)
                    const Center(child: CircularProgressIndicator())
                  else if (_platformInfo != null) ...[
                    _InfoTile(
                      title: 'Platform',
                      value: _platformInfo!['platform'] ?? 'Unknown',
                    ),
                    _InfoTile(
                      title: 'Supported',
                      value: _platformInfo!['supported'] == true ? 'Yes' : 'No',
                    ),
                    if (_platformInfo!['version'] != null)
                      _InfoTile(
                        title: 'Version',
                        value: _platformInfo!['version'],
                      ),
                    
                    // Permissions section
                    if (_platformInfo!['requiresPermissions'] == true) ...[
                      const Divider(),
                      ListTile(
                        leading: Icon(
                          _platformInfo!['hasPermissions'] == true
                              ? Icons.check_circle
                              : Icons.warning,
                          color: _platformInfo!['hasPermissions'] == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                        title: Text(
                          _platformInfo!['hasPermissions'] == true
                              ? 'Permissions Granted'
                              : 'Permissions Required',
                        ),
                        subtitle: Text(_platformInfo!['permissionsLocation'] ?? ''),
                        trailing: _platformInfo!['hasPermissions'] != true
                            ? ElevatedButton(
                                onPressed: _requestPermissions,
                                child: const Text('Grant'),
                              )
                            : null,
                      ),
                    ],
                  ] else
                    const Text('Failed to load platform information'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Test section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bug_report,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Testing',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  ListTile(
                    title: const Text('Test Foreground App Detection'),
                    subtitle: const Text('Check if the native integration is working'),
                    trailing: ElevatedButton(
                      onPressed: _testForegroundAppDetection,
                      child: const Text('Test'),
                    ),
                  ),
                  
                  ListTile(
                    title: const Text('View Tracking Statistics'),
                    subtitle: const Text('See auto-tracking performance'),
                    trailing: ElevatedButton(
                      onPressed: _showTrackingStats,
                      child: const Text('View'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testForegroundAppDetection() async {
    try {
      final service = ForegroundAppService();
      final appName = await service.getForegroundAppName();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Test Result'),
            content: Text(
              appName != null
                  ? 'Current foreground app: $appName'
                  : 'No foreground app detected',
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
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Test Failed'),
            content: Text('Error: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _showTrackingStats() async {
    try {
      final stats = await ref.read(autoTrackerProvider.notifier).getTrackingStats();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Tracking Statistics'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (stats.containsKey('error'))
                    Text('Error: ${stats['error']}')
                  else ...[
                    Text('Total Activities: ${stats['totalActivities'] ?? 0}'),
                    const SizedBox(height: 8),
                    Text('Total Duration: ${_formatDuration(stats['totalDuration'] as Duration? ?? Duration.zero)}'),
                    const SizedBox(height: 8),
                    if (stats['mostUsedApp'] != null)
                      Text('Most Used App: ${stats['mostUsedApp']}'),
                    const SizedBox(height: 16),
                    const Text('App Usage:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (stats['appCounts'] != null)
                      ...(stats['appCounts'] as Map<String, int>).entries.map(
                        (entry) => Text('${entry.key}: ${entry.value} sessions'),
                      ),
                  ],
                ],
              ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load stats: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  IconData _getPlatformIcon() {
    if (Platform.isMacOS) return Icons.laptop_mac;
    if (Platform.isWindows) return Icons.laptop_windows;
    if (Platform.isAndroid) return Icons.phone_android;
    if (Platform.isIOS) return Icons.phone_iphone;
    if (Platform.isLinux) return Icons.computer;
    return Icons.device_unknown;
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;

  const _InfoTile({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }
}
