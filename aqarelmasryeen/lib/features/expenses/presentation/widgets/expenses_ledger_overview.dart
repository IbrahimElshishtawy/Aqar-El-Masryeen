part of '../expenses_ledger_screen.dart';

class _ExpensesTopBarActions extends StatelessWidget {
  const _ExpensesTopBarActions({required this.showingHistory});

  final bool showingHistory;

  @override
  Widget build(BuildContext context) {
    final canGoBack = showingHistory || context.canPop();

    if (!canGoBack) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TopBarIconButton(
          icon: Icons.arrow_forward_rounded,
          tooltip: 'رجوع',
          onPressed: () {
            if (showingHistory) {
              context.go(AppRoutes.expenses);
              return;
            }
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
      ],
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        side: const BorderSide(color: Color(0xFFD8D8D2)),
      ),
      icon: Icon(icon),
    );
  }
}

class _ExpensesOverviewPanel extends StatelessWidget {
  const _ExpensesOverviewPanel({
    required this.currentTotal,
    required this.counterpartTotal,
    required this.entriesCount,
    required this.showingHistory,
    required this.hasOlderRows,
    required this.currentColumnLabel,
    required this.counterpartColumnLabel,
    required this.onAddExpense,
    this.onShowMore,
    this.onShowToday,
  });

  final double currentTotal;
  final double counterpartTotal;
  final int entriesCount;
  final bool showingHistory;
  final bool hasOlderRows;
  final String currentColumnLabel;
  final String counterpartColumnLabel;
  final VoidCallback onAddExpense;
  final VoidCallback? onShowMore;
  final VoidCallback? onShowToday;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'ملخص المصروفات',
      subtitle: showingHistory
          ? 'الإجماليات هنا محسوبة من كل المصروفات المسجلة، بينما الجدول بالأسفل يعرض الأيام السابقة فقط.'
          : 'الإجماليات هنا محسوبة من كل المصروفات المسجلة، بينما الصفوف توزع بين $currentColumnLabel و$counterpartColumnLabel.',
      trailing: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (showingHistory && onShowToday != null)
            TextButton(onPressed: onShowToday, child: const Text('اليوم')),
          if (!showingHistory && hasOlderRows && onShowMore != null)
            TextButton(onPressed: onShowMore, child: const Text('عرض المزيد')),
          FilledButton.icon(
            onPressed: onAddExpense,
            icon: const Icon(Icons.add),
            label: const Text('إضافة مصروف'),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _MetricPill(
            label: 'إجمالي $currentColumnLabel',
            value: currentTotal.egp,
          ),
          _MetricPill(
            label: 'إجمالي $counterpartColumnLabel',
            value: counterpartTotal.egp,
          ),
          _MetricPill(label: 'عدد المصروفات', value: '$entriesCount'),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF17352F),
            ),
          ),
        ],
      ),
    );
  }
}
