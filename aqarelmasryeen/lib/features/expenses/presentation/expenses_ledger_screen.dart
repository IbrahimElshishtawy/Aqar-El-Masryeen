import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/summary_card.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/domain/materials_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_ledger_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/partners/domain/partner_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/financial_ledger_table.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allMaterialsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(materialExpenseRepositoryProvider).watchAll(),
);
final allPartnersProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(partnerRepositoryProvider).watchPartners(),
);
final allPartnerLedgersProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(partnerLedgerRepositoryProvider).watchAll(),
);

class ExpensesLedgerScreen extends ConsumerWidget {
  const ExpensesLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(allMaterialsProvider);
    final partnersAsync = ref.watch(allPartnersProvider);
    final partnerLedgersAsync = ref.watch(allPartnerLedgersProvider);

    if (materialsAsync.hasError || partnersAsync.hasError || partnerLedgersAsync.hasError) {
      return AppShellScaffold(
        title: 'Expenses',
        subtitle: 'Supplier and partner ledgers',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'Unable to load expense ledgers',
          message:
              materialsAsync.error?.toString() ??
              partnersAsync.error?.toString() ??
              partnerLedgersAsync.error?.toString() ??
              'Unknown error',
        ),
      );
    }

    if (!materialsAsync.hasValue || !partnersAsync.hasValue || !partnerLedgersAsync.hasValue) {
      return const AppShellScaffold(
        title: 'Expenses',
        subtitle: 'Supplier and partner ledgers',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final materials = materialsAsync.value!;
    final partners = partnersAsync.value!;
    final partnerLedgers = partnerLedgersAsync.value!;
    final materialSnapshot = const MaterialsLedgerCalculator().build(materials);
    final partnerSnapshot = const PartnerLedgerCalculator().build(
      partners: partners,
      expenses: const [],
      materialExpenses: materials,
      ledgerEntries: partnerLedgers,
    );

    return AppShellScaffold(
      title: 'Expenses',
      subtitle: 'Supplier and partner ledgers',
      currentIndex: 1,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _ExpenseSummaryGrid(
            cards: [
              SummaryCard(
                label: 'Material total',
                value: materialSnapshot.overallTotal.egp,
                subtitle: 'All supplier invoices',
                icon: Icons.inventory_outlined,
                emphasis: true,
              ),
              SummaryCard(
                label: 'Supplier dues',
                value: materialSnapshot.overallRemaining.egp,
                subtitle: 'Outstanding supplier balances',
                icon: Icons.pending_actions_outlined,
              ),
              SummaryCard(
                label: 'Partners tracked',
                value: '${partnerSnapshot.length}',
                subtitle: 'Protected contribution ledger',
                icon: Icons.groups_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          FinancialLedgerTable<SupplierLedgerSummary>(
            title: 'Supplier Summary',
            subtitle: 'Paid vs owed by supplier',
            rows: materialSnapshot.supplierSummaries,
            columns: [
              LedgerColumn(label: 'Supplier', valueBuilder: (row) => Text(row.supplierName)),
              LedgerColumn(label: 'Invoices', valueBuilder: (row) => Text('${row.invoiceCount}')),
              LedgerColumn(label: 'Purchased', valueBuilder: (row) => Text(row.totalPurchased.egp)),
              LedgerColumn(label: 'Paid', valueBuilder: (row) => Text(row.totalPaid.egp)),
              LedgerColumn(label: 'Remaining', valueBuilder: (row) => Text(row.totalRemaining.egp)),
            ],
          ),
          const SizedBox(height: 16),
          FinancialLedgerTable<PartnerLedgerSummaryRow>(
            title: 'Partner Ledger',
            subtitle: 'Total paid, owed, and balance by partner',
            rows: partnerSnapshot,
            columns: [
              LedgerColumn(label: 'Partner', valueBuilder: (row) => Text(row.partner.name)),
              LedgerColumn(label: 'Paid', valueBuilder: (row) => Text(row.totalPaid.egp)),
              LedgerColumn(label: 'Owed', valueBuilder: (row) => Text(row.totalOwed.egp)),
              LedgerColumn(label: 'Balance', valueBuilder: (row) => Text(row.balance.egp)),
              LedgerColumn(label: 'Last updated', valueBuilder: (row) => Text(row.lastUpdated.toString().split(' ').first)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseSummaryGrid extends StatelessWidget {
  const _ExpenseSummaryGrid({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 800 ? 3 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: count == 1 ? 2.4 : 1.7,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}
