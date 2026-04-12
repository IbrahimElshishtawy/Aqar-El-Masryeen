// ignore_for_file: dead_code, unused_element

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
import 'package:aqarelmasryeen/features/expenses/presentation/widgets/expense_split_ledger_table.dart';
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
part 'widgets/expenses_ledger_overview.dart';
part 'widgets/expenses_ledger_table.dart';
part 'widgets/expenses_ledger_selection_sheet.dart';

final allExpensesProvider = StreamProvider.autoDispose((ref) {
  return ref
      .watch(expenseRepositoryProvider)
      .watchAll(workspaceId: ref.watch(currentWorkspaceIdProvider));
});

final allPartnersProvider = StreamProvider.autoDispose((ref) {
  return ref
      .watch(partnerRepositoryProvider)
      .watchPartners(workspaceId: ref.watch(currentWorkspaceIdProvider));
});

final allPropertiesProvider = StreamProvider.autoDispose((ref) {
  return ref
      .watch(propertyRepositoryProvider)
      .watchProperties(workspaceId: ref.watch(currentWorkspaceIdProvider));
});

class ExpensesLedgerScreen extends ConsumerWidget {
  const ExpensesLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final workspaceId = ref.watch(currentWorkspaceIdProvider);
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
    final partners = workspaceId.isEmpty
        ? const <Partner>[]
        : partnersAsync.value!
              .where((partner) => partner.workspaceId.trim() == workspaceId)
              .toList(growable: false);
    final properties = workspaceId.isEmpty
        ? const <PropertyProject>[]
        : propertiesAsync.value!;
    final propertyIds = properties.map((property) => property.id).toSet();
    final scopedExpenses = workspaceId.isEmpty
        ? const <ExpenseRecord>[]
        : expenses
              .where((expense) => propertyIds.contains(expense.propertyId))
              .toList(growable: false);
    final showingHistory = _showingHistory(context);
    final today = DateTime.now();

    final currentUserId = session?.userId;
    final currentPartner = partners.firstWhereOrNull(
      (partner) => partner.userId == currentUserId,
    );
    final currentColumnLabel = resolveCurrentPartyLabel(currentPartner);
    final counterpartColumnLabel = resolveCounterpartPartyLabel(
      partners: partners,
      currentPartner: currentPartner,
      maxVisibleNames: 1,
    );
    final rows = _buildExpenseRows(
      expenses: scopedExpenses,
      currentUserId: currentUserId,
      currentPartnerId: currentPartner?.id,
      referenceDate: today,
      includeOlderDays: showingHistory,
    );
    final currentTotal = scopedExpenses
        .where(
          (expense) => _isCurrentUserExpense(
            expense,
            currentUserId: currentUserId,
            currentPartnerId: currentPartner?.id,
          ),
        )
        .fold<double>(0, (sum, expense) => sum + expense.amount);
    final counterpartTotal = scopedExpenses
        .where(
          (expense) => !_isCurrentUserExpense(
            expense,
            currentUserId: currentUserId,
            currentPartnerId: currentPartner?.id,
          ),
        )
        .fold<double>(0, (sum, expense) => sum + expense.amount);
    final hasOlderRows = scopedExpenses.any(
      (expense) => !_isSameCalendarDay(expense.date, today),
    );

