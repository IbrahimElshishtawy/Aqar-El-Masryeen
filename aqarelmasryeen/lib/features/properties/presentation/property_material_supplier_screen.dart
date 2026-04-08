import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/material_expense_form_sheet.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/features/properties/presentation/property_detail_presenters.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/financial_ledger_table.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PropertyMaterialSupplierScreen extends ConsumerStatefulWidget {
  const PropertyMaterialSupplierScreen({
    super.key,
    required this.propertyId,
    required this.supplierName,
  });

  final String propertyId;
  final String supplierName;

  @override
  ConsumerState<PropertyMaterialSupplierScreen> createState() =>
      _PropertyMaterialSupplierScreenState();
}

class _PropertyMaterialSupplierScreenState
    extends ConsumerState<PropertyMaterialSupplierScreen> {
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
      'سيتم أرشفة هذه الفاتورة من كشف المورد.',
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
        title: 'كشف المورد',
        subtitle: 'تحميل بيانات المورد',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => AppShellScaffold(
        title: 'كشف المورد',
        subtitle: 'تعذر تحميل البيانات',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'تعذر تحميل كشف المورد',
          message: error.toString(),
        ),
      ),
      data: (data) {
        if (data == null) {
          return const AppShellScaffold(
            title: 'كشف المورد',
            subtitle: 'العقار غير موجود',
            currentIndex: 1,
            child: EmptyStateView(
              title: 'العقار غير موجود',
              message: 'لم نتمكن من العثور على هذا العقار.',
            ),
          );
        }

        final supplierName = _normalizeSupplierName(widget.supplierName);
        final rows =
            data.materials
                .where(
                  (entry) =>
                      _normalizeSupplierName(entry.supplierName) ==
                      supplierName,
                )
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
        final totalPurchased = rows.fold<double>(
          0,
          (sum, item) => sum + item.totalPrice,
        );
        final totalPaid = rows.fold<double>(
          0,
          (sum, item) => sum + item.amountPaid,
        );
        final totalRemaining = rows.fold<double>(
          0,
          (sum, item) => sum + item.amountRemaining,
        );
        final dueDates =
            rows
                .where(
                  (item) => item.dueDate != null && item.amountRemaining > 0,
                )
                .map((item) => item.dueDate!)
                .toList()
              ..sort();
        final nextDueDate = dueDates.isEmpty ? null : dueDates.first;

        return AppShellScaffold(
          title: supplierName,
          subtitle: data.property.name,
          currentIndex: 1,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 24),
            children: [
              _SupplierHeaderPanel(
                supplierName: supplierName,
                invoicesCount: rows.length,
                totalPurchased: totalPurchased,
                totalPaid: totalPaid,
                totalRemaining: totalRemaining,
                nextDueDate: nextDueDate,
              ),
              const SizedBox(height: 16),
              if (rows.isEmpty)
                const EmptyStateView(
                  title: 'لا توجد فواتير لهذا المورد',
                  message: 'بمجرد إضافة فاتورة بهذا الاسم ستظهر هنا.',
                )
              else
                FinancialLedgerTable<MaterialExpenseEntry>(
                  title: 'كشف حساب المورد',
                  subtitle:
                      'يعرض ما تم استلامه من المورد، والمدفوع، والمتبقي، وميعاد الدفع.',
                  rows: rows,
                  forceTableLayout: true,
                  onEdit: (entry) => _showMaterialSheet(entry: entry),
                  onDelete: _deleteMaterial,
                  sheetLabel: 'كشف $supplierName',
                  columns: [
                    LedgerColumn(
                      label: 'تاريخ الفاتورة',
                      valueBuilder: (row) => Text(row.date.formatShort()),
                      minWidth: 120,
                    ),
                    LedgerColumn(
                      label: 'المستلم',
                      valueBuilder: (row) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            row.itemName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            row.materialCategory.label,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      minWidth: 180,
                    ),
                    LedgerColumn(
                      label: 'الكمية',
                      valueBuilder: (row) =>
                          Text(row.quantity.toStringAsFixed(0)),
                      minWidth: 92,
                      numeric: true,
                    ),
                    LedgerColumn(
                      label: 'الإجمالي',
                      valueBuilder: (row) => Text(row.totalPrice.egp),
                      minWidth: 124,
                      numeric: true,
                    ),
                    LedgerColumn(
                      label: 'المدفوع',
                      valueBuilder: (row) => Text(row.amountPaid.egp),
                      minWidth: 116,
                      numeric: true,
                    ),
                    LedgerColumn(
                      label: 'المتبقي',
                      valueBuilder: (row) => Text(row.amountRemaining.egp),
                      minWidth: 116,
                      numeric: true,
                    ),
                    LedgerColumn(
                      label: 'ميعاد الدفع',
                      valueBuilder: (row) => Text(
                        row.dueDate == null
                            ? 'غير محدد'
                            : row.dueDate!.formatShort(),
                      ),
                      minWidth: 124,
                    ),
                    LedgerColumn(
                      label: 'الحالة',
                      valueBuilder: (row) => FinancialStatusChip(
                        label: row.status.label,
                        color: supplierInvoiceStatusColor(row.status),
                      ),
                      minWidth: 126,
                    ),
                    LedgerColumn(
                      label: 'ملاحظات',
                      valueBuilder: (row) => Text(
                        row.notes.trim().isEmpty ? 'لا يوجد' : row.notes.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      minWidth: 180,
                    ),
                  ],
                  totalsFooter: LedgerTotalsFooter(
                    children: [
                      LedgerFooterValue(
                        label: 'إجمالي المشتريات',
                        value: totalPurchased.egp,
                      ),
                      LedgerFooterValue(
                        label: 'إجمالي المدفوع',
                        value: totalPaid.egp,
                      ),
                      LedgerFooterValue(
                        label: 'إجمالي المتبقي',
                        value: totalRemaining.egp,
                      ),
                      LedgerFooterValue(
                        label: 'عدد الفواتير',
                        value: '${rows.length}',
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SupplierHeaderPanel extends StatelessWidget {
  const _SupplierHeaderPanel({
    required this.supplierName,
    required this.invoicesCount,
    required this.totalPurchased,
    required this.totalPaid,
    required this.totalRemaining,
    required this.nextDueDate,
  });

  final String supplierName;
  final int invoicesCount;
  final double totalPurchased;
  final double totalPaid;
  final double totalRemaining;
  final DateTime? nextDueDate;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: supplierName,
      subtitle: nextDueDate == null
          ? 'كل فواتير المورد المعروضة في كشف واحد.'
          : 'أقرب ميعاد دفع: ${nextDueDate!.formatShort()}',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _SupplierMetricCard(
            label: 'إجمالي المشتريات',
            value: totalPurchased.egp,
          ),
          _SupplierMetricCard(label: 'إجمالي المدفوع', value: totalPaid.egp),
          _SupplierMetricCard(
            label: 'إجمالي المتبقي',
            value: totalRemaining.egp,
          ),
          _SupplierMetricCard(label: 'عدد الفواتير', value: '$invoicesCount'),
        ],
      ),
    );
  }
}

class _SupplierMetricCard extends StatelessWidget {
  const _SupplierMetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
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

String _normalizeSupplierName(String supplierName) {
  final normalized = supplierName.trim();
  return normalized.isEmpty ? 'مورد غير محدد' : normalized;
}
