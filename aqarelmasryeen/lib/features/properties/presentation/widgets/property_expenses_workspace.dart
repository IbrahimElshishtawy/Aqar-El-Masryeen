import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
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
    final entries = data.expenseLedgerRows
        .map(
          (row) => _ExpenseDisplayEntry(
            row: row,
            isCurrentSide: _isCurrentSide(row),
            ownerLabel: _ownerLabel(row),
            addedByLabel: _addedByLabel(row),
          ),
        )
        .toList(growable: false);
    final groups = _buildDayGroups(entries);
    final currentTotal = groups.fold<double>(
      0,
      (sum, group) => sum + group.currentTotal,
    );
    final counterpartTotal = groups.fold<double>(
      0,
      (sum, group) => sum + group.counterpartTotal,
    );
    final overallTotal = currentTotal + counterpartTotal;
    final entriesCount = groups.fold<int>(
      0,
      (sum, group) =>
          sum + group.currentEntries.length + group.counterpartEntries.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSummaryPanel) ...[
          _AddExpensePanel(
            onOpenMaterials: onOpenMaterials,
            linkedPartnerName: data.linkedPartnerName,
            hasLinkedPartner: data.hasLinkedPartner,
            currentTotal: currentTotal,
            counterpartTotal: counterpartTotal,
            overallTotal: overallTotal,
            entriesCount: entriesCount,
          ),
          const SizedBox(height: 16),
        ],
        _ExpenseComparisonTable(
          title: _tableTitle,
          subtitle: _tableSubtitle(groups.length),
          emptyTitle: _emptyTitle,
          emptyMessage: _emptyMessage,
          currentColumnLabel: data.currentColumnLabel,
          counterpartColumnLabel: data.counterpartColumnLabel,
          groups: groups,
          currentTotal: currentTotal,
          counterpartTotal: counterpartTotal,
          hasLinkedPartner: data.hasLinkedPartner,
          onOpenDetailedExpenses: onOpenDetailedExpenses,
          showDetailedButton: showDetailedButton,
          onAddExpense: onAddExpense,
          onEditExpense: onEditExpense,
          onDeleteExpense: onDeleteExpense,
          onOpenDayDetails: (group, currentSide) =>
              _showDayDetails(context, group, currentSide: currentSide),
        ),
      ],
    );
  }

  List<_ExpenseDayGroup> _buildDayGroups(List<_ExpenseDisplayEntry> entries) {
    final filteredEntries = entries.where((entry) {
      final isToday = DateUtils.isSameDay(entry.row.expense.date, DateTime.now());
      switch (scope) {
        case ExpenseTableScope.recent24Hours:
          return isToday;
        case ExpenseTableScope.olderThan24Hours:
          return !isToday;
        case ExpenseTableScope.all:
          return true;
      }
    }).toList()
      ..sort((a, b) => b.row.expense.date.compareTo(a.row.expense.date));

    final grouped = <DateTime, List<_ExpenseDisplayEntry>>{};
    for (final entry in filteredEntries) {
      final day = DateTime(
        entry.row.expense.date.year,
        entry.row.expense.date.month,
        entry.row.expense.date.day,
      );
      grouped.putIfAbsent(day, () => []).add(entry);
    }

    return grouped.entries.map((entry) {
      final currentEntries =
          entry.value.where((item) => item.isCurrentSide).toList(growable: false);
      final counterpartEntries = entry.value
          .where((item) => !item.isCurrentSide)
          .toList(growable: false);
      return _ExpenseDayGroup(
        day: entry.key,
        currentEntries: currentEntries,
        counterpartEntries: counterpartEntries,
      );
    }).toList()
      ..sort((a, b) => b.day.compareTo(a.day));
  }

  bool _isCurrentSide(PropertyExpenseLedgerRow row) {
    if (data.currentUserId != null && row.expense.createdBy == data.currentUserId) {
      return true;
    }
    if (data.currentPartner != null &&
        row.expense.paidByPartnerId == data.currentPartner!.id) {
      return true;
    }
    return false;
  }

  String _ownerLabel(PropertyExpenseLedgerRow row) {
    if (_isCurrentSide(row)) {
      return data.currentUserDisplayName;
    }
    final partnerName = row.payer?.name.trim() ?? '';
    if (partnerName.isNotEmpty) {
      return partnerName;
    }
    return data.linkedPartnerName ?? 'الشريك المرتبط';
  }

  String _addedByLabel(PropertyExpenseLedgerRow row) {
    if (data.currentUserId != null && row.expense.createdBy == data.currentUserId) {
      return data.currentUserDisplayName;
    }
    final partnerName = row.payer?.name.trim() ?? '';
    if (partnerName.isNotEmpty) {
      return partnerName;
    }
    return 'مستخدم غير محدد';
  }

  void _showDayDetails(
    BuildContext context,
    _ExpenseDayGroup group, {
    required bool currentSide,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _ExpenseDayDetailsSheet(
        group: group,
        currentLabel: data.currentColumnLabel,
        counterpartLabel: data.counterpartColumnLabel,
        currentDisplayName: data.currentUserDisplayName,
        hasLinkedPartner: data.hasLinkedPartner,
        initialCurrentSide: currentSide,
        onEditExpense: onEditExpense,
        onDeleteExpense: onDeleteExpense,
      ),
    );
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

  String _tableSubtitle(int groupsCount) {
    switch (scope) {
      case ExpenseTableScope.recent24Hours:
        return groupsCount == 0
            ? 'لا توجد أي مصروفات مسجلة على تاريخ اليوم.'
            : 'كل صف يمثل يومًا واحدًا ويعرض ما صرفه المستخدم الحالي وما صرفه الشريك المرتبط.';
      case ExpenseTableScope.olderThan24Hours:
        return groupsCount == 0
            ? 'لا توجد أيام سابقة تحتوي على مصروفات حتى الآن.'
            : 'راجع الأيام السابقة وافتح تفاصيل أي يوم لمعرفة كل حركة للطرفين.';
      case ExpenseTableScope.all:
        return groupsCount == 0
            ? 'لا توجد مصروفات مسجلة لهذا المشروع بعد.'
            : 'مقارنة يومية واضحة بين المستخدم الحالي والشريك المرتبط مع تفاصيل كاملة لكل يوم.';
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
        return 'بمجرد تسجيل أول مصروف بتاريخ اليوم سيظهر هنا تحت عمود المستخدم أو الشريك المرتبط.';
      case ExpenseTableScope.olderThan24Hours:
        return 'عند وجود مصروفات بتاريخ أقدم من اليوم ستظهر هنا تلقائيًا يومًا بيوم.';
      case ExpenseTableScope.all:
        return 'أضف أول مصروف ليبدأ سجل المقارنة بين المستخدم الحالي والشريك المرتبط.';
    }
  }
}

