import 'package:aqarelmasryeen/core/theme/app_colors.dart';
import 'package:aqarelmasryeen/core/theme/app_spacing.dart';
import 'package:aqarelmasryeen/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:aqarelmasryeen/shared/layouts/app_shell.dart';
import 'package:aqarelmasryeen/shared/widgets/app_button.dart';
import 'package:aqarelmasryeen/shared/widgets/app_card.dart';
import 'package:aqarelmasryeen/shared/widgets/kpi_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final destinations = [
      ShellDestination(label: 'dashboard'.tr, icon: Icons.grid_view_rounded),
      ShellDestination(label: 'workers'.tr, icon: Icons.groups_rounded),
      ShellDestination(label: 'properties'.tr, icon: Icons.apartment_rounded),
      ShellDestination(label: 'units'.tr, icon: Icons.meeting_room_rounded),
      ShellDestination(label: 'sales'.tr, icon: Icons.sell_rounded),
      ShellDestination(label: 'expenses'.tr, icon: Icons.receipt_long_rounded),
      ShellDestination(label: 'reports'.tr, icon: Icons.insert_chart_outlined_rounded),
      ShellDestination(label: 'notifications'.tr, icon: Icons.notifications_active_rounded),
    ];

    return Obx(
      () => AppShell(
        destinations: destinations,
        selectedIndex: controller.selectedIndex.value,
        onDestinationSelected: controller.selectSection,
        title: 'dashboard'.tr,
        subtitle: 'premium_workspace'.tr,
        actions: [
          SizedBox(
            width: 148,
            child: AppButton(
              label: 'add_worker'.tr,
              variant: AppButtonVariant.secondary,
              onPressed: () => controller.selectSection(1),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 148,
            child: AppButton(
              label: 'add_property'.tr,
              onPressed: () => controller.selectSection(2),
            ),
          ),
        ],
        profileMenu: _ProfileMenu(onLogout: controller.logout),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  for (final metric in controller.metrics)
                    SizedBox(
                      width: 250,
                      child: KpiCard(
                        title: metric.titleKey.tr,
                        value: metric.value,
                        caption: metric.caption,
                        icon: _iconFromName(metric.iconName),
                        tint: _tintForMetric(metric.iconName),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'latest_activity'.tr,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 18),
                          ...controller.activities.map(
                            (activity) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      activity,
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 2,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'recent_notifications'.tr,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 18),
                          const _NotificationTile(
                            title: 'Installment due tomorrow',
                            body: 'Unit B-17 • Palm View Residence',
                          ),
                          const SizedBox(height: 12),
                          const _NotificationTile(
                            title: 'New expense added',
                            body: 'Labor category • EGP 74,000',
                          ),
                          const SizedBox(height: 12),
                          const _NotificationTile(
                            title: 'Collection risk detected',
                            body: '4 overdue contracts in East Gate Plaza',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'properties'.tr,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  for (final property in controller.propertyCards)
                    SizedBox(
                      width: 360,
                      child: _PropertyCard(property: property),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.onLogout});

  final VoidCallback onLogout;

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
            child: Text(
              'profile'.tr,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          PopupMenuButton<String>(
            color: Colors.white,
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                onLogout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'settings', child: Text('settings'.tr)),
              PopupMenuItem(value: 'profile', child: Text('profile'.tr)),
              PopupMenuItem(value: 'logout', child: Text('logout'.tr)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.notifications_active_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});

  final PropertyPreview property;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${property.code} • ${property.location}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  property.status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: property.progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: AppColors.surfaceMuted,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 18,
            runSpacing: 14,
            children: [
              _MetricItem(label: 'Units', value: '${property.unitCount}'),
              _MetricItem(label: 'Sold', value: '${property.soldUnits}'),
              _MetricItem(label: 'Available', value: '${property.availableUnits}'),
              _MetricItem(label: 'Sales', value: property.totalSales),
              _MetricItem(label: 'Expenses', value: property.totalExpenses),
              _MetricItem(label: 'Receivables', value: property.remainingReceivables),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

IconData _iconFromName(String name) {
  switch (name) {
    case 'domain':
      return Icons.domain_rounded;
    case 'payments':
      return Icons.payments_rounded;
    case 'receipt_long':
      return Icons.receipt_long_rounded;
    case 'account_balance_wallet':
      return Icons.account_balance_wallet_rounded;
    case 'notification_important':
      return Icons.notification_important_rounded;
    default:
      return Icons.bar_chart_rounded;
  }
}

Color _tintForMetric(String name) {
  switch (name) {
    case 'payments':
      return AppColors.success;
    case 'receipt_long':
      return AppColors.warning;
    case 'notification_important':
      return AppColors.danger;
    case 'account_balance_wallet':
      return AppColors.accent;
    default:
      return AppColors.primary;
  }
}
