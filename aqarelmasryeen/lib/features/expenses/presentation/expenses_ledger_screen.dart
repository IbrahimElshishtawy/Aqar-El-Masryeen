// ignore_for_file: dead_code

import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/utils/partner_display_labels.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/expense_form_sheet.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final allExpensesProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(expenseRepositoryProvider).watchAll(),
);

final allPartnersProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(partnerRepositoryProvider).watchPartners(),
);

final allPropertiesProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(propertyRepositoryProvider).watchProperties(),
);

class ExpensesLedgerScreen extends ConsumerWidget {
  const ExpensesLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final expensesAsync = ref.watch(allExpensesProvider);
    final partnersAsync = ref.watch(allPartnersProvider);
    final propertiesAsync = ref.watch(allPropertiesProvider);

    if (expensesAsync.hasError ||
        partnersAsync.hasError ||
        propertiesAsync.hasError) {
      return AppShellScaffold(
        title: 'المصاريف',
        subtitle: 'تعذر تحميل بيانات المصروفات',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'تعذر تحميل شاشة المصروفات',
          message:
              expensesAsync.error?.toString() ??
              partnersAsync.error?.toString() ??
              propertiesAsync.error?.toString() ??
              'حدث خطأ غير متوقع',
        ),
      );
    }

    if (!expensesAsync.hasValue ||
        !partnersAsync.hasValue ||
        !propertiesAsync.hasValue) {
      return const AppShellScaffold(
        title: 'المصاريف',
        subtitle: 'جاري تحميل سجل المصروفات',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final expenses = expensesAsync.value!
        .where((expense) => !expense.archived)
        .toList(growable: false);
    final partners = partnersAsync.value!;
    final properties = propertiesAsync.value!;
    final showingHistory = _showingHistory(context);
    final today = DateTime.now();

    final currentPartner = partners.firstWhereOrNull(
      (partner) => partner.userId == session?.userId,
    );
    final currentColumnLabel = resolveCurrentPartyLabel(currentPartner);
    final counterpartColumnLabel = resolveCounterpartPartyLabel(
      partners: partners,
      currentPartner: currentPartner,
    );
    final rows = _buildExpenseRows(
      expenses: expenses,
      currentPartnerId: currentPartner?.id,
      referenceDate: today,
      includeOlderDays: showingHistory,
    );
    final totalAmount = rows.fold<double>(
      0,
      (sum, row) => sum + row.expense.amount,
    );
    final hasOlderRows = expenses.any(
      (expense) => !_isSameCalendarDay(expense.date, today),
    );

    return AppShellScaffold(
      title: showingHistory ? 'سجل المصروفات' : 'مصاريف اليوم',
      subtitle: showingHistory
          ? 'عرض تواريخ بقية الأيام للمصروفات'
          : 'جدول يومي بسيط بين $currentColumnLabel و$counterpartColumnLabel',
      currentIndex: 1,
      automaticallyImplyLeading: false,
      titleActions: [
        _ExpensesTopBarActions(
          properties: properties,
          partners: partners,
          showingHistory: showingHistory,
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 24),
        children: [
          _ExpensesOverviewPanel(
            totalAmount: totalAmount,
            entriesCount: rows.length,
            showingHistory: showingHistory,
            hasOlderRows: hasOlderRows,
            currentColumnLabel: currentColumnLabel,
            counterpartColumnLabel: counterpartColumnLabel,
            onAddExpense: () => _showExpenseSheet(
              context,
              properties: properties,
              partners: partners,
            ),
            onShowMore: hasOlderRows && !showingHistory
                ? () => context.push(AppRoutes.expensesHistory())
                : null,
            onShowToday: showingHistory
                ? () => context.go(AppRoutes.expenses)
                : null,
          ),
          const SizedBox(height: 16),
          _ExpensesDailyTable(
            rows: rows,
            currentColumnLabel: currentColumnLabel,
            counterpartColumnLabel: counterpartColumnLabel,
            emptyTitle: showingHistory
                ? 'لا توجد مصروفات في الأيام السابقة'
                : 'لا توجد مصروفات اليوم',
            emptyMessage: showingHistory
                ? 'عند وجود مصروفات بتاريخ أقدم من اليوم ستظهر هنا.'
                : 'بمجرد إضافة مصروف اليوم سيظهر هنا تحت $currentColumnLabel أو $counterpartColumnLabel.',
          ),
        ],
      ),
    );
  }
}

class _ExpensesTopBarActions extends StatelessWidget {
  const _ExpensesTopBarActions({
    required this.properties,
    required this.partners,
    required this.showingHistory,
  });

  final List<PropertyProject> properties;
  final List<Partner> partners;
  final bool showingHistory;

  @override
  Widget build(BuildContext context) {
    final canGoBack = showingHistory || context.canPop();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TopBarIconButton(
          icon: Icons.add_rounded,
          tooltip: 'إضافة مصروف',
          onPressed: () => _showExpenseSheet(
            context,
            properties: properties,
            partners: partners,
          ),
        ),
        if (canGoBack)
          _TopBarIconButton(
            icon: Icons.arrow_forward_rounded,
            tooltip: 'رجوع',
            onPressed: () {
              if (showingHistory) {
                context.go(AppRoutes.expenses);
                return;
              }
              if (context.canPop()) {
                context.pop();
              }
            },
          ),
      ],
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        side: const BorderSide(color: Color(0xFFD8D8D2)),
      ),
      icon: Icon(icon),
    );
  }
}

