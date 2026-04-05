import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/summary_card.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/properties/domain/property_financial_summary.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final propertiesStreamProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(propertyRepositoryProvider).watchProperties(),
);
final propertyExpensesStreamProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(expenseRepositoryProvider).watchAll(),
);
final propertyPaymentsStreamProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(paymentRepositoryProvider).watchAll(),
);

class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesStreamProvider);
    final expensesAsync = ref.watch(propertyExpensesStreamProvider);
    final paymentsAsync = ref.watch(propertyPaymentsStreamProvider);

    if (propertiesAsync.hasError ||
        expensesAsync.hasError ||
        paymentsAsync.hasError) {
      return AppShellScaffold(
        title: 'المشروعات',
        subtitle: 'ملخص الأداء المالي لكل مشروع',
        currentIndex: 1,
        actions: [
          IconButton(
            tooltip: 'إضافة مشروع',
            onPressed: () => context.push('${AppRoutes.properties}/new'),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
        child: EmptyStateView(
          title: 'تعذر تحميل المشروعات',
          message:
              propertiesAsync.error?.toString() ??
              expensesAsync.error?.toString() ??
              paymentsAsync.error?.toString() ??
              'حدث خطأ غير متوقع',
        ),
      );
    }

    if (!propertiesAsync.hasValue ||
        !expensesAsync.hasValue ||
        !paymentsAsync.hasValue) {
      return const AppShellScaffold(
        title: 'المشروعات',
        subtitle: 'ملخص الأداء المالي لكل مشروع',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final summaries = const PropertyFinancialSummaryBuilder().build(
      properties: propertiesAsync.value!,
      expenses: expensesAsync.value!,
      payments: paymentsAsync.value!,
    );
    final totalExpenses = summaries.fold<double>(
      0,
      (sum, summary) => sum + summary.totalExpenses,
    );
    final totalPayments = summaries.fold<double>(
      0,
      (sum, summary) => sum + summary.totalPayments,
    );

    return AppShellScaffold(
      title: 'المشروعات',
      subtitle: 'ملخص الأداء المالي لكل مشروع',
      currentIndex: 1,
      actions: [
        IconButton(
          tooltip: 'إضافة مشروع',
          onPressed: () => context.push('${AppRoutes.properties}/new'),
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                SummaryCard(
                  label: 'المشروعات',
                  value: '${summaries.length}',
                  subtitle: 'المشروعات النشطة داخل المحفظة',
                  icon: Icons.apartment_rounded,
                  emphasis: true,
                ),
                Row(
                  children: [
                    SummaryCard(
                      label: 'المصروفات',
                      value: totalExpenses.egp,
                      subtitle: 'إجمالي مصروفات المشروعات',
                      icon: Icons.north_east_rounded,
                    ),
                    SummaryCard(
                      label: 'التحصيلات',
                      value: totalPayments.egp,
                      subtitle: 'إجمالي تحصيلات المشروعات',
                      icon: Icons.south_west_rounded,
                    ),
                  ],
                ),
              ];

              if (constraints.maxWidth < 680) {
                return Column(
                  children: [
                    for (var index = 0; index < cards.length; index++) ...[
                      cards[index],
                      if (index != cards.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                );
              }

              return GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: cards,
              );
            },
          ),
          const SizedBox(height: 12),
          if (summaries.isEmpty)
            const EmptyStateView(
              title: 'لا توجد مشروعات بعد',
              message:
                  'ستظهر المشروعات هنا بعد إضافة البيانات إلى مساحة العمل.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 900) {
                  return Column(
                    children: [
                      for (
                        var index = 0;
                        index < summaries.length;
                        index++
                      ) ...[
                        _PropertySummaryCard(summary: summaries[index]),
                        if (index != summaries.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  );
                }

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: summaries.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.18,
                  ),
                  itemBuilder: (context, index) =>
                      _PropertySummaryCard(summary: summaries[index]),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PropertySummaryCard extends StatelessWidget {
  const _PropertySummaryCard({required this.summary});

  final PropertyFinancialSummary summary;

  @override
  Widget build(BuildContext context) {
    final totalMovement = summary.totalMovement == 0
        ? 1
        : summary.totalMovement;
    final paymentRatio = summary.totalPayments / totalMovement;
    final expenseRatio = summary.totalExpenses / totalMovement;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => context.push(AppRoutes.propertyDetails(summary.property.id)),
      child: AppPanel(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final theme = Theme.of(context);
            final isCompact = constraints.maxWidth < 400;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCompact) ...[
                  Text(
                    summary.property.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary.property.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  _StatusChip(label: summary.property.status.label),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary.property.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              summary.property.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _StatusChip(label: summary.property.status.label),
                    ],
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'المصروفات',
                        value: summary.totalExpenses.egp,
                        compact: isCompact,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                        label: 'التحصيلات',
                        value: summary.totalPayments.egp,
                        compact: isCompact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (paymentRatio * 1000).round().clamp(1, 1000),
                          child: Container(color: Colors.black),
                        ),
                        Expanded(
                          flex: (expenseRatio * 1000).round().clamp(1, 1000),
                          child: Container(color: const Color(0xFFB3B3AB)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'الرصيد ${summary.balance.egp}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 15 : null,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0EA),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(compact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          SizedBox(height: compact ? 4 : 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 14 : null,
            ),
          ),
        ],
      ),
    );
  }
}
