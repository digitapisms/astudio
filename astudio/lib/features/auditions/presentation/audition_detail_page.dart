import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/audition_providers.dart';
import '../data/audition_repository.dart';
import '../domain/audition_request.dart';

class AuditionDetailPage extends ConsumerWidget {
  const AuditionDetailPage({super.key, required this.auditionId});

  final String auditionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditions = ref.watch(talentAuditionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audition Details'),
      ),
      body: auditions.when(
        data: (items) {
          final audition =
              items.firstWhere((element) => element.id == auditionId);
          return _AuditionDetailView(audition: audition);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Unable to load audition: $error')),
      ),
    );
  }
}

class _AuditionDetailView extends ConsumerStatefulWidget {
  const _AuditionDetailView({required this.audition});

  final AuditionRequest audition;

  @override
  ConsumerState<_AuditionDetailView> createState() =>
      _AuditionDetailViewState();
}

class _AuditionDetailViewState extends ConsumerState<_AuditionDetailView> {
  final _linkController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _linkController.text = widget.audition.submissionUrl ?? '';
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audition = widget.audition;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  audition.castingTitle ?? 'Casting',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('Request type: ${audition.requestType}'),
                if (audition.instructions?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(
                    audition.instructions!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                if (audition.dueDate != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Due ${_formatDate(audition.dueDate!)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (audition.meetingLink?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text('Meeting link: ${audition.meetingLink}'),
                ],
              ],
            ),
          ),
        ),
        if (audition.status == AuditionStatus.pending ||
            audition.status == AuditionStatus.confirmed ||
            audition.status == AuditionStatus.submitted)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submit self tape',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _linkController,
                    decoration: const InputDecoration(
                      labelText: 'Video link',
                      hintText: 'https://',
                    ),
                  ),
                  const SizedBox(height: 12),
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
                          : const Text('Send submission'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (audition.reviewerNotes?.isNotEmpty == true)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reviewer notes',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(audition.reviewerNotes!),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _submit() async {
    final url = _linkController.text.trim();
    if (url.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(auditionRepositoryProvider).submitSelfTape(
            auditionId: widget.audition.id,
            submissionUrl: url,
          );
      ref.invalidate(talentAuditionsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission sent')),
      );
      Navigator.of(context).pop();
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

String _formatDate(DateTime dateTime) {
  return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

