// ignore_for_file: unused_element

import 'dart:math' as math;

import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/load_failure_view.dart';
import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/data/supplier_payment_repository.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/material_expense_form_sheet.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/financial_ledger_table.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
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
  Future<void> _showMaterialSheet({
    required List<Partner> partners,
    MaterialExpenseEntry? entry,
    String? initialSupplierName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MaterialExpenseFormSheet(
        propertyId: widget.propertyId,
        partners: partners,
        entry: entry,
        initialSupplierName: initialSupplierName,
      ),
    );
  }

  Future<void> _showSupplierPaymentSheet({
    required String supplierName,
    required List<MaterialExpenseEntry> invoiceRows,
    required List<Partner> partners,
    required double totalRemaining,
    required String? currentPartnerId,
    required String currentUserLabel,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SupplierPaymentSheet(
        supplierName: supplierName,
        partners: partners,
        currentPartnerId: currentPartnerId,
        currentUserLabel: currentUserLabel,
        totalRemaining: totalRemaining,
        onSubmit: (amount, paidAt, notes, paidByPartnerId) =>
            _applySupplierPayment(
              supplierName: supplierName,
              rows: invoiceRows,
              partners: partners,
              amount: amount,
              paidAt: paidAt,
              notes: notes,
              paidByPartnerId: paidByPartnerId,
            ),
      ),
    );
  }

  String _currentUserLabel() {
    final session = ref.read(authSessionProvider).valueOrNull;
    return _resolveUserDisplayName(session);
  }

  Future<void> _applySupplierPayment({
    required String supplierName,
    required List<MaterialExpenseEntry> rows,
    required List<Partner> partners,
    required double amount,
    required DateTime paidAt,
    required String notes,
    required String paidByPartnerId,
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
    final materialsRepository = ref.read(materialExpenseRepositoryProvider);

    for (final entry in openRows) {
      if (remainingPayment <= 0) {
        break;
      }

      final appliedAmount = math.min(remainingPayment, entry.amountRemaining);
      if (appliedAmount <= 0) {
        continue;
      }

      await materialsRepository.save(
        entry.copyWith(
          amountPaid: entry.amountPaid + appliedAmount,
          amountRemaining: (entry.amountRemaining - appliedAmount)
              .clamp(0, entry.totalPrice)
              .toDouble(),
          updatedBy: session.userId,
          updatedAt: now,
        ),
      );
      remainingPayment -= appliedAmount;
      touchedInvoices += 1;
    }

    if (touchedInvoices <= 0) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد فواتير مفتوحة لتسجيل دفعة عليها.'),
        ),
      );
      return;
    }

    final paidByLabel = _partnerLabel(
      partners,
      paidByPartnerId,
      currentUserId: session.userId,
      currentUserLabel: _currentUserLabel(),
    );
    await ref
        .read(supplierPaymentRepositoryProvider)
        .save(
          SupplierPaymentRecord(
            id: '',
            propertyId: widget.propertyId,
            supplierName: supplierName,
            amount: amount - remainingPayment,
            paidAt: paidAt,
            paidByPartnerId: paidByPartnerId,
            paidByLabel: paidByLabel,
            notes: notes,
            createdBy: session.userId,
            updatedBy: session.userId,
            createdAt: now,
            updatedAt: now,
            archived: false,
          ),
        );

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
            'amount': amount - remainingPayment,
            'paidAt': paidAt.toIso8601String(),
            'paidByPartnerId': paidByPartnerId,
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
          'تم تسجيل دفعة ${(amount - remainingPayment).egp} على $touchedInvoices فاتورة.',
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
        child: LoadFailureView(
          title: 'تعذر تحميل كشف المورد',
          error: error,
          onRetry: () => ref.invalidate(
            propertyProjectViewDataProvider(widget.propertyId),
          ),
        ),
      ),
      data: (data) {
        final session = ref.watch(authSessionProvider).valueOrNull;
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
        final currentUserId = session?.userId;
        final currentUserLabel = _resolveUserDisplayName(session);
        final invoiceRows =
            data.materials
                .where(
                  (entry) =>
                      _normalizeSupplierName(entry.supplierName) ==
                      supplierName,
                )
                .toList()
              ..sort((a, b) {
                final dateCompare = a.date.compareTo(b.date);
                if (dateCompare != 0) {
                  return dateCompare;
                }
                return a.createdAt.compareTo(b.createdAt);
              });
        final paymentRows =
            data.supplierPayments
                .where(
                  (payment) =>
                      _normalizeSupplierName(payment.supplierName) ==
                      supplierName,
                )
                .toList()
              ..sort((a, b) {
                final dateCompare = a.paidAt.compareTo(b.paidAt);
                if (dateCompare != 0) {
                  return dateCompare;
                }
                return a.createdAt.compareTo(b.createdAt);
              });

        final accountSummary = _buildSupplierAccountSummary(
          invoiceRows: invoiceRows,
          paymentRows: paymentRows,
        );
        final nextDueDate = accountSummary.totalRemaining <= 0
            ? null
            : invoiceRows
                  .where(
                    (item) =>
                        item.dueDate != null &&
                        (item.amountRemaining > 0 ||
                            item.totalPrice > item.amountPaid),
                  )
                  .map((item) => item.dueDate!)
                  .fold<DateTime?>(null, (current, date) {
                    if (current == null || date.isBefore(current)) {
                      return date;
                    }
                    return current;
                  });
        final ledgerRows = _buildLedgerRows(
          invoiceRows: invoiceRows,
          paymentRows: paymentRows,
          partners: data.partners,
          currentUserId: currentUserId,
          currentUserLabel: currentUserLabel,
        );
        final currentPartnerId = data.currentPartner?.id;
        final canAddPayment =
            accountSummary.totalRemaining > 0 && invoiceRows.isNotEmpty;

        return AppShellScaffold(
          title: supplierName,
          subtitle: data.property.name,
          currentIndex: 1,

          child: ListView(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 24),
            children: [
              _SupplierHeaderPanel(
                supplierName: supplierName,
                totalQuantity: accountSummary.totalQuantity,
                invoiceCount: invoiceRows.length,
                paymentCount: paymentRows.length,
                totalRequired: accountSummary.totalRequired,
                totalPaid: accountSummary.totalPaid,
                totalRemaining: accountSummary.totalRemaining,
                nextDueDate: nextDueDate,
                onAddQuantity: () => _showMaterialSheet(
                  partners: data.partners,
                  initialSupplierName: supplierName,
                ),
                onAddPayment: canAddPayment
                    ? () => _showSupplierPaymentSheet(
                        supplierName: supplierName,
                        invoiceRows: invoiceRows,
                        partners: data.partners,
                        totalRemaining: accountSummary.totalRemaining,
                        currentPartnerId: currentPartnerId,
                        currentUserLabel: currentUserLabel,
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              if (ledgerRows.isEmpty)
                const EmptyStateView(
                  title: 'لا توجد حركات لهذا المورد',
                  message:
                      'بمجرد إضافة كمية جديدة أو دفعة سيظهر كشف المورد هنا.',
                )
              else
                FinancialLedgerTable<_SupplierLedgerRow>(
                  title: 'كشف حساب المورد',
                  subtitle:
                      'يعرض كل عمليات إضافة الكميات والدفعات للمورد نفسه في جدول واحد واضح.',
                  rows: ledgerRows,
                  forceTableLayout: true,
                  showRowNumbers: false,
                  sheetLabel: 'كشف $supplierName',
                  compactCardBuilder: (context, row, rowNumber, _) {
                    return _SupplierLedgerCompactCard(
                      row: row,
                      rowNumber: rowNumber,
                      onEditMaterial: row.materialEntry == null
                          ? null
                          : () => _showMaterialSheet(
                              partners: data.partners,
                              entry: row.materialEntry,
                            ),
                      onDeleteMaterial: row.materialEntry == null
                          ? null
                          : () => _deleteMaterial(row.materialEntry!),
                    );
                  },
                  columns: [
                    LedgerColumn(
                      label: 'تاريخ الحركة',
                      valueBuilder: (row) =>
                          Text(row.displayDate.formatShort()),
                      minWidth: 118,
                    ),
                    LedgerColumn(
                      label: 'النوع',
                      valueBuilder: (row) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              row.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      minWidth: 170,
                    ),
                    LedgerColumn(
                      label: 'الكمية',
                      valueBuilder: (row) => Text(row.quantityLabel),
                      minWidth: 92,
                      numeric: true,
                    ),
                    LedgerColumn(
                      label: 'السعر',
                      valueBuilder: (row) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(row.priceLabel),
                          if (row.unitPrice > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'الوحدة ${row.unitPrice.egp}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFF5F655B)),
                            ),
                          ],
                        ],
                      ),
                      minWidth: 132,
                      numeric: true,
                    ),
                    LedgerColumn(
                      label: 'المدفوع',
                      valueBuilder: (row) => Text(row.paidValue.egp),
                      minWidth: 118,
                      numeric: true,
                    ),
                    LedgerColumn(
                      label: 'المتبقي',
                      valueBuilder: (row) => Text(row.remainingAfter.egp),
                      minWidth: 118,
                      numeric: true,
                    ),
                    LedgerColumn(
                      label: 'من الذي دفع',
                      valueBuilder: (row) => Text(row.paidByLabel),
                      minWidth: 140,
                    ),
                    LedgerColumn(
                      label: 'الإجراء',
                      valueBuilder: (row) => row.materialEntry == null
                          ? const Text('-')
                          : Wrap(
                              spacing: 2,
                              children: [
                                IconButton(
                                  onPressed: () => _showMaterialSheet(
                                    partners: data.partners,
                                    entry: row.materialEntry,
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'تعديل',
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _deleteMaterial(row.materialEntry!),
                                  icon: const Icon(Icons.delete_outline),
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'حذف',
                                ),
                              ],
                            ),
                      minWidth: 120,
                    ),
                  ],
                  totalsFooter: LedgerTotalsFooter(
                    children: [
                      LedgerFooterValue(
                        label: 'إجمالي الكمية',
                        value: _formatQuantity(accountSummary.totalQuantity),
                      ),
                      LedgerFooterValue(
                        label: 'إجمالي السعر',
                        value: accountSummary.totalRequired.egp,
                      ),
                      LedgerFooterValue(
                        label: 'إجمالي المدفوع',
                        value: accountSummary.totalPaid.egp,
                      ),
                      LedgerFooterValue(
                        label: 'إجمالي المتبقي',
                        value: accountSummary.totalRemaining.egp,
                      ),
                      LedgerFooterValue(
                        label: 'عدد الحركات',
                        value: '${ledgerRows.length}',
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
    required this.totalQuantity,
    required this.invoiceCount,
    required this.paymentCount,
    required this.totalRequired,
    required this.totalPaid,
    required this.totalRemaining,
    required this.nextDueDate,
    required this.onAddQuantity,
    this.onAddPayment,
  });

  final String supplierName;
  final double totalQuantity;
  final int invoiceCount;
  final int paymentCount;
  final double totalRequired;
  final double totalPaid;
  final double totalRemaining;
  final DateTime? nextDueDate;
  final VoidCallback onAddQuantity;
  final VoidCallback? onAddPayment;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: supplierName,
      subtitle: nextDueDate == null
          ? 'كشف موحد يوضح الإضافات والدفعات وحالة المتبقي على المورد.'
          : 'أقرب تاريخ استحقاق مفتوح: ${nextDueDate!.formatShort()}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SupplierMetricCard(
                label: 'إجمالي الكمية',
                value: _formatQuantity(totalQuantity),
              ),
              _SupplierMetricCard(
                label: 'إجمالي السعر',
                value: totalRequired.egp,
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
                label: 'عدد الإضافات',
                value: '$invoiceCount',
              ),
              _SupplierMetricCard(label: 'عدد الدفعات', value: '$paymentCount'),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: onAddQuantity,
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('إضافة كمية'),
              ),
              FilledButton.icon(
                onPressed: onAddPayment,
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('إضافة دفعة'),
              ),
            ],
          ),
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

class _SupplierLedgerCompactCard extends StatelessWidget {
  const _SupplierLedgerCompactCard({
    required this.row,
    required this.rowNumber,
    this.onEditMaterial,
    this.onDeleteMaterial,
  });

  final _SupplierLedgerRow row;
  final int? rowNumber;
  final VoidCallback? onEditMaterial;
  final VoidCallback? onDeleteMaterial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rowNumber == null
                          ? row.typeLabel
                          : '${row.typeLabel} #$rowNumber',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: row.isPayment
                            ? const Color(0xFF9A4F42)
                            : const Color(0xFF2E6B3F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row.description,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF17352F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                row.remainingAfter.egp,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF17352F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LedgerChip(label: row.displayDate.formatShort()),
              _LedgerChip(label: 'النوع: ${row.typeLabel}'),
              _LedgerChip(label: 'الكمية: ${row.quantityLabel}'),
              _LedgerChip(label: 'من دفع: ${row.paidByLabel}'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _LedgerValue(label: 'السعر', value: row.priceLabel),
              _LedgerValue(label: 'المدفوع', value: row.paidValue.egp),
              _LedgerValue(label: 'المتبقي', value: row.remainingAfter.egp),
            ],
          ),
          if (row.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              row.notes.trim(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF40564F)),
            ),
          ],
          if (onEditMaterial != null || onDeleteMaterial != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                if (onEditMaterial != null)
                  OutlinedButton.icon(
                    onPressed: onEditMaterial,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('تعديل'),
                  ),
                if (onDeleteMaterial != null)
                  OutlinedButton.icon(
                    onPressed: onDeleteMaterial,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('حذف'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LedgerChip extends StatelessWidget {
  const _LedgerChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF465145),
        ),
      ),
    );
  }
}

