import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:flutter/material.dart';

class DashboardOverviewSection extends StatelessWidget {
  const DashboardOverviewSection({super.key, required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHero(snapshot: snapshot),
          const SizedBox(height: 12),
          DashboardStatsGrid(
            cards: [
              DashboardStatCard(
                label: 'قيمة المبيعات',
                value: snapshot.totalSalesValue.egp,
                subtitle: 'إجمالي العقود المباعة',
                icon: Icons.sell_outlined,
              ),
              DashboardStatCard(
                label: 'قيمة المصروفات',
                value: snapshot.totalExpenses.egp,
                subtitle: 'مواد البناء وفواتير الموردين',
                icon: Icons.receipt_long_outlined,
              ),
              DashboardStatCard(
                label: 'الأقساط المحصلة',
                value: snapshot.totalPaidInstallments.egp,
                subtitle: 'التحصيلات المستلمة',
                icon: Icons.payments_outlined,
              ),
              DashboardStatCard(
                label: 'الأقساط المتبقية',
                value: snapshot.totalRemainingInstallments.egp,
                subtitle: 'أرصدة العملاء المتبقية',
                icon: Icons.schedule_outlined,
              ),
              DashboardStatCard(
                label: 'مستحقات الموردين',
                value: snapshot.pendingSupplierDues.egp,
                subtitle: 'الالتزامات المفتوحة',
                icon: Icons.inventory_2_outlined,
              ),
              DashboardStatCard(
                label: 'مساهمات الشركاء',
                value: snapshot.partnerContributionTotal.egp,
                subtitle: 'رؤوس الأموال المسجلة',
                icon: Icons.groups_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardHero extends StatelessWidget {
  const DashboardHero({super.key, required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final netValue = snapshot.totalPaidInstallments - snapshot.totalExpenses;
    final netColor = netValue >= 0
        ? const Color(0xFF175546)
        : const Color(0xFFA34836);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFFFEFB), Color(0xFFF3F0E7)],
        ),
        borderRadius: BorderRadius.circular(26),
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
                      'ملخص المشاريع ',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD8D8D2)),
                ),
                child: const Icon(Icons.grid_view_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${snapshot.propertyCount}',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            snapshot.propertyCount == 1
                ? 'مشروع نشط داخل مساحة العمل'
                : 'مشروعات نشطة داخل مساحة العمل',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD8D8D2)),
            ),
            child: Row(
              children: [
                Icon(Icons.wallet_outlined, size: 18, color: netColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'صافي التدفق الحالي',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                Text(
                  netValue.egp,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: netColor,
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

class DashboardStatsGrid extends StatelessWidget {
  const DashboardStatsGrid({super.key, required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 300
            ? 2
            : 1;
        final ratio = switch (count) {
          3 => 1.38,
          2 => 1.08,
          _ => 2.15,
        };
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: ratio,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    super.key,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 180;
        final cardPadding = isCompact ? 12.0 : 14.0;
        final badgeSize = isCompact ? 34.0 : 38.0;
        final valueStyle =
            (isCompact
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.titleLarge)
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  height: 1.15,
                );

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFFFFEFB), Color(0xFFF5F3EC)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD8D8D2)),
          ),
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: isCompact ? 13 : 14,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD8D8D2)),
                    ),
                    child: Icon(icon, size: isCompact ? 17 : 18),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: isCompact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontSize: isCompact ? 11 : 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
