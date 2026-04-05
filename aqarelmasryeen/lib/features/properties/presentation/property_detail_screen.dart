import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/summary_card.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/domain/materials_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/material_expense_form_sheet.dart';
import 'package:aqarelmasryeen/features/installments/data/installment_repository.dart';
import 'package:aqarelmasryeen/features/installments/presentation/installment_form_sheet.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_ledger_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/partners/domain/partner_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/partners/presentation/partner_ledger_entry_form_sheet.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/payments/presentation/payment_form_sheet.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/financial_ledger_table.dart';
import 'package:aqarelmasryeen/features/sales/data/sales_repository.dart';
import 'package:aqarelmasryeen/features/sales/presentation/unit_form_sheet.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/features/unit_sales/domain/unit_sales_calculator.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final propertyDetailsProvider = StreamProvider.autoDispose.family<PropertyProject?, String>(
  (ref, propertyId) => ref.watch(propertyRepositoryProvider).watchProperty(propertyId),
);
final propertyUnitsProvider = StreamProvider.autoDispose.family<List<UnitSale>, String>(
  (ref, propertyId) => ref.watch(salesRepositoryProvider).watchByProperty(propertyId),
);
final propertyInstallmentsProvider = StreamProvider.autoDispose.family<List<Installment>, String>(
  (ref, propertyId) => ref.watch(installmentRepositoryProvider).watchInstallmentsByProperty(propertyId),
);
final propertyPaymentsProvider = StreamProvider.autoDispose.family<List<PaymentRecord>, String>(
  (ref, propertyId) => ref.watch(paymentRepositoryProvider).watchByProperty(propertyId),
);
final propertyMaterialsProvider = StreamProvider.autoDispose.family<List<MaterialExpenseEntry>, String>(
  (ref, propertyId) => ref.watch(materialExpenseRepositoryProvider).watchByProperty(propertyId),
);
final propertyPartnersProvider = StreamProvider.autoDispose<List<Partner>>(
  (ref) => ref.watch(partnerRepositoryProvider).watchPartners(),
);
final propertyPartnerLedgerProvider = StreamProvider.autoDispose<List<PartnerLedgerEntry>>(
  (ref) => ref.watch(partnerLedgerRepositoryProvider).watchAll(),
);

