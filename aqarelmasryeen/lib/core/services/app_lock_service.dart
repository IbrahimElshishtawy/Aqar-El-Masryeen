import 'package:aqarelmasryeen/app/routes/app_routes.dart';
import 'package:aqarelmasryeen/core/services/session_service.dart';
import 'package:aqarelmasryeen/data/repositories/auth_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class AppLockService extends GetxService with WidgetsBindingObserver {
  AppLockService({
    required SessionService sessionService,
    required AuthRepository authRepository,
  })  : _sessionService = sessionService,
        _authRepository = authRepository;

  final SessionService _sessionService;
  final AuthRepository _authRepository;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _sessionService.initializeLockState();
    WidgetsBinding.instance.addObserver(this);
    _initialized = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_authRepository.isAuthenticated) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _lockIfEnabled();
      return;
    }

    if (state == AppLifecycleState.resumed && _sessionService.isLockedSync) {
      Get.offAllNamed(AppRoutes.login, arguments: {'unlock': true});
    }
  }

  Future<void> _lockIfEnabled() async {
    final lockEnabled = await _sessionService.isAppLockEnabled();
    if (!lockEnabled) {
      return;
    }
    await _sessionService.lockApp();
  }
}
