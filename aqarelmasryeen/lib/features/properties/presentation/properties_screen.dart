import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/properties/domain/property_financial_summary.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final propertiesStreamProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(propertyRepositoryProvider).watchProperties(),
);
final propertyExpensesStreamProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(expenseRepositoryProvider).watchAll(),
);
final propertyPaymentsStreamProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(paymentRepositoryProvider).watchAll(),
);

class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesStreamProvider);
    final expensesAsync = ref.watch(propertyExpensesStreamProvider);
    final paymentsAsync = ref.watch(propertyPaymentsStreamProvider);

    if (propertiesAsync.hasError ||
        expensesAsync.hasError ||
        paymentsAsync.hasError) {
      return AppShellScaffold(
        title: 'المشروعات',
        subtitle: 'ملخص الأداء المالي لكل مشروع',
        currentIndex: 1,
        actions: [
          IconButton(
            tooltip: 'إضافة مشروع',
            onPressed: () => context.push('${AppRoutes.properties}/new'),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
        child: EmptyStateView(
          title: 'تعذر تحميل المشروعات',
          message:
              propertiesAsync.error?.toString() ??
              expensesAsync.error?.toString() ??
              paymentsAsync.error?.toString() ??
              'حدث خطأ غير متوقع',
        ),
      );
    }

    if (!propertiesAsync.hasValue ||
        !expensesAsync.hasValue ||
        !paymentsAsync.hasValue) {
      return const AppShellScaffold(
        title: 'المشروعات',
        subtitle: 'ملخص الأداء المالي لكل مشروع',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final summaries = const PropertyFinancialSummaryBuilder().build(
      properties: propertiesAsync.value!,
      expenses: expensesAsync.value!,
      payments: paymentsAsync.value!,
    );
    final totalExpenses = summaries.fold<double>(
      0,
      (sum, summary) => sum + summary.totalExpenses,
    );
    final totalPayments = summaries.fold<double>(
      0,
      (sum, summary) => sum + summary.totalPayments,
    );

    return AppShellScaffold(
      title: 'المشروعات',
      subtitle: 'ملخص الأداء المالي لكل مشروع',
      currentIndex: 1,
      actions: [
        IconButton(
          tooltip: 'إضافة مشروع',
          onPressed: () => context.push('${AppRoutes.properties}/new'),
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _ProjectsOverviewSection(
            projectCount: summaries.length,
            totalExpenses: totalExpenses,
            totalPayments: totalPayments,
          ),
          const SizedBox(height: 12),
          if (summaries.isEmpty)
            const EmptyStateView(
              title: 'لا توجد مشروعات بعد',
              message:
                  'ستظهر المشروعات هنا بعد إضافة البيانات إلى مساحة العمل.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 900) {
                  return Column(
                    children: [
                      for (
                        var index = 0;
                        index < summaries.length;
                        index++
                      ) ...[
                        _PropertySummaryCard(summary: summaries[index]),
                        if (index != summaries.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  );
                }

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: summaries.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.14,
                  ),
                  itemBuilder: (context, index) =>
                      _PropertySummaryCard(summary: summaries[index]),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ProjectsOverviewSection extends StatelessWidget {
  const _ProjectsOverviewSection({
    required this.projectCount,
    required this.totalExpenses,
    required this.totalPayments,
  });

  final int projectCount;
  final double totalExpenses;
  final double totalPayments;

  @override
  Widget build(BuildContext context) {
    final balance = totalPayments - totalExpenses;

    return AppPanel(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;

          final hero = _OverviewHeroCard(
            projectCount: projectCount,
            balance: balance,
          );
          final metrics = [
            _OverviewMetricCard(
              label: 'المصروفات',
              value: totalExpenses.egp,
              subtitle: 'إجمالي مصروفات المشروعات',
              icon: Icons.north_east_rounded,
            ),
            _OverviewMetricCard(
              label: 'التحصيلات',
              value: totalPayments.egp,
              subtitle: 'إجمالي تحصيلات المشروعات',
              icon: Icons.south_west_rounded,
            ),
          ];

          if (isCompact) {
            return Column(
              children: [
                hero,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: metrics[0]),
                    const SizedBox(width: 12),
                    Expanded(child: metrics[1]),
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 8, child: hero),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    Expanded(child: metrics[0]),
                    const SizedBox(height: 12),
                    Expanded(child: metrics[1]),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewHeroCard extends StatelessWidget {
  const _OverviewHeroCard({required this.projectCount, required this.balance});

  final int projectCount;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balanceColor = balance >= 0
        ? const Color(0xFF175546)
        : const Color(0xFF9E3D2D);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFFFEFB), Color(0xFFF4F1E8)],
        ),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(18),
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
                      'المشروعات',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'نظرة سريعة على المحفظة الحالية',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD8D8D2)),
                ),
                child: const Icon(Icons.apartment_rounded, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '$projectCount',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            projectCount == 1
                ? 'مشروع نشط داخل المحفظة'
                : 'مشروعات نشطة داخل المحفظة',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD8D8D2)),
            ),
            child: Row(
              children: [
                Icon(Icons.wallet_outlined, size: 18, color: balanceColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'صافي الحركة',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                Text(
                  balance.egp,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: balanceColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewMetricCard extends StatelessWidget {
  const _OverviewMetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD8D8D2)),
                ),
                child: Icon(icon, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertySummaryCard extends StatelessWidget {
  const _PropertySummaryCard({required this.summary});

  final PropertyFinancialSummary summary;

  @override
  Widget build(BuildContext context) {
    final totalMovement = summary.totalMovement == 0
        ? 1
        : summary.totalMovement;
    final paymentRatio = summary.totalPayments / totalMovement;
    final expenseRatio = summary.totalExpenses / totalMovement;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => context.push(AppRoutes.propertyDetails(summary.property.id)),
      child: AppPanel(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final theme = Theme.of(context);
            final isCompact = constraints.maxWidth < 400;

            return Column(
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
                            summary.property.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            summary.property.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const _OpenProjectBadge(),
                        const SizedBox(height: 10),
                        _StatusChip(label: summary.property.status.label),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'المصروفات',
                        value: summary.totalExpenses.egp,
                        compact: isCompact,
                        icon: Icons.north_east_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                        label: 'التحصيلات',
                        value: summary.totalPayments.egp,
                        compact: isCompact,
                        icon: Icons.south_west_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 9,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (paymentRatio * 1000).round().clamp(1, 1000),
                          child: Container(color: Colors.black),
                        ),
                        Expanded(
                          flex: (expenseRatio * 1000).round().clamp(1, 1000),
                          child: Container(color: const Color(0xFFBBB6AB)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'الرصيد ${summary.balance.egp}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: isCompact ? 15 : null,
                        ),
                      ),
                    ),
                    Text(
                      'تحصيل / مصروف',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OpenProjectBadge extends StatelessWidget {
  const _OpenProjectBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      child: const Icon(Icons.arrow_outward_rounded, size: 18),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: EdgeInsets.all(compact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: compact ? 14 : null,
            ),
          ),
        ],
      ),
    );
  }
}
