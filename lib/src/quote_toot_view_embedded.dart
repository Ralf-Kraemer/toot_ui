import 'package:flutter/material.dart';
import 'package:toot_ui/src/byline.dart';
import 'package:toot_ui/src/media_container.dart';
import 'package:toot_ui/src/url_launcher.dart';
import 'package:toot_ui/src/view_mode.dart';
import 'package:toot_ui/toot_ui.dart';

class QuoteTootViewEmbedded extends StatelessWidget {
  final MastodonStatus toot;
  final TextStyle? userNameStyle;
  final TextStyle? userScreenNameStyle;
  final TextStyle? textStyle;
  final TextStyle? clickableTextStyle;
  final Color? borderColor;
  final Color? backgroundColor;
  final OnTapImage? onTapImage;
  final bool? autoPlayVideo;
  final bool? enableVideoFullscreen;
  final Color? videoControlBarBgColor;
  final Widget? videoPlaceholder;

  QuoteTootViewEmbedded(
    this.toot, {
    this.userNameStyle,
    this.userScreenNameStyle,
    this.textStyle,
    this.clickableTextStyle,
    this.borderColor,
    this.backgroundColor,
    this.onTapImage,
    this.autoPlayVideo,
    this.enableVideoFullscreen,
    this.videoControlBarBgColor,
    this.videoPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openUrl(toot.url?? "");
      },
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            border: new Border.all(
              width: 0.8,
              color: Colors.grey[400]!,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    Byline(
                      toot,
                      ViewMode.quote,
                      userNameStyle: userNameStyle,
                      userScreenNameStyle: userScreenNameStyle,
                      showDate: false,
                    ),
                    Text(
                      toot.content,
                      style: textStyle
                    ),
                  ],
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
