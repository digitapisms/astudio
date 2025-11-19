import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_repository.dart';
import '../data/profile_repository.dart';
import '../domain/portfolio_media.dart';
import '../domain/portfolio_media_input.dart';

class PortfolioItemSheet extends ConsumerStatefulWidget {
  const PortfolioItemSheet({
    super.key,
    required this.profileId,
    this.existing,
  });

  final String profileId;
  final PortfolioMedia? existing;

  @override
  ConsumerState<PortfolioItemSheet> createState() =>
      _PortfolioItemSheetState();
}

class _PortfolioItemSheetState extends ConsumerState<PortfolioItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _urlController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;
  PortfolioMediaType _mediaType = PortfolioMediaType.link;
  bool _isPublic = true;
  bool _isSaving = false;
  bool _isUploading = false;
  String? _uploadedFileName;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _urlController = TextEditingController(text: existing?.mediaUrl ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _tagsController =
        TextEditingController(text: existing?.tags.join(', ') ?? '');
    if (existing != null) {
      _mediaType = existing.mediaType;
      _isPublic = existing.isPublic;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null ? 'Add portfolio item' : 'Edit item',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PortfolioMediaType>(
                initialValue: _mediaType,
                decoration: const InputDecoration(labelText: 'Media type'),
                items: PortfolioMediaType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _mediaType = value);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isUploading ? null : _handleUpload,
                icon: _isUploading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  _isUploading ? 'Uploading...' : 'Upload from device',
                ),
              ),
              if (_uploadedFileName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Uploaded: $_uploadedFileName',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Media URL',
                  hintText: 'https://',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
                title: const Text('Visible to producers'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.existing == null ? 'Add item' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final repo = ref.read(profileRepositoryProvider);
    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
      final input = PortfolioMediaInput(
        profileId: widget.profileId,
        title: _titleController.text.trim(),
        mediaUrl: _urlController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        mediaType: _mediaType.name,
        tags: tags,
        isPublic: _isPublic,
      );
      await repo.savePortfolioMedia(
        mediaId: widget.existing?.id,
        input: input,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save portfolio item: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleUpload() async {
    setState(() {
      _isUploading = true;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _isUploading = false);
        return;
      }
      final file = result.files.single;
      final storage = ref.read(storageRepositoryProvider);
      final url = await storage.uploadPortfolioAsset(
        profileId: widget.profileId,
        file: file,
      );
      setState(() {
        _uploadedFileName = file.name;
        _urlController.text = url;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}

