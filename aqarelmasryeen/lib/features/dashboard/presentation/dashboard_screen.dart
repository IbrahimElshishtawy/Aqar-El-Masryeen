import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/async_value_view.dart';
import 'package:aqarelmasryeen/features/dashboard/presentation/dashboard_providers.dart';
import 'package:aqarelmasryeen/features/dashboard/presentation/widgets/dashboard_finance_chart.dart';
import 'package:aqarelmasryeen/features/dashboard/presentation/widgets/dashboard_overview_section.dart';
import 'package:aqarelmasryeen/features/dashboard/presentation/widgets/dashboard_partner_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardViewDataProvider);

    return AppShellScaffold(
      title: 'الرئيسية',
      subtitle: 'ملخص المبيعات والتحصيلات والمصروفات',
      currentIndex: 0,
      actions: _actions(context),
      child: AsyncValueView(
        value: dashboardAsync,
        loadingLabel: 'جار تحميل لوحة المتابعة',
        data: (viewData) => ListView(
          padding: const EdgeInsets.fromLTRB(6, 1, 6, 4),
          children: [
            DashboardOverviewSection(snapshot: viewData.snapshot),
            const SizedBox(height: 5),
            DashboardFinanceChart(buckets: viewData.snapshot.chart),
            const SizedBox(height: 5),
            AppPanel(
              title: 'روابط سريعة',
              subtitle: 'افتح الجداول والأقسام الأساسية مباشرة',
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
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.partners),
                    icon: const Icon(Icons.groups_outlined),
                    label: const Text('الشركاء'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppPanel(
              title: 'آخر الأنشطة',
              subtitle: 'آخر التحصيلات وحركة الموردين',
              child: viewData.snapshot.recentRecords.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('لا توجد حركة مالية حتى الآن.'),
                    )
                  : Column(
                      children: [
                        for (
                          var index = 0;
                          index < viewData.snapshot.recentRecords.length;
                          index++
                        ) ...[
                          RecentRecordTile(
                            record: viewData.snapshot.recentRecords[index],
                          ),
                          if (index !=
                              viewData.snapshot.recentRecords.length - 1)
                            const Divider(height: 24),
                        ],
                      ],
                    ),
            ),
          ],
        ),
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
