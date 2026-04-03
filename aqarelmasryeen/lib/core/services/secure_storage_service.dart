import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:aqarelmasryeen/core/constants/secure_storage_keys.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;
  Future<SharedPreferences>? _preferences;

  Future<SharedPreferences> get _sharedPreferences =>
      _preferences ??= SharedPreferences.getInstance();

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (error, stackTrace) {
      _logFallback('write', key, error, stackTrace);
    }

    try {
      final prefs = await _sharedPreferences;
      await prefs.setString(key, value);
    } catch (error, stackTrace) {
      _logFallback('write_cache', key, error, stackTrace);
    }
  }

  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value != null) {
        final prefs = await _sharedPreferences;
        await prefs.setString(key, value);
      }
      if (value != null) {
        return value;
      }
    } catch (error, stackTrace) {
      _logFallback('read', key, error, stackTrace);
    }

    try {
      final prefs = await _sharedPreferences;
      return prefs.getString(key);
    } catch (error, stackTrace) {
      _logFallback('read_cache', key, error, stackTrace);
      return null;
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (error, stackTrace) {
      _logFallback('delete', key, error, stackTrace);
    }

    try {
      final prefs = await _sharedPreferences;
      await prefs.remove(key);
    } catch (error, stackTrace) {
      _logFallback('delete_cache', key, error, stackTrace);
    }
  }

  Future<void> writeBool(String key, bool value) =>
      write(key, value ? 'true' : 'false');

  Future<bool?> readBool(String key) async {
    final value = await read(key);
    if (value == null) return null;
    return value == 'true';
  }

  Future<void> writeInt(String key, int value) => write(key, value.toString());

  Future<int?> readInt(String key) async {
    final value = await read(key);
    return value == null ? null : int.tryParse(value);
  }

  Future<void> writeDateTime(String key, DateTime value) =>
      write(key, value.toIso8601String());

  Future<DateTime?> readDateTime(String key) async {
    final value = await read(key);
    return value == null ? null : DateTime.tryParse(value)?.toLocal();
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) =>
      write(key, jsonEncode(value));

  Future<Map<String, dynamic>?> readJson(String key) async {
    final value = await read(key);
    if (value == null || value.isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (error, stackTrace) {
      _logFallback('decode_json', key, error, stackTrace);
      return null;
    }
  }

  Future<bool> hasOpenedAppBefore() async =>
      await readBool(SecureStorageKeys.hasOpenedApp) ?? false;

  Future<void> markAppOpened() =>
      writeBool(SecureStorageKeys.hasOpenedApp, true);

  Future<String?> readLastKnownUid() => read(SecureStorageKeys.lastKnownUid);

  Future<void> writeLastKnownUid(String uid) =>
      write(SecureStorageKeys.lastKnownUid, uid);

  Future<void> persistSecurityPreferences({
    required bool trustedDeviceEnabled,
    required bool biometricEnabled,
    required bool appLockEnabled,
    required int inactivityTimeoutSeconds,
  }) async {
    await writeBool(
      SecureStorageKeys.trustedDeviceEnabled,
      trustedDeviceEnabled,
    );
    await writeBool(SecureStorageKeys.biometricEnabled, biometricEnabled);
    await writeBool(SecureStorageKeys.appLockEnabled, appLockEnabled);
    await writeInt(
      SecureStorageKeys.inactivityTimeoutSeconds,
      inactivityTimeoutSeconds,
    );
  }

  Future<void> clearSessionData() async {
    await Future.wait([
      delete(SecureStorageKeys.appLockEnabled),
      delete(SecureStorageKeys.biometricEnabled),
      delete(SecureStorageKeys.trustedDeviceEnabled),
      delete(SecureStorageKeys.inactivityTimeoutSeconds),
      delete(SecureStorageKeys.lastActivityAt),
      delete(SecureStorageKeys.lastBackgroundAt),
      delete(SecureStorageKeys.isLocked),
    ]);
  }

  void _logFallback(
    String operation,
    String key,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      'SecureStorageService fallback on $operation for "$key": $error',
    );
    debugPrintStack(stackTrace: stackTrace, maxFrames: 4);
  }
}
