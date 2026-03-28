import 'package:aqarelmasryeen/core/theme/app_colors.dart';
import 'package:aqarelmasryeen/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:aqarelmasryeen/modules/dashboard/widgets/finance_sections.dart';
import 'package:aqarelmasryeen/modules/dashboard/widgets/overview_section.dart';
import 'package:aqarelmasryeen/modules/dashboard/widgets/properties_section.dart';
import 'package:aqarelmasryeen/modules/dashboard/widgets/reports_notifications_sections.dart';
import 'package:aqarelmasryeen/modules/dashboard/widgets/units_section.dart';
import 'package:aqarelmasryeen/modules/dashboard/widgets/users_section.dart';
import 'package:aqarelmasryeen/shared/layouts/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final workspace = controller.workspace;
      final destinations = controller.destinations
          .map(
            (item) => ShellDestination(
              label: item.labelKey.tr,
              icon: item.icon,
            ),
          )
          .toList();

      return AppShell(
        destinations: destinations,
        selectedIndex: controller.selectedIndex.value,
        onDestinationSelected: controller.selectSection,
        title: 'dashboard'.tr,
        subtitle: 'premium_workspace'.tr,
        actions: [
          IconButton.filledTonal(
            onPressed: controller.refreshWorkspace,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'refresh'.tr,
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                controller.logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'profile', child: Text('profile'.tr)),
              PopupMenuItem(value: 'settings', child: Text('settings'.tr)),
              PopupMenuItem(value: 'logout', child: Text('logout'.tr)),
            ],
          ),
        ],
        profileMenu: _ProfileMenu(
          roleLabel: workspace.currentRole.value.labelKey.tr,
          unreadNotifications: workspace.notifications
              .where((item) => !item.isRead)
              .length,
        ),
        body: workspace.isReady.value
            ? _SectionBody(selectedIndex: controller.selectedIndex.value)
            : const Center(child: CircularProgressIndicator()),
      );
    });
  }
}

class _SectionBody extends GetView<DashboardController> {
  const _SectionBody({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final body = switch (selectedIndex) {
      0 => const OverviewSection(),
      1 => const UsersSection(),
      2 => const PropertiesSection(),
      3 => const UnitsSection(),
      4 => const SalesSection(),
      5 => const ExpensesSection(),
      6 => const ReportsSection(),
      7 => const NotificationsSection(),
      _ => const OverviewSection(),
    };

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: body,
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({
    required this.roleLabel,
    required this.unreadNotifications,
  });

  final String roleLabel;
  final int unreadNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0x33FFFFFF),
            child: Icon(Icons.person_outline_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'profile'.tr,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  roleLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$unreadNotifications',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
