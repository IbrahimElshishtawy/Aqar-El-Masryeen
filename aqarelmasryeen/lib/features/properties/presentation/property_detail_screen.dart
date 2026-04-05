import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/expense_form_sheet.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/payments/presentation/payment_form_sheet.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/property_record_tables.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
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

class PropertyDetailScreen extends ConsumerStatefulWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  Future<void> _showRecordsSheet({
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _PropertyRecordsSheet(title: title, child: child),
    );
  }

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

  Future<void> _showExpenseTableSheet({
    required String title,
    required List<ExpenseRecord> expenses,
    required List<Partner> partners,
    required Map<String, String> partnerNames,
  }) {
    final totalAmount = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    return _showRecordsSheet(
      title: title,
      child: PropertyExpensesTable(
        title: title,
        subtitle: '${expenses.length} سجل - الإجمالي ${totalAmount.egp}',
        addLabel: 'إضافة مصروف',
        emptyLabel: 'لا توجد مصاريف في هذا القسم',
        emptyActionLabel: 'إضافة مصروف',
        expenses: expenses,
        partnerNames: partnerNames,
        totalAmount: totalAmount,
        onAdd: () => _showExpenseSheet(partners: partners),
        onEdit: (expense) =>
            _showExpenseSheet(partners: partners, expense: expense),
        onDelete: _deleteExpense,
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

  Future<void> _showPaymentTableSheet({
    required String title,
    required List<PaymentRecord> payments,
  }) {
    final totalAmount = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    return _showRecordsSheet(
      title: title,
      child: PropertyPaymentsTable(
        title: title,
        subtitle: '${payments.length} سجل - الإجمالي ${totalAmount.egp}',
        addLabel: 'إضافة مبيعة',
        emptyLabel: 'لا توجد مبيعات في هذا القسم',
        emptyActionLabel: 'إضافة مبيعة',
        payments: payments,
        totalAmount: totalAmount,
        onAdd: () => _showPaymentSheet(),
        onEdit: (payment) => _showPaymentSheet(payment: payment),
        onDelete: _deletePayment,
      ),
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

  Partner? _resolveCurrentPartner({
    required List<Partner> partners,
    required String? sessionUserId,
    required String? profileName,
  }) {
    if (sessionUserId != null && sessionUserId.trim().isNotEmpty) {
      for (final partner in partners) {
        if (partner.userId == sessionUserId) {
          return partner;
        }
      }
    }

    if (profileName != null && profileName.trim().isNotEmpty) {
      final normalizedProfileName = profileName.trim().toLowerCase();
      for (final partner in partners) {
        if (partner.name.trim().toLowerCase() == normalizedProfileName) {
          return partner;
        }
      }
    }

    return null;
  }

  String _buildExpensePartnerLabel({
    required List<Partner> partners,
    required Partner? currentPartner,
    required List<ExpenseRecord> expenses,
  }) {
    final otherPartnerIds = expenses
        .map((expense) => expense.paidByPartnerId)
        .where((id) => id.isNotEmpty && id != currentPartner?.id)
        .toSet();
    final otherPartners = partners
        .where((partner) => otherPartnerIds.contains(partner.id))
        .toList();

    if (otherPartners.length == 1) {
      return 'مصاريف ${otherPartners.first.name}';
    }
    if (otherPartners.length > 1) {
      return 'مصاريف الشركاء';
    }
    return 'مصاريف الشريك';
  }

  String _buildPaymentPartnerLabel({
    required List<Partner> partners,
    required String? sessionUserId,
    required List<PaymentRecord> payments,
  }) {
    final otherCreatorIds = payments
        .map((payment) => payment.createdBy)
        .where((id) => id.isNotEmpty && id != sessionUserId)
        .toSet();
    final otherPartners = partners
        .where((partner) => otherCreatorIds.contains(partner.userId))
        .toList();

    if (otherPartners.length == 1) {
      return 'مبيعات ${otherPartners.first.name}';
    }
    if (otherPartners.length > 1) {
      return 'مبيعات الشركاء';
    }
    return 'مبيعات الشريك';
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
    final session = ref.watch(authSessionProvider).valueOrNull;

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
    final currentPartner = _resolveCurrentPartner(
      partners: partners,
      sessionUserId: session?.userId,
      profileName: session?.profile?.name,
    );
    final myExpenses = currentPartner != null
        ? expenses
              .where((expense) => expense.paidByPartnerId == currentPartner.id)
              .toList()
        : session == null
        ? <ExpenseRecord>[]
        : expenses
              .where((expense) => expense.createdBy == session.userId)
              .toList();
    final partnerExpenses = currentPartner != null
        ? expenses
              .where((expense) => expense.paidByPartnerId != currentPartner.id)
              .toList()
        : session == null
        ? expenses
        : expenses
              .where((expense) => expense.createdBy != session.userId)
              .toList();
    final myPayments = session == null
        ? <PaymentRecord>[]
        : payments
              .where((payment) => payment.createdBy == session.userId)
              .toList();
    final partnerPayments = session == null
        ? payments
        : payments
              .where((payment) => payment.createdBy != session.userId)
              .toList();
    final myExpensesTotal = myExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final partnerExpensesTotal = partnerExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final myPaymentsTotal = myPayments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    final partnerPaymentsTotal = partnerPayments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    final partnerExpensesLabel = _buildExpensePartnerLabel(
      partners: partners,
      currentPartner: currentPartner,
      expenses: partnerExpenses,
    );
    final partnerPaymentsLabel = _buildPaymentPartnerLabel(
      partners: partners,
      sessionUserId: session?.userId,
      payments: partnerPayments,
    );

    return AppShellScaffold(
      title: property.name,
      subtitle: property.location,
      currentIndex: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showSideBySide = constraints.maxWidth >= 980;

          final paymentsOverview = PropertyRecordsOverviewPanel(
            title: 'المبيعات',
            subtitle: '${payments.length} سجل - الإجمالي ${totalPayments.egp}',
            addLabel: 'إضافة مبيعة',
            onAdd: () => _showPaymentSheet(),
            primaryLabel: 'مبيعاتي',
            primaryCount: myPayments.length,
            primaryTotal: myPaymentsTotal,
            onOpenPrimary: () =>
                _showPaymentTableSheet(title: 'مبيعاتي', payments: myPayments),
            secondaryLabel: partnerPaymentsLabel,
            secondaryCount: partnerPayments.length,
            secondaryTotal: partnerPaymentsTotal,
            onOpenSecondary: () => _showPaymentTableSheet(
              title: partnerPaymentsLabel,
              payments: partnerPayments,
            ),
            icon: Icons.point_of_sale_outlined,
          );
          final expensesOverview = PropertyRecordsOverviewPanel(
            title: 'المصاريف',
            subtitle: '${expenses.length} سجل - الإجمالي ${totalExpenses.egp}',
            addLabel: 'إضافة مصروف',
            onAdd: () => _showExpenseSheet(partners: partners),
            primaryLabel: 'مصاريفي',
            primaryCount: myExpenses.length,
            primaryTotal: myExpensesTotal,
            onOpenPrimary: () => _showExpenseTableSheet(
              title: 'مصاريفي',
              expenses: myExpenses,
              partners: partners,
              partnerNames: partnerNames,
            ),
            secondaryLabel: partnerExpensesLabel,
            secondaryCount: partnerExpenses.length,
            secondaryTotal: partnerExpensesTotal,
            onOpenSecondary: () => _showExpenseTableSheet(
              title: partnerExpensesLabel,
              expenses: partnerExpenses,
              partners: partners,
              partnerNames: partnerNames,
            ),
            icon: Icons.receipt_long_outlined,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (showSideBySide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: paymentsOverview),
                    const SizedBox(width: 12),
                    Expanded(child: expensesOverview),
                  ],
                )
              else ...[
                paymentsOverview,
                const SizedBox(height: 12),
                expensesOverview,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PropertyRecordsSheet extends StatelessWidget {
  const _PropertyRecordsSheet({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: ListView(children: [child])),
          ],
        ),
      ),
    );
  }
}
