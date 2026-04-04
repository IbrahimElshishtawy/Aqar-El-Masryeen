import 'dart:async';

import 'package:aqarelmasryeen/core/mock/mock_workspace_store.dart';
import 'package:aqarelmasryeen/core/services/firebase_initializer.dart';
import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:aqarelmasryeen/features/auth/domain/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._auth, this._store);

  final FirebaseAuth _auth;
  final MockWorkspaceStore _store;
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
  Future<void> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _ensureMockSession(fullName: fullName, email: email);
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _ensureMockSession(email: email);
  }

  @override
  Future<void> completeProfile({
    required String fullName,
    required String email,
    String? password,
  }) async {
    await _ensureMockSession(fullName: fullName, email: email);
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
    await _auth.signOut();
    _currentSession = null;
    _controller.add(null);
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await initializeFirebase();
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        _currentSession = null;
        _controller.add(null);
        return;
      }
      _currentSession = AppSession(
        firebaseUser: user,
        profile: _store.profileForUid(user.uid),
      );
      _controller.add(_currentSession);
    });
    await _ensureAnonymousUser();
    await _emitCurrentSession();
  }

  Future<void> _ensureMockSession({String? fullName, String? email}) async {
    await _ensureInitialized();
    final user = await _ensureAnonymousUser();
    _store.updateProfile(uid: user.uid, fullName: fullName, email: email);
    await _emitCurrentSession();
  }

  Future<User> _ensureAnonymousUser() async {
    final current = _auth.currentUser;
    if (current != null) {
      return current;
    }
    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  Future<void> _emitCurrentSession() async {
    final user = _auth.currentUser;
    if (user == null) {
      _currentSession = null;
    } else {
      _currentSession = AppSession(
        firebaseUser: user,
        profile: _store.profileForUid(user.uid),
      );
    }
    _controller.add(_currentSession);
  }
}
