import 'package:flutter/material.dart';
import 'package:toot_ui/models/viewmodels/toot_vm.dart';
import 'package:toot_ui/src/url_launcher.dart';

/// Widget that displays user name that retooted a Tweet
class RetootInformation extends StatelessWidget {
  const RetootInformation(
    this.tootVM, {
    Key? key,
    this.retootInformationStyle,
  }) : super(key: key);

  final TootVM tootVM;
  final TextStyle? retootInformationStyle;

  @override
  Widget build(BuildContext context) {
    if (tootVM.retootedToot != null) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          openUrl(tootVM.userLink);
        },
        child: Padding(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Image.asset(
                      "assets/tw__ic_retoot_light.png",
                      fit: BoxFit.fitWidth,
                      package: 'toot_ui',
                      color: retootInformationStyle!.color,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6.0),
                      child: Text(
                        "Retooted by ${tootVM.userName}",
                        overflow: TextOverflow.fade,
                        style: retootInformationStyle,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          padding: EdgeInsets.only(bottom: 4.0),
        ),
      );
    } else {
      return Container();
    }
  }
}
