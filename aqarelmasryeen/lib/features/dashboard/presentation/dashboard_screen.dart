import 'package:aqarelmasryeen/core\extensions\number_extensions.dart';
import 'package:aqarelmasryeen/core\widgets\app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core\widgets\metric_card.dart';
import 'package:aqarelmasryeen/features\auth\presentation\auth_providers.dart';
import 'package:aqarelmasryeen/features\collections\data\payment_repository.dart';
import 'package:aqarelmasryeen/features\dashboard\domain\dashboard_assembler.dart';
import 'package:aqarelmasryeen/features\notifications\presentation\notifications_center_screen.dart';
import 'package:aqarelmasryeen/features\properties\data\property_repository.dart';
import 'package:aqarelmasryeen/features\expenses\data\expense_repository.dart';
import 'package:aqarelmasryeen/features\installments\data\installment_repository.dart';
import 'package:aqarelmasryeen/features\sales\data\sales_repository.dart';
import 'package:aqarelmasryeen/features\settings\data\activity_repository.dart';
import 'package:aqarelmasryeen/shared\models\partner_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final dashboardPropertiesProvider = StreamProvider(
  (ref) => ref.watch(propertyRepositoryProvider).watchProperties(),
);
final dashboardExpensesProvider = StreamProvider(
  (ref) => ref.watch(expenseRepositoryProvider).watchAll(),
);
final dashboardUnitsProvider = StreamProvider(
  (ref) => ref.watch(salesRepositoryProvider).watchAll(),
);
final dashboardInstallmentsProvider = StreamProvider(
  (ref) => ref.watch(installmentRepositoryProvider).watchAllInstallments(),
);
final dashboardPaymentsProvider = StreamProvider(
  (ref) => ref.watch(paymentRepositoryProvider).watchAll(),
);
final dashboardActivityProvider = StreamProvider<List<ActivityLogEntry>>(
  (ref) => ref.watch(activityRepositoryProvider).watchRecent(),
);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(dashboardPropertiesProvider);
    final expenses = ref.watch(dashboardExpensesProvider);
    final units = ref.watch(dashboardUnitsProvider);
    final installments = ref.watch(dashboardInstallmentsProvider);
    final payments = ref.watch(dashboardPaymentsProvider);
    final activity = ref.watch(dashboardActivityProvider);
    final session = ref.watch(authSessionProvider).valueOrNull;

    final allReady = [
      properties,
      expenses,
      units,
      installments,
      payments,
      activity,
    ].every((item) => item.hasValue);

    final summary = allReady
        ? const DashboardAssembler().build(
            properties: properties.value!,
            expenses: expenses.value!,
            units: units.value!,
            installments: installments.value!,
            payments: payments.value!,
            recentActivity: activity.value!,
          )
        : null;

    return AppShellScaffold(
      title: 'Dashboard',
      currentIndex: 0,
      actions: [
        IconButton(
          onPressed: () => context.push('/notifications'),
          icon: const Icon(Icons.notifications_none_outlined),
        ),
      ],
      child: summary == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Welcome ${session?.profile?.name.isNotEmpty == true ? session!.profile!.name : 'Partner'}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: MediaQuery.sizeOf(context).width < 420 ? 2 : 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.2,
                  children: [
                    MetricCard(
                      label: 'Properties',
                      value: '${summary.totalProperties}',
                      icon: Icons.apartment_outlined,
                    ),
                    MetricCard(
                      label: 'Expenses',
                      value: summary.totalExpenses.egp,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    MetricCard(
                      label: 'Sales',
                      value: summary.totalSalesValue.egp,
                      icon: Icons.trending_up_outlined,
                    ),
                    MetricCard(
                      label: 'Collected',
                      value: summary.totalCollected.egp,
                      icon: Icons.payments_outlined,
                    ),
                    MetricCard(
                      label: 'Remaining',
                      value: summary.totalRemaining.egp,
                      icon: Icons.hourglass_bottom_outlined,
                    ),
                    MetricCard(
                      label: 'Overdue',
                      value: '${summary.overdueInstallmentsCount}',
                      icon: Icons.warning_amber_outlined,
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Recent activity', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final item in activity.value!)
                  Card(
                    child: ListTile(
                      dense: true,
                      title: Text('${item.actorName} ${item.action.replaceAll('_', ' ')}'),
                      subtitle: Text(item.entityType),
                      trailing: Text(
                        TimeOfDay.fromDateTime(item.createdAt).format(context),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
