import 'package:aqarelmasryeen/app/routes/app_routes.dart';
import 'package:aqarelmasryeen/core/services/session_service.dart';
import 'package:aqarelmasryeen/data/repositories/auth_repository.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  final SessionService _sessionService = Get.find();
  final AuthRepository _authRepository = Get.find();

  @override
  void onReady() {
    super.onReady();
    Future<void>.delayed(const Duration(milliseconds: 1100), _routeNext);
  }

  Future<void> _routeNext() async {
    await _sessionService.initializeLockState();

    final onboardingSeen = await _sessionService.isOnboardingSeen();
    if (!onboardingSeen) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }

    if (_authRepository.isAuthenticated) {
      if (_sessionService.isLockedSync) {
        Get.offAllNamed(AppRoutes.login, arguments: {'unlock': true});
        return;
      }
      Get.offAllNamed(AppRoutes.dashboard);
      return;
    }

    Get.offAllNamed(AppRoutes.login);
  }
}
