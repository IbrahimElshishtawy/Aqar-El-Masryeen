import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/summary_card.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/features/properties/presentation/property_detail_presenters.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/financial_ledger_table.dart';
import 'package:aqarelmasryeen/features/unit_sales/domain/unit_sales_calculator.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';

class PropertyUnitDetailView extends StatelessWidget {
  const PropertyUnitDetailView({
    super.key,
    required this.data,
    required this.onEditUnit,
    required this.onDeleteUnit,
    required this.onAddInstallment,
    required this.onEditInstallment,
    required this.onDeleteInstallment,
    required this.onViewInstallmentPayments,
    required this.onAddPayment,
    required this.onEditPayment,
    required this.onDeletePayment,
  });

  final PropertyUnitViewData data;
  final VoidCallback onEditUnit;
  final VoidCallback onDeleteUnit;
  final VoidCallback onAddInstallment;
  final ValueChanged<Installment> onEditInstallment;
  final ValueChanged<Installment> onDeleteInstallment;
  final ValueChanged<InstallmentComputedRow> onViewInstallmentPayments;
  final ValueChanged<String> onAddPayment;
  final ValueChanged<PaymentRecord> onEditPayment;
  final ValueChanged<PaymentRecord> onDeletePayment;

  @override
  Widget build(BuildContext context) {
    final summary = data.summary;
    final projectedCompletion = summary.projectedCompletionDate == null
        ? 'غير محدد'
        : summary.projectedCompletionDate!.formatShort();
    final installmentLabels = {
      for (final row in summary.installmentRows)
        row.installment.id: 'قسط ${row.installment.sequence}',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _UnitHeroCard(
          data: data,
          onEditUnit: onEditUnit,
          onDeleteUnit: onDeleteUnit,
        ),
        const SizedBox(height: 16),
        _ResponsiveGrid(
          children: [
            SummaryCard(
              label: 'الإجمالي',
              value: summary.totalContractAmount.egp,
              subtitle: 'قيمة التعاقد النهائية',
              icon: Icons.description_outlined,
              emphasis: true,
            ),
            SummaryCard(
              label: 'المقدم',
              value: summary.unit.downPayment.egp,
              subtitle: 'المبلغ المحصل مقدمًا',
              icon: Icons.savings_outlined,
            ),
            SummaryCard(
              label: 'إجمالي المدفوع',
              value: summary.totalPaidSoFar.egp,
              subtitle: 'المقدم + الأقساط المدفوعة',
              icon: Icons.payments_outlined,
            ),
            SummaryCard(
              label: 'المتبقي',
              value: summary.totalRemaining.egp,
              subtitle: '${summary.unpaidInstallmentsCount} أقساط غير مسددة',
              icon: Icons.schedule_outlined,
            ),
            SummaryCard(
              label: 'إنهاء الأقساط',
              value: projectedCompletion,
              subtitle: summary.remainingDuration.inDays <= 0
                  ? 'مستحق الآن أو مكتمل'
                  : '${summary.remainingDuration.inDays} يوم متبقٍ',
              icon: Icons.event_available_outlined,
            ),
            SummaryCard(
              label: 'حالة الوحدة',
              value: unitAlertLabelForSummary(summary),
              subtitle:
                  '${summary.paidInstallmentsCount}/${summary.totalInstallmentsCount} أقساط مدفوعة',
              icon: Icons.table_chart_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FinancialLedgerTable<InstallmentComputedRow>(
          title: 'شيت أقساط الوحدة',
          subtitle:
              '${summary.installmentRows.length} صف - متبقي ${summary.totalRemainingInstallmentsAmount.egp}',
          rows: summary.installmentRows,
          forceTableLayout: true,
          onAdd: onAddInstallment,
          addLabel: 'إضافة قسط',
          onView: onViewInstallmentPayments,
          onEdit: (row) => onEditInstallment(row.installment),
          onDelete: (row) => onDeleteInstallment(row.installment),
          sheetLabel: 'شيت أقساط الوحدة',
          columns: [
            LedgerColumn(
              label: 'رقم القسط',
              valueBuilder: (row) => Text('${row.installment.sequence}'),
              minWidth: 82,
              numeric: true,
            ),
            LedgerColumn(
              label: 'الاستحقاق',
              valueBuilder: (row) =>
                  Text(row.installment.dueDate.formatShort()),
              minWidth: 116,
            ),
            LedgerColumn(
              label: 'قيمة القسط',
              valueBuilder: (row) => Text(row.installment.amount.egp),
              minWidth: 124,
              numeric: true,
            ),
            LedgerColumn(
              label: 'من دفع',
              valueBuilder: (row) => Text(row.payerSummary),
              minWidth: 170,
            ),
            LedgerColumn(
              label: 'المدفوع',
              valueBuilder: (row) => Text(row.amountPaid.egp),
              minWidth: 120,
              numeric: true,
            ),
            LedgerColumn(
              label: 'المتبقي',
              valueBuilder: (row) => Text(row.remainingAmount.egp),
              minWidth: 120,
              numeric: true,
            ),
            LedgerColumn(
              label: 'الحالة',
              valueBuilder: (row) => FinancialStatusChip(
                label: row.status.label,
                color: row.status == InstallmentStatus.paid
                    ? Colors.green
                    : row.status == InstallmentStatus.partiallyPaid
                    ? Colors.orange
                    : row.status == InstallmentStatus.overdue
                    ? Colors.redAccent
                    : Colors.blueGrey,
              ),
              minWidth: 126,
            ),
            LedgerColumn(
              label: 'التنبيه',
              valueBuilder: (row) => FinancialStatusChip(
                label: installmentAlertLabelForRow(row),
                color: installmentAlertColorForRow(row),
              ),
              minWidth: 118,
            ),
          ],
          totalsFooter: LedgerTotalsFooter(
            children: [
              LedgerFooterValue(
                label: 'عدد الأقساط',
                value: '${summary.installmentScheduleCount}',
              ),
              LedgerFooterValue(
                label: 'الأقساط المدفوعة',
                value: '${summary.paidInstallmentsCount}',
              ),
              LedgerFooterValue(
                label: 'مدفوع جزئي',
                value: '${summary.partiallyPaidInstallmentsCount}',
              ),
              LedgerFooterValue(
                label: 'متأخر',
                value: '${summary.overdueInstallmentsCount}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FinancialLedgerTable<PaymentRecord>(
          title: 'شيت التحصيل',
          subtitle:
              '${data.payments.length} دفعة - الإجمالي ${data.payments.fold<double>(0, (sum, item) => sum + item.amount).egp}',
          rows: data.payments,
          forceTableLayout: true,
          sheetLabel: 'شيت التحصيل',
          onEdit: onEditPayment,
          onDelete: onDeletePayment,
          onAdd: summary.installmentRows.isEmpty
              ? null
              : () =>
                    onAddPayment(summary.installmentRows.first.installment.id),
          addLabel: 'إضافة دفعة',
          columns: [
            LedgerColumn(
              label: 'التاريخ',
              valueBuilder: (row) => Text(row.receivedAt.formatShort()),
              minWidth: 116,
            ),
            LedgerColumn(
              label: 'العميل / الدافع',
              valueBuilder: (row) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    row.customerName.trim().isEmpty
                        ? summary.unit.customerName
                        : row.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    row.effectivePayerName.isEmpty
                        ? '-'
                        : row.effectivePayerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              minWidth: 190,
            ),
            LedgerColumn(
              label: 'طريقة الدفع',
              valueBuilder: (row) => Text(row.paymentMethod.label),
              minWidth: 130,
            ),
            LedgerColumn(
              label: 'المصدر',
              valueBuilder: (row) =>
                  Text(row.paymentSource.isEmpty ? '-' : row.paymentSource),
              minWidth: 150,
            ),
            LedgerColumn(
              label: 'القسط',
              valueBuilder: (row) => Text(
                row.installmentId == null
                    ? '-'
                    : (installmentLabels[row.installmentId!] ?? 'دفعة خاصة'),
              ),
              minWidth: 116,
            ),
            LedgerColumn(
              label: 'المبلغ',
              valueBuilder: (row) => Text(row.amount.egp),
              minWidth: 124,
              numeric: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _UnitHeroCard extends StatelessWidget {
  const _UnitHeroCard({
    required this.data,
    required this.onEditUnit,
    required this.onDeleteUnit,
  });

  final PropertyUnitViewData data;
  final VoidCallback onEditUnit;
  final VoidCallback onDeleteUnit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = data.summary.unit;
    final customerName = unit.customerName.trim().isEmpty
        ? 'عميل غير محدد'
        : unit.customerName;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFD8D8D2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الوحدة ${unit.unitNumber}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${data.property.name} • ${data.property.location}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      customerName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<VoidCallback>(
                iconColor: theme.colorScheme.onSurface,
                onSelected: (callback) => callback(),
                itemBuilder: (_) => [
                  PopupMenuItem<VoidCallback>(
                    value: onEditUnit,
                    child: const Text('تعديل الوحدة'),
                  ),
                  PopupMenuItem<VoidCallback>(
                    value: onDeleteUnit,
                    child: const Text('حذف الوحدة'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _UnitInfoTable(
            rows: [
              MapEntry(
                'الهاتف',
                unit.customerPhone.trim().isEmpty ? '-' : unit.customerPhone,
              ),
              MapEntry('النوع', unit.unitType.label),
              MapEntry('الدور', '${unit.floor}'),
              MapEntry('المساحة', '${formatUnitArea(unit.area)} م²'),
              MapEntry('نظام السداد', unit.paymentPlanType.label),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FinancialStatusChip(
                label: unit.status.label,
                color: unitStatusColor(unit.status),
              ),
              FinancialStatusChip(
                label: unitAlertLabelForSummary(data.summary),
                color: unitAlertColorForSummary(data.summary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnitInfoTable extends StatelessWidget {
  const _UnitInfoTable({required this.rows});

  final List<MapEntry<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.15),
          1: FlexColumnWidth(1.85),
        },
        children: [
          for (var index = 0; index < rows.length; index++)
            TableRow(
              decoration: BoxDecoration(
                border: index == rows.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFFD8D8D2)),
                      ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Text(
                    rows[index].key,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Text(
                    rows[index].value,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 960
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : constraints.maxWidth >= 330
            ? 2
            : 1;
        final ratio = count == 1
            ? 1.95
            : constraints.maxWidth < 420
            ? 1.12
            : constraints.maxWidth < 700
            ? 1.28
            : 1.42;
        return GridView.count(
          crossAxisCount: count,
          childAspectRatio: ratio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: children,
        );
      },
    );
  }
}
