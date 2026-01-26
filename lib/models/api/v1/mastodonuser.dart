import 'dart:convert';

class MastodonUser {
  String id;
  String? url;
  String displayName;
  String username;
  bool verified; // currently mapped from bot
  String? avatarUrl;

  MastodonUser({
    required this.id,
    this.url,
    required this.displayName,
    required this.username,
    required this.verified,
    this.avatarUrl,
  });

  factory MastodonUser.fromRawJson(String str) =>
      MastodonUser.fromJson(json.decode(str));

  factory MastodonUser.fromJson(Map<String, dynamic> json) => MastodonUser(
        id: json["id"],
        url: json["url"],
        displayName: json["display_name"] ?? '',
        username: json["username"] ?? '',
        verified: json["bot"] ?? false, // or map a real verified field if your instance supports it
        avatarUrl: json["avatar"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "url": url,
        "display_name": displayName,
        "username": username,
        "bot": verified,
        "avatar": avatarUrl,
      };
}
