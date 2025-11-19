import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_router.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/domain/profile_status.dart';
import '../../profile/domain/user_profile.dart';

class DashboardScaffold extends ConsumerWidget {
  const DashboardScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile?.fullName ?? 'Welcome',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (profile != null) ...[
              Text(
                profile.role.label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    label: Text(profile.status.label),
                    backgroundColor: _statusColor(profile.status),
                  ),
                  if (profile.role.isStaff)
                    const Chip(
                      label: Text('Staff'),
                      backgroundColor: Color(0xFF3949AB),
                    ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'View profile',
            onPressed: () => context.pushNamed(AppRoute.profile.name),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Manage profile',
            onPressed: () => context.pushNamed(AppRoute.profileManage.name),
            icon: const Icon(Icons.manage_accounts_outlined),
          ),
          IconButton(
            tooltip: 'Messages',
            onPressed: () => context.pushNamed(AppRoute.messages.name),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: isWide ? 2 : 0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: _ProfileOverview(profile: profile),
                  ),
                ),
                SizedBox(width: isWide ? 24 : 0, height: isWide ? 0 : 24),
                Expanded(child: child),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileOverview extends StatelessWidget {
  const _ProfileOverview({this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person_outline, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              profile?.fullName ?? 'Complete your profile',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              profile?.profession ?? 'Add your profession to be discovered',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            _QuickDetail(
              icon: Icons.location_on_outlined,
              label: profile?.location ?? 'Set your base location',
            ),
            const SizedBox(height: 12),
            _QuickDetail(
              icon: Icons.public,
              label: profile?.email ?? 'Update contact email',
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pushNamed(AppRoute.profile.name),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Complete profile setup'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickDetail extends StatelessWidget {
  const _QuickDetail({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

Color _statusColor(ProfileStatus status) {
  switch (status) {
    case ProfileStatus.approved:
      return Colors.green.withValues(alpha: 0.2);
    case ProfileStatus.pending:
      return Colors.orange.withValues(alpha: 0.2);
    case ProfileStatus.rejected:
      return Colors.red.withValues(alpha: 0.2);
    case ProfileStatus.suspended:
      return Colors.grey.withValues(alpha: 0.2);
  }
}
