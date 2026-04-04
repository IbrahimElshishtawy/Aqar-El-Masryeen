import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/secure_storage_keys.dart';
import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/services/device_info_service.dart';
import 'package:aqarelmasryeen/core/services/secure_storage_service.dart';
import 'package:aqarelmasryeen/features/auth/data/datasources/firebase_auth_remote_data_source.dart';
import 'package:aqarelmasryeen/features/auth/data/datasources/user_profile_remote_data_source.dart';
import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:aqarelmasryeen/features/auth/domain/auth_repository.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/models/app_user.dart';
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

      yield* _profileDataSource.watchProfile(user.uid).asyncMap((
        profile,
      ) async {
        final resolvedProfile =
            profile ?? await _profileDataSource.fetchProfile(user.uid);
        await _syncLocalSession(resolvedProfile, user.uid);
        return AppSession(firebaseUser: user, profile: resolvedProfile);
      });
    }
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
        throw const AppException('لم يتم إرجاع مستخدم بعد إنشاء الحساب.');
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
      final profile = await _profileDataSource.fetchProfile(user.uid);
      if (profile != null && !profile.isActive) {
        await _authDataSource.signOut();
        throw const AppException(
          'هذا الحساب معطل. تواصل مع المسؤول.',
          code: 'account_disabled',
        );
      }

      if (profile != null) {
        final previousDeviceId = profile.deviceInfo?.deviceId ?? '';
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
            title: 'تم اكتشاف جهاز موثوق جديد',
            body: 'تم استخدام ${deviceInfo.deviceName} لتسجيل الدخول.',
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

  @override
  Future<void> completeProfile({
    required String fullName,
    required String email,
    String? password,
  }) async {
    final user = _authDataSource.currentUser;
    if (user == null) {
      throw const AppException('لا يوجد مستخدم مسجل حاليًا.');
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
            'أنشئ كلمة مرور لإكمال ترحيل هذا الحساب.',
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
          'استخدم البريد الإلكتروني الحالي لإكمال الملف الشخصي.',
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
      throw const AppException('لا يوجد مستخدم مسجل حاليًا.');
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
        actorName: user.displayName ?? user.email ?? 'شريك',
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
        actorName: user.displayName ?? user.email ?? 'شريك',
        action: 'logout',
      );
      await _analytics.logEvent(name: 'secure_logout');
    }
    await _secureStorage.clearSessionData();
    await _authDataSource.signOut();
  }

  Future<void> _syncLocalSession(AppUser? profile, String uid) async {
    await _secureStorage.markAppOpened();
    await _secureStorage.writeLastKnownUid(uid);
    if (profile == null) {
      await _secureStorage.clearSessionData();
      return;
    }
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
