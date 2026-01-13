import 'package:flutter/material.dart';

/// A visualizable ActivityPub custom profile widget.
/// Can be placed anywhere with pre-fetched custom fields.
class ProfileCustom extends StatelessWidget {
  final List<ProfileCustomNode> customFields;

  const ProfileCustom({super.key, required this.customFields});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: customFields.map((node) => node.build()).toList(),
    );
  }
}

/// Represents one node in the custom profile tree
class ProfileCustomNode {
  final String id; // Widget type: Text, Theme, SEDCARD, XMPP
  final String label;
  final List<ProfileCustomNode> children;

  ProfileCustomNode({
    required this.id,
    required this.label,
    this.children = const [],
  });

  /// Detect type from field name
  static String detectWidgetType(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('theme')) return 'Theme';
    if (lower.contains('sedcard')) return 'SEDCARD';
    if (lower.contains('xmpp')) return 'XMPP';
    return 'Text';
  }

  /// Factory to convert ActivityPub-style field map to node
  factory ProfileCustomNode.fromField(Map<String, String> field) {
    final name = field['name'] ?? '';
    final value = field['value'] ?? '';
    return ProfileCustomNode(
      id: detectWidgetType(name),
      label: value,
    );
  }

  /// Build the actual widget tree for this node
  Widget build() {
    switch (id) {
      case 'Theme':
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.purpleAccent.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Theme: $label'),
          ),
        );

      case 'SEDCARD':
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                ...children.map((c) => c.build()),
              ],
            ),
          ),
        );

      case 'XMPP':
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label),
                ElevatedButton.icon(
                  onPressed: () {
                    // Visualization only
                  },
                  icon: const Icon(Icons.message),
                  label: const Text('Message'),
                ),
              ],
            ),
          ),
        );

      case 'Text':
      default:
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(label),
          ),
        );
    }
  }
}
