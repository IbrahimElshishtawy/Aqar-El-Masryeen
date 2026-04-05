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
        title: 'Properties',
        subtitle: 'Financial health by asset',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'Unable to load properties',
          message:
              propertiesAsync.error?.toString() ??
              expensesAsync.error?.toString() ??
              paymentsAsync.error?.toString() ??
              'Unknown error',
        ),
      );
    }

    if (!propertiesAsync.hasValue ||
        !expensesAsync.hasValue ||
        !paymentsAsync.hasValue) {
      return const AppShellScaffold(
        title: 'Properties',
        subtitle: 'Financial health by asset',
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
      title: 'Properties',
      subtitle: 'Financial health by asset',
      currentIndex: 1,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 680;
              return GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: isWide ? 3 : 1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isWide ? 1.55 : 2.35,
                children: [
                  SummaryCard(
                    label: 'Properties',
                    value: '${summaries.length}',
                    subtitle: 'Active portfolio entries',
                    icon: Icons.apartment_rounded,
                    emphasis: true,
                  ),
                  SummaryCard(
                    label: 'Expenses',
                    value: totalExpenses.egp,
                    subtitle: 'All property expenses',
                    icon: Icons.north_east_rounded,
                  ),
                  SummaryCard(
                    label: 'Payments',
                    value: totalPayments.egp,
                    subtitle: 'All property payments',
                    icon: Icons.south_west_rounded,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (summaries.isEmpty)
            const EmptyStateView(
              title: 'No properties yet',
              message:
                  'Properties will appear here once your workspace is populated.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 900 ? 2 : 1;
                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: summaries.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: crossAxisCount == 1 ? 1.55 : 1.28,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.property.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(summary.property.location),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0EA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(summary.property.status.label),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Expenses',
                    value: summary.totalExpenses.egp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    label: 'Payments',
                    value: summary.totalPayments.egp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 10,
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
              'Balance ${summary.balance.egp}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0EA),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
