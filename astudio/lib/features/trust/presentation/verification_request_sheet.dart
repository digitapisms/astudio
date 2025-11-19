import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/trust_repository.dart';

class VerificationRequestSheet extends ConsumerStatefulWidget {
  const VerificationRequestSheet({super.key});

  @override
  ConsumerState<VerificationRequestSheet> createState() =>
      _VerificationRequestSheetState();
}

class _VerificationRequestSheetState
    extends ConsumerState<VerificationRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _documentUrlController = TextEditingController();
  final _documentTypeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _documentUrlController.dispose();
    _documentTypeController.dispose();
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
              'Submit verification documents',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _documentTypeController,
              decoration: const InputDecoration(
                labelText: 'Document type (e.g. Passport, ID card)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _documentUrlController,
              decoration: const InputDecoration(
                labelText: 'Secure document link',
                hintText: 'https://secure-upload.example.com/my-id',
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Document link required' : null,
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
                    : const Text('Request verification'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A member of our compliance team will review your documents within 2-3 business days.',
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
      final profile = ref.read(authControllerProvider).profile;
      if (profile == null) throw Exception('Profile not available');
      await ref.read(trustRepositoryProvider).submitVerification(
            profileId: profile.id,
            documentUrl: _documentUrlController.text.trim(),
            documentType: _documentTypeController.text.trim().isEmpty
                ? null
                : _documentTypeController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to submit request: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

