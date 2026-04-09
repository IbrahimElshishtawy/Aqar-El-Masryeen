import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/expense_form_sheet.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/property_expenses_workspace.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PropertyExpensesDetailScreen extends ConsumerStatefulWidget {
  const PropertyExpensesDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyExpensesDetailScreen> createState() =>
      _PropertyExpensesDetailScreenState();
}

class _PropertyExpensesDetailScreenState
    extends ConsumerState<PropertyExpensesDetailScreen> {
  Future<void> _showExpenseSheet({
    ExpenseRecord? expense,
    required List<Partner> partners,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ExpenseFormSheet(
        propertyId: widget.propertyId,
        partners: partners,
        expense: expense,
      ),
    );
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('تأكيد'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteExpense(ExpenseRecord expense) async {
    final confirmed = await _confirm(
      'حذف المصروف',
      'سيتم حذف هذا المصروف من سجل العقار.',
    );
    if (!confirmed) {
      return;
    }
    await ref.read(expenseRepositoryProvider).softDelete(expense.id);
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(
      propertyProjectViewDataProvider(widget.propertyId),
    );

    return asyncData.when(
      loading: () => const AppShellScaffold(
        title: 'تفاصيل المصروفات',
        subtitle: 'تحميل بيانات العقار',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => AppShellScaffold(
        title: 'تفاصيل المصروفات',
        subtitle: 'تعذر تحميل البيانات',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'تعذر تحميل جدول المصروفات',
          message: mapException(error).message,
        ),
      ),
      data: (data) {
        if (data == null) {
          return const AppShellScaffold(
            title: 'تفاصيل المصروفات',
            subtitle: 'العقار غير موجود',
            currentIndex: 1,
            child: EmptyStateView(
              title: 'العقار غير موجود',
              message: 'لم نتمكن من العثور على هذا العقار.',
            ),
          );
        }

        return AppShellScaffold(
          title: 'تفاصيل المصروفات',
          subtitle: '${data.property.name} - الأيام السابقة',
          currentIndex: 1,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 24),
            children: [
              PropertyExpensesWorkspace(
                data: data,
                showSummaryPanel: false,
                showDetailedButton: false,
                scope: ExpenseTableScope.olderThan24Hours,
                onAddExpense: () => _showExpenseSheet(partners: data.partners),
                onEditExpense: (expense) => _showExpenseSheet(
                  expense: expense,
                  partners: data.partners,
                ),
                onDeleteExpense: _deleteExpense,
              ),
            ],
          ),
        );
      },
    );
  }
}
