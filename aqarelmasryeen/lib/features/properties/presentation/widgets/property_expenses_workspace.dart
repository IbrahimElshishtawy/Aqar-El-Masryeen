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
    this.detailedButtonLabel =
        '\u0627\u0644\u0623\u064a\u0627\u0645 \u0627\u0644\u0633\u0627\u0628\u0642\u0629',
    this.onAddExpense,
    required this.onEditExpense,
    required this.onDeleteExpense,
    this.showSummaryPanel = false,
    this.showDetailedButton = true,
    this.showSplitTable = true,
    this.scope = ExpenseTableScope.all,
    this.showDetailedLedger = false,
    this.maxVisibleRows,
  });

  final PropertyProjectViewData data;
  final VoidCallback? onOpenMaterials;
  final VoidCallback? onOpenDetailedExpenses;
  final String detailedButtonLabel;
  final VoidCallback? onAddExpense;
  final ValueChanged<ExpenseRecord> onEditExpense;
  final ValueChanged<ExpenseRecord> onDeleteExpense;
  final bool showSummaryPanel;
  final bool showDetailedButton;
  final bool showSplitTable;
  final ExpenseTableScope scope;
  final bool showDetailedLedger;
  final int? maxVisibleRows;

  @override
  Widget build(BuildContext context) {
    final allRows = _buildRows(applyLimit: false);
    final visibleRows = _buildRows();
    final splitRows = visibleRows
        .map(
          (row) => ExpenseSplitLedgerRow(
            dateLabel: row.row.expense.date.formatShort(),
            amountLabel: row.row.expense.amount.egp,
            description: row.description,
            isCurrentSide: row.isCurrentSide,
          ),
        )
        .toList(growable: false);
    final currentTotal = allRows
        .where((row) => row.isCurrentSide)
        .fold<double>(0, (sum, row) => sum + row.row.expense.amount);
    final counterpartTotal = allRows
        .where((row) => !row.isCurrentSide)
        .fold<double>(0, (sum, row) => sum + row.row.expense.amount);
    final overallTotal = allRows.fold<double>(
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
            entriesCount: allRows.length,
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
                  label: const Text(
                    '\u0645\u0648\u0627\u062f \u0627\u0644\u0628\u0646\u0627\u0621',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (showSplitTable)
          ExpenseSplitLedgerTable(
            rows: splitRows,
            currentColumnLabel: data.currentColumnLabel,
            counterpartColumnLabel: data.counterpartColumnLabel,
            title: _splitTableTitle,
            subtitle: _splitTableSubtitle,
            emptyTitle: _emptyTitle,
            emptyMessage: _emptyMessage,
            trailing: _buildSplitTableTrailing(),
            currentTotalLabel: currentTotal.egp,
            counterpartTotalLabel: counterpartTotal.egp,
          ),
        if (showDetailedLedger) ...[
          if (showSplitTable) const SizedBox(height: 12),
          FinancialLedgerTable<_ExpenseTableRow>(
            title: _tableTitle,
            subtitle: _tableSubtitle,
            rows: allRows,
            forceTableLayout: true,
            onAdd: onAddExpense,
            addLabel:
                '\u0625\u0636\u0627\u0641\u0629 \u0645\u0635\u0631\u0648\u0641',
            emptyTitle: _emptyTitle,
            emptyMessage: _emptyMessage,
            sheetLabel:
                '\u062c\u062f\u0648\u0644 \u0645\u0635\u0631\u0648\u0641\u0627\u062a \u0627\u0644\u0645\u0634\u0631\u0648\u0639',
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
                label: '\u0627\u0644\u062a\u0627\u0631\u064a\u062e',
                valueBuilder: (row) => Text(row.row.expense.date.formatShort()),
                minWidth: 120,
              ),
              LedgerColumn(
                label:
                    '\u0627\u0644\u0628\u064a\u0627\u0646 / \u0627\u0644\u0648\u0635\u0641',
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
                label: '\u0627\u0644\u0645\u0628\u0644\u063a',
                valueBuilder: (row) => Text(row.row.expense.amount.egp),
                minWidth: 120,
                numeric: true,
              ),
              LedgerColumn(
                label:
                    '\u0645\u0646 \u0627\u0644\u0630\u064a \u062f\u0641\u0639',
                valueBuilder: (row) => Text(row.paidByLabel),
                minWidth: 150,
              ),
              LedgerColumn(
                label: '\u0645\u0644\u0627\u062d\u0638\u0627\u062a',
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
                  label:
                      '\u0627\u0644\u0625\u062c\u0645\u0627\u0644\u064a \u0627\u0644\u0643\u0644\u064a',
                  value: overallTotal.egp,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  bool get _shouldShowActionStrip {
    return onOpenMaterials != null;
  }

  Widget? _buildSplitTableTrailing() {
    final actions = <Widget>[
      if (!showDetailedLedger && onAddExpense != null)
        FilledButton.icon(
          onPressed: onAddExpense,
          icon: const Icon(Icons.add),
          label: const Text(
            '\u0625\u0636\u0627\u0641\u0629 \u0645\u0635\u0631\u0648\u0641',
          ),
        ),
      if (showDetailedButton && onOpenDetailedExpenses != null)
        OutlinedButton.icon(
          onPressed: onOpenDetailedExpenses,
          icon: const Icon(Icons.history_rounded),
          label: Text(detailedButtonLabel),
        ),
    ];
    if (actions.isEmpty) {
      return null;
    }
    return Wrap(spacing: 8, runSpacing: 8, children: actions);
  }

  String get _tableTitle {
    switch (scope) {
      case ExpenseTableScope.recent24Hours:
        return '\u0645\u0635\u0631\u0648\u0641\u0627\u062a \u0627\u0644\u064a\u0648\u0645';
      case ExpenseTableScope.olderThan24Hours:
        return '\u0645\u0635\u0631\u0648\u0641\u0627\u062a \u0627\u0644\u0623\u064a\u0627\u0645 \u0627\u0644\u0633\u0627\u0628\u0642\u0629';
      case ExpenseTableScope.all:
        return '\u0633\u062c\u0644 \u0627\u0644\u0645\u0635\u0631\u0648\u0641\u0627\u062a';
    }
  }

  String get _tableSubtitle {
    switch (scope) {
      case ExpenseTableScope.recent24Hours:
        return '\u0643\u0644 \u0645\u0635\u0631\u0648\u0641 \u064a\u0638\u0647\u0631 \u0643\u0633\u0637\u0631 \u0645\u0633\u062a\u0642\u0644 \u0645\u0639 \u062a\u062d\u062f\u064a\u062f \u0627\u0644\u062a\u0627\u0631\u064a\u062e \u0648\u0627\u0644\u0648\u0635\u0641 \u0648\u0627\u0644\u0645\u0628\u0644\u063a \u0648\u0645\u0646 \u0627\u0644\u0630\u064a \u062f\u0641\u0639.';
      case ExpenseTableScope.olderThan24Hours:
        return '\u0639\u0631\u0636 \u062d\u0631\u0643\u0627\u062a \u0627\u0644\u0623\u064a\u0627\u0645 \u0627\u0644\u0633\u0627\u0628\u0642\u0629 \u0628\u0646\u0641\u0633 \u0627\u0644\u062c\u062f\u0648\u0644 \u0627\u0644\u0645\u0648\u062d\u062f \u0648\u0628\u062f\u0648\u0646 \u0625\u062c\u0645\u0627\u0644\u064a\u0627\u062a \u064a\u0648\u0645\u064a\u0629.';
      case ExpenseTableScope.all:
        return '\u062c\u062f\u0648\u0644 \u064a\u0648\u0645\u064a \u0645\u0648\u062d\u062f \u064a\u0639\u0631\u0636 \u0643\u0644 \u0627\u0644\u0645\u0635\u0631\u0648\u0641\u0627\u062a \u0627\u0644\u0645\u0633\u062c\u0644\u0629 \u062f\u0627\u062e\u0644 \u0627\u0644\u0645\u0634\u0631\u0648\u0639 \u0645\u0639 Totals \u0641\u0642\u0637 \u0644\u0643\u0644 \u0637\u0631\u0641.';
    }
  }

  String get _emptyTitle {
    switch (scope) {
      case ExpenseTableScope.recent24Hours:
        return '\u0644\u0627 \u062a\u0648\u062c\u062f \u0645\u0635\u0631\u0648\u0641\u0627\u062a \u0627\u0644\u064a\u0648\u0645';
      case ExpenseTableScope.olderThan24Hours:
        return '\u0644\u0627 \u062a\u0648\u062c\u062f \u0645\u0635\u0631\u0648\u0641\u0627\u062a \u0644\u0644\u0623\u064a\u0627\u0645 \u0627\u0644\u0633\u0627\u0628\u0642\u0629';
      case ExpenseTableScope.all:
        return '\u0644\u0627 \u062a\u0648\u062c\u062f \u0645\u0635\u0631\u0648\u0641\u0627\u062a \u0628\u0639\u062f';
    }
  }

  String get _emptyMessage {
    switch (scope) {
      case ExpenseTableScope.recent24Hours:
        return '\u0628\u0645\u062c\u0631\u062f \u062a\u0633\u062c\u064a\u0644 \u0623\u0648\u0644 \u0645\u0635\u0631\u0648\u0641 \u0628\u062a\u0627\u0631\u064a\u062e \u0627\u0644\u064a\u0648\u0645 \u0633\u064a\u0638\u0647\u0631 \u0647\u0646\u0627 \u062f\u0627\u062e\u0644 \u0627\u0644\u062c\u062f\u0648\u0644.';
      case ExpenseTableScope.olderThan24Hours:
        return '\u0639\u0646\u062f \u0648\u062c\u0648\u062f \u0645\u0635\u0631\u0648\u0641\u0627\u062a \u0628\u062a\u0648\u0627\u0631\u064a\u062e \u0623\u0642\u062f\u0645 \u0645\u0646 \u0627\u0644\u064a\u0648\u0645 \u0633\u062a\u0638\u0647\u0631 \u0647\u0646\u0627 \u062a\u0644\u0642\u0627\u0626\u064a\u064b\u0627.';
      case ExpenseTableScope.all:
        return '\u0623\u0636\u0641 \u0623\u0648\u0644 \u0645\u0635\u0631\u0648\u0641 \u0644\u064a\u0628\u062f\u0623 \u0627\u0644\u062c\u062f\u0648\u0644 \u0627\u0644\u064a\u0648\u0645\u064a \u0648\u062a\u0638\u0647\u0631 Totals \u0644\u0644\u0645\u0633\u062a\u062e\u062f\u0645 \u0648\u0627\u0644\u0634\u0631\u064a\u0643.';
    }
  }

  String get _splitTableTitle {
    if (_isPreviewMode) {
      return '\u0622\u062e\u0631 \u0627\u0644\u0645\u0635\u0631\u0648\u0641\u0627\u062a';
    }
    return '\u062c\u062f\u0648\u0644 \u0627\u0644\u0645\u0635\u0631\u0648\u0641\u0627\u062a';
  }

  String? get _splitTableSubtitle {
    if (_isPreviewMode) {
      return '\u064a\u0639\u0631\u0636 \u0622\u062e\u0631 $maxVisibleRows \u0645\u0635\u0627\u0631\u064a\u0641 \u0641\u0642\u0637. \u0627\u0641\u062a\u062d \u0639\u0631\u0636 \u0643\u0644 \u0627\u0644\u0645\u0635\u0627\u0631\u064a\u0641 \u0644\u0631\u0624\u064a\u0629 \u0627\u0644\u0633\u062c\u0644 \u0628\u0627\u0644\u0643\u0627\u0645\u0644.';
    }
    return null;
  }

  bool get _isPreviewMode {
    return !showDetailedLedger &&
        scope == ExpenseTableScope.all &&
        maxVisibleRows != null;
  }

  List<_ExpenseTableRow> _buildRows({bool applyLimit = true}) {
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
    final limit = applyLimit ? maxVisibleRows : null;
    if (limit == null || rows.length <= limit) {
      return rows;
    }
    return rows.take(limit).toList(growable: false);
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
        : (data.linkedPartnerName ??
              '\u0627\u0644\u0634\u0631\u064a\u0643 \u0627\u0644\u0645\u0631\u062a\u0628\u0637');
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
      title:
          '\u0645\u0644\u062e\u0635 \u0627\u0644\u0645\u0635\u0631\u0648\u0641\u0627\u062a',
      subtitle:
          'Totals \u0641\u0642\u0637 \u0644\u0644\u0645\u0633\u062a\u062e\u062f\u0645 \u0648\u0627\u0644\u0634\u0631\u064a\u0643 \u0648\u0627\u0644\u0625\u062c\u0645\u0627\u0644\u064a \u0627\u0644\u0643\u0644\u064a \u0628\u062f\u0648\u0646 \u0623\u064a \u0625\u062c\u0645\u0627\u0644\u064a\u0627\u062a \u064a\u0648\u0645\u064a\u0629.',
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
          _ExpenseMetricPill(
            label:
                '\u0627\u0644\u0625\u062c\u0645\u0627\u0644\u064a \u0627\u0644\u0643\u0644\u064a',
            value: overallTotal.egp,
          ),
          _ExpenseMetricPill(
            label:
                '\u0639\u062f\u062f \u0627\u0644\u062d\u0631\u0643\u0627\u062a',
            value: '$entriesCount',
          ),
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
                        '\u0645\u0635\u0631\u0648\u0641 #$rowNumber',
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
