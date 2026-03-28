import 'dart:async';

import 'package:aqarelmasryeen/app/routes/app_routes.dart';
import 'package:aqarelmasryeen/core/services/app_lock_service.dart';
import 'package:aqarelmasryeen/core/services/notification_service.dart';
import 'package:aqarelmasryeen/core/services/session_service.dart';
import 'package:aqarelmasryeen/data/repositories/auth_repository.dart';
import 'package:aqarelmasryeen/data/repositories/workspace_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  DashboardController();

  final AuthRepository _authRepository = Get.find();
  final SessionService _sessionService = Get.find();
  final WorkspaceRepository workspace = Get.find();

  final selectedIndex = 0.obs;

  final destinations = const [
    DashboardDestination('dashboard', Icons.grid_view_rounded, 'dashboard'),
    DashboardDestination('workers', Icons.groups_rounded, 'workers'),
    DashboardDestination('properties', Icons.apartment_rounded, 'properties'),
    DashboardDestination('units', Icons.meeting_room_rounded, 'units'),
    DashboardDestination('sales', Icons.sell_rounded, 'sales'),
    DashboardDestination('expenses', Icons.receipt_long_rounded, 'expenses'),
    DashboardDestination('reports', Icons.insert_chart_outlined_rounded, 'reports'),
    DashboardDestination(
      'notifications',
      Icons.notifications_active_rounded,
      'notifications',
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _applyRouteArguments(Get.arguments);
    unawaited(Get.find<AppLockService>().initialize());
    unawaited(Get.find<NotificationService>().initialize());
    unawaited(workspace.initialize());
  }

  Future<void> refreshWorkspace() async {
    await workspace.initialize();
    update();
  }

  void selectSection(int index) {
    selectedIndex.value = index;
  }

  void openSectionByKey(String key) {
    final index = destinations.indexWhere((item) => item.sectionKey == key);
    if (index >= 0) {
      selectedIndex.value = index;
    }
  }

  Future<void> logout() async {
    await _authRepository.signOut();
    await _sessionService.clearSession();
    Get.offAllNamed(AppRoutes.login);
  }

  void _applyRouteArguments(dynamic arguments) {
    if (arguments is Map<String, dynamic>) {
      final section = arguments['section'] as String?;
      if (section != null) {
        openSectionByKey(section);
      }
    }
  }
}

class DashboardDestination {
  const DashboardDestination(this.labelKey, this.icon, this.sectionKey);

  final String labelKey;
  final IconData icon;
  final String sectionKey;
}
