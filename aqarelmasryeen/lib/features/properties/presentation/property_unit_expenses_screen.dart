import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/load_failure_view.dart';
import 'package:aqarelmasryeen/features/expenses/data/unit_expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/unit_expense_form_sheet.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/property_unit_expenses_section.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PropertyUnitExpensesScreen extends ConsumerStatefulWidget {
  const PropertyUnitExpensesScreen({
    super.key,
    required this.propertyId,
    required this.unitId,
  });

  final String propertyId;
  final String unitId;

  @override
  ConsumerState<PropertyUnitExpensesScreen> createState() =>
      _PropertyUnitExpensesScreenState();
}

class _PropertyUnitExpensesScreenState
    extends ConsumerState<PropertyUnitExpensesScreen> {
  Future<void> _showUnitExpenseSheet({
    required PropertyUnitViewData data,
    UnitExpenseRecord? expense,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => UnitExpenseFormSheet(
        propertyId: widget.propertyId,
        unitId: data.summary.unit.id,
        unitLabel: data.summary.unit.unitNumber,
        partners: data.partners,
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

  Future<void> _deleteUnitExpense(UnitExpenseRecord expense) async {
    final confirmed = await _confirm(
      'حذف المصروف',
      'سيتم حذف هذا المصروف من سجل الوحدة.',
    );
    if (!confirmed) {
      return;
    }

    await ref.read(unitExpenseRepositoryProvider).softDelete(expense.id);
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(
      propertyUnitViewDataProvider(
        PropertyUnitRequest(
          propertyId: widget.propertyId,
          unitId: widget.unitId,
        ),
      ),
    );

    return asyncData.when(
      loading: () => const AppShellScaffold(
        title: 'مصروفات الوحدة',
        subtitle: 'جاري تحميل البيانات',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => AppShellScaffold(
        title: 'مصروفات الوحدة',
        subtitle: 'تعذر تحميل البيانات',
        currentIndex: 1,
        child: LoadFailureView(
          title: 'تعذر تحميل سجل مصروفات الوحدة',
          error: error,
          onRetry: () => ref.invalidate(
            propertyUnitViewDataProvider(
              PropertyUnitRequest(
                propertyId: widget.propertyId,
                unitId: widget.unitId,
              ),
            ),
          ),
        ),
      ),
      data: (data) {
        if (data == null) {
          return const AppShellScaffold(
            title: 'مصروفات الوحدة',
            subtitle: 'الوحدة غير موجودة',
            currentIndex: 1,
            child: EmptyStateView(
              title: 'الوحدة غير موجودة',
              message: 'لم نتمكن من العثور على هذه الوحدة داخل العقار.',
            ),
          );
        }

        return AppShellScaffold(
          title: 'مصروفات الوحدة ${data.summary.unit.unitNumber}',
          subtitle: data.property.name,
          currentIndex: 1,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 24),
            children: [
              PropertyUnitExpensesSection(
                data: data,
                onAddExpense: () => _showUnitExpenseSheet(data: data),
                onEditExpense: (expense) =>
                    _showUnitExpenseSheet(data: data, expense: expense),
                onDeleteExpense: _deleteUnitExpense,
              ),
            ],
          ),
        );
      },
    );
  }
}
