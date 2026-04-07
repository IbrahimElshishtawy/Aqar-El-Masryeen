import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/domain/materials_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/expense_form_sheet.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/material_expense_form_sheet.dart';
import 'package:aqarelmasryeen/features/installments/data/installment_repository.dart';
import 'package:aqarelmasryeen/features/installments/presentation/installment_form_sheet.dart';
import 'package:aqarelmasryeen/features/notifications/data/financial_notification_coordinator.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/payments/presentation/payment_form_sheet.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/property_expenses_workspace.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/property_material_entries_table.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/property_sales_workspace.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/property_unit_detail_view.dart';
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
  int _primaryTabIndex = 0;
  int _expensesLedgerIndex = 0;

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

  Future<void> _showInstallmentSheet({
    required PropertyUnitViewData data,
    Installment? installment,
    int? suggestedSequence,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => InstallmentFormSheet(
        propertyId: widget.propertyId,
        unitId: data.summary.unit.id,
        planId: installment?.planId ?? data.planId,
        installment: installment,
        suggestedSequence: suggestedSequence,
      ),
    );
  }

  Future<void> _showPaymentSheet({
    required PropertyUnitViewData data,
    String? installmentId,
    PaymentRecord? payment,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PaymentFormSheet(
        propertyId: widget.propertyId,
        payment: payment,
        installmentId: payment?.installmentId ?? installmentId,
        initialUnitId: data.summary.unit.unitNumber,
      ),
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
      'حذف الوحدة',
      'سيتم حذف الوحدة مع الأقساط والمدفوعات المرتبطة بها.',
    );
    if (!confirmed) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

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
    if (!confirmed) {
      return;
    }
    await ref
        .read(installmentRepositoryProvider)
        .deleteInstallment(installment.id);
  }

  Future<void> _deletePayment(PaymentRecord payment) async {
    final confirmed = await _confirm(
      'حذف الدفعة',
      'سيتم حذف هذه الدفعة من التحصيلات.',
    );
    if (!confirmed) {
      return;
    }
    await ref.read(paymentRepositoryProvider).delete(payment.id);
  }

  Future<void> _deleteExpense(ExpenseRecord expense) async {
    final confirmed = await _confirm(
      'حذف المصروف',
      'سيتم حذف هذا المصروف من سجل العقار.',
    );
    if (!confirmed) {
      return;
    }
    await ref.read(expenseRepositoryProvider).softDelete(expense.id);
  }

  Future<void> _deleteMaterial(MaterialExpenseEntry entry) async {
    final confirmed = await _confirm(
      'حذف فاتورة مواد',
      'سيتم أرشفة فاتورة المواد من الجداول النشطة.',
    );
    if (!confirmed) {
      return;
    }
    await ref.read(materialExpenseRepositoryProvider).softDelete(entry.id);
  }

  Future<void> _showInstallmentPaymentsSheet(InstallmentComputedRow row) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مدفوعات القسط ${row.installment.sequence}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                row.payments.isEmpty
                    ? 'لا توجد مدفوعات مسجلة لهذا القسط حتى الآن.'
                    : 'تفاصيل الدفعات المسجلة لهذا القسط.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              if (row.payments.isEmpty)
                const ListTile(title: Text('لا توجد بيانات'))
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: row.payments.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final payment = row.payments[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          payment.effectivePayerName.isEmpty
                              ? 'دافع غير محدد'
                              : payment.effectivePayerName,
                        ),
                        subtitle: Text(payment.receivedAt.formatShort()),
                        trailing: Text(payment.amount.egp),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPartnerHistorySheet(
    Partner partner,
    List<PartnerLedgerEntry> entries,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سجل ${partner.name}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                entries.isEmpty
                    ? 'لا توجد حركة مسجلة لهذا الشريك.'
                    : 'كل الحركات الخاصة بالشريك داخل هذا العقار.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              if (entries.isEmpty)
                const ListTile(title: Text('لا توجد بيانات'))
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.entryType.label),
                        subtitle: Text(entry.notes.isEmpty ? '-' : entry.notes),
                        trailing: Text(entry.amount.egp),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
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
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: PropertyMaterialEntriesTable(
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
    if (widget.unitId != null) {
      return _buildUnitDetails(context);
    }
    return _buildProjectDetails(context);
  }

  Widget _buildUnitDetails(BuildContext context) {
    final asyncData = ref.watch(
      propertyUnitViewDataProvider(
        PropertyUnitRequest(
          propertyId: widget.propertyId,
          unitId: widget.unitId!,
        ),
      ),
    );

    return asyncData.when(
      loading: () => const AppShellScaffold(
        title: 'الوحدة',
        subtitle: 'تفاصيل البيع والتحصيل',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => AppShellScaffold(
        title: 'الوحدة',
        subtitle: 'تفاصيل البيع والتحصيل',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'تعذر تحميل بيانات الوحدة',
          message: error.toString(),
        ),
      ),
      data: (data) {
        if (data == null) {
          return const AppShellScaffold(
            title: 'الوحدة',
            subtitle: 'تفاصيل البيع والتحصيل',
            currentIndex: 1,
            child: EmptyStateView(
              title: 'الوحدة غير موجودة',
              message: 'لم نتمكن من العثور على هذه الوحدة داخل العقار.',
            ),
          );
        }

        return AppShellScaffold(
          title: 'الوحدة ${data.summary.unit.unitNumber}',
          subtitle: data.property.name,
          currentIndex: 1,
          child: PropertyUnitDetailView(
            data: data,
            onEditUnit: () => _showUnitSheet(unit: data.summary.unit),
            onDeleteUnit: () => _deleteUnit(data.summary.unit),
            onAddInstallment: () => _showInstallmentSheet(
              data: data,
              suggestedSequence: data.summary.installmentRows.length + 1,
            ),
            onEditInstallment: (installment) =>
                _showInstallmentSheet(data: data, installment: installment),
            onDeleteInstallment: _deleteInstallment,
            onViewInstallmentPayments: _showInstallmentPaymentsSheet,
            onAddPayment: (installmentId) =>
                _showPaymentSheet(data: data, installmentId: installmentId),
            onEditPayment: (payment) =>
                _showPaymentSheet(data: data, payment: payment),
            onDeletePayment: _deletePayment,
          ),
        );
      },
    );
  }

  Widget _buildProjectDetails(BuildContext context) {
    final asyncData = ref.watch(
      propertyProjectViewDataProvider(widget.propertyId),
    );
    final session = ref.watch(authSessionProvider).valueOrNull;

    return asyncData.when(
      loading: () => const AppShellScaffold(
        title: 'العقار',
        subtitle: 'المبيعات والمصاريف',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => AppShellScaffold(
        title: 'العقار',
        subtitle: 'المبيعات والمصاريف',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'تعذر تحميل بيانات العقار',
          message: error.toString(),
        ),
      ),
      data: (data) {
        if (data == null) {
          return const AppShellScaffold(
            title: 'العقار',
            subtitle: 'المبيعات والمصاريف',
            currentIndex: 1,
            child: EmptyStateView(
              title: 'العقار غير موجود',
              message: 'هذا العقار لم يعد متاحًا.',
            ),
          );
        }

        if (session != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(financialNotificationCoordinatorProvider)
                .syncPropertyAlerts(
                  userId: session.userId,
                  propertyId: widget.propertyId,
                  unitSummaries: data.unitSummaries,
                  materials: data.materials,
                );
          });
        }

        return AppShellScaffold(
          title: data.property.name,
          subtitle: data.property.location,
          currentIndex: 1,
          actions: [
            IconButton(
              tooltip: 'إضافة وحدة',
              onPressed: () => _showUnitSheet(),
              icon: const Icon(Icons.add_business_outlined),
            ),
            IconButton(
              tooltip: 'إضافة مصروف',
              onPressed: () => _showExpenseSheet(partners: data.partners),
              icon: const Icon(Icons.receipt_long_outlined),
            ),
          ],
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _PropertyHeroCard(
                data: data,
                onAddUnit: () => _showUnitSheet(),
                onAddExpense: () => _showExpenseSheet(partners: data.partners),
                onAddMaterial: _showMaterialSheet,
              ),
              const SizedBox(height: 16),
              _PrimarySwitchCard(
                selectedIndex: _primaryTabIndex,
                onChanged: (index) => setState(() => _primaryTabIndex = index),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: _primaryTabIndex != 0
                    ? PropertyExpensesWorkspace(
                        key: const ValueKey('expenses'),
                        data: data,
                        selectedLedgerIndex: _expensesLedgerIndex,
                        onLedgerIndexChanged: (index) =>
                            setState(() => _expensesLedgerIndex = index),
                        onAddExpense: () =>
                            _showExpenseSheet(partners: data.partners),
                        onEditExpense: (expense) => _showExpenseSheet(
                          expense: expense,
                          partners: data.partners,
                        ),
                        onDeleteExpense: _deleteExpense,
                        onAddMaterial: _showMaterialSheet,
                        onEditMaterial: (entry) =>
                            _showMaterialSheet(entry: entry),
                        onDeleteMaterial: _deleteMaterial,
                        onOpenPartnerHistory: (partner) =>
                            _showPartnerHistorySheet(
                              partner,
                              data.partnerEntriesByPartner[partner.id] ??
                                  const <PartnerLedgerEntry>[],
                            ),
                        onOpenSupplierSheet: (summary) =>
                            _showSupplierEntriesSheet(
                              summary,
                              data.materials
                                  .where(
                                    (entry) =>
                                        entry.supplierName.trim() ==
                                        summary.supplierName.trim(),
                                  )
                                  .toList(),
                            ),
                      )
                    : PropertySalesWorkspace(
                        key: const ValueKey('sales'),
                        data: data,
                        onAddUnit: () => _showUnitSheet(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PropertyHeroCard extends StatelessWidget {
  const _PropertyHeroCard({
    required this.data,
    required this.onAddUnit,
    required this.onAddExpense,
    required this.onAddMaterial,
  });

  final PropertyProjectViewData data;
  final VoidCallback onAddUnit;
  final VoidCallback onAddExpense;
  final VoidCallback onAddMaterial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: theme.colorScheme.surface,
        border: Border.all(color: const Color(0xFFD8D8D2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.property.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.property.location,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F4),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFD8D8D2)),
                ),
                child: Text(
                  data.property.status.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroMetric(label: 'المبيعات', value: data.totalSalesValue.egp),
              _HeroMetric(
                label: 'إجمالي المصاريف',
                value: data.totalProjectExpenses.egp,
              ),
              _HeroMetric(
                label: 'الوحدات',
                value: '${data.unitSummaries.length}',
              ),
              _HeroMetric(
                label: 'الموردين',
                value: data.materialsSnapshot.overallRemaining.egp,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: onAddUnit,
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('إضافة وحدة'),
              ),
              FilledButton.tonalIcon(
                onPressed: onAddExpense,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('إضافة مصروف'),
              ),
              FilledButton.tonalIcon(
                onPressed: onAddMaterial,
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('مواد البناء'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D8D2)),
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimarySwitchCard extends StatelessWidget {
  const _PrimarySwitchCard({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9DED6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PrimarySwitchChip(
              label: 'المبيعات',
              subtitle: 'الوحدات والتحصيل',
              selected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _PrimarySwitchChip(
              label: 'المصاريف',
              subtitle: 'اليومية ومواد البناء',
              selected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimarySwitchChip extends StatelessWidget {
  const _PrimarySwitchChip({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 170;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 14,
              vertical: isCompact ? 10 : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: selected ? const Color(0xFF123A33) : Colors.transparent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : const Color(0xFF17352F),
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected
                          ? Colors.white70
                          : const Color(0xFF68766C),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
