import 'dart:math' as math;

import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/material_expense_form_sheet.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/features/properties/presentation/property_detail_presenters.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/financial_ledger_table.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
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

  Future<void> _showSupplierPaymentSheet({
    required String supplierName,
    required List<MaterialExpenseEntry> rows,
    required double totalRemaining,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SupplierPaymentSheet(
        supplierName: supplierName,
        totalRemaining: totalRemaining,
        onSubmit: (amount, paidAt, notes) => _applySupplierPayment(
          supplierName: supplierName,
          rows: rows,
          amount: amount,
          paidAt: paidAt,
          notes: notes,
        ),
      ),
    );
  }

  Future<void> _applySupplierPayment({
    required String supplierName,
    required List<MaterialExpenseEntry> rows,
    required double amount,
    required DateTime paidAt,
    required String notes,
  }) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    final openRows =
        rows.where((entry) => entry.amountRemaining > 0).toList(growable: false)
          ..sort((a, b) {
            final dueCompare = (a.dueDate ?? a.date).compareTo(
              b.dueDate ?? b.date,
            );
            if (dueCompare != 0) {
              return dueCompare;
            }
            return a.date.compareTo(b.date);
          });

    var remainingPayment = amount;
    var touchedInvoices = 0;
    final now = DateTime.now();
    final repository = ref.read(materialExpenseRepositoryProvider);

    for (final entry in openRows) {
      if (remainingPayment <= 0) {
        break;
      }

      final appliedAmount = math.min(remainingPayment, entry.amountRemaining);
      if (appliedAmount <= 0) {
        continue;
      }

      await repository.save(
        entry.copyWith(
          amountPaid: entry.amountPaid + appliedAmount,
          amountRemaining: (entry.amountRemaining - appliedAmount)
              .clamp(0, entry.totalPrice)
              .toDouble(),
          updatedBy: session.userId,
          updatedAt: now,
          dueDate: entry.dueDate,
          notes: entry.notes,
        ),
      );
      remainingPayment -= appliedAmount;
      touchedInvoices += 1;
    }

    await ref
        .read(activityRepositoryProvider)
        .log(
          actorId: session.userId,
          actorName: session.profile?.name ?? 'شريك',
          action: 'supplier_payment_recorded',
          entityType: 'material_supplier',
          entityId: supplierName,
          metadata: {
            'propertyId': widget.propertyId,
            'supplierName': supplierName,
            'amount': amount,
            'paidAt': paidAt.toIso8601String(),
            'notes': notes,
            'affectedInvoices': touchedInvoices,
          },
        );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          touchedInvoices <= 0
              ? 'لا توجد فواتير مفتوحة لتسجيل دفعة عليها.'
              : 'تم تسجيل دفعة ${amount.egp} على $touchedInvoices فاتورة.',
        ),
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
          message: mapException(error).message,
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
        final canAddPayment = rows.isNotEmpty && totalRemaining > 0;

        return AppShellScaffold(
          title: supplierName,
          subtitle: data.property.name,
          currentIndex: 1,
          actions: [
            if (canAddPayment)
              _SupplierTopBarAction(
                label: 'إضافة دفعة',
                icon: Icons.add_card_rounded,
                onPressed: () => _showSupplierPaymentSheet(
                  supplierName: supplierName,
                  rows: rows,
                  totalRemaining: totalRemaining,
                ),
              ),
          ],
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
                onAddPayment: canAddPayment
                    ? () => _showSupplierPaymentSheet(
                        supplierName: supplierName,
                        rows: rows,
                        totalRemaining: totalRemaining,
                      )
                    : null,
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

class _SupplierTopBarAction extends StatelessWidget {
  const _SupplierTopBarAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: Center(
        child: FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
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
    this.onAddPayment,
  });

  final String supplierName;
  final int invoicesCount;
  final double totalPurchased;
  final double totalPaid;
  final double totalRemaining;
  final DateTime? nextDueDate;
  final VoidCallback? onAddPayment;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: supplierName,
      subtitle: nextDueDate == null
          ? 'كل فواتير المورد المعروضة في كشف واحد.'
          : 'أقرب ميعاد دفع: ${nextDueDate!.formatShort()}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SupplierMetricCard(
                label: 'إجمالي المشتريات',
                value: totalPurchased.egp,
              ),
              _SupplierMetricCard(
                label: 'إجمالي المدفوع',
                value: totalPaid.egp,
              ),
              _SupplierMetricCard(
                label: 'إجمالي المتبقي',
                value: totalRemaining.egp,
              ),
              _SupplierMetricCard(
                label: 'عدد الفواتير',
                value: '$invoicesCount',
              ),
            ],
          ),
          if (onAddPayment != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAddPayment,
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('إضافة دفعة حساب'),
              ),
            ),
          ],
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

class _SupplierPaymentSheet extends StatefulWidget {
  const _SupplierPaymentSheet({
    required this.supplierName,
    required this.totalRemaining,
    required this.onSubmit,
  });

  final String supplierName;
  final double totalRemaining;
  final Future<void> Function(double amount, DateTime paidAt, String notes)
  onSubmit;

  @override
  State<_SupplierPaymentSheet> createState() => _SupplierPaymentSheetState();
}

class _SupplierPaymentSheetState extends State<_SupplierPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late DateTime _paidAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
    _paidAt = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _paidAt = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    setState(() => _saving = true);
    try {
      await widget.onSubmit(amount, _paidAt, _notesController.text.trim());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: 'إضافة دفعة حساب',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.supplierName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'المتبقي الحالي ${widget.totalRemaining.egp}. سيتم توزيع الدفعة على الفواتير المفتوحة من الأقدم للأحدث.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'قيمة الدفعة',
                helperText: 'الحد الأقصى ${widget.totalRemaining.egp}',
              ),
              validator: (value) {
                final amount = double.tryParse((value ?? '').trim()) ?? 0;
                if (amount <= 0) {
                  return 'أدخل قيمة دفعة صحيحة.';
                }
                if (amount > widget.totalRemaining) {
                  return 'القيمة أكبر من المتبقي على المورد.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'تاريخ الدفعة'),
                child: Text(_paidAt.formatShort()),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                helperText: 'اختياري',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'جاري الحفظ...' : 'حفظ الدفعة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _normalizeSupplierName(String supplierName) {
  final normalized = supplierName.trim();
  return normalized.isEmpty ? 'مورد غير محدد' : normalized;
}
