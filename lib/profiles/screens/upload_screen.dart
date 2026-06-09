import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:play_smart/core/router/app_router.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Content Upload screen — athlete uploads video, photo, or post.
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  ContentType _selectedType = ContentType.video;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  MomentType? _selectedMoment;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleUpload() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    // Simulate upload with compression for videos
    final steps = _selectedType == ContentType.video ? 5 : 3;
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _uploadProgress = i / steps);
    }

    if (!mounted) return;
    setState(() => _isUploading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedType.name.capitalize()} uploaded successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    context.go(AppRouter.myProfile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Content'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Media type selector
              Text('Content Type', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTypeChip(ContentType.video, Icons.videocam, 'Video'),
                  const SizedBox(width: 8),
                  _buildTypeChip(ContentType.photo, Icons.photo, 'Photo'),
                  const SizedBox(width: 8),
                  _buildTypeChip(ContentType.post, Icons.article, 'Post'),
                ],
              ),
              const SizedBox(height: 24),

              // File picker area
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File picker coming soon.')),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedType == ContentType.video
                            ? Icons.videocam
                            : _selectedType == ContentType.photo
                                ? Icons.photo_library
                                : Icons.edit_note,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedType == ContentType.video
                            ? 'Tap to select video'
                            : _selectedType == ContentType.photo
                                ? 'Tap to select photo'
                                : 'Write a post',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (_selectedType == ContentType.video)
                        Text(
                          'MP4, max 100MB. Will be compressed.',
                          style: theme.textTheme.bodySmall,
                        ),
                      if (_selectedType == ContentType.photo)
                        Text(
                          'JPG, PNG. Max 10MB.',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Match Highlights - March 2026',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Tell viewers what this is about...',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Moment tag selector
              Text('Moment Type (optional)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MomentType.values.map((moment) {
                  final selected = _selectedMoment == moment;
                  final (icon, label) = _momentMeta(moment);
                  return ChoiceChip(
                    avatar: Icon(icon, size: 18),
                    label: Text(label),
                    selected: selected,
                    onSelected: (val) =>
                        setState(() => _selectedMoment = val ? moment : null),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Compression note for videos
              if (_selectedType == ContentType.video)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.compress, color: theme.colorScheme.onTertiaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Videos will be compressed for optimal playback on mobile connections.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Upload progress
              if (_isUploading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(value: _uploadProgress),
                      const SizedBox(height: 8),
                      Text(
                        _selectedType == ContentType.video && _uploadProgress < 0.4
                            ? 'Compressing video...'
                            : 'Uploading... ${(_uploadProgress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

              // Submit button
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _handleUpload,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isUploading ? 'Uploading...' : 'Upload'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(ContentType type, IconData icon, String label) {
    final selected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? Theme.of(context).colorScheme.primary : null),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, String) _momentMeta(MomentType moment) {
    return switch (moment) {
      MomentType.goal => (Icons.sports_soccer, 'Goal'),
      MomentType.assist => (Icons.handshake, 'Assist'),
      MomentType.sprint => (Icons.directions_run, 'Sprint'),
      MomentType.tackle => (Icons.shield, 'Tackle'),
      MomentType.save => (Icons.sports_handball, 'Save'),
    };
  }
}

extension on String {
  String capitalize() => isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}