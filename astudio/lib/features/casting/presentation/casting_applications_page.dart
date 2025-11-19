import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../auditions/application/audition_providers.dart';
import '../../auditions/domain/audition_request.dart';
import '../../auditions/presentation/audition_request_sheet.dart';
import '../../profile/domain/user_role.dart';
import '../application/casting_providers.dart';
import '../data/casting_repository.dart';
import '../domain/casting_application.dart';

class CastingApplicationsPage extends ConsumerWidget {
  const CastingApplicationsPage({
    super.key,
    required this.castingId,
  });

  final String castingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).profile;
    final isProducer =
        profile?.role == UserRole.producer || profile?.role.isStaff == true;

    if (!isProducer) {
      return const Scaffold(
        body: Center(
          child: Text('Only producers and staff can view applications.'),
        ),
      );
    }

    final applicationsAsync = ref.watch(
      castingApplicationsProvider(castingId),
    );
    final auditionsAsync = ref.watch(
      castingAuditionsProvider(castingId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applications'),
      ),
      body: applicationsAsync.when(
        data: (items) {
          return auditionsAsync.when(
            data: (auditions) {
              if (items.isEmpty) {
                return const Center(child: Text('No applications yet.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final application = items[index];
                  final latestAudition = _latestAuditionForTalent(
                    auditions,
                    application.talentSummary?.id,
                  );
                  return _ApplicationCard(
                    application: application,
                    audition: latestAudition,
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: items.length,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Text('Unable to load auditions: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Unable to load applications: $error'),
        ),
      ),
    );
  }
}

AuditionRequest? _latestAuditionForTalent(
  List<AuditionRequest> auditions,
  String? talentId,
) {
  if (talentId == null) return null;
  final filtered = auditions
      .where((audition) => audition.talentId == talentId)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return filtered.isNotEmpty ? filtered.first : null;
}

class _ApplicationCard extends ConsumerWidget {
  const _ApplicationCard({
    required this.application,
    this.audition,
  });

  final CastingApplication application;
  final AuditionRequest? audition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = const [
      'submitted',
      'shortlisted',
      'declined',
      'hired',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.charcoal.withValues(alpha: 0.2),
                  child: Text(
                    application.talentSummary?.fullName
                            .substring(0, 1)
                            .toUpperCase() ??
                        '?',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.talentSummary?.fullName ?? 'Unknown talent',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        application.talentSummary?.profession ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                DropdownButton<String>(
                  value: application.status,
                  onChanged: (value) async {
                    if (value == null) return;
                    final repo = ref.read(castingRepositoryProvider);
                    await repo.updateApplicationStatus(
                      applicationId: application.id,
                      status: value,
                    );
                    ref.invalidate(
                      castingApplicationsProvider(application.castingId),
                    );
                  },
                  items: statuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(application.coverLetter ?? ''),
            if (audition != null) ...[
              const SizedBox(height: 8),
              Chip(
                backgroundColor: Colors.blueGrey.withValues(alpha: 0.2),
                label: Text('Audition: ${audition!.status.label}'),
              ),
              if (audition!.dueDate != null)
                Text(
                  'Due ${_formatDate(audition!.dueDate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
            if (application.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Media links',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              ...application.mediaUrls.map(
                (url) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: SelectableText(
                    url,
                    style: const TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AuditionRequestSheet(
                    castingId: application.castingId,
                    talentId: application.talentSummary!.id,
                    applicationId: application.id,
                  ),
                );
                if (result == true) {
                  ref.invalidate(castingAuditionsProvider(application.castingId));
                }
              },
              icon: const Icon(Icons.video_call),
              label: Text(
                audition == null ? 'Request audition' : 'Update audition',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime dateTime) {
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}

