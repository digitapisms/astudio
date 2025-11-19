import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../router/app_router.dart';
import '../application/audition_providers.dart';
import '../domain/audition_request.dart';

class AuditionInboxPage extends ConsumerWidget {
  const AuditionInboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditions = ref.watch(talentAuditionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audition Requests'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(talentAuditionsProvider),
        child: auditions.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Producers will send audition instructions once you are shortlisted.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) => _AuditionCard(
                audition: items[index],
              ),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: items.length,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text('Failed to load auditions: $error')),
        ),
      ),
    );
  }
}

class _AuditionCard extends ConsumerWidget {
  const _AuditionCard({required this.audition});

  final AuditionRequest audition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(audition.status);
    return Card(
      child: ListTile(
        onTap: () => context.pushNamed(
          AppRoute.auditionDetail.name,
          pathParameters: {'auditionId': audition.id},
        ),
        title: Text(audition.castingTitle ?? 'Casting'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (audition.instructions?.isNotEmpty == true)
              Text(
                audition.instructions!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (audition.dueDate != null)
              Text(
                'Due ${_formatDate(audition.dueDate!)}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        trailing: Chip(
          label: Text(audition.status.label),
          backgroundColor: statusColor.withValues(alpha: 0.2),
          labelStyle: TextStyle(color: statusColor),
        ),
      ),
    );
  }
}

Color _statusColor(AuditionStatus status) {
  switch (status) {
    case AuditionStatus.pending:
      return Colors.orangeAccent;
    case AuditionStatus.confirmed:
      return Colors.blueAccent;
    case AuditionStatus.submitted:
      return Colors.greenAccent;
    case AuditionStatus.reviewed:
      return AppColors.sunsetGold;
    case AuditionStatus.cancelled:
      return AppColors.errorRed;
  }
}

String _formatDate(DateTime dateTime) {
  return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

