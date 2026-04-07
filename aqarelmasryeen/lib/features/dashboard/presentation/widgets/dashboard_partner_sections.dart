import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PartnerConnectionSection extends StatelessWidget {
  const PartnerConnectionSection({
    super.key,
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
          ? LinkedPartnerCard(partner: currentPartner!)
          : PartnerLinkPrompt(totalPartners: totalPartners),
    );
  }
}

class LinkedPartnerCard extends StatelessWidget {
  const LinkedPartnerCard({super.key, required this.partner});

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
                child: PartnerMetric(
                  label: 'نسبة الشراكة',
                  value: '${(partner.shareRatio * 100).toStringAsFixed(0)}%',
                  icon: Icons.pie_chart_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PartnerMetric(
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

class PartnerMetric extends StatelessWidget {
  const PartnerMetric({
    super.key,
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

class PartnerLinkPrompt extends StatelessWidget {
  const PartnerLinkPrompt({super.key, required this.totalPartners});

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

class OtherPartnersSection extends StatelessWidget {
  const OtherPartnersSection({super.key, required this.partners});

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
          for (var index = 0; index < partners.length && index < 3; index++) ...[
            OtherPartnerRow(partner: partners[index]),
            if (index != partners.length - 1 && index != 2)
              const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}

class OtherPartnerRow extends StatelessWidget {
  const OtherPartnerRow({super.key, required this.partner});

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

class RecentRecordTile extends StatelessWidget {
  const RecentRecordTile({super.key, required this.record});

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
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
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
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
