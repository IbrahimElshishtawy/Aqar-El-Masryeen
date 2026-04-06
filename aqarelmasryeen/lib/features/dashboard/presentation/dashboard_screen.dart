import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/summary_card.dart';
import 'package:aqarelmasryeen/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:aqarelmasryeen/features/dashboard/presentation/widgets/dashboard_finance_chart.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/sales/data/sales_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final dashboardPropertiesProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(propertyRepositoryProvider).watchProperties(),
);
final dashboardUnitsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(salesRepositoryProvider).watchAll(),
);
final dashboardPaymentsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(paymentRepositoryProvider).watchAll(),
);
final dashboardMaterialsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(materialExpenseRepositoryProvider).watchAll(),
);
final dashboardPartnersProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(partnerRepositoryProvider).watchPartners(),
);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(dashboardPropertiesProvider);
    final unitsAsync = ref.watch(dashboardUnitsProvider);
    final paymentsAsync = ref.watch(dashboardPaymentsProvider);
    final materialsAsync = ref.watch(dashboardMaterialsProvider);
    final partnersAsync = ref.watch(dashboardPartnersProvider);

    final hasError =
        propertiesAsync.hasError ||
        unitsAsync.hasError ||
        paymentsAsync.hasError ||
        materialsAsync.hasError ||
        partnersAsync.hasError;
    if (hasError) {
      return AppShellScaffold(
        title: 'الرئيسية',
        subtitle: 'ملخص المبيعات والتحصيلات والمصروفات',
        currentIndex: 0,
        actions: _actions(context),
        child: EmptyStateView(
          title: 'تعذر تحميل لوحة المتابعة',
          message:
              propertiesAsync.error?.toString() ??
              unitsAsync.error?.toString() ??
              paymentsAsync.error?.toString() ??
              materialsAsync.error?.toString() ??
              partnersAsync.error?.toString() ??
              'حدث خطأ غير متوقع',
        ),
      );
    }

    if (!propertiesAsync.hasValue ||
        !unitsAsync.hasValue ||
        !paymentsAsync.hasValue ||
        !materialsAsync.hasValue ||
        !partnersAsync.hasValue) {
      return AppShellScaffold(
        title: 'الرئيسية',
        subtitle: 'ملخص المبيعات والتحصيلات والمصروفات',
        currentIndex: 0,
        actions: _actions(context),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final snapshot = const DashboardSnapshotBuilder().build(
      properties: propertiesAsync.value!,
      units: unitsAsync.value!,
      payments: paymentsAsync.value!,
      materials: materialsAsync.value!,
      partners: partnersAsync.value!,
    );

    return AppShellScaffold(
      title: 'الرئيسية',
      subtitle: 'ملخص المبيعات والتحصيلات والمصروفات',
      currentIndex: 0,
      actions: _actions(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _DashboardCardGrid(
            cards: [
              SummaryCard(
                label: 'المشروعات',
                value: '${snapshot.propertyCount}',
                subtitle: 'إجمالي عدد المشروعات',
                icon: Icons.apartment_rounded,
                emphasis: true,
              ),
              SummaryCard(
                label: 'قيمة المبيعات',
                value: snapshot.totalSalesValue.egp,
                subtitle: 'إجمالي العقود المباعة',
                icon: Icons.sell_outlined,
              ),
              SummaryCard(
                label: 'قيمة المصروفات',
                value: snapshot.totalExpenses.egp,
                subtitle: 'مواد البناء وفواتير الموردين',
                icon: Icons.receipt_long_outlined,
              ),
              SummaryCard(
                label: 'الأقساط المحصلة',
                value: snapshot.totalPaidInstallments.egp,
                subtitle: 'التحصيلات المستلمة',
                icon: Icons.payments_outlined,
              ),
              SummaryCard(
                label: 'الأقساط المتبقية',
                value: snapshot.totalRemainingInstallments.egp,
                subtitle: 'أرصدة العملاء المتبقية',
                icon: Icons.schedule_outlined,
              ),
              SummaryCard(
                label: 'مستحقات الموردين',
                value: snapshot.pendingSupplierDues.egp,
                subtitle: 'التزامات الموردين المفتوحة',
                icon: Icons.inventory_2_outlined,
              ),
              SummaryCard(
                label: 'مساهمات الشركاء',
                value: snapshot.partnerContributionTotal.egp,
                subtitle: 'رؤوس الأموال المسجلة',
                icon: Icons.groups_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          DashboardFinanceChart(buckets: snapshot.chart),
          const SizedBox(height: 12),
          AppPanel(
            title: 'روابط سريعة',
            subtitle: 'افتح الجداول المالية مباشرة',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.properties),
                  icon: const Icon(Icons.apartment_outlined),
                  label: const Text('المشروعات'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.expenses),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('المصروفات'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppPanel(
            title: 'آخر الأنشطة',
            subtitle: 'آخر التحصيلات وحركة الموردين',
            child: snapshot.recentRecords.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('لا توجد حركة مالية حتى الآن.'),
                  )
                : Column(
                    children: [
                      for (
                        var index = 0;
                        index < snapshot.recentRecords.length;
                        index++
                      ) ...[
                        _RecentRecordTile(
                          record: snapshot.recentRecords[index],
                        ),
                        if (index != snapshot.recentRecords.length - 1)
                          const Divider(height: 24),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    return [
      TextButton.icon(
        onPressed: () => context.push(AppRoutes.expensesTab('resources')),
        icon: const Icon(Icons.inventory_2_outlined),
        label: const Text('الموارد'),
      ),
      IconButton(
        onPressed: () => context.push(AppRoutes.expenses),
        icon: const Icon(Icons.receipt_long_outlined),
      ),
      IconButton(
        onPressed: () => context.push(AppRoutes.notifications),
        icon: const Icon(Icons.notifications_none_rounded),
      ),
    ];
  }
}

class _DashboardCardGrid extends StatelessWidget {
  const _DashboardCardGrid({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 960
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: count == 1 ? 2.4 : 1.65,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

class _RecentRecordTile extends StatelessWidget {
  const _RecentRecordTile({required this.record});

  final DashboardRecentRecord record;

  @override
  Widget build(BuildContext context) {
    final isExpense = record.type == DashboardRecordType.expense;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isExpense ? const Color(0xFFF0F0EA) : Colors.black,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isExpense ? Icons.north_east_rounded : Icons.south_west_rounded,
            color: isExpense ? Colors.black : Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text('${record.propertyName} - ${record.subtitle}'),
              const SizedBox(height: 4),
              Text(record.date.formatWithTime()),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${isExpense ? '-' : '+'}${record.amount.egp}',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
