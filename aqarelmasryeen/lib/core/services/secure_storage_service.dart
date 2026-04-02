import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const biometricEnabledKey = 'biometric_enabled';
  static const trustedDeviceKey = 'trusted_device';
  static const lastActivityAtKey = 'last_activity_at';

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> clearSession() => _storage.deleteAll();
}
