import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toot_ui/default_text_styles.dart';
import 'package:toot_ui/models/api/v1/mastodonstatus.dart';
import 'package:toot_ui/models/viewmodels/tag_view.dart';
import 'package:toot_ui/models/viewmodels/profile_view.dart';
import 'package:toot_ui/on_tap_image.dart';
import 'package:toot_ui/src/byline.dart';
import 'package:toot_ui/src/parsed_html.dart';
import 'package:toot_ui/src/profile_image_embedded.dart';
import 'package:toot_ui/src/url_launcher.dart';
import 'package:toot_ui/src/view_mode.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toot_ui/helper.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:better_player/better_player.dart';

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
  int _currentSlideIndex = 0;

  @override
  Widget build(BuildContext context) {
    final t = widget.toot;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If this is a boost, original = t.reblog; otherwise original = t
    final bool isReblog = t.reblog != null;
    final MastodonStatus original = isReblog ? t.reblog! : t;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        border: Border.all(width: 0.6, color: Colors.blueGrey),
        color: widget.backgroundColor ?? colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtle booster note
          if (isReblog)
            Padding(
              padding: const EdgeInsets.only(left: 15, top: 8, bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.repeat, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${t.account.displayName} boosted', // t.account = booster
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

          // Original author info & content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProfileView(
                          userId: original.account.id,
                          url: original.account.url,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      ProfileImage(toot: original),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Byline(
                          original,
                          ViewMode.standard,
                          userNameStyle: theme.textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                          showDate: true,
                          userScreenNameStyle: defaultEmbeddedUserNameStyle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ParsedHtml(html: original.content),
              ],
            ),
          ),

          if (original.mediaUrls.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: Builder(
              builder: (_) {
                final firstUrl = original.mediaUrls[0].toLowerCase();
                final isVideo = firstUrl.endsWith('.mp4') || firstUrl.endsWith('.hls') || firstUrl.endsWith('.m3u8');

                // --- Case 1: First media is a video ---
                if (isVideo) {
                  return AspectRatio(
                    aspectRatio: 5 / 6,
                    child: BetterPlayer.network(
                      firstUrl,
                      betterPlayerConfiguration: const BetterPlayerConfiguration(
                        autoPlay: false,
                        looping: false,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }

                // --- Case 2: Exactly one image ---
                if (original.mediaUrls.length == 1) {
                  return CachedNetworkImage(
                    width: double.infinity,
                    imageUrl: original.mediaUrls[0],
                    fit: BoxFit.cover,
                  );
                }

                // --- Case 3: Multiple images (current implementation) ---
                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    CarouselSlider.builder(
                      itemCount: original.mediaUrls.length,
                      itemBuilder: (_, i, __) => CachedNetworkImage(
                        width: double.infinity,
                        imageUrl: original.mediaUrls[i],
                        fit: BoxFit.cover,
                      ),
                      options: CarouselOptions(
                        height: 360,
                        aspectRatio: 5 / 6,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentSlideIndex = index;
                          });
                        },
                      ),
                    ),
                    if (original.mediaUrls.length > 1)
                      Positioned(
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentSlideIndex + 1}/${original.mediaUrls.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),


          const Divider(color: Colors.blueGrey, thickness: 0.3),

          // Interaction bar (boost, favorite, reply, share) still bound to top-level toot
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    if (t.reblogged) {
                      try {
                        await helper.unboostStatus(t.id);
                        setState(() {
                          t.reblogged = false;
                          t.reblogsCount =
                              (t.reblogsCount > 0) ? t.reblogsCount - 1 : 0;
                        });
                      } catch (e) {
                        print('Boost failed: $e');
                      }
                    } else {
                      try {
                        await helper.boostStatus(t.id);
                        setState(() {
                          t.reblogged = true;
                          t.reblogsCount += 1;
                        });
                      } catch (e) {
                        print('Boost failed: $e');
                      }
                    }
                  },
                  child: Icon(
                    Icons.local_fire_department,
                    size: 24,
                    color: t.reblogged
                        ? Colors.orangeAccent[400]
                        : theme.iconTheme.color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(t.reblogsCount.toString(),
                    style: theme.textTheme.bodySmall),
                const SizedBox(width: 24),
                Icon(Icons.mode_comment_outlined,
                    size: 24,
                    color: theme.iconTheme.color),
                const SizedBox(width: 6),
                Text(t.repliesCount.toString(),
                    style: theme.textTheme.bodySmall),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () async {
                    if (t.favourited) {
                      try {
                        await helper.unfavouriteStatus(t.id);
                        setState(() {
                          t.favourited = false;
                          t.favouritesCount =
                              (t.favouritesCount > 0)
                                  ? t.favouritesCount - 1
                                  : 0;
                        });
                      } catch (e) {
                        print('Favourite failed: $e');
                      }
                    } else {
                      try {
                        await helper.favouriteStatus(t.id);
                        setState(() {
                          t.favourited = true;
                          t.favouritesCount += 1;
                        });
                      } catch (e) {
                        print('Favourite failed: $e');
                      }
                    }
                  },
                  child: Icon(
                    size: 24,
                    t.favourited
                        ? Icons.workspace_premium_sharp
                        : Icons.workspace_premium_outlined,
                    color: t.favourited
                        ? Colors.blueAccent[200]
                        : theme.iconTheme.color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(t.favouritesCount.toString(),
                    style: theme.textTheme.bodySmall),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () => Share.share('Check out this post: ${t.url}'),
                  child: Icon(Icons.share, color: theme.iconTheme.color, size: 24),
                ),
                const SizedBox(width: 32),
                GestureDetector(
                  onTap: () {},
                  child: Icon(Icons.more_vert, color: theme.iconTheme.color, size: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Parsing helpers

List<TextSpan> parseMastodonHtml(String html, BuildContext context) {
  final fragment = html_parser.parseFragment(html);
  final spans = <TextSpan>[];

  void walk(dom.Node node) {
    if (node is dom.Text) {
      spans.add(TextSpan(text: node.text));
    } else if (node is dom.Element) {
      if (node.localName == 'br') {
        spans.add(const TextSpan(text: '\n'));
      } else if (node.localName == 'p') {
        node.nodes.forEach(walk);
        spans.add(const TextSpan(text: '\n\n'));
      } else if (node.localName == 'a') {
        final href = node.attributes['href'] ?? '';
        final classes = node.classes;
        if (classes.contains('hashtag')) {
          spans.add(HashtagSpan(tag: node.text, context: context));
        } else if (classes.contains('mention')) {
          spans.add(UserSpan(
              username: node.text,
              context: context,
              url: node.attributes['href']));
        } else if (href.isNotEmpty) {
          spans.add(HyperlinkSpan(text: node.text, url: href));
        } else {
          node.nodes.forEach(walk);
        }
      } else {
        node.nodes.forEach(walk);
      }
    }
  }

  fragment.nodes.forEach(walk);
  return spans;
}

class HashtagSpan extends TextSpan {
  HashtagSpan({
    required String tag,
    required BuildContext context,
  }) : super(
          text: tag,
          style: const TextStyle(color: Colors.blue),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => TagView(
                        tag: tag.startsWith('#') ? tag.substring(1) : tag,
                      )));
            },
        );
}

class UserSpan extends TextSpan {
  UserSpan({
    String? url,
    required String username,
    String? userId,
    required BuildContext context,
  }) : super(
          text: username,
          style: const TextStyle(color: Colors.blue),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => ProfileView(username: username, url: url)),
              );
            },
        );
}

class HyperlinkSpan extends TextSpan {
  HyperlinkSpan({
    required String text,
    required String url,
  }) : super(
          text: text,
          style: const TextStyle(color: Colors.blue),
          recognizer: TapGestureRecognizer()..onTap = () => openUrl(url),
        );
}
