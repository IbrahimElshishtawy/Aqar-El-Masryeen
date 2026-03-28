import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> writeBool(String key, bool value) =>
      write(key, value.toString());

  Future<bool> readBool(String key, {bool fallback = false}) async {
    final value = await read(key);
    if (value == null) {
      return fallback;
    }
    return value.toLowerCase() == 'true';
  }

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();
}