class _LedgerValue extends StatelessWidget {
  const _LedgerValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
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

class _SupplierPaymentSheet extends StatefulWidget {
  const _SupplierPaymentSheet({
    required this.supplierName,
    required this.partners,
    required this.currentPartnerId,
    required this.currentUserLabel,
    required this.totalRemaining,
    required this.onSubmit,
  });

  final String supplierName;
  final List<Partner> partners;
  final String? currentPartnerId;
  final String currentUserLabel;
  final double totalRemaining;
  final Future<void> Function(
    double amount,
    DateTime paidAt,
    String notes,
    String paidByPartnerId,
  )
  onSubmit;

  @override
  State<_SupplierPaymentSheet> createState() => _SupplierPaymentSheetState();
}

class _SupplierPaymentSheetState extends State<_SupplierPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late DateTime _paidAt;
  late String _paidByPartnerId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
    _paidAt = DateTime.now();
    _paidByPartnerId =
        widget.currentPartnerId ??
        (widget.partners.isEmpty ? '' : widget.partners.first.id);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _partnerOptionLabel(Partner partner) {
    final name = partner.name.trim();
    if (name.isNotEmpty) {
      return name;
    }

    if (partner.id == widget.currentPartnerId &&
        widget.currentUserLabel.trim().isNotEmpty) {
      return widget.currentUserLabel;
    }

    final linkedEmail = partner.linkedEmail.trim();
    if (linkedEmail.isNotEmpty) {
      return linkedEmail;
    }

    return 'شريك';
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

    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        double.parse(_amountController.text.trim()),
        _paidAt,
        _notesController.text.trim(),
        _paidByPartnerId,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedPayer = widget.partners.any(
      (partner) => partner.id == _paidByPartnerId,
    );

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
              'المتبقي الحالي ${widget.totalRemaining.egp}. سيتم توزيع الدفعة على الفواتير المفتوحة من الأقدم إلى الأحدث.',
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
            if (widget.partners.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: hasSelectedPayer ? _paidByPartnerId : null,
                items: [
                  for (final partner in widget.partners)
                    DropdownMenuItem(
                      value: partner.id,
                      child: Text(_partnerOptionLabel(partner)),
                    ),
                ],
                onChanged: (value) {
                  setState(() => _paidByPartnerId = value ?? _paidByPartnerId);
                },
                decoration: const InputDecoration(labelText: 'من الذي دفع'),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'اختر من الذي دفع هذه الدفعة.'
                    : null,
              ),
            ],
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

List<_SupplierLedgerRow> _buildLedgerRows({
  required List<MaterialExpenseEntry> invoiceRows,
  required List<SupplierPaymentRecord> paymentRows,
  required List<Partner> partners,
  required String? currentUserId,
  required String currentUserLabel,
}) {
  final events =
      <_SupplierLedgerEvent>[
        for (final row in invoiceRows) _SupplierLedgerEvent.invoice(row),
        for (final row in paymentRows) _SupplierLedgerEvent.payment(row),
      ]..sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) {
          return dateCompare;
        }
        final createdCompare = a.createdAt.compareTo(b.createdAt);
        if (createdCompare != 0) {
          return createdCompare;
        }
        if (a.type == b.type) {
          return 0;
        }
        return a.type == _SupplierLedgerEventType.invoice ? -1 : 1;
      });

  var remaining = 0.0;
  final rows = <_SupplierLedgerRow>[];

  for (final event in events) {
    if (event.type == _SupplierLedgerEventType.invoice) {
      final invoice = event.material!;
      remaining += invoice.totalPrice;
      remaining = (remaining - invoice.initialPaidAmount).clamp(
        0,
        double.infinity,
      );
      rows.add(
        _SupplierLedgerRow(
          sequence: rows.length + 1,
          displayDate: invoice.date,
          isPayment: false,
          description: invoice.itemName.trim().isEmpty
              ? 'صنف غير محدد'
              : invoice.itemName.trim(),
          quantity: invoice.quantity,
          unitPrice: invoice.unitPrice,
          addedValue: invoice.totalPrice,
          paidValue: invoice.initialPaidAmount,
          remainingAfter: remaining,
          paidByLabel: invoice.initialPaidAmount > 0
              ? _resolveStoredPayerLabel(
                  storedLabel: invoice.initialPaidByLabel,
                  partnerId: invoice.initialPaidByPartnerId,
                  partners: partners,
                  currentUserId: currentUserId,
                  currentUserLabel: currentUserLabel,
                  createdBy: invoice.createdBy,
                )
              : '-',
          notes: invoice.notes,
          materialEntry: invoice,
          paymentEntry: null,
        ),
      );
      continue;
    }

    final payment = event.payment!;
    remaining = (remaining - payment.amount).clamp(0, double.infinity);
    rows.add(
      _SupplierLedgerRow(
        sequence: rows.length + 1,
        displayDate: payment.paidAt,
        isPayment: true,
        description: 'دفعة على المورد',
        quantity: null,
        unitPrice: 0,
        addedValue: 0,
        paidValue: payment.amount,
        remainingAfter: remaining,
        paidByLabel: _resolveStoredPayerLabel(
          storedLabel: payment.paidByLabel,
          partnerId: payment.paidByPartnerId,
          partners: partners,
          currentUserId: currentUserId,
          currentUserLabel: currentUserLabel,
          createdBy: payment.createdBy,
        ),
        notes: payment.notes,
        materialEntry: null,
        paymentEntry: payment,
      ),
    );
  }

  return rows.reversed.toList(growable: false);
}

