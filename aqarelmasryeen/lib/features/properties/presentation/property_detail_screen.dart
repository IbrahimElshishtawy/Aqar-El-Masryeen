import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/summary_card.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/domain/materials_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/expense_form_sheet.dart';
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
import 'package:go_router/go_router.dart';

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
final propertyExpensesProvider = StreamProvider.autoDispose
    .family<List<ExpenseRecord>, String>(
      (ref, propertyId) =>
          ref.watch(expenseRepositoryProvider).watchByProperty(propertyId),
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
  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
    this.unitId,
  });

  final String propertyId;
  final String? unitId;

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  final _salesSectionKey = GlobalKey();
  final _expensesSectionKey = GlobalKey();
  int _expensesWorkbookTabIndex = 0;

  Future<void> _showUnitSheet({UnitSale? unit}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => UnitFormSheet(propertyId: widget.propertyId, unit: unit),
    );
  }

  Future<void> _showExpenseSheet({
    ExpenseRecord? expense,
    required List<Partner> partners,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ExpenseFormSheet(
        propertyId: widget.propertyId,
        partners: partners,
        expense: expense,
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
    if (mounted && widget.unitId != null) {
      context.pop();
    }
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

  Future<void> _deleteExpense(ExpenseRecord expense) async {
    final confirmed = await _confirm(
      'حذف المصروف',
      'سيتم حذف هذا المصروف من سجل المصاريف داخل العقار.',
    );
    if (!confirmed) return;
    await ref.read(expenseRepositoryProvider).softDelete(expense.id);
  }

  Future<void> _deleteMaterial(MaterialExpenseEntry entry) async {
    final confirmed = await _confirm(
      'حذف فاتورة مواد',
      'سيتم أرشفة هذه الفاتورة من الجداول النشطة.',
    );
    if (!confirmed) return;
    await ref.read(materialExpenseRepositoryProvider).softDelete(entry.id);
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOutCubic,
      alignment: 0.04,
    );
  }

  Future<void> _showSupplierEntriesSheet(
    SupplierLedgerSummary summary,
    List<MaterialExpenseEntry> rows,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: _MaterialEntriesSheet(
            title: 'شيت ${summary.supplierName}',
            rows: rows,
            onEdit: (entry) => _showMaterialSheet(entry: entry),
            onDelete: _deleteMaterial,
          ),
        ),
      ),
    );
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
    final session = ref.watch(authSessionProvider).valueOrNull;

    if (widget.unitId != null) {
      final hasUnitError =
          propertyAsync.hasError ||
          unitsAsync.hasError ||
          installmentsAsync.hasError ||
          paymentsAsync.hasError;
      if (hasUnitError) {
        return AppShellScaffold(
          title: 'الوحدة',
          subtitle: 'تفاصيل البيع والتحصيل',
          currentIndex: 1,
          child: EmptyStateView(
            title: 'تعذر تحميل بيانات الوحدة',
            message:
                propertyAsync.error?.toString() ??
                unitsAsync.error?.toString() ??
                installmentsAsync.error?.toString() ??
                paymentsAsync.error?.toString() ??
                'حدث خطأ غير متوقع',
          ),
        );
      }

      final waitingForUnit =
          !propertyAsync.hasValue ||
          !unitsAsync.hasValue ||
          !installmentsAsync.hasValue ||
          !paymentsAsync.hasValue;
      if (waitingForUnit) {
        return const AppShellScaffold(
          title: 'الوحدة',
          subtitle: 'تفاصيل البيع والتحصيل',
          currentIndex: 1,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final property = propertyAsync.value;
      if (property == null) {
        return const AppShellScaffold(
          title: 'الوحدة',
          subtitle: 'تفاصيل البيع والتحصيل',
          currentIndex: 1,
          child: EmptyStateView(
            title: 'المشروع غير موجود',
            message: 'لا يمكن فتح الوحدة لأن المشروع غير متاح الآن.',
          ),
        );
      }

      final units = unitsAsync.value!;
      final installments = installmentsAsync.value!;
      final payments = paymentsAsync.value!;
      final unitSummaries = const UnitSalesCalculator().build(
        units: units,
        installments: installments,
        payments: payments,
      );

      UnitSaleComputedSummary? selectedSummary;
      for (final summary in unitSummaries) {
        if (summary.unit.id == widget.unitId) {
          selectedSummary = summary;
          break;
        }
      }

      if (selectedSummary == null) {
        return AppShellScaffold(
          title: property.name,
          subtitle: property.location,
          currentIndex: 1,
          child: const EmptyStateView(
            title: 'الوحدة غير موجودة',
            message: 'هذه الوحدة لم تعد متاحة داخل هذا المشروع.',
          ),
        );
      }

      final UnitSaleComputedSummary summary = selectedSummary;

      return AppShellScaffold(
        title: 'الوحدة ${summary.unit.unitNumber}',
        subtitle: property.name,
        currentIndex: 1,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _UnitIdentitySection(property: property, summary: summary),
            const SizedBox(height: 16),
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
          ],
        ),
      );
    }

    final expensesAsync = ref.watch(
      propertyExpensesProvider(widget.propertyId),
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
        expensesAsync.hasError ||
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
              expensesAsync.error?.toString() ??
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
        !expensesAsync.hasValue ||
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
    final expenses = expensesAsync.value!;
    final materials = materialsAsync.value!;
    final partners = partnersAsync.value!;
    final partnerLedgers = partnerLedgerAsync.value!;

    final unitSummaries = const UnitSalesCalculator().build(
      units: units,
      installments: installments,
      payments: payments,
    );
    final materialsSnapshot = const MaterialsLedgerCalculator().build(
      materials,
    );
    final partnerHistory =
        partnerLedgers
            .where((item) => item.propertyId == widget.propertyId)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final partnerEntriesByPartner = <String, List<PartnerLedgerEntry>>{
      for (final partner in partners)
        partner.id: partnerHistory
            .where((entry) => entry.partnerId == partner.id)
            .toList(),
    };
    final featuredMaterialCategories = [
      MaterialCategory.cement,
      MaterialCategory.brick,
      MaterialCategory.steel,
    ];
    final materialRowsByCategory =
        <MaterialCategory, List<MaterialExpenseEntry>>{
          for (final category in MaterialCategory.values)
            category: materials
                .where((entry) => entry.materialCategory == category)
                .toList(),
        };
    final featuredMaterialTotals = featuredMaterialCategories
        .map(
          (category) => materialsSnapshot.categoryTotals.firstWhere(
            (item) => item.categoryLabel == category.label,
            orElse: () => MaterialCategoryTotal(
              categoryLabel: category.label,
              totalQuantity: 0,
              totalSpending: 0,
            ),
          ),
        )
        .toList();
    final partnerSummaries = const PartnerLedgerCalculator().build(
      partners: partners,
      expenses: expenses,
      materialExpenses: materials,
      ledgerEntries: partnerHistory,
    );

    final totalSalesValue = unitSummaries.fold<double>(
      0,
      (sum, item) => sum + item.totalContractAmount,
    );
    final totalDirectExpenses = expenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
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
          _UnitsOverviewSection(
            summaries: unitSummaries,
            onAddUnit: () => _showUnitSheet(),
            onOpenUnit: (summary) => context.push(
              AppRoutes.propertyUnitDetails(widget.propertyId, summary.unit.id),
            ),
          ),
          const SizedBox(height: 16),
          _SectionShortcuts(
            salesCount: unitSummaries.length,
            salesTotal: totalSalesValue,
            expensesCount:
                expenses.length + materials.length + partnerHistory.length,
            expensesTotal: totalDirectExpenses + materialsSnapshot.overallTotal,
            onOpenSales: () => _scrollToSection(_salesSectionKey),
            onOpenExpenses: () => _scrollToSection(_expensesSectionKey),
          ),
          const SizedBox(height: 16),
          Container(
            key: _salesSectionKey,
            child: _SpreadsheetSectionBanner(
              title: 'شيت مبيعات الوحدات',
              subtitle:
                  'جدول شامل للمقدم وقيمة البيع والإجمالي والمتبقي وعدد الأقساط والمدفوع والمتبقي ومدة إنهاء الأقساط.',
              icon: Icons.table_chart_outlined,
              actionLabel: 'إضافة وحدة',
              onAction: () => _showUnitSheet(),
            ),
          ),
          const SizedBox(height: 16),
          FinancialLedgerTable<UnitSaleComputedSummary>(
            title: 'ورقة مبيعات الوحدات',
            subtitle:
                'ملخص شبيه بالإكسل لكل وحدة سكنية مع حالة الأقساط والمدفوع والمتبقي.',
            rows: unitSummaries,
            sheetLabel: 'شيت مبيعات الوحدات',
            onView: (row) => context.push(
              AppRoutes.propertyUnitDetails(widget.propertyId, row.unit.id),
            ),
            columns: [
              LedgerColumn(
                label: 'الوحدة / العميل',
                valueBuilder: (row) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(row.unit.unitNumber),
                    Text(
                      row.unit.customerName.isEmpty
                          ? 'عميل غير محدد'
                          : row.unit.customerName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                minWidth: 180,
              ),
              LedgerColumn(
                label: 'المقدم',
                valueBuilder: (row) => Text(row.unit.downPayment.egp),
                minWidth: 116,
                numeric: true,
              ),
              LedgerColumn(
                label: 'مبلغ البيع',
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
                label: 'المدفوع',
                valueBuilder: (row) => Text(row.totalPaidSoFar.egp),
                minWidth: 120,
                numeric: true,
              ),
              LedgerColumn(
                label: 'المتبقي',
                valueBuilder: (row) => Text(row.totalRemaining.egp),
                minWidth: 120,
                numeric: true,
              ),
              LedgerColumn(
                label: 'الأقساط المدفوعة',
                valueBuilder: (row) =>
                    Text(row.totalPaidInstallmentsAmount.egp),
                minWidth: 132,
                numeric: true,
              ),
              LedgerColumn(
                label: 'الأقساط المتبقية',
                valueBuilder: (row) =>
                    Text(row.totalRemainingInstallmentsAmount.egp),
                minWidth: 136,
                numeric: true,
              ),
              LedgerColumn(
                label: 'عدد الأقساط',
                valueBuilder: (row) => Text(
                  '${row.totalInstallmentsCount}/${row.installmentScheduleCount}',
                ),
                minWidth: 116,
                numeric: true,
              ),
              LedgerColumn(
                label: 'التنبيه',
                valueBuilder: (row) => FinancialStatusChip(
                  label: _unitAlertLabelForSummary(row),
                  color: _unitAlertColorForSummary(row),
                ),
                minWidth: 120,
              ),
              LedgerColumn(
                label: 'من دفع',
                valueBuilder: (row) => Text(
                  _payerNamesSummary(row),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                minWidth: 180,
              ),
              LedgerColumn(
                label: 'إنهاء الأقساط',
                valueBuilder: (row) => Text(
                  row.projectedCompletionDate == null
                      ? '-'
                      : row.projectedCompletionDate!.formatShort(),
                ),
                minWidth: 124,
              ),
              LedgerColumn(
                label: 'الوقت المتبقي',
                valueBuilder: (row) => Text(
                  row.projectedCompletionDate == null
                      ? '-'
                      : '${row.remainingDuration.inDays} يوم',
                ),
                minWidth: 116,
              ),
            ],
            totalsFooter: LedgerTotalsFooter(
              children: [
                LedgerFooterValue(
                  label: 'إجمالي قيمة المبيعات',
                  value: totalSalesValue.egp,
                ),
                LedgerFooterValue(
                  label: 'إجمالي الأقساط المدفوعة',
                  value: totalPaidInstallments.egp,
                ),
                LedgerFooterValue(
                  label: 'إجمالي الأقساط المتبقية',
                  value: totalRemainingInstallments.egp,
                ),
                LedgerFooterValue(
                  label: 'أقساط متأخرة',
                  value: '$overdueInstallments',
                ),
              ],
            ),
          ),
          Container(
            key: _expensesSectionKey,
            child: _SpreadsheetSectionBanner(
              title: 'شيت مصاريف المشروع',
              subtitle:
                  'هيدر للشركاء وهيدر للموارد داخل نفس صفحة العقار مع جداول تشبه شيت الإكسل وتناسب شاشة الهاتف.',
              icon: Icons.receipt_long_outlined,
              actionLabel: 'إضافة فاتورة مواد',
              onAction: _showMaterialSheet,
            ),
          ),
          const SizedBox(height: 16),
          _ExpensesWorkbookSection(
            currentTabIndex: _expensesWorkbookTabIndex,
            onTabChanged: (index) =>
                setState(() => _expensesWorkbookTabIndex = index),
            currentUserId: session?.userId,
            directExpenses: expenses,
            directExpensesTotal: totalDirectExpenses,
            partners: partners,
            partnerSummaries: partnerSummaries,
            partnerHistory: partnerHistory,
            materials: materials,
            materialsSnapshot: materialsSnapshot,
            featuredMaterialTotals: featuredMaterialTotals,
            featuredMaterialCategories: featuredMaterialCategories,
            materialRowsByCategory: materialRowsByCategory,
            onAddExpense: () => _showExpenseSheet(partners: partners),
            onEditExpense: (expense) =>
                _showExpenseSheet(expense: expense, partners: partners),
            onDeleteExpense: _deleteExpense,
            onEditMaterial: (entry) => _showMaterialSheet(entry: entry),
            onDeleteMaterial: _deleteMaterial,
            onOpenPartnerHistory: (partner) => _showPartnerHistoryDialog(
              partner,
              partnerEntriesByPartner[partner.id] ??
                  const <PartnerLedgerEntry>[],
            ),
            onOpenSupplierSheet: (summary) => _showSupplierEntriesSheet(
              summary,
              materials
                  .where(
                    (entry) =>
                        entry.supplierName.trim() ==
                        summary.supplierName.trim(),
                  )
                  .toList(),
            ),
          ),
          if (_expensesWorkbookTabIndex == -1) ...[
            _SpreadsheetSectionBanner(
              title: 'هيدر الشركاء',
              subtitle:
                  'عرض قراءة فقط لمعرفة كل شريك دفع كام وعليه كام بدون تعديل مباشر.',
              icon: Icons.groups_outlined,
            ),
            const SizedBox(height: 16),
            FinancialLedgerTable<PartnerLedgerSummaryRow>(
              title: 'ورقة الشركاء',
              subtitle: 'المدفوع والمستحق والرصيد لكل شريك داخل هذا العقار.',
              rows: partnerSummaries,
              sheetLabel: 'شيت الشركاء',
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
                  label: 'السجل',
                  valueBuilder: (row) => OutlinedButton.icon(
                    onPressed: () => _showPartnerHistoryDialog(
                      row.partner,
                      partnerEntriesByPartner[row.partner.id] ??
                          const <PartnerLedgerEntry>[],
                    ),
                    icon: const Icon(Icons.table_view_outlined, size: 16),
                    label: const Text('عرض'),
                  ),
                  minWidth: 134,
                ),
                LedgerColumn(
                  label: 'ملاحظات',
                  valueBuilder: (row) =>
                      Text(row.notes.isEmpty ? '-' : row.notes),
                  minWidth: 200,
                ),
              ],
            ),
            if (partnerHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              FinancialLedgerTable<PartnerLedgerEntry>(
                title: 'سجل حركة الشركاء',
                subtitle: 'سجل تفصيلي للقراءة فقط داخل هذا العقار.',
                rows: partnerHistory,
                sheetLabel: 'شيت سجل الشركاء',
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
            const SizedBox(height: 16),
            _SpreadsheetSectionBanner(
              title: 'هيدر الموارد',
              subtitle:
                  'جداول مواد البناء والموردين مقسمة وتوضح اشتريت كام ودفعت كام وباقي عليك كام لكل مورد.',
              icon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 16),
            _SummaryGrid(
              cards: [
                for (final item in featuredMaterialTotals)
                  SummaryCard(
                    label: item.categoryLabel,
                    value: item.totalSpending.egp,
                    subtitle: 'الكمية ${item.totalQuantity.toStringAsFixed(0)}',
                    icon: Icons.category_outlined,
                    emphasis: item.totalSpending > 0,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FinancialLedgerTable<SupplierLedgerSummary>(
              title: 'ورقة الموردين',
              subtitle: 'دفعت كام لكل تاجر وباقي عليك كام لكل تاجر.',
              rows: materialsSnapshot.supplierSummaries,
              sheetLabel: 'شيت الموردين',
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
                  minWidth: 132,
                  numeric: true,
                ),
                LedgerColumn(
                  label: 'دفعت',
                  valueBuilder: (row) => Text(row.totalPaid.egp),
                  minWidth: 120,
                  numeric: true,
                ),
                LedgerColumn(
                  label: 'عليك',
                  valueBuilder: (row) => Text(row.totalRemaining.egp),
                  minWidth: 120,
                  numeric: true,
                ),
              ],
              totalsFooter: LedgerTotalsFooter(
                children: [
                  LedgerFooterValue(
                    label: 'إجمالي الموارد',
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
            FinancialLedgerTable<MaterialCategoryTotal>(
              title: 'تقسيم مواد البناء',
              subtitle: 'أسمنت وطوب وحديد مع إجمالي الكميات والتكلفة.',
              rows: featuredMaterialTotals,
              sheetLabel: 'شيت تقسيم مواد البناء',
              columns: [
                LedgerColumn(
                  label: 'الفئة',
                  valueBuilder: (row) => Text(row.categoryLabel),
                  minWidth: 140,
                ),
                LedgerColumn(
                  label: 'إجمالي الكمية',
                  valueBuilder: (row) =>
                      Text(row.totalQuantity.toStringAsFixed(0)),
                  minWidth: 116,
                  numeric: true,
                ),
                LedgerColumn(
                  label: 'إجمالي التكلفة',
                  valueBuilder: (row) => Text(row.totalSpending.egp),
                  minWidth: 132,
                  numeric: true,
                ),
              ],
            ),
            for (final category in featuredMaterialCategories)
              if ((materialRowsByCategory[category] ??
                      const <MaterialExpenseEntry>[])
                  .isNotEmpty) ...[
                const SizedBox(height: 16),
                _MaterialEntriesSheet(
                  title: 'شيت ${category.label}',
                  rows:
                      materialRowsByCategory[category] ??
                      const <MaterialExpenseEntry>[],
                  onEdit: (entry) => _showMaterialSheet(entry: entry),
                  onDelete: _deleteMaterial,
                ),
              ],
            if (materials
                .where(
                  (entry) => !featuredMaterialCategories.contains(
                    entry.materialCategory,
                  ),
                )
                .isNotEmpty) ...[
              const SizedBox(height: 16),
              _MaterialEntriesSheet(
                title: 'شيت مواد أخرى',
                rows: materials
                    .where(
                      (entry) => !featuredMaterialCategories.contains(
                        entry.materialCategory,
                      ),
                    )
                    .toList(),
                onEdit: (entry) => _showMaterialSheet(entry: entry),
                onDelete: _deleteMaterial,
              ),
            ],
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

  String _payerNamesSummary(UnitSaleComputedSummary summary) {
    final names = summary.installmentRows
        .map((row) => row.payerSummary)
        .where((name) => name != '-')
        .toSet()
        .toList();
    if (names.isEmpty) {
      return '-';
    }
    return names.join('، ');
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
}

int _dueSoonInstallmentsCountForSummary(UnitSaleComputedSummary summary) {
  return summary.installmentRows.where((row) {
    if (row.status != InstallmentStatus.pending) {
      return false;
    }
    final daysUntilDue = row.installment.dueDate
        .difference(DateTime.now())
        .inDays;
    return daysUntilDue >= 0 && daysUntilDue <= 7;
  }).length;
}

String _unitAlertLabelForSummary(UnitSaleComputedSummary summary) {
  if (summary.overdueInstallmentsCount > 0) {
    return '${summary.overdueInstallmentsCount} متأخر';
  }
  final dueSoonCount = _dueSoonInstallmentsCountForSummary(summary);
  if (dueSoonCount > 0) {
    return '$dueSoonCount قريب';
  }
  if (summary.isFullyPaid) {
    return 'مكتمل';
  }
  return 'مستقر';
}

Color _unitAlertColorForSummary(UnitSaleComputedSummary summary) {
  if (summary.overdueInstallmentsCount > 0) {
    return Colors.redAccent;
  }
  if (_dueSoonInstallmentsCountForSummary(summary) > 0) {
    return Colors.orange;
  }
  if (summary.isFullyPaid) {
    return Colors.green;
  }
  return Colors.blueGrey;
}

String _installmentAlertLabelForRow(InstallmentComputedRow row) {
  if (row.status == InstallmentStatus.overdue) {
    return 'متأخر';
  }
  if (row.status == InstallmentStatus.paid) {
    return 'تم السداد';
  }
  final daysUntilDue = row.installment.dueDate
      .difference(DateTime.now())
      .inDays;
  if (daysUntilDue >= 0 && daysUntilDue <= 7) {
    return 'قريب';
  }
  return 'متابعة';
}

Color _installmentAlertColorForRow(InstallmentComputedRow row) {
  if (row.status == InstallmentStatus.overdue) {
    return Colors.redAccent;
  }
  if (row.status == InstallmentStatus.paid) {
    return Colors.green;
  }
  final daysUntilDue = row.installment.dueDate
      .difference(DateTime.now())
      .inDays;
  if (daysUntilDue >= 0 && daysUntilDue <= 7) {
    return Colors.orange;
  }
  return Colors.blueGrey;
}

class _ExpensesWorkbookSection extends StatelessWidget {
  const _ExpensesWorkbookSection({
    required this.currentTabIndex,
    required this.onTabChanged,
    required this.currentUserId,
    required this.directExpenses,
    required this.directExpensesTotal,
    required this.partners,
    required this.partnerSummaries,
    required this.partnerHistory,
    required this.materials,
    required this.materialsSnapshot,
    required this.featuredMaterialTotals,
    required this.featuredMaterialCategories,
    required this.materialRowsByCategory,
    required this.onAddExpense,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onEditMaterial,
    required this.onDeleteMaterial,
    required this.onOpenPartnerHistory,
    required this.onOpenSupplierSheet,
  });

  final int currentTabIndex;
  final ValueChanged<int> onTabChanged;
  final String? currentUserId;
  final List<ExpenseRecord> directExpenses;
  final double directExpensesTotal;
  final List<Partner> partners;
  final List<PartnerLedgerSummaryRow> partnerSummaries;
  final List<PartnerLedgerEntry> partnerHistory;
  final List<MaterialExpenseEntry> materials;
  final MaterialsLedgerSnapshot materialsSnapshot;
  final List<MaterialCategoryTotal> featuredMaterialTotals;
  final List<MaterialCategory> featuredMaterialCategories;
  final Map<MaterialCategory, List<MaterialExpenseEntry>>
  materialRowsByCategory;
  final VoidCallback onAddExpense;
  final ValueChanged<ExpenseRecord> onEditExpense;
  final ValueChanged<ExpenseRecord> onDeleteExpense;
  final ValueChanged<MaterialExpenseEntry> onEditMaterial;
  final ValueChanged<MaterialExpenseEntry> onDeleteMaterial;
  final ValueChanged<Partner> onOpenPartnerHistory;
  final ValueChanged<SupplierLedgerSummary> onOpenSupplierSheet;

  @override
  Widget build(BuildContext context) {
    final partnerPaidTotal = partnerSummaries.fold<double>(
      0,
      (sum, row) => sum + row.totalPaid,
    );
    final partnerOwedTotal = partnerSummaries.fold<double>(
      0,
      (sum, row) => sum + row.totalOwed,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هيدر المصاريف',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'اختَر الشيت المطلوب: الشركاء للمصاريف والسجلات، أو الموارد لفواتير الموردين ومواد البناء.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 640;
                  final tabs = [
                    _WorkbookTabButton(
                      label: 'الشركاء',
                      subtitle: 'المصاريف والسجلات',
                      icon: Icons.groups_outlined,
                      selected: currentTabIndex == 0,
                      onTap: () => onTabChanged(0),
                    ),
                    _WorkbookTabButton(
                      label: 'الموارد',
                      subtitle: 'الموردين ومواد البناء',
                      icon: Icons.inventory_2_outlined,
                      selected: currentTabIndex == 1,
                      onTap: () => onTabChanged(1),
                    ),
                  ];

                  if (compact) {
                    return Column(
                      children: [tabs[0], const SizedBox(height: 12), tabs[1]],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: tabs[0]),
                      const SizedBox(width: 12),
                      Expanded(child: tabs[1]),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (currentTabIndex == 0) ...[
          _SummaryGrid(
            cards: [
              SummaryCard(
                label: 'المصاريف المباشرة',
                value: directExpensesTotal.egp,
                subtitle: '${directExpenses.length} حركة داخل العقار',
                icon: Icons.receipt_long_outlined,
                emphasis: true,
              ),
              SummaryCard(
                label: 'المدفوع من الشركاء',
                value: partnerPaidTotal.egp,
                subtitle: 'يشمل المصاريف المباشرة والتسويات',
                icon: Icons.account_balance_wallet_outlined,
              ),
              SummaryCard(
                label: 'المتبقي على الشركاء',
                value: partnerOwedTotal.egp,
                subtitle: 'عرض فقط بدون تعديل مباشر على الشريك',
                icon: Icons.pending_actions_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          FinancialLedgerTable<ExpenseRecord>(
            title: 'ورقة مصاريف العقار',
            subtitle:
                'شيت إكسل للمصاريف المباشرة والمعلومات المرتبطة بكل حركة.',
            rows: [...directExpenses]..sort((a, b) => b.date.compareTo(a.date)),
            onAdd: onAddExpense,
            addLabel: 'إضافة مصروف',
            onEdit: onEditExpense,
            onDelete: onDeleteExpense,
            sheetLabel: 'شيت مصاريف العقار',
            columns: [
              LedgerColumn(
                label: 'التاريخ',
                valueBuilder: (row) => Text(row.date.formatShort()),
                minWidth: 116,
              ),
              LedgerColumn(
                label: 'البيان',
                valueBuilder: (row) => Text(
                  row.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                minWidth: 190,
              ),
              LedgerColumn(
                label: 'الفئة',
                valueBuilder: (row) => Text(row.category.label),
                minWidth: 130,
              ),
              LedgerColumn(
                label: 'الدافع',
                valueBuilder: (row) {
                  Partner? partner;
                  for (final item in partners) {
                    if (item.id == row.paidByPartnerId) {
                      partner = item;
                      break;
                    }
                  }
                  return _PartnerIdentityCell(
                    name: partner?.name ?? 'غير محدد',
                    highlightAsMe:
                        partner != null && partner.userId == currentUserId,
                  );
                },
                minWidth: 170,
              ),
              LedgerColumn(
                label: 'طريقة الدفع',
                valueBuilder: (row) => Text(row.paymentMethod.label),
                minWidth: 130,
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
            totalsFooter: LedgerTotalsFooter(
              children: [
                LedgerFooterValue(
                  label: 'إجمالي المصاريف المباشرة',
                  value: directExpensesTotal.egp,
                ),
                LedgerFooterValue(
                  label: 'عدد السجلات',
                  value: '${directExpenses.length}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FinancialLedgerTable<PartnerLedgerSummaryRow>(
            title: 'ورقة الشركاء',
            subtitle:
                'كل شريك ظاهر بوضوح: دفع كام، عليه كام، والرصيد الحالي داخل العقار.',
            rows: partnerSummaries,
            sheetLabel: 'شيت الشركاء',
            columns: [
              LedgerColumn(
                label: 'الشريك',
                valueBuilder: (row) => _PartnerIdentityCell(
                  name: row.partner.name,
                  highlightAsMe: row.partner.userId == currentUserId,
                ),
                minWidth: 180,
              ),
              LedgerColumn(
                label: 'إجمالي المدفوع',
                valueBuilder: (row) => Text(row.totalPaid.egp),
                minWidth: 132,
                numeric: true,
              ),
              LedgerColumn(
                label: 'إجمالي المستحق',
                valueBuilder: (row) => Text(row.totalOwed.egp),
                minWidth: 132,
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
                label: 'السجل',
                valueBuilder: (row) => OutlinedButton.icon(
                  onPressed: () => onOpenPartnerHistory(row.partner),
                  icon: const Icon(Icons.table_view_outlined, size: 16),
                  label: const Text('عرض'),
                ),
                minWidth: 132,
              ),
              LedgerColumn(
                label: 'ملاحظات',
                valueBuilder: (row) => Text(
                  row.notes.isEmpty ? '-' : row.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                minWidth: 210,
              ),
            ],
          ),
          if (partnerHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            FinancialLedgerTable<PartnerLedgerEntry>(
              title: 'سجل حركة الشركاء',
              subtitle:
                  'قراءة فقط لسجل الشريك داخل هذا العقار بدون إضافة أو تعديل مباشر.',
              rows: partnerHistory,
              sheetLabel: 'شيت سجل الشركاء',
              columns: [
                LedgerColumn(
                  label: 'الشريك',
                  valueBuilder: (row) {
                    Partner? partner;
                    for (final item in partners) {
                      if (item.id == row.partnerId) {
                        partner = item;
                        break;
                      }
                    }
                    return _PartnerIdentityCell(
                      name: partner?.name ?? 'غير محدد',
                      highlightAsMe:
                          partner != null && partner.userId == currentUserId,
                    );
                  },
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
                  valueBuilder: (row) => Text(
                    row.notes.isEmpty ? '-' : row.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  minWidth: 220,
                ),
              ],
            ),
          ],
        ] else ...[
          _SummaryGrid(
            cards: [
              for (final item in featuredMaterialTotals)
                SummaryCard(
                  label: item.categoryLabel,
                  value: item.totalSpending.egp,
                  subtitle: 'الكمية ${item.totalQuantity.toStringAsFixed(0)}',
                  icon: Icons.category_outlined,
                  emphasis: item.totalSpending > 0,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _MaterialEntriesSheet(
            title: 'ورقة الموارد',
            rows: materials,
            onEdit: onEditMaterial,
            onDelete: onDeleteMaterial,
          ),
          const SizedBox(height: 16),
          FinancialLedgerTable<SupplierLedgerSummary>(
            title: 'ورقة الموردين',
            subtitle:
                'شوف بسرعة كل تاجر اشتريت منه بكام، دفعت له كام، ولسه عليك كام.',
            rows: materialsSnapshot.supplierSummaries,
            sheetLabel: 'شيت الموردين',
            onView: onOpenSupplierSheet,
            columns: [
              LedgerColumn(
                label: 'المورد',
                valueBuilder: (row) => Text(row.supplierName),
                minWidth: 180,
              ),
              LedgerColumn(
                label: 'عدد الفواتير',
                valueBuilder: (row) => Text('${row.invoiceCount}'),
                minWidth: 108,
                numeric: true,
              ),
              LedgerColumn(
                label: 'إجمالي المشتريات',
                valueBuilder: (row) => Text(row.totalPurchased.egp),
                minWidth: 138,
                numeric: true,
              ),
              LedgerColumn(
                label: 'دفعت',
                valueBuilder: (row) => Text(row.totalPaid.egp),
                minWidth: 120,
                numeric: true,
              ),
              LedgerColumn(
                label: 'عليك',
                valueBuilder: (row) => Text(row.totalRemaining.egp),
                minWidth: 120,
                numeric: true,
              ),
            ],
            totalsFooter: LedgerTotalsFooter(
              children: [
                LedgerFooterValue(
                  label: 'إجمالي الموارد',
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
          FinancialLedgerTable<MaterialCategoryTotal>(
            title: 'تقسيم مواد البناء',
            subtitle:
                'الأسمنت والطوب والحديد في صورة شيتات منفصلة مع الإجماليات.',
            rows: featuredMaterialTotals,
            sheetLabel: 'شيت تقسيم مواد البناء',
            columns: [
              LedgerColumn(
                label: 'الفئة',
                valueBuilder: (row) => Text(row.categoryLabel),
                minWidth: 150,
              ),
              LedgerColumn(
                label: 'إجمالي الكمية',
                valueBuilder: (row) =>
                    Text(row.totalQuantity.toStringAsFixed(0)),
                minWidth: 118,
                numeric: true,
              ),
              LedgerColumn(
                label: 'إجمالي التكلفة',
                valueBuilder: (row) => Text(row.totalSpending.egp),
                minWidth: 138,
                numeric: true,
              ),
            ],
          ),
          for (final category in featuredMaterialCategories)
            if ((materialRowsByCategory[category] ??
                    const <MaterialExpenseEntry>[])
                .isNotEmpty) ...[
              const SizedBox(height: 16),
              _MaterialEntriesSheet(
                title: 'شيت ${category.label}',
                rows:
                    materialRowsByCategory[category] ??
                    const <MaterialExpenseEntry>[],
                onEdit: onEditMaterial,
                onDelete: onDeleteMaterial,
              ),
            ],
          if (materials
              .where(
                (entry) => !featuredMaterialCategories.contains(
                  entry.materialCategory,
                ),
              )
              .isNotEmpty) ...[
            const SizedBox(height: 16),
            _MaterialEntriesSheet(
              title: 'شيت مواد أخرى',
              rows: materials
                  .where(
                    (entry) => !featuredMaterialCategories.contains(
                      entry.materialCategory,
                    ),
                  )
                  .toList(),
              onEdit: onEditMaterial,
              onDelete: onDeleteMaterial,
            ),
          ],
        ],
      ],
    );
  }
}

class _WorkbookTabButton extends StatelessWidget {
  const _WorkbookTabButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFFD8D8D2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF5EC) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFDCEBD5)
                    : const Color(0xFFF3F4EF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected
                    ? const Color(0xFF2E6B3F)
                    : const Color(0xFF66715F),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerIdentityCell extends StatelessWidget {
  const _PartnerIdentityCell({required this.name, required this.highlightAsMe});

  final String name;
  final bool highlightAsMe;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(name),
        if (highlightAsMe)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE7EFE3),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'أنا',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2E6B3F),
              ),
            ),
          ),
      ],
    );
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
            : constraints.maxWidth >= 300
            ? 2
            : 1;
        final childAspectRatio = count == 1
            ? 1.45
            : constraints.maxWidth < 620
            ? 1.02
            : 1.55;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

class _UnitsOverviewSection extends StatelessWidget {
  const _UnitsOverviewSection({
    required this.summaries,
    required this.onAddUnit,
    required this.onOpenUnit,
  });

  final List<UnitSaleComputedSummary> summaries;
  final VoidCallback onAddUnit;
  final ValueChanged<UnitSaleComputedSummary> onOpenUnit;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'الوحدات',
      subtitle: summaries.isEmpty
          ? 'أضيفي وحدة أولًا ثم افتحي تفاصيل الأقساط والتحصيل.'
          : '${summaries.length} وحدة جاهزة للعرض قبل التفاصيل',
      trailing: FilledButton.icon(
        onPressed: onAddUnit,
        icon: const Icon(Icons.add),
        label: const Text('إضافة وحدة'),
      ),
      child: summaries.isEmpty
          ? const EmptyStateView(
              title: 'لا توجد وحدات بعد',
              message:
                  'ستظهر هنا كروت الوحدات بمجرد إضافة أول وحدة داخل العقار.',
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1100
                    ? 3
                    : constraints.maxWidth >= 700
                    ? 2
                    : 1;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: summaries.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: columns == 1
                        ? 1.18
                        : columns == 2
                        ? 1.02
                        : 1.08,
                  ),
                  itemBuilder: (context, index) => _UnitOverviewCard(
                    summary: summaries[index],
                    onTap: () => onOpenUnit(summaries[index]),
                  ),
                );
              },
            ),
    );
  }
}

class _UnitOverviewCard extends StatelessWidget {
  const _UnitOverviewCard({required this.summary, required this.onTap});

  final UnitSaleComputedSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerName = summary.unit.customerName.trim().isEmpty
        ? 'عميل غير محدد'
        : summary.unit.customerName;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDF9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD8D8D2)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الوحدة ${summary.unit.unitNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FinancialStatusChip(
                  label: _unitAlertLabelForSummary(summary),
                  color: _unitAlertColorForSummary(summary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _UnitMetricChip(
                  label: 'الإجمالي',
                  value: summary.totalContractAmount.egp,
                ),
                _UnitMetricChip(
                  label: 'المدفوع',
                  value: summary.totalPaidSoFar.egp,
                ),
                _UnitMetricChip(
                  label: 'المتبقي',
                  value: summary.totalRemaining.egp,
                ),
                _UnitMetricChip(
                  label: 'الأقساط',
                  value:
                      '${summary.paidInstallmentsCount}/${summary.totalInstallmentsCount}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonalIcon(
                onPressed: onTap,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('فتح التفاصيل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitMetricChip extends StatelessWidget {
  const _UnitMetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _UnitIdentitySection extends StatelessWidget {
  const _UnitIdentitySection({required this.property, required this.summary});

  final PropertyProject property;
  final UnitSaleComputedSummary summary;

  @override
  Widget build(BuildContext context) {
    final unit = summary.unit;
    final customerName = unit.customerName.trim().isEmpty
        ? 'عميل غير محدد'
        : unit.customerName;
    final customerPhone = unit.customerPhone.trim().isEmpty
        ? '-'
        : unit.customerPhone;

    return AppPanel(
      title: 'بيانات الوحدة',
      subtitle: '${property.name} • ${property.location}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _UnitMetricChip(label: 'العميل', value: customerName),
              _UnitMetricChip(label: 'الهاتف', value: customerPhone),
              _UnitMetricChip(label: 'النوع', value: unit.unitType.label),
              _UnitMetricChip(label: 'الدور', value: '${unit.floor}'),
              _UnitMetricChip(
                label: 'المساحة',
                value: '${_formatUnitArea(unit.area)} م²',
              ),
              _UnitMetricChip(
                label: 'نظام السداد',
                value: unit.paymentPlanType.label,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FinancialStatusChip(
                label: unit.status.label,
                color: _unitStatusColor(unit.status),
              ),
              FinancialStatusChip(
                label: _unitAlertLabelForSummary(summary),
                color: _unitAlertColorForSummary(summary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatUnitArea(double area) {
  final hasFraction = area.truncateToDouble() != area;
  return area.toStringAsFixed(hasFraction ? 1 : 0);
}

Color _unitStatusColor(UnitStatus status) {
  switch (status) {
    case UnitStatus.available:
      return Colors.blueGrey;
    case UnitStatus.reserved:
      return Colors.orange;
    case UnitStatus.sold:
      return Colors.green;
    case UnitStatus.cancelled:
      return Colors.redAccent;
  }
}

class _SectionShortcuts extends StatelessWidget {
  const _SectionShortcuts({
    required this.salesCount,
    required this.salesTotal,
    required this.expensesCount,
    required this.expensesTotal,
    required this.onOpenSales,
    required this.onOpenExpenses,
  });

  final int salesCount;
  final double salesTotal;
  final int expensesCount;
  final double expensesTotal;
  final VoidCallback onOpenSales;
  final VoidCallback onOpenExpenses;

  @override
  Widget build(BuildContext context) {
    final salesCard = _SectionShortcutCard(
      title: 'المبيعات',
      subtitle: 'افتح شيت المبيعات والأقساط والتحصيل للوحدات السكنية.',
      value: '$salesCount وحدة',
      secondaryValue: salesTotal.egp,
      icon: Icons.sell_outlined,
      color: const Color(0xFF1F6F5E),
      actionLabel: 'فتح المبيعات',
      onTap: onOpenSales,
    );
    final expensesCard = _SectionShortcutCard(
      title: 'المصاريف',
      subtitle: 'افتح هيدر الشركاء وهيدر الموارد وجداول المواد والموردين.',
      value: '$expensesCount سجل',
      secondaryValue: expensesTotal.egp,
      icon: Icons.receipt_long_outlined,
      color: const Color(0xFF8A5A1E),
      actionLabel: 'فتح المصاريف',
      onTap: onOpenExpenses,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = constraints.maxWidth < 760;
        if (vertical) {
          return Column(
            children: [salesCard, const SizedBox(height: 12), expensesCard],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: salesCard),
            const SizedBox(width: 12),
            Expanded(child: expensesCard),
          ],
        );
      },
    );
  }
}

class _SectionShortcutCard extends StatelessWidget {
  const _SectionShortcutCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.secondaryValue,
    required this.icon,
    required this.color,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String value;
  final String secondaryValue;
  final IconData icon;
  final Color color;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InlineInfoChip(label: 'الحجم', value: value, color: color),
              _InlineInfoChip(
                label: 'الإجمالي',
                value: secondaryValue,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_downward_rounded),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineInfoChip extends StatelessWidget {
  const _InlineInfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SpreadsheetSectionBanner extends StatelessWidget {
  const _SpreadsheetSectionBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final action = onAction == null || actionLabel == null
              ? null
              : FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add),
                  label: Text(actionLabel!),
                );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF5EC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: const Color(0xFF2E6B3F)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (action != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: action),
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF5EC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF2E6B3F)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[const SizedBox(width: 12), action],
            ],
          );
        },
      ),
    );
  }
}

class _MaterialEntriesSheet extends StatelessWidget {
  const _MaterialEntriesSheet({
    required this.title,
    required this.rows,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final List<MaterialExpenseEntry> rows;
  final ValueChanged<MaterialExpenseEntry> onEdit;
  final ValueChanged<MaterialExpenseEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final sortedRows = [...rows]..sort((a, b) => b.date.compareTo(a.date));
    final total = sortedRows.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    final paid = sortedRows.fold<double>(
      0,
      (sum, item) => sum + item.amountPaid,
    );
    final remaining = sortedRows.fold<double>(
      0,
      (sum, item) => sum + item.amountRemaining,
    );

    return FinancialLedgerTable<MaterialExpenseEntry>(
      title: title,
      subtitle: '${sortedRows.length} صف - الإجمالي ${total.egp}',
      rows: sortedRows,
      onEdit: onEdit,
      onDelete: onDelete,
      sheetLabel: title,
      columns: [
        LedgerColumn(
          label: 'التاريخ',
          valueBuilder: (row) => Text(row.date.formatShort()),
          minWidth: 116,
        ),
        LedgerColumn(
          label: 'الصنف',
          valueBuilder: (row) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(row.itemName, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                row.materialCategory.label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          minWidth: 170,
        ),
        LedgerColumn(
          label: 'الكمية',
          valueBuilder: (row) => Text(row.quantity.toStringAsFixed(0)),
          minWidth: 90,
          numeric: true,
        ),
        LedgerColumn(
          label: 'المورد',
          valueBuilder: (row) => Text(row.supplierName),
          minWidth: 170,
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
          minWidth: 120,
          numeric: true,
        ),
        LedgerColumn(
          label: 'دفعت',
          valueBuilder: (row) => Text(row.amountPaid.egp),
          minWidth: 116,
          numeric: true,
        ),
        LedgerColumn(
          label: 'عليك',
          valueBuilder: (row) => Text(row.amountRemaining.egp),
          minWidth: 116,
          numeric: true,
        ),
        LedgerColumn(
          label: 'الحالة',
          valueBuilder: (row) => FinancialStatusChip(
            label: row.status.label,
            color: _entryStatusColor(row.status),
          ),
          minWidth: 128,
        ),
      ],
      totalsFooter: LedgerTotalsFooter(
        children: [
          LedgerFooterValue(label: 'إجمالي المشتريات', value: total.egp),
          LedgerFooterValue(label: 'إجمالي المدفوع', value: paid.egp),
          LedgerFooterValue(label: 'إجمالي المتبقي', value: remaining.egp),
        ],
      ),
    );
  }

  Color _entryStatusColor(SupplierInvoiceStatus status) {
    switch (status) {
      case SupplierInvoiceStatus.paid:
        return Colors.green;
      case SupplierInvoiceStatus.partiallyPaid:
        return Colors.orange;
      case SupplierInvoiceStatus.overdue:
        return Colors.redAccent;
      case SupplierInvoiceStatus.unpaid:
        return Colors.blueGrey;
    }
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
          forceTableLayout: true,
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
              label: 'التنبيه',
              valueBuilder: (row) => FinancialStatusChip(
                label: _installmentAlertLabelForRow(row),
                color: _installmentAlertColorForRow(row),
              ),
              minWidth: 120,
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
          forceTableLayout: true,
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
