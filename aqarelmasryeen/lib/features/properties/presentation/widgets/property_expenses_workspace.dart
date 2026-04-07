import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';

class PropertyExpensesWorkspace extends StatelessWidget {
  const PropertyExpensesWorkspace({
    super.key,
    required this.data,
    required this.onOpenMaterials,
    required this.onOpenDetailedExpenses,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  final PropertyProjectViewData data;
  final VoidCallback onOpenMaterials;
  final VoidCallback onOpenDetailedExpenses;
  final ValueChanged<ExpenseRecord> onEditExpense;
  final ValueChanged<ExpenseRecord> onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    final groupedRows = _buildDayRows();
    final today = _dateOnly(DateTime.now());
    final todayRows = data.expenseLedgerRows.where(
      (row) => _dateOnly(row.expense.date) == today,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AddExpensePanel(
          onOpenMaterials: onOpenMaterials,
          todayTotal: data.todayDirectExpenses,
          overallTotal: data.totalDirectExpenses,
          entriesCount: data.expenseLedgerRows.length,
        ),
        const SizedBox(height: 16),
        _ExpenseComparisonTable(
          currentColumnLabel: data.currentPartner?.name ?? 'المستخدم',
          counterpartColumnLabel: data.counterpartLabel,
          rows: groupedRows,
          currentTodayTotal: _sumRows(todayRows, currentSide: true),
          counterpartTodayTotal: _sumRows(todayRows, currentSide: false),
          currentOverallTotal: _sumRows(
            data.expenseLedgerRows,
            currentSide: true,
          ),
          counterpartOverallTotal: _sumRows(
            data.expenseLedgerRows,
            currentSide: false,
          ),
          onOpenDetailedExpenses: onOpenDetailedExpenses,
          onEditExpense: onEditExpense,
          onDeleteExpense: onDeleteExpense,
        ),
      ],
    );
  }

  List<_ExpenseDayGroup> _buildDayRows() {
    final grouped = <DateTime, _MutableExpenseDayGroup>{};

    for (final row in data.expenseLedgerRows) {
      final day = _dateOnly(row.expense.date);
      final bucket = grouped.putIfAbsent(
        day,
        () => _MutableExpenseDayGroup(day: day),
      );
      if (_isCurrentSide(row)) {
        bucket.currentRows.add(row);
      } else {
        bucket.counterpartRows.add(row);
      }
    }

    return grouped.values
        .map(
          (group) => _ExpenseDayGroup(
            day: group.day,
            currentRows: List<PropertyExpenseLedgerRow>.unmodifiable(
              group.currentRows,
            ),
            counterpartRows: List<PropertyExpenseLedgerRow>.unmodifiable(
              group.counterpartRows,
            ),
          ),
        )
        .toList()
      ..sort((a, b) => b.day.compareTo(a.day));
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
    Iterable<PropertyExpenseLedgerRow> rows, {
    required bool currentSide,
  }) {
    return rows.fold<double>(0, (sum, row) {
      final matchesCurrent = _isCurrentSide(row);
      if (matchesCurrent != currentSide) {
        return sum;
      }
      return sum + row.expense.amount;
    });
  }
}

class _AddExpensePanel extends StatelessWidget {
  const _AddExpensePanel({
    required this.onOpenMaterials,
    required this.todayTotal,
    required this.overallTotal,
    required this.entriesCount,
  });