_SupplierAccountSummary _buildSupplierAccountSummary({
  required List<MaterialExpenseEntry> invoiceRows,
  required List<SupplierPaymentRecord> paymentRows,
}) {
  final totalQuantity = invoiceRows.fold<double>(
    0,
    (sum, item) => sum + item.quantity,
  );
  final totalRequired = invoiceRows.fold<double>(
    0,
    (sum, item) => sum + item.totalPrice,
  );
  final recordedPaidOnInvoices = invoiceRows.fold<double>(
    0,
    (sum, item) => sum + item.amountPaid,
  );
  final initialPaid = invoiceRows.fold<double>(
    0,
    (sum, item) => sum + item.initialPaidAmount,
  );
  final supplierPaymentsTotal = paymentRows.fold<double>(
    0,
    (sum, item) => sum + item.amount,
  );
  final totalPaid = math.max(
    recordedPaidOnInvoices,
    initialPaid + supplierPaymentsTotal,
  );
  final totalRemaining = totalRequired <= 0
      ? 0.0
      : (totalRequired - totalPaid).clamp(0, totalRequired).toDouble();

  return _SupplierAccountSummary(
    totalQuantity: totalQuantity,
    totalRequired: totalRequired,
    totalPaid: totalPaid,
    totalRemaining: totalRemaining,
  );
}

