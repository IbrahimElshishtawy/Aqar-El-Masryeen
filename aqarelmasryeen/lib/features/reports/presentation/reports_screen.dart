import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/metric_card.dart';
import 'package:aqarelmasryeen/features/collections/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/installments/data/installment_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/sales/data/sales_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
part 'widgets/reports_banner_widgets.dart';
part 'widgets/property_performance_card.dart';

final reportsPropertiesProvider = StreamProvider.autoDispose((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  return ref
      .watch(propertyRepositoryProvider)
      .watchProperties(workspaceId: session?.profile?.workspaceId.trim() ?? '');
});

final reportsExpensesProvider = StreamProvider.autoDispose((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  return ref
      .watch(expenseRepositoryProvider)
      .watchAll(workspaceId: session?.profile?.workspaceId.trim() ?? '');
});

final reportsUnitsProvider = StreamProvider.autoDispose((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  return ref
      .watch(salesRepositoryProvider)
      .watchAll(workspaceId: session?.profile?.workspaceId.trim() ?? '');
});

final reportsPaymentsProvider = StreamProvider.autoDispose((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  return ref
      .watch(paymentRepositoryProvider)
      .watchAll(workspaceId: session?.profile?.workspaceId.trim() ?? '');
});

final reportsInstallmentsProvider = StreamProvider.autoDispose((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  return ref
      .watch(installmentRepositoryProvider)
      .watchAllInstallments(
        workspaceId: session?.profile?.workspaceId.trim() ?? '',
      );
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(reportsPropertiesProvider);
    final expenses = ref.watch(reportsExpensesProvider);
    final units = ref.watch(reportsUnitsProvider);
    final payments = ref.watch(reportsPaymentsProvider);
    final installments = ref.watch(reportsInstallmentsProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (!properties.hasValue ||
        !expenses.hasValue ||
        !units.hasValue ||
        !payments.hasValue ||
        !installments.hasValue) {
      return const AppShellScaffold(
        title: 'التقارير',
        currentIndex: 3,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final propertyItems = properties.value!;
    final propertyCount = propertyItems.length;
    final totalExpenses = expenses.value!.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final totalSales = units.value!.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    final totalCollected = payments.value!.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final overdue = installments.value!.where((item) => item.isOverdue).length;
    final outstanding = totalSales - totalCollected;
    final collectionRate = totalSales <= 0 ? 0.0 : totalCollected / totalSales;
    final expenseRatio = totalSales <= 0 ? 0.0 : totalExpenses / totalSales;
    final planningCount = propertyItems
        .where((item) => item.status == PropertyStatus.planning)
        .length;
    final activeCount = propertyItems
        .where((item) => item.status == PropertyStatus.active)
        .length;
    final deliveredCount = propertyItems
        .where((item) => item.status == PropertyStatus.delivered)
        .length;

    return AppShellScaffold(
      title: 'التقارير',
      currentIndex: 3,
      child: ListView(
        padding: EdgeInsets.all(screenWidth < 640 ? 12 : 16),
        children: [
          _ReportsBanner(
            propertyCount: propertyCount,
            collectionRate: collectionRate,
            totalCollected: totalCollected,
            outstanding: outstanding,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: screenWidth < 520 ? 2 : 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: screenWidth < 520 ? 1.22 : 1.18,
            children: [
              MetricCard(
                label: 'المشروعات',
                value: '$propertyCount',
                icon: Icons.business_outlined,
              ),
              MetricCard(
                label: 'المصروفات',
                value: totalExpenses.egp,
                icon: Icons.money_off_csred_outlined,
                color: Colors.deepOrange,
              ),
              MetricCard(
                label: 'التحصيلات',
                value: totalCollected.egp,
                icon: Icons.payments_outlined,
                color: Colors.green,
              ),
              MetricCard(
                label: 'الأقساط المتأخرة',
                value: '$overdue',
                icon: Icons.warning_amber_outlined,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionHeading(
            title: 'مؤشرات المحفظة',
            subtitle: 'قراءة مركزة للأداء المالي والتشغيلي الحالي.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _ReportRow(label: 'إجمالي المبيعات', value: totalSales.egp),
                  const SizedBox(height: 12),
                  _ReportRow(
                    label: 'إجمالي التحصيلات',
                    value: totalCollected.egp,
                  ),
                  const SizedBox(height: 12),
                  _ReportRow(label: 'صافي المتبقي', value: outstanding.egp),
                  const SizedBox(height: 12),
                  _ReportRow(
                    label: 'نسبة التحصيل',
                    value: _formatPercentage(collectionRate),
                  ),
                  const SizedBox(height: 12),
                  _ReportRow(
                    label: 'نسبة المصروفات إلى المبيعات',
                    value: _formatPercentage(expenseRatio),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatusPill(
                label: 'تحت التخطيط',
                value: '$planningCount',
                color: Colors.indigo,
              ),
              _StatusPill(
                label: 'نشطة',
                value: '$activeCount',
                color: Colors.green,
              ),
              _StatusPill(
                label: 'تم التسليم',
                value: '$deliveredCount',
                color: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionHeading(
            title: 'أداء العقارات',
            subtitle: 'توزيع سريع للمشروعات حسب حالتها والمستهدف البيعي.',
          ),
          const SizedBox(height: 12),
          if (propertyItems.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'لا توجد بيانات كافية لإظهار تقارير العقارات حتى الآن.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          else
            for (final property in propertyItems) ...[
              _PropertyPerformanceCard(
                property: property,
                totalPortfolioTarget: totalSales > 0
                    ? totalSales
                    : propertyItems.fold<double>(
                        0,
                        (sum, item) => sum + item.totalSalesTarget,
                      ),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

String _formatPercentage(double ratio) {
  final percentage = ratio * 100;
  final decimals = percentage == percentage.roundToDouble() ? 0 : 1;
  return '${percentage.toStringAsFixed(decimals)}%';
}
