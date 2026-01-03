// helper.dart
import 'package:shared_preferences/shared_preferences.dart';

class Helper {
  static final Helper _instance = Helper._internal();

  Helper._internal();

  factory Helper.get() => _instance;

  // ===== Access token =====

  Future<String?> getAccessToken() async {
    return getPrefString('accessToken');
  }

  // ===== Instance =====

  Future<String?> getHomeInstanceName() async {
    return getPrefString('homeInstanceName');
  }

  Future<bool> setHomeInstanceName(String value) async {
    return setPrefString('homeInstanceName', value);
  }

  // ===== Mastodon API URLs =====

  Future<Uri> getBoostUrl(String statusId) async {
    final instance = await getHomeInstanceName();
    if (instance == null || instance.isEmpty) {
      throw StateError('Home instance name is not set');
    }

    return Uri.https(
      instance,
      '/api/v1/statuses/$statusId/reblog',
    );
  }

  Future<Uri> getUnboostUrl(String statusId) async {
    final instance = await getHomeInstanceName();
    if (instance == null || instance.isEmpty) {
      throw StateError('Home instance name is not set');
    }

    return Uri.https(
      instance,
      '/api/v1/statuses/$statusId/unreblog',
    );
  }

  Future<Uri> getFavouriteUrl(String statusId) async {
    final instance = await getHomeInstanceName();
    if (instance == null || instance.isEmpty) {
      throw StateError('Home instance name is not set');
    }

    return Uri.https(
      instance,
      '/api/v1/statuses/$statusId/favourite',
    );
  }

  // ✅ NEW: unfavourite endpoint
  Future<Uri> getUnfavouriteUrl(String statusId) async {
    final instance = await getHomeInstanceName();
    if (instance == null || instance.isEmpty) {
      throw StateError('Home instance name is not set');
    }

    return Uri.https(
      instance,
      '/api/v1/statuses/$statusId/unfavourite',
    );
  }

  // ===== SharedPreferences helpers =====

  Future<String?> getPrefString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<bool> setPrefString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  Future<int?> getPrefInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  Future<bool> setPrefInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(key, value);
  }

  Future<bool> removeKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }

  Future<bool> containsKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  Future<bool> clear() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }


}

