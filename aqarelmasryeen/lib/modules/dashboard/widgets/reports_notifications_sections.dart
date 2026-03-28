import 'package:aqarelmasryeen/core/responsive/app_breakpoints.dart';
import 'package:aqarelmasryeen/core/theme/app_colors.dart';
import 'package:aqarelmasryeen/core/theme/app_spacing.dart';
import 'package:aqarelmasryeen/data/repositories/workspace_repository.dart';
import 'package:aqarelmasryeen/modules/dashboard/widgets/workspace_ui.dart';
import 'package:aqarelmasryeen/shared/widgets/app_button.dart';
import 'package:aqarelmasryeen/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReportsSection extends StatelessWidget {
  const ReportsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = Get.find<WorkspaceRepository>();
    final selectedCustomer = workspace.customers.isEmpty ? null : workspace.customers.first;
    final statement = selectedCustomer == null
        ? const <CustomerStatementLine>[]
        : workspace.statementForCustomer(selectedCustomer.id);

    return SectionScaffold(
      title: 'reports'.tr,
      subtitle: 'reports_subtitle'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 280,
                child: SummaryStatCard(
                  title: 'property_financial_summary'.tr,
                  value: '${workspace.propertySummaries.length}',
                  caption: 'dashboard_properties_caption'.tr,
                  icon: Icons.domain_rounded,
                ),
              ),
              SizedBox(
                width: 280,
                child: SummaryStatCard(
                  title: 'sales_summary'.tr,
                  value: formatCurrency(workspace.totalSalesValue),
                  caption: '${workspace.activeContractsCount} ${'active_contracts'.tr}',
                  icon: Icons.sell_rounded,
                  color: AppColors.success,
                ),
              ),
              SizedBox(
                width: 280,
                child: SummaryStatCard(
                  title: 'overdue_installments'.tr,
                  value: '${workspace.overdueInstallmentsCount}',
                  caption: formatCurrency(
                    workspace.overdueInstallments().fold<double>(
                      0,
                      (sum, item) => sum + item.remainingAmount,
                    ),
                  ),
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
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
                width: context.isDesktop ? 420 : double.infinity,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'totals_by_user'.tr,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...workspace.expenseTotalsByUser.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(child: Text(item.key)),
                              Text(formatCurrency(item.total)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: context.isDesktop ? 420 : double.infinity,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'totals_by_category'.tr,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...workspace.expenseTotalsByCategory.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(child: Text(item.key.tr)),
                              Text(formatCurrency(item.total)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'overdue_installments'.tr,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                if (workspace.overdueInstallments().isEmpty)
                  Text('no_overdue_installments'.tr)
                else
                  ...workspace.overdueInstallments().map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${workspace.customerNameById(workspace.contractById(item.saleContractId)?.customerId ?? '')} • ${formatDate(item.dueDate)}',
                            ),
                          ),
                          Text(
                            formatCurrency(item.remainingAmount),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'customer_statement'.tr,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (selectedCustomer != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    selectedCustomer.fullName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...statement.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${line.title} • ${formatDate(line.date)}'),
                          ),
                          Text(
                            formatCurrency(line.amount),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: line.amount < 0 ? AppColors.success : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsSection extends StatelessWidget {
  const NotificationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = Get.find<WorkspaceRepository>();

    return SectionScaffold(
      title: 'notifications'.tr,
      subtitle: 'notifications_subtitle'.tr,
      action: SizedBox(
        width: 180,
        child: AppButton(
          label: 'mark_all_read'.tr,
          variant: AppButtonVariant.secondary,
          onPressed: workspace.markAllNotificationsRead,
        ),
      ),
      child: Column(
        children: workspace.notifications
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: item.isRead ? AppColors.border : AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(item.body),
                            const SizedBox(height: 6),
                            Text(
                              '${item.category.labelKey.tr} • ${formatDate(item.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!item.isRead)
                        TextButton(
                          onPressed: () => workspace.markNotificationRead(item.id),
                          child: Text('mark_read'.tr),
                        ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
