import 'dart:async';

import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:aqarelmasryeen/core/mock/mock_workspace_store.dart';
import 'package:aqarelmasryeen/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:aqarelmasryeen/features/auth/domain/auth_repository.dart';

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
    _store.updateProfile(fullName: fullName, email: email.trim().toLowerCase());
    await _ensureMockSession();
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail != AppConfig.mockPartnerEmail ||
        password != AppConfig.mockPartnerPassword) {
      throw AppException(
        'استخدم بيانات الموك: ${AppConfig.mockPartnerEmail} / ${AppConfig.mockPartnerPassword}',
        code: 'mock_invalid_credentials',
      );
    }
    _store.updateProfile(email: AppConfig.mockPartnerEmail);
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
    _store.updateProfile(email: AppConfig.mockPartnerEmail);
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
    final profile = _store.profileForUid('mock-user');
    await _localDataSource.cacheProfile(profile);
    _currentSession = AppSession(
      userId: 'mock-user',
      profile: profile,
      email: profile.email,
      displayName: profile.fullName,
      phoneNumber: profile.phone,
      providerIds: const ['password'],
    );
    _controller.add(_currentSession);
  }
}
