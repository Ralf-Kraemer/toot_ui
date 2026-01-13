import 'dart:convert';

/// Users in Mastodon are represented by accounts. They can post statuses, follow others, and be mentioned.
class MastodonUser {
  /// The unique identifier for this user.
  String id;
  String? url;

  /// The display name of the user. Not necessarily a person's real name.
  String displayName;

  /// The username (handle) of the user, unique within the instance.
  String username;

  /// The URL to the user's avatar image.
  String? avatarUrl;

  /// Indicates if the account is verified (Mastodon has no global verification like Twitter, but users can verify via links).
  bool verified;

  MastodonUser({
    required this.id,
    this.url,
    required this.displayName,
    required this.username,
    required this.verified,
    this.avatarUrl,
  });

  factory MastodonUser.fromRawJson(String str) => MastodonUser.fromJson(json.decode(str));

  factory MastodonUser.fromJson(Map<String, dynamic> json) => MastodonUser(
        id: json["id"],
        url: json["url"],
        displayName: json["display_name"],
        username: json["username"],
        verified: json["bot"] ?? false, // Mastodon doesn't have verified accounts like Twitter
        avatarUrl: json["avatar"],
      );

}