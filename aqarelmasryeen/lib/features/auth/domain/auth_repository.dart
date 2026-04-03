import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';

abstract class AuthRepository {
  Stream<AppSession?> watchSession();

  Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    int? resendToken,
  });

  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  Future<void> signInWithIdentifier({
    required String identifier,
    required String password,
  });

  Future<void> completeProfile({
    required String fullName,
    required String email,
    required String password,
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
