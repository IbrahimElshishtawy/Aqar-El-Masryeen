import 'package:aqarelmasryeen/core/bootstrap/app_bootstrap.dart';
import 'package:aqarelmasryeen/core/localization/locale_service.dart';
import 'package:aqarelmasryeen/core/services/app_lock_service.dart';
import 'package:aqarelmasryeen/core/services/biometric_service.dart';
import 'package:aqarelmasryeen/core/services/local_cache_service.dart';
import 'package:aqarelmasryeen/core/services/notification_service.dart';
import 'package:aqarelmasryeen/core/services/secure_storage_service.dart';
import 'package:aqarelmasryeen/core/services/session_service.dart';
import 'package:aqarelmasryeen/data/repositories/auth_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class InitialBinding extends Bindings {
  InitialBinding(this.bootstrap);

  final BootstrapState bootstrap;

  @override
  void dependencies() {
    Get.put<BootstrapState>(bootstrap, permanent: true);

    Get.put(SecureStorageService(), permanent: true);
    Get.put(LocalCacheService(), permanent: true);
    Get.put(LocaleService(Get.find()), permanent: true);
    Get.put(SessionService(Get.find(), Get.find()), permanent: true);
    Get.put(BiometricService(), permanent: true);
    Get.put(
      AuthRepository(bootstrapState: Get.find(), sessionService: Get.find()),
      permanent: true,
    );
    Get.put(NotificationService(bootstrapState: Get.find()), permanent: true);
    Get.put(
      AppLockService(sessionService: Get.find(), authRepository: Get.find()),
      permanent: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<LocalCacheService>().initialize();
      Get.find<LocaleService>().loadSavedLocale();
      Get.find<NotificationService>().initialize();
      Get.find<AppLockService>().initialize();
    });
  }
}
