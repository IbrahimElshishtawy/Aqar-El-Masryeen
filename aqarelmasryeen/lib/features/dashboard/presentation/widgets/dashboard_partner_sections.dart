import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:aqarelmasryeen/features/partners/domain/partner_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/partners/presentation/partner_form_sheet.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/financial_ledger_table.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PartnerConnectionSection extends StatelessWidget {
  const PartnerConnectionSection({
    super.key,
    required this.currentPartner,
    required this.totalPartners,
    required this.linkedPartnersCount,
  });

  final Partner? currentPartner;
  final int totalPartners;
  final int linkedPartnersCount;

  @override
  Widget build(BuildContext context) {
    final isLinked = currentPartner != null;
    final totalUnlinked = totalPartners - linkedPartnersCount;
    final totalShare = currentPartner == null
        ? 0.0
        : currentPartner!.shareRatio * 100;

    return AppPanel(
      title: isLinked ? 'ربط الحساب بالشريك' : 'الحساب غير مربوط',
      subtitle: isLinked
          ? 'الحساب الحالي مربوط بالفعل، وتقدر تعدل بياناته أو تغيّر الربط من شاشة الشركاء.'
          : 'فعّل الربط من بيانات أي شريك علشان تظهر حصتك وتفاصيلك مباشرة في الرئيسية.',
      trailing: FilledButton.tonalIcon(
        onPressed: () => context.go(AppRoutes.partners),
        icon: Icon(isLinked ? Icons.edit_outlined : Icons.link_rounded),
        label: Text(isLinked ? 'إدارة الربط' : 'ربط الآن'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ConnectionStatChip(label: 'عدد الشركاء', value: '$totalPartners'),
              _ConnectionStatChip(
                label: 'مربوطين بحساب',
                value: '$linkedPartnersCount',
              ),
              _ConnectionStatChip(
                label: 'بدون ربط',
                value: '$totalUnlinked',
              ),
              if (isLinked)
                _ConnectionStatChip(
                  label: 'نسبة الحساب الحالي',
                  value: '${totalShare.toStringAsFixed(totalShare % 1 == 0 ? 0 : 1)}%',
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLinked)
            LinkedPartnerCard(partner: currentPartner!)
          else
            PartnerLinkPrompt(totalPartners: totalPartners),
        ],
      ),
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
                  partner.name.isEmpty ? '?' : partner.name.trim().characters.first,
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

class PartnersLedgerSection extends StatelessWidget {
  const PartnersLedgerSection({
    super.key,
    required this.partners,
    required this.summaries,
    required this.currentUserId,
  });

  final List<Partner> partners;
  final List<PartnerLedgerSummaryRow> summaries;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final rows = summaries
        .map(
          (summary) => _PartnerSheetRow(
            summary: summary,
            linkedToCurrentAccount:
                summary.partner.userId.isNotEmpty &&
                summary.partner.userId == currentUserId,
            linkedToAnyAccount: summary.partner.userId.isNotEmpty,
          ),
        )
        .toList();
    final totalContribution = partners.fold<double>(
      0,
      (sum, partner) => sum + partner.contributionTotal,
    );
    final totalPaid = summaries.fold<double>(
      0,
      (sum, summary) => sum + summary.totalPaid,
    );
    final totalOwed = summaries.fold<double>(
      0,
      (sum, summary) => sum + summary.totalOwed,
    );

    return FinancialLedgerTable<_PartnerSheetRow>(
      title: 'شيت الشركاء',
      subtitle:
          'جدول واضح شبه الإكسل يوضح تفاصيل كل شريك، نسبته، حالة الربط، ومدفوعاته الحالية.',
      rows: rows,
      forceTableLayout: true,
      emptyLabel: 'لا توجد بيانات شركاء حتى الآن.',
      sheetLabel: 'جدول الشركاء',
      addLabel: 'إضافة شريك',
      onAdd: () => _openPartnerSheet(context),
      onEdit: (row) => _openPartnerSheet(context, partner: row.summary.partner),
      columns: [
        LedgerColumn(
          label: 'الشريك',
          minWidth: 220,
          valueBuilder: (row) => _PartnerNameCell(
            name: row.summary.partner.name,
            highlight: row.linkedToCurrentAccount,
          ),
        ),
        LedgerColumn(
          label: 'الحساب',
          minWidth: 150,
          valueBuilder: (row) => _PartnerAccountCell(row: row),
        ),
        LedgerColumn(
          label: 'النسبة',
          minWidth: 100,
          numeric: true,
          valueBuilder: (row) => Text(
            _formatPercentage(row.summary.partner.shareRatio),
          ),
        ),
        LedgerColumn(
          label: 'المساهمة',
          minWidth: 138,
          numeric: true,
          valueBuilder: (row) => Text(row.summary.partner.contributionTotal.egp),
        ),
        LedgerColumn(
          label: 'المدفوع',
          minWidth: 130,
          numeric: true,
          valueBuilder: (row) => Text(row.summary.totalPaid.egp),
        ),
        LedgerColumn(
          label: 'المستحق',
          minWidth: 130,
          numeric: true,
          valueBuilder: (row) => Text(row.summary.totalOwed.egp),
        ),
        LedgerColumn(
          label: 'الرصيد',
          minWidth: 130,
          numeric: true,
          valueBuilder: (row) => _BalanceValue(value: row.summary.balance),
        ),
        LedgerColumn(
          label: 'آخر تحديث',
          minWidth: 128,
          valueBuilder: (row) => Text(row.summary.lastUpdated.formatShort()),
        ),
        LedgerColumn(
          label: 'ملاحظات',
          minWidth: 190,
          valueBuilder: (row) => Text(
            row.summary.notes.trim().isEmpty ? '-' : row.summary.notes.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      totalsFooter: LedgerTotalsFooter(
        children: [
          LedgerFooterValue(
            label: 'إجمالي المساهمات',
            value: totalContribution.egp,
          ),
          LedgerFooterValue(label: 'إجمالي المدفوع', value: totalPaid.egp),
          LedgerFooterValue(label: 'إجمالي المستحق', value: totalOwed.egp),
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

class _PartnerSheetRow {
  const _PartnerSheetRow({
    required this.summary,
    required this.linkedToCurrentAccount,
    required this.linkedToAnyAccount,
  });

  final PartnerLedgerSummaryRow summary;
  final bool linkedToCurrentAccount;
  final bool linkedToAnyAccount;
}

class _PartnerNameCell extends StatelessWidget {
  const _PartnerNameCell({required this.name, required this.highlight});

  final String name;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final accent = highlight ? const Color(0xFF1E5A47) : const Color(0xFF4F584F);
    final background = highlight ? const Color(0xFFE8F3ED) : const Color(0xFFF2F2EC);

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            name.isEmpty ? '?' : name.trim().characters.first,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            highlight ? '$name (أنا)' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PartnerAccountCell extends StatelessWidget {
  const _PartnerAccountCell({required this.row});

  final _PartnerSheetRow row;

  @override
  Widget build(BuildContext context) {
    if (row.linkedToCurrentAccount) {
      return const _PartnerStatusPill(
        label: 'الحساب الحالي',
        color: Color(0xFF285847),
        background: Color(0xFFE7F2EC),
      );
    }
    if (row.linkedToAnyAccount) {
      return const _PartnerStatusPill(
        label: 'مربوط بحساب',
        color: Color(0xFF6A6238),
        background: Color(0xFFF5F0DE),
      );
    }
    return const _PartnerStatusPill(
      label: 'غير مربوط',
      color: Color(0xFF6A6660),
      background: Color(0xFFF1F1ED),
    );
  }
}

class _PartnerStatusPill extends StatelessWidget {
  const _PartnerStatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BalanceValue extends StatelessWidget {
  const _BalanceValue({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final color = value >= 0 ? const Color(0xFF1E5A47) : const Color(0xFF9A4F42);

    return Text(
      value.egp,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
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

void _openPartnerSheet(BuildContext context, {Partner? partner}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => PartnerFormSheet(partner: partner),
  );
}

String _formatPercentage(double ratio) {
  final percentage = ratio * 100;
  final decimals = percentage == percentage.roundToDouble() ? 0 : 1;
  return '${percentage.toStringAsFixed(decimals)}%';
}
