import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../helper.dart';

class StatusForm extends StatefulWidget {
  /// Optional: if replying to a status
  final String? inReplyToId;

  const StatusForm({super.key, this.inReplyToId});

  @override
  State<StatusForm> createState() => _StatusFormState();
}

class _StatusFormState extends State<StatusForm> {
  final _formKey = GlobalKey<FormState>();
  final _statusController = TextEditingController();
  final _spoilerController = TextEditingController();
  bool _sensitive = false;
  bool _private = false;
  bool _isPosting = false;

  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedMedia = [];

  @override
  void dispose() {
    _statusController.dispose();
    _spoilerController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    if (_selectedMedia.isNotEmpty) {
      setState(() => _selectedMedia = []);
    } else {
      _selectedMedia = await _picker.pickMultipleMedia();
      setState(() {});
    }
  }

  Future<void> _submitStatus() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPosting = true);
    List<int> mediaIds = [];
    try {
      mediaIds = await Helper.get().uploadMediaFiles(_selectedMedia);
    } catch (e) {}

    try {
      final result = await Helper.get().postStatus(
        _statusController.text.trim(),
        inReplyToId: widget.inReplyToId,
        sensitive: _sensitive,
        private: _private,
        mediaIDs: mediaIds,
        spoilerText: _spoilerController.text.trim().isEmpty
            ? null
            : _spoilerController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status posted successfully!')),
        );

        if (result != null) {
          _statusController.clear();
          _spoilerController.clear();
        }

        setState(() => _sensitive = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Reply notice
              if (widget.inReplyToId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Replying to status ${widget.inReplyToId}',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),

              // Status input
              TextFormField(
                controller: _statusController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'What’s happening?',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty || v.trim().length > 500
                        ? 'Must be 1-500 characters'
                        : null,
              ),

              const SizedBox(height: 10),

              // Spoiler input
              TextField(
                controller: _spoilerController,
                decoration: const InputDecoration(
                  labelText: 'Content warning (optional)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // Sensitive / Private
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [/*
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _sensitive,
                        onChanged: (v) {
                          if (v != null) setState(() => _sensitive = v);
                        },
                      ),
                      const Text('Sensitive / NSFW'),
                    ],
                  ),*/
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _private,
                        onChanged: (v) {
                          if (v != null) setState(() => _private = v);
                        },
                      ),
                      const Text('Private'),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Media preview
              if (_selectedMedia.isNotEmpty)
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedMedia.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedMedia[index].path),
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isPosting ? null : _pickMedia,
                      icon: _selectedMedia.isEmpty
                          ? const Icon(Icons.browse_gallery)
                          : const Icon(Icons.clear),
                      label: _selectedMedia.isEmpty
                          ? const Text('Attach')
                          : const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isPosting ? null : _submitStatus,
                      child: _isPosting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(widget.inReplyToId != null ? 'Reply' : 'Post'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
