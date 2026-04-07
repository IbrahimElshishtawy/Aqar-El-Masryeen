import 'package:aqarelmasryeen/core/services/secure_storage_service.dart';
import 'package:aqarelmasryeen/core/storage/cache_keys.dart';
import 'package:aqarelmasryeen/core/storage/local_cache_service.dart';
import 'package:aqarelmasryeen/shared/models/app_user.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._cache, this._secureStorage);

  final LocalCacheService _cache;
  final SecureStorageService _secureStorage;

  Future<void> cacheProfile(AppUser profile) async {
    await _cache.writeObject(CacheKeys.authProfile(profile.uid), profile.toMap());
  }

  Future<AppUser?> readProfile(String uid) async {
    final data = await _cache.readObject(CacheKeys.authProfile(uid));
    if (data == null) {
      return null;
    }
    return AppUser.fromMap(uid, data);
  }

  Future<AppUser?> readLastKnownProfile() async {
    final uid = await _secureStorage.readLastKnownUid();
    if (uid == null || uid.isEmpty) {
      return null;
    }
    return readProfile(uid);
  }

  Future<void> clearProfile(String uid) async {
    await _cache.remove(CacheKeys.authProfile(uid));
  }

  Future<void> clearAllProfiles() async {
    await _cache.clearByPrefix('${CacheKeys.auth}.profile.');
  }

  Future<bool> readMockSessionActive() async {
    return await _cache.readBool(CacheKeys.mockSessionActive) ?? true;
  }

  Future<void> writeMockSessionActive(bool value) async {
    await _cache.writeBool(CacheKeys.mockSessionActive, value);
  }
}
