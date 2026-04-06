import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/summary_card.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/features/properties/presentation/property_detail_presenters.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/financial_ledger_table.dart';
import 'package:aqarelmasryeen/features/unit_sales/domain/unit_sales_calculator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PropertySalesWorkspace extends StatelessWidget {
  const PropertySalesWorkspace({
    super.key,
    required this.data,
    required this.onAddUnit,
  });

  final PropertyProjectViewData data;
  final VoidCallback onAddUnit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SalesSummaryGrid(data: data),
        const SizedBox(height: 16),
        _UnitsOverviewPanel(data: data, onAddUnit: onAddUnit),
        const SizedBox(height: 16),
        FinancialLedgerTable<UnitSaleComputedSummary>(
          title: 'شيت مبيعات العقار',
          subtitle:
              'مستوحى من الإكسل لعرض كل وحدة، المدفوع، المتبقي، وحالة الأقساط من نفس الشاشة.',
          rows: data.unitSummaries,
          onAdd: onAddUnit,
          addLabel: 'إضافة وحدة',
          sheetLabel: 'شيت مبيعات الوحدات',
          onView: (row) => context.push(
            AppRoutes.propertyUnitDetails(data.property.id, row.unit.id),
          ),
          columns: [
            LedgerColumn(
              label: 'الوحدة / العميل',
              valueBuilder: (row) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(row.unit.unitNumber),
                  Text(
                    row.unit.customerName.trim().isEmpty
                        ? 'عميل غير محدد'
                        : row.unit.customerName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              minWidth: 190,
            ),
            LedgerColumn(
              label: 'المقدم',
              valueBuilder: (row) => Text(row.unit.downPayment.egp),
              minWidth: 116,
              numeric: true,
            ),
            LedgerColumn(
              label: 'قيمة البيع',
              valueBuilder: (row) => Text(row.unit.saleAmount.egp),
              minWidth: 124,
              numeric: true,
            ),
            LedgerColumn(
              label: 'الإجمالي',
              valueBuilder: (row) => Text(row.totalContractAmount.egp),
              minWidth: 124,
              numeric: true,
            ),
            LedgerColumn(
              label: 'المدفوع',
              valueBuilder: (row) => Text(row.totalPaidSoFar.egp),
              minWidth: 124,
              numeric: true,
            ),
            LedgerColumn(
              label: 'المتبقي',
              valueBuilder: (row) => Text(row.totalRemaining.egp),
              minWidth: 124,
              numeric: true,
            ),
            LedgerColumn(
              label: 'حالة الأقساط',
              valueBuilder: (row) => FinancialStatusChip(
                label: unitAlertLabelForSummary(row),
                color: unitAlertColorForSummary(row),
              ),
              minWidth: 124,
            ),
            LedgerColumn(
              label: 'من دفع',
              valueBuilder: (row) => Text(
                payerNamesSummary(row),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              minWidth: 170,
            ),
            LedgerColumn(
              label: 'الأقساط',
              valueBuilder: (row) => Text(
                '${row.paidInstallmentsCount}/${row.totalInstallmentsCount}',
              ),
              minWidth: 92,
              numeric: true,
            ),
          ],
          totalsFooter: LedgerTotalsFooter(
            children: [
              LedgerFooterValue(
                label: 'إجمالي المبيعات',
                value: data.totalSalesValue.egp,
              ),
              LedgerFooterValue(
                label: 'المحصل من الأقساط',
                value: data.totalPaidInstallments.egp,
              ),
              LedgerFooterValue(
                label: 'المتبقي من الأقساط',
                value: data.totalRemainingInstallments.egp,
              ),
              LedgerFooterValue(
                label: 'أقساط متأخرة',
                value: '${data.overdueInstallments}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SalesSummaryGrid extends StatelessWidget {
  const _SalesSummaryGrid({required this.data});

  final PropertyProjectViewData data;

  @override
  Widget build(BuildContext context) {
    return _ResponsiveGrid(
      children: [
        SummaryCard(
          label: 'الوحدات',
          value: '${data.unitSummaries.length}',
          subtitle: 'إجمالي الوحدات المسجلة داخل العقار',
          icon: Icons.apartment_outlined,
          emphasis: true,
        ),
        SummaryCard(
          label: 'إجمالي المبيعات',
          value: data.totalSalesValue.egp,
          subtitle: 'قيمة العقود المباعة حتى الآن',
          icon: Icons.sell_outlined,
        ),
        SummaryCard(
          label: 'الأقساط المحصلة',
          value: data.totalPaidInstallments.egp,
          subtitle: 'ما تم تحصيله من جداول الأقساط',
          icon: Icons.payments_outlined,
        ),
        SummaryCard(
          label: 'الأقساط المتبقية',
          value: data.totalRemainingInstallments.egp,
          subtitle: 'رصيد الأقساط المفتوح داخل العقار',
          icon: Icons.schedule_outlined,
        ),
      ],
    );
  }
}

class _UnitsOverviewPanel extends StatelessWidget {
  const _UnitsOverviewPanel({required this.data, required this.onAddUnit});

  final PropertyProjectViewData data;
  final VoidCallback onAddUnit;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'بطاقات الوحدات',
      subtitle: data.unitSummaries.isEmpty
          ? 'أضف أول وحدة ثم افتح المبيعات والتحصيل من نفس المكان.'
          : 'واجهة سريعة لفتح كل وحدة بدل التنقل داخل جداول طويلة.',
      trailing: FilledButton.icon(
        onPressed: onAddUnit,
        icon: const Icon(Icons.add),
        label: const Text('إضافة وحدة'),
      ),
      child: data.unitSummaries.isEmpty
          ? const EmptyStateView(
              title: 'لا توجد وحدات بعد',
              message: 'بمجرد إضافة وحدة ستظهر هنا كبطاقة موبايل جاهزة للفتح.',
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1050
                    ? 3
                    : constraints.maxWidth >= 720
                    ? 2
                    : 1;
                return GridView.builder(
                  itemCount: data.unitSummaries.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: columns == 1 ? 1.08 : 0.98,
                  ),
                  itemBuilder: (context, index) => _UnitOverviewCard(
                    summary: data.unitSummaries[index],
                    propertyId: data.property.id,
                  ),
                );
              },
            ),
    );
  }
}

class _UnitOverviewCard extends StatelessWidget {
  const _UnitOverviewCard({required this.summary, required this.propertyId});

  final UnitSaleComputedSummary summary;
  final String propertyId;

  @override
  Widget build(BuildContext context) {
    final customerName = summary.unit.customerName.trim().isEmpty
        ? 'عميل غير محدد'
        : summary.unit.customerName;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.push(
        AppRoutes.propertyUnitDetails(propertyId, summary.unit.id),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD9DED6)),
          color: const Color(0xFFFFFEFB),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الوحدة ${summary.unit.unitNumber}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                FinancialStatusChip(
                  label: unitAlertLabelForSummary(summary),
                  color: unitAlertColorForSummary(summary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricPill(
                  label: 'الإجمالي',
                  value: summary.totalContractAmount.egp,
                ),
                _MetricPill(
                  label: 'المدفوع',
                  value: summary.totalPaidSoFar.egp,
                ),
                _MetricPill(
                  label: 'المتبقي',
                  value: summary.totalRemaining.egp,
                ),
                _MetricPill(
                  label: 'الأقساط',
                  value:
                      '${summary.paidInstallmentsCount}/${summary.totalInstallmentsCount}',
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => context.push(
                  AppRoutes.propertyUnitDetails(propertyId, summary.unit.id),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('فتح التفاصيل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 116),
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

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 960
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final ratio = count == 1
            ? 1.55
            : constraints.maxWidth < 700
            ? 1.12
            : 1.35;
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
