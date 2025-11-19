import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../application/audition_providers.dart';

class AuditionRequestSheet extends ConsumerStatefulWidget {
  const AuditionRequestSheet({
    super.key,
    required this.castingId,
    required this.talentId,
    this.applicationId,
  });

  final String castingId;
  final String talentId;
  final String? applicationId;

  @override
  ConsumerState<AuditionRequestSheet> createState() =>
      _AuditionRequestSheetState();
}

class _AuditionRequestSheetState
    extends ConsumerState<AuditionRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _instructionsController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  DateTime? _dueDate;
  DateTime? _scheduledAt;
  String _requestType = 'self_tape';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _instructionsController.dispose();
    _meetingLinkController.dispose();
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request audition',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _requestType,
                decoration: const InputDecoration(labelText: 'Request type'),
                items: const [
                  DropdownMenuItem(value: 'self_tape', child: Text('Self tape')),
                  DropdownMenuItem(value: 'live_online', child: Text('Live (online)')),
                  DropdownMenuItem(value: 'in_person', child: Text('In-person')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _requestType = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  hintText: 'Provide script notes, wardrobe, camera setup etc.',
                ),
                maxLines: 4,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              if (_requestType != 'self_tape')
                TextFormField(
                  controller: _meetingLinkController,
                  decoration: const InputDecoration(
                    labelText: 'Meeting link / location',
                  ),
                ),
              const SizedBox(height: 12),
              _DateField(
                label: _requestType == 'self_tape'
                    ? 'Submission due date'
                    : 'Audition date & time',
                value: _requestType == 'self_tape' ? _dueDate : _scheduledAt,
                onChanged: (date) {
                  if (_requestType == 'self_tape') {
                    setState(() => _dueDate = date);
                  } else {
                    setState(() => _scheduledAt = date);
                  }
                },
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
                      : const Text('Send request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final refContainer = ref.read(authControllerProvider);
    final requester = refContainer.profile;
    if (requester == null) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(auditionActionProvider.notifier).requestAudition(
            castingId: widget.castingId,
            talentId: widget.talentId,
            requestedBy: requester.id,
            applicationId: widget.applicationId,
            requestType: _requestType,
            instructions: _instructionsController.text.trim(),
            dueDate: _dueDate,
            scheduledAt: _scheduledAt,
            meetingLink: _meetingLinkController.text.trim().isEmpty
                ? null
                : _meetingLinkController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to request audition: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: now,
          lastDate: DateTime(now.year + 2),
        );
        if (picked == null) return;
        if (!context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value ?? now),
        );
        if (!context.mounted) return;
        if (time == null) {
          onChanged(DateTime(picked.year, picked.month, picked.day));
        } else {
          onChanged(DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          ));
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          value != null
              ? '${value!.day}/${value!.month}/${value!.year} ${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}'
              : 'Select date',
        ),
      ),
    );
  }
}

