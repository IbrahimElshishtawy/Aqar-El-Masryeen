import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/utils/partner_display_labels.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:aqarelmasryeen/features/dashboard/presentation/dashboard_providers.dart';
import 'package:flutter/material.dart';

class DashboardOverviewSection extends StatelessWidget {
  const DashboardOverviewSection({super.key, required this.viewData});

  final DashboardViewData viewData;

  @override
  Widget build(BuildContext context) {
    final snapshot = viewData.snapshot;
    final counterpartLabel = resolveCounterpartPartyLabel(
      partners: viewData.partners,
      currentPartner: viewData.currentPartner,
      fallback: 'الشريك',
      maxVisibleNames: 1,
    );
    final counterpartExpensesLabel = counterpartLabel == 'الشريك'
        ? 'مصروفات الشريك'
        : 'مصروفات $counterpartLabel';

    return AppPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHero(snapshot: snapshot),
          const SizedBox(height: 5),
          DashboardStatsGrid(
            cards: [
              DashboardStatCard(
                label: 'إجمالي المصروفات',
                value: snapshot.totalExpenses.egp,
                subtitle:
                    'كل المصروفات المباشرة مع المدفوع الفعلي للمواد والموردين',
                icon: Icons.receipt_long_outlined,
              ),
              DashboardStatCard(
                label: 'مصروفاتك',
                value: snapshot.currentUserExpenses.egp,
                subtitle:
                    'كل ما تم تسجيله أو دفعه من جهتك داخل المصروفات والمواد',
                icon: Icons.person_outline_rounded,
              ),
              DashboardStatCard(
                label: counterpartExpensesLabel,
                value: snapshot.counterpartExpenses.egp,
                subtitle: 'إجمالي ما يخص الطرف الآخر من المصروفات والمدفوعات',
                icon: Icons.groups_2_outlined,
              ),
              DashboardStatCard(
                label: 'قيمة المبيعات',
                value: snapshot.totalSalesValue.egp,
                subtitle: 'إجمالي المبيعات على مستوى كل المشاريع والوحدات',
                icon: Icons.sell_outlined,
              ),
              DashboardStatCard(
                label: 'الأقساط المحصلة',
                value: snapshot.totalPaidInstallments.egp,
                subtitle: 'المقدمات وكل الدفعات المحصلة من العملاء',
                icon: Icons.payments_outlined,
              ),
              DashboardStatCard(
                label: 'الأقساط المتبقية',
                value: snapshot.totalRemainingInstallments.egp,
                subtitle: 'المتبقي على العملاء على مستوى النظام بالكامل',
                icon: Icons.schedule_outlined,
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFFFEFB), Color(0xFFF3F0E7)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(13),
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
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD8D8D2)),
                ),
                child: const Icon(Icons.grid_view_rounded),
              ),
            ],
          ),
          const SizedBox(height: 5),
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
        final count = constraints.maxWidth >= 920
            ? 4
            : constraints.maxWidth >= 520
            ? 2
            : constraints.maxWidth >= 285
            ? 2
            : 1;
        final ratio = switch (count) {
          4 => 1.02,
          2 => constraints.maxWidth < 340 ? 0.88 : 0.96,
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
        final isCompact = constraints.maxWidth <= 132;
        final isTight = constraints.maxWidth <= 118;
        final cardPadding = isCompact ? 12.0 : 14.0;
        final badgeSize = isTight ? 26.0 : 30.0;
        final sectionSpacing = isCompact ? 8.0 : 10.0;
        final valueStyle =
            (isCompact
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.titleLarge)
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  height: isCompact ? 1.05 : 1.15,
                  fontSize: isTight ? 18 : null,
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
                        fontSize: isTight ? 12 : (isCompact ? 13 : 14),
                        height: isCompact ? 1.15 : 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 1),
                  Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD8D8D2)),
                    ),
                    child: Icon(
                      icon,
                      size: isTight ? 16 : (isCompact ? 17 : 18),
                    ),
                  ),
                ],
              ),
              SizedBox(height: sectionSpacing),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
              SizedBox(height: sectionSpacing),
              Text(
                subtitle,
                maxLines: isCompact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontSize: isTight ? 10 : (isCompact ? 11 : 12),
                  height: isCompact ? 1.15 : 1.25,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
