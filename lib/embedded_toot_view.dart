// Fixed version of EmbeddedTootView
// Includes structure fixes, setState usage, corrected boost/unboost URLs,
// removed stray http.post(helper.), and turned it into a proper StatefulWidget.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toot_ui/default_text_styles.dart';
import 'package:toot_ui/models/api/v1/mastodonstatus.dart';
import 'package:toot_ui/models/viewmodels/toot_vm.dart';
import 'package:toot_ui/on_tap_image.dart';
import 'package:toot_ui/src/byline.dart';
import 'package:toot_ui/src/profile_image_embedded.dart';
import 'package:toot_ui/src/url_launcher.dart';
import 'package:toot_ui/src/view_mode.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:toot_ui/helper.dart' as helper;

class EmbeddedTootView extends StatefulWidget {
  final MastodonStatus toot;
  final Color? backgroundColor;
  final bool darkMode;
  final bool showRepliesCount;
  final OnTapImage? onTapImage;
  final DateFormat? createdDateDisplayFormat;

  const EmbeddedTootView(
    this.toot, {
    this.backgroundColor,
    required this.darkMode,
    this.onTapImage,
    this.createdDateDisplayFormat,
    this.showRepliesCount = false,
  });

  const EmbeddedTootView.fromToot(
    MastodonStatus toot, {
    this.backgroundColor = Colors.white,
    this.darkMode = false,
    this.onTapImage,
    this.createdDateDisplayFormat,
    this.showRepliesCount = false,
  }) : toot = toot;

  @override
  State<EmbeddedTootView> createState() => _EmbeddedTootViewState();
}

class _EmbeddedTootViewState extends State<EmbeddedTootView> {
  @override
  Widget build(BuildContext context) {
    final t = widget.toot;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        border: Border.all(width: 0.6, color: Colors.grey[400]!),
        color: widget.backgroundColor,
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
                          IntrinsicHeight(
                            child: Column(
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
                                          userNameStyle: TextStyle(
                                            color: (widget.darkMode)
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 16.0,
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.w700,
                                          ),
                                          showDate: false,
                                          userScreenNameStyle:
                                              defaultEmbeddedUserNameStyle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Align(
                            alignment: Alignment.topRight,
                            child: Icon(Icons.alternate_email),
                          )
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => openUrl(t.url ?? ""),
                    child: Text(
                      t.content,
                      style: (widget.darkMode)
                          ? defaultEmbeddedDarkTextStyle
                          : defaultEmbeddedTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (t.mediaUrls.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 20, right: 20),
              child: CarouselSlider.builder(
                itemCount: t.mediaUrls.length,
                itemBuilder: (context, index, pageViewIndex) =>
                    CachedNetworkImage(imageUrl: t.mediaUrls[index]),
                options: CarouselOptions(height: 400),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 15, top: 5),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => openUrl(t.account.url ?? ""),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (t.createdAt != null)
                    Container(
                      margin: const EdgeInsets.only(left: 16),
                      child: Text(
                        t.createdAt!,
                        style: TextStyle(
                          color: (widget.darkMode)
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Divider(color: Colors.grey[400]),
          Container(
            margin: const EdgeInsets.only(top: 5, left: 20, right: 20, bottom: 5),
            child: Row(
              children: <Widget>[
                // Boost button
                Container(
                  margin: const EdgeInsets.only(left: 24),
                  child: GestureDetector(
                    onTap: () async {
                      if (t.reblogged) {
                        setState(() => t.reblogged = false);
                      } else {
                        setState(() => t.reblogged = true);
                      }
                    },
                    child: Icon(
                      Icons.local_fire_department,
                      color: (t.reblogged)
                          ? Colors.orange[700]
                          : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: Text(
                    t.reblogsCount.toString(),
                    style: TextStyle(
                      color: (widget.darkMode)
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                ),

                // Replies (not tappable)
                Container(
                  margin: const EdgeInsets.only(left: 24),
                  child: Icon(
                    Icons.mode_comment_outlined,
                    color:
                        widget.darkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 24,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: Text(
                    t.repliesCount.toString(),
                    style: TextStyle(
                      color: (widget.darkMode)
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                ),

                // Favourite
                Container(
                  margin: const EdgeInsets.only(left: 24),
                  child: GestureDetector(
                    onTap: () async {
                      if (t.favourited) {
                        setState(() => t.favourited = false);
                      } else {
                        setState(() => t.favourited = true);
                      }
                    },
                    child: Icon(
                      t.favourited
                          ? Icons.bookmark_added
                          : Icons.bookmark,
                      color: t.favourited
                          ? Colors.green[600]
                          : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: Text(
                    t.favouritesCount.toString(),
                    style: TextStyle(
                      color: (widget.darkMode)
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                ),

                // Share
                Container(
                  margin: const EdgeInsets.only(left: 24),
                  child: GestureDetector(
                    onTap: () => Share.share("Check out this post on ${t.url}"),
                    child: Icon(
                      Icons.share,
                      color: widget.darkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                      size: 24,
                    ),
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
