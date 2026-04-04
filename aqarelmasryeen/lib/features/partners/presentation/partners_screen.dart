import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/metric_card.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/partners/domain/partner_settlement_calculator.dart';
import 'package:aqarelmasryeen/features/partners/presentation/partner_form_sheet.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final partnersStreamProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(partnerRepositoryProvider).watchPartners(),
);

final partnersExpensesProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(expenseRepositoryProvider).watchAll(),
);

class PartnersScreen extends ConsumerWidget {
  const PartnersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partners = ref.watch(partnersStreamProvider);
    final expenses = ref.watch(partnersExpensesProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;

    return AppShellScaffold(
      title: 'الشركاء',
      currentIndex: 2,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const PartnerFormSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('إضافة شريك'),
      ),
      child: partners.when(
        data: (partnerItems) => expenses.when(
          data: (expenseItems) {
            final settlements = const PartnerSettlementCalculator().build(
              partners: partnerItems,
              expenses: expenseItems,
            );
            final totalCapital = partnerItems.fold<double>(
              0,
              (sum, item) => sum + item.contributionTotal,
            );
            final totalExpected = settlements.fold<double>(
              0,
              (sum, item) => sum + item.expectedContribution,
            );
            final positiveBalances = settlements
                .where((item) => item.balanceDelta >= 0)
                .fold<double>(0, (sum, item) => sum + item.balanceDelta);
            final negativeBalances = settlements
                .where((item) => item.balanceDelta < 0)
                .fold<double>(0, (sum, item) => sum + item.balanceDelta.abs());
            final averageShare = partnerItems.isEmpty
                ? 0.0
                : partnerItems.fold<double>(
                        0,
                        (sum, item) => sum + item.shareRatio,
                      ) /
                    partnerItems.length;

            return ListView(
              padding: EdgeInsets.all(screenWidth < 640 ? 12 : 16),
              children: [
                _PartnersBanner(
                  partnerCount: partnerItems.length,
                  totalCapital: totalCapital,
                  totalExpected: totalExpected,
                  averageShare: averageShare,
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: screenWidth < 520 ? 2 : 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: screenWidth < 520 ? 1.22 : 1.18,
                  children: [
                    MetricCard(
                      label: 'عدد الشركاء',
                      value: '${partnerItems.length}',
                      icon: Icons.groups_outlined,
                    ),
                    MetricCard(
                      label: 'إجمالي المساهمة',
                      value: totalCapital.egp,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    MetricCard(
                      label: 'أرصدة دائنة',
                      value: positiveBalances.egp,
                      icon: Icons.north_east_rounded,
                      color: Colors.green,
                    ),
                    MetricCard(
                      label: 'أرصدة مستحقة',
                      value: negativeBalances.egp,
                      icon: Icons.south_west_rounded,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionHeading(
                  title: 'تفاصيل الشركاء',
                  subtitle: 'متابعة سريعة لنسبة كل شريك ومساهمته ورصيده الحالي.',
                ),
                const SizedBox(height: 12),
                if (partnerItems.isEmpty)
                  const EmptyStateView(
                    title: 'لا توجد سجلات للشركاء',
                    message:
                        'أضف الشركاء لتبدأ في متابعة المساهمات والتسويات والرصيد المستحق لكل طرف.',
                  )
                else
                  for (final settlement in settlements) ...[
                    _PartnerCard(
                      settlement: settlement,
                      partner: partnerItems.firstWhere(
                        (partner) => partner.id == settlement.partnerId,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            );
          },
          error: (error, _) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _PartnersBanner extends StatelessWidget {
  const _PartnersBanner({
    required this.partnerCount,
    required this.totalCapital,
    required this.totalExpected,
    required this.averageShare,
  });

  final int partnerCount;
  final double totalCapital;
  final double totalExpected;
  final double averageShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary,
            theme.colorScheme.primary,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
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
                        'إدارة الشركاء',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'راقب المساهمات ونسب الملكية والتسويات من عرض واحد واضح.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _BannerPill(label: 'عدد الشركاء', value: '$partnerCount'),
                _BannerPill(label: 'إجمالي المساهمة', value: totalCapital.egp),
                _BannerPill(label: 'المتوقع تغطيته', value: totalExpected.egp),
                _BannerPill(
                  label: 'متوسط النسبة',
                  value: _formatPercentage(averageShare),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.settlement, required this.partner});

  final PartnerSettlement settlement;
  final Partner partner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = settlement.balanceDelta >= 0;
    final accent = isPositive ? Colors.green : Colors.redAccent;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.10,
                  ),
                  child: Text(
                    partner.name.isEmpty ? '?' : partner.name.characters.first,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
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
                        settlement.partnerName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'نسبة الشراكة ${_formatPercentage(partner.shareRatio)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _BalanceChip(
                  label: isPositive ? 'رصيد دائن' : 'رصيد مستحق',
                  value: settlement.balanceDelta.egp,
                  color: accent,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ValueTile(
                    label: 'المتوقع',
                    value: settlement.expectedContribution.egp,
                    icon: Icons.pie_chart_outline_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ValueTile(
                    label: 'المدفوع',
                    value: settlement.contributedAmount.egp,
                    icon: Icons.payments_outlined,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => PartnerFormSheet(partner: partner),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل بيانات الشريك'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerPill extends StatelessWidget {
  const _BannerPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: accent.withValues(alpha: 0.16),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatPercentage(double ratio) {
  final percentage = ratio * 100;
  final decimals = percentage == percentage.roundToDouble() ? 0 : 1;
  return '${percentage.toStringAsFixed(decimals)}%';
}
