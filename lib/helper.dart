import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Helper {
  static final Helper _instance = Helper._internal();
  Helper._internal();
  factory Helper.get() => _instance;

  // ===== Access token =====
  Future<String?> getAccessToken() => getPrefString('accessToken');
  Future<bool> setAccessToken(String value) =>
      setPrefString('accessToken', value);

  // ===== Instance =====
  Future<String?> getHomeInstanceName() => getPrefString('homeInstanceName');
  Future<bool> setHomeInstanceName(String value) =>
      setPrefString('homeInstanceName', value);

  // ===== Internal URL builder =====
  Future<Uri> _buildUrl(String path, [Map<String, String>? query]) async {
    final instance = await getHomeInstanceName();
    if (instance == null || instance.isEmpty) {
      throw StateError('Home instance name is not set');
    }

    final host = instance.replaceAll(RegExp(r'^https?://'), '');
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

  // ===== Media upload (with MIME fix) =====
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

      // Detect MIME type from extension
      final ext = file.path.split('.').last.toLowerCase();
      final mimeType = _detectMimeType(ext);

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
  }) async {
    final url = await _buildUrl('/api/v1/statuses');
    final body = <String, dynamic>{'status': status};

    if (inReplyToId != null) body['in_reply_to_id'] = inReplyToId;
    if (sensitive != null) body['sensitive'] = sensitive;
    if (private != null) body['visibility'] = private ? 'private' : 'public';
    if (spoilerText != null) body['spoiler_text'] = spoilerText;
    if (mediaIDs != null && mediaIDs.isNotEmpty) body['media_ids'] = mediaIDs;

    return _postJson(url, body);
  }

  Future<dynamic> boostStatus(String statusId) async =>
      _postJson(await _buildUrl('/api/v1/statuses/$statusId/reblog'));
  Future<dynamic> unboostStatus(String statusId) async =>
      _postJson(await _buildUrl('/api/v1/statuses/$statusId/unreblog'));
  Future<dynamic> favouriteStatus(String statusId) async =>
      _postJson(await _buildUrl('/api/v1/statuses/$statusId/favourite'));
  Future<dynamic> unfavouriteStatus(String statusId) async =>
      _postJson(await _buildUrl('/api/v1/statuses/$statusId/unfavourite'));
  Future<dynamic> deleteStatus(String statusId) async =>
      _deleteJson(await _buildUrl('/api/v1/statuses/$statusId'));

  // ===== Timeline helpers =====
  Future<List<dynamic>> _fetchTimeline(String path, {int? limit, String? maxId, String? sinceId}) async {
    final query = <String, String>{};
    if (limit != null) query['limit'] = '$limit';
    if (maxId != null) query['max_id'] = maxId;
    if (sinceId != null) query['since_id'] = sinceId;

    final json = await _getJson(await _buildUrl(path, query.isEmpty ? null : query));
    return json is List ? json : [];
  }

  Future<List<dynamic>> getHomeTimeline({int? limit, String? maxId, String? sinceId}) =>
      _fetchTimeline('/api/v1/timelines/home', limit: limit, maxId: maxId, sinceId: sinceId);

  Future<List<dynamic>> getLocalTimeline({int? limit, String? maxId, String? sinceId}) =>
      _fetchTimeline('/api/v1/timelines/public', limit: limit, maxId: maxId, sinceId: sinceId);

  Future<List<dynamic>> getFederatedTimeline({int? limit, String? maxId, String? sinceId}) =>
      _fetchTimeline('/api/v1/timelines/public', limit: limit, maxId: maxId, sinceId: sinceId);

  Future<List<dynamic>> getUserTimeline(String accountId, {int? limit, String? maxId, String? sinceId}) =>
      _fetchTimeline('/api/v1/accounts/$accountId/statuses', limit: limit, maxId: maxId, sinceId: sinceId);

  Future<List<dynamic>> getHashtagTimeline(String hashtag, {int? limit, String? maxId, String? sinceId}) =>
      _fetchTimeline('/api/v1/timelines/tag/$hashtag', limit: limit, maxId: maxId, sinceId: sinceId);

  // ===== Notifications =====
  Future<List<dynamic>> _fetchNotifications({int? limit, String? maxId, String? sinceId}) async {
    final query = <String, String>{};
    if (limit != null) query['limit'] = '$limit';
    if (maxId != null) query['max_id'] = maxId;
    if (sinceId != null) query['since_id'] = sinceId;

    final json = await _getJson(await _buildUrl('/api/v1/notifications', query.isEmpty ? null : query));
    return json is List ? json : [];
  }

  Future<List<dynamic>> getNotifications({int? limit, String? maxId, String? sinceId}) =>
      _fetchNotifications(limit: limit, maxId: maxId, sinceId: sinceId);

  // ===== SharedPreferences helpers =====
  Future<String?> getPrefString(String key) async => (await SharedPreferences.getInstance()).getString(key);
  Future<bool> setPrefString(String key, String value) async => (await SharedPreferences.getInstance()).setString(key, value);
  Future<int?> getPrefInt(String key) async => (await SharedPreferences.getInstance()).getInt(key);
  Future<bool> setPrefInt(String key, int value) async => (await SharedPreferences.getInstance()).setInt(key, value);
  Future<bool> removeKey(String key) async => (await SharedPreferences.getInstance()).remove(key);
  Future<bool> containsKey(String key) async => (await SharedPreferences.getInstance()).containsKey(key);
  Future<bool> clear() async => (await SharedPreferences.getInstance()).clear();
}
