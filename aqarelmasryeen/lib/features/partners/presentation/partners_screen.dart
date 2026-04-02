import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core\widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/partners/domain/partner_settlement_calculator.dart';
import 'package:aqarelmasryeen/features/partners/presentation/partner_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PartnersScreen extends ConsumerWidget {
  const PartnersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partners = ref.watch(
      StreamProvider.autoDispose((ref) => ref.watch(partnerRepositoryProvider).watchPartners()),
    );
    final expenses = ref.watch(
      StreamProvider.autoDispose((ref) => ref.watch(expenseRepositoryProvider).watchAll()),
    );

    return AppShellScaffold(
      title: 'Partners',
      currentIndex: 2,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const PartnerFormSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add partner'),
      ),
      child: partners.when(
        data: (partnerItems) => expenses.when(
          data: (expenseItems) {
            if (partnerItems.isEmpty) {
              return const EmptyStateView(
                title: 'No partner records',
                message: 'Create the two partner records to start settlement tracking.',
              );
            }
            final settlements = const PartnerSettlementCalculator().build(
              partners: partnerItems,
              expenses: expenseItems,
            );
            final totalCapital =
                partnerItems.fold<double>(0, (sum, item) => sum + item.contributionTotal);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    title: const Text('Tracked capital contributions'),
                    trailing: Text(totalCapital.egp),
                  ),
                ),
                const SizedBox(height: 12),
                for (final item in settlements) ...[
                  Card(
                    child: ListTile(
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => PartnerFormSheet(
                          partner: partnerItems.firstWhere((partner) => partner.id == item.partnerId),
                        ),
                      ),
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
                  const SizedBox(height: 12),
                ],
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
