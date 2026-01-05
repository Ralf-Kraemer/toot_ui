// helper.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Helper {
  static final Helper _instance = Helper._internal();
  Helper._internal();
  factory Helper.get() => _instance;

  // ===== Access token =====
  Future<String?> getAccessToken() => getPrefString('accessToken');
  Future<bool> setAccessToken(String value) => setPrefString('accessToken', value);

  // ===== Instance =====
  Future<String?> getHomeInstanceName() => getPrefString('homeInstanceName');
  Future<bool> setHomeInstanceName(String value) => setPrefString('homeInstanceName', value);

  // ===== Internal URL builder =====
  Future<Uri> _buildUrl(String path, [Map<String, String>? query]) async {
    final instance = await getHomeInstanceName();
    if (instance == null || instance.isEmpty) {
      throw StateError('Home instance name is not set');
    }

    // Strip scheme if present
    final host = instance.replaceAll(RegExp(r'^https?://'), '');

    // Remove leading slash from path if present
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    return Uri.https(host, cleanPath, query);
  }


  // ===== Internal HTTP helper =====
  Future<dynamic> _requestJson(String method, Uri url, [Map<String, dynamic>? body]) async {
    final token = await getAccessToken();
    if (token == null) throw StateError('Access token is not set');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    late http.Response response;
    switch (method) {
      case 'POST':
        response = await http.post(url, headers: headers, body: body != null ? jsonEncode(body) : null);
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
      return jsonDecode(response.body); // can be Map or List
    } else {
      throw http.ClientException(
        'Request failed: ${response.statusCode} ${response.reasonPhrase}',
        response.request?.url,
      );
    }
  }

  Future<dynamic> _postJson(Uri url, [Map<String, dynamic>? body]) => _requestJson('POST', url, body);
  Future<dynamic> _getJson(Uri url) => _requestJson('GET', url);
  Future<dynamic> _deleteJson(Uri url) => _requestJson('DELETE', url);

  // ===== Status actions =====
  Future<dynamic> boostStatus(String statusId) async {
    final url = await _buildUrl('/api/v1/statuses/$statusId/reblog');
    return _postJson(url);
  }

  Future<dynamic> unboostStatus(String statusId) async {
    final url = await _buildUrl('/api/v1/statuses/$statusId/unreblog');
    return _postJson(url);
  }

  Future<dynamic> favouriteStatus(String statusId) async {
    final url = await _buildUrl('/api/v1/statuses/$statusId/favourite');
    return _postJson(url);
  }

  Future<dynamic> unfavouriteStatus(String statusId) async {
    final url = await _buildUrl('/api/v1/statuses/$statusId/unfavourite');
    return _postJson(url);
  }

  Future<dynamic> deleteStatus(String statusId) async {
    final url = await _buildUrl('/api/v1/statuses/$statusId');
    return _deleteJson(url);
  }

  Future<dynamic> postStatus(String status,
      {String? inReplyToId, bool? sensitive, String? spoilerText}) async {
    final url = await _buildUrl('/api/v1/statuses');
    final body = {'status': status};
    if (inReplyToId != null) body['in_reply_to_id'] = inReplyToId;
    if (sensitive != null) body['sensitive'] = sensitive.toString();
    if (spoilerText != null) body['spoiler_text'] = spoilerText;
    return _postJson(url, body);
  }

  // ===== Follow / Unfollow =====
  Future<dynamic> follow(String accountId) async {
    final url = await _buildUrl('/api/v1/accounts/$accountId/follow');
    return _postJson(url);
  }

  Future<dynamic> unfollow(String accountId) async {
    final url = await _buildUrl('/api/v1/accounts/$accountId/unfollow');
    return _postJson(url);
  }

  Future<dynamic> getAccountDetails(String accountId) async {
    final url = await _buildUrl('/api/v1/accounts/$accountId');
    return _getJson(url);
  }

  // ===== Timelines =====
  Future<List<dynamic>> getHomeTimeline({int? limit, String? maxId, String? sinceId}) async {
    final query = <String, String>{};
    if (limit != null) query['limit'] = '$limit';
    if (maxId != null) query['max_id'] = maxId;
    if (sinceId != null) query['since_id'] = sinceId;

    final url = await _buildUrl('/api/v1/timelines/home', query.isEmpty ? null : query);
    final json = await _getJson(url);
    return json is List ? json : [];
  }

  Future<List<dynamic>> getLocalTimeline({int? limit, String? maxId, String? sinceId}) async {
    final query = {'local': 'true'};
    if (limit != null) query['limit'] = '$limit';
    if (maxId != null) query['max_id'] = maxId;
    if (sinceId != null) query['since_id'] = sinceId;

    final url = await _buildUrl('/api/v1/timelines/public', query);
    final json = await _getJson(url);
    return json is List ? json : [];
  }

  Future<List<dynamic>> getFederatedTimeline({int? limit, String? maxId, String? sinceId}) async {
    final query = {'local': 'false'};
    if (limit != null) query['limit'] = '$limit';
    if (maxId != null) query['max_id'] = maxId;
    if (sinceId != null) query['since_id'] = sinceId;

    final url = await _buildUrl('/api/v1/timelines/public', query);
    final json = await _getJson(url);
    return json is List ? json : [];
  }

  // ===== Notifications =====
  Future<List<dynamic>> getNotifications({int? limit, String? maxId, String? sinceId}) async {
    final query = <String, String>{};
    if (limit != null) query['limit'] = '$limit';
    if (maxId != null) query['max_id'] = maxId;
    if (sinceId != null) query['since_id'] = sinceId;

    final url = await _buildUrl('/api/v1/notifications', query.isEmpty ? null : query);
    final json = await _getJson(url);
    return json is List ? json : [];
  }

  // ===== SharedPreferences helpers =====
  Future<String?> getPrefString(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  Future<bool> setPrefString(String key, String value) async =>
      (await SharedPreferences.getInstance()).setString(key, value);

  Future<int?> getPrefInt(String key) async =>
      (await SharedPreferences.getInstance()).getInt(key);

  Future<bool> setPrefInt(String key, int value) async =>
      (await SharedPreferences.getInstance()).setInt(key, value);

  Future<bool> removeKey(String key) async =>
      (await SharedPreferences.getInstance()).remove(key);

  Future<bool> containsKey(String key) async =>
      (await SharedPreferences.getInstance()).containsKey(key);

  Future<bool> clear() async =>
      (await SharedPreferences.getInstance()).clear();
}
