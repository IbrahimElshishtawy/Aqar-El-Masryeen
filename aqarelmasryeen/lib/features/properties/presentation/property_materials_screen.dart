import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/material_expense_form_sheet.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/property_material_entries_table.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PropertyMaterialsScreen extends ConsumerStatefulWidget {
  const PropertyMaterialsScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyMaterialsScreen> createState() =>
      _PropertyMaterialsScreenState();
}

class _PropertyMaterialsScreenState
    extends ConsumerState<PropertyMaterialsScreen> {
  Future<void> _showMaterialSheet({MaterialExpenseEntry? entry}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          MaterialExpenseFormSheet(propertyId: widget.propertyId, entry: entry),
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

  Future<void> _deleteMaterial(MaterialExpenseEntry entry) async {
    final confirmed = await _confirm(
      'حذف فاتورة مواد',
      'سيتم أرشفة فاتورة المواد من الجداول النشطة.',
    );
    if (!confirmed) {
      return;
    }
    await ref.read(materialExpenseRepositoryProvider).softDelete(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(
      propertyProjectViewDataProvider(widget.propertyId),
    );

    return asyncData.when(
      loading: () => const AppShellScaffold(
        title: 'مواد البناء',
        subtitle: 'تحميل بيانات العقار',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => AppShellScaffold(
        title: 'مواد البناء',
        subtitle: 'تعذر تحميل البيانات',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'تعذر تحميل مواد البناء',
          message: error.toString(),
        ),
      ),
      data: (data) {
        if (data == null) {
          return const AppShellScaffold(
            title: 'مواد البناء',
            subtitle: 'العقار غير موجود',
            currentIndex: 1,
            child: EmptyStateView(
              title: 'العقار غير موجود',
              message: 'لم نتمكن من العثور على هذا العقار.',
            ),
          );
        }

        return AppShellScaffold(
          title: 'مواد البناء',
          subtitle: data.property.name,
          currentIndex: 1,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 24),
            children: [
              PropertyMaterialEntriesTable(
                title: 'جدول مواد البناء',
                rows: data.materials,
                onAdd: () => _showMaterialSheet(),
                addLabel: 'إضافة فاتورة',
                onEdit: (entry) => _showMaterialSheet(entry: entry),
                onDelete: _deleteMaterial,
              ),
            ],
          ),
        );
      },
    );
  }
}
