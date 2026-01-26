import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:toot_ui/models/viewmodels/tag_view.dart';
import 'package:toot_ui/models/viewmodels/profile_view.dart';
import 'package:toot_ui/src/url_launcher.dart';

class ParsedHtml extends StatelessWidget {
  final String html;

  const ParsedHtml({super.key, required this.html});

  List<TextSpan> _parseMastodonHtml(String html, BuildContext context) {
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
          for (final child in node.nodes) {
            walk(child);
          }
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
              url: node.attributes['href'],
            ));
          } else if (href.isNotEmpty) {
            spans.add(HyperlinkSpan(text: node.text, url: href));
          } else {
            for (final child in node.nodes) {
              walk(child);
            }
          }
        } else {
          for (final child in node.nodes) {
            walk(child);
          }
        }
      }
    }

    for (final node in fragment.nodes) {
      walk(node);
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: _parseMastodonHtml(html, context),
      ),
    );
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
                  builder: (_) => TagView(tag: tag.substring(1)),
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
