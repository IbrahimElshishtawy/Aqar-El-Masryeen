import 'package:aqarelmasryeen/core/constants/storage_keys.dart';
import 'package:aqarelmasryeen/core/services/local_cache_service.dart';
import 'package:aqarelmasryeen/core/services/secure_storage_service.dart';
import 'package:aqarelmasryeen/data/models/cached_session.dart';
import 'package:aqarelmasryeen/data/models/phone_verification_session.dart';

class SessionService {
  SessionService(this._secureStorageService, this._localCacheService);

  final SecureStorageService _secureStorageService;
  final LocalCacheService _localCacheService;

  bool _isLocked = false;

  bool get isLockedSync => _isLocked;

  Future<void> initializeLockState() async {
    _isLocked = await _secureStorageService.readBool(StorageKeys.sessionLocked);
  }

  Future<bool> isOnboardingSeen() =>
      _localCacheService.readBool(StorageKeys.onboardingSeen);

  Future<void> markOnboardingSeen() =>
      _localCacheService.writeBool(StorageKeys.onboardingSeen, true);

  Future<void> cacheSession(CachedSession session) async {
    await _secureStorageService.write(StorageKeys.cachedUserId, session.userId);
    await _secureStorageService.write(StorageKeys.cachedPhone, session.phone);
    await _secureStorageService.write(StorageKeys.cachedName, session.fullName);
    await _secureStorageService.write(StorageKeys.cachedRole, session.roleKey);
  }

  Future<CachedSession?> readCachedSession() async {
    final userId = await _secureStorageService.read(StorageKeys.cachedUserId);
    final phone = await _secureStorageService.read(StorageKeys.cachedPhone);
    final fullName = await _secureStorageService.read(StorageKeys.cachedName);
    final roleKey = await _secureStorageService.read(StorageKeys.cachedRole);

    if (userId == null ||
        phone == null ||
        fullName == null ||
        roleKey == null) {
      return null;
    }

    return CachedSession(
      userId: userId,
      phone: phone,
      fullName: fullName,
      roleKey: roleKey,
    );
  }

  Future<void> cachePhoneVerificationSession(
    PhoneVerificationSession session,
  ) async {
    await _secureStorageService.write(
      StorageKeys.pendingVerificationPhone,
      session.phone,
    );
    await _secureStorageService.write(
      StorageKeys.pendingVerificationId,
      session.verificationId,
    );
    await _secureStorageService.writeBool(
      StorageKeys.pendingVerificationIsRegistration,
      session.isRegistration,
    );

    if (session.resendToken == null) {
      await _secureStorageService.delete(
        StorageKeys.pendingVerificationResendToken,
      );
      return;
    }

    await _secureStorageService.write(
      StorageKeys.pendingVerificationResendToken,
      session.resendToken.toString(),
    );
  }

  Future<PhoneVerificationSession?> readPhoneVerificationSession() async {
    final phone = await _secureStorageService.read(
      StorageKeys.pendingVerificationPhone,
    );
    final verificationId = await _secureStorageService.read(
      StorageKeys.pendingVerificationId,
    );
    final isRegistrationRaw = await _secureStorageService.read(
      StorageKeys.pendingVerificationIsRegistration,
    );
    final resendTokenRaw = await _secureStorageService.read(
      StorageKeys.pendingVerificationResendToken,
    );

    if (phone == null || verificationId == null || isRegistrationRaw == null) {
      return null;
    }

    return PhoneVerificationSession(
      phone: phone,
      verificationId: verificationId,
      isRegistration: isRegistrationRaw.toLowerCase() == 'true',
      resendToken: int.tryParse(resendTokenRaw ?? ''),
    );
  }

  Future<void> clearPhoneVerificationSession() async {
    await _secureStorageService.delete(StorageKeys.pendingVerificationPhone);
    await _secureStorageService.delete(StorageKeys.pendingVerificationId);
    await _secureStorageService.delete(
      StorageKeys.pendingVerificationIsRegistration,
    );
    await _secureStorageService.delete(
      StorageKeys.pendingVerificationResendToken,
    );
  }

  Future<void> setBiometricEnabled(bool enabled) =>
      _secureStorageService.writeBool(StorageKeys.biometricEnabled, enabled);

  Future<bool> isBiometricEnabled() =>
      _secureStorageService.readBool(StorageKeys.biometricEnabled);

  Future<void> setAppLockEnabled(bool enabled) =>
      _secureStorageService.writeBool(StorageKeys.appLockEnabled, enabled);

  Future<bool> isAppLockEnabled() =>
      _secureStorageService.readBool(StorageKeys.appLockEnabled);

  Future<void> lockApp() async {
    _isLocked = true;
    await _secureStorageService.writeBool(StorageKeys.sessionLocked, true);
  }

  Future<void> unlockApp() async {
    _isLocked = false;
    await _secureStorageService.writeBool(StorageKeys.sessionLocked, false);
  }

  Future<void> clearSession({bool keepOnboarding = true}) async {
    final onboardingSeen = keepOnboarding ? await isOnboardingSeen() : false;
    await _secureStorageService.deleteAll();
    await _localCacheService.remove(StorageKeys.notificationToken);
    _isLocked = false;
    if (onboardingSeen) {
      await markOnboardingSeen();
    }
  }
}
