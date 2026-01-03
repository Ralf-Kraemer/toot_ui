import 'package:flutter/material.dart';
import 'package:toot_ui/src/url_launcher.dart';
import 'package:toot_ui/src/verified_user_badge.dart';
import 'package:toot_ui/src/view_mode.dart';
import 'package:toot_ui/toot_ui.dart';

/// Widget that displays user name, user screen name (the @ name), if the user is verified
class Byline extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bool createdDateAvailable =
        toot.createdAt != "";

    switch (viewMode) {
      case ViewMode.standard:
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Flexible(
                  child: Text(
                    toot.account.displayName,
                    textAlign: TextAlign.start,
                    style: userNameStyle,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 2.0, right: 20),
                  child: VerifiedUsedBadge(toot, viewMode),
                ),
              ],
            ),
            toot.account.username.isNotEmpty
                ? (showDate
                    ? Text(
                        "@" +
                            toot.account.username +
                            (createdDateAvailable
                                ? " • ${toot.createdAt}"
                                : ""),
                        textAlign: TextAlign.start,
                        style: userScreenNameStyle,
                      )
                    : Text(
                        "@" + toot.account.username,
                        textAlign: TextAlign.start,
                        style: userScreenNameStyle,
                      ))
                : const SizedBox.shrink(),
          ],
        );
      case ViewMode.compact:
      case ViewMode.quote:
        return Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  openUrl(toot.account.url?? "");
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    if (toot.account.username.isNotEmpty)
                      Text(
                        toot.account.username,
                        style: userNameStyle,
                        textAlign: TextAlign.start,
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 2.0),
                      child: VerifiedUsedBadge(
                          toot, viewMode),
                    ),
                    if (toot.account.username.isNotEmpty)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            "@" + toot.account.username,
                            style: userScreenNameStyle,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ),
                    (showDate == true)
                        ? Flexible(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                "• " +
                                    (toot.createdAt ?? ""),
                                style: userScreenNameStyle,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                textAlign: TextAlign.start,
                              ),
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
            ),
            Icon(Icons.alternate_email),
          ],
        );
      default:

        /// should never happen
        return Container();
    }
  }
}
