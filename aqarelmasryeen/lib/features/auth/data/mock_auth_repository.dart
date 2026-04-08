import 'dart:async';

import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:aqarelmasryeen/core/mock/mock_workspace_store.dart';
import 'package:aqarelmasryeen/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:aqarelmasryeen/features/auth/domain/auth_repository.dart';
import 'package:aqarelmasryeen/shared/models/app_user.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._store, this._localDataSource);

  final MockWorkspaceStore _store;
  final AuthLocalDataSource _localDataSource;
  final StreamController<AppSession?> _controller =
      StreamController<AppSession?>.broadcast();

  bool _initialized = false;
  AppSession? _currentSession;

  @override
  Stream<AppSession?> watchSession() async* {
    await _ensureInitialized();
    yield _currentSession;
    yield* _controller.stream;
  }

  @override
  Future<AppSession?> restoreSession() async {
    await _ensureInitialized();
    return _currentSession;
  }

  @override
  Future<void> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final existingProfile = _store.profileByEmail(email);
    if (existingProfile != null) {
      throw const AppException(
        'يوجد حساب مسجل بالفعل بهذا البريد الإلكتروني.',
        code: 'email_already_exists',
      );
    }

    final profile = _store.createPartnerProfile(
      fullName: fullName,
      email: email,
      password: password,
    );
    _store.setActiveProfile(profile.uid);
    await _ensureMockSession();
  }

  @override
  Future<AppUser> provisionPartnerAccount({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final existingProfile = _store.profileByEmail(email);
    if (existingProfile != null) {
      throw const AppException(
        'يوجد حساب مسجل بالفعل بهذا البريد الإلكتروني.',
        code: 'email_already_exists',
      );
    }

    return _store.createPartnerProfile(
      fullName: fullName,
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final profile = _store.profileByEmail(normalizedEmail);
    if (profile == null ||
        !_store.validateCredentials(normalizedEmail, password)) {
      throw const AppException(
        'بيانات الدخول غير صحيحة في وضع الاختبار.',
        code: 'mock_invalid_credentials',
      );
    }

    _store.setActiveProfile(profile.uid);
    await _ensureMockSession();
  }

  @override
  Future<void> completeProfile({
    required String fullName,
    required String email,
    String? password,
  }) async {
    _store.updateProfile(fullName: fullName, email: email.trim().toLowerCase());
    await _ensureMockSession();
  }

  @override
  Future<void> saveSecurityPreferences({
    required bool trustedDeviceEnabled,
    required bool biometricEnabled,
    required bool appLockEnabled,
    required int inactivityTimeoutSeconds,
  }) async {
    await _ensureInitialized();
    _store.updateProfile(
      trustedDeviceEnabled: trustedDeviceEnabled,
      biometricEnabled: biometricEnabled,
      appLockEnabled: appLockEnabled,
      inactivityTimeoutSeconds: inactivityTimeoutSeconds,
    );
    await _emitCurrentSession();
  }

  @override
  Future<void> setBiometrics(bool enabled) async {
    await _ensureInitialized();
    _store.updateProfile(biometricEnabled: enabled);
    await _emitCurrentSession();
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    _currentSession = null;
    await _localDataSource.writeMockSessionActive(false);
    _controller.add(null);
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    final isSignedIn = await _localDataSource.readMockSessionActive();
    if (isSignedIn) {
      await _emitCurrentSession();
      return;
    }
    _currentSession = null;
  }

  Future<void> _ensureMockSession() async {
    await _ensureInitialized();
    await _localDataSource.writeMockSessionActive(true);
    await _emitCurrentSession();
  }

  Future<void> _emitCurrentSession() async {
    final profile = _store.activeProfile;
    await _localDataSource.cacheProfile(profile);
    _currentSession = AppSession(
      userId: profile.uid,
      profile: profile,
      email: profile.email,
      displayName: profile.fullName,
      phoneNumber: profile.phone,
      providerIds: const ['password'],
    );
    _controller.add(_currentSession);
  }
}