class PropertyDetailScreen extends ConsumerStatefulWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  Future<void> _showUnitSheet({UnitSale? unit}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => UnitFormSheet(propertyId: widget.propertyId, unit: unit),
    );
  }

  Future<void> _showInstallmentSheet({
    required UnitSale unit,
    required String planId,
    Installment? installment,
    int? suggestedSequence,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => InstallmentFormSheet(
        propertyId: widget.propertyId,
        unitId: unit.id,
        planId: planId,
        installment: installment,
        suggestedSequence: suggestedSequence,
      ),
    );
  }

  Future<void> _showPaymentSheet({
    required UnitSale unit,
    String? installmentId,
    PaymentRecord? payment,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PaymentFormSheet(
        propertyId: widget.propertyId,
        initialUnitId: unit.id,
        installmentId: installmentId,
        payment: payment,
      ),
    );
  }

  Future<void> _showMaterialSheet({MaterialExpenseEntry? entry}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MaterialExpenseFormSheet(propertyId: widget.propertyId, entry: entry),
    );
  }

  Future<void> _showPartnerLedgerSheet({required Partner partner, PartnerLedgerEntry? entry}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PartnerLedgerEntryFormSheet(partner: partner, entry: entry),
    );
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm')),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteUnit(UnitSale unit) async {
    final confirmed = await _confirm(
      'Delete unit sale',
      'This removes the unit, its installments, and linked payments.',
    );
    if (!confirmed) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    await ref.read(salesRepositoryProvider).delete(unit.id);
    await ref.read(activityRepositoryProvider).log(
      actorId: session.userId,
      actorName: session.profile?.name ?? 'Partner',
      action: 'unit_deleted',
      entityType: 'unit',
      entityId: unit.id,
      metadata: {'propertyId': widget.propertyId},
    );
  }

  Future<void> _deleteInstallment(Installment installment) async {
    final confirmed = await _confirm(
      'Delete installment',
      'The installment and its linked payments will be removed.',
    );
    if (!confirmed) return;
    await ref.read(installmentRepositoryProvider).deleteInstallment(installment.id);
  }

  Future<void> _deletePayment(PaymentRecord payment) async {
    final confirmed = await _confirm(
      'Delete payment',
      'This payment will be removed from installment totals.',
    );
    if (!confirmed) return;
    await ref.read(paymentRepositoryProvider).delete(payment.id);
  }

  Future<void> _deleteMaterial(MaterialExpenseEntry entry) async {
    final confirmed = await _confirm(
      'Delete material invoice',
      'This invoice will be archived from active ledgers.',
    );
    if (!confirmed) return;
    await ref.read(materialExpenseRepositoryProvider).softDelete(entry.id);
  }

  Future<void> _deletePartnerLedger(PartnerLedgerEntry entry) async {
    final confirmed = await _confirm(
      'Authorized delete',
      'This protected partner ledger entry will be archived.',
    );
    if (!confirmed) return;
    await ref.read(partnerLedgerRepositoryProvider).softDeleteAuthorized(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final propertyAsync = ref.watch(propertyDetailsProvider(widget.propertyId));
    final unitsAsync = ref.watch(propertyUnitsProvider(widget.propertyId));
    final installmentsAsync = ref.watch(propertyInstallmentsProvider(widget.propertyId));
    final paymentsAsync = ref.watch(propertyPaymentsProvider(widget.propertyId));
    final materialsAsync = ref.watch(propertyMaterialsProvider(widget.propertyId));
    final partnersAsync = ref.watch(propertyPartnersProvider);
    final partnerLedgerAsync = ref.watch(propertyPartnerLedgerProvider);

    final hasError = propertyAsync.hasError ||
        unitsAsync.hasError ||
        installmentsAsync.hasError ||
        paymentsAsync.hasError ||
        materialsAsync.hasError ||
        partnersAsync.hasError ||
        partnerLedgerAsync.hasError;
    if (hasError) {
      return AppShellScaffold(
        title: 'Property',
        subtitle: 'Sales and ledger view',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'Unable to load property finance',
          message:
              propertyAsync.error?.toString() ??
              unitsAsync.error?.toString() ??
              installmentsAsync.error?.toString() ??
              paymentsAsync.error?.toString() ??
              materialsAsync.error?.toString() ??
              partnersAsync.error?.toString() ??
              partnerLedgerAsync.error?.toString() ??
              'Unknown error',
        ),
      );
    }

    final waiting = !propertyAsync.hasValue ||
        !unitsAsync.hasValue ||
        !installmentsAsync.hasValue ||
        !paymentsAsync.hasValue ||
        !materialsAsync.hasValue ||
        !partnersAsync.hasValue ||
        !partnerLedgerAsync.hasValue;
    if (waiting) {
      return const AppShellScaffold(
        title: 'Property',
        subtitle: 'Sales and ledger view',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final property = propertyAsync.value;
    if (property == null) {
      return const AppShellScaffold(
        title: 'Property',
        subtitle: 'Sales and ledger view',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'Property not found',
          message: 'This property is no longer available.',
        ),
      );
    }

    final units = unitsAsync.value!;
    final installments = installmentsAsync.value!;
    final payments = paymentsAsync.value!;
    final materials = materialsAsync.value!;
    final partners = partnersAsync.value!;
    final partnerLedgers = partnerLedgerAsync.value!;

    final unitSummaries = const UnitSalesCalculator().build(
      units: units,
      installments: installments,
      payments: payments,
    );
    final materialsSnapshot = const MaterialsLedgerCalculator().build(materials);
    final partnerHistory = partnerLedgers
        .where((item) => item.propertyId == widget.propertyId)
        .toList();
    final partnerSummaries = const PartnerLedgerCalculator().build(
      partners: partners,
      expenses: const [],
      materialExpenses: materials,
      ledgerEntries: partnerHistory,
    );

    final totalSalesValue =
        unitSummaries.fold<double>(0, (sum, item) => sum + item.totalContractAmount);
    final totalPaidInstallments =
        unitSummaries.fold<double>(0, (sum, item) => sum + item.totalPaidInstallmentsAmount);
    final totalRemainingInstallments = unitSummaries.fold<double>(
      0,
      (sum, item) => sum + item.totalRemainingInstallmentsAmount,
    );
    final overdueInstallments =
        unitSummaries.fold<int>(0, (sum, item) => sum + item.overdueInstallmentsCount);

    return AppShellScaffold(
      title: property.name,
      subtitle: property.location,
      currentIndex: 1,
      actions: [
        IconButton(
          tooltip: 'Add unit sale',
          onPressed: () => _showUnitSheet(),
          icon: const Icon(Icons.add_business_outlined),
        ),
        IconButton(
          tooltip: 'Add supplier invoice',
          onPressed: () => _showMaterialSheet(),
          icon: const Icon(Icons.receipt_long_outlined),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SummaryGrid(
            cards: [
              SummaryCard(
                label: 'Units',
                value: '${units.length}',
                subtitle: 'Tracked residential sales',
                icon: Icons.home_work_outlined,
                emphasis: true,
              ),
              SummaryCard(
                label: 'Sales value',
                value: totalSalesValue.egp,
                subtitle: 'Total contract value',
                icon: Icons.sell_outlined,
              ),
              SummaryCard(
                label: 'Paid installments',
                value: totalPaidInstallments.egp,
                subtitle: 'Collected installment cash',
                icon: Icons.payments_outlined,
              ),
              SummaryCard(
                label: 'Remaining installments',
                value: totalRemainingInstallments.egp,
                subtitle: 'Outstanding installment balance',
                icon: Icons.schedule_outlined,
              ),
              SummaryCard(
                label: 'Supplier dues',
                value: materialsSnapshot.overallRemaining.egp,
                subtitle: 'Unpaid supplier invoices',
                icon: Icons.inventory_2_outlined,
              ),
              SummaryCard(
                label: 'Overdue',
                value: '$overdueInstallments',
                subtitle: 'Late installments requiring follow-up',
                icon: Icons.warning_amber_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final summary in unitSummaries) ...[
            _UnitSalesPanel(
              summary: summary,
              payments: payments.where((item) => item.unitId == summary.unit.id).toList(),
              onEditUnit: () => _showUnitSheet(unit: summary.unit),
              onDeleteUnit: () => _deleteUnit(summary.unit),
              onAddInstallment: () => _showInstallmentSheet(
                unit: summary.unit,
                planId: _planIdFor(summary.unit.id, installments),
                suggestedSequence: summary.installmentRows.length + 1,
              ),
              onEditInstallment: (installment) => _showInstallmentSheet(
                unit: summary.unit,
                planId: installment.planId,
                installment: installment,
              ),
              onDeleteInstallment: _deleteInstallment,
              onViewInstallment: _showInstallmentPaymentsDialog,
              onAddPayment: (installmentId) =>
                  _showPaymentSheet(unit: summary.unit, installmentId: installmentId),
              onEditPayment: (payment) =>
                  _showPaymentSheet(unit: summary.unit, payment: payment),
              onDeletePayment: _deletePayment,
            ),
            const SizedBox(height: 16),
          ],
          FinancialLedgerTable<MaterialExpenseEntry>(
            title: 'Building Materials Ledger',
            subtitle: '${materials.length} invoice(s) - total ${materialsSnapshot.overallTotal.egp}',
            rows: materials,
            addLabel: 'Add invoice',
            onAdd: _showMaterialSheet,
            onEdit: (entry) => _showMaterialSheet(entry: entry),
            onDelete: _deleteMaterial,
            columns: [
              LedgerColumn(label: 'Date', valueBuilder: (row) => Text(row.date.formatShort())),
              LedgerColumn(
                label: 'Material',
                valueBuilder: (row) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(row.itemName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(row.materialCategory.label, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              LedgerColumn(label: 'Supplier', valueBuilder: (row) => Text(row.supplierName)),
              LedgerColumn(label: 'Qty', valueBuilder: (row) => Text('${row.quantity}')),
              LedgerColumn(label: 'Total', valueBuilder: (row) => Text(row.totalPrice.egp)),
              LedgerColumn(label: 'Paid', valueBuilder: (row) => Text(row.amountPaid.egp)),
              LedgerColumn(label: 'Remaining', valueBuilder: (row) => Text(row.amountRemaining.egp)),
              LedgerColumn(
                label: 'Status',
                valueBuilder: (row) => FinancialStatusChip(
                  label: row.status.label,
                  color: _statusColor(row.status),
                ),
              ),
            ],
            totalsFooter: LedgerTotalsFooter(
              children: [
                LedgerFooterValue(label: 'Overall total', value: materialsSnapshot.overallTotal.egp),
                LedgerFooterValue(label: 'Paid', value: materialsSnapshot.overallPaid.egp),
                LedgerFooterValue(label: 'Remaining', value: materialsSnapshot.overallRemaining.egp),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FinancialLedgerTable<SupplierLedgerSummary>(
            title: 'Supplier Summary',
            subtitle: 'Outstanding balances and purchase totals by supplier',
            rows: materialsSnapshot.supplierSummaries,
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
            title: 'Partner Expense Ledger',
            subtitle: 'Protected settlement flow with paid, owed, and balances',
            rows: partnerSummaries,
            columns: [
              LedgerColumn(label: 'Partner', valueBuilder: (row) => Text(row.partner.name)),
              LedgerColumn(label: 'Total paid', valueBuilder: (row) => Text(row.totalPaid.egp)),
              LedgerColumn(label: 'Total owed', valueBuilder: (row) => Text(row.totalOwed.egp)),
              LedgerColumn(label: 'Balance', valueBuilder: (row) => Text(row.balance.egp)),
              LedgerColumn(label: 'Last updated', valueBuilder: (row) => Text(row.lastUpdated.formatShort())),
              LedgerColumn(label: 'Notes', valueBuilder: (row) => Text(row.notes.isEmpty ? '-' : row.notes)),
            ],
            onView: (row) => _showPartnerHistoryDialog(row.partner, partnerHistory),
            onEdit: (row) => _showPartnerLedgerSheet(partner: row.partner),
            addLabel: 'Authorized action',
            onAdd: partners.isEmpty ? null : () => _showPartnerLedgerSheet(partner: partners.first),
          ),
          if (partnerHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            FinancialLedgerTable<PartnerLedgerEntry>(
              title: 'Partner Ledger History',
              subtitle: 'Authorized ledger entries for this property',
              rows: partnerHistory,
              columns: [
                LedgerColumn(
                  label: 'Partner',
                  valueBuilder: (row) => Text(
                    partners.firstWhere((item) => item.id == row.partnerId).name,
                  ),
                ),
                LedgerColumn(label: 'Type', valueBuilder: (row) => Text(row.entryType.label)),
                LedgerColumn(label: 'Amount', valueBuilder: (row) => Text(row.amount.egp)),
                LedgerColumn(label: 'Notes', valueBuilder: (row) => Text(row.notes.isEmpty ? '-' : row.notes)),
              ],
              onDelete: _deletePartnerLedger,
              onEdit: (row) => _showPartnerLedgerSheet(
                partner: partners.firstWhere((item) => item.id == row.partnerId),
                entry: row,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _planIdFor(String unitId, List<Installment> installments) {
    for (final installment in installments) {
      if (installment.unitId == unitId) {
        return installment.planId;
      }
    }
    return '';
  }

  Future<void> _showInstallmentPaymentsDialog(InstallmentComputedRow row) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Installment ${row.installment.sequence} payments'),
        content: SizedBox(
          width: 420,
          child: row.payments.isEmpty
              ? const Text('No payments recorded yet.')
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final payment in row.payments)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(payment.effectivePayerName.isEmpty ? 'Unspecified payer' : payment.effectivePayerName),
                        subtitle: Text(payment.receivedAt.formatShort()),
                        trailing: Text(payment.amount.egp),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _showPartnerHistoryDialog(Partner partner, List<PartnerLedgerEntry> entries) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${partner.name} history'),
        content: SizedBox(
          width: 420,
          child: entries.isEmpty
              ? const Text('No authorized entries yet.')
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final entry in entries)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.entryType.label),
                        subtitle: Text(entry.notes.isEmpty ? '-' : entry.notes),
                        trailing: Text(entry.amount.egp),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Color _statusColor(Enum value) {
    if (value == InstallmentStatus.paid || value == SupplierInvoiceStatus.paid) {
      return Colors.green;
    }
    if (value == InstallmentStatus.partiallyPaid || value == SupplierInvoiceStatus.partiallyPaid) {
      return Colors.orange;
    }
    if (value == InstallmentStatus.overdue || value == SupplierInvoiceStatus.overdue) {
      return Colors.redAccent;
    }
    return Colors.blueGrey;
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 960
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: count == 1 ? 2.5 : 1.6,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

class _UnitSalesPanel extends StatelessWidget {
  const _UnitSalesPanel({
    required this.summary,
    required this.payments,
    required this.onEditUnit,
    required this.onDeleteUnit,
    required this.onAddInstallment,
    required this.onEditInstallment,
    required this.onDeleteInstallment,
    required this.onViewInstallment,
    required this.onAddPayment,
    required this.onEditPayment,
    required this.onDeletePayment,
  });

  final UnitSaleComputedSummary summary;
  final List<PaymentRecord> payments;
  final VoidCallback onEditUnit;
  final VoidCallback onDeleteUnit;
  final VoidCallback onAddInstallment;
  final ValueChanged<Installment> onEditInstallment;
  final ValueChanged<Installment> onDeleteInstallment;
  final ValueChanged<InstallmentComputedRow> onViewInstallment;
  final ValueChanged<String> onAddPayment;
  final ValueChanged<PaymentRecord> onEditPayment;
  final ValueChanged<PaymentRecord> onDeletePayment;

  @override
  Widget build(BuildContext context) {
    final projectedCompletion = summary.projectedCompletionDate == null
        ? 'TBD'
        : summary.projectedCompletionDate!.formatShort();
    final durationDays = summary.remainingDuration.inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Unit ${summary.unit.unitNumber} • ${summary.unit.customerName.isEmpty ? 'Unassigned' : summary.unit.customerName}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(onPressed: onEditUnit, icon: const Icon(Icons.edit_outlined)),
            IconButton(onPressed: onDeleteUnit, icon: const Icon(Icons.delete_outline)),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryGrid(
          cards: [
            SummaryCard(
              label: 'Contract amount',
              value: summary.totalContractAmount.egp,
              subtitle: 'Sale ${summary.unit.saleAmount.egp}',
              icon: Icons.description_outlined,
              emphasis: true,
            ),
            SummaryCard(
              label: 'Down payment',
              value: summary.unit.downPayment.egp,
              subtitle: 'Initial collection',
              icon: Icons.savings_outlined,
            ),
            SummaryCard(
              label: 'Total paid',
              value: summary.totalPaidSoFar.egp,
              subtitle: 'Down payment plus installments',
              icon: Icons.payments_outlined,
            ),
            SummaryCard(
              label: 'Remaining',
              value: summary.totalRemaining.egp,
              subtitle: '${summary.unpaidInstallmentsCount} unpaid installment(s)',
              icon: Icons.schedule_outlined,
            ),
            SummaryCard(
              label: 'Projected completion',
              value: projectedCompletion,
              subtitle: durationDays <= 0 ? 'Complete or due now' : '$durationDays day(s) remaining',
              icon: Icons.event_available_outlined,
            ),
            SummaryCard(
              label: 'Installment status',
              value: '${summary.paidInstallmentsCount}/${summary.totalInstallmentsCount} paid',
              subtitle: '${summary.partiallyPaidInstallmentsCount} partial • ${summary.overdueInstallmentsCount} overdue',
              icon: Icons.table_chart_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        FinancialLedgerTable<InstallmentComputedRow>(
          title: 'Installment Sheet',
          subtitle: '${summary.installmentRows.length} row(s) - remaining ${summary.totalRemainingInstallmentsAmount.egp}',
          rows: summary.installmentRows,
          addLabel: 'Add installment',
          onAdd: onAddInstallment,
          onView: onViewInstallment,
          onEdit: (row) => onEditInstallment(row.installment),
          onDelete: (row) => onDeleteInstallment(row.installment),
          columns: [
            LedgerColumn(label: '#', valueBuilder: (row) => Text('${row.installment.sequence}')),
            LedgerColumn(label: 'Due date', valueBuilder: (row) => Text(row.installment.dueDate.formatShort())),
            LedgerColumn(label: 'Amount due', valueBuilder: (row) => Text(row.installment.amount.egp)),
            LedgerColumn(label: 'Payer', valueBuilder: (row) => Text(row.payerSummary)),
            LedgerColumn(label: 'Amount paid', valueBuilder: (row) => Text(row.amountPaid.egp)),
            LedgerColumn(label: 'Remaining', valueBuilder: (row) => Text(row.remainingAmount.egp)),
            LedgerColumn(
              label: 'Status',
              valueBuilder: (row) => FinancialStatusChip(
                label: row.status.label,
                color: row.status == InstallmentStatus.paid
                    ? Colors.green
                    : row.status == InstallmentStatus.partiallyPaid
                    ? Colors.orange
                    : row.status == InstallmentStatus.overdue
                    ? Colors.redAccent
                    : Colors.blueGrey,
              ),
            ),
            LedgerColumn(label: 'Notes', valueBuilder: (row) => Text(row.installment.notes.isEmpty ? '-' : row.installment.notes)),
          ],
          totalsFooter: LedgerTotalsFooter(
            children: [
              LedgerFooterValue(label: 'Schedule count', value: '${summary.installmentScheduleCount}'),
              LedgerFooterValue(label: 'Paid installments', value: '${summary.paidInstallmentsCount}'),
              LedgerFooterValue(label: 'Partial', value: '${summary.partiallyPaidInstallmentsCount}'),
              LedgerFooterValue(label: 'Overdue', value: '${summary.overdueInstallmentsCount}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FinancialLedgerTable<PaymentRecord>(
          title: 'Installment Payments',
          subtitle: '${payments.length} payment(s) - total ${payments.fold<double>(0, (sum, item) => sum + item.amount).egp}',
          rows: payments,
          columns: [
            LedgerColumn(label: 'Date', valueBuilder: (row) => Text(row.receivedAt.formatShort())),
            LedgerColumn(label: 'Payer', valueBuilder: (row) => Text(row.effectivePayerName.isEmpty ? '-' : row.effectivePayerName)),
            LedgerColumn(label: 'Source', valueBuilder: (row) => Text(row.paymentSource.isEmpty ? '-' : row.paymentSource)),
            LedgerColumn(label: 'Installment', valueBuilder: (row) => Text(row.installmentId ?? '-')),
            LedgerColumn(label: 'Amount', valueBuilder: (row) => Text(row.amount.egp)),
          ],
          onEdit: onEditPayment,
          onDelete: onDeletePayment,
          onAdd: summary.installmentRows.isEmpty ? null : () => onAddPayment(summary.installmentRows.first.installment.id),
          addLabel: 'Record payment',
        ),
      ],
    );
  }
}
