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
import 'package:play_smart/discovery/providers/discovery_provider.dart';
import 'package:play_smart/profiles/providers/content_provider.dart';
import 'package:play_smart/profiles/providers/profile_provider.dart';
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
  Uint8List? _pickedThumbnailBytes;

  @override
  void initState() {
    super.initState();
    // Upload is reachable directly from the bottom nav, so the profile may
    // not have been loaded yet (normally done by MyProfileScreen).
    Future.microtask(() => ref.read(profileProvider.notifier).loadMyProfile());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    try {
      final file = await picker.pickMedia();
      if (file == null) return;

      final path = file.path.toLowerCase();
      final isVideo = path.endsWith('.mp4') ||
          path.endsWith('.mov') ||
          path.endsWith('.avi') ||
          path.endsWith('.mkv') ||
          path.endsWith('.webm') ||
          path.endsWith('.3gp');

      setState(() {
        _selectedType = isVideo ? ContentType.video : ContentType.photo;
      });

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

      Uint8List? thumbnailBytes;
      if (_selectedType == ContentType.video && !kIsWeb) {
        // Compress on-device (native Media3/AVFoundation encoders, no
        // external service) before upload — same rationale as photos above.
        // Web has no native compressor, so raw bytes are kept there.
        if (!mounted) return;
        setState(() => _isCompressing = true);
        var videoPathForThumbnail = file.path;
        try {
          final result = await VVideoCompressor().compressVideo(
            file.path,
            const VVideoCompressionConfig.medium(),
          );
          if (result != null) {
            bytes = await File(result.compressedFilePath).readAsBytes();
            videoPathForThumbnail = result.compressedFilePath;
          }
        } catch (_) {
          // keep original bytes
        }
        try {
          // Powers the preview shown in content galleries (My Profile,
          // Athlete Profile) — without this, ContentThumbnail falls back to
          // a generic icon since AthleteContent.thumbnailUrl has nothing to
          // point at.
          final thumbnail = await VVideoCompressor().getVideoThumbnail(
            videoPathForThumbnail,
            const VVideoThumbnailConfig(
              timeMs: 1000,
              maxWidth: 480,
              maxHeight: 480,
              format: VThumbnailFormat.jpeg,
              quality: 75,
            ),
          );
          if (thumbnail != null) {
            thumbnailBytes = await File(thumbnail.thumbnailPath).readAsBytes();
          }
        } catch (_) {
          // no thumbnail — gallery falls back to a placeholder icon
        } finally {
          if (mounted) setState(() => _isCompressing = false);
        }
      }

      if (!mounted) return;
      setState(() {
        _pickedFile = file;
        _pickedBytes = bytes;
        _pickedThumbnailBytes = thumbnailBytes;
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

    // Storage paths are scoped by the auth user id (RLS bucket policy checks
    // the first path segment against auth.uid()); the DB row's athlete_id
    // must be the athlete profile's own id, not the user id — they're
    // different rows (public.athletes.id vs public.users.id).
    final authState = ref.read(authProvider);
    var athlete = ref.read(profileProvider).value;
    if (athlete == null && authState is AuthAuthenticated) {
      // Not loaded yet (e.g. Upload tapped directly from the bottom nav
      // before the initState load finished) — fetch it now rather than
      // wrongly telling an existing athlete to complete their profile.
      await ref.read(profileProvider.notifier).loadMyProfile();
      if (!mounted) return;
      athlete = ref.read(profileProvider).value;
    }
    if (authState is! AuthAuthenticated || athlete == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must complete your profile before uploading.')),
        );
      }
      setState(() => _isUploading = false);
      return;
    }
    final userId = authState.user.id;
    final athleteId = athlete.id;

    try {
      String? fileUrl;
      String? thumbnailUrl;
      if (_pickedBytes != null) {
        // Photos/videos are already compressed at pick time (see _pickFile)
        // — upload the (possibly compressed) bytes as-is.
        final uploadId = DateTime.now().millisecondsSinceEpoch.toString();
        final extension = _selectedType == ContentType.video ? 'mp4' : 'jpg';
        fileUrl = await ref.read(contentRepositoryProvider).uploadContentFile(
              userId: userId,
              contentId: uploadId,
              filename: '$uploadId.$extension',
              bytes: _pickedBytes!,
            );
        if (!mounted) return;
        setState(() => _uploadProgress = 0.7);

        if (_pickedThumbnailBytes != null) {
          thumbnailUrl = await ref.read(contentRepositoryProvider).uploadContentFile(
                userId: userId,
                contentId: uploadId,
                filename: '$uploadId-thumb.jpg',
                bytes: _pickedThumbnailBytes!,
              );
          if (!mounted) return;
        }
      }

      final content = AthleteContent(
        id: '', // assigned by the database
        athleteId: athleteId,
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        fileUrl: fileUrl,
        thumbnailUrl: thumbnailUrl,
        momentTag: _selectedMoment,
      );

      await ref.read(contentProvider.notifier).createContent(content);
      // MyProfileScreen reads athlete.content from profileProvider (the
      // embedded relation), not from contentProvider — refresh it so the
      // gallery shows the new upload. The screen's own state persists across
      // tab switches (StatefulShellRoute), so a stale profileProvider value
      // wouldn't otherwise be refetched just by navigating back to it.
      await ref.read(profileProvider.notifier).loadMyProfile();
      // Same reasoning for the Discover feed — DiscoverScreen only loads
      // once via its own initState, so without this the new post wouldn't
      // show up there until the app restarts.
      await ref.read(discoveryProvider.notifier).loadDiscoverFeed();

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
              // File picker area
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
                              : Icons.perm_media_outlined,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _pickedFile != null
                              ? _pickedFile!.name
                              : 'Tap to select photo or video',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        if (_pickedFile == null)
                          Text(
                            'Supports MP4, JPG, PNG.',
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
                maxLines: 6,
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

}