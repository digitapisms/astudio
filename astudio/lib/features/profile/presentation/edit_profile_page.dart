import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/profile_repository.dart';
import '../domain/profile_update_input.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _professionController;
  late final TextEditingController _locationController;
  late final TextEditingController _bioController;
  late final TextEditingController _ageController;
  late final TextEditingController _skillsController;
  late final TextEditingController _languagesController;
  late final TextEditingController _instagramController;
  late final TextEditingController _youtubeController;
  late final TextEditingController _tiktokController;
  late final TextEditingController _websiteController;
  String? _gender;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authControllerProvider).profile;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _professionController =
        TextEditingController(text: profile?.profession ?? '');
    _locationController = TextEditingController(text: profile?.location ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _ageController =
        TextEditingController(text: profile?.age?.toString() ?? '');
    _skillsController =
        TextEditingController(text: profile?.skills.join(', ') ?? '');
    _languagesController =
        TextEditingController(text: profile?.languages.join(', ') ?? '');
    _instagramController =
        TextEditingController(text: profile?.instagram ?? '');
    _youtubeController = TextEditingController(text: profile?.youtube ?? '');
    _tiktokController = TextEditingController(text: profile?.tiktok ?? '');
    _websiteController = TextEditingController(text: profile?.website ?? '');
    _gender = profile?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _skillsController.dispose();
    _languagesController.dispose();
    _instagramController.dispose();
    _youtubeController.dispose();
    _tiktokController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authControllerProvider).profile;
    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _professionController,
                decoration: const InputDecoration(labelText: 'Profession'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration:
                    const InputDecoration(labelText: 'Primary location'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(
                      value: 'non_binary', child: Text('Non-binary')),
                  DropdownMenuItem(value: 'prefer_not', child: Text('Prefer not to say')),
                ],
                onChanged: (value) => setState(() => _gender = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: 'Skills (comma separated)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _languagesController,
                decoration: const InputDecoration(
                  labelText: 'Languages (comma separated)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _instagramController,
                decoration: const InputDecoration(labelText: 'Instagram'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _youtubeController,
                decoration: const InputDecoration(labelText: 'YouTube'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tiktokController,
                decoration: const InputDecoration(labelText: 'TikTok'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(labelText: 'Website'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = ref.read(authControllerProvider).profile;
    if (profile == null) return;
    setState(() => _isSaving = true);
    final repo = ref.read(profileRepositoryProvider);
    try {
      final input = ProfileUpdateInput(
        id: profile.id,
        fullName: _nameController.text.trim(),
        profession: _professionController.text.trim().isEmpty
            ? null
            : _professionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        gender: _gender,
        age: int.tryParse(_ageController.text.trim()),
        skills: _parseList(_skillsController.text),
        languages: _parseList(_languagesController.text),
        instagram: _instagramController.text.trim().isEmpty
            ? null
            : _instagramController.text.trim(),
        youtube: _youtubeController.text.trim().isEmpty
            ? null
            : _youtubeController.text.trim(),
        tiktok: _tiktokController.text.trim().isEmpty
            ? null
            : _tiktokController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
      );

      await repo.updateProfileDetails(input);
      await ref.read(authControllerProvider.notifier).refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  List<String> _parseList(String input) {
    return input
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

