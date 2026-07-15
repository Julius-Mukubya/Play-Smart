import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/core/router/app_router.dart';
import 'package:play_smart/profiles/providers/content_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:v_video_compressor/v_video_compressor.dart';

/// Content Upload screen — athlete uploads video, photo, or post.
/// Uses ContentRepository to persist uploaded content.
class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  ContentType _selectedType = ContentType.video;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  MomentType? _selectedMoment;
  bool _isUploading = false;
  bool _isCompressing = false;
  double _uploadProgress = 0.0;
  XFile? _pickedFile;
  Uint8List? _pickedBytes;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    try {
      final file = _selectedType == ContentType.video
          ? await picker.pickVideo(source: ImageSource.gallery)
          : await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      var bytes = await file.readAsBytes();

      if (_selectedType == ContentType.photo) {
        // Compress on-device before upload — keeps playback/load fast on
        // typical Ugandan mobile data connections (context/project-overview.md).
        // Falls back to the original bytes if compression isn't supported on
        // this platform rather than blocking the upload.
        try {
          bytes = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: 1280,
            minHeight: 1280,
            quality: 70,
          );
        } catch (_) {
          // keep original bytes
        }
      }

      if (_selectedType == ContentType.video && !kIsWeb) {
        // Compress on-device (native Media3/AVFoundation encoders, no
        // external service) before upload — same rationale as photos above.
        // Web has no native compressor, so raw bytes are kept there.
        if (!mounted) return;
        setState(() => _isCompressing = true);
        try {
          final result = await VVideoCompressor().compressVideo(
            file.path,
            const VVideoCompressionConfig.medium(),
          );
          if (result != null) {
            bytes = await File(result.compressedFilePath).readAsBytes();
          }
        } catch (_) {
          // keep original bytes
        } finally {
          if (mounted) setState(() => _isCompressing = false);
        }
      }

      if (!mounted) return;
      setState(() {
        _pickedFile = file;
        _pickedBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not select file: $e')),
      );
    }
  }

  Future<void> _handleUpload() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title.')),
      );
      return;
    }

    if (_selectedType != ContentType.post && _pickedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to upload.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    // Get current athlete ID from auth state
    final authState = ref.read(authProvider);
    String athleteId;
    if (authState is AuthAuthenticated) {
      athleteId = authState.user.id;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be signed in to upload.')),
        );
      }
      setState(() => _isUploading = false);
      return;
    }

    try {
      String? fileUrl;
      if (_pickedBytes != null) {
        // Photos/videos are already compressed at pick time (see _pickFile)
        // — upload the (possibly compressed) bytes as-is.
        final uploadId = DateTime.now().millisecondsSinceEpoch.toString();
        final extension = _selectedType == ContentType.video ? 'mp4' : 'jpg';
        fileUrl = await ref.read(contentRepositoryProvider).uploadContentFile(
              userId: athleteId,
              contentId: uploadId,
              filename: '$uploadId.$extension',
              bytes: _pickedBytes!,
            );
        if (!mounted) return;
        setState(() => _uploadProgress = 0.7);
      }

      final content = AthleteContent(
        id: '', // assigned by the database
        athleteId: athleteId,
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        fileUrl: fileUrl,
        momentTag: _selectedMoment,
      );

      await ref.read(contentProvider.notifier).createContent(content);

      if (!mounted) return;
      setState(() {
        _uploadProgress = 1.0;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedType.name[0].toUpperCase()}${_selectedType.name.substring(1)} uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go(AppRouter.myProfile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              if (_selectedType != ContentType.post)
                InkWell(
                  onTap: _isCompressing ? null : _pickFile,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: _pickedFile != null
                          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _pickedFile != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isCompressing) ...[
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text('Compressing video...', style: theme.textTheme.titleMedium),
                        ] else if (_selectedType == ContentType.photo && _pickedBytes != null)
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(_pickedBytes!, fit: BoxFit.cover, width: double.infinity),
                            ),
                          )
                        else ...[
                          Icon(
                            _pickedFile != null
                                ? Icons.check_circle
                                : _selectedType == ContentType.video
                                    ? Icons.videocam
                                    : Icons.photo_library,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _pickedFile != null
                                ? _pickedFile!.name
                                : _selectedType == ContentType.video
                                    ? 'Tap to select video'
                                    : 'Tap to select photo',
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          if (_selectedType == ContentType.video && _pickedFile == null)
                            Text(
                              'MP4, max 100MB. Compressed automatically.',
                              style: theme.textTheme.bodySmall,
                            ),
                          if (_selectedType == ContentType.photo && _pickedFile == null)
                            Text(
                              'JPG, PNG. Max 10MB.',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
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
        onTap: () => setState(() {
          _selectedType = type;
          _pickedFile = null;
          _pickedBytes = null;
        }),
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