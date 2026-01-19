import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toot_ui/models/api/v1/mastodonuser.dart';

class Helper {
  static final Helper _instance = Helper._internal();
  Helper._internal();
  factory Helper.get() => _instance;

  // ===== Access token =====
  Future<String?> getAccessToken() => getPrefString('accessToken');
  Future<bool> setAccessToken(String value) =>
      setPrefString('accessToken', value);

  // ===== Instance =====
  Future<bool> setHomeInstanceName(String value) =>
      setPrefString('homeInstanceName', value);

  Future<String?> getHomeInstanceName() => getPrefString('homeInstanceName');

  // ===== Internal URL builder =====
  Future<Uri> _buildUrl(String instance, String path, [Map<String, String>? query]) async {
    Uri _preUrl = Uri.parse(instance);
    final host = '${_preUrl.scheme}://${_preUrl.host}'.replaceAll(RegExp(r'^https?://'), '');
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.https(host, cleanPath, query);
  }

  // ===== Internal HTTP helper =====
  Future<dynamic> _requestJson(
    String method,
    Uri url, [
    Map<String, dynamic>? body,
  ]) async {
    final token = await getAccessToken();
    if (token == null) throw StateError('Access token is not set');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    late http.Response response;

    switch (method) {
      case 'POST':
        response = await http.post(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'GET':
        response = await http.get(url, headers: headers);
        break;
      case 'DELETE':
        response = await http.delete(url, headers: headers);
        break;
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    }

    throw http.ClientException(
      'Request failed: ${response.statusCode} ${response.reasonPhrase}',
      response.request?.url,
    );
  }

  Future<dynamic> _postJson(Uri url, [Map<String, dynamic>? body]) =>
      _requestJson('POST', url, body);
  Future<dynamic> _getJson(Uri url) => _requestJson('GET', url);
  Future<dynamic> _deleteJson(Uri url) => _requestJson('DELETE', url);

  // ===== Media upload =====
  Future<List<int>> uploadMediaFiles(List<XFile> files) async {
    if (files.isEmpty) return [];

    final token = await getAccessToken();
    if (token == null) throw StateError('Access token is not set');

    final instance = await getHomeInstanceName();
    if (instance == null || instance.isEmpty) {
      throw StateError('Home instance name is not set');
    }

    final host = instance.replaceAll(RegExp(r'^https?://'), '');
    final uri = Uri.https(host, 'api/v2/media');
    final mediaIds = <int>[];

    for (final file in files) {
      final f = File(file.path);
      if (!await f.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }

      final mimeType = _detectMimeType(file.path.split('.').last.toLowerCase());

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType(mimeType.split('/')[0], mimeType.split('/')[1]),
        ));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body);
        final id = json['id'];
        if (id is int) {
          mediaIds.add(id);
        } else {
          throw FormatException('Media upload response missing id');
        }
      } else {
        throw http.ClientException(
          'Media upload failed: ${response.statusCode}',
          uri,
        );
      }
    }

    return mediaIds;
  }

  String _detectMimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }

  // ===== Status actions =====
  Future<dynamic> postStatus(
    String status, {
    String? inReplyToId,
    bool? sensitive,
    bool? private,
    String? spoilerText,
    List<int>? mediaIDs,
    List<XFile>? mediaFiles, // new optional parameter
  }) async {
    // If media files are provided, upload them first
    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      mediaIDs = await uploadMediaFiles(mediaFiles);
    }

    final _i = await getHomeInstanceName();
    final url = await _buildUrl(_i!, '/api/v1/statuses');
    final body = <String, dynamic>{'status': status};

    if (inReplyToId != null) body['in_reply_to_id'] = inReplyToId;
    if (sensitive != null) body['sensitive'] = sensitive;
    if (private != null) body['visibility'] = private ? 'private' : 'public';
    if (spoilerText != null) body['spoiler_text'] = spoilerText;
    if (mediaIDs != null && mediaIDs.isNotEmpty) body['media_ids'] = mediaIDs;

    return _postJson(url, body);
  }


  Future<dynamic> boostStatus(String statusId, String? url) async =>
      _postJson(await _buildUrl(url!, '/api/v1/statuses/$statusId/reblog'));
  Future<dynamic> unboostStatus(String statusId, String? url) async =>
      _postJson(await _buildUrl(url!, '/api/v1/statuses/$statusId/unreblog'));
  Future<dynamic> favouriteStatus(String statusId, String? url) async =>
      _postJson(await _buildUrl(url!, '/api/v1/statuses/$statusId/favourite'));
  Future<dynamic> unfavouriteStatus(String statusId, String? url) async =>
      _postJson(await _buildUrl(url!, '/api/v1/statuses/$statusId/unfavourite'));
  Future<dynamic> deleteStatus(String statusId, String? url) async =>
      _deleteJson(await _buildUrl(url!, '/api/v1/statuses/$statusId'));

  // ===== Timeline helpers =====
  Future<List<dynamic>> _fetchTimeline(String path, {int? limit, String? url, String? maxId, String? sinceId}) async {
    final query = <String, String>{};
    String? _i;
    if (limit != null) query['limit'] = '$limit';
    if (maxId != null) query['max_id'] = maxId;
    if (sinceId != null) query['since_id'] = sinceId;
    if (url == null) {
      _i = await getHomeInstanceName();
    } else {
      _i = url;
    }
    final json = await _getJson(await _buildUrl(_i!, path, query.isEmpty ? null : query));
    return json is List ? json : [];
  }

  Future<List<dynamic>> getHomeTimeline({int? limit, String? maxId, String? sinceId}) =>
      _fetchTimeline('/api/v1/timelines/home', limit: limit, maxId: maxId, sinceId: sinceId);

  Future<List<dynamic>> getLocalTimeline({int? limit, String? maxId, String? sinceId}) =>
      _fetchTimeline('/api/v1/timelines/public', limit: limit, maxId: maxId, sinceId: sinceId);

  Future<List<dynamic>> getFederatedTimeline({int? limit, String? maxId, String? sinceId}) =>
      _fetchTimeline('/api/v1/timelines/public', limit: limit, maxId: maxId, sinceId: sinceId);

  Future<List<dynamic>> getUserTimeline(String accountId, String url, {int? limit, String? maxId, String? sinceId}) =>
      _fetchTimeline('/api/v1/accounts/$accountId/statuses', limit: limit, url: url, maxId: maxId, sinceId: sinceId);

  Future<List<dynamic>> getHashtagTimeline(String hashtag, {int? limit, String? maxId, String? sinceId}) =>
      _fetchTimeline('/api/v1/timelines/tag/$hashtag', limit: limit, maxId: maxId, sinceId: sinceId);

  // ===== Notifications =====
  Future<List<dynamic>> _fetchNotifications({int? limit, String? maxId, String? sinceId}) async {
    final query = <String, String>{};
    if (limit != null) query['limit'] = '$limit';
    if (maxId != null) query['max_id'] = maxId;
    if (sinceId != null) query['since_id'] = sinceId;
    final _i = await getHomeInstanceName();
    final json = await _getJson(await _buildUrl(_i!, '/api/v1/notifications', query.isEmpty ? null : query));
    return json is List ? json : [];
  }

  Future<List<dynamic>> getNotifications({int? limit, String? maxId, String? sinceId}) =>
      _fetchNotifications(limit: limit, maxId: maxId, sinceId: sinceId);

  // ===== Profile reading/writing =====

  /// Get any user's profile by ID
  Future<Map<String, dynamic>> getProfile(String url, String userId) async {
    final json = await _getJson(await _buildUrl(url, '/api/v1/accounts/$userId'));
    if (json is Map<String, dynamic>) {
      return {
        'id': json['id'],
        'username': json['username'],
        'acct': json['acct'],
        'display_name': json['display_name'],
        'note': json['note'],
        'avatar': json['avatar'],
        'header': json['header'],
        'custom_fields': json['fields'] ?? [],
      };
    }
    throw FormatException('Invalid profile response for user $userId');
  }

  /// Update logged-in user's profile (supports display_name, note, avatar, header, fields)
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> fields) async {
    final _instance = await getHomeInstanceName();
    final url = await _buildUrl(_instance!, '/api/v1/accounts/update_credentials');

    final allowedKeys = ['display_name', 'note', 'avatar', 'header', 'fields'];
    final body = <String, dynamic>{};
    for (final key in allowedKeys) {
      if (fields.containsKey(key)) body[key] = fields[key];
    }

    final json = await _postJson(url, body);
    if (json is Map<String, dynamic>) return json;
    throw FormatException('Invalid response from profile update');
  }

  /// Update only custom fields safely
  Future<Map<String, dynamic>> updateCustomFields(List<Map<String, String>> fields) async {
    // Each field should be {'name': 'label', 'value': 'text/value'}
    return updateProfile({'fields': fields});
  }

  /// Get current user's custom fields
  Future<List<Map<String, String>>> getOwnCustomFields() async {
    final _i = await getHomeInstanceName();
    final me = await _getJson(await _buildUrl(_i!, '/api/v1/accounts/verify_credentials'));
    if (me is Map<String, dynamic>) {
      final fields = me['fields'] as List<dynamic>? ?? [];
      return fields
          .whereType<Map<String, dynamic>>()
          .map((f) => {
                'name': f['name']?.toString() ?? '',
                'value': f['value']?.toString() ?? '',
              })
          .toList();
    }
    return [];
  }

  /// Look up a user by username on a known instance
  /// `username` may be "user" or "user@instance"
  Future<MastodonUser?> getUserByUsername(
    String instance,
    String username,
  ) async {
    // Strip leading @ if present
    var query = username.startsWith('@') ? username.substring(1) : username;

    final url = await _buildUrl(
      instance,
      '/api/v1/accounts/search',
      {
        'q': query,
        'limit': '1',
        'resolve': 'true',
      },
    );

    final json = await _getJson(url);

    if (json is List && json.isNotEmpty && json.first is Map<String, dynamic>) {
      return MastodonUser.fromJson(json.first as Map<String, dynamic>);
    }

    return null;
  }

  // ===== Own account storage =====

