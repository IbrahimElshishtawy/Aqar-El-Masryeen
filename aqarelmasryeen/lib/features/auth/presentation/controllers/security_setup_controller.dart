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
          'يجب تفعيل الفتح للجهاز الموثوق عند تفعيل القفل التلقائي للتطبيق.',
        );
      }

      if (trustedDeviceEnabled) {
        final availability = await ref
            .read(biometricServiceProvider)
            .getAvailability();
        if (!availability.canUseSecureUnlock) {
          throw const AppException('هذا الجهاز لا يدعم التحقق الآمن.');
        }
        final authenticated = await ref
            .read(biometricServiceProvider)
            .authenticate(reason: 'أكد الفتح الآمن لهذا الجهاز الموثوق');
        if (!authenticated) {
          throw const AppException(
            'تم إلغاء التحقق من الجهاز. لم يتم حفظ إعدادات الأمان.',
          );
        }
      }

      await ref
          .read(authRepositoryProvider)
          .saveSecurityPreferences(
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
