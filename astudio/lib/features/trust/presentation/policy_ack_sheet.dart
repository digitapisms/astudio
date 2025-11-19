import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/trust_repository.dart';

class PolicyAckSheet extends ConsumerStatefulWidget {
  const PolicyAckSheet({super.key});

  @override
  ConsumerState<PolicyAckSheet> createState() => _PolicyAckSheetState();
}

class _PolicyAckSheetState extends ConsumerState<PolicyAckSheet> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Code of Conduct',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Please confirm you have read and agree to the Actor Studio Global Community Code of Conduct.',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                '• Treat all members with respect.\n'
                '• Do not share casting materials outside of permitted channels.\n'
                '• Follow all safety guidelines for in-person meetings.\n'
                '• Report any misconduct to the trust & safety team.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _acknowledge,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('I agree'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acknowledge() async {
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(authControllerProvider).profile;
      if (profile == null) throw Exception('Profile not available');
      await ref.read(trustRepositoryProvider).acknowledgePolicy(
            profileId: profile.id,
            policyKey: 'code_of_conduct',
            policyVersion: 'v1',
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to acknowledge policy: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

