import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../router/app_router.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/domain/profile_status.dart';
import '../../profile/domain/user_role.dart';
import '../../auditions/application/audition_providers.dart';
import '../../auditions/data/audition_repository.dart';
import '../../auditions/domain/audition_request.dart';
import '../application/casting_providers.dart';
import '../data/casting_repository.dart';
import '../domain/casting_application.dart';
import '../domain/casting_call.dart';

class CastingDetailPage extends ConsumerWidget {
  const CastingDetailPage({
    super.key,
    required this.castingId,
  });

  final String castingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final castingAsync = ref.watch(castingDetailProvider(castingId));
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile;
    final isProducer =
        profile?.role == UserRole.producer || profile?.role.isStaff == true;

    final castingData = castingAsync.asData?.value;
    final canEdit = castingData?.isMine == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Casting details'),
        actions: [
          if (canEdit && castingData != null)
            IconButton(
              tooltip: 'Edit casting',
              onPressed: () => context.pushNamed(
                AppRoute.castingEdit.name,
                pathParameters: {'castingId': castingData.id},
              ),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: castingAsync.when(
        data: (casting) => _CastingDetailBody(
          casting: casting,
          isProducer: isProducer,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('Unable to load casting: $error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(castingDetailProvider(castingId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CastingDetailBody extends ConsumerWidget {
  const _CastingDetailBody({
    required this.casting,
    required this.isProducer,
  });

  final CastingCall casting;
  final bool isProducer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).profile;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  casting.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(casting.description),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (casting.category != null)
                      _DetailChip(
                        icon: Icons.category_outlined,
                        label: casting.category!,
                      ),
                    if (casting.budget != null)
                      _DetailChip(
                        icon: Icons.payments,
                        label: casting.budget!,
                      ),
                    if (casting.city != null)
                      _DetailChip(
                        icon: Icons.location_on_outlined,
                        label: casting.city!,
                      ),
                    if (casting.applicationDeadline != null)
                      _DetailChip(
                        icon: Icons.schedule,
                        label:
                            'Apply by ${_formatDate(casting.applicationDeadline!)}',
                      ),
                    if (casting.shootDate != null)
                      _DetailChip(
                        icon: Icons.movie_creation_outlined,
                        label: 'Shoot ${_formatDate(casting.shootDate!)}',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (casting.requirements.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Requirements',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...casting.requirements.map(
                        (req) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.check_circle_outline),
                          title: Text(req),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                if (!isProducer &&
                    profile != null &&
                    profile.status == ProfileStatus.approved)
                  ElevatedButton.icon(
                    onPressed: () => _showApplicationSheet(
                      context,
                      ref,
                      castingId: casting.id,
                      talentId: profile.id,
                    ),
                    icon: const Icon(Icons.send),
                    label: Text(
                      casting.hasApplied ? 'Application submitted' : 'Apply now',
                    ),
                  ),
                if (!isProducer && profile?.status != ProfileStatus.approved)
                  Text(
                    'Your profile must be approved before applying to castings.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                if (isProducer)
                  OutlinedButton.icon(
                    onPressed: () => _navigateToApplications(context, casting.id),
                    icon: const Icon(Icons.people_outline),
                    label: const Text('View applications'),
                  ),
              ],
            ),
          ),
        ),
        if (isProducer) ...[
          _ProducerApplicationsSection(castingId: casting.id),
          const SizedBox(height: 16),
          _ProducerAuditionsSection(castingId: casting.id),
        ],
      ],
    );
  }

  Future<void> _showApplicationSheet(
    BuildContext context,
    WidgetRef ref, {
    required String castingId,
    required String talentId,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CastingApplicationSheet(
        castingId: castingId,
        talentId: talentId,
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted!')),
      );
      ref.invalidate(castingDetailProvider(castingId));
    }
  }

  void _navigateToApplications(BuildContext context, String castingId) {
    context.pushNamed(
      AppRoute.castingApplications.name,
      pathParameters: {'castingId': castingId},
    );
  }
}

class CastingApplicationSheet extends ConsumerStatefulWidget {
  const CastingApplicationSheet({
    super.key,
    required this.castingId,
    required this.talentId,
  });

