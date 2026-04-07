import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/summary_card.dart';
import 'package:aqarelmasryeen/features/expenses/domain/materials_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/partners/domain/partner_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/financial_ledger_table.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/property_material_entries_table.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:flutter/material.dart';

class PropertyExpensesWorkspace extends StatelessWidget {
  const PropertyExpensesWorkspace({
    super.key,
    required this.data,
    required this.selectedLedgerIndex,
    required this.onLedgerIndexChanged,
    required this.onAddExpense,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onAddMaterial,
    required this.onEditMaterial,
    required this.onDeleteMaterial,
    required this.onOpenPartnerHistory,
    required this.onOpenSupplierSheet,
  });

  final PropertyProjectViewData data;
  final int selectedLedgerIndex;
  final ValueChanged<int> onLedgerIndexChanged;
  final VoidCallback onAddExpense;
  final ValueChanged<ExpenseRecord> onEditExpense;
  final ValueChanged<ExpenseRecord> onDeleteExpense;
  final VoidCallback onAddMaterial;
  final ValueChanged<MaterialExpenseEntry> onEditMaterial;
  final ValueChanged<MaterialExpenseEntry> onDeleteMaterial;
  final ValueChanged<Partner> onOpenPartnerHistory;
  final ValueChanged<SupplierLedgerSummary> onOpenSupplierSheet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ExpensesSummaryGrid(data: data),
        const SizedBox(height: 16),
        _LedgerModePanel(
          selectedLedgerIndex: selectedLedgerIndex,
          onLedgerIndexChanged: onLedgerIndexChanged,
          onAddExpense: onAddExpense,
          onAddMaterial: onAddMaterial,
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: switch (selectedLedgerIndex) {
            1 => _PartnerBalancesView(
              key: const ValueKey('partner-balances-view'),
              data: data,
              onOpenPartnerHistory: onOpenPartnerHistory,
            ),
            2 => _MaterialsView(
              key: const ValueKey('materials-view'),
              data: data,
              onAddMaterial: onAddMaterial,
              onEditMaterial: onEditMaterial,
              onDeleteMaterial: onDeleteMaterial,
              onOpenSupplierSheet: onOpenSupplierSheet,
            ),
            _ => _DailyExpensesView(
              key: const ValueKey('daily-expenses-view'),
              data: data,
              onAddExpense: onAddExpense,
              onEditExpense: onEditExpense,
              onDeleteExpense: onDeleteExpense,
            ),
          },
        ),
      ],
    );
  }
}

class _ExpensesSummaryGrid extends StatelessWidget {
  const _ExpensesSummaryGrid({required this.data});

  final PropertyProjectViewData data;

  @override
  Widget build(BuildContext context) {
    return _ResponsiveGrid(
      children: [
        SummaryCard(
          label: 'مصاريف اليوم',
          value: data.todayDirectExpenses.egp,
          subtitle: 'إجمالي اليوميات المسجلة اليوم داخل العقار',
          icon: Icons.today_outlined,
          emphasis: true,
        ),
        SummaryCard(
          label: 'إجمالي المصروفات',
          value: data.totalDirectExpenses.egp,
          subtitle: 'كل المصروفات المباشرة المسجلة على العقار',
          icon: Icons.receipt_long_outlined,
        ),
        SummaryCard(
          label: data.myLabel,
          value: data.myTotalExpenseShare.egp,
          subtitle: 'حصتي التقديرية من مصروفات العقار',
          icon: Icons.person_outline_rounded,
        ),
        SummaryCard(
          label: data.counterpartLabel,
          value: data.counterpartTotalExpenseShare.egp,
          subtitle: 'حصة الطرف الآخر من المصروفات المباشرة',
          icon: Icons.groups_outlined,
        ),
        SummaryCard(
          label: 'الموارد',
          value: data.materialsSnapshot.overallTotal.egp,
          subtitle: 'فواتير المواد والموردين الخاصة بالعقار',
          icon: Icons.inventory_2_outlined,
        ),
      ],
    );
  }
}

class _LedgerModePanel extends StatelessWidget {
  const _LedgerModePanel({
    required this.selectedLedgerIndex,
    required this.onLedgerIndexChanged,
    required this.onAddExpense,
    required this.onAddMaterial,
  });

