import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:toot_ui/src/url_launcher.dart';
import 'package:toot_ui/src/verified_user_badge.dart';
import 'package:toot_ui/src/view_mode.dart';
import 'package:toot_ui/toot_ui.dart';

class Byline extends StatefulWidget {
  const Byline(
    this.toot,
    this.viewMode, {
    Key? key,
    this.showDate = false,
    this.userNameStyle,
    this.userScreenNameStyle,
  }) : super(key: key);

  final MastodonStatus toot;
  final bool showDate;
  final TextStyle? userNameStyle;
  final TextStyle? userScreenNameStyle;
  final ViewMode viewMode;

  @override
  State<Byline> createState() => _BylineState();
}

class _BylineState extends State<Byline> {
  Timer? _timer;
  String? _relativeTime;

  @override
  void initState() {
    super.initState();
    _updateRelativeTime();
    // Update relative time every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateRelativeTime();
    });
  }

  @override
  void didUpdateWidget(covariant Byline oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate if toot changes
    if (oldWidget.toot.createdAt != widget.toot.createdAt) {
      _updateRelativeTime();
    }
  }

  void _updateRelativeTime() {
    if (widget.toot.createdAt.isEmpty) return;

    try {
      final dt = DateTime.parse(widget.toot.createdAt).toLocal();
      final locale = Localizations.localeOf(context).languageCode;

      final newTime = timeago.format(dt, locale: locale, allowFromNow: true);

      if (mounted) {
        setState(() => _relativeTime = newTime);
      }
    } catch (_) {
      // fallback: ISO string
      if (mounted) setState(() => _relativeTime = widget.toot.createdAt);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showDate = widget.showDate && _relativeTime != null;

    switch (widget.viewMode) {
      case ViewMode.standard:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    widget.toot.account.displayName,
                    style: widget.userNameStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                VerifiedUsedBadge(widget.toot, widget.viewMode),
              ],
            ),
            if (widget.toot.account.username.isNotEmpty)
              Text(
                "@${widget.toot.account.username}" +
                    (showDate ? " • $_relativeTime" : ""),
                style: widget.userScreenNameStyle,
              ),
          ],
        );

      case ViewMode.compact:
      case ViewMode.quote:
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => openUrl(widget.toot.account.url ?? ""),
                child: Row(
                  children: [
                    if (widget.toot.account.username.isNotEmpty)
                      Text(
                        widget.toot.account.username,
                        style: widget.userNameStyle,
                      ),
                    const SizedBox(width: 2),
                    VerifiedUsedBadge(widget.toot, widget.viewMode),
                    if (widget.toot.account.username.isNotEmpty)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            "@${widget.toot.account.username}" +
                                (showDate ? " • $_relativeTime" : ""),
                            style: widget.userScreenNameStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.alternate_email),
          ],
        );

      default:
        return Container();
    }
  }
}