class _AddExpensePanel extends StatelessWidget {
  const _AddExpensePanel({
    required this.onOpenMaterials,
    required this.linkedPartnerName,
    required this.hasLinkedPartner,
    required this.currentTotal,
    required this.counterpartTotal,
    required this.overallTotal,
    required this.entriesCount,
  });

  final VoidCallback? onOpenMaterials;
  final String? linkedPartnerName;
  final bool hasLinkedPartner;
  final double currentTotal;
  final double counterpartTotal;
  final double overallTotal;
  final int entriesCount;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'ملخص المصروفات',
      subtitle:
          'يعرض مصروفات المستخدم الحالي والشريك المرتبط بشكل منفصل مع إجمالي واضح لكل طرف.',
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasLinkedPartner
                  ? const Color(0xFFEAF4EF)
                  : const Color(0xFFFFF3E8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              hasLinkedPartner
                  ? 'الحساب الحالي مرتبط بالشريك: ${linkedPartnerName ?? 'الشريك المرتبط'}'
                  : 'لا يوجد شريك مرتبط بهذا الحساب. سيتم عرض بيانات المستخدم الحالي فقط إلى أن يتم الربط.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF21463D),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ExpenseMetricPill(label: 'المستخدم', value: currentTotal.egp),
              _ExpenseMetricPill(
                label: 'الشريك المرتبط',
                value: counterpartTotal.egp,
              ),
              _ExpenseMetricPill(label: 'الإجمالي', value: overallTotal.egp),
              _ExpenseMetricPill(label: 'عدد الحركات', value: '$entriesCount'),
            ],
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
    required this.groups,
    required this.currentTotal,
    required this.counterpartTotal,
    required this.hasLinkedPartner,
    required this.onOpenDetailedExpenses,
    required this.showDetailedButton,
    required this.onAddExpense,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onOpenDayDetails,
  });

  final String title;
  final String subtitle;
  final String emptyTitle;
  final String emptyMessage;
  final String currentColumnLabel;
  final String counterpartColumnLabel;
  final List<_ExpenseDayGroup> groups;
  final double currentTotal;
  final double counterpartTotal;
  final bool hasLinkedPartner;
  final VoidCallback? onOpenDetailedExpenses;
  final bool showDetailedButton;
  final VoidCallback? onAddExpense;
  final ValueChanged<ExpenseRecord> onEditExpense;
  final ValueChanged<ExpenseRecord> onDeleteExpense;
  final void Function(_ExpenseDayGroup group, bool currentSide) onOpenDayDetails;

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
              child: const Text('عرض الأيام السابقة'),
            ),
          if (onAddExpense != null)
            FilledButton.icon(
              onPressed: onAddExpense,
              icon: const Icon(Icons.add),
              label: const Text('إضافة مصروف'),
            ),
        ],
      ),
      child: groups.isEmpty
          ? EmptyStateView(title: emptyTitle, message: emptyMessage)
          : LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth =
                    constraints.maxWidth < 600 ? 760.0 : constraints.maxWidth;
                final innerTableWidth = tableWidth - 2;
                final dateColumnWidth = 132.0;
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
                        for (final group in groups)
                          _ExpenseDayRow(
                            group: group,
                            dateColumnWidth: dateColumnWidth,
                            sideColumnWidth: sideColumnWidth,
                            hasLinkedPartner: hasLinkedPartner,
                            onOpenDayDetails: onOpenDayDetails,
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
          _HeaderCell(width: dateColumnWidth, label: 'اليوم'),
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

class _ExpenseDayRow extends StatelessWidget {
  const _ExpenseDayRow({
    required this.group,
    required this.dateColumnWidth,
    required this.sideColumnWidth,
    required this.hasLinkedPartner,
    required this.onOpenDayDetails,
  });

  final _ExpenseDayGroup group;
  final double dateColumnWidth;
  final double sideColumnWidth;
  final bool hasLinkedPartner;
  final void Function(_ExpenseDayGroup group, bool currentSide) onOpenDayDetails;

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
            _ExpenseDateCell(width: dateColumnWidth, day: group.day),
            _ExpenseDaySideCell(
              width: sideColumnWidth,
              entries: group.currentEntries,
              tint: const Color(0xFFEAF4EF),
              emptyLabel: 'لا توجد مصروفات للمستخدم في هذا اليوم',
              onOpenDetails: () => onOpenDayDetails(group, true),
            ),
            _ExpenseDaySideCell(
              width: sideColumnWidth,
              entries: group.counterpartEntries,
              tint: const Color(0xFFF6F4EF),
              emptyLabel: hasLinkedPartner
                  ? 'لا توجد مصروفات للشريك في هذا اليوم'
                  : 'لا يوجد شريك مرتبط بهذا الحساب',
              onOpenDetails: () => onOpenDayDetails(group, false),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseDateCell extends StatelessWidget {
  const _ExpenseDateCell({required this.width, required this.day});

  final double width;
  final DateTime day;

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
        day.formatShort(),
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
    required this.entries,
    required this.tint,
    required this.emptyLabel,
    required this.onOpenDetails,
  });

  final double width;
  final List<_ExpenseDisplayEntry> entries;
  final Color tint;
  final String emptyLabel;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.row.expense.amount,
    );

    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFD9DED6))),
      ),
      child: entries.isEmpty
          ? Center(
              child: Text(
                emptyLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD5DDD5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    total.egp,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF17352F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entries.length} حركة',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final entry in entries.take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ExpensePreviewLine(entry: entry),
                    ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: onOpenDetails,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('عرض التفصيل'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ExpensePreviewLine extends StatelessWidget {
  const _ExpensePreviewLine({required this.entry});

  final _ExpenseDisplayEntry entry;

  @override
  Widget build(BuildContext context) {
    final expense = entry.row.expense;
    final description = expense.description.trim().isEmpty
        ? expense.category.label
        : expense.description.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF40564F),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                expense.createdAt.formatWithTime(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          expense.amount.egp,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF17352F),
          ),
        ),
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