  final int selectedLedgerIndex;
  final ValueChanged<int> onLedgerIndexChanged;
  final VoidCallback onAddExpense;
  final VoidCallback onAddMaterial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'دفتر مصروفات العقار',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'تقدر الآن تتنقل بين سجل اليومية، كشف الشركاء، وجدول الموارد بنفس شكل الجداول الواضح داخل التطبيق.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F5F0),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD9DED6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _LedgerTab(
                    label: 'سجل المصروفات',
                    subtitle: 'اليومية',
                    selected: selectedLedgerIndex == 0,
                    onTap: () => onLedgerIndexChanged(0),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _LedgerTab(
                    label: 'أنا / الشريك',
                    subtitle: 'الالتزامات',
                    selected: selectedLedgerIndex == 1,
                    onTap: () => onLedgerIndexChanged(1),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _LedgerTab(
                    label: 'الموارد',
                    subtitle: 'الموردون',
                    selected: selectedLedgerIndex == 2,
                    onTap: () => onLedgerIndexChanged(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: switch (selectedLedgerIndex) {
              2 => FilledButton.tonalIcon(
                key: const ValueKey('add-material-button'),
                onPressed: onAddMaterial,
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('إضافة فاتورة موارد'),
              ),
              1 => Container(
                key: const ValueKey('partners-hint'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD8D8D2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Color(0xFF5C675E),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'اضغط على أي شريك لعرض سجله داخل هذا العقار.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5C675E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _ => FilledButton.icon(
                key: const ValueKey('add-expense-button'),
                onPressed: onAddExpense,
                icon: const Icon(Icons.add),
                label: const Text('إضافة مصروف يومي'),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _DailyExpensesView extends StatelessWidget {
  const _DailyExpensesView({
    super.key,
    required this.data,
    required this.onAddExpense,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  final PropertyProjectViewData data;
  final VoidCallback onAddExpense;
  final ValueChanged<ExpenseRecord> onEditExpense;
  final ValueChanged<ExpenseRecord> onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinancialLedgerTable<PropertyExpenseDayRow>(
          title: 'سجل المصروفات',
          subtitle: data.dailyExpenseRows.isEmpty
              ? 'لا توجد يوميات مصروفات مسجلة داخل هذا العقار حتى الآن.'
              : '${data.dailyExpenseRows.length} يوم - الإجمالي ${data.totalDirectExpenses.egp}',
          rows: data.dailyExpenseRows,
          forceTableLayout: true,
          sheetLabel: 'ورقة المصروفات المباشرة',
          columns: [
            LedgerColumn(
              label: 'التاريخ',
              valueBuilder: (row) => Text(row.day.formatShort()),
              minWidth: 130,
            ),
            LedgerColumn(
              label: 'الحركات',
              valueBuilder: (row) => Text('${row.entriesCount}'),
              minWidth: 96,
              numeric: true,
            ),
            LedgerColumn(
              label: 'الإجمالي',
              valueBuilder: (row) => Text(row.total.egp),
              minWidth: 128,
              numeric: true,
            ),
            LedgerColumn(
              label: data.myLabel,
              valueBuilder: (row) => Text(row.myShare.egp),
              minWidth: 128,
              numeric: true,
            ),
            LedgerColumn(
              label: data.counterpartLabel,
              valueBuilder: (row) => Text(row.counterpartShare.egp),
              minWidth: 140,
              numeric: true,
            ),
          ],
          totalsFooter: LedgerTotalsFooter(
            children: [
              LedgerFooterValue(
                label: 'مصاريف اليوم',
                value: data.todayDirectExpenses.egp,
              ),
              LedgerFooterValue(
                label: 'حصة ${data.myLabel}',
                value: data.myTodayExpenseShare.egp,
              ),
              LedgerFooterValue(
                label: 'حصة ${data.counterpartLabel}',
                value: data.counterpartTodayExpenseShare.egp,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FinancialLedgerTable<PropertyExpenseLedgerRow>(
          title: 'الحركات اليومية التفصيلية',
          subtitle: data.expenseLedgerRows.isEmpty
              ? 'لا توجد حركات يومية مسجلة.'
              : '${data.expenseLedgerRows.length} حركة - جدول يومي مشابه لورقة المصروفات.',
          rows: data.expenseLedgerRows,
          forceTableLayout: true,
          onAdd: onAddExpense,
          addLabel: 'إضافة مصروف',
          onEdit: (row) => onEditExpense(row.expense),
          onDelete: (row) => onDeleteExpense(row.expense),
          sheetLabel: 'ورقة تفاصيل المصروفات',
          columns: [
            LedgerColumn(
              label: 'التاريخ',
              valueBuilder: (row) => Text(row.expense.date.formatShort()),
              minWidth: 118,
            ),
            LedgerColumn(
              label: 'البيان',
              valueBuilder: (row) => Text(
                row.expense.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              minWidth: 190,
            ),
            LedgerColumn(
              label: 'الفئة',
              valueBuilder: (row) => Text(row.expense.category.label),
              minWidth: 128,
            ),
            LedgerColumn(
              label: 'الدافع',
              valueBuilder: (row) => _PartnerChip(
                label: row.payer?.name ?? 'غير محدد',
                highlight: row.payer?.userId == data.currentUserId,
              ),
              minWidth: 150,
            ),
            LedgerColumn(
              label: 'المدفوع',
              valueBuilder: (row) => Text(row.expense.amount.egp),
              minWidth: 124,
              numeric: true,
            ),
            LedgerColumn(
              label: 'ملاحظات',
              valueBuilder: (row) => Text(
                row.expense.notes.isEmpty ? '-' : row.expense.notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              minWidth: 200,
            ),
          ],
          totalsFooter: LedgerTotalsFooter(
            children: [
              LedgerFooterValue(
                label: 'إجمالي المصروفات المباشرة',
                value: data.totalDirectExpenses.egp,
              ),
              LedgerFooterValue(
                label: data.myLabel,
                value: data.myTotalExpenseShare.egp,
              ),
              LedgerFooterValue(
                label: data.counterpartLabel,
                value: data.counterpartTotalExpenseShare.egp,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PartnerBalancesView extends StatelessWidget {
  const _PartnerBalancesView({
    super.key,
    required this.data,
    required this.onOpenPartnerHistory,
  });

  final PropertyProjectViewData data;
  final ValueChanged<Partner> onOpenPartnerHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResponsiveGrid(
          children: [
            SummaryCard(
              label: ' ${data.myLabel} اليوم',
              value: data.myTodayExpenseShare.egp,
              subtitle: '',
              icon: Icons.calendar_today_outlined,
              emphasis: true,
            ),
            SummaryCard(
              label: ' ${data.counterpartLabel} اليوم',
              value: data.counterpartTodayExpenseShare.egp,
              subtitle: '',
              icon: Icons.group_outlined,
            ),
            SummaryCard(
              label: 'إجمالي ${data.myLabel}',
              value: data.myTotalExpenseShare.egp,
              subtitle: ' ',
              icon: Icons.person_outline_rounded,
            ),
            SummaryCard(
              label: 'إجمالي ${data.counterpartLabel}',
              value: data.counterpartTotalExpenseShare.egp,
              subtitle: '',
              icon: Icons.balance_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FinancialLedgerTable<PartnerLedgerSummaryRow>(
          title: 'أنا / الشريك',
          subtitle: data.partnerSummaries.isEmpty
              ? 'لا توجد حركة شركاء مسجلة داخل هذا العقار.'
              : 'جدول سريع يوضح المدفوع والمستحق والرصيد لكل شريك داخل العقار.',
          rows: data.partnerSummaries,
          forceTableLayout: true,
          sheetLabel: 'ورقة ملخص الشركاء',
          onView: (row) => onOpenPartnerHistory(row.partner),
          columns: [
            LedgerColumn(
              label: 'الشريك',
              valueBuilder: (row) => _PartnerChip(
                label: row.partner.name,
                highlight: row.partner.userId == data.currentUserId,
              ),
              minWidth: 180,
            ),
            LedgerColumn(
              label: 'نسبة الشراكة',
              valueBuilder: (row) =>
                  Text('${(row.partner.shareRatio * 100).toStringAsFixed(0)}%'),
              minWidth: 120,
              numeric: true,
            ),
            LedgerColumn(
              label: 'المدفوع',
              valueBuilder: (row) => Text(row.totalPaid.egp),
              minWidth: 124,
              numeric: true,
            ),
            LedgerColumn(
              label: 'المستحق',
              valueBuilder: (row) => Text(row.totalOwed.egp),
              minWidth: 124,
              numeric: true,
            ),
            LedgerColumn(
              label: 'الرصيد',
              valueBuilder: (row) => Text(row.balance.egp),
              minWidth: 124,
              numeric: true,
            ),
            LedgerColumn(
              label: 'آخر تحديث',
              valueBuilder: (row) => Text(row.lastUpdated.formatShort()),
              minWidth: 118,
            ),
          ],
        ),
      ],
    );
  }
}

class _MaterialsView extends StatelessWidget {
  const _MaterialsView({
    super.key,
    required this.data,
    required this.onAddMaterial,
    required this.onEditMaterial,
    required this.onDeleteMaterial,
    required this.onOpenSupplierSheet,
  });

  final PropertyProjectViewData data;
  final VoidCallback onAddMaterial;
  final ValueChanged<MaterialExpenseEntry> onEditMaterial;
  final ValueChanged<MaterialExpenseEntry> onDeleteMaterial;
  final ValueChanged<SupplierLedgerSummary> onOpenSupplierSheet;

  @override
  Widget build(BuildContext context) {
    final topCategories = data.materialsSnapshot.categoryTotals
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResponsiveGrid(
          children: [
            SummaryCard(
              label: 'إجمالي الموارد',
              value: data.materialsSnapshot.overallTotal.egp,
              subtitle: 'كل فواتير مواد البناء المسجلة',
              icon: Icons.inventory_2_outlined,
              emphasis: true,
            ),
            SummaryCard(
              label: 'المدفوع للموردين',
              value: data.materialsSnapshot.overallPaid.egp,
              subtitle: 'ما تم سداده حتى الآن',
              icon: Icons.payments_outlined,
            ),
            SummaryCard(
              label: 'المتبقي على الموردين',
              value: data.materialsSnapshot.overallRemaining.egp,
              subtitle: 'الرصيد المفتوح حتى الآن',
              icon: Icons.pending_actions_outlined,
            ),
            SummaryCard(
              label: topCategories.isEmpty
                  ? 'أعلى فئة'
                  : topCategories.first.categoryLabel,
              value: topCategories.isEmpty
                  ? 0.egp
                  : topCategories.first.totalSpending.egp,
              subtitle: 'أكثر فئة استهلاكًا داخل هذا العقار',
              icon: Icons.category_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FinancialLedgerTable<SupplierLedgerSummary>(
          title: 'كشف الموردين',
          subtitle: data.materialsSnapshot.supplierSummaries.isEmpty
              ? 'لا توجد فواتير موردين مسجلة بعد.'
              : 'ملخص سريع يوضح كل مورد وإجمالي المشتريات والمدفوع والمتبقي.',
          rows: data.materialsSnapshot.supplierSummaries,
          forceTableLayout: true,
          showRowNumbers: false,
          sheetLabel: 'ورقة الموردين',
          onView: onOpenSupplierSheet,
          columns: [
            LedgerColumn(
              label: 'المورد',
              valueBuilder: (row) => Text(row.supplierName),
              minWidth: 190,
            ),
            LedgerColumn(
              label: 'عدد الفواتير',
              valueBuilder: (row) => Text('${row.invoiceCount}'),
              minWidth: 108,
              numeric: true,
            ),
            LedgerColumn(
              label: 'الإجمالي',
              valueBuilder: (row) => Text(row.totalPurchased.egp),
              minWidth: 124,
              numeric: true,
            ),
            LedgerColumn(
              label: 'المدفوع',
              valueBuilder: (row) => Text(row.totalPaid.egp),
              minWidth: 120,
              numeric: true,
            ),
            LedgerColumn(
              label: 'المتبقي',
              valueBuilder: (row) => Text(row.totalRemaining.egp),
              minWidth: 120,
              numeric: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        PropertyMaterialEntriesTable(
          title: 'جدول الموارد',
          rows: data.materials,
          onAdd: onAddMaterial,
          onEdit: onEditMaterial,
          onDelete: onDeleteMaterial,
        ),
      ],
    );
  }
}

class _LedgerTab extends StatelessWidget {
  const _LedgerTab({
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
        final isCompact = constraints.maxWidth < 120;
        final background = selected
            ? const Color.fromARGB(255, 127, 152, 148)
            : Colors.white;
        final foreground = selected ? Colors.white : const Color(0xFF17352F);

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 12,
              vertical: isCompact ? 10 : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: background,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: isCompact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: foreground,
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

class _PartnerChip extends StatelessWidget {
  const _PartnerChip({required this.label, required this.highlight});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFE5F3EE) : const Color(0xFFF3F4EE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        highlight ? '$label (أنا)' : label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: highlight ? const Color(0xFF175546) : const Color(0xFF556257),
        ),
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 960
            ? 4
            : constraints.maxWidth >= 700
            ? 2
            : constraints.maxWidth >= 330
            ? 2
            : 1;
        final ratio = count == 1
            ? 1.18
            : constraints.maxWidth < 480
            ? 1.02
            : constraints.maxWidth < 760
            ? 1.12
            : 1.3;
        return GridView.count(
          crossAxisCount: count,
          childAspectRatio: ratio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: children,
        );
      },
    );
  }
}
