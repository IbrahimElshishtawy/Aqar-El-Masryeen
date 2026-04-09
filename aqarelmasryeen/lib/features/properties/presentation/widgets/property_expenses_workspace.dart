import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:collection/collection.dart';
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
    final filteredRows = _filterRows(data.expenseLedgerRows);
    final linkedPartner = data.counterpartPartners.firstOrNull;
    final dayRows = _buildDayRows(filteredRows, linkedPartner: linkedPartner);

    final currentColumnLabel = 'المستخدم';
    final counterpartColumnLabel = linkedPartner == null
        ? 'الشريك المرتبط'
        : 'الشريك المرتبط (${linkedPartner.name})';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSummaryPanel) ...[
          _AddExpensePanel(
            onOpenMaterials: onOpenMaterials,
            linkedPartnerName: linkedPartner?.name.trim(),
            todayTotal: _sumAmounts(filteredRows),
            overallTotal: data.totalDirectExpenses,
            entriesCount: filteredRows.length,
          ),
          const SizedBox(height: 16),
        ],
        _ExpenseComparisonTable(
          title: _tableTitle,
          subtitle: _tableSubtitle(dayRows.length),
          emptyTitle: _emptyTitle,
          emptyMessage: _emptyMessage(
            currentColumnLabel: currentColumnLabel,
            counterpartColumnLabel: counterpartColumnLabel,
          ),
          currentColumnLabel: currentColumnLabel,
          counterpartColumnLabel: counterpartColumnLabel,
          dayRows: dayRows,
          currentTotal: _sumRows(dayRows, currentSide: true),
          counterpartTotal: _sumRows(dayRows, currentSide: false),
          linkedPartner: linkedPartner,
          partners: data.partners,
          currentUserId: data.currentUserId,
          onOpenDetailedExpenses: onOpenDetailedExpenses,
          showDetailedButton: showDetailedButton,
          onAddExpense: onAddExpense,
          onEditExpense: onEditExpense,
          onDeleteExpense: onDeleteExpense,
        ),
      ],
    );
  }

  List<PropertyExpenseLedgerRow> _filterRows(List<PropertyExpenseLedgerRow> rows) {
    final today = DateTime.now();
    return rows
        .where((row) {
          final isToday = DateUtils.isSameDay(row.expense.date, today);
          switch (scope) {
            case ExpenseTableScope.recent24Hours:
              return isToday;
            case ExpenseTableScope.olderThan24Hours:
              return !isToday;
            case ExpenseTableScope.all:
              return true;
          }
        })
        .toList(growable: false);
  }

  List<_DailyExpenseComparisonRow> _buildDayRows(
    List<PropertyExpenseLedgerRow> rows, {
    required Partner? linkedPartner,
  }) {
    final grouped = rows.groupListsBy(
      (row) => DateTime(
        row.expense.date.year,
        row.expense.date.month,
        row.expense.date.day,
      ),
    );

    return grouped.entries
        .map((entry) {
          final currentEntries = entry.value
              .where((row) => _isCurrentSide(row))
              .toList(growable: false);
          final counterpartEntries = linkedPartner == null
              ? const <PropertyExpenseLedgerRow>[]
              : entry.value
                    .where((row) => _isLinkedCounterpart(row, linkedPartner))
                    .toList(growable: false);
          return _DailyExpenseComparisonRow(
            day: entry.key,
            currentEntries: currentEntries,
            counterpartEntries: counterpartEntries,
          );
        })
        .sorted((a, b) => b.day.compareTo(a.day));
  }

  bool _isCurrentSide(PropertyExpenseLedgerRow row) {
    final currentPartner = data.currentPartner;
    if (currentPartner != null) {
      return row.payer?.id == currentPartner.id;
    }
    if (data.currentUserId != null) {
      return row.expense.createdBy == data.currentUserId;
    }
    return false;
  }

  bool _isLinkedCounterpart(PropertyExpenseLedgerRow row, Partner linkedPartner) {
    if (row.payer?.id == linkedPartner.id) {
      return true;
    }
    return linkedPartner.userId.isNotEmpty &&
        row.expense.createdBy == linkedPartner.userId;
  }

  double _sumRows(
    Iterable<_DailyExpenseComparisonRow> rows, {
    required bool currentSide,
  }) {
    return rows.fold<double>(0, (sum, row) {
      final entries = currentSide ? row.currentEntries : row.counterpartEntries;
      return sum +
          entries.fold<double>(
            0,
            (sideSum, entry) => sideSum + entry.expense.amount,
          );
    });
  }

  double _sumAmounts(Iterable<PropertyExpenseLedgerRow> rows) {
    return rows.fold<double>(0, (sum, row) => sum + row.expense.amount);
  }

  String get _tableTitle {
    switch (scope) {
      case ExpenseTableScope.recent24Hours:
        return 'جدول المصروفات اليومية';
      case ExpenseTableScope.olderThan24Hours:
        return 'مصاريف الأيام السابقة';
      case ExpenseTableScope.all:
        return 'جدول المصروفات';
    }
  }

  String _tableSubtitle(int count) {
    switch (scope) {
      case ExpenseTableScope.recent24Hours:
        return count == 0
            ? 'لا توجد مصروفات مسجلة بتاريخ اليوم.'
            : 'يعرض مصروفات اليوم للمستخدم والشريك المرتبط في نفس الصف.';
      case ExpenseTableScope.olderThan24Hours:
        return count == 0
            ? 'لا توجد مصروفات بتواريخ أقدم من اليوم.'
            : 'يعرض كل المصروفات مرتبة حسب تواريخ الأيام السابقة.';
      case ExpenseTableScope.all:
        return count == 0
            ? 'لا توجد مصروفات مسجلة لهذا العقار حتى الآن.'
            : 'كل صف يمثل يومًا واحدًا ويقسم مصروفات المستخدم والشريك بوضوح.';
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

  String _emptyMessage({
    required String currentColumnLabel,
    required String counterpartColumnLabel,
  }) {
    switch (scope) {
      case ExpenseTableScope.recent24Hours:
        return 'بمجرد إضافة مصروف بتاريخ اليوم سيظهر هنا تحت $currentColumnLabel أو $counterpartColumnLabel.';
      case ExpenseTableScope.olderThan24Hours:
        return 'كل المصروفات المسجلة في أيام أقدم من اليوم ستظهر هنا تلقائيًا.';
      case ExpenseTableScope.all:
        return 'بمجرد إضافة أول مصروف سيظهر هنا التاريخ وإجمالي كل طرف.';
    }
  }
}

class _AddExpensePanel extends StatelessWidget {
  const _AddExpensePanel({
    required this.onOpenMaterials,
    required this.linkedPartnerName,
    required this.todayTotal,
    required this.overallTotal,
    required this.entriesCount,
  });

  final VoidCallback? onOpenMaterials;
  final String? linkedPartnerName;
  final double todayTotal;
  final double overallTotal;
  final int entriesCount;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'ملخص المصروفات',
      subtitle:
          'راجع أرقام مصروفات اليوم سريعًا وافتح صفحة مواد البناء من هنا.',
      trailing: onOpenMaterials == null
          ? null
          : FilledButton.icon(
              onPressed: onOpenMaterials,
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('مواد البناء'),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (linkedPartnerName?.isNotEmpty == true) ...[
            _InfoBanner(
              message: 'الحساب الحالي مربوط بالشريك: $linkedPartnerName',
              color: const Color(0xFFEAF4EF),
              textColor: const Color(0xFF1D5140),
            ),
            const SizedBox(height: 12),
          ] else ...[
            const _InfoBanner(
              message: 'لا يوجد شريك مرتبط بهذا الحساب',
              color: Color(0xFFFFF4E6),
              textColor: Color(0xFF9A5A00),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ExpenseMetricPill(label: 'مصاريف اليوم', value: todayTotal.egp),
              _ExpenseMetricPill(label: 'الإجمالي العام', value: overallTotal.egp),
              _ExpenseMetricPill(label: 'عدد الحركات', value: '$entriesCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.message,
    required this.color,
    required this.textColor,
  });

  final String message;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline_rounded, size: 18, color: textColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
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
    required this.dayRows,
    required this.currentTotal,
    required this.counterpartTotal,
    required this.linkedPartner,
    required this.partners,
    required this.currentUserId,
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
  final List<_DailyExpenseComparisonRow> dayRows;
  final double currentTotal;
  final double counterpartTotal;
  final Partner? linkedPartner;
  final List<Partner> partners;
  final String? currentUserId;
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
      child: dayRows.isEmpty
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
                        for (final row in dayRows)
                          _ExpenseLedgerTableRow(
                            row: row,
                            dateColumnWidth: dateColumnWidth,
                            sideColumnWidth: sideColumnWidth,
                            linkedPartner: linkedPartner,
                            partners: partners,
                            currentUserId: currentUserId,
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
    required this.linkedPartner,
    required this.partners,
    required this.currentUserId,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  final _DailyExpenseComparisonRow row;
  final double dateColumnWidth;
  final double sideColumnWidth;
  final Partner? linkedPartner;
  final List<Partner> partners;
  final String? currentUserId;
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
            _ExpenseDateCell(width: dateColumnWidth, date: row.day),
            _ExpenseDaySideCell(
              width: sideColumnWidth,
              day: row.day,
              entries: row.currentEntries,
              counterpartEntries: row.counterpartEntries,
              tint: const Color(0xFFEAF4EF),
              borderColor: const Color(0xFFD9DED6),
              title: 'مصروفات المستخدم',
              counterpartTitle: linkedPartner == null
                  ? 'مصروفات الشريك'
                  : 'مصروفات ${linkedPartner!.name}',
              partners: partners,
              currentUserId: currentUserId,
              sideOwner: null,
              onEditExpense: onEditExpense,
              onDeleteExpense: onDeleteExpense,
            ),
            _ExpenseDaySideCell(
              width: sideColumnWidth,
              day: row.day,
              entries: row.counterpartEntries,
              counterpartEntries: row.currentEntries,
              tint: const Color(0xFFF6F4EF),
              borderColor: const Color(0xFFD9DED6),
              title: linkedPartner == null
                  ? 'مصروفات الشريك'
                  : 'مصروفات ${linkedPartner!.name}',
              counterpartTitle: 'مصروفات المستخدم',
              partners: partners,
              currentUserId: currentUserId,
              sideOwner: linkedPartner,
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

class _ExpenseDaySideCell extends StatelessWidget {
  const _ExpenseDaySideCell({
    required this.width,
    required this.day,
    required this.entries,
    required this.counterpartEntries,
    required this.tint,
    required this.borderColor,
    required this.title,
    required this.counterpartTitle,
    required this.partners,
    required this.currentUserId,
    required this.sideOwner,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  final double width;
  final DateTime day;
  final List<PropertyExpenseLedgerRow> entries;
  final List<PropertyExpenseLedgerRow> counterpartEntries;
  final Color tint;
  final Color borderColor;
  final String title;
  final String counterpartTitle;
  final List<Partner> partners;
  final String? currentUserId;
  final Partner? sideOwner;
  final ValueChanged<ExpenseRecord> onEditExpense;
  final ValueChanged<ExpenseRecord> onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<double>(0, (sum, item) => sum + item.expense.amount);
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: borderColor)),
      ),
      child: entries.isEmpty
          ? Center(
              child: Text(
                'لا يوجد',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            )
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD5DDD5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    total.egp,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF17352F),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$title • ${entries.length} حركة',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF40564F),
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _showDayDetails(
                      context,
                      day: day,
                      primaryEntries: entries,
                      primaryTitle: title,
                      secondaryEntries: counterpartEntries,
                      secondaryTitle: counterpartTitle,
                      partners: partners,
                      currentUserId: currentUserId,
                      sideOwner: sideOwner,
                      onEditExpense: onEditExpense,
                      onDeleteExpense: onDeleteExpense,
                    ),
                    child: const Text('عرض التفصيل'),
                  ),
                ],
              ),
            ),
    );
  }
}

