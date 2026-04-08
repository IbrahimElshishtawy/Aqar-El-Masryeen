import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/domain/materials_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/material_expense_form_sheet.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/property_material_entries_table.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
              _SupplierOverviewPanel(
                summaries: data.materialsSnapshot.supplierSummaries,
                onOpenSupplier: (supplierName) => context.push(
                  AppRoutes.propertyMaterialSupplier(
                    widget.propertyId,
                    supplierName,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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

class _SupplierOverviewPanel extends StatelessWidget {
  const _SupplierOverviewPanel({
    required this.summaries,
    required this.onOpenSupplier,
  });

  final List<SupplierLedgerSummary> summaries;
  final ValueChanged<String> onOpenSupplier;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'الموردون',
      subtitle: summaries.isEmpty
          ? 'أضف أول فاتورة مواد بناء لعرض الموردين هنا.'
          : 'اضغط على اسم المورد لفتح كشف الحساب والمدفوعات الخاصة به.',
      child: summaries.isEmpty
          ? const EmptyStateView(
              title: 'لا يوجد موردون بعد',
              message: 'بمجرد إضافة فاتورة مواد البناء سيظهر اسم المورد هنا.',
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1100
                    ? 3
                    : constraints.maxWidth >= 720
                    ? 2
                    : 1;
                return GridView.builder(
                  itemCount: summaries.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: columns == 1 ? 1.65 : 1.28,
                  ),
                  itemBuilder: (context, index) {
                    final supplier = summaries[index];
                    return _SupplierSummaryCard(
                      summary: supplier,
                      onTap: () => onOpenSupplier(supplier.supplierName),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _SupplierSummaryCard extends StatelessWidget {
  const _SupplierSummaryCard({required this.summary, required this.onTap});

  final SupplierLedgerSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEFB),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD8D8D2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.supplierName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${summary.invoiceCount} فاتورة',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SupplierMetricPill(
                  label: 'المدفوع',
                  value: summary.totalPaid.egp,
                ),
                _SupplierMetricPill(
                  label: 'المتبقي',
                  value: summary.totalRemaining.egp,
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onTap,
                child: const Text('فتح كشف المورد'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierMetricPill extends StatelessWidget {
  const _SupplierMetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
