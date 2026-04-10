import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:aqarelmasryeen/shared/models/app_user.dart';

abstract class AuthRepository {
  Stream<AppSession?> watchSession();

  Future<AppSession?> restoreSession();

  Future<void> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  });

  Future<AppUser> provisionPartnerAccount({
    required String fullName,
    required String email,
    required String password,
    String? createdBy,
    String? createdByName,
    String? workspaceId,
  });

  Future<Map<String, int>> backfillAuthProfiles({String? workspaceId});

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
