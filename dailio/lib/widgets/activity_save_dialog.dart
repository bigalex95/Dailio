import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/activity.dart';
import '../providers/activity_repository_provider.dart';

class ActivitySaveDialog extends ConsumerStatefulWidget {
  final int durationSeconds;

  const ActivitySaveDialog({
    super.key,
    required this.durationSeconds,
  });

  @override
  ConsumerState<ActivitySaveDialog> createState() => _ActivitySaveDialogState();
}

class _ActivitySaveDialogState extends ConsumerState<ActivitySaveDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedCategory = 'useful';
  bool _isSaving = false;

  final List<String> _categories = ['useful', 'wasted'];

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.save,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Save Activity'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Duration display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Duration',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(widget.durationSeconds),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Activity name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Activity Name',
                  hintText: 'e.g., Reading, Coding, Social Media',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an activity name';
                  }
                  if (value.trim().length < 2) {
                    return 'Activity name must be at least 2 characters';
                  }
                  return null;
                },
                autofocus: true,
              ),
              
              const SizedBox(height: 16),
              
              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          color: _getCategoryColor(category, context),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(_getCategoryDisplayName(category)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Notes field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional details...',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveActivity,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'useful':
        return Icons.trending_up;
      case 'wasted':
        return Icons.trending_down;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category, BuildContext context) {
    switch (category) {
      case 'useful':
        return Colors.green;
      case 'wasted':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'useful':
        return 'Useful';
      case 'wasted':
        return 'Wasted';
      default:
        return category;
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final activity = Activity(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        category: _selectedCategory,
        durationSeconds: widget.durationSeconds,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        timestamp: DateTime.now(),
      );

      await ref.read(activityOperationsProvider).saveActivity(activity);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Activity "${activity.name}" saved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save activity: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}