import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';

class RejectedProfilePage extends ConsumerWidget {
  const RejectedProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).profile;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.report_problem,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Profile needs updates',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Our editorial team couldn’t approve your submission yet. '
                        'Please address the feedback below and resubmit for review.',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          profile?.reviewNotes?.isNotEmpty == true
                              ? profile!.reviewNotes!
                              : 'No reviewer notes provided. Please contact support.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.redAccent),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Next steps',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const _NextStep(
                        text:
                            'Update your profile details and portfolio assets.',
                      ),
                      const _NextStep(
                        text:
                            'Ensure media links are accessible and represent your latest work.',
                      ),
                      const _NextStep(
                        text:
                            'Hit “Resubmit for review” and we’ll take another look within 24-48h.',
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => ref
                                .read(authControllerProvider.notifier)
                                .refreshProfile(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Check again'),
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

class _NextStep extends StatelessWidget {
  const _NextStep({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check, size: 18, color: Colors.greenAccent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
