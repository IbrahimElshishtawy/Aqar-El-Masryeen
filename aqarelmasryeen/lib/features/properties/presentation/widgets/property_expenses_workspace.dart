import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/widgets/expense_split_ledger_table.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';

import 'financial_ledger_table.dart';

enum ExpenseTableScope { recent24Hours, olderThan24Hours, all }

class PropertyExpensesWorkspace extends StatelessWidget {
  const PropertyExpensesWorkspace({
    super.key,
    required this.data,
    this.onOpenMaterials,
    this.onOpenDetailedExpenses,
    this.onAddExpense,
    required this.onEditExpense,
    required this.onDeleteExpense,
    this.showSummaryPanel = false,
    this.showDetailedButton = true,
    this.scope = ExpenseTableScope.all,
  });

  final PropertyProjectViewData data;
  final VoidCallback? onOpenMaterials;
  final VoidCallback? onOpenDetailedExpenses;
  final VoidCallback? onAddExpense;
  final ValueChanged<ExpenseRecord> onEditExpense;
  final ValueChanged<ExpenseRecord> onDeleteExpense;
  final bool showSummaryPanel;
  final bool showDetailedButton;
  final ExpenseTableScope scope;

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
    final splitRows = rows
        .map(
          (row) => ExpenseSplitLedgerRow(
            dateLabel: row.row.expense.date.formatShort(),
            amountLabel: row.row.expense.amount.egp,
            description: row.description,
            isCurrentSide: row.isCurrentSide,
          ),
        )
        .toList(growable: false);
    final currentTotal = rows
        .where((row) => row.isCurrentSide)
        .fold<double>(0, (sum, row) => sum + row.row.expense.amount);
    final counterpartTotal = rows
        .where((row) => !row.isCurrentSide)
        .fold<double>(0, (sum, row) => sum + row.row.expense.amount);
    final overallTotal = rows.fold<double>(
      0,
      (sum, row) => sum + row.row.expense.amount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSummaryPanel) ...[
          _ExpenseTotalsPanel(
            currentLabel: data.currentColumnLabel,
            counterpartLabel: data.counterpartColumnLabel,
            currentTotal: currentTotal,
            counterpartTotal: counterpartTotal,
            overallTotal: overallTotal,
            entriesCount: rows.length,
          ),
          const SizedBox(height: 16),
        ],
        if (_shouldShowActionStrip) ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (onOpenMaterials != null)
                FilledButton.tonalIcon(
                  onPressed: onOpenMaterials,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('مواد البناء'),
                ),
              if (showDetailedButton && onOpenDetailedExpenses != null)
                OutlinedButton.icon(
                  onPressed: onOpenDetailedExpenses,
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('الأيام السابقة'),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        ExpenseSplitLedgerTable(
          rows: splitRows,
          currentColumnLabel: data.currentColumnLabel,
          counterpartColumnLabel: data.counterpartColumnLabel,
          emptyTitle: _emptyTitle,
          emptyMessage: _emptyMessage,
        ),
        const SizedBox(height: 12),
        FinancialLedgerTable<_ExpenseTableRow>(
          title: _tableTitle,
          subtitle: _tableSubtitle,
          rows: rows,
          forceTableLayout: true,
          onAdd: onAddExpense,
          addLabel: 'إضافة مصروف',
          emptyTitle: _emptyTitle,
          emptyMessage: _emptyMessage,
          sheetLabel: 'جدول مصروفات المشروع',
          onEdit: (row) => onEditExpense(row.row.expense),
          onDelete: (row) => onDeleteExpense(row.row.expense),
          compactCardBuilder: (context, row, rowNumber, actions) {
            return _ExpenseCompactCard(
              row: row,
              rowNumber: rowNumber,
              actions: actions,
            );
          },
          columns: [
            LedgerColumn(
              label: 'التاريخ',
              valueBuilder: (row) => Text(row.row.expense.date.formatShort()),
              minWidth: 120,
            ),
            LedgerColumn(
              label: 'البيان / الوصف',
              valueBuilder: (row) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    row.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.row.expense.category.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              minWidth: 220,
            ),
            LedgerColumn(
              label: 'المبلغ',
              valueBuilder: (row) => Text(row.row.expense.amount.egp),
              minWidth: 120,
              numeric: true,
            ),
            LedgerColumn(
              label: 'من الذي دفع',
              valueBuilder: (row) => Text(row.paidByLabel),
              minWidth: 150,
            ),
            LedgerColumn(
              label: 'ملاحظات',
              valueBuilder: (row) => Text(
                row.row.expense.notes.trim().isEmpty
                    ? '-'
                    : row.row.expense.notes.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              minWidth: 180,
            ),
          ],
          totalsFooter: LedgerTotalsFooter(
            children: [
              LedgerFooterValue(
                label: 'Total ${data.currentColumnLabel}',
                value: currentTotal.egp,
              ),
              LedgerFooterValue(
                label: 'Total ${data.counterpartColumnLabel}',
                value: counterpartTotal.egp,
              ),
              LedgerFooterValue(
                label: 'الإجمالي الكلي',
                value: overallTotal.egp,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool get _shouldShowActionStrip {
    return onOpenMaterials != null ||
        (showDetailedButton && onOpenDetailedExpenses != null);
  }

  String get _tableTitle {
    switch (scope) {
      case ExpenseTableScope.recent24Hours:
        return 'مصروفات اليوم';
      case ExpenseTableScope.olderThan24Hours:
        return 'مصروفات الأيام السابقة';
      case ExpenseTableScope.all:
        return 'سجل المصروفات';
    }
  }

  String get _tableSubtitle {
    switch (scope) {
      case ExpenseTableScope.recent24Hours:
        return 'كل مصروف يظهر كسطر مستقل مع تحديد التاريخ والوصف والمبلغ ومن الذي دفع.';
      case ExpenseTableScope.olderThan24Hours:
        return 'عرض حركات الأيام السابقة بنفس الجدول الموحد وبدون إجماليات يومية.';
      case ExpenseTableScope.all:
        return 'جدول يومي موحد يعرض كل المصروفات المسجلة داخل المشروع مع Totals فقط لكل طرف.';
    }
  }

  String get _emptyTitle {
    switch (scope) {
      case ExpenseTableScope.recent24Hours:
        return 'لا توجد مصروفات اليوم';
      case ExpenseTableScope.olderThan24Hours:
        return 'لا توجد مصروفات للأيام السابقة';
      case ExpenseTableScope.all:
        return 'لا توجد مصروفات بعد';
    }
  }

  String get _emptyMessage {
    switch (scope) {
      case ExpenseTableScope.recent24Hours:
        return 'بمجرد تسجيل أول مصروف بتاريخ اليوم سيظهر هنا داخل الجدول.';
      case ExpenseTableScope.olderThan24Hours:
        return 'عند وجود مصروفات بتواريخ أقدم من اليوم ستظهر هنا تلقائيًا.';
      case ExpenseTableScope.all:
        return 'أضف أول مصروف ليبدأ الجدول اليومي وتظهر Totals للمستخدم والشريك.';
    }
  }

  List<_ExpenseTableRow> _buildRows() {
    final rows =
        data.expenseLedgerRows
            .where(_matchesScope)
            .map(
              (row) => _ExpenseTableRow(
                row: row,
                isCurrentSide: _isCurrentSide(row),
                paidByLabel: _paidByLabel(row),
              ),
            )
            .toList()
          ..sort((a, b) => b.row.expense.date.compareTo(a.row.expense.date));
    return rows;
  }

  bool _matchesScope(PropertyExpenseLedgerRow row) {
    final isToday = DateUtils.isSameDay(row.expense.date, DateTime.now());
    switch (scope) {
      case ExpenseTableScope.recent24Hours:
        return isToday;
      case ExpenseTableScope.olderThan24Hours:
        return !isToday;
      case ExpenseTableScope.all:
        return true;
    }
  }

  bool _isCurrentSide(PropertyExpenseLedgerRow row) {
    if (data.currentPartner != null &&
        row.expense.paidByPartnerId == data.currentPartner!.id) {
      return true;
    }
    return row.expense.createdBy == data.currentUserId;
  }

  String _paidByLabel(PropertyExpenseLedgerRow row) {
    final partnerName = row.payer?.name.trim() ?? '';
    if (partnerName.isNotEmpty) {
      return partnerName;
    }
    return _isCurrentSide(row)
        ? data.currentUserDisplayName
        : (data.linkedPartnerName ?? 'الشريك المرتبط');
  }
}

class _ExpenseTotalsPanel extends StatelessWidget {
  const _ExpenseTotalsPanel({
    required this.currentLabel,
    required this.counterpartLabel,
    required this.currentTotal,
    required this.counterpartTotal,
    required this.overallTotal,
    required this.entriesCount,
  });

  final String currentLabel;
  final String counterpartLabel;
  final double currentTotal;
  final double counterpartTotal;
  final double overallTotal;
  final int entriesCount;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'ملخص المصروفات',
      subtitle:
          'Totals فقط للمستخدم والشريك والإجمالي الكلي بدون أي إجماليات يومية.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _ExpenseMetricPill(
            label: 'Total $currentLabel',
            value: currentTotal.egp,
          ),
          _ExpenseMetricPill(
            label: 'Total $counterpartLabel',
            value: counterpartTotal.egp,
          ),
          _ExpenseMetricPill(label: 'الإجمالي الكلي', value: overallTotal.egp),
          _ExpenseMetricPill(label: 'عدد الحركات', value: '$entriesCount'),
        ],
      ),
    );
  }
}

class _ExpenseMetricPill extends StatelessWidget {
  const _ExpenseMetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 136),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF17352F),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCompactCard extends StatelessWidget {
  const _ExpenseCompactCard({
    required this.row,
    required this.rowNumber,
    required this.actions,
  });

  final _ExpenseTableRow row;
  final int? rowNumber;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(14),
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
                    if (rowNumber != null)
                      Text(
                        'مصروف #$rowNumber',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2E6B3F),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      row.description,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF17352F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                row.row.expense.amount.egp,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF17352F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ExpenseMetaChip(label: row.row.expense.date.formatShort()),
              _ExpenseMetaChip(label: row.paidByLabel),
              _ExpenseMetaChip(label: row.row.expense.category.label),
            ],
          ),
          if (row.row.expense.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              row.row.expense.notes.trim(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF40564F)),
            ),
          ],
          if (actions != null) ...[const SizedBox(height: 8), actions!],
        ],
      ),
    );
  }
}

class _ExpenseMetaChip extends StatelessWidget {
  const _ExpenseMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF465145),
        ),
      ),
    );
  }
}

class _ExpenseTableRow {
  const _ExpenseTableRow({
    required this.row,
    required this.isCurrentSide,
    required this.paidByLabel,
  });

  final PropertyExpenseLedgerRow row;
  final bool isCurrentSide;
  final String paidByLabel;

  String get description {
    final description = row.expense.description.trim();
    return description.isEmpty ? row.expense.category.label : description;
  }
}
