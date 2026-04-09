import 'dart:async';

import 'package:aqarelmasryeen/core/constants/secure_storage_keys.dart';
import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/services/device_info_service.dart';
import 'package:aqarelmasryeen/core/services/secure_storage_service.dart';
import 'package:aqarelmasryeen/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:aqarelmasryeen/features/auth/data/datasources/firebase_auth_remote_data_source.dart';
import 'package:aqarelmasryeen/features/auth/data/datasources/user_profile_remote_data_source.dart';
import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:aqarelmasryeen/features/auth/domain/auth_repository.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/models/app_user.dart';
import 'package:aqarelmasryeen/shared/models/auth_device_info.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(
    this._authDataSource,
    this._profileDataSource,
    this._localDataSource,
    this._activityRepository,
    this._notificationRepository,
    this._secureStorage,
    this._deviceInfoService,
    this._analytics,
    this._crashlytics,
  );

  final FirebaseAuthRemoteDataSource _authDataSource;
  final UserProfileRemoteDataSource _profileDataSource;
  final AuthLocalDataSource _localDataSource;
  final ActivityRepository _activityRepository;
  final NotificationRepository _notificationRepository;
  final SecureStorageService _secureStorage;
  final DeviceInfoService _deviceInfoService;
  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;

  @override
  Stream<AppSession?> watchSession() async* {
    await for (final user in _authDataSource.authStateChanges()) {
      if (user == null) {
        await _secureStorage.clearSessionData();
        yield null;
        continue;
      }

      final cachedProfile = await _localDataSource.readProfile(user.uid);
      if (cachedProfile != null) {
        yield AppSession.fromFirebaseUser(
          firebaseUser: user,
          profile: cachedProfile,
        );
      }

      yield* _profileDataSource.watchProfile(user.uid).asyncMap((
        profile,
      ) async {
        final resolvedProfile =
            profile ??
            cachedProfile ??
            await _profileDataSource.fetchProfile(user.uid);
        await _syncLocalSession(resolvedProfile, user.uid);
        return AppSession.fromFirebaseUser(
          firebaseUser: user,
          profile: resolvedProfile,
        );
      });
    }
  }

  @override
  Future<AppSession?> restoreSession() async {
    final user = _authDataSource.currentUser;
    if (user == null) {
      return null;
    }

    final cachedProfile = await _localDataSource.readProfile(user.uid);
    if (cachedProfile != null) {
      unawaited(_refreshCachedProfile(user.uid));
      return AppSession.fromFirebaseUser(
        firebaseUser: user,
        profile: cachedProfile,
      );
    }

    final profile = await _profileDataSource.fetchProfile(user.uid);
    await _syncLocalSession(profile, user.uid);
    return AppSession.fromFirebaseUser(firebaseUser: user, profile: profile);
  }

  @override
  Future<void> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = fullName.trim();

    try {
      final credential = await _authDataSource.createUserWithEmail(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AppException(
          'Ù„Ù… ÙŠØªÙ… Ø¥Ø±Ø¬Ø§Ø¹ Ù…Ø³ØªØ®Ø¯Ù… Ø¨Ø¹Ø¯ Ø¥Ù†Ø´Ø§Ø¡ Ø§Ù„Ø­Ø³Ø§Ø¨.',
        );
      }

      await _authDataSource.updateDisplayName(user, normalizedName);
      await _authDataSource.reloadUser(user);

      final deviceInfo = await _deviceInfoService.currentDeviceInfo();
      await _profileDataSource.createOrMergeProfile(
        uid: user.uid,
        fullName: normalizedName,
        email: normalizedEmail,
        deviceInfo: deviceInfo,
      );

      final profile = await _profileDataSource.fetchProfile(user.uid);
      await _syncLocalSession(profile, user.uid);
      await _analytics.logSignUp(signUpMethod: 'email_password');
      await _logSecurityEvent(
        actorId: user.uid,
        actorName: normalizedName,
        action: 'register',
        metadata: {'email': normalizedEmail},
      );
    } catch (error, stackTrace) {
      _recordError(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<AppUser> provisionPartnerAccount({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = fullName.trim();

    try {
      final createdUid = await _authDataSource.createUserWithEmailOnIsolatedApp(
        email: normalizedEmail,
        password: password,
        fullName: normalizedName,
        appName: 'partner-provision-${DateTime.now().microsecondsSinceEpoch}',
      );

      final deviceInfo = await _deviceInfoService.currentDeviceInfo();
      await _profileDataSource.createOrMergeProfile(
        uid: createdUid,
        fullName: normalizedName,
        email: normalizedEmail,
        deviceInfo: deviceInfo,
      );

      final profile = await _profileDataSource.fetchProfile(createdUid);
      if (profile == null) {
        throw const AppException('تم إنشاء الحساب لكن تعذر تحميل بياناته.');
      }
      return profile;
    } catch (error, stackTrace) {
      _recordError(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final credential = await _authDataSource.signInWithEmail(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AppException('Authentication did not return a user.');
      }

      final deviceInfo = await _deviceInfoService.currentDeviceInfo();
      var profile = await _profileDataSource.fetchProfile(user.uid);
      if (profile != null && !profile.isActive) {
        await _authDataSource.signOut();
        throw const AppException(
          'Ù‡Ø°Ø§ Ø§Ù„Ø­Ø³Ø§Ø¨ Ù…Ø¹Ø·Ù„. ØªÙˆØ§ØµÙ„ Ù…Ø¹ Ø§Ù„Ù…Ø³Ø¤ÙˆÙ„.',
          code: 'account_disabled',
        );
      }

      final previousDeviceId = profile?.deviceInfo?.deviceId ?? '';
      profile = await _ensureProfileForSignedInUser(
        user: user,
        fallbackEmail: normalizedEmail,
        deviceInfo: deviceInfo,
        existingProfile: profile,
      );

      if (profile != null) {
        final isNewDevice =
            previousDeviceId.isNotEmpty &&
            previousDeviceId != deviceInfo.deviceId;
        await _profileDataSource.touchLogin(
          uid: user.uid,
          deviceInfo: deviceInfo,
        );
        if (isNewDevice) {
          await _notificationRepository.createSecurityNotification(
            userId: user.uid,
            title: 'ØªÙ… Ø§ÙƒØªØ´Ø§Ù Ø¬Ù‡Ø§Ø² Ù…ÙˆØ«ÙˆÙ‚ Ø¬Ø¯ÙŠØ¯',
            body:
                'ØªÙ… Ø§Ø³ØªØ®Ø¯Ø§Ù… ${deviceInfo.deviceName} Ù„ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„.',
            route: AppRoutes.settings,
          );
        }
      }

      await _syncLocalSession(profile, user.uid);
      await _analytics.logLogin(loginMethod: 'email_password');
      await _logSecurityEvent(
        actorId: user.uid,
        actorName: _actorName(user, profile, normalizedEmail),
        action: 'login',
        metadata: {'route': 'email_password'},
      );
    } catch (error, stackTrace) {
      _recordError(error, stackTrace);
      rethrow;
    }
  }

  Future<AppUser?> _ensureProfileForSignedInUser({
    required User user,
    required String fallbackEmail,
    required AuthDeviceInfo deviceInfo,
    required AppUser? existingProfile,
  }) async {
    final normalizedDisplayName = user.displayName?.trim() ?? '';
    final existingName = existingProfile?.fullName.trim() ?? '';
    final resolvedName = normalizedDisplayName.isNotEmpty
        ? normalizedDisplayName
        : existingName.isNotEmpty
        ? existingName
        : fallbackEmail.split('@').first;
    final userEmail = user.email?.trim().toLowerCase() ?? '';
    final resolvedEmail = userEmail.isNotEmpty ? userEmail : fallbackEmail;

    await _profileDataSource.createOrMergeProfile(
      uid: user.uid,
      fullName: resolvedName,
      email: resolvedEmail,
      deviceInfo: deviceInfo,
      biometricEnabled: existingProfile?.biometricEnabled ?? false,
      appLockEnabled: existingProfile?.appLockEnabled ?? true,
      trustedDeviceEnabled: existingProfile?.trustedDeviceEnabled ?? false,
      isActive: existingProfile?.isActive ?? true,
      role: existingProfile?.role.name ?? 'partner',
    );

    return _profileDataSource.fetchProfile(user.uid);
  }

  @override
  Future<void> completeProfile({
    required String fullName,
    required String email,
    String? password,
  }) async {
    final user = _authDataSource.currentUser;
    if (user == null) {
      throw const AppException(
        'Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ù…Ø³ØªØ®Ø¯Ù… Ù…Ø³Ø¬Ù„ Ø­Ø§Ù„ÙŠÙ‹Ø§.',
      );
    }

    final normalizedName = fullName.trim();
    final requestedEmail = email.trim().toLowerCase();
    final authEmail = user.email?.trim().toLowerCase();
    final hasEmailProvider = user.providerData.any(
      (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
    );

    try {
      final profileEmail = authEmail?.isNotEmpty == true
          ? authEmail!
          : requestedEmail;

      if (!hasEmailProvider || authEmail == null || authEmail.isEmpty) {
        if ((password ?? '').isEmpty) {
          throw const AppException(
            'Ø£Ù†Ø´Ø¦ ÙƒÙ„Ù…Ø© Ù…Ø±ÙˆØ± Ù„Ø¥ÙƒÙ…Ø§Ù„ ØªØ±Ø­ÙŠÙ„ Ù‡Ø°Ø§ Ø§Ù„Ø­Ø³Ø§Ø¨.',
            code: 'password_required',
          );
        }
        await _authDataSource.linkEmailCredential(
          user: user,
          email: profileEmail,
          password: password!,
        );
      } else if (requestedEmail.isNotEmpty && requestedEmail != profileEmail) {
        throw const AppException(
          'Ø§Ø³ØªØ®Ø¯Ù… Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ Ø§Ù„Ø­Ø§Ù„ÙŠ Ù„Ø¥ÙƒÙ…Ø§Ù„ Ø§Ù„Ù…Ù„Ù Ø§Ù„Ø´Ø®ØµÙŠ.',
          code: 'email_mismatch',
        );
      }

      await _authDataSource.updateDisplayName(user, normalizedName);
      await _authDataSource.reloadUser(user);

      final deviceInfo = await _deviceInfoService.currentDeviceInfo();
      await _profileDataSource.completeProfile(
        user: user,
        fullName: normalizedName,
        email: profileEmail,
        deviceInfo: deviceInfo,
      );

      final profile = await _profileDataSource.fetchProfile(user.uid);
      await _syncLocalSession(profile, user.uid);
      await _logSecurityEvent(
        actorId: user.uid,
        actorName: normalizedName,
        action: 'profile_completed',
        metadata: {'email': profileEmail},
      );
      await _analytics.logEvent(name: 'profile_completed');
    } catch (error, stackTrace) {
      _recordError(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> saveSecurityPreferences({
    required bool trustedDeviceEnabled,
    required bool biometricEnabled,
    required bool appLockEnabled,
    required int inactivityTimeoutSeconds,
  }) async {
    final user = _authDataSource.currentUser;
    if (user == null) {
      throw const AppException(
        'Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ù…Ø³ØªØ®Ø¯Ù… Ù…Ø³Ø¬Ù„ Ø­Ø§Ù„ÙŠÙ‹Ø§.',
      );
    }

    try {
      final deviceInfo = await _deviceInfoService.currentDeviceInfo();
      await _profileDataSource.updateSecurityPreferences(
        uid: user.uid,
        trustedDeviceEnabled: trustedDeviceEnabled,
        biometricEnabled: biometricEnabled,
        appLockEnabled: appLockEnabled,
        inactivityTimeoutSeconds: inactivityTimeoutSeconds,
        deviceInfo: deviceInfo,
      );
      await _secureStorage.persistSecurityPreferences(
        trustedDeviceEnabled: trustedDeviceEnabled,
        biometricEnabled: biometricEnabled,
        appLockEnabled: appLockEnabled,
        inactivityTimeoutSeconds: inactivityTimeoutSeconds,
      );
      await _logSecurityEvent(
        actorId: user.uid,
        actorName: user.displayName ?? user.email ?? 'Ø´Ø±ÙŠÙƒ',
        action: 'security_preferences_updated',
        metadata: {
          'trustedDeviceEnabled': trustedDeviceEnabled,
          'biometricEnabled': biometricEnabled,
          'appLockEnabled': appLockEnabled,
          'inactivityTimeoutSeconds': inactivityTimeoutSeconds,
        },
      );
    } catch (error, stackTrace) {
      _recordError(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> setBiometrics(bool enabled) async {
    final user = _authDataSource.currentUser;
    if (user == null) {
      throw const AppException('No authenticated user found.');
    }

    await _profileDataSource.setBiometricPreference(
      uid: user.uid,
      biometricEnabled: enabled,
    );
    final appLockEnabled =
        await _secureStorage.readBool(SecureStorageKeys.appLockEnabled) ?? true;
    final inactivityTimeoutSeconds =
        await _secureStorage.readInt(
          SecureStorageKeys.inactivityTimeoutSeconds,
        ) ??
        90;
    final trustedDeviceEnabled =
        await _secureStorage.readBool(SecureStorageKeys.trustedDeviceEnabled) ??
        enabled;
    await _secureStorage.persistSecurityPreferences(
      trustedDeviceEnabled: trustedDeviceEnabled,
      biometricEnabled: enabled,
      appLockEnabled: appLockEnabled,
      inactivityTimeoutSeconds: inactivityTimeoutSeconds,
    );
  }

  @override
  Future<void> signOut() async {
    final user = _authDataSource.currentUser;
    if (user != null) {
      await _logSecurityEvent(
        actorId: user.uid,
        actorName: user.displayName ?? user.email ?? 'Ø´Ø±ÙŠÙƒ',
        action: 'logout',
      );
      await _analytics.logEvent(name: 'secure_logout');
      await _localDataSource.clearProfile(user.uid);
    }
    await _secureStorage.clearSessionData();
    await _authDataSource.signOut();
  }

  Future<void> _refreshCachedProfile(String uid) async {
    try {
      final profile = await _profileDataSource.fetchProfile(uid);
      await _syncLocalSession(profile, uid);
    } catch (_) {
      // Keep cached data as the startup fallback when the network is unavailable.
    }
  }

  Future<void> _syncLocalSession(AppUser? profile, String uid) async {
    await _secureStorage.markAppOpened();
    await _secureStorage.writeLastKnownUid(uid);
    if (profile == null) {
      await _localDataSource.clearProfile(uid);
      await _secureStorage.clearSessionData();
      return;
    }

    await _localDataSource.cacheProfile(profile);
    await _secureStorage.persistSecurityPreferences(
      trustedDeviceEnabled: profile.trustedDeviceEnabled,
      biometricEnabled: profile.biometricEnabled,
      appLockEnabled: profile.appLockEnabled,
      inactivityTimeoutSeconds: profile.inactivityTimeoutSeconds,
    );
  }

  Future<void> _logSecurityEvent({
    required String actorId,
    required String actorName,
    required String action,
    Map<String, dynamic> metadata = const {},
  }) {
    return _activityRepository.log(
      actorId: actorId,
      actorName: actorName,
      action: action,
      entityType: 'user',
      entityId: actorId,
      metadata: metadata,
    );
  }

  String _actorName(User user, AppUser? profile, String fallbackEmail) {
    final profileName = profile?.fullName.trim() ?? '';
    if (profileName.isNotEmpty) {
      return profileName;
    }
    final displayName = user.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }
    return fallbackEmail;
  }

  void _recordError(Object error, StackTrace stackTrace) {
    _crashlytics.recordError(error, stackTrace, fatal: false);
  }
}
