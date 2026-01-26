import 'package:flutter/material.dart';
import 'package:toot_ui/src/view_mode.dart';
import 'package:toot_ui/toot_ui.dart';

class VerifiedUsedBadge extends StatelessWidget {
  const VerifiedUsedBadge(
    this.toot,
    this.viewMode, {
    Key? key,
  }) : super(key: key);

  final MastodonStatus toot;
  final ViewMode viewMode;

  @override
  Widget build(BuildContext context) {
    return (toot.account.verified)
        ? Text(
            '🤖',
            style: TextStyle(
              fontSize: viewMode == ViewMode.compact ? 18 : 24,
            ),
        ) : const SizedBox.shrink();
  }
}
