import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';

abstract class AuthRepository {
  Stream<AppSession?> watchSession();

  Stream<bool> authStateChanges();

  Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId, int? resendToken) onCodeSent,
  });

  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> completeProfile({
    required String name,
    required String email,
    required String password,
  });

  Future<void> setBiometrics(bool enabled);

  Future<bool> biometricsEnabled();

  Future<void> signOut();
}
