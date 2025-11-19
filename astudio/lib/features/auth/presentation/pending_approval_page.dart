import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/profile_status.dart';
import '../application/auth_controller.dart';

class PendingApprovalPage extends ConsumerWidget {
  const PendingApprovalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 64,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Profile under review',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Thanks ${profile?.fullName ?? ''}! Our editorial team is reviewing your profile '
                        'to keep the marketplace high-quality and safe. You will receive an email once approved.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _StatusTimeline(status: profile?.status),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => ref
                                .read(authControllerProvider.notifier)
                                .refreshProfile(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Check status'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => ref
                                .read(authControllerProvider.notifier)
                                .signOut(),
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign out'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Need help? Contact approvals@actorstudio.global',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({this.status});

  final ProfileStatus? status;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimelineTile(
          isActive: true,
          title: 'Submission received',
          subtitle: 'We have your talent profile',
        ),
        _TimelineTile(
          isActive: status?.isAwaitingReview ?? true,
          title: 'Under editorial review',
          subtitle: 'Our staff validates portfolio and identity',
        ),
        _TimelineTile(
          isActive: status?.isActive ?? false,
          title: 'Published to marketplace',
          subtitle: 'Once approved, your profile is searchable worldwide',
        ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.title,
    required this.subtitle,
    required this.isActive,
  });

  final String title;
  final String subtitle;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isActive ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isActive ? Colors.greenAccent : Colors.white24,
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
      ),
    );
  }
}
