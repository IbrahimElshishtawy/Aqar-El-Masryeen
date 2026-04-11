part of '../reports_screen.dart';

class _PropertyPerformanceCard extends StatelessWidget {
  const _PropertyPerformanceCard({
    required this.property,
    required this.totalPortfolioTarget,
  });

  final PropertyProject property;
  final double totalPortfolioTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(property.status);
    final progress = totalPortfolioTarget <= 0
        ? 0.0
        : (property.totalSalesTarget / totalPortfolioTarget).clamp(0, 1);

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        property.location,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusPill(
                  label: 'الحالة',
                  value: property.status.label,
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ReportRow(
              label: 'المستهدف البيعي',
              value: property.totalSalesTarget.egp,
            ),
            const SizedBox(height: 12),
            _ReportRow(
              label: 'موازنة المشروع',
              value: property.totalBudget.egp,
            ),
            const SizedBox(height: 14),
            Text(
              'وزن المشروع داخل المحفظة',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.toDouble(),
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: statusColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.planning:
        return Colors.indigo;
      case PropertyStatus.active:
        return Colors.green;
      case PropertyStatus.delivered:
        return Colors.teal;
      case PropertyStatus.archived:
        return Colors.orange;
    }
  }
}
