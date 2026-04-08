import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';

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
    this.showSummaryPanel = true,
    this.showDetailedButton = true,
    this.scope = ExpenseTableScope.recent24Hours,
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
    final allRows = data.expenseLedgerRows
        .map(
          (row) =>
              _ExpenseDisplayRow(row: row, isCurrentSide: _isCurrentSide(row)),
        )
        .toList(growable: false);
    final rows = _filterRows(allRows);
    final recentTotal = _sumAmounts(rows);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSummaryPanel) ...[
          _AddExpensePanel(
            onOpenMaterials: onOpenMaterials,
            todayTotal: recentTotal,
            overallTotal: data.totalDirectExpenses,
            entriesCount: rows.length,
          ),
          const SizedBox(height: 16),
        ],
        _ExpenseComparisonTable(
          title: _tableTitle,
          subtitle: _tableSubtitle(rows.length),
          emptyTitle: _emptyTitle,
          emptyMessage: _emptyMessage,
          currentColumnLabel: data.currentColumnLabel,
          counterpartColumnLabel: data.counterpartColumnLabel,
          rows: rows,
          currentTotal: _sumRows(rows, currentSide: true),
          counterpartTotal: _sumRows(rows, currentSide: false),
          onOpenDetailedExpenses: onOpenDetailedExpenses,
          showDetailedButton: showDetailedButton,
          onAddExpense: onAddExpense,
          onEditExpense: onEditExpense,
          onDeleteExpense: onDeleteExpense,
        ),
      ],
    );
  }

  List<_ExpenseDisplayRow> _filterRows(List<_ExpenseDisplayRow> rows) {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return rows
        .where((row) {
          final isRecent = !row.row.expense.date.isBefore(cutoff);
          switch (scope) {
            case ExpenseTableScope.recent24Hours:
              return isRecent;
            case ExpenseTableScope.olderThan24Hours:
              return !isRecent;
            case ExpenseTableScope.all:
              return true;
          }
        })
        .toList(growable: false);
  }

  bool _isCurrentSide(PropertyExpenseLedgerRow row) {
    final currentPartner = data.currentPartner;
    if (currentPartner != null) {
      return row.payer?.id == currentPartner.id;
    }
    if (data.currentUserId != null) {
      return row.payer?.userId == data.currentUserId;
    }
    return false;
  }

  double _sumRows(
    Iterable<_ExpenseDisplayRow> rows, {
    required bool currentSide,
  }) {
    return rows.fold<double>(0, (sum, row) {
      if (row.isCurrentSide != currentSide) {
        return sum;
      }
      return sum + row.row.expense.amount;
    });
  }

  double _sumAmounts(Iterable<_ExpenseDisplayRow> rows) {
    return rows.fold<double>(0, (sum, row) => sum + row.row.expense.amount);
  }

  String get _tableTitle {
    switch (scope) {
      case ExpenseTableScope.recent24Hours:
        return 'جدول المصروفات اليومية';
      case ExpenseTableScope.olderThan24Hours:
        return 'المصاريف الأقدم';
      case ExpenseTableScope.all:
        return 'جدول المصروفات';
    }
  }

  String _tableSubtitle(int count) {
    switch (scope) {
      case ExpenseTableScope.recent24Hours:
        return count == 0
            ? 'لا توجد مصروفات مسجلة خلال آخر 24 ساعة.'
            : 'يعرض مصروفات آخر 24 ساعة فقط، وما قبل ذلك يظهر في عرض التفاصيل.';
      case ExpenseTableScope.olderThan24Hours:
        return count == 0
            ? 'لا توجد مصروفات أقدم من 24 ساعة.'
            : 'يعرض كل المصروفات الأقدم من آخر 24 ساعة.';
      case ExpenseTableScope.all:
        return count == 0
            ? 'لا توجد مصروفات مسجلة لهذا العقار حتى الآن.'
            : 'كل صف يعرض تاريخ المصروف والمبلغ ووصفه تحت ${data.currentColumnLabel} أو ${data.counterpartColumnLabel}.';
    }
  }

  String get _emptyTitle {
    switch (scope) {
      case ExpenseTableScope.recent24Hours:
        return 'لا توجد مصروفات يومية';
      case ExpenseTableScope.olderThan24Hours:
        return 'لا توجد مصروفات قديمة';
      case ExpenseTableScope.all:
        return 'لا توجد مصروفات بعد';
    }
  }

  String get _emptyMessage {
    switch (scope) {
      case ExpenseTableScope.recent24Hours:
        return 'بمجرد إضافة مصروف خلال آخر 24 ساعة سيظهر هنا تحت ${data.currentColumnLabel} أو ${data.counterpartColumnLabel}.';
      case ExpenseTableScope.olderThan24Hours:
        return 'كل المصروفات الأقدم من 24 ساعة ستظهر هنا تلقائيًا.';
      case ExpenseTableScope.all:
        return 'بمجرد إضافة أول مصروف سيظهر هنا التاريخ والمبلغ والوصف لـ ${data.currentColumnLabel} أو ${data.counterpartColumnLabel}.';
    }
  }
}

