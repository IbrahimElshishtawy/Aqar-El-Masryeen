part of '../partners_screen.dart';

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.partnerCount,
    required this.hasAccountCount,
    required this.noAccountCount,
  });

  final int partnerCount;
  final int hasAccountCount;
  final int noAccountCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(label: 'عدد الشركاء', value: '$partnerCount'),
          ),
          _buildDivider(theme),
          Expanded(
            child: _StatItem(label: 'مرتبطين بحساب', value: '$hasAccountCount'),
          ),
          _buildDivider(theme),
          Expanded(
            child: _StatItem(label: 'بدون حساب', value: '$noAccountCount'),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: theme.colorScheme.outlineVariant,
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
