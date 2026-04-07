import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';

abstract class AuthRepository {
  Stream<AppSession?> watchSession();

  Future<AppSession?> restoreSession();

  Future<void> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> completeProfile({
    required String fullName,
    required String email,
    String? password,
  });

  Future<void> saveSecurityPreferences({
    required bool trustedDeviceEnabled,
    required bool biometricEnabled,
    required bool appLockEnabled,
    required int inactivityTimeoutSeconds,
  });

  Future<void> setBiometrics(bool enabled);

  Future<void> signOut();
}
