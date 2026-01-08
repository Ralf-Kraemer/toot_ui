import 'package:flutter/material.dart';
import '../helper.dart';
import 'package:image_picker/image_picker.dart';

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

  ImagePicker _picker = ImagePicker();
  List<XFile> _selectedMedia = [];

  @override
  void dispose() {
    _statusController.dispose();
    _spoilerController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    if (_selectedMedia.isNotEmpty) {
        setState(() {
          _selectedMedia = [];
        });
    } else {
        _selectedMedia = await _picker.pickMultipleMedia();
        setState(() { });
    }
  }

  Future<void> _submitStatus() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPosting = true);
    List<int> mediaIds = [];
    try {
      mediaIds = await Helper.get().uploadMediaFiles(_selectedMedia);
    } catch (e) {

    }

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

      // Optionally show a confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status posted successfully!')),
        );
        // Clear the form
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
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.inReplyToId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Replying to status ${widget.inReplyToId}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              TextFormField(
                controller: _statusController,
                maxLines: 9,
                decoration: const InputDecoration(
                  labelText: 'What’s happening?',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty || v.trim().length > 500 ? 'Must be 1-500 characters' : null,
              ),
              
              const SizedBox(height: 4),
              TextField(
                controller: _spoilerController,
                decoration: const InputDecoration(
                  labelText: 'Content warning (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              Row(
                children: [
                  Column(
                    children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _sensitive,
                              onChanged: (v) {
                                if (v != null) setState(() => _sensitive = v);
                              },
                            ),
                            const Text('Sensitive / NSFW'),
                          ],
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _private,
                              onChanged: (v) {
                                if (v != null) setState(() => _private = v);
                              },
                            ),
                            const Text('Private'),
                          ],
                        )
                    ]
                  ),
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _isPosting ? null : _pickMedia,
                        child: Row(children: [
                          _selectedMedia.isEmpty ? const Icon(Icons.image) : Icon(Icons.remove),
                          const SizedBox(width: 4),
                          _selectedMedia.isEmpty ? const Text('Attach Media') : const Text('Clear'),
                        ],),
                      ),
                      ElevatedButton(
                        onPressed: _isPosting ? null : _submitStatus,
                        child: _isPosting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(widget.inReplyToId != null ? 'Reply' : 'Post'),
                      ),
                    ]
                  )
                ]
              ),
            ],
          ),
        ),
      ),
    );
  }
}
