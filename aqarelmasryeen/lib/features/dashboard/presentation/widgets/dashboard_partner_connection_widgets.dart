part of 'dashboard_partner_sections.dart';

class LinkedPartnerCard extends StatelessWidget {
  const LinkedPartnerCard({super.key, required this.partner});

  final Partner partner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F1EC),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  partner.name.isEmpty
                      ? '?'
                      : partner.name.trim().characters.first,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF23443B),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partner.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const _PartnerStatusPill(
                    label: 'مربوط بالحساب الحالي',
                    color: Color(0xFF285847),
                    background: Color(0xFFE7F2EC),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'كل أرقام هذا الشريك ستظهر لك مباشرة في الجدول بالأسفل، وتقدر تعدل الربط أو البيانات وقت ما تحتاج.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PartnerMetric(
                  label: 'نسبة الشراكة',
                  value: _formatPercentage(partner.shareRatio),
                  icon: Icons.pie_chart_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PartnerMetric(
                  label: 'المساهمة',
                  value: partner.contributionTotal.egp,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PartnerMetric(
                  label: 'آخر تحديث',
                  value: partner.updatedAt.formatShort(),
                  icon: Icons.event_note_outlined,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E1DB)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF5A645A)),
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
        color: const Color(0xFFFBFBF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2EC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.link_off_rounded, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  totalPartners == 0
                      ? 'ابدأ بإضافة شريك أولًا'
                      : 'اختَر الشريك الذي تريد ربطه بالحساب الحالي',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            totalPartners == 0
                ? 'من شاشة الشركاء تقدر تضيف أول شريك، وبعدها فعّل خيار "ربط هذا الشريك بالحساب الحالي".'
                : 'من شاشة الشركاء افتح بيانات الشريك، ثم فعّل خيار "ربط هذا الشريك بالحساب الحالي" ليظهر هنا تلقائيًا.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionStatChip extends StatelessWidget {
  const _ConnectionStatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E1DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
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
    );
  }
}
