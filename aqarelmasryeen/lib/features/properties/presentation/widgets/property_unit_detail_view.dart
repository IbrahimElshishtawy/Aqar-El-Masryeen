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
    final unit = data.summary.unit;
    final customerName = unit.customerName.trim().isEmpty
        ? 'عميل غير محدد'
        : unit.customerName;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123A33), Color(0xFF1B5C50)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 24,
            offset: Offset(0, 12),
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${data.property.name} • ${data.property.location}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      customerName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<VoidCallback>(
                iconColor: Colors.white,
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(
                label: 'الهاتف',
                value: unit.customerPhone.trim().isEmpty
                    ? '-'
                    : unit.customerPhone,
              ),
              _HeroPill(label: 'النوع', value: unit.unitType.label),
              _HeroPill(label: 'الدور', value: '${unit.floor}'),
              _HeroPill(
                label: 'المساحة',
                value: '${formatUnitArea(unit.area)} م²',
              ),
              _HeroPill(
                label: 'نظام السداد',
                value: unit.paymentPlanType.label,
              ),
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

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
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
            : 1;
        final ratio = count == 1
            ? 1.55
            : constraints.maxWidth < 700
            ? 1.12
            : 1.32;
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