  final String castingId;
  final String talentId;

  @override
  ConsumerState<CastingApplicationSheet> createState() =>
      _CastingApplicationSheetState();
}

class _CastingApplicationSheetState
    extends ConsumerState<CastingApplicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  final _mediaController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _coverLetterController.dispose();
    _mediaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submit application',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _coverLetterController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Cover letter',
                hintText: 'Tell the casting team why you are a great fit.',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Cover letter is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mediaController,
              decoration: const InputDecoration(
                labelText: 'Media links (comma separated)',
                hintText: 'e.g. headshots, reels, drive links',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send application'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final repo = ref.read(castingRepositoryProvider);
    try {
      final media =
          _mediaController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      await repo.submitApplication(
        castingId: widget.castingId,
        talentId: widget.talentId,
        coverLetter: _coverLetterController.text.trim(),
        mediaUrls: media,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _ProducerApplicationsSection extends ConsumerWidget {
  const _ProducerApplicationsSection({required this.castingId});

  final String castingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(castingApplicationsProvider(castingId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent applications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            applicationsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Text('No applications yet.');
                }
                return Column(
                  children: [
                    for (final application in items.take(5))
                      _ApplicationTile(application: application),
                    if (items.length > 5)
                      TextButton(
                        onPressed: () => context.pushNamed(
                          AppRoute.castingApplications.name,
                          pathParameters: {'castingId': castingId},
                        ),
                        child: const Text('View all applications'),
                      ),
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Text(
                'Unable to load applications: $error',
                style: const TextStyle(color: AppColors.errorRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProducerAuditionsSection extends ConsumerWidget {
  const _ProducerAuditionsSection({required this.castingId});

  final String castingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditionsAsync = ref.watch(castingAuditionsProvider(castingId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audition requests',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            auditionsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Text('No audition requests created yet.');
                }
                return Column(
                  children: [
                    for (final audition in items)
                      _AuditionAdminTile(
                        audition: audition,
                        castingId: castingId,
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Text('Unable to load auditions: $error'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditionAdminTile extends ConsumerWidget {
  const _AuditionAdminTile({
    required this.audition,
    required this.castingId,
  });

  final AuditionRequest audition;
  final String castingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(auditionRepositoryProvider);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(audition.talentName ?? 'Talent'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (audition.instructions?.isNotEmpty == true)
            Text(audition.instructions!),
          if (audition.dueDate != null)
            Text('Due ${_formatDate(audition.dueDate!)}'),
          if (audition.submissionUrl?.isNotEmpty == true)
            SelectableText(
              audition.submissionUrl!,
              style: const TextStyle(color: Colors.blueAccent),
            ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          await repo.reviewSubmission(
            auditionId: audition.id,
            status: value,
          );
          ref.invalidate(castingAuditionsProvider(castingId));
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'confirmed',
            child: Text('Mark confirmed'),
          ),
          PopupMenuItem(
            value: 'reviewed',
            child: Text('Mark reviewed'),
          ),
          PopupMenuItem(
            value: 'cancelled',
            child: Text('Cancel request'),
          ),
        ],
        child: Chip(
          label: Text(audition.status.label),
        ),
      ),
    );
  }
}

class _ApplicationTile extends ConsumerWidget {
  const _ApplicationTile({required this.application});

  final CastingApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(application.status);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.charcoal.withValues(alpha: 0.3),
        child: Text(
          application.talentSummary?.fullName.substring(0, 1).toUpperCase() ??
              '?',
        ),
      ),
      title: Text(application.talentSummary?.fullName ?? 'Unknown talent'),
      subtitle: Text(application.coverLetter ?? ''),
      trailing: Chip(
        label: Text(application.status),
        backgroundColor: statusColor.withValues(alpha: 0.2),
        labelStyle: TextStyle(color: statusColor),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'shortlisted':
      return Colors.blueAccent;
    case 'declined':
      return AppColors.errorRed;
    case 'hired':
      return Colors.greenAccent;
    default:
      return Colors.orangeAccent;
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

