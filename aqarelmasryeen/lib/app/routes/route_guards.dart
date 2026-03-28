import 'package:aqarelmasryeen/app/routes/app_routes.dart';
import 'package:aqarelmasryeen/core/services/session_service.dart';
import 'package:aqarelmasryeen/data/repositories/auth_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class ProtectedRouteGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authRepository = Get.find<AuthRepository>();
    final sessionService = Get.find<SessionService>();

    if (!authRepository.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }

    if (sessionService.isLockedSync) {
      return const RouteSettings(
        name: AppRoutes.login,
        arguments: {'unlock': true},
      );
    }

    return null;
  }
}

class GuestOnlyGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authRepository = Get.find<AuthRepository>();
    final sessionService = Get.find<SessionService>();

    if (authRepository.isAuthenticated && !sessionService.isLockedSync) {
      return const RouteSettings(name: AppRoutes.dashboard);
    }

    return null;
  }
}
