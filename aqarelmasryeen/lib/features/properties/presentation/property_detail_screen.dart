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
import 'package:aqarelmasryeen/features/notifications/data/financial_notification_coordinator.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_ledger_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/partners/domain/partner_ledger_calculator.dart';
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

final propertyDetailsProvider = StreamProvider.autoDispose
    .family<PropertyProject?, String>(
      (ref, propertyId) =>
          ref.watch(propertyRepositoryProvider).watchProperty(propertyId),
    );
final propertyUnitsProvider = StreamProvider.autoDispose
    .family<List<UnitSale>, String>(
      (ref, propertyId) =>
          ref.watch(salesRepositoryProvider).watchByProperty(propertyId),
    );
final propertyInstallmentsProvider = StreamProvider.autoDispose
    .family<List<Installment>, String>(
      (ref, propertyId) => ref
          .watch(installmentRepositoryProvider)
          .watchInstallmentsByProperty(propertyId),
    );
final propertyPaymentsProvider = StreamProvider.autoDispose
    .family<List<PaymentRecord>, String>(
      (ref, propertyId) =>
          ref.watch(paymentRepositoryProvider).watchByProperty(propertyId),
    );
final propertyMaterialsProvider = StreamProvider.autoDispose
    .family<List<MaterialExpenseEntry>, String>(
      (ref, propertyId) => ref
          .watch(materialExpenseRepositoryProvider)
          .watchByProperty(propertyId),
    );
final propertyPartnersProvider = StreamProvider.autoDispose<List<Partner>>(
  (ref) => ref.watch(partnerRepositoryProvider).watchPartners(),
);
final propertyPartnerLedgerProvider =
    StreamProvider.autoDispose<List<PartnerLedgerEntry>>(
      (ref) => ref.watch(partnerLedgerRepositoryProvider).watchAll(),
    );

