import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:aqarelmasryeen/features/dashboard/presentation/widgets/dashboard_finance_chart.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/sales/data/sales_repository.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
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

    final session = ref.watch(authSessionProvider).valueOrNull;
    final partners = partnersAsync.value!;
    final currentPartner = session == null
        ? null
        : _findCurrentPartner(partners, session.userId);
    final otherPartners = currentPartner == null
        ? partners
        : partners.where((partner) => partner.id != currentPartner.id).toList();

    return AppShellScaffold(
      title: 'الرئيسية',
      subtitle: 'ملخص المبيعات والتحصيلات والمصروفات',
      currentIndex: 0,
      actions: _actions(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _DashboardOverviewSection(snapshot: snapshot),
          const SizedBox(height: 12),
          _PartnerConnectionSection(
            currentPartner: currentPartner,
            totalPartners: partners.length,
          ),
          const SizedBox(height: 12),
          if (otherPartners.isNotEmpty)
            _OtherPartnersSection(partners: otherPartners),
          if (otherPartners.isNotEmpty) const SizedBox(height: 12),
          DashboardFinanceChart(buckets: snapshot.chart),
          const SizedBox(height: 12),
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

  Partner? _findCurrentPartner(List<Partner> partners, String userId) {
    for (final partner in partners) {
      if (partner.userId == userId) {
        return partner;
      }
    }
    return null;
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

class _DashboardOverviewSection extends StatelessWidget {
  const _DashboardOverviewSection({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardHero(snapshot: snapshot),
          const SizedBox(height: 12),
          _DashboardStatsGrid(
            cards: [
              _DashboardStatCard(
                label: 'قيمة المبيعات',
                value: snapshot.totalSalesValue.egp,
                subtitle: 'إجمالي العقود المباعة',
                icon: Icons.sell_outlined,
              ),
              _DashboardStatCard(
                label: 'قيمة المصروفات',
                value: snapshot.totalExpenses.egp,
                subtitle: 'مواد البناء وفواتير الموردين',
                icon: Icons.receipt_long_outlined,
              ),
              _DashboardStatCard(
                label: 'الأقساط المحصلة',
                value: snapshot.totalPaidInstallments.egp,
                subtitle: 'التحصيلات المستلمة',
                icon: Icons.payments_outlined,
              ),
              _DashboardStatCard(
                label: 'الأقساط المتبقية',
                value: snapshot.totalRemainingInstallments.egp,
                subtitle: 'أرصدة العملاء المتبقية',
                icon: Icons.schedule_outlined,
              ),
              _DashboardStatCard(
                label: 'مستحقات الموردين',
                value: snapshot.pendingSupplierDues.egp,
                subtitle: 'الالتزامات المفتوحة',
                icon: Icons.inventory_2_outlined,
              ),
              _DashboardStatCard(
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

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.snapshot});

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
                      'ملخص المحفظة',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'متابعة سريعة للمشروعات والتحصيلات والسيولة الحالية',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
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

class _DashboardStatsGrid extends StatelessWidget {
  const _DashboardStatsGrid({required this.cards});

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

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
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

class _PartnerConnectionSection extends StatelessWidget {
  const _PartnerConnectionSection({
    required this.currentPartner,
    required this.totalPartners,
  });

  final Partner? currentPartner;
  final int totalPartners;

  @override
  Widget build(BuildContext context) {
    final isLinked = currentPartner != null;

    return AppPanel(
      title: isLinked ? 'الشريك المرتبط بالحساب' : 'ربط الحساب بالشريك',
      subtitle: isLinked
          ? 'هذا القسم يوضح الشريك المرتبط بالحساب الحالي بشكل مباشر.'
          : 'اربط الحساب الحالي بأحد الشركاء حتى تظهر حصتك وإحصاءاتك بسهولة.',
      trailing: FilledButton.tonalIcon(
        onPressed: () => context.push(AppRoutes.partners),
        icon: Icon(isLinked ? Icons.edit_outlined : Icons.link_rounded),
        label: Text(isLinked ? 'إدارة الشريك' : 'ربط الآن'),
      ),
      child: isLinked
          ? _LinkedPartnerCard(partner: currentPartner!)
          : _PartnerLinkPrompt(totalPartners: totalPartners),
    );
  }
}

class _LinkedPartnerCard extends StatelessWidget {
  const _LinkedPartnerCard({required this.partner});

  final Partner partner;

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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            partner.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'تم ربط هذا الحساب بالشريك الحالي داخل مساحة العمل.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PartnerMetric(
                  label: 'نسبة الشراكة',
                  value: '${(partner.shareRatio * 100).toStringAsFixed(0)}%',
                  icon: Icons.pie_chart_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PartnerMetric(
                  label: 'المساهمة',
                  value: partner.contributionTotal.egp,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PartnerMetric extends StatelessWidget {
  const _PartnerMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(12),
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
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerLinkPrompt extends StatelessWidget {
  const _PartnerLinkPrompt({required this.totalPartners});

  final int totalPartners;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            totalPartners == 0
                ? 'لا يوجد شركاء مضافون بعد.'
                : 'الحساب الحالي غير مربوط بأي شريك حتى الآن.',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            totalPartners == 0
                ? 'أضف شريكًا أولًا ثم فعّل خيار ربطه بالحساب الحالي.'
                : 'يمكنك فتح شاشة الشركاء، تعديل الشريك المطلوب، ثم تفعيل خيار ربطه بالحساب الحالي.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherPartnersSection extends StatelessWidget {
  const _OtherPartnersSection({required this.partners});

  final List<Partner> partners;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'إحصائيات الشركاء الآخرين',
      subtitle: 'نظرة سريعة على بقية الشركاء داخل مساحة العمل.',
      trailing: TextButton.icon(
        onPressed: () => context.push(AppRoutes.partners),
        icon: const Icon(Icons.arrow_outward_rounded, size: 18),
        label: const Text('عرض الكل'),
      ),
      child: Column(
        children: [
          for (
            var index = 0;
            index < partners.length && index < 3;
            index++
          ) ...[
            _OtherPartnerRow(partner: partners[index]),
            if (index != partners.length - 1 && index != 2)
              const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}

class _OtherPartnerRow extends StatelessWidget {
  const _OtherPartnerRow({required this.partner});

  final Partner partner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0EA),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            partner.name.isEmpty ? '?' : partner.name.trim().characters.first,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                partner.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'نسبة ${(partner.shareRatio * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          partner.contributionTotal.egp,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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