String _formatQuantity(double value) {
  return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
}

String _resolveUserDisplayName(AppSession? session) {
  final profileName = session?.profile?.fullName.trim() ?? '';
  if (profileName.isNotEmpty) {
    return profileName;
  }

  final displayName = session?.displayName?.trim() ?? '';
  if (displayName.isNotEmpty) {
    return displayName;
  }

  return 'شريك';
}

String _partnerLabel(
  List<Partner> partners,
  String partnerId, {
  String? currentUserId,
  String currentUserLabel = 'شريك',
}) {
  for (final partner in partners) {
    if (partner.id == partnerId) {
      final label = _partnerDisplayName(
        partner,
        currentUserId: currentUserId,
        currentUserLabel: currentUserLabel,
      );
      return label.isEmpty ? currentUserLabel : label;
    }
  }
  return currentUserLabel;
}

String _partnerDisplayName(
  Partner partner, {
  String? currentUserId,
  String currentUserLabel = 'شريك',
}) {
  final name = partner.name.trim();
  if (name.isNotEmpty) {
    return name;
  }

  if (currentUserId != null &&
      partner.userId == currentUserId &&
      currentUserLabel.trim().isNotEmpty) {
    return currentUserLabel;
  }

  final linkedEmail = partner.linkedEmail.trim();
  if (linkedEmail.isNotEmpty) {
    return linkedEmail;
  }

  return '';
}

