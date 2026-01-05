import 'package:flutter/material.dart';
import '../helper.dart';

class InlineReplyForm extends StatefulWidget {
  final String inReplyToId;
  final VoidCallback? onPosted; // Optional callback to refresh timeline

  const InlineReplyForm({
    super.key,
    required this.inReplyToId,
    this.onPosted,
  });

  @override
  State<InlineReplyForm> createState() => _InlineReplyFormState();
}

class _InlineReplyFormState extends State<InlineReplyForm> {
  final _controller = TextEditingController();
  final _spoilerController = TextEditingController();
  bool _sensitive = false;
  bool _isPosting = false;
  bool _expanded = false;

  @override
  void dispose() {
    _controller.dispose();
    _spoilerController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isPosting = true);

    try {
      await Helper.get().postStatus(
        _controller.text.trim(),
        inReplyToId: widget.inReplyToId,
        sensitive: _sensitive,
        spoilerText:
            _spoilerController.text.trim().isEmpty ? null : _spoilerController.text.trim(),
      );

      // Clear form and collapse
      _controller.clear();
      _spoilerController.clear();
      setState(() {
        _sensitive = false;
        _expanded = false;
      });

      // Optional callback to refresh timeline
      if (widget.onPosted != null) widget.onPosted!();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply posted!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting reply: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      crossFadeState:
          _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      firstChild: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              TextFormField(
                controller: _controller,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Write a reply...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _spoilerController,
                decoration: const InputDecoration(
                  hintText: 'Content warning (optional)',
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
                  const Text('Sensitive'),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isPosting ? null : _submitReply,
                    child: _isPosting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Reply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      secondChild: GestureDetector(
        onTap: () => setState(() => _expanded = true),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: const Text(
            'Reply...',
            style: TextStyle(color: Colors.blue),
          ),
        ),
      ),
    );
  }
}
