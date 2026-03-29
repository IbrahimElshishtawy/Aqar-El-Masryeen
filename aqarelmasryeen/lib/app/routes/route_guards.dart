import 'package:aqarelmasryeen/app/routes/app_routes.dart';
import 'package:aqarelmasryeen/core/services/session_service.dart';
import 'package:aqarelmasryeen/data/models/app_role.dart';
import 'package:aqarelmasryeen/data/repositories/auth_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class ProtectedRouteGuard extends GetMiddleware {
  ProtectedRouteGuard({
    this.allowedRoles = const {
      AppRole.owner,
      AppRole.accountant,
      AppRole.employee,
      AppRole.viewer,
    },
  });

  final Set<AppRole> allowedRoles;

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

    final cachedSession = sessionService.cachedSessionSync;
    if (cachedSession != null) {
      final role = AppRole.fromKey(cachedSession.roleKey);
      if (!allowedRoles.contains(role)) {
        return const RouteSettings(name: AppRoutes.login);
      }
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