/// Keys for SharedPreferences
static const _keyOwnAccountId = 'ownAccountId';
static const _keyOwnUsername = 'ownUsername';
static const _keyOwnAcct = 'ownAcct';
static const _keyOwnDisplayName = 'ownDisplayName';
static const _keyOwnAvatar = 'ownAvatar';
static const _keyOwnHeader = 'ownHeader';

/// Store user info fetched by ApiOAuth
Future<void> storeOwnAccountInfo({
  required String id,
  required String username,
  required String acct,
  required String displayName,
  String? avatar,
  String? header,
}) async {
  await setPrefString(_keyOwnAccountId, id);
  await setPrefString(_keyOwnUsername, username);
  await setPrefString(_keyOwnAcct, acct);
  await setPrefString(_keyOwnDisplayName, displayName);
  if (avatar != null) await setPrefString(_keyOwnAvatar, avatar);
  if (header != null) await setPrefString(_keyOwnHeader, header);
}

/// Fetch stored own account info
Future<Map<String, String?>> getOwnAccountInfo() async {
  return {
    'id': await getPrefString(_keyOwnAccountId),
    'username': await getPrefString(_keyOwnUsername),
    'acct': await getPrefString(_keyOwnAcct),
    'displayName': await getPrefString(_keyOwnDisplayName),
    'avatar': await getPrefString(_keyOwnAvatar),
    'header': await getPrefString(_keyOwnHeader),
  };
}

