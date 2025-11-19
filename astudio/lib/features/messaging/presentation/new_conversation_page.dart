import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../profile/data/profile_repository.dart';
import '../data/messaging_repository.dart';

class NewConversationPage extends ConsumerStatefulWidget {
  const NewConversationPage({super.key});

  @override
  ConsumerState<NewConversationPage> createState() =>
      _NewConversationPageState();
}

class _NewConversationPageState extends ConsumerState<NewConversationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _titleController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _emailController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New conversation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Participant email',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email required';
                  }
                  if (!value.contains('@')) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Conversation title (optional)',
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createConversation,
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Start conversation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createConversation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isCreating = true);
    try {
      final me = ref.read(authControllerProvider).profile;
      if (me == null) throw Exception('Profile not available');
      final profileRepo = ref.read(profileRepositoryProvider);
      final participant =
          await profileRepo.findProfileByEmail(_emailController.text.trim());
      if (participant == null) {
        throw Exception('No user found with that email');
      }
      final messagingRepo = ref.read(messagingRepositoryProvider);
      final conversation = await messagingRepo.createConversation(
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        createdBy: me.id,
        participantIds: {me.id, participant.id}.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(conversation.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create conversation: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}

