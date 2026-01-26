import 'dart:convert';
import 'package:toot_ui/models/api/v1/mastodonuser.dart';

class MastodonStatus {
  String id;
  String? uri;
  String? url;
  String createdAt;
  String content;
  MastodonUser account;
  MastodonStatus? reblog;

  int favouritesCount;
  bool favourited;
  int reblogsCount;
  bool reblogged;
  int repliesCount;
  bool bookmarked;

  List<String> mediaUrls;

  MastodonStatus({
    required this.id,
    this.uri,
    this.url,
    required this.createdAt,
    required this.content,
    required this.account,
    this.reblog,
    required this.favouritesCount,
    required this.favourited,
    required this.reblogsCount,
    required this.reblogged,
    required this.repliesCount,
    required this.bookmarked,
    required this.mediaUrls,
  });

  factory MastodonStatus.fromJson(Map<String, dynamic> json) {
    // If reblog exists, we take media/content from the reblog
    final reblogJson = json['reblog'];
    final isReblog = reblogJson != null;

    final originalContent = isReblog ? reblogJson['content'] ?? '' : json['content'] ?? '';
    final originalMediaAttachments = isReblog
        ? reblogJson['media_attachments'] ?? []
        : json['media_attachments'] ?? [];

    // Extract media URLs
    final mediaUrls = <String>[];
    for (var m in originalMediaAttachments) {
      if (m['url'] != null) mediaUrls.add(m['url']);
    }

    return MastodonStatus(
      id: json['id'],
      uri: json['uri'],
      url: json['url'],
      createdAt: json['created_at'],
      content: originalContent,
      account: MastodonUser.fromJson(json['account']),
      reblog: isReblog ? MastodonStatus.fromJson(reblogJson) : null,
      favouritesCount: json['favourites_count'] ?? 0,
      favourited: json['favourited'] ?? false,
      reblogsCount: json['reblogs_count'] ?? 0,
      reblogged: json['reblogged'] ?? false,
      repliesCount: json['replies_count'] ?? 0,
      bookmarked: json['bookmarked'] ?? false,
      mediaUrls: mediaUrls,
    );
  }

  factory MastodonStatus.fromRawJson(String str) => MastodonStatus.fromJson(json.decode(str));
}
