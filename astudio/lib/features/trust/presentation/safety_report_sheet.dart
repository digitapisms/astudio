import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/trust_repository.dart';

class SafetyReportSheet extends ConsumerStatefulWidget {
  const SafetyReportSheet({super.key, this.targetProfileId});

  final String? targetProfileId;

  @override
  ConsumerState<SafetyReportSheet> createState() => _SafetyReportSheetState();
}

class _SafetyReportSheetState extends ConsumerState<SafetyReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController(text: 'safety');
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _categoryController.dispose();
    _detailsController.dispose();
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
              'Report a concern',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Category required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Describe what happened',
              ),
              maxLines: 5,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Details required' : null,
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
                    : const Text('Submit report'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Our trust & safety team will review this report and may contact you for additional details.',
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final reporter = ref.read(authControllerProvider).profile;
      if (reporter == null) throw Exception('Profile not available');
      await ref.read(trustRepositoryProvider).submitSafetyReport(
            reporterId: reporter.id,
            targetProfileId: widget.targetProfileId,
            category: _categoryController.text.trim(),
            description: _detailsController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to submit report: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

