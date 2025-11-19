import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:another_flushbar/flushbar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shimmer_blocks.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile_status.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/domain/user_role.dart';
import 'dashboard_scaffold.dart';

final pendingProfilesProvider = FutureProvider.autoDispose<List<UserProfile>>(
  (ref) async {
    final repo = ref.watch(profileRepositoryProvider);
    return repo.fetchPendingProfiles();
  },
);

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() =>
      _AdminDashboardPageState();
}

class _AdminDashboardPageState
    extends ConsumerState<AdminDashboardPage> {
  UserRole? _roleFilter;
  String _dateFilter = 'any';
  final Set<String> _selection = <String>{};
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingProfilesProvider);

    return DashboardScaffold(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pendingProfilesProvider);
          await ref.read(authControllerProvider.notifier).refreshProfile();
        },
        child: ListView(
          children: [
            Text(
              'Admin Control Center',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Review pending profiles, approve creators, and keep the marketplace in top shape.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            pendingAsync.when(
              data: (profiles) => _PendingProfilesList(
                profiles: profiles,
                roleFilter: _roleFilter,
                dateFilter: _dateFilter,
                selection: _selection,
                isProcessing: _isProcessing,
                onRoleChanged: (role) => setState(() => _roleFilter = role),
                onDateChanged: (value) => setState(() => _dateFilter = value),
                onToggleSelection: _toggleSelection,
                onClearSelection: () =>
                    setState(() => _selection.clear()),
                onApproveSelection: () => _handleBulkAction(
                  ProfileStatus.approved,
                ),
                onRejectSelection: () => _handleBulkAction(
                  ProfileStatus.rejected,
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerList(itemCount: 3, itemHeight: 120),
              ),
              error: (error, stackTrace) => _ErrorState(error: error),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selection.contains(id)) {
        _selection.remove(id);
      } else {
        _selection.add(id);
      }
    });
  }

  Future<void> _handleBulkAction(ProfileStatus status) async {
    if (_selection.isEmpty || _isProcessing) return;
    String? notes;
    if (status == ProfileStatus.rejected) {
      notes = await _promptNotes();
      if (notes == null) return;
    }

    setState(() => _isProcessing = true);
    final repo = ref.read(profileRepositoryProvider);
    try {
      await repo.bulkReviewProfiles(
        profileIds: _selection.toList(),
        status: status,
        notes: notes,
      );
      ref.invalidate(pendingProfilesProvider);
      setState(() => _selection.clear());
      if (!mounted) return;
      Flushbar(
        title: 'Success',
        message:
            'Updated ${status == ProfileStatus.approved ? 'approved' : 'rejected'} profiles.',
        duration: const Duration(seconds: 3),
      ).show(context);
    } catch (e) {
      if (!mounted) return;
      Flushbar(
        title: 'Error',
        message: 'Bulk action failed: $e',
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.errorRed,
      ).show(context);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<String?> _promptNotes() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add reviewer notes'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Let the talent know why it was rejected',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      return controller.text.trim();
    }
    return null;
  }
}

class _PendingProfilesList extends StatelessWidget {
  const _PendingProfilesList({
    required this.profiles,
    required this.roleFilter,
    required this.dateFilter,
    required this.selection,
    required this.isProcessing,
    required this.onRoleChanged,
    required this.onDateChanged,
    required this.onToggleSelection,
    required this.onClearSelection,
    required this.onApproveSelection,
    required this.onRejectSelection,
  });

