part of 'dashboard_partner_sections.dart';

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
    final accent = highlight
        ? const Color(0xFF1E5A47)
        : const Color(0xFF4F584F);
    final background = highlight
        ? const Color(0xFFE8F3ED)
        : const Color(0xFFF2F2EC);

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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
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
    final color = value >= 0
        ? const Color(0xFF1E5A47)
        : const Color(0xFF9A4F42);

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
    final isPayment = record.type == DashboardRecordType.payment;
    final icon = isPayment
        ? Icons.south_west_rounded
        : isExpense
        ? Icons.north_east_rounded
        : Icons.history_rounded;
    final backgroundColor = isPayment
        ? Colors.black
        : isExpense
        ? const Color(0xFFF0F0EA)
        : const Color(0xFFEAF2EF);
    final foregroundColor = isPayment ? Colors.white : Colors.black;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: foregroundColor, size: 18),
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
        if (record.showAmount) ...[
          const SizedBox(width: 12),
          Text(
            '${isExpense ? '-' : '+'}${record.amount.egp}',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }
}
