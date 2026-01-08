import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toot_ui/default_text_styles.dart';
import 'package:toot_ui/models/api/v1/mastodonstatus.dart';
import 'package:toot_ui/on_tap_image.dart';
import 'package:toot_ui/src/byline.dart';
import 'package:toot_ui/src/profile_image_embedded.dart';
import 'package:toot_ui/src/url_launcher.dart';
import 'package:toot_ui/src/view_mode.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toot_ui/helper.dart';


class TootView extends StatefulWidget {
  final MastodonStatus toot;
  final Color? backgroundColor;
  final bool darkMode;
  final bool showRepliesCount;
  final OnTapImage? onTapImage;
  final DateFormat? createdDateDisplayFormat;

  const TootView(
    this.toot, {
    this.backgroundColor,
    required this.darkMode,
    this.onTapImage,
    this.createdDateDisplayFormat,
    this.showRepliesCount = false,
  });

  const TootView.fromToot(
    MastodonStatus toot, {
    this.backgroundColor = Colors.white,
    this.darkMode = false,
    this.onTapImage,
    this.createdDateDisplayFormat,
    this.showRepliesCount = false,
  }) : toot = toot;

  @override
  State<TootView> createState() => _TootViewState();
}

class _TootViewState extends State<TootView> {
  final Helper helper = Helper.get();

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  @override
  Widget build(BuildContext context) {
    final t = widget.toot;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        border: Border.all(
          width: 0.6,
          color: theme.dividerColor,
        ),
        color: widget.backgroundColor ?? colorScheme.surface,
      ),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => openUrl(t.url ?? ""),
            child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => openUrl(t.account.url ?? ""),
                      child: Stack(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              ProfileImage(toot: t),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Byline(
                                    t,
                                    ViewMode.standard,
                                    userNameStyle: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                    showDate: false,
                                    userScreenNameStyle:
                                        defaultEmbeddedUserNameStyle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Icon(
                              Icons.alternate_email,
                              color: theme.iconTheme.color,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.content,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          if (t.mediaUrls.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: CarouselSlider.builder(
                itemCount: t.mediaUrls.length,
                itemBuilder: (_, i, __) => CachedNetworkImage(
                  imageUrl: t.mediaUrls[i],
                  fit: BoxFit.cover,
                ),
                options: CarouselOptions(height: 400),
              ),
            ),

          Divider(color: theme.dividerColor),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              children: <Widget>[
                // Boost
                GestureDetector(
                  onTap: () async {

                    if (t.reblogged) {
                      final r = await helper.unboostStatus(t.id);
                      if (r.statusCode == 200) {
                        setState(() {
                          t.reblogged = false;
                          t.reblogsCount =
                              (t.reblogsCount > 0) ? t.reblogsCount - 1 : 0;
                        });
                      }
                    } else {
                      final r = await helper.unboostStatus(t.id);
                      if (r.statusCode == 200) {
                        setState(() {
                          t.reblogged = true;
                          t.reblogsCount += 1;
                        });
                      }
                    }
                  },
                  child: Icon(
                    Icons.local_fire_department,
                    color: t.reblogged
                        ? Colors.orange[700]
                        : theme.iconTheme.color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  t.reblogsCount.toString(),
                  style: theme.textTheme.bodySmall,
                ),

                const SizedBox(width: 24),

                // Replies
                Icon(
                  Icons.mode_comment_outlined,
                  color: theme.iconTheme.color,
                ),
                const SizedBox(width: 6),
                Text(
                  t.repliesCount.toString(),
                  style: theme.textTheme.bodySmall,
                ),

                const SizedBox(width: 24),

                // Favourite
                GestureDetector(
                  onTap: () async {
                    final token = await helper.getAccessToken();
                    if (token == null) return;

                    if (t.favourited) {
                      final r = await helper.unfavouriteStatus(t.id);
                      if (r.statusCode == 200) {
                        setState(() {
                          t.favourited = false;
                          t.favouritesCount = (t.favouritesCount > 0)
                              ? t.favouritesCount - 1
                              : 0;
                        });
                      }
                    } else {
                      final r = await helper.favouriteStatus(t.id);
                      if (r.statusCode == 200) {
                        setState(() {
                          t.favourited = true;
                          t.favouritesCount += 1;
                        });
                      }
                    }
                  },
                  child: Icon(
                    t.favourited
                        ? Icons.bookmark_added
                        : Icons.bookmark,
                    color: t.favourited
                        ? Colors.green[600]
                        : theme.iconTheme.color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  t.favouritesCount.toString(),
                  style: theme.textTheme.bodySmall,
                ),

                const SizedBox(width: 24),

                // Share
                GestureDetector(
                  onTap: () =>
                      Share.share('Check out this post: ${t.url}'),
                  child: Icon(
                    Icons.share,
                    color: theme.iconTheme.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
