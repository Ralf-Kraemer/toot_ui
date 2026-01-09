import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toot_ui/default_text_styles.dart';
import 'package:toot_ui/models/api/v1/mastodonstatus.dart';
import 'package:toot_ui/models/viewmodels/toot_vm.dart';
import 'package:toot_ui/on_tap_image.dart';
import 'package:toot_ui/src/byline.dart';
import 'package:toot_ui/src/profile_image.dart';
import 'package:toot_ui/src/url_launcher.dart';
import 'package:toot_ui/src/view_mode.dart';

class CompactTootView extends StatelessWidget {
  /// Business logic class created from [TootVM.fromApiModel]
  final MastodonStatus _toot;

  /// Style of the user name
  final TextStyle? userNameStyle;

  /// Style of the '@' user name and the date of the Toot
  final TextStyle? userScreenNameStyle;

  /// Style of the Toot text
  final TextStyle? textStyle;

  /// Style of the retoot information
  final TextStyle? retootInformationTextStyle;

  /// Style of the clickable elements in the Toot text (URLs, mentions, hashtags, symbols)
  final TextStyle? clickableTextStyle;

  /// Style of the user name in a embedded quote Toot
  final TextStyle? quoteUserNameStyle;

  /// Style of the '@' user name and the date of the Toot in a embedded quote Toot
  final TextStyle? quoteUserScreenNameStyle;

  /// Style of the Toot text in a embedded quote Toot
  final TextStyle? quoteTextStyle;

  /// Style of the clickable elements in the Toot text (URLs, mentions, hashtags, symbols) in a embedded quote Toot
  final TextStyle? quoteClickableTextStyle;

  /// Color of the border around embedded quote Toot
  final Color? quoteBorderColor;

  /// Color of the embedded quote Toot background
  final Color? quoteBackgroundColor;

  /// Color of the Toot background
  final Color? backgroundColor;

  /// If the Toot contains a video then an initial volume can be specified with a value between 0.0 and 1.0.
  final double? videoPlayerInitialVolume;

  /// Function used when you want a custom image tapped callback
  final OnTapImage? onTapImage;

  /// Date format when the toot was created. When null it defaults to DateFormat("HH:mm • MM.dd.yyyy", 'en_US')
  final DateFormat? createdDateDisplayFormat;

  /// If set to true betterplayer will load the highest quality available.
  /// If set to false betterplayer will load the lowest quality available.
  final bool videoHighQuality;

  /// If set to true the video in the toot, if available, will autoplay
  /// By default it is false
  final bool? autoPlayVideo;

  /// If set to false will disallow user to enter full screen in toot video
  /// By default it is true
  final bool? enableVideoFullscreen;

  /// Set video Control Bar background color
  final Color? videoControlBarBgColor;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  final Widget? videoPlaceholder;

  CompactTootView(
    this._toot, {
    this.userNameStyle,
    this.userScreenNameStyle,
    this.textStyle,
    this.clickableTextStyle,
    this.retootInformationTextStyle,
    this.quoteUserNameStyle,
    this.quoteUserScreenNameStyle,
    this.quoteTextStyle,
    this.quoteClickableTextStyle,
    this.quoteBorderColor,
    this.quoteBackgroundColor,
    this.backgroundColor,
    this.videoPlayerInitialVolume,
    this.onTapImage,
    this.createdDateDisplayFormat,
    required this.videoHighQuality,
    this.autoPlayVideo,
    this.enableVideoFullscreen,
    this.videoControlBarBgColor,
    this.videoPlaceholder,
  }); //  TootView(this.tootVM);

  CompactTootView.fromTootV1(
    MastodonStatus toot, {
    this.userNameStyle = defaultCompactUserNameStyle,
    this.userScreenNameStyle = defaultCompactUserScreenNameStyle,
    this.textStyle = defaultCompactTextStyle,
    this.clickableTextStyle = defaultCompactClickableTextStyle,
    this.retootInformationTextStyle =
        defaultCompactRetweetInformationNameStyle,
    this.quoteUserNameStyle = defaultQuoteUserNameStyle,
    this.quoteUserScreenNameStyle = defaultQuoteUserScreenNameStyle,
    this.quoteTextStyle = defaultQuoteTextStyle,
    this.quoteClickableTextStyle = defaultQuoteClickableTextStyle,
    this.quoteBorderColor = Colors.grey,
    this.quoteBackgroundColor = Colors.white,
    this.backgroundColor = Colors.white,
    this.videoPlayerInitialVolume = 0.0,
    this.onTapImage,
    this.createdDateDisplayFormat,
    this.videoHighQuality = true,
    this.autoPlayVideo,
    this.enableVideoFullscreen,
    this.videoControlBarBgColor,
    this.videoPlaceholder,
  }) : _toot = toot;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          children: <Widget>[
            
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                ProfileImage(toot: _toot),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          child: Byline(
                            _toot,
                            ViewMode.compact,
                            userNameStyle: userNameStyle,
                            userScreenNameStyle: userScreenNameStyle,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            openUrl(_toot.url?? "");
                          },
                          child: Text(
                            _toot.content,
                            style: textStyle,
                            
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