String _resolveStoredPayerLabel({
  required String storedLabel,
  required String partnerId,
  required List<Partner> partners,
  required String? currentUserId,
  required String currentUserLabel,
  String? createdBy,
}) {
  if (partnerId.trim().isNotEmpty) {
    final partnerLabel = _partnerLabel(
      partners,
      partnerId,
      currentUserId: currentUserId,
      currentUserLabel: currentUserLabel,
    ).trim();
    if (partnerLabel.isNotEmpty && partnerLabel != 'شريك') {
      return partnerLabel;
    }
  }

  final cleanedStoredLabel = storedLabel.trim();
  if (cleanedStoredLabel.isNotEmpty &&
      cleanedStoredLabel != 'شريك' &&
      cleanedStoredLabel != 'غير محدد') {
    return cleanedStoredLabel;
  }

  if (cleanedStoredLabel == 'شريك' &&
      createdBy != null &&
      createdBy == currentUserId &&
      currentUserLabel.trim().isNotEmpty) {
    return currentUserLabel;
  }

  if (cleanedStoredLabel == 'غير محدد') {
    return cleanedStoredLabel;
  }

  return cleanedStoredLabel.isEmpty ? 'غير محدد' : currentUserLabel;
}

String _normalizeSupplierName(String supplierName) {
  final normalized = supplierName.trim();
  return normalized.isEmpty ? 'مورد غير محدد' : normalized;
}

