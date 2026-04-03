import 'dart:async';

import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/secure_storage_keys.dart';
import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/services/device_info_service.dart';
import 'package:aqarelmasryeen/core/services/secure_storage_service.dart';
import 'package:aqarelmasryeen/core/utils/phone_utils.dart';
import 'package:aqarelmasryeen/features/auth/data/datasources/firebase_auth_remote_data_source.dart';
import 'package:aqarelmasryeen/features/auth/data/datasources/user_profile_remote_data_source.dart';
import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:aqarelmasryeen/features/auth/domain/auth_repository.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(
    this._authDataSource,
    this._profileDataSource,
    this._activityRepository,
    this._notificationRepository,
    this._secureStorage,
    this._deviceInfoService,
    this._analytics,
    this._crashlytics,
  );

  final FirebaseAuthRemoteDataSource _authDataSource;
  final UserProfileRemoteDataSource _profileDataSource;
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
        yield null;
        continue;
      }

      yield* _profileDataSource.watchProfile(user.uid).asyncMap((profile) async {
        await _syncLocalSession(
          profile ?? await _profileDataSource.fetchProfile(user.uid),
          user.uid,
        );
        return AppSession(firebaseUser: user, profile: profile);
      });
    }
  }

  @override
  Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    int? resendToken,
  }) async {
    final normalizedPhone = PhoneUtils.normalize(phone);

    try {
      await _authDataSource.sendOtp(
        phone: normalizedPhone,
        resendToken: resendToken,
        onCodeSent: onCodeSent,
      );

      final user = _authDataSource.currentUser;
      if (user != null) {
        await _bootstrapPhoneVerifiedUser(user);
      }
    } catch (error, stackTrace) {
      _recordError(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = await _authDataSource.verifyOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final user = credential.user;
      if (user == null) {
        throw const AppException('Phone verification did not return a user.');
      }
      await _bootstrapPhoneVerifiedUser(user);
    } catch (error, stackTrace) {
      _recordError(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    try {
      final normalized = identifier.trim().toLowerCase();
      final looksLikeEmail = normalized.contains('@');
      String email = normalized;

      if (!looksLikeEmail) {
        final phone = PhoneUtils.normalize(identifier);
        final profile = await _profileDataSource.findByPhone(phone);
        if (profile == null) {
          throw const AppException(
            'No account was found for this phone number.',
            code: 'missing_account',
          );
        }
        if (!profile.isActive) {
          throw const AppException(
            'This account is disabled. Contact the administrator.',
            code: 'account_disabled',
          );
        }
        if (profile.email.trim().isEmpty) {
          throw const AppException(
            'This account is missing an email login. Sign in with phone verification again to recover access.',
            code: 'missing_email_login',
          );
        }
        email = profile.email.trim().toLowerCase();
      }

      final credential = await _authDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AppException('Authentication did not return a user.');
      }

      final deviceInfo = await _deviceInfoService.currentDeviceInfo();
      final profile = await _profileDataSource.fetchProfile(user.uid);
      if (profile == null) {
        await _authDataSource.signOut();
        throw const AppException(
          'Your account profile is missing. Use phone registration recovery or contact the administrator.',
          code: 'missing_profile',
        );
      }
      if (!profile.isActive) {
        await _authDataSource.signOut();
        throw const AppException(
          'This account is disabled. Contact the administrator.',
          code: 'account_disabled',
        );
      }

      await _profileDataSource.touchLogin(uid: user.uid, deviceInfo: deviceInfo);
      await _syncLocalSession(profile, user.uid);
      await _logSecurityEvent(
        actorId: user.uid,
        actorName: profile.fullName.isEmpty ? 'Partner' : profile.fullName,
        action: 'login',
        metadata: {'route': 'credentials', 'device': deviceInfo.deviceName},
      );
      await _analytics.logLogin(
        loginMethod: looksLikeEmail ? 'email' : 'phone_password',
      );
    } catch (error, stackTrace) {
      _recordError(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> completeProfile({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final user = _authDataSource.currentUser;
    if (user == null) {
      throw const AppException('No authenticated user found.');
    }

    final normalizedEmail = email.trim().toLowerCase();

    try {
      await _authDataSource.linkEmailCredential(
        user: user,
        email: normalizedEmail,
        password: password,
      );
      await _authDataSource.updateDisplayName(user, fullName.trim());
      await _authDataSource.reloadUser(user);

      final deviceInfo = await _deviceInfoService.currentDeviceInfo();
      await _profileDataSource.completeProfile(
        user: user,
        fullName: fullName.trim(),
        email: normalizedEmail,
        deviceInfo: deviceInfo,
      );

      await _secureStorage.writeLastKnownUid(user.uid);
      await _analytics.logSignUp(signUpMethod: 'phone_otp');
      await _logSecurityEvent(
        actorId: user.uid,
        actorName: fullName.trim(),
        action: 'profile_completed',
        metadata: {'email': normalizedEmail},
      );
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
      throw const AppException('No authenticated user found.');
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
        actorName: user.displayName ?? 'Partner',
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
        await _secureStorage.readBool(
          SecureStorageKeys.trustedDeviceEnabled,
        ) ??
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
        actorName: user.displayName ?? user.phoneNumber ?? 'Partner',
        action: 'logout',
      );
      await _analytics.logEvent(name: 'secure_logout');
    }
    await _secureStorage.clearSessionData();
    await _authDataSource.signOut();
  }

  Future<void> _ensurePhoneVerifiedPlaceholder(User user) async {
    final existingProfile = await _profileDataSource.fetchProfile(user.uid);
    final deviceInfo = await _deviceInfoService.currentDeviceInfo();
    await _profileDataSource.ensurePlaceholderProfile(
      user: user,
      deviceInfo: deviceInfo,
    );
    final profile = await _profileDataSource.fetchProfile(user.uid);
    await _syncLocalSession(profile, user.uid);

    final isNewDevice =
        existingProfile?.deviceInfo?.deviceId.isNotEmpty == true &&
        existingProfile!.deviceInfo!.deviceId != deviceInfo.deviceId;
    if (isNewDevice) {
      await _notificationRepository.createSecurityNotification(
        userId: user.uid,
        title: 'New trusted device detected',
        body: 'A sign-in attempt used ${deviceInfo.deviceName}.',
        route: AppRoutes.settings,
      );
    }
  }

  Future<void> _bootstrapPhoneVerifiedUser(User user) async {
    try {
      await _ensurePhoneVerifiedPlaceholder(user);
    } on FirebaseException catch (error) {
      await _authDataSource.signOut();
      throw _mapProfileBootstrapException(error);
    }
  }

  Future<void> _syncLocalSession(AppUser? profile, String uid) async {
    await _secureStorage.markAppOpened();
    await _secureStorage.writeLastKnownUid(uid);
    if (profile == null) return;
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

  void _recordError(Object error, StackTrace stackTrace) {
    _crashlytics.recordError(error, stackTrace, fatal: false);
  }

  AppException _mapProfileBootstrapException(FirebaseException error) {
    final message = error.message ?? '';
    if (error.plugin == 'cloud_firestore' &&
        message.contains('database (default) does not exist')) {
      return const AppException(
        'Phone verification succeeded, but Cloud Firestore is not created for this Firebase project. Create the default Firestore database, then try again.',
        code: 'firestore_not_configured',
      );
    }
    if (error.plugin == 'cloud_firestore' && error.code == 'unavailable') {
      return const AppException(
        'Phone verification succeeded, but the app could not reach Cloud Firestore. Check Firestore setup, App Check, and internet access, then try again.',
        code: 'firestore_unavailable',
      );
    }
    return AppException(
      message.isEmpty ? 'Could not finish account setup.' : message,
      code: error.code,
    );
  }
}

final firebaseAuthRemoteDataSourceProvider =
    Provider<FirebaseAuthRemoteDataSource>((ref) {
      return FirebaseAuthRemoteDataSource(ref.watch(firebaseAuthProvider));
    });

final userProfileRemoteDataSourceProvider =
    Provider<UserProfileRemoteDataSource>((ref) {
      return UserProfileRemoteDataSource(ref.watch(firestoreProvider));
    });

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    ref.watch(firebaseAuthRemoteDataSourceProvider),
    ref.watch(userProfileRemoteDataSourceProvider),
    ref.watch(activityRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
    ref.watch(secureStorageProvider),
    ref.watch(deviceInfoServiceProvider),
    ref.watch(analyticsProvider),
    ref.watch(crashlyticsProvider),
  );
});
