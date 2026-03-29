import 'dart:async';

import 'package:aqarelmasryeen/app/routes/app_routes.dart';
import 'package:aqarelmasryeen/core/services/auth_service.dart';
import 'package:aqarelmasryeen/core/services/session_service.dart';
import 'package:aqarelmasryeen/data/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  final SessionService _sessionService = Get.find();
  final AuthRepository _authRepository = Get.find();
  final AuthService _authService = Get.find();
  Timer? _routeTimer;
  bool _hasNavigated = false;

  @override
  void onReady() {
    super.onReady();
    _routeTimer = Timer(const Duration(milliseconds: 1100), () {
      unawaited(_routeNextSafely());
    });
  }

  @override
  void onClose() {
    _routeTimer?.cancel();
    super.onClose();
  }

  Future<void> _routeNextSafely() async {
    try {
      await _sessionService.initializeLockState().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint(
            'SplashController: initializeLockState timed out. Continuing.',
          );
        },
      );

      final onboardingSeen = await _sessionService.isOnboardingSeen().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint(
            'SplashController: onboarding check timed out. Falling back to onboarding.',
          );
          return false;
        },
      );

      if (!onboardingSeen) {
        _navigate(AppRoutes.onboarding);
        return;
      }

      final pendingVerification = await _authService.readPendingChallenge().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint(
            'SplashController: pending verification lookup timed out. Ignoring pending phone auth state.',
          );
          return null;
        },
      );

      if (pendingVerification != null) {
        final route = await _resolvePendingVerificationRoute(
          pendingVerification,
        );
        if (route != null) {
          if (route == AppRoutes.dashboard) {
            await _authService.clearPendingChallenge();
          }
          _navigate(route);
          return;
        }
      }

      if (_authRepository.isAuthenticated) {
        if (_sessionService.isLockedSync) {
          _navigate(AppRoutes.login, arguments: {'unlock': true});
          return;
        }

        _navigate(AppRoutes.dashboard);
        return;
      }

      _navigate(AppRoutes.login);
    } catch (error, stackTrace) {
      debugPrint('SplashController routing failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _navigate(AppRoutes.login);
    }
  }

  void _navigate(String route, {Object? arguments}) {
    if (_hasNavigated || isClosed) {
      return;
    }

    _hasNavigated = true;
    Get.offAllNamed(route, arguments: arguments);
  }

  Future<String?> _resolvePendingVerificationRoute(
    dynamic pendingVerification,
  ) async {
    if (!_authRepository.isAuthenticated) {
      return AppRoutes.otp;
    }

    final profile = await _authRepository.getCurrentProfile().timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        debugPrint(
          'SplashController: current profile lookup timed out while restoring phone auth flow.',
        );
        return null;
      },
    );

    return profile == null ? AppRoutes.otp : AppRoutes.dashboard;
  }
}
