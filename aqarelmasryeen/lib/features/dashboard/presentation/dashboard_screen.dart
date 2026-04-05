import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/summary_card.dart';
import 'package:aqarelmasryeen/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:aqarelmasryeen/features/dashboard/presentation/widgets/dashboard_finance_chart.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final dashboardPropertiesProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(propertyRepositoryProvider).watchProperties(),
);
final dashboardExpensesProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(expenseRepositoryProvider).watchAll(),
);
final dashboardPaymentsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(paymentRepositoryProvider).watchAll(),
);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(dashboardPropertiesProvider);
    final expensesAsync = ref.watch(dashboardExpensesProvider);
    final paymentsAsync = ref.watch(dashboardPaymentsProvider);

    if (propertiesAsync.hasError ||
        expensesAsync.hasError ||
        paymentsAsync.hasError) {
      return AppShellScaffold(
        title: 'Home',
        subtitle: 'Portfolio overview',
        currentIndex: 0,
        actions: _actions(context),
        child: EmptyStateView(
          title: 'Unable to load dashboard',
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
      return AppShellScaffold(
        title: 'Home',
        subtitle: 'Portfolio overview',
        currentIndex: 0,
        actions: _actions(context),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final snapshot = const DashboardSnapshotBuilder().build(
      properties: propertiesAsync.value!,
      expenses: expensesAsync.value!,
      payments: paymentsAsync.value!,
    );

    return AppShellScaffold(
      title: 'Home',
      subtitle: 'Portfolio overview',
      currentIndex: 0,
      actions: _actions(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SummaryCard(
            label: 'Total properties',
            value: '${snapshot.propertyCount}',
            subtitle: 'Primary portfolio count across the workspace',
            icon: Icons.apartment_rounded,
            emphasis: true,
            splitLayout: true,
          ),
          const SizedBox(height: 12),
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
                    label: 'Total expenses',
                    value: snapshot.totalExpenses.egp,
                    subtitle: 'All recorded outgoing costs',
                    icon: Icons.north_east_rounded,
                    splitLayout: true,
                  ),
                  SummaryCard(
                    label: 'Total payments',
                    value: snapshot.totalPayments.egp,
                    subtitle: 'All recorded incoming cash',
                    icon: Icons.south_west_rounded,
                    splitLayout: true,
                  ),
                  SummaryCard(
                    label: 'Net balance',
                    value: snapshot.netBalance.egp,
                    subtitle: 'Payments minus expenses',
                    icon: Icons.account_balance_wallet_outlined,
                    splitLayout: true,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          DashboardFinanceChart(buckets: snapshot.chart),
          const SizedBox(height: 12),
          AppPanel(
            title: 'Recent financial activity',
            subtitle: 'Latest expense and payment records',
            child: snapshot.recentRecords.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No financial activity yet.'),
                  )
                : Column(
                    children: [
                      for (
                        var index = 0;
                        index < snapshot.recentRecords.length;
                        index++
                      ) ...[
                        _RecentRecordTile(
                          record: snapshot.recentRecords[index],
                        ),
                        if (index != snapshot.recentRecords.length - 1)
                          const Divider(height: 24),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => context.push(AppRoutes.notifications),
        icon: const Icon(Icons.notifications_none_rounded),
      ),
      IconButton(
        onPressed: () => context.push(AppRoutes.settings),
        icon: const Icon(Icons.settings_outlined),
      ),
    ];
  }
}

class _RecentRecordTile extends StatelessWidget {
  const _RecentRecordTile({required this.record});

  final DashboardRecentRecord record;

  @override
  Widget build(BuildContext context) {
    final isExpense = record.type == DashboardRecordType.expense;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isExpense ? const Color(0xFFF0F0EA) : Colors.black,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isExpense ? Icons.north_east_rounded : Icons.south_west_rounded,
            color: isExpense ? Colors.black : Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text('${record.propertyName} • ${record.subtitle}'),
              const SizedBox(height: 4),
              Text(record.date.formatWithTime()),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${isExpense ? '-' : '+'}${record.amount.egp}',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
