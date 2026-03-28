import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  SharedPreferences? _preferences;

  Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  Future<void> writeString(String key, String value) async {
    await initialize();
    await _preferences!.setString(key, value);
  }

  Future<String?> readString(String key) async {
    await initialize();
    return _preferences!.getString(key);
  }

  Future<void> writeBool(String key, bool value) async {
    await initialize();
    await _preferences!.setBool(key, value);
  }

  Future<bool> readBool(String key, {bool fallback = false}) async {
    await initialize();
    return _preferences!.getBool(key) ?? fallback;
  }

  Future<void> remove(String key) async {
    await initialize();
    await _preferences!.remove(key);
  }
}
