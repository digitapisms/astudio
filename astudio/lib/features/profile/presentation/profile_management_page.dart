import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/storage_repository.dart';
import '../../../core/widgets/shimmer_blocks.dart';
import '../../../router/app_router.dart';
import '../../auth/application/auth_controller.dart';
import '../application/profile_providers.dart';
import '../data/profile_repository.dart';
import '../domain/portfolio_media.dart';
import '../domain/profile_update_input.dart';
import '../domain/user_profile.dart';
import 'portfolio_item_sheet.dart';

class ProfileManagementPage extends ConsumerStatefulWidget {
  const ProfileManagementPage({super.key});

  @override
  ConsumerState<ProfileManagementPage> createState() =>
      _ProfileManagementPageState();
}

class _ProfileManagementPageState
    extends ConsumerState<ProfileManagementPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _professionController;
  late final TextEditingController _locationController;
  late final TextEditingController _bioController;
  late final TextEditingController _skillsController;
  late final TextEditingController _languagesController;
  late final TextEditingController _instagramController;
  late final TextEditingController _youtubeController;
  late final TextEditingController _tiktokController;
  late final TextEditingController _websiteController;

  String? _gender;
  String? _avatarUrl;
  String? _bannerUrl;
  bool _isVisible = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingBanner = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authControllerProvider).profile;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _professionController =
        TextEditingController(text: profile?.profession ?? '');
    _locationController = TextEditingController(text: profile?.location ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
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
    _avatarUrl = profile?.avatarUrl;
    _bannerUrl = profile?.bannerUrl;
    _isVisible = profile?.isVisible ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    _locationController.dispose();
    _bioController.dispose();
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
    final portfolioAsync = ref.watch(portfolioProvider(profile.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile management'),
        actions: [
          IconButton(
            tooltip: 'Preview public profile',
            onPressed: () => context.pushNamed(AppRoute.profile.name),
            icon: const Icon(Icons.visibility_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(portfolioProvider(profile.id));
          await ref.read(authControllerProvider.notifier).refreshProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _MediaHeader(
                  avatarUrl: _avatarUrl,
                  bannerUrl: _bannerUrl,
                  onAvatarTap: () => _pickImage(isBanner: false),
                  onBannerTap: () => _pickImage(isBanner: true),
                  uploadingAvatar: _isUploadingAvatar,
                  uploadingBanner: _isUploadingBanner,
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Talent basics',
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
                      decoration:
                          const InputDecoration(labelText: 'Primary role'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration:
                          const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_gender),
                      initialValue: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'non_binary',
                          child: Text('Non-binary'),
                        ),
                        DropdownMenuItem(
                          value: 'prefer_not',
                          child: Text('Prefer not to say'),
                        ),
                      ],
                      onChanged: (value) => setState(() => _gender = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      maxLines: 5,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Skills & languages',
                  children: [
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
                    SwitchListTile(
                      value: _isVisible,
                      onChanged: (value) => setState(() => _isVisible = value),
                      title: const Text('Visible to producers'),
                      subtitle: const Text(
                        'Only approved profiles with visibility on appear in searches.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Social & web',
                  children: [
                    TextFormField(
                      controller: _instagramController,
                      decoration:
                          const InputDecoration(labelText: 'Instagram handle'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _youtubeController,
                      decoration:
                          const InputDecoration(labelText: 'YouTube URL'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tiktokController,
                      decoration:
                          const InputDecoration(labelText: 'TikTok handle'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _websiteController,
                      decoration:
                          const InputDecoration(labelText: 'Website / Linktree'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Media gallery',
                  trailing: TextButton.icon(
                    onPressed: () => _openPortfolioSheet(profile.id),
                    icon: const Icon(Icons.add),
                    label: const Text('Add media'),
                  ),
                  children: [
                    portfolioAsync.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return const Text(
                            'Upload headshots, showreels or audio clips to stand out.',
                          );
                        }
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final media = items[index];
                            return _PortfolioTile(
                              media: media,
                              onEdit: () => _openPortfolioSheet(
                                profile.id,
                                existing: media,
                              ),
                              onDelete: () async {
                                final repo =
                                    ref.read(profileRepositoryProvider);
                                await repo.deletePortfolioMedia(media.id);
                                ref.invalidate(portfolioProvider(profile.id));
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: ShimmerList(itemCount: 2, itemHeight: 120),
                      ),
                      error: (error, stackTrace) => Text(
                        'Unable to load media: $error',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : () => _save(profile),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPortfolioSheet(
    String profileId, {
    PortfolioMedia? existing,
  }) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PortfolioItemSheet(
        profileId: profileId,
        existing: existing,
      ),
    );
    if (added == true) {
      ref.invalidate(portfolioProvider(profileId));
    }
  }

  Future<void> _pickImage({required bool isBanner}) async {
    setState(() {
      if (isBanner) {
        _isUploadingBanner = true;
      } else {
        _isUploadingAvatar = true;
      }
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) {
        setState(() {
          _isUploadingAvatar = false;
          _isUploadingBanner = false;
        });
        return;
      }
      final storage = ref.read(storageRepositoryProvider);
      final file = result.files.single;
      final url = await storage.uploadProfileImage(
        profileId: ref.read(authControllerProvider).profile!.id,
        file: file,
        folder: isBanner ? 'banners' : 'avatars',
      );
      setState(() {
        if (isBanner) {
          _bannerUrl = url;
        } else {
          _avatarUrl = url;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
          _isUploadingBanner = false;
        });
      }
    }
  }

  Future<void> _save(UserProfile profile) async {
    if (!_formKey.currentState!.validate()) return;
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
        skills: _skillsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        languages: _languagesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
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
        avatarUrl: _avatarUrl,
        bannerUrl: _bannerUrl,
        isVisible: _isVisible,
      );
      await repo.updateProfileDetails(input);
      await ref.read(authControllerProvider.notifier).refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MediaHeader extends StatelessWidget {
  const _MediaHeader({
    required this.avatarUrl,
    required this.bannerUrl,
    required this.onAvatarTap,
    required this.onBannerTap,
    required this.uploadingAvatar,
    required this.uploadingBanner,
  });

  final String? avatarUrl;
  final String? bannerUrl;
  final VoidCallback onAvatarTap;
  final VoidCallback onBannerTap;
  final bool uploadingAvatar;
  final bool uploadingBanner;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: uploadingBanner ? null : onBannerTap,
            child: Ink(
              height: 150,
              decoration: BoxDecoration(
                image: bannerUrl != null
                    ? DecorationImage(
                        image: NetworkImage(bannerUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: Colors.blueGrey.withValues(alpha: 0.2),
              ),
              child: Center(
                child: uploadingBanner
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.photo_camera_outlined),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: InkWell(
              onTap: uploadingAvatar ? null : onAvatarTap,
              child: CircleAvatar(
                radius: 40,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: uploadingAvatar
                    ? const CircularProgressIndicator()
                    : avatarUrl == null
                        ? const Icon(Icons.person_outline, size: 32)
                        : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  const _PortfolioTile({
    required this.media,
    required this.onEdit,
    required this.onDelete,
  });

  final PortfolioMedia media;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              media.mediaUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.black26,
                alignment: Alignment.center,
                child: const Icon(Icons.insert_drive_file_outlined),
              ),
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: Card(
            color: Colors.black54,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

