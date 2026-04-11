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
part 'dashboard_partner_connection_widgets.dart';
part 'dashboard_partner_ledger_widgets.dart';

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
              _ConnectionStatChip(
                label: 'عدد الشركاء',
                value: '$totalPartners',
              ),
              _ConnectionStatChip(
                label: 'مربوطين بحساب',
                value: '$linkedPartnersCount',
              ),
              _ConnectionStatChip(label: 'بدون ربط', value: '$totalUnlinked'),
              if (isLinked)
                _ConnectionStatChip(
                  label: 'نسبة الحساب الحالي',
                  value:
                      '${totalShare.toStringAsFixed(totalShare % 1 == 0 ? 0 : 1)}%',
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
          valueBuilder: (row) =>
              Text(_formatPercentage(row.summary.partner.shareRatio)),
        ),
        LedgerColumn(
          label: 'المساهمة',
          minWidth: 138,
          numeric: true,
          valueBuilder: (row) =>
              Text(row.summary.partner.contributionTotal.egp),
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
