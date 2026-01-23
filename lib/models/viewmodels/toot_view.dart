import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toot_ui/default_text_styles.dart';
import 'package:toot_ui/models/api/v1/mastodonstatus.dart';
import 'package:toot_ui/models/api/v1/mastodonuser.dart';
import 'package:toot_ui/models/viewmodels/tag_view.dart';
import 'package:toot_ui/models/viewmodels/profile_view.dart';
import 'package:toot_ui/on_tap_image.dart';
import 'package:toot_ui/src/byline.dart';
import 'package:toot_ui/src/profile_image_embedded.dart';
import 'package:toot_ui/src/url_launcher.dart';
import 'package:toot_ui/src/view_mode.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toot_ui/helper.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

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
          color: Colors.blueGrey,
        ),
        color: widget.backgroundColor ?? colorScheme.surface,
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProfileView(userId: t.account.id, url: t.account.url,),
                        ),
                      );
                    },
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: parseMastodonHtml(t.content, context),
                  ),
                ),
              ],
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
          Divider(color: Colors.blueGrey, thickness: 0.3,),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              children: <Widget>[
                GestureDetector(
                  onTap: () async {
                    if (t.reblogged) {
                      final r = await helper.unboostStatus(t.id, t.url!);
                      if (r.statusCode == 200) {
                        setState(() {
                          t.reblogged = false;
                          t.reblogsCount =
                              (t.reblogsCount > 0) ? t.reblogsCount - 1 : 0;
                        });
                      }
                    } else {
                      final r = await helper.boostStatus(t.id, t.url!);
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
                        ? Colors.orangeAccent[400]
                        : theme.iconTheme.color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  t.reblogsCount.toString(),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 24),
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
                GestureDetector(
                  onTap: () async {
                    if (t.favourited) {
                      final r = await helper.unfavouriteStatus(t.id, t.url!);
                      if (r.statusCode == 200) {
                        setState(() {
                          t.favourited = false;
                          t.favouritesCount =
                              (t.favouritesCount > 0)
                                  ? t.favouritesCount - 1
                                  : 0;
                        });
                      }
                    } else {
                      final r = await helper.favouriteStatus(t.id, t.url!);
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
                        ? Icons.favorite
                        : Icons.favorite_outline,
                    color: t.favourited
                        ? Colors.blueAccent[200]
                        : theme.iconTheme.color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  t.favouritesCount.toString(),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 24),
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

  List<TextSpan> parseMastodonHtml(String html, BuildContext context) {
    final fragment = html_parser.parseFragment(html);
    final spans = <TextSpan>[];

    void walk(dom.Node node) {
      if (node is dom.Text) {
        spans.add(TextSpan(text: node.text));
        return;
      }
      if (node is dom.Element) {
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
            spans.add(UserSpan(username: node.text, context: context, url: node.attributes['href']));
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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TagView(tag: tag.substring(1),),
                ),
              );
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
                  builder: (_) => ProfileView(username: username, url: url),
                ),
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
          recognizer: TapGestureRecognizer()
            ..onTap = () => openUrl(url),
        );
}