class _SupplierAccountSummary {
  const _SupplierAccountSummary({
    required this.totalQuantity,
    required this.totalRequired,
    required this.totalPaid,
    required this.totalRemaining,
  });

  final double totalQuantity;
  final double totalRequired;
  final double totalPaid;
  final double totalRemaining;
}

class _SupplierLedgerRow {
  const _SupplierLedgerRow({
    required this.sequence,
    required this.displayDate,
    required this.isPayment,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.addedValue,
    required this.paidValue,
    required this.remainingAfter,
    required this.paidByLabel,
    required this.notes,
    required this.materialEntry,
    required this.paymentEntry,
  });

  final int sequence;
  final DateTime displayDate;
  final bool isPayment;
  final String description;
  final double? quantity;
  final double unitPrice;
  final double addedValue;
  final double paidValue;
  final double remainingAfter;
  final String paidByLabel;
  final String notes;
  final MaterialExpenseEntry? materialEntry;
  final SupplierPaymentRecord? paymentEntry;

  String get typeLabel => isPayment ? 'دفعة' : '';

  String get quantityLabel {
    if (quantity == null || quantity == 0) {
      return '-';
    }
    return _formatQuantity(quantity!);
  }

  String get priceLabel {
    if (isPayment || addedValue <= 0) {
      return '-';
    }
    return addedValue.egp;
  }
}

enum _SupplierLedgerEventType { invoice, payment }

class _SupplierLedgerEvent {
  const _SupplierLedgerEvent._({
    required this.type,
    required this.date,
    required this.createdAt,
    this.material,
    this.payment,
  });

  factory _SupplierLedgerEvent.invoice(MaterialExpenseEntry material) {
    return _SupplierLedgerEvent._(
      type: _SupplierLedgerEventType.invoice,
      date: material.date,
      createdAt: material.createdAt,
      material: material,
    );
  }

  factory _SupplierLedgerEvent.payment(SupplierPaymentRecord payment) {
    return _SupplierLedgerEvent._(
      type: _SupplierLedgerEventType.payment,
      date: payment.paidAt,
      createdAt: payment.createdAt,
      payment: payment,
    );
  }

  final _SupplierLedgerEventType type;
  final DateTime date;
  final DateTime createdAt;
  final MaterialExpenseEntry? material;
  final SupplierPaymentRecord? payment;
}
