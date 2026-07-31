import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/core/supabase/supabase_config.dart';
import 'package:play_smart/profiles/providers/profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  XFile? _pickedImage;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    final authState = ref.read(authProvider);

    String name = '';
    String email = '';
    if (profile != null) {
      name = profile.displayName;
      _currentPhotoUrl = profile.photoUrl;
    }
    if (authState is AuthAuthenticated) {
      email = authState.user.email;
      if (name.isEmpty) name = authState.user.name;
    }

    _nameController = TextEditingController(text: name);
    _emailController = TextEditingController(text: email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final profile = ref.read(profileProvider).value;
      final authState = ref.read(authProvider);

      if (profile == null || authState is! AuthAuthenticated) {
        throw Exception("Session profile not loaded.");
      }

      String? newPhotoUrl = _currentPhotoUrl;

      // 1. Upload new profile picture if picked
      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        final ext = _pickedImage!.name.split('.').last;
        final filename = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
        
        newPhotoUrl = await ref.read(profileRepositoryProvider).uploadAvatar(
          userId: authState.user.id,
          filename: filename,
          bytes: bytes,
        );
      }

      // 2. Update Supabase Auth email / password
      final emailVal = _emailController.text.trim();
      final passwordVal = _passwordController.text.trim();

      if (emailVal != authState.user.email || passwordVal.isNotEmpty) {
        await supabase.auth.updateUser(
          UserAttributes(
            email: emailVal != authState.user.email ? emailVal : null,
            password: passwordVal.isNotEmpty ? passwordVal : null,
          ),
        );
      }

      // 3. Update public users database profile row
      await supabase.from('users').update({
        'name': _nameController.text.trim(),
      }).eq('id', authState.user.id);

      // 4. Update athletes database table row
      final updatedAthlete = profile.copyWith(
        displayName: _nameController.text.trim(),
        photoUrl: newPhotoUrl,
      );

      await ref.read(profileProvider.notifier).updateProfile(updatedAthlete);
      await ref.read(authProvider.notifier).checkSession(); // Refresh auth user state

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar picker
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 56,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              backgroundImage: _pickedImage != null
                                  ? FileImage(File(_pickedImage!.path)) as ImageProvider
                                  : (_currentPhotoUrl != null
                                      ? NetworkImage(_currentPhotoUrl!) as ImageProvider
                                      : null),
                              child: (_pickedImage == null && _currentPhotoUrl == null)
                                  ? const Icon(Icons.person, size: 56)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'New Password (optional)',
                        prefixIcon: Icon(Icons.lock_outline),
                        helperText: 'Leave blank to keep current password',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
