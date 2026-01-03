import 'dart:convert';
import 'package:toot_ui/models/api/v1/mastodonuser.dart';

/// Represents a status update (post) in Mastodon.
class MastodonStatus {
  /// The unique identifier for this status.
  String id;
  String? uri;
  String? url;

  /// The creation timestamp of the status.
  String createdAt;

  /// The content of the status (HTML formatted).
  String content;

  /// The user who posted this status.
  MastodonUser account;

  /// Nullable. If the status is a boost (reblog), this contains the original status.
  MastodonStatus? reblog;

  /// The number of favourites (likes) this status has received.
  int favouritesCount;
  bool favourited;

  /// The number of reblogs (boosts) this status has received.
  int reblogsCount;
  bool reblogged;

  /// The number of replies this status has received.
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

  factory MastodonStatus.fromRawJson(String str) => MastodonStatus.fromJson(json.decode(str));

  factory MastodonStatus.fromJson(Map<String, dynamic> json) => MastodonStatus(
        id: json["id"],
        uri: json["uri"],
        url: json["url"],
        createdAt: json["created_at"],
        content: json["content"],
        account: MastodonUser.fromJson(json["account"]),
        reblog: json["reblog"] != null ? MastodonStatus.fromJson(json["reblog"]) : null,
        favouritesCount: json["favourites_count"],
        favourited: json["favourited"],
        reblogsCount: json["reblogs_count"],
        reblogged: json["reblogged"],
        repliesCount: json["replies_count"],
        bookmarked: json["bookmarked"],
        mediaUrls: json["media_attachments"]
      );
}
