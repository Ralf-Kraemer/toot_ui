import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:toot_ui/models/api/v1/mastodonstatus.dart';

class ProfileImage extends StatelessWidget {
  const ProfileImage({
    Key? key,
    required this.toot,
  }) : super(key: key);

  final MastodonStatus toot;

  @override
  Widget build(BuildContext context) {
    final url = toot.account.avatarUrl;
    if (url == null) {
      return const SizedBox.shrink();
    }

    return CachedNetworkImage(
      height: 40,
      width: 40,
      imageUrl: url,
      placeholder: (context, url) => Container(height: 40, width: 40),
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }
}
