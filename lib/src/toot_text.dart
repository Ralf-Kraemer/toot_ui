import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:toot_ui/models/api/v1/entieties/hashtag_entity.dart';
import 'package:toot_ui/models/api/v1/entieties/mention_entity.dart';
import 'package:toot_ui/models/api/v1/entieties/symbol_entity.dart';
import 'package:toot_ui/models/api/v1/entieties/url_entity.dart';
import 'package:toot_ui/models/viewmodels/toot_vm.dart';
import 'package:toot_ui/src/url_launcher.dart';

class TootText extends StatelessWidget {
  TootText(
    this.tootVM, {
    Key? key,
    this.textStyle,
    this.clickableTextStyle,
    this.padding,
  }) : super(key: key);

  final TootVM tootVM;
  final TextStyle? textStyle;
  final TextStyle? clickableTextStyle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    var spans = _getSpans(context);
    if (spans.isNotEmpty) {
      return Padding(
        padding: padding!,
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: RichText(
            textAlign: TextAlign.start,
            text: TextSpan(children: spans),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  List<TextSpan> _getSpans(BuildContext context) {
    List<TextSpan> spans = [];
    int? boundary = tootVM.startDisplayText;
    var unescape = new HtmlUnescape();

    if (tootVM.startDisplayText == 0 && tootVM.endDisplayText == 0) return [];

    if (tootVM.allEntities.isEmpty) {
      spans.add(TextSpan(
        text: unescape.convert(tootVM.text),
        style: textStyle,
      ));
    } else {
      tootVM.allEntities.asMap().forEach((index, entity) {
        // look for the next match
        final startIndex = entity.start;

        // respect the `display_text_range` from JSON.
        if (startIndex > tootVM.endDisplayText!) return;

        // add any plain text before the next entity
        if (startIndex > boundary!) {
          spans.add(TextSpan(
            text: unescape.convert(String.fromCharCodes(tootVM.textRunes,
                boundary!, min(startIndex, tootVM.endDisplayText!))),
            style: textStyle,
          ));
        }

        if (entity.runtimeType == UrlEntity) {
          UrlEntity urlEntity = (entity as UrlEntity);
          final spanText = unescape.convert(urlEntity.displayUrl);
          spans.add(TextSpan(
            text: spanText,
            style: clickableTextStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                openUrl(urlEntity.url);
              },
          ));
        } else {
          final spanText = unescape.convert(
            String.fromCharCodes(tootVM.textRunes, startIndex,
                min(entity.end, tootVM.endDisplayText!)),
          );
          spans.add(TextSpan(
            text: spanText,
            style: clickableTextStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                if (entity.runtimeType == MentionEntity) {
                  MentionEntity mentionEntity = (entity as MentionEntity);
                  openUrl("https://twitter.com/${mentionEntity.screenName}");
                } else if (entity.runtimeType == SymbolEntity) {
                  SymbolEntity symbolEntity = (entity as SymbolEntity);
                  openUrl("https://twitter.com/search?q=${symbolEntity.text}");
                } else if (entity.runtimeType == HashtagEntity) {
                  HashtagEntity hashtagEntity = (entity as HashtagEntity);
                  openUrl("https://twitter.com/hashtag/${hashtagEntity.text}");
                }
              },
          ));
        }

        // update the boundary to know from where to start the next iteration
        boundary = entity.end;
      });

      spans.add(TextSpan(
        text: unescape.convert(String.fromCharCodes(tootVM.textRunes,
            boundary!, min(tootVM.textRunes.length, tootVM.endDisplayText!))),
        style: textStyle,
      ));
    }

    return spans;
  }
}