class _AddExpensePanel extends StatelessWidget {
  const _AddExpensePanel({
    required this.onOpenMaterials,
    required this.todayTotal,
    required this.overallTotal,
    required this.entriesCount,
  });

  final VoidCallback? onOpenMaterials;
  final double todayTotal;
  final double overallTotal;
  final int entriesCount;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'ملخص المصروفات',
      subtitle: 'راجع أرقام المصروفات سريعًا وافتح صفحة مواد البناء من هنا.',
      trailing: onOpenMaterials == null
          ? null
          : FilledButton.icon(
              onPressed: onOpenMaterials,
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('مواد البناء'),
            ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _ExpenseMetricPill(
            label: 'مصروفات آخر 24 ساعة',
            value: todayTotal.egp,
          ),
          _ExpenseMetricPill(label: 'الإجمالي العام', value: overallTotal.egp),
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
      constraints: const BoxConstraints(minWidth: 120),
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

class _ExpenseComparisonTable extends StatelessWidget {
  const _ExpenseComparisonTable({
    required this.title,
    required this.subtitle,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.currentColumnLabel,
    required this.counterpartColumnLabel,
    required this.rows,
    required this.currentTotal,
    required this.counterpartTotal,
    required this.onOpenDetailedExpenses,
    required this.showDetailedButton,
    required this.onAddExpense,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  final String title;
  final String subtitle;
  final String emptyTitle;
  final String emptyMessage;
  final String currentColumnLabel;
  final String counterpartColumnLabel;
  final List<_ExpenseDisplayRow> rows;
  final double currentTotal;
  final double counterpartTotal;
  final VoidCallback? onOpenDetailedExpenses;
  final bool showDetailedButton;
  final VoidCallback? onAddExpense;
  final ValueChanged<ExpenseRecord> onEditExpense;
  final ValueChanged<ExpenseRecord> onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: title,
      subtitle: subtitle,
      trailing: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (showDetailedButton && onOpenDetailedExpenses != null)
            TextButton(
              onPressed: onOpenDetailedExpenses,
              child: const Text('عرض بالتفصيل'),
            ),
          if (onAddExpense != null)
            FilledButton.icon(
              onPressed: onAddExpense,
              icon: const Icon(Icons.add),
              label: const Text('إضافة مصروف يومي'),
            ),
        ],
      ),
      child: rows.isEmpty
          ? EmptyStateView(title: emptyTitle, message: emptyMessage)
          : LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth < 520
                    ? 620.0
                    : constraints.maxWidth;
                final innerTableWidth = tableWidth - 2;
                final dateColumnWidth = 126.0;
                final sideColumnWidth = (innerTableWidth - dateColumnWidth) / 2;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: tableWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFEFB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD9DED6)),
                    ),
                    child: Column(
                      children: [
                        _ExpenseTableHeader(
                          dateColumnWidth: dateColumnWidth,
                          sideColumnWidth: sideColumnWidth,
                          currentColumnLabel: currentColumnLabel,
                          counterpartColumnLabel: counterpartColumnLabel,
                        ),
                        for (final row in rows)
                          _ExpenseLedgerTableRow(
                            row: row,
                            dateColumnWidth: dateColumnWidth,
                            sideColumnWidth: sideColumnWidth,
                            onEditExpense: onEditExpense,
                            onDeleteExpense: onDeleteExpense,
                          ),
                        _ExpenseTotalsRow(
                          dateColumnWidth: dateColumnWidth,
                          sideColumnWidth: sideColumnWidth,
                          currentColumnLabel: currentColumnLabel,
                          counterpartColumnLabel: counterpartColumnLabel,
                          currentTotal: currentTotal,
                          counterpartTotal: counterpartTotal,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ExpenseTableHeader extends StatelessWidget {
  const _ExpenseTableHeader({
    required this.dateColumnWidth,
    required this.sideColumnWidth,
    required this.currentColumnLabel,
    required this.counterpartColumnLabel,
  });

  final double dateColumnWidth;
  final double sideColumnWidth;
  final String currentColumnLabel;
  final String counterpartColumnLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE7EEE6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          _HeaderCell(width: dateColumnWidth, label: 'التاريخ'),
          _HeaderCell(width: sideColumnWidth, label: currentColumnLabel),
          _HeaderCell(width: sideColumnWidth, label: counterpartColumnLabel),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.width, required this.label});

  final double width;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFD9DED6))),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF21463D),
        ),
      ),
    );
  }
}