class _ExpensesOverviewPanel extends StatelessWidget {
  const _ExpensesOverviewPanel({
    required this.totalAmount,
    required this.entriesCount,
    required this.showingHistory,
    required this.hasOlderRows,
    required this.currentColumnLabel,
    required this.counterpartColumnLabel,
    required this.onAddExpense,
    this.onShowMore,
    this.onShowToday,
  });

  final double totalAmount;
  final int entriesCount;
  final bool showingHistory;
  final bool hasOlderRows;
  final String currentColumnLabel;
  final String counterpartColumnLabel;
  final VoidCallback onAddExpense;
  final VoidCallback? onShowMore;
  final VoidCallback? onShowToday;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: showingHistory ? 'باقي الأيام' : 'ملخص اليوم',
      subtitle: showingHistory
          ? 'هنا ستشوف تواريخ الأيام السابقة للمصاريف.'
          : 'القيمة والوصف يظهران داخل عمود $currentColumnLabel أو $counterpartColumnLabel فقط.',
      trailing: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (showingHistory && onShowToday != null)
            TextButton(onPressed: onShowToday, child: const Text('اليوم')),
          if (!showingHistory && hasOlderRows && onShowMore != null)
            TextButton(onPressed: onShowMore, child: const Text('عرض المزيد')),
          FilledButton.icon(
            onPressed: onAddExpense,
            icon: const Icon(Icons.add),
            label: const Text('إضافة مصروف'),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _MetricPill(
            label: showingHistory ? 'إجمالي المعروض' : 'إجمالي اليوم',
            value: totalAmount.egp,
          ),
          _MetricPill(label: 'عدد المصروفات', value: '$entriesCount'),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
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

class _ExpensesDailyTable extends StatelessWidget {
  const _ExpensesDailyTable({
    required this.rows,
    required this.currentColumnLabel,
    required this.counterpartColumnLabel,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final List<_ExpenseDisplayRow> rows;
  final String currentColumnLabel;
  final String counterpartColumnLabel;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'جدول المصروفات',
      subtitle:
          'ثلاثة أعمدة فقط: التاريخ، $currentColumnLabel، $counterpartColumnLabel.',
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
  });

  final _ExpenseDisplayRow row;
  final double dateColumnWidth;
  final double sideColumnWidth;

  @override
  Widget build(BuildContext context) {
    final userRow = row.isCurrentUser ? row : null;
    final partnerRow = row.isCurrentUser ? null : row;

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFD9DED6))),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ExpenseDateCell(width: dateColumnWidth, date: row.expense.date),
            _ExpenseSideCell(
              width: sideColumnWidth,
              entry: userRow,
              tint: const Color(0xFFEAF4EF),
            ),
            _ExpenseSideCell(
              width: sideColumnWidth,
              entry: partnerRow,
              tint: const Color(0xFFF6F4EF),
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
  });

  final double width;
  final _ExpenseDisplayRow? entry;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFD9DED6))),
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
          : _ExpenseEntryCard(entry: entry!, tint: tint),
    );
  }
}

class _ExpenseEntryCard extends StatelessWidget {
  const _ExpenseEntryCard({required this.entry, required this.tint});

  final _ExpenseDisplayRow entry;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final expense = entry.expense;
    final meaning = expense.description.trim().isEmpty
        ? expense.category.label
        : expense.description.trim();

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
            expense.amount.egp,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF17352F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meaning,
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

class _SelectionSheet<T> extends StatelessWidget {
  const _SelectionSheet({
    required this.title,
    required this.items,
    required this.labelBuilder,
    required this.onSelected,
  });

  final String title;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: Text(labelBuilder(item)),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () => onSelected(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showExpenseSheet(
  BuildContext context, {
  required List<PropertyProject> properties,
  required List<Partner> partners,
}) async {
  final property = await _pickProperty(context, properties);
  if (property == null || !context.mounted) {
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        ExpenseFormSheet(propertyId: property.id, partners: partners),
  );
}

Future<PropertyProject?> _pickProperty(
  BuildContext context,
  List<PropertyProject> properties,
) async {
  if (properties.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لا توجد عقارات متاحة لإضافة المصروف.')),
    );
    return null;
  }

  if (properties.length == 1) {
    return properties.first;
  }

  return showModalBottomSheet<PropertyProject>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) => _SelectionSheet<PropertyProject>(
      title: 'اختر العقار',
      items: properties,
      labelBuilder: (item) => item.name,
      onSelected: (item) => Navigator.of(sheetContext).pop(item),
    ),
  );
}

bool _showingHistory(BuildContext context) {
  return GoRouterState.of(context).uri.queryParameters['history'] == 'older';
}

bool _isSameCalendarDay(DateTime first, DateTime second) {
  return DateUtils.isSameDay(first, second);
}

List<_ExpenseDisplayRow> _buildExpenseRows({
  required List<ExpenseRecord> expenses,
  required String? currentPartnerId,
  required DateTime referenceDate,
  required bool includeOlderDays,
}) {
  final filtered = expenses.where((expense) {
    final sameDay = _isSameCalendarDay(expense.date, referenceDate);
    return includeOlderDays ? !sameDay : sameDay;
  }).toList()..sort((a, b) => b.date.compareTo(a.date));

  return filtered
      .map(
        (expense) => _ExpenseDisplayRow(
          expense: expense,
          isCurrentUser:
              currentPartnerId != null &&
              expense.paidByPartnerId == currentPartnerId,
        ),
      )
      .toList(growable: false);
}

class _ExpenseDisplayRow {
  const _ExpenseDisplayRow({
    required this.expense,
    required this.isCurrentUser,
  });

  final ExpenseRecord expense;
  final bool isCurrentUser;
}
