import 'package:aqarelmasryeen/core\extensions\number_extensions.dart';
import 'package:aqarelmasryeen/core\widgets\app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core\widgets\metric_card.dart';
import 'package:aqarelmasryeen/features\collections\data\payment_repository.dart';
import 'package:aqarelmasryeen/features\expenses\data\expense_repository.dart';
import 'package:aqarelmasryeen/features\properties\data\property_repository.dart';
import 'package:aqarelmasryeen/features\sales\data\sales_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(StreamProvider((ref) => ref.watch(propertyRepositoryProvider).watchProperties()));
    final expenses = ref.watch(StreamProvider((ref) => ref.watch(expenseRepositoryProvider).watchAll()));
    final units = ref.watch(StreamProvider((ref) => ref.watch(salesRepositoryProvider).watchAll()));
    final payments = ref.watch(StreamProvider((ref) => ref.watch(paymentRepositoryProvider).watchAll()));

    if (!properties.hasValue || !expenses.hasValue || !units.hasValue || !payments.hasValue) {
      return const AppShellScaffold(
        title: 'Reports',
        currentIndex: 3,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final propertyCount = properties.value!.length;
    final totalExpenses = expenses.value!.fold<double>(0, (sum, item) => sum + item.amount);
    final totalSales = units.value!.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final totalCollected = payments.value!.fold<double>(0, (sum, item) => sum + item.amount);

    return AppShellScaffold(
      title: 'Reports',
      currentIndex: 3,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: MediaQuery.sizeOf(context).width < 420 ? 2 : 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.25,
            children: [
              MetricCard(label: 'Projects', value: '$propertyCount', icon: Icons.business_outlined),
              MetricCard(label: 'Expense summary', value: totalExpenses.egp, icon: Icons.money_off_csred_outlined),
              MetricCard(label: 'Collections', value: totalCollected.egp, icon: Icons.payments_outlined),
              MetricCard(label: 'Sales value', value: totalSales.egp, icon: Icons.trending_up_outlined),
            ],
          ),
          const SizedBox(height: 20),
          Text('Property report', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final property in properties.value!)
            Card(
              child: ListTile(
                title: Text(property.name),
                subtitle: Text(property.location),
                trailing: Text(property.totalSalesTarget.egp),
              ),
            ),
        ],
      ),
    );
  }
}
