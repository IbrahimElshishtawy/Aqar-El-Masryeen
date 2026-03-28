import 'package:aqarelmasryeen/core/responsive/app_breakpoints.dart';
import 'package:aqarelmasryeen/core/theme/app_colors.dart';
import 'package:aqarelmasryeen/core/theme/app_spacing.dart';
import 'package:aqarelmasryeen/data/repositories/workspace_repository.dart';
import 'package:aqarelmasryeen/modules/dashboard/widgets/workspace_ui.dart';
import 'package:aqarelmasryeen/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OverviewSection extends StatelessWidget {
  const OverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = Get.find<WorkspaceRepository>();
    final summaries = workspace.propertySummaries;

    return SectionScaffold(
      title: 'dashboard'.tr,
      subtitle: 'dashboard_overview_subtitle'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 250,
                child: SummaryStatCard(
                  title: 'total_properties'.tr,
                  value: '${workspace.properties.length}',
                  caption: 'dashboard_properties_caption'.tr,
                  icon: Icons.domain_rounded,
                ),
              ),
              SizedBox(
                width: 250,
                child: SummaryStatCard(
                  title: 'total_sales'.tr,
                  value: formatCurrency(workspace.totalSalesValue),
                  caption: '${workspace.activeContractsCount} ${'active_contracts'.tr}',
                  icon: Icons.payments_rounded,
                  color: AppColors.success,
                ),
              ),
              SizedBox(
                width: 250,
                child: SummaryStatCard(
                  title: 'total_expenses'.tr,
                  value: formatCurrency(workspace.totalExpensesValue),
                  caption: '${workspace.expenses.length} ${'expense_records'.tr}',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.warning,
                ),
              ),
              SizedBox(
                width: 250,
                child: SummaryStatCard(
                  title: 'remaining_receivables'.tr,
                  value: formatCurrency(workspace.totalReceivablesValue),
                  caption: '${workspace.overdueInstallmentsCount} ${'overdue_installments'.tr}',
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: context.isDesktop ? 680 : double.infinity,
                child: _ActivityCard(items: workspace.recentActivity),
              ),
              SizedBox(
                width: context.isDesktop ? 420 : double.infinity,
                child: _NotificationsCard(items: workspace.recentNotifications),
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final summary in summaries)
                SizedBox(
                  width: context.isDesktop ? 360 : double.infinity,
                  child: _PropertyCard(summary: summary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.items});

  final List<ActivityLogRecord> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'latest_activity'.tr,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text('empty_activity'.tr)
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(item.description),
                          const SizedBox(height: 4),
                          Text(
                            formatDate(item.createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard({required this.items});

  final List<AppNotificationRecord> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'recent_notifications'.tr,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text('empty_notifications'.tr)
          else
            ...items.take(4).map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.isRead ? AppColors.surfaceMuted : AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(item.body),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.summary});

  final PropertyOverviewSummary summary;

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
                      summary.property.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.property.code} • ${summary.property.location}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(summary.property.status.labelKey.tr),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: summary.progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: AppColors.surfaceMuted,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 14,
            children: [
              _Metric(label: 'units'.tr, value: '${summary.totalUnits}'),
              _Metric(label: 'sold'.tr, value: '${summary.soldUnits}'),
              _Metric(label: 'available'.tr, value: '${summary.availableUnits}'),
              _Metric(label: 'reserved'.tr, value: '${summary.reservedUnits}'),
              _Metric(label: 'total_sales'.tr, value: formatCurrency(summary.totalSales)),
              _Metric(
                label: 'total_expenses'.tr,
                value: formatCurrency(summary.totalExpenses),
              ),
              _Metric(
                label: 'remaining_receivables'.tr,
                value: formatCurrency(summary.remainingReceivables),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

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
