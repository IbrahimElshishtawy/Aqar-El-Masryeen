import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/summary_card.dart';
import 'package:aqarelmasryeen/features/expenses/domain/materials_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/partners/domain/partner_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/financial_ledger_table.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/property_material_entries_table.dart';
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
        if (selectedLedgerIndex == 0) ...[
          _DailyExpensesView(
            data: data,
            onAddExpense: onAddExpense,
            onEditExpense: onEditExpense,
            onDeleteExpense: onDeleteExpense,
            onOpenPartnerHistory: onOpenPartnerHistory,
          ),
        ] else ...[
          _MaterialsView(
            data: data,
            onAddMaterial: onAddMaterial,
            onEditMaterial: onEditMaterial,
            onDeleteMaterial: onDeleteMaterial,
            onOpenSupplierSheet: onOpenSupplierSheet,
          ),
        ],
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
          label: 'مصروفات العقار',
          value: data.totalDirectExpenses.egp,
          subtitle: 'إجمالي اليوميات المسجلة داخل العقار',
          icon: Icons.today_outlined,
          emphasis: true,
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
          subtitle: 'حصة الطرف الآخر من مصروفات العقار',
          icon: Icons.group_outlined,
        ),
        SummaryCard(
          label: 'مواد البناء',
          value: data.materialsSnapshot.overallTotal.egp,
          subtitle: 'إجمالي فواتير المواد والموردين',
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
    return AppPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ورق المصاريف',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'اختر بين يوميات المصاريف أو مواد البناء، وكل جزء له جدول واضح مناسب للموبايل.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _LedgerTab(
                  label: 'اليومية',
                  subtitle: 'المصروفات اليومية',
                  selected: selectedLedgerIndex == 0,
                  onTap: () => onLedgerIndexChanged(0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LedgerTab(
                  label: 'مواد البناء',
                  subtitle: 'الموردين والخامات',
                  selected: selectedLedgerIndex == 1,
                  onTap: () => onLedgerIndexChanged(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onAddExpense,
                icon: const Icon(Icons.add),
                label: const Text('إضافة مصروف'),
              ),
              FilledButton.tonalIcon(
                onPressed: onAddMaterial,
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('إضافة مواد'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyExpensesView extends StatelessWidget {
  const _DailyExpensesView({
    required this.data,
    required this.onAddExpense,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onOpenPartnerHistory,
  });

  final PropertyProjectViewData data;
  final VoidCallback onAddExpense;
  final ValueChanged<ExpenseRecord> onEditExpense;
  final ValueChanged<ExpenseRecord> onDeleteExpense;
  final ValueChanged<Partner> onOpenPartnerHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinancialLedgerTable<PropertyExpenseDayRow>(
          title: 'ملخص يومي للمصاريف',
          subtitle: 'كل يوم ظاهر بإجماليه وحصتي وحصة ${data.counterpartLabel}.',
          rows: data.dailyExpenseRows,
          forceTableLayout: true,
          showRowNumbers: false,
          sheetLabel: 'ورقة اليوميات',
          columns: [
            LedgerColumn(
              label: 'اليوم',
              valueBuilder: (row) => Text(row.day.formatShort()),
              minWidth: 116,
            ),
            // LedgerColumn(
            //   label: 'عدد الحركات',
            //   valueBuilder: (row) => Text('${row.entriesCount}'),
            //   minWidth: 108,
            //   numeric: true,
            // ),
            LedgerColumn(
              label: 'الإجمالي',
              valueBuilder: (row) => Text(row.total.egp),
              minWidth: 124,
              numeric: true,
            ),
            LedgerColumn(
              label: 'حصتي',
              valueBuilder: (row) => Text(row.myShare.egp),
              minWidth: 120,
              numeric: true,
            ),
            LedgerColumn(
              label: data.counterpartLabel,
              valueBuilder: (row) => Text(row.counterpartShare.egp),
              minWidth: 140,
              numeric: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FinancialLedgerTable<PropertyExpenseLedgerRow>(
          title: 'شيت المصاريف اليومية',
          subtitle:
              'جدول يومي شبيه بالإكسل يوضح البيان، الدافع، والإجمالي مع التقسيم بيني وبين ${data.counterpartLabel}.',
          rows: data.expenseLedgerRows,
          forceTableLayout: true,
          onAdd: onAddExpense,
          addLabel: 'إضافة مصروف',
          onEdit: (row) => onEditExpense(row.expense),
          onDelete: (row) => onDeleteExpense(row.expense),
          sheetLabel: 'شيت مصاريف العقار',
          columns: [
            LedgerColumn(
              label: 'التاريخ',
              valueBuilder: (row) => Text(row.expense.date.formatShort()),
              minWidth: 116,
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
            // LedgerColumn(
            //   label: 'الفئة',
            //   valueBuilder: (row) => Text(row.expense.category.label),
            //   minWidth: 120,
            // ),
            LedgerColumn(
              label: 'الدافع',
              valueBuilder: (row) => _PartnerChip(
                label: row.payer?.name ?? 'غير محدد',
                highlight: row.payer?.userId == data.currentUserId,
              ),
              minWidth: 150,
            ),
            LedgerColumn(
              label: 'الإجمالي',
              valueBuilder: (row) => Text(row.expense.amount.egp),
              minWidth: 124,
              numeric: true,
            ),
            LedgerColumn(
              label: 'حصتي',
              valueBuilder: (row) => Text(row.myShare.egp),
              minWidth: 116,
              numeric: true,
            ),
            LedgerColumn(
              label: data.counterpartLabel,
              valueBuilder: (row) => Text(row.counterpartShare.egp),
              minWidth: 140,
              numeric: true,
            ),
            LedgerColumn(
              label: 'ملاحظات',
              valueBuilder: (row) => Text(
                row.expense.notes.isEmpty ? '-' : row.expense.notes,
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
                value: data.totalDirectExpenses.egp,
              ),
              LedgerFooterValue(
                label: 'حصتي التراكمية',
                value: data.expenseLedgerRows
                    .fold<double>(0, (sum, row) => sum + row.myShare)
                    .egp,
              ),
              LedgerFooterValue(
                label: data.counterpartLabel,
                value: data.expenseLedgerRows
                    .fold<double>(0, (sum, row) => sum + row.counterpartShare)
                    .egp,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FinancialLedgerTable<PartnerLedgerSummaryRow>(
          title: 'موقف الشركاء',
          subtitle: 'عرض سريع لمن دفع كام وعليه كام داخل العقار.',
          rows: data.partnerSummaries,
          forceTableLayout: true,
          sheetLabel: 'شيت الشركاء',
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
              minWidth: 116,
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
              label: 'السجل',
              valueBuilder: (row) => OutlinedButton.icon(
                onPressed: () => onOpenPartnerHistory(row.partner),
                icon: const Icon(Icons.table_view_outlined, size: 16),
                label: const Text('عرض'),
              ),
              minWidth: 128,
            ),
          ],
        ),
      ],
    );
  }
}

class _MaterialsView extends StatelessWidget {
  const _MaterialsView({
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
              label: 'إجمالي المواد',
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
              subtitle: 'رصيد الموردين المفتوح',
              icon: Icons.pending_actions_outlined,
            ),
            SummaryCard(
              label: topCategories.isEmpty
                  ? 'التقسيم'
                  : topCategories.first.categoryLabel,
              value: topCategories.isEmpty
                  ? 0.egp
                  : topCategories.first.totalSpending.egp,
              subtitle: 'أعلى فئة مواد داخل العقار',
              icon: Icons.category_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FinancialLedgerTable<SupplierLedgerSummary>(
          title: 'شيت الموردين',
          subtitle: 'من اشتريت منه بكام، دفعت له كام، ولسه عليك كام.',
          rows: data.materialsSnapshot.supplierSummaries,
          forceTableLayout: true,
          showRowNumbers: false,
          sheetLabel: 'شيت الموردين',
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
          title: 'شيت مواد البناء',
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
    final background = selected
        ? const Color(0xFF123A33)
        : const Color(0xFFF6F7F2);
    final foreground = selected ? Colors.white : const Color(0xFF17352F);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: background,
          border: Border.all(
            color: selected ? const Color(0xFF123A33) : const Color(0xFFD9DED6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? Colors.white70 : const Color(0xFF647267),
              ),
            ),
          ],
        ),
      ),
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
