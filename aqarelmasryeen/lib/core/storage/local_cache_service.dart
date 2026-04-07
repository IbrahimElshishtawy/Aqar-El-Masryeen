import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  LocalCacheService();

  static const _cachedAtSuffix = '__cached_at';

  Future<SharedPreferences>? _preferences;

  Future<SharedPreferences> get _prefs =>
      _preferences ??= SharedPreferences.getInstance();

  Future<void> writeObject(String key, Map<String, dynamic> value) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(_normalize(value)));
    await prefs.setString(_timestampKey(key), DateTime.now().toIso8601String());
  }

  Future<Map<String, dynamic>?> readObject(String key) async {
    final prefs = await _prefs;
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map(
        (dynamic key, dynamic value) => MapEntry(key.toString(), value),
      );
    }
    return null;
  }

  Future<void> writeObjectList(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(_normalize(value)));
    await prefs.setString(_timestampKey(key), DateTime.now().toIso8601String());
  }

  Future<List<Map<String, dynamic>>> readObjectList(String key) async {
    final prefs = await _prefs;
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (entry) => entry.map(
            (dynamic key, dynamic value) => MapEntry(key.toString(), value),
          ),
        )
        .toList(growable: false);
  }

  Future<void> writeBool(String key, bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(key, value);
    await prefs.setString(_timestampKey(key), DateTime.now().toIso8601String());
  }

  Future<bool?> readBool(String key) async {
    final prefs = await _prefs;
    return prefs.getBool(key);
  }

  Future<DateTime?> readCachedAt(String key) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_timestampKey(key));
    return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
  }

  Future<void> remove(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
    await prefs.remove(_timestampKey(key));
  }

  Future<void> clearByPrefix(String prefix) async {
    final prefs = await _prefs;
    final matchingKeys = prefs.getKeys().where((key) => key.startsWith(prefix));
    for (final key in matchingKeys) {
      await prefs.remove(key);
    }
  }

  String _timestampKey(String key) => '$key$_cachedAtSuffix';

  Object? _normalize(Object? value) {
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Iterable) {
      return value.map(_normalize).toList(growable: false);
    }
    if (value is Map) {
      return value.map(
        (dynamic key, dynamic item) => MapEntry(key.toString(), _normalize(item)),
      );
    }
    return value;
  }
}