Future<void> _showDayDetails(
  BuildContext context, {
  required DateTime day,
  required List<PropertyExpenseLedgerRow> primaryEntries,
  required String primaryTitle,
  required List<PropertyExpenseLedgerRow> secondaryEntries,
  required String secondaryTitle,
  required List<Partner> partners,
  required String? currentUserId,
  required Partner? sideOwner,
  required ValueChanged<ExpenseRecord> onEditExpense,
  required ValueChanged<ExpenseRecord> onDeleteExpense,
}) {
  final primary = primaryEntries.sorted(
    (a, b) => b.expense.updatedAt.compareTo(a.expense.updatedAt),
  );
  final secondary = secondaryEntries.sorted(
    (a, b) => b.expense.updatedAt.compareTo(a.expense.updatedAt),
  );

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('تفاصيل مصروفات ${day.formatShort()}'),
      content: SizedBox(
        width: 520,
        child: ListView(
          shrinkWrap: true,
          children: [
            _ExpenseDetailsSection(
              title: primaryTitle,
              entries: primary,
              partners: partners,
              currentUserId: currentUserId,
              sideOwner: sideOwner,
              onEditExpense: onEditExpense,
              onDeleteExpense: onDeleteExpense,
            ),
            const SizedBox(height: 16),
            _ExpenseDetailsSection(
              title: secondaryTitle,
              entries: secondary,
              partners: partners,
              currentUserId: currentUserId,
              sideOwner: sideOwner,
              onEditExpense: onEditExpense,
              onDeleteExpense: onDeleteExpense,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    ),
  );
}

class _ExpenseDetailsSection extends StatelessWidget {
  const _ExpenseDetailsSection({
    required this.title,
    required this.entries,
    required this.partners,
    required this.currentUserId,
    required this.sideOwner,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  final String title;
  final List<PropertyExpenseLedgerRow> entries;
  final List<Partner> partners;
  final String? currentUserId;
  final Partner? sideOwner;
  final ValueChanged<ExpenseRecord> onEditExpense;
  final ValueChanged<ExpenseRecord> onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          const Text('لا يوجد')
        else
          ...entries.map((row) {
            final expense = row.expense;
            final actor = _resolveCreatedByLabel(
              expense: expense,
              partners: partners,
              currentUserId: currentUserId,
              sideOwner: sideOwner,
            );
            final description = expense.description.trim().isEmpty
                ? expense.category.label
                : expense.description.trim();
            final time = TimeOfDay.fromDateTime(expense.updatedAt).format(
              context,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.amount.egp,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text('النوع: ${expense.category.label}'),
                  Text('الوصف: $description'),
                  Text('الوقت: $time'),
                  Text('من قام بالإضافة: $actor'),
                  if (expense.notes.trim().isNotEmpty)
                    Text('ملاحظات: ${expense.notes.trim()}'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onEditExpense(expense);
                        },
                        child: const Text('تعديل'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onDeleteExpense(expense);
                        },
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                ],
              ),
            );
          }),
      ],
    );
  }
}

String _resolveCreatedByLabel({
  required ExpenseRecord expense,
  required List<Partner> partners,
  required String? currentUserId,
  required Partner? sideOwner,
}) {
  if (currentUserId != null && expense.createdBy == currentUserId) {
    return 'المستخدم الحالي';
  }
  final byUser = partners.firstWhereOrNull(
    (partner) => partner.userId == expense.createdBy,
  );
  if (byUser != null && byUser.name.trim().isNotEmpty) {
    return byUser.name.trim();
  }
  if (sideOwner?.name.trim().isNotEmpty == true) {
    return sideOwner!.name.trim();
  }
  return 'غير معروف';
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

class _DailyExpenseComparisonRow {
  const _DailyExpenseComparisonRow({
    required this.day,
    required this.currentEntries,
    required this.counterpartEntries,
  });

  final DateTime day;
  final List<PropertyExpenseLedgerRow> currentEntries;
  final List<PropertyExpenseLedgerRow> counterpartEntries;
}