    return AppShellScaffold(
      title: showingHistory ? 'سجل المصروفات' : 'مصاريف اليوم',
      subtitle: showingHistory
          ? 'عرض تواريخ بقية الأيام للمصروفات'
          : 'جدول يومي بسيط بين $currentColumnLabel و$counterpartColumnLabel',
      currentIndex: 1,
      automaticallyImplyLeading: false,
      titleActions: [_ExpensesTopBarActions(showingHistory: showingHistory)],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 24),
        children: [
          _ExpensesOverviewPanel(
            currentTotal: currentTotal,
            counterpartTotal: counterpartTotal,
            entriesCount: scopedExpenses.length,
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
          ExpenseSplitLedgerTable(
            rows: rows
                .map(
                  (row) => ExpenseSplitLedgerRow(
                    dateLabel: row.expense.date.formatShort(),
                    amountLabel: row.expense.amount.egp,
                    description: _expenseMeaning(row.expense),
                    isCurrentSide: row.isCurrentUser,
                    onEdit: () => _showExpenseSheet(
                      context,
                      properties: properties,
                      partners: partners,
                      expense: row.expense,
                    ),
                    onDelete: () => _deleteExpense(context, ref, row.expense),
                  ),
                )
                .toList(growable: false),
            currentColumnLabel: currentColumnLabel,
            counterpartColumnLabel: counterpartColumnLabel,
            emptyTitle: showingHistory
                ? workspaceId.isEmpty
                      ? 'الحساب غير مرتبط بمساحة عمل'
                      : 'لا توجد مصروفات في الأيام السابقة'
                : workspaceId.isEmpty
                ? 'الحساب غير مرتبط بمساحة عمل'
                : 'لا توجد مصروفات اليوم',
            emptyMessage: showingHistory
                ? workspaceId.isEmpty
                      ? 'لن تظهر أي بيانات مالية حتى يتم ربط الحساب بمساحة عمل وشريك.'
                      : 'عند وجود مصروفات بتاريخ أقدم من اليوم ستظهر هنا.'
                : workspaceId.isEmpty
                ? 'لن تظهر أي بيانات مالية حتى يتم ربط الحساب بمساحة عمل وشريك.'
                : 'بمجرد إضافة مصروف اليوم سيظهر هنا تحت $currentColumnLabel أو $counterpartColumnLabel.',
          ),
        ],
      ),
    );
  }
}

Future<void> _showExpenseSheet(
  BuildContext context, {
  required List<PropertyProject> properties,
  required List<Partner> partners,
  ExpenseRecord? expense,
}) async {
  var propertyId = expense?.propertyId ?? '';
  if (propertyId.isEmpty) {
    final property = await _pickProperty(context, properties);
    if (property == null || !context.mounted) {
      return;
    }
    propertyId = property.id;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ExpenseFormSheet(
      propertyId: propertyId,
      partners: partners,
      expense: expense,
    ),
  );
}

Future<void> _deleteExpense(
  BuildContext context,
  WidgetRef ref,
  ExpenseRecord expense,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(
        '\u062d\u0630\u0641 \u0627\u0644\u0645\u0635\u0631\u0648\u0641',
      ),
      content: const Text(
        '\u0633\u064a\u062a\u0645 \u062d\u0630\u0641 \u0647\u0630\u0627 \u0627\u0644\u0645\u0635\u0631\u0648\u0641 \u0645\u0646 \u062c\u062f\u0648\u0644 \u0627\u0644\u0645\u0635\u0627\u0631\u064a\u0641.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('\u0625\u0644\u063a\u0627\u0621'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('\u062d\u0630\u0641'),
        ),
      ],
    ),
  );
  if (confirmed != true) {
    return;
  }

  await ref.read(expenseRepositoryProvider).softDelete(expense.id);
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

String _expenseMeaning(ExpenseRecord expense) {
  final description = expense.description.trim();
  return description.isEmpty ? expense.category.label : description;
}

bool _isSameCalendarDay(DateTime first, DateTime second) {
  return DateUtils.isSameDay(first, second);
}

bool _isCurrentUserExpense(
  ExpenseRecord expense, {
  required String? currentUserId,
  required String? currentPartnerId,
}) {
  return (currentUserId != null && expense.createdBy == currentUserId) ||
      (currentPartnerId != null && expense.paidByPartnerId == currentPartnerId);
}

List<_ExpenseDisplayRow> _buildExpenseRows({
  required List<ExpenseRecord> expenses,
  required String? currentUserId,
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
          isCurrentUser: _isCurrentUserExpense(
            expense,
            currentUserId: currentUserId,
            currentPartnerId: currentPartnerId,
          ),
        ),
      )
      .toList(growable: false);
}