class PropertyDetailScreen extends ConsumerStatefulWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
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
      builder: (_) =>
          MaterialExpenseFormSheet(propertyId: widget.propertyId, entry: entry),
    );
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('تأكيد'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteUnit(UnitSale unit) async {
    final confirmed = await _confirm(
      'حذف مبيعات الوحدة',
      'سيتم حذف الوحدة مع الأقساط والمدفوعات المرتبطة بها.',
    );
    if (!confirmed) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    await ref.read(salesRepositoryProvider).delete(unit.id);
    await ref
        .read(activityRepositoryProvider)
        .log(
          actorId: session.userId,
          actorName: session.profile?.name ?? 'شريك',
          action: 'unit_deleted',
          entityType: 'unit',
          entityId: unit.id,
          metadata: {'propertyId': widget.propertyId},
        );
  }

  Future<void> _deleteInstallment(Installment installment) async {
    final confirmed = await _confirm(
      'حذف القسط',
      'سيتم حذف القسط والمدفوعات المرتبطة به.',
    );
    if (!confirmed) return;
    await ref
        .read(installmentRepositoryProvider)
        .deleteInstallment(installment.id);
  }

  Future<void> _deletePayment(PaymentRecord payment) async {
    final confirmed = await _confirm(
      'حذف الدفعة',
      'سيتم حذف الدفعة من إجماليات الأقساط.',
    );
    if (!confirmed) return;
    await ref.read(paymentRepositoryProvider).delete(payment.id);
  }

  Future<void> _deleteMaterial(MaterialExpenseEntry entry) async {
    final confirmed = await _confirm(
      'حذف فاتورة مواد',
      'سيتم أرشفة هذه الفاتورة من الجداول النشطة.',
    );
    if (!confirmed) return;
    await ref.read(materialExpenseRepositoryProvider).softDelete(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final propertyAsync = ref.watch(propertyDetailsProvider(widget.propertyId));
    final unitsAsync = ref.watch(propertyUnitsProvider(widget.propertyId));
    final installmentsAsync = ref.watch(
      propertyInstallmentsProvider(widget.propertyId),
    );
    final paymentsAsync = ref.watch(
      propertyPaymentsProvider(widget.propertyId),
    );
    final materialsAsync = ref.watch(
      propertyMaterialsProvider(widget.propertyId),
    );
    final partnersAsync = ref.watch(propertyPartnersProvider);
    final partnerLedgerAsync = ref.watch(propertyPartnerLedgerProvider);

    final hasError =
        propertyAsync.hasError ||
        unitsAsync.hasError ||
        installmentsAsync.hasError ||
        paymentsAsync.hasError ||
        materialsAsync.hasError ||
        partnersAsync.hasError ||
        partnerLedgerAsync.hasError;
    if (hasError) {
      return AppShellScaffold(
        title: 'المشروع',
        subtitle: 'المبيعات والمصاريف',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'تعذر تحميل البيانات المالية',
          message:
              propertyAsync.error?.toString() ??
              unitsAsync.error?.toString() ??
              installmentsAsync.error?.toString() ??
              paymentsAsync.error?.toString() ??
              materialsAsync.error?.toString() ??
              partnersAsync.error?.toString() ??
              partnerLedgerAsync.error?.toString() ??
              'حدث خطأ غير متوقع',
        ),
      );
    }

    final waiting =
        !propertyAsync.hasValue ||
        !unitsAsync.hasValue ||
        !installmentsAsync.hasValue ||
        !paymentsAsync.hasValue ||
        !materialsAsync.hasValue ||
        !partnersAsync.hasValue ||
        !partnerLedgerAsync.hasValue;
    if (waiting) {
      return const AppShellScaffold(
        title: 'المشروع',
        subtitle: 'المبيعات والمصاريف',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final property = propertyAsync.value;
    if (property == null) {
      return const AppShellScaffold(
        title: 'المشروع',
        subtitle: 'المبيعات والمصاريف',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'المشروع غير موجود',
          message: 'هذا المشروع لم يعد متاحاً.',
        ),
      );
    }

    final units = unitsAsync.value!;
    final installments = installmentsAsync.value!;
    final payments = paymentsAsync.value!;
    final materials = materialsAsync.value!;
    final partners = partnersAsync.value!;
    final partnerLedgers = partnerLedgerAsync.value!;
    final session = ref.watch(authSessionProvider).valueOrNull;

    final unitSummaries = const UnitSalesCalculator().build(
      units: units,
      installments: installments,
      payments: payments,
    );
    final materialsSnapshot = const MaterialsLedgerCalculator().build(
      materials,
    );
    final partnerHistory = partnerLedgers
        .where((item) => item.propertyId == widget.propertyId)
        .toList();
    final partnerSummaries = const PartnerLedgerCalculator().build(
      partners: partners,
      expenses: const <ExpenseRecord>[],
      materialExpenses: materials,
      ledgerEntries: partnerHistory,
    );

    final totalSalesValue = unitSummaries.fold<double>(
      0,
      (sum, item) => sum + item.totalContractAmount,
    );
    final totalPaidInstallments = unitSummaries.fold<double>(
      0,
      (sum, item) => sum + item.totalPaidInstallmentsAmount,
    );
    final totalRemainingInstallments = unitSummaries.fold<double>(
      0,
      (sum, item) => sum + item.totalRemainingInstallmentsAmount,
    );
    final overdueInstallments = unitSummaries.fold<int>(
      0,
      (sum, item) => sum + item.overdueInstallmentsCount,
    );

    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(financialNotificationCoordinatorProvider)
            .syncPropertyAlerts(
              userId: session.userId,
              propertyId: widget.propertyId,
              unitSummaries: unitSummaries,
              materials: materials,
            );
      });
    }

    return AppShellScaffold(
      title: property.name,
      subtitle: property.location,
      currentIndex: 1,
      actions: [
        IconButton(
          tooltip: 'إضافة مبيعات وحدة',
          onPressed: () => _showUnitSheet(),
          icon: const Icon(Icons.add_business_outlined),
        ),
        IconButton(
          tooltip: 'إضافة فاتورة مواد',
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
                label: 'الوحدات',
                value: '${units.length}',
                subtitle: 'الوحدات السكنية المسجلة',
                icon: Icons.home_work_outlined,
                emphasis: true,
              ),
              SummaryCard(
                label: 'إجمالي المبيعات',
                value: totalSalesValue.egp,
                subtitle: 'إجمالي قيمة العقود',
                icon: Icons.sell_outlined,
              ),
              SummaryCard(
                label: 'الأقساط المدفوعة',
                value: totalPaidInstallments.egp,
                subtitle: 'إجمالي ما تم تحصيله من الأقساط',
                icon: Icons.payments_outlined,
              ),
              SummaryCard(
                label: 'الأقساط المتبقية',
                value: totalRemainingInstallments.egp,
                subtitle: 'الرصيد المتبقي من الأقساط',
                icon: Icons.schedule_outlined,
              ),
              SummaryCard(
                label: 'مستحقات الموردين',
                value: materialsSnapshot.overallRemaining.egp,
                subtitle: 'الفواتير غير المسددة',
                icon: Icons.inventory_2_outlined,
              ),
              SummaryCard(
                label: 'الأقساط المتأخرة',
                value: '$overdueInstallments',
                subtitle: 'تحتاج متابعة وإشعارات',
                icon: Icons.warning_amber_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          FinancialLedgerTable<UnitSaleComputedSummary>(
            title: 'ورقة مبيعات الوحدات',
            subtitle: 'ملخص المقدم والإجمالي والمتبقي والأقساط لكل وحدة',
            rows: unitSummaries,
            sheetLabel: 'ورقة إكسل مبيعات الوحدات',
            columns: [
              LedgerColumn(
                label: 'الوحدة',
                valueBuilder: (row) => Text(row.unit.unitNumber),
                minWidth: 100,
              ),
              LedgerColumn(
                label: 'العميل',
                valueBuilder: (row) => Text(
                  row.unit.customerName.isEmpty
                      ? 'غير محدد'
                      : row.unit.customerName,
                ),
                minWidth: 170,
              ),
              LedgerColumn(
                label: 'المقدم',
                valueBuilder: (row) => Text(row.unit.downPayment.egp),
                minWidth: 120,
                numeric: true,
              ),
              LedgerColumn(
                label: 'قيمة البيع',
                valueBuilder: (row) => Text(row.unit.saleAmount.egp),
                minWidth: 120,
                numeric: true,
              ),
              LedgerColumn(
                label: 'الإجمالي',
                valueBuilder: (row) => Text(row.totalContractAmount.egp),
                minWidth: 120,
                numeric: true,
              ),
              LedgerColumn(
                label: 'المدفوع من الأقساط',
                valueBuilder: (row) =>
                    Text(row.totalPaidInstallmentsAmount.egp),
                minWidth: 140,
                numeric: true,
              ),
              LedgerColumn(
                label: 'المتبقي من الأقساط',
                valueBuilder: (row) =>
                    Text(row.totalRemainingInstallmentsAmount.egp),
                minWidth: 145,
                numeric: true,
              ),
              LedgerColumn(
                label: 'إجمالي المدفوع',
                valueBuilder: (row) => Text(row.totalPaidSoFar.egp),
                minWidth: 130,
                numeric: true,
              ),
              LedgerColumn(
                label: 'إجمالي المتبقي',
                valueBuilder: (row) => Text(row.totalRemaining.egp),
                minWidth: 130,
                numeric: true,
              ),
              LedgerColumn(
                label: 'عدد الأقساط',
                valueBuilder: (row) => Text(
                  '${row.totalInstallmentsCount}/${row.installmentScheduleCount}',
                ),
                minWidth: 120,
                numeric: true,
              ),
              LedgerColumn(
                label: 'إنهاء الأقساط',
                valueBuilder: (row) => Text(
                  row.projectedCompletionDate == null
                      ? '-'
                      : row.projectedCompletionDate!.formatShort(),
                ),
                minWidth: 125,
              ),
              LedgerColumn(
                label: 'المدة المتبقية',
                valueBuilder: (row) => Text(
                  row.projectedCompletionDate == null
                      ? '-'
                      : '${row.remainingDuration.inDays} يوم',
                ),
                minWidth: 120,
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final summary in unitSummaries) ...[
            _UnitSalesPanel(
              summary: summary,
              payments: payments
                  .where((item) => item.unitId == summary.unit.id)
                  .toList(),
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
              onAddPayment: (installmentId) => _showPaymentSheet(
                unit: summary.unit,
                installmentId: installmentId,
              ),
              onEditPayment: (payment) =>
                  _showPaymentSheet(unit: summary.unit, payment: payment),
              onDeletePayment: _deletePayment,
            ),
            const SizedBox(height: 16),
          ],
          FinancialLedgerTable<MaterialExpenseEntry>(
            title: 'ورقة مصاريف مواد البناء',
            subtitle:
                '${materials.length} فاتورة - الإجمالي ${materialsSnapshot.overallTotal.egp}',
            rows: materials,
            addLabel: 'إضافة فاتورة',
            onAdd: _showMaterialSheet,
            onEdit: (entry) => _showMaterialSheet(entry: entry),
            onDelete: _deleteMaterial,
            sheetLabel: 'ورقة إكسل فواتير الموردين',
            columns: [
              LedgerColumn(
                label: 'التاريخ',
                valueBuilder: (row) => Text(row.date.formatShort()),
                minWidth: 116,
              ),
              LedgerColumn(
                label: 'المورد',
                valueBuilder: (row) => Text(row.supplierName),
                minWidth: 170,
              ),
              LedgerColumn(
                label: 'المادة / الصنف',
                valueBuilder: (row) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      row.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      row.materialCategory.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                minWidth: 220,
              ),
              LedgerColumn(
                label: 'الكمية',
                valueBuilder: (row) => Text('${row.quantity}'),
                minWidth: 88,
                numeric: true,
              ),
              LedgerColumn(
                label: 'سعر الوحدة',
                valueBuilder: (row) => Text(row.unitPrice.egp),
                minWidth: 120,
                numeric: true,
              ),
              LedgerColumn(
                label: 'الإجمالي',
                valueBuilder: (row) => Text(row.totalPrice.egp),
                minWidth: 128,
                numeric: true,
              ),
              LedgerColumn(
                label: 'المدفوع',
                valueBuilder: (row) => Text(row.amountPaid.egp),
                minWidth: 128,
                numeric: true,
              ),
              LedgerColumn(
                label: 'المتبقي',
                valueBuilder: (row) => Text(row.amountRemaining.egp),
                minWidth: 132,
                numeric: true,
              ),
              LedgerColumn(
                label: 'الاستحقاق',
                valueBuilder: (row) => Text(
                  row.dueDate == null ? '-' : row.dueDate!.formatShort(),
                ),
                minWidth: 120,
              ),
              LedgerColumn(
                label: 'الحالة',
                valueBuilder: (row) => FinancialStatusChip(
                  label: row.status.label,
                  color: _statusColor(row.status),
                ),
                minWidth: 128,
              ),
              LedgerColumn(
                label: 'ملاحظات',
                valueBuilder: (row) => Text(
                  row.notes.isEmpty ? '-' : row.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                minWidth: 220,
              ),
            ],
            totalsFooter: LedgerTotalsFooter(
              children: [
                LedgerFooterValue(
                  label: 'إجمالي الفواتير',
                  value: materialsSnapshot.overallTotal.egp,
                ),
                LedgerFooterValue(
                  label: 'إجمالي المدفوع',
                  value: materialsSnapshot.overallPaid.egp,
                ),
                LedgerFooterValue(
                  label: 'إجمالي المتبقي',
                  value: materialsSnapshot.overallRemaining.egp,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FinancialLedgerTable<SupplierLedgerSummary>(
            title: 'ورقة ملخص الموردين',
            subtitle: 'إجمالي المشتريات والمدفوع والمتبقي لكل مورد',
            rows: materialsSnapshot.supplierSummaries,
            sheetLabel: 'ورقة إكسل ملخص الموردين',
            columns: [
              LedgerColumn(
                label: 'المورد',
                valueBuilder: (row) => Text(row.supplierName),
                minWidth: 180,
              ),
              LedgerColumn(
                label: 'عدد الفواتير',
                valueBuilder: (row) => Text('${row.invoiceCount}'),
                minWidth: 100,
                numeric: true,
              ),
              LedgerColumn(
                label: 'إجمالي المشتريات',
                valueBuilder: (row) => Text(row.totalPurchased.egp),
                minWidth: 128,
                numeric: true,
              ),
              LedgerColumn(
                label: 'المدفوع',
                valueBuilder: (row) => Text(row.totalPaid.egp),
                minWidth: 128,
                numeric: true,
              ),
              LedgerColumn(
                label: 'المتبقي',
                valueBuilder: (row) => Text(row.totalRemaining.egp),
                minWidth: 132,
                numeric: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          FinancialLedgerTable<PartnerLedgerSummaryRow>(
            title: 'ورقة الشركاء',
            subtitle: 'عرض فقط للمدفوع والمستحق والرصيد لكل شريك',
            rows: partnerSummaries,
            sheetLabel: 'ورقة إكسل الشركاء',
            columns: [
              LedgerColumn(
                label: 'الشريك',
                valueBuilder: (row) => Text(row.partner.name),
                minWidth: 180,
              ),
              LedgerColumn(
                label: 'إجمالي المدفوع',
                valueBuilder: (row) => Text(row.totalPaid.egp),
                minWidth: 128,
                numeric: true,
              ),
              LedgerColumn(
                label: 'إجمالي المستحق',
                valueBuilder: (row) => Text(row.totalOwed.egp),
                minWidth: 128,
                numeric: true,
              ),
              LedgerColumn(
                label: 'الرصيد',
                valueBuilder: (row) => Text(row.balance.egp),
                minWidth: 132,
                numeric: true,
              ),
              LedgerColumn(
                label: 'آخر تحديث',
                valueBuilder: (row) => Text(row.lastUpdated.formatShort()),
                minWidth: 118,
              ),
              LedgerColumn(
                label: 'ملاحظات',
                valueBuilder: (row) =>
                    Text(row.notes.isEmpty ? '-' : row.notes),
                minWidth: 220,
              ),
            ],
            onView: (row) =>
                _showPartnerHistoryDialog(row.partner, partnerHistory),
          ),
          if (partnerHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            FinancialLedgerTable<PartnerLedgerEntry>(
              title: 'سجل حركة الشركاء',
              subtitle: 'سجل للقراءة فقط داخل هذا المشروع',
              rows: partnerHistory,
              sheetLabel: 'ورقة إكسل سجل الشركاء',
              columns: [
                LedgerColumn(
                  label: 'الشريك',
                  valueBuilder: (row) => Text(
                    partners
                        .firstWhere((item) => item.id == row.partnerId)
                        .name,
                  ),
                  minWidth: 180,
                ),
                LedgerColumn(
                  label: 'النوع',
                  valueBuilder: (row) => Text(row.entryType.label),
                  minWidth: 140,
                ),
                LedgerColumn(
                  label: 'المبلغ',
                  valueBuilder: (row) => Text(row.amount.egp),
                  minWidth: 132,
                  numeric: true,
                ),
                LedgerColumn(
                  label: 'ملاحظات',
                  valueBuilder: (row) =>
                      Text(row.notes.isEmpty ? '-' : row.notes),
                  minWidth: 220,
                ),
              ],
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

  Future<void> _showInstallmentPaymentsDialog(
    InstallmentComputedRow row,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('مدفوعات القسط ${row.installment.sequence}'),
        content: SizedBox(
          width: 420,
          child: row.payments.isEmpty
              ? const Text('لا توجد مدفوعات مسجلة حتى الآن.')
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final payment in row.payments)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          payment.effectivePayerName.isEmpty
                              ? 'دافع غير محدد'
                              : payment.effectivePayerName,
                        ),
                        subtitle: Text(payment.receivedAt.formatShort()),
                        trailing: Text(payment.amount.egp),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _showPartnerHistoryDialog(
    Partner partner,
    List<PartnerLedgerEntry> entries,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('سجل ${partner.name}'),
        content: SizedBox(
          width: 420,
          child: entries.isEmpty
              ? const Text('لا توجد حركات مسجلة حتى الآن.')
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
    if (value == InstallmentStatus.paid ||
        value == SupplierInvoiceStatus.paid) {
      return Colors.green;
    }
    if (value == InstallmentStatus.partiallyPaid ||
        value == SupplierInvoiceStatus.partiallyPaid) {
      return Colors.orange;
    }
    if (value == InstallmentStatus.overdue ||
        value == SupplierInvoiceStatus.overdue) {
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
        ? 'غير محدد'
        : summary.projectedCompletionDate!.formatShort();
    final durationDays = summary.remainingDuration.inDays;
    final installmentLabels = {
      for (final row in summary.installmentRows)
        row.installment.id: 'قسط ${row.installment.sequence}',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'الوحدة ${summary.unit.unitNumber} • ${summary.unit.customerName.isEmpty ? 'عميل غير محدد' : summary.unit.customerName}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: onEditUnit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: onDeleteUnit,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryGrid(
          cards: [
            SummaryCard(
              label: 'الإجمالي',
              value: summary.totalContractAmount.egp,
              subtitle: 'قيمة البيع ${summary.unit.saleAmount.egp}',
              icon: Icons.description_outlined,
              emphasis: true,
            ),
            SummaryCard(
              label: 'المقدم',
              value: summary.unit.downPayment.egp,
              subtitle: 'المبلغ المحصل مقدماً',
              icon: Icons.savings_outlined,
            ),
            SummaryCard(
              label: 'إجمالي المدفوع',
              value: summary.totalPaidSoFar.egp,
              subtitle: 'المقدم + الأقساط المسددة',
              icon: Icons.payments_outlined,
            ),
            SummaryCard(
              label: 'إجمالي المتبقي',
              value: summary.totalRemaining.egp,
              subtitle: '${summary.unpaidInstallmentsCount} أقساط غير مسددة',
              icon: Icons.schedule_outlined,
            ),
            SummaryCard(
              label: 'إنهاء الأقساط',
              value: projectedCompletion,
              subtitle: durationDays <= 0
                  ? 'مستحق الآن أو مكتمل'
                  : '$durationDays يوم متبقٍ',
              icon: Icons.event_available_outlined,
            ),
            SummaryCard(
              label: 'حالة الأقساط',
              value:
                  '${summary.paidInstallmentsCount}/${summary.totalInstallmentsCount} مدفوع',
              subtitle:
                  '${summary.partiallyPaidInstallmentsCount} جزئي • ${summary.overdueInstallmentsCount} متأخر',
              icon: Icons.table_chart_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        FinancialLedgerTable<InstallmentComputedRow>(
          title: 'ورقة أقساط الوحدة',
          subtitle:
              '${summary.installmentRows.length} صف - متبقي ${summary.totalRemainingInstallmentsAmount.egp}',
          rows: summary.installmentRows,
          addLabel: 'إضافة قسط',
          onAdd: onAddInstallment,
          onView: onViewInstallment,
          onEdit: (row) => onEditInstallment(row.installment),
          onDelete: (row) => onDeleteInstallment(row.installment),
          sheetLabel: 'ورقة إكسل جدول الأقساط',
          columns: [
            LedgerColumn(
              label: 'رقم القسط',
              valueBuilder: (row) => Text('${row.installment.sequence}'),
              minWidth: 78,
              numeric: true,
            ),
            LedgerColumn(
              label: 'الاستحقاق',
              valueBuilder: (row) =>
                  Text(row.installment.dueDate.formatShort()),
              minWidth: 118,
            ),
            LedgerColumn(
              label: 'قيمة القسط',
              valueBuilder: (row) => Text(row.installment.amount.egp),
              minWidth: 128,
              numeric: true,
            ),
            LedgerColumn(
              label: 'من دفع',
              valueBuilder: (row) => Text(row.payerSummary),
              minWidth: 180,
            ),
            LedgerColumn(
              label: 'المدفوع',
              valueBuilder: (row) => Text(row.amountPaid.egp),
              minWidth: 128,
              numeric: true,
            ),
            LedgerColumn(
              label: 'المتبقي',
              valueBuilder: (row) => Text(row.remainingAmount.egp),
              minWidth: 132,
              numeric: true,
            ),
            LedgerColumn(
              label: 'الحالة',
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
              minWidth: 128,
            ),
            LedgerColumn(
              label: 'ملاحظات',
              valueBuilder: (row) => Text(
                row.installment.notes.isEmpty ? '-' : row.installment.notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              minWidth: 220,
            ),
          ],
          totalsFooter: LedgerTotalsFooter(
            children: [
              LedgerFooterValue(
                label: 'عدد الأقساط المخطط',
                value: '${summary.installmentScheduleCount}',
              ),
              LedgerFooterValue(
                label: 'الأقساط المدفوعة',
                value: '${summary.paidInstallmentsCount}',
              ),
              LedgerFooterValue(
                label: 'مدفوع جزئي',
                value: '${summary.partiallyPaidInstallmentsCount}',
              ),
              LedgerFooterValue(
                label: 'متأخر',
                value: '${summary.overdueInstallmentsCount}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FinancialLedgerTable<PaymentRecord>(
          title: 'ورقة التحصيل',
          subtitle:
              '${payments.length} دفعة - الإجمالي ${payments.fold<double>(0, (sum, item) => sum + item.amount).egp}',
          rows: payments,
          sheetLabel: 'ورقة إكسل التحصيل',
          columns: [
            LedgerColumn(
              label: 'التاريخ',
              valueBuilder: (row) => Text(row.receivedAt.formatShort()),
              minWidth: 116,
            ),
            LedgerColumn(
              label: 'الوحدة',
              valueBuilder: (_) => Text(summary.unit.unitNumber),
              minWidth: 92,
            ),
            LedgerColumn(
              label: 'العميل / الدافع',
              valueBuilder: (row) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    row.customerName.trim().isEmpty
                        ? summary.unit.customerName
                        : row.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    row.effectivePayerName.isEmpty
                        ? '-'
                        : row.effectivePayerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              minWidth: 190,
            ),
            LedgerColumn(
              label: 'طريقة الدفع',
              valueBuilder: (row) => Text(row.paymentMethod.label),
              minWidth: 130,
            ),
            LedgerColumn(
              label: 'المصدر',
              valueBuilder: (row) =>
                  Text(row.paymentSource.isEmpty ? '-' : row.paymentSource),
              minWidth: 150,
            ),
            LedgerColumn(
              label: 'القسط',
              valueBuilder: (row) => Text(
                row.installmentId == null
                    ? '-'
                    : (installmentLabels[row.installmentId!] ?? 'دفعة خاصة'),
              ),
              minWidth: 110,
            ),
            LedgerColumn(
              label: 'المبلغ',
              valueBuilder: (row) => Text(row.amount.egp),
              minWidth: 128,
              numeric: true,
            ),
            LedgerColumn(
              label: 'ملاحظات',
              valueBuilder: (row) => Text(
                row.notes.isEmpty ? '-' : row.notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              minWidth: 220,
            ),
          ],
          onEdit: onEditPayment,
          onDelete: onDeletePayment,
          onAdd: summary.installmentRows.isEmpty
              ? null
              : () =>
                    onAddPayment(summary.installmentRows.first.installment.id),
          addLabel: 'إضافة دفعة',
        ),
      ],
    );
  }
}
