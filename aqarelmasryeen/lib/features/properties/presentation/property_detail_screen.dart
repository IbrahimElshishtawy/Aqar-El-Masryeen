import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/summary_card.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/expense_form_sheet.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/payments/presentation/payment_form_sheet.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/property_record_tables.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final propertyDetailsProvider = StreamProvider.autoDispose
    .family<PropertyProject?, String>(
      (ref, propertyId) =>
          ref.watch(propertyRepositoryProvider).watchProperty(propertyId),
    );
final propertyExpensesProvider = StreamProvider.autoDispose
    .family<List<ExpenseRecord>, String>(
      (ref, propertyId) =>
          ref.watch(expenseRepositoryProvider).watchByProperty(propertyId),
    );
final propertyPaymentsProvider = StreamProvider.autoDispose
    .family<List<PaymentRecord>, String>(
      (ref, propertyId) =>
          ref.watch(paymentRepositoryProvider).watchByProperty(propertyId),
    );
final propertyPartnersProvider = StreamProvider.autoDispose<List<Partner>>(
  (ref) => ref.watch(partnerRepositoryProvider).watchPartners(),
);

enum _PropertySection { expenses, payments }

class PropertyDetailScreen extends ConsumerStatefulWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  _PropertySection _section = _PropertySection.expenses;

  Future<void> _showExpenseSheet({
    required List<Partner> partners,
    ExpenseRecord? expense,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ExpenseFormSheet(
        propertyId: widget.propertyId,
        partners: partners,
        expense: expense,
      ),
    );
  }

  Future<void> _showPaymentSheet({PaymentRecord? payment}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          PaymentFormSheet(propertyId: widget.propertyId, payment: payment),
    );
  }

  Future<void> _deleteExpense(ExpenseRecord expense) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete expense'),
            content: const Text(
              'This expense will be removed from the active list.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    await ref.read(expenseRepositoryProvider).softDelete(expense.id);
    await ref
        .read(activityRepositoryProvider)
        .log(
          actorId: session.userId,
          actorName: session.profile?.name ?? 'Partner',
          action: 'expense_deleted',
          entityType: 'expense',
          entityId: expense.id,
          metadata: {'propertyId': widget.propertyId, 'amount': expense.amount},
        );
  }

  Future<void> _deletePayment(PaymentRecord payment) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete payment'),
            content: const Text('This payment will be permanently deleted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    await ref.read(paymentRepositoryProvider).delete(payment.id);
    await ref
        .read(activityRepositoryProvider)
        .log(
          actorId: session.userId,
          actorName: session.profile?.name ?? 'Partner',
          action: 'payment_deleted',
          entityType: 'payment',
          entityId: payment.id,
          metadata: {'propertyId': widget.propertyId, 'amount': payment.amount},
        );
  }

  @override
  Widget build(BuildContext context) {
    final propertyAsync = ref.watch(propertyDetailsProvider(widget.propertyId));
    final expensesAsync = ref.watch(
      propertyExpensesProvider(widget.propertyId),
    );
    final paymentsAsync = ref.watch(
      propertyPaymentsProvider(widget.propertyId),
    );
    final partnersAsync = ref.watch(propertyPartnersProvider);

    if (propertyAsync.hasError ||
        expensesAsync.hasError ||
        paymentsAsync.hasError ||
        partnersAsync.hasError) {
      return AppShellScaffold(
        title: 'Property',
        subtitle: 'Financial records',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'Unable to load property',
          message:
              propertyAsync.error?.toString() ??
              expensesAsync.error?.toString() ??
              paymentsAsync.error?.toString() ??
              partnersAsync.error?.toString() ??
              'Unknown error',
        ),
      );
    }

    if (!propertyAsync.hasValue ||
        !expensesAsync.hasValue ||
        !paymentsAsync.hasValue ||
        !partnersAsync.hasValue) {
      return const AppShellScaffold(
        title: 'Property',
        subtitle: 'Financial records',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final property = propertyAsync.value;
    if (property == null) {
      return const AppShellScaffold(
        title: 'Property',
        subtitle: 'Financial records',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'Property not found',
          message: 'This property is no longer available.',
        ),
      );
    }

    final expenses = expensesAsync.value!;
    final payments = paymentsAsync.value!;
    final partners = partnersAsync.value!;
    final partnerNames = {
      for (final partner in partners) partner.id: partner.name,
    };
    final totalExpenses = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final totalPayments = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );

    return AppShellScaffold(
      title: property.name,
      subtitle: property.location,
      currentIndex: 1,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
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
                      childAspectRatio: isWide ? 1.55 : 2.25,
                      children: [
                        SummaryCard(
                          label: 'Status',
                          value: property.status.label,
                          subtitle: property.location,
                          icon: Icons.apartment_rounded,
                          emphasis: true,
                        ),
                        SummaryCard(
                          label: 'Expenses',
                          value: totalExpenses.egp,
                          subtitle: '${expenses.length} record(s)',
                          icon: Icons.north_east_rounded,
                        ),
                        SummaryCard(
                          label: 'Payments',
                          value: totalPayments.egp,
                          subtitle: '${payments.length} record(s)',
                          icon: Icons.south_west_rounded,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_PropertySection>(
                    segments: const [
                      ButtonSegment(
                        value: _PropertySection.expenses,
                        label: Text('Expenses'),
                      ),
                      ButtonSegment(
                        value: _PropertySection.payments,
                        label: Text('Payments'),
                      ),
                    ],
                    selected: {_section},
                    onSelectionChanged: (value) {
                      setState(() => _section = value.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                if (_section == _PropertySection.expenses)
                  PropertyExpensesTable(
                    expenses: expenses,
                    partnerNames: partnerNames,
                    onAdd: () => _showExpenseSheet(partners: partners),
                    onEdit: (expense) =>
                        _showExpenseSheet(partners: partners, expense: expense),
                    onDelete: _deleteExpense,
                  )
                else
                  PropertyPaymentsTable(
                    payments: payments,
                    onAdd: () => _showPaymentSheet(),
                    onEdit: (payment) => _showPaymentSheet(payment: payment),
                    onDelete: _deletePayment,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
