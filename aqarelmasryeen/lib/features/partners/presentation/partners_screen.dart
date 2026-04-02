import 'package:aqarelmasryeen/core\extensions\number_extensions.dart';
import 'package:aqarelmasryeen/core\widgets\app_shell_scaffold.dart';
import 'package:aqarelmasryeen/features\expenses\data\expense_repository.dart';
import 'package:aqarelmasryeen/features\partners\data\partner_repository.dart';
import 'package:aqarelmasryeen/features\partners\domain\partner_settlement_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PartnersScreen extends ConsumerWidget {
  const PartnersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partners = ref.watch(
      StreamProvider((ref) => ref.watch(partnerRepositoryProvider).watchPartners()),
    );
    final expenses = ref.watch(
      StreamProvider((ref) => ref.watch(expenseRepositoryProvider).watchAll()),
    );

    return AppShellScaffold(
      title: 'Partners',
      currentIndex: 2,
      child: partners.when(
        data: (partnerItems) => expenses.when(
          data: (expenseItems) {
            final settlements = const PartnerSettlementCalculator().build(
              partners: partnerItems,
              expenses: expenseItems,
            );
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final item in settlements)
                  Card(
                    child: ListTile(
                      title: Text(item.partnerName),
                      subtitle: Text(
                        'Expected ${item.expectedContribution.egp} • Contributed ${item.contributedAmount.egp}',
                      ),
                      trailing: Text(
                        item.balanceDelta.egp,
                        style: TextStyle(
                          color: item.balanceDelta >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
          error: (error, _) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