  final List<UserProfile> profiles;
  final UserRole? roleFilter;
  final String dateFilter;
  final Set<String> selection;
  final bool isProcessing;
  final ValueChanged<UserRole?> onRoleChanged;
  final ValueChanged<String> onDateChanged;
  final void Function(String id) onToggleSelection;
  final VoidCallback onClearSelection;
  final Future<void> Function() onApproveSelection;
  final Future<void> Function() onRejectSelection;

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.inbox_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                'No pending profiles',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'New submissions that need review will appear here.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final filtered = profiles.where((profile) {
      final matchesRole = roleFilter == null || profile.role == roleFilter;
      final createdAt = profile.createdAt;
      bool matchesDate = true;
      if (dateFilter != 'any' && createdAt != null) {
        final days = dateFilter == '7' ? 7 : 30;
        matchesDate = createdAt.isAfter(now.subtract(Duration(days: days)));
      }
      return matchesRole && matchesDate;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending approvals',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilterChip(
              label: const Text('All roles'),
              selected: roleFilter == null,
              onSelected: (_) => onRoleChanged(null),
            ),
            for (final role in [UserRole.artist, UserRole.producer])
              FilterChip(
                label: Text(role.label),
                selected: roleFilter == role,
                onSelected: (_) =>
                    onRoleChanged(roleFilter == role ? null : role),
              ),
            DropdownButton<String>(
              value: dateFilter,
              items: const [
                DropdownMenuItem(value: 'any', child: Text('Any time')),
                DropdownMenuItem(value: '7', child: Text('Last 7 days')),
                DropdownMenuItem(value: '30', child: Text('Last 30 days')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onDateChanged(value);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (selection.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text('${selection.length} selected'),
                  const Spacer(),
                  FilledButton(
                    onPressed: isProcessing ? null : onApproveSelection,
                    child: const Text('Approve'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: isProcessing ? null : onRejectSelection,
                    child: const Text('Reject'),
                  ),
                  IconButton(
                    tooltip: 'Clear selection',
                    onPressed: isProcessing ? null : onClearSelection,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No profiles match the selected filters.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
            ),
          )
        else
          AnimationLimiter(
            child: Column(
              children: [
                for (var i = 0; i < filtered.length; i++)
                  AnimationConfiguration.staggeredList(
                    position: i,
                    duration: const Duration(milliseconds: 250),
                    child: SlideAnimation(
                      verticalOffset: 40,
                      child: FadeInAnimation(
                        child: _ReviewCard(
                          filtered[i],
                          selected: selection.contains(filtered[i].id),
                          onToggleSelection: () =>
                              onToggleSelection(filtered[i].id),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard(
    this.profile, {
    required this.selected,
    required this.onToggleSelection,
  });

  final UserProfile profile;
  final bool selected;
  final VoidCallback onToggleSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (_) => onToggleSelection(),
                ),
                CircleAvatar(
                  backgroundImage: profile.avatarUrl != null
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null
                      ? Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName[0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        profile.role.label,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(profile.status.label),
                  backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (profile.bio != null && profile.bio!.isNotEmpty)
              Text(profile.bio!, style: Theme.of(context).textTheme.bodyMedium),
            if (profile.bio != null) const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _handleReview(
                    context,
                    ref,
                    status: ProfileStatus.approved,
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context, ref),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReview(
    BuildContext context,
    WidgetRef ref, {
    required ProfileStatus status,
    String? notes,
  }) async {
    final repo = ref.read(profileRepositoryProvider);
    try {
      await repo.reviewProfile(
        profileId: profile.id,
        status: status,
        notes: notes,
      );
      ref.invalidate(pendingProfilesProvider);
      if (!context.mounted) return;
      final successFlushbar = Flushbar(
        title: 'Success',
        message: '${profile.fullName} marked as ${status.label.toLowerCase()}',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        leftBarIndicatorColor: Colors.green[300],
        borderRadius: BorderRadius.circular(12),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
      );
      successFlushbar.show(context);
    } catch (e) {
      if (!context.mounted) return;
      final errorFlushbar = Flushbar(
        title: 'Error',
        message: 'Failed to update profile: $e',
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.errorRed,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        leftBarIndicatorColor: AppColors.errorRed.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
      );
      errorFlushbar.show(context);
    }
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add reviewer notes'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Let the talent know why it was rejected',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Reject profile'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      await _handleReview(
        context,
        ref,
        status: ProfileStatus.rejected,
        notes: controller.text.trim().isEmpty ? null : controller.text.trim(),
      );
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unable to load pending profiles',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}