  final VoidCallback onOpenMaterials;
  final double todayTotal;
  final double overallTotal;
  final int entriesCount;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'ملخص المصروفات',
      subtitle: 'راجع أرقام المصروفات سريعًا وافتح صفحة مواد البناء من هنا.',
      trailing: FilledButton.icon(
        onPressed: onOpenMaterials,
        icon: const Icon(Icons.inventory_2_outlined),
        label: const Text('مواد البناء'),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _ExpenseMetricPill(label: 'مصروفات اليوم', value: todayTotal.egp),
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
    required this.currentColumnLabel,
    required this.counterpartColumnLabel,
    required this.rows,
    required this.currentTodayTotal,
    required this.counterpartTodayTotal,
    required this.currentOverallTotal,
    required this.counterpartOverallTotal,
    required this.onOpenDetailedExpenses,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  final String currentColumnLabel;
  final String counterpartColumnLabel;
  final List<_ExpenseDayGroup> rows;
  final double currentTodayTotal;
  final double counterpartTodayTotal;
  final double currentOverallTotal;
  final double counterpartOverallTotal;
  final VoidCallback onOpenDetailedExpenses;
  final ValueChanged<ExpenseRecord> onEditExpense;
  final ValueChanged<ExpenseRecord> onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'جدول المصروفات',
      subtitle: rows.isEmpty
          ? 'لا توجد مصروفات مسجلة لهذا العقار حتى الآن.'
          : 'الجدول مرتب حسب التاريخ، وكل عمود يعرض المبلغ والوصف للطرف المناسب.',
      trailing: TextButton(
        onPressed: onOpenDetailedExpenses,
        child: const Text('عرض بالتفصيل'),
      ),
      child: rows.isEmpty
          ? const EmptyStateView(
              title: 'لا توجد مصروفات بعد',
              message:
                  'بمجرد إضافة أول مصروف سيظهر هنا تحت المستخدم أو الشريك.',
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth < 460
                    ? 560.0
                    : constraints.maxWidth;
                final innerTableWidth = tableWidth - 2;
                final dateColumnWidth = 100.0;
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
                          _ExpenseDayTableRow(
                            row: row,
                            dateColumnWidth: dateColumnWidth,
                            sideColumnWidth: sideColumnWidth,
                            onEditExpense: onEditExpense,
                            onDeleteExpense: onDeleteExpense,
                          ),
                        _ExpenseTotalsRow(
                          dateColumnWidth: dateColumnWidth,
                          sideColumnWidth: sideColumnWidth,
                          currentTodayTotal: currentTodayTotal,
                          counterpartTodayTotal: counterpartTodayTotal,
                          currentOverallTotal: currentOverallTotal,
                          counterpartOverallTotal: counterpartOverallTotal,
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

class _ExpenseDayTableRow extends StatelessWidget {
  const _ExpenseDayTableRow({
    required this.row,
    required this.dateColumnWidth,
    required this.sideColumnWidth,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  final _ExpenseDayGroup row;
  final double dateColumnWidth;
  final double sideColumnWidth;
  final ValueChanged<ExpenseRecord> onEditExpense;
  final ValueChanged<ExpenseRecord> onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFD9DED6))),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: dateColumnWidth,
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F8F4),
                border: Border(left: BorderSide(color: Color(0xFFD9DED6))),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.day.formatShort(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF17352F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${row.entriesCount} حركة',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            _ExpenseSideCell(
              width: sideColumnWidth,
              entries: row.currentRows,
              tint: const Color(0xFFEAF4EF),
              borderColor: const Color(0xFFD9DED6),
              onEditExpense: onEditExpense,
              onDeleteExpense: onDeleteExpense,
            ),
            _ExpenseSideCell(
              width: sideColumnWidth,
              entries: row.counterpartRows,
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

class _ExpenseSideCell extends StatelessWidget {
  const _ExpenseSideCell({
    required this.width,
    required this.entries,
    required this.tint,
    required this.borderColor,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  final double width;
  final List<PropertyExpenseLedgerRow> entries;
  final Color tint;
  final Color borderColor;
  final ValueChanged<ExpenseRecord> onEditExpense;
  final ValueChanged<ExpenseRecord> onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: borderColor)),
      ),
      child: entries.isEmpty
          ? Center(
              child: Text(
                'لا يوجد',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < entries.length; index++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: width > 190 ? 210 : width - 32,
                            ),
                            child: _ExpenseEntryCard(
                              row: entries[index],
                              tint: tint,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _ExpenseEntryMenuButton(
                        row: entries[index],
                        onEditExpense: onEditExpense,
                        onDeleteExpense: onDeleteExpense,
                      ),
                    ],
                  ),
                  if (index != entries.length - 1) const SizedBox(height: 8),
                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
    required this.currentTodayTotal,
    required this.counterpartTodayTotal,
    required this.currentOverallTotal,
    required this.counterpartOverallTotal,
  });

  final double dateColumnWidth;
  final double sideColumnWidth;
  final double currentTodayTotal;
  final double counterpartTodayTotal;
  final double currentOverallTotal;
  final double counterpartOverallTotal;

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
              'إجماليات الجدول',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF17352F),
              ),
            ),
          ),
          _TotalsCell(
            width: sideColumnWidth,
            todayTotal: currentTodayTotal,
            overallTotal: currentOverallTotal,
          ),
          _TotalsCell(
            width: sideColumnWidth,
            todayTotal: counterpartTodayTotal,
            overallTotal: counterpartOverallTotal,
          ),
        ],
      ),
    );
  }
}

class _TotalsCell extends StatelessWidget {
  const _TotalsCell({
    required this.width,
    required this.todayTotal,
    required this.overallTotal,
  });

  final double width;
  final double todayTotal;
  final double overallTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFD9DED6))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TotalsLine(label: 'إجمالي اليوم', value: todayTotal.egp),
          const SizedBox(height: 6),
          _TotalsLine(label: 'الإجمالي العام', value: overallTotal.egp),
        ],
      ),
    );
  }
}

class _TotalsLine extends StatelessWidget {
  const _TotalsLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF17352F),
          ),
        ),
      ],
    );
  }
}

enum _ExpenseEntryAction { edit, delete }

class _ExpenseDayGroup {
  const _ExpenseDayGroup({
    required this.day,
    required this.currentRows,
    required this.counterpartRows,
  });

  final DateTime day;
  final List<PropertyExpenseLedgerRow> currentRows;
  final List<PropertyExpenseLedgerRow> counterpartRows;

  int get entriesCount => currentRows.length + counterpartRows.length;
}

class _MutableExpenseDayGroup {
  _MutableExpenseDayGroup({required this.day});

  final DateTime day;
  final List<PropertyExpenseLedgerRow> currentRows = [];
  final List<PropertyExpenseLedgerRow> counterpartRows = [];
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