/// Convenience getters
Future<String?> getOwnAccountId() => getPrefString(_keyOwnAccountId);
Future<String?> getOwnUsername() => getPrefString(_keyOwnUsername);
Future<String?> getOwnAcct() => getPrefString(_keyOwnAcct);
Future<String?> getOwnDisplayName() => getPrefString(_keyOwnDisplayName);
Future<String?> getOwnAvatar() => getPrefString(_keyOwnAvatar);
Future<String?> getOwnHeader() => getPrefString(_keyOwnHeader);

/// Clear stored user info
Future<void> clearOwnAccountInfo() async {
  await removeKey(_keyOwnAccountId);
  await removeKey(_keyOwnUsername);
  await removeKey(_keyOwnAcct);
  await removeKey(_keyOwnDisplayName);
  await removeKey(_keyOwnAvatar);
  await removeKey(_keyOwnHeader);
}



  // ===== SharedPreferences helpers =====
  Future<String?> getPrefString(String key) async => (await SharedPreferences.getInstance()).getString(key);
  Future<bool> setPrefString(String key, String value) async => (await SharedPreferences.getInstance()).setString(key, value);
  Future<int?> getPrefInt(String key) async => (await SharedPreferences.getInstance()).getInt(key);
  Future<bool> setPrefInt(String key, int value) async => (await SharedPreferences.getInstance()).setInt(key, value);
  Future<bool> removeKey(String key) async => (await SharedPreferences.getInstance()).remove(key);
  Future<bool> containsKey(String key) async => (await SharedPreferences.getInstance()).containsKey(key);
  Future<bool> clear() async => (await SharedPreferences.getInstance()).clear();
}
