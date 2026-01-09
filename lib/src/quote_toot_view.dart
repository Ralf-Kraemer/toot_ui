import 'package:flutter/material.dart';
import 'package:toot_ui/models/viewmodels/toot_vm.dart';
import 'package:toot_ui/on_tap_image.dart';
import 'package:toot_ui/src/media_container.dart';
import 'package:toot_ui/src/toot_text.dart';
import 'package:toot_ui/src/url_launcher.dart';
import 'package:toot_ui/src/view_mode.dart';

class QuoteTootView extends StatelessWidget {
  final TootVM tootVM;
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

  QuoteTootView(
    this.tootVM, {
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
        openUrl(tootVM.tootLink);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            border: Border.all(
              color: borderColor!,
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
                    
                    TootText(
                      tootVM,
                      textStyle: textStyle,
                      clickableTextStyle: clickableTextStyle,
                      padding: const EdgeInsets.only(top: 0.0),
                    ),
                  ],
                ),
              ),
              MediaContainer(
                tootVM,
                ViewMode.quote,
                onTapImage: onTapImage,
                autoPlayVideo: autoPlayVideo,
                enableVideoFullscreen: enableVideoFullscreen,
                videoControlBarBgColor: videoControlBarBgColor,
                videoPlaceholder: videoPlaceholder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
