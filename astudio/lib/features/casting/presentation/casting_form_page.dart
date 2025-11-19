import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../data/casting_repository.dart';

class CastingFormPage extends ConsumerStatefulWidget {
  const CastingFormPage({super.key, this.castingId});

  final String? castingId;

  @override
  ConsumerState<CastingFormPage> createState() => _CastingFormPageState();
}

class _CastingFormPageState extends ConsumerState<CastingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _cityController = TextEditingController();
  final _requirementsController = TextEditingController();
  DateTime? _deadline;
  DateTime? _shootDate;
  String? _category;
  bool _isPublished = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.castingId != null) {
      _loadCasting();
    }
  }

  Future<void> _loadCasting() async {
    final repo = ref.read(castingRepositoryProvider);
    final casting =
        await repo.fetchCastingById(widget.castingId!, currentProfileId: null);
    if (!mounted) return;
    setState(() {
      _titleController.text = casting.title;
      _descriptionController.text = casting.description;
      _budgetController.text = casting.budget ?? '';
      _cityController.text = casting.city ?? '';
      _requirementsController.text = casting.requirements.join('\n');
      _deadline = casting.applicationDeadline;
      _shootDate = casting.shootDate;
      _category = casting.category;
      _isPublished = casting.isPublished;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _cityController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.castingId == null ? 'New casting call' : 'Edit casting'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'film', child: Text('Film')),
                  DropdownMenuItem(value: 'tv', child: Text('TV')),
                  DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                  DropdownMenuItem(value: 'theatre', child: Text('Theatre')),
                  DropdownMenuItem(value: 'voice', child: Text('Voice Over')),
                ],
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(labelText: 'Compensation / Budget'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City / Location'),
              ),
              const SizedBox(height: 12),
              _DatePickerField(
                label: 'Application deadline',
                value: _deadline,
                onChanged: (date) => setState(() => _deadline = date),
              ),
              const SizedBox(height: 12),
              _DatePickerField(
                label: 'Shoot date',
                value: _shootDate,
                onChanged: (date) => setState(() => _shootDate = date),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _requirementsController,
                decoration: const InputDecoration(
                  labelText: 'Requirements (one per line)',
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isPublished,
                onChanged: (value) => setState(() => _isPublished = value),
                title: const Text('Publish immediately'),
                subtitle: const Text('Visible to artists once published'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save casting'),
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
    setState(() => _isLoading = true);
    final repo = ref.read(castingRepositoryProvider);
    final profile = ref.read(authControllerProvider).profile;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile not loaded')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final draft = CastingDraft(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        createdBy: widget.castingId == null ? profile.id : null,
        category: _category,
        budget: _budgetController.text.trim().isEmpty
            ? null
            : _budgetController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        requirements: _requirementsController.text
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList(),
        applicationDeadline: _deadline,
        shootDate: _shootDate,
        isPublished: _isPublished,
      );

      await repo.createOrUpdateCasting(
        castingId: widget.castingId,
        payload: draft.toJson(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.castingId == null
                ? 'Casting created'
                : 'Casting updated successfully',
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save casting: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
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
          firstDate: now.subtract(const Duration(days: 1)),
          lastDate: DateTime(now.year + 2),
        );
        onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value != null
                  ? '${value!.day}/${value!.month}/${value!.year}'
                  : 'Select date',
            ),
            const Icon(Icons.calendar_today_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}

