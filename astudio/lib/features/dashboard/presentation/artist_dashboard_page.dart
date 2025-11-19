import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/shimmer_blocks.dart';
import '../../../router/app_router.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../dashboard/domain/profile_metrics.dart';
import '../../notifications/application/notification_providers.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/domain/app_notification.dart';
import 'dashboard_scaffold.dart';

class ArtistDashboardPage extends ConsumerWidget {
  const ArtistDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(profileMetricsProvider);
    final notificationsAsync = ref.watch(notificationFeedProvider);

    ref.listen(notificationFeedProvider, (previous, next) {
      final previousUnread = previous?.maybeWhen(
            data: (data) =>
                data.where((n) => n.isUnread).map((n) => n.id).toSet(),
            orElse: () => <String>{},
          ) ??
          <String>{};
      final newUnread = next.maybeWhen(
        data: (data) => data
            .where((n) => n.isUnread && !previousUnread.contains(n.id))
            .toList(),
        orElse: () => <AppNotification>[],
      );
      if (newUnread.isNotEmpty && context.mounted) {
        Flushbar(
          title: 'New update',
          message: newUnread.first.title,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.notifications_active, color: Colors.white),
        ).show(context);
      }
    });

    return DashboardScaffold(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 48),
        children: [
          metricsAsync.when(
            data: (metrics) => _MetricsRow(metrics: metrics),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(itemCount: 1, itemHeight: 90),
            ),
            error: (error, _) => _ErrorBanner(
              message: 'Unable to load insights: $error',
            ),
          ),
          const SizedBox(height: 16),
          const _CastingShortcutCard(),
          const SizedBox(height: 16),
          const _LearningShortcutCard(),
          const SizedBox(height: 16),
          const _AuditionShortcutCard(),
          const SizedBox(height: 24),
          _NextStepsCard(
            onManageProfile: () =>
                context.pushNamed(AppRoute.profileManage.name),
          ),
          const SizedBox(height: 24),
          notificationsAsync.when(
            data: (items) => _NotificationFeedCard(
              notifications: items,
              onTap: (notification) async {
                if (notification.readAt != null) return;
                final repo = ref.read(notificationRepositoryProvider);
                await repo.markAsRead(notification.id);
                ref.invalidate(notificationFeedProvider);
              },
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ShimmerList(itemCount: 2, itemHeight: 70),
            ),
            error: (error, _) =>
                _ErrorBanner(message: 'Feed unavailable: $error'),
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.metrics});

  final ProfileMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _MetricCard(
              label: 'Profile views',
              value: metrics.profileViews.toString(),
              subtitle: metrics.lastProfileView != null
                  ? 'Last visit ${metrics.lastProfileView}'
                  : 'No visits logged',
              icon: Icons.insights_outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricCard(
              label: 'Shortlists',
              value: metrics.saves.toString(),
              subtitle: 'Casting director interest',
              icon: Icons.bookmark_add_outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricCard(
              label: 'Audition invites',
              value: metrics.auditionInvites.toString(),
              subtitle: 'Across all projects',
              icon: Icons.event_available_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label),
            Text(
              subtitle,
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
}

class _CastingShortcutCard extends StatelessWidget {
  const _CastingShortcutCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white12,
              child: Icon(Icons.campaign_outlined, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore casting board',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse live auditions curated for your profile and apply in a few taps.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => context.pushNamed(AppRoute.castings.name),
              child: const Text('Open board'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningShortcutCard extends StatelessWidget {
  const _LearningShortcutCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white12,
              child: Icon(Icons.school_outlined, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Training & courses',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sharpen your craft with curated lessons, quizzes, and workbooks.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => context.pushNamed(AppRoute.learning.name),
              child: const Text('Learning hub'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditionShortcutCard extends StatelessWidget {
  const _AuditionShortcutCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white12,
              child: Icon(Icons.music_note_outlined, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audition inbox',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track callbacks, upload self tapes, and chat with producers.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => context.pushNamed(AppRoute.auditions.name),
              child: const Text('View inbox'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard({required this.onManageProfile});

  final VoidCallback onManageProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Boost your visibility',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete these quick wins to show up at the top of casting searches.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _CheckStep(
                    icon: Icons.photo_camera_outlined,
                    label: 'Upload headshots',
                  ),
                  _CheckStep(
                    icon: Icons.movie_creation_outlined,
                    label: 'Add reel or VO sample',
                  ),
                  _CheckStep(
                    icon: Icons.public_outlined,
                    label: 'Toggle visibility on',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onManageProfile,
                icon: const Icon(Icons.manage_accounts_outlined),
                label: const Text('Open profile manager'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckStep extends StatelessWidget {
  const _CheckStep({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _NotificationFeedCard extends StatelessWidget {
  const _NotificationFeedCard({
    required this.notifications,
    required this.onTap,
  });

  final List<AppNotification> notifications;
  final void Function(AppNotification notification) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Activity feed',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(
                      '${notifications.where((n) => n.isUnread).length} new',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (notifications.isEmpty)
                const Text(
                  'You’ll see audition reminders, approvals, and casting alerts here.',
                )
              else
                ...notifications.take(5).map(
                      (notification) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          notification.type == NotificationType.profile
                              ? Icons.verified_user_outlined
                              : Icons.notifications_outlined,
                        ),
                        title: Text(notification.title),
                        subtitle: notification.body != null
                            ? Text(notification.body!)
                            : null,
                        trailing: notification.readAt == null
                            ? const Icon(Icons.circle, size: 10)
                            : null,
                        onTap: () => onTap(notification),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.red.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

