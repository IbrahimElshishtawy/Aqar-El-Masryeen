import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/metric_card.dart';
import 'package:aqarelmasryeen/features/collections/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/installments/data/installment_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/sales/data/sales_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportsPropertiesProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(propertyRepositoryProvider).watchProperties(),
);

final reportsExpensesProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(expenseRepositoryProvider).watchAll(),
);

final reportsUnitsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(salesRepositoryProvider).watchAll(),
);

final reportsPaymentsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(paymentRepositoryProvider).watchAll(),
);

final reportsInstallmentsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(installmentRepositoryProvider).watchAllInstallments(),
);

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

class _ReportsBanner extends StatelessWidget {
  const _ReportsBanner({
    required this.propertyCount,
    required this.collectionRate,
    required this.totalCollected,
    required this.outstanding,
  });

  final int propertyCount;
  final double collectionRate;
  final double totalCollected;
  final double outstanding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, const Color(0xFF0F766E)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
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
                        'لوحة التقارير',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'اعرض الأداء العام للمشروعات والتحصيلات والمبالغ المتبقية بسرعة.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  child: const Icon(
                    Icons.assessment_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _BannerPill(label: 'عدد المشروعات', value: '$propertyCount'),
                _BannerPill(
                  label: 'نسبة التحصيل',
                  value: _formatPercentage(collectionRate),
                ),
                _BannerPill(label: 'إجمالي المحصل', value: totalCollected.egp),
                _BannerPill(label: 'المتبقي', value: outstanding.egp),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyPerformanceCard extends StatelessWidget {
  const _PropertyPerformanceCard({
    required this.property,
    required this.totalPortfolioTarget,
  });

  final PropertyProject property;
  final double totalPortfolioTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(property.status);
    final progress = totalPortfolioTarget <= 0
        ? 0.0
        : (property.totalSalesTarget / totalPortfolioTarget).clamp(0, 1);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        property.location,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusPill(
                  label: 'الحالة',
                  value: property.status.label,
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ReportRow(
              label: 'المستهدف البيعي',
              value: property.totalSalesTarget.egp,
            ),
            const SizedBox(height: 12),
            _ReportRow(
              label: 'موازنة المشروع',
              value: property.totalBudget.egp,
            ),
            const SizedBox(height: 14),
            Text(
              'وزن المشروع داخل المحفظة',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.toDouble(),
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: statusColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.planning:
        return Colors.indigo;
      case PropertyStatus.active:
        return Colors.green;
      case PropertyStatus.delivered:
        return Colors.teal;
      case PropertyStatus.archived:
        return Colors.orange;
    }
  }
}

class _BannerPill extends StatelessWidget {
  const _BannerPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatPercentage(double ratio) {
  final percentage = ratio * 100;
  final decimals = percentage == percentage.roundToDouble() ? 0 : 1;
  return '${percentage.toStringAsFixed(decimals)}%';
}
