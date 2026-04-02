import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/metric_card.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/collections/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/dashboard/domain/dashboard_assembler.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/installments/data/installment_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/sales/data/sales_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final dashboardPropertiesProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(propertyRepositoryProvider).watchProperties(),
);
final dashboardExpensesProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(expenseRepositoryProvider).watchAll(),
);
final dashboardUnitsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(salesRepositoryProvider).watchAll(),
);
final dashboardInstallmentsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(installmentRepositoryProvider).watchAllInstallments(),
);
final dashboardPaymentsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(paymentRepositoryProvider).watchAll(),
);
final dashboardActivityProvider = StreamProvider.autoDispose<List<ActivityLogEntry>>(
  (ref) => ref.watch(activityRepositoryProvider).watchRecent(),
);
final dashboardPartnersProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(partnerRepositoryProvider).watchPartners(),
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
    final partners = ref.watch(dashboardPartnersProvider);
    final session = ref.watch(authSessionProvider).valueOrNull;

    final allReady = [
      properties,
      expenses,
      units,
      installments,
      payments,
      activity,
      partners,
    ].every((item) => item.hasValue);

    if (!allReady) {
      return const AppShellScaffold(
        title: 'Dashboard',
        currentIndex: 0,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final summary = const DashboardAssembler().build(
      properties: properties.value!,
      expenses: expenses.value!,
      units: units.value!,
      installments: installments.value!,
      payments: payments.value!,
      recentActivity: activity.value!,
    );
    final topProperties = properties.value!.take(3).toList();

    return AppShellScaffold(
      title: 'Dashboard',
      currentIndex: 0,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.notifications),
          icon: const Icon(Icons.notifications_none_outlined),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome ${session?.profile?.name.isNotEmpty == true ? session!.profile!.name : 'Partner'}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Live accounting snapshot across properties, collections, and partner settlement exposure.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: MediaQuery.sizeOf(context).width < 500 ? 2 : 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: [
              MetricCard(label: 'Properties', value: '${summary.totalProperties}', icon: Icons.apartment_outlined),
              MetricCard(label: 'Expenses', value: summary.totalExpenses.egp, icon: Icons.account_balance_wallet_outlined),
              MetricCard(label: 'Sales', value: summary.totalSalesValue.egp, icon: Icons.trending_up_outlined),
              MetricCard(label: 'Collected', value: summary.totalCollected.egp, icon: Icons.payments_outlined),
              MetricCard(label: 'Remaining', value: summary.totalRemaining.egp, icon: Icons.hourglass_bottom_outlined),
              MetricCard(label: 'Overdue', value: '${summary.overdueInstallmentsCount}', icon: Icons.warning_amber_outlined, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.properties),
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Manage properties'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.partners),
                icon: const Icon(Icons.group_outlined),
                label: const Text('Partner balances'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.reports),
                icon: const Icon(Icons.summarize_outlined),
                label: const Text('Open reports'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Priority properties', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (topProperties.isEmpty)
            const EmptyStateView(
              title: 'No active properties',
              message: 'Create a project to start the accounting workflow.',
            )
          else
            for (final property in topProperties) ...[
              Card(
                child: ListTile(
                  title: Text(property.name),
                  subtitle: Text('${property.location} • ${property.status.label}'),
                  trailing: TextButton(
                    onPressed: () => context.push(AppRoutes.propertyDetails(property.id)),
                    child: const Text('Open'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          Text('Recent activity', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final item in activity.value!) ...[
            Card(
              child: ListTile(
                dense: true,
                title: Text('${item.actorName} ${item.action.replaceAll('_', ' ')}'),
                subtitle: Text(item.createdAt.formatWithTime()),
                trailing: Text(item.entityType),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
