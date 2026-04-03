import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:aqarelmasryeen/core/security/session_lock_controller.dart';
import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecuritySetupController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit({
    required bool trustedDeviceEnabled,
    required bool biometricEnabled,
    required bool appLockEnabled,
    required int inactivityTimeoutSeconds,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (appLockEnabled && !trustedDeviceEnabled) {
        throw const AppException(
          'Trusted-device unlock must be enabled when automatic app lock is enabled.',
        );
      }

      if (trustedDeviceEnabled) {
        final availability = await ref.read(biometricServiceProvider).getAvailability();
        if (!availability.canUseSecureUnlock) {
          throw const AppException(
            'This device does not support secure device authentication.',
          );
        }
        final authenticated = await ref.read(biometricServiceProvider).authenticate(
          reason: 'Confirm secure unlock for this trusted device',
        );
        if (!authenticated) {
          throw const AppException(
            'Device authentication was canceled. Security settings were not saved.',
          );
        }
      }

      await ref.read(authRepositoryProvider).saveSecurityPreferences(
        trustedDeviceEnabled: trustedDeviceEnabled,
        biometricEnabled: biometricEnabled && trustedDeviceEnabled,
        appLockEnabled: appLockEnabled,
        inactivityTimeoutSeconds: inactivityTimeoutSeconds,
      );

      if (trustedDeviceEnabled && appLockEnabled) {
        await ref.read(sessionLockControllerProvider.notifier).unlock();
      }
    });
  }
}

final securitySetupControllerProvider =
    NotifierProvider<SecuritySetupController, AsyncValue<void>>(
      SecuritySetupController.new,
    );