class _ExpenseLedgerTableRow extends StatelessWidget {
  const _ExpenseLedgerTableRow({
    required this.row,
    required this.dateColumnWidth,
    required this.sideColumnWidth,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  final _ExpenseDisplayRow row;
  final double dateColumnWidth;
  final double sideColumnWidth;
  final ValueChanged<ExpenseRecord> onEditExpense;
  final ValueChanged<ExpenseRecord> onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    final currentRow = row.isCurrentSide ? row.row : null;
    final counterpartRow = row.isCurrentSide ? null : row.row;

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFD9DED6))),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ExpenseDateCell(
              width: dateColumnWidth,
              date: row.row.expense.date,
            ),
            _ExpenseSideCell(
              width: sideColumnWidth,
              entry: currentRow,
              tint: const Color(0xFFEAF4EF),
              borderColor: const Color(0xFFD9DED6),
              onEditExpense: onEditExpense,
              onDeleteExpense: onDeleteExpense,
            ),
            _ExpenseSideCell(
              width: sideColumnWidth,
              entry: counterpartRow,
              tint: const Color(0xFFF6F4EF),
              borderColor: const Color(0xFFD9DED6),
              onEditExpense: onEditExpense,
              onDeleteExpense: onDeleteExpense,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseDateCell extends StatelessWidget {
  const _ExpenseDateCell({required this.width, required this.date});

  final double width;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8F4),
        border: Border(left: BorderSide(color: Color(0xFFD9DED6))),
      ),
      alignment: Alignment.center,
      child: Text(
        date.formatShort(),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF17352F),
        ),
      ),
    );
  }
}

class _ExpenseSideCell extends StatelessWidget {
  const _ExpenseSideCell({
    required this.width,
    required this.entry,
    required this.tint,
    required this.borderColor,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  final double width;
  final PropertyExpenseLedgerRow? entry;
  final Color tint;
  final Color borderColor;
  final ValueChanged<ExpenseRecord> onEditExpense;
  final ValueChanged<ExpenseRecord> onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: borderColor)),
      ),
      child: entry == null
          ? Center(
              child: Text(
                'لا يوجد',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ExpenseEntryCard(row: entry!, tint: tint),
                ),
                const SizedBox(width: 6),
                _ExpenseEntryMenuButton(
                  row: entry!,
                  onEditExpense: onEditExpense,
                  onDeleteExpense: onDeleteExpense,
                ),
              ],
            ),
    );
  }
}

class _ExpenseEntryCard extends StatelessWidget {
  const _ExpenseEntryCard({required this.row, required this.tint});

  final PropertyExpenseLedgerRow row;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final description = row.expense.description.trim().isEmpty
        ? row.expense.category.label
        : row.expense.description.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD5DDD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            row.expense.amount.egp,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF17352F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF40564F),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseEntryMenuButton extends StatelessWidget {
  const _ExpenseEntryMenuButton({
    required this.row,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  final PropertyExpenseLedgerRow row;
  final ValueChanged<ExpenseRecord> onEditExpense;
  final ValueChanged<ExpenseRecord> onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ExpenseEntryAction>(
      tooltip: 'خيارات الحركة',
      padding: EdgeInsets.zero,
      iconSize: 18,
      onSelected: (action) {
        switch (action) {
          case _ExpenseEntryAction.edit:
            onEditExpense(row.expense);
            break;
          case _ExpenseEntryAction.delete:
            onDeleteExpense(row.expense);
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: _ExpenseEntryAction.edit, child: Text('تعديل')),
        PopupMenuItem(value: _ExpenseEntryAction.delete, child: Text('حذف')),
      ],
    );
  }
}

class _ExpenseTotalsRow extends StatelessWidget {
  const _ExpenseTotalsRow({
    required this.dateColumnWidth,
    required this.sideColumnWidth,
    required this.currentColumnLabel,
    required this.counterpartColumnLabel,
    required this.currentTotal,
    required this.counterpartTotal,
  });

  final double dateColumnWidth;
  final double sideColumnWidth;
  final String currentColumnLabel;
  final String counterpartColumnLabel;
  final double currentTotal;
  final double counterpartTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF3F5F0),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0xFFD9DED6))),
      ),
      child: Row(
        children: [
          Container(
            width: dateColumnWidth,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Color(0xFFD9DED6))),
            ),
            child: Text(
              'الإجمالي',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF17352F),
              ),
            ),
          ),
          _TotalsCell(
            width: sideColumnWidth,
            label: 'إجمالي $currentColumnLabel',
            total: currentTotal,
          ),
          _TotalsCell(
            width: sideColumnWidth,
            label: 'إجمالي $counterpartColumnLabel',
            total: counterpartTotal,
          ),
        ],
      ),
    );
  }
}

class _TotalsCell extends StatelessWidget {
  const _TotalsCell({
    required this.width,
    required this.label,
    required this.total,
  });

  final double width;
  final String label;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFD9DED6))),
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
            total.egp,
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

enum _ExpenseEntryAction { edit, delete }

class _ExpenseDisplayRow {
  const _ExpenseDisplayRow({required this.row, required this.isCurrentSide});

  final PropertyExpenseLedgerRow row;
  final bool isCurrentSide;
}
