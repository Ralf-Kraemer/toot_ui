import 'package:flutter/material.dart';
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
  bool _isPosting = false;

  @override
  void dispose() {
    _statusController.dispose();
    _spoilerController.dispose();
    super.dispose();
  }

  Future<void> _submitStatus() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPosting = true);

    try {
      final result = await Helper.get().postStatus(
        _statusController.text.trim(),
        inReplyToId: widget.inReplyToId,
        sensitive: _sensitive,
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
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'What’s happening?',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Status cannot be empty' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _spoilerController,
                decoration: const InputDecoration(
                  labelText: 'Content warning (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _sensitive,
                    onChanged: (v) {
                      if (v != null) setState(() => _sensitive = v);
                    },
                  ),
                  const Text('Mark as sensitive'),
                  const Spacer(),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
