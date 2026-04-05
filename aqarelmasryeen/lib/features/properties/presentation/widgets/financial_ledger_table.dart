import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:flutter/material.dart';

class LedgerColumn<T> {
  const LedgerColumn({
    required this.label,
    required this.valueBuilder,
    this.flex = 1,
  });

  final String label;
  final Widget Function(T row) valueBuilder;
  final int flex;
}

class FinancialLedgerTable<T> extends StatelessWidget {
  const FinancialLedgerTable({
    super.key,
    required this.title,
    required this.rows,
    required this.columns,
    this.subtitle,
    this.emptyLabel = 'No records yet',
    this.onAdd,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.addLabel = 'Add item',
    this.totalsFooter,
  });

  final String title;
  final String? subtitle;
  final List<T> rows;
  final List<LedgerColumn<T>> columns;
  final String emptyLabel;
  final VoidCallback? onAdd;
  final ValueChanged<T>? onEdit;
  final ValueChanged<T>? onDelete;
  final ValueChanged<T>? onView;
  final String addLabel;
  final Widget? totalsFooter;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: title,
      subtitle: subtitle,
      trailing: onAdd == null
          ? null
          : FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(addLabel),
            ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (rows.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(emptyLabel),
            );
          }

          final isCompact = constraints.maxWidth < 820;
          if (isCompact) {
            return Column(
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  _CompactLedgerCard<T>(
                    row: rows[index],
                    columns: columns,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onView: onView,
                  ),
                  if (index != rows.length - 1) const SizedBox(height: 12),
                ],
                if (totalsFooter != null) ...[
                  const SizedBox(height: 12),
                  totalsFooter!,
                ],
              ],
            );
          }

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowHeight: 46,
                    dataRowMinHeight: 68,
                    dataRowMaxHeight: 78,
                    border: TableBorder.all(color: const Color(0xFFD8D8D2)),
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF0F0EA),
                    ),
                    columns: [
                      for (final column in columns)
                        DataColumn(label: Text(column.label)),
                      if (_hasActions)
                        const DataColumn(label: Text('Actions')),
                    ],
                    rows: [
                      for (final row in rows)
                        DataRow(
                          cells: [
                            for (final column in columns)
                              DataCell(column.valueBuilder(row)),
                            if (_hasActions) DataCell(_ActionsRow<T>(
                              row: row,
                              onEdit: onEdit,
                              onDelete: onDelete,
                              onView: onView,
                            )),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              if (totalsFooter != null) ...[
                const SizedBox(height: 12),
                totalsFooter!,
              ],
            ],
          );
        },
      ),
    );
  }

  bool get _hasActions => onEdit != null || onDelete != null || onView != null;
}

class FinancialStatusChip extends StatelessWidget {
  const FinancialStatusChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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

class LedgerTotalsFooter extends StatelessWidget {
  const LedgerTotalsFooter({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(14),
      child: Wrap(spacing: 12, runSpacing: 12, children: children),
    );
  }
}

class LedgerFooterValue extends StatelessWidget {
  const LedgerFooterValue({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactLedgerCard<T> extends StatelessWidget {
  const _CompactLedgerCard({
    required this.row,
    required this.columns,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  final T row;
  final List<LedgerColumn<T>> columns;
  final ValueChanged<T>? onEdit;
  final ValueChanged<T>? onDelete;
  final ValueChanged<T>? onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (var index = 0; index < columns.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    columns[index].label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(flex: 6, child: columns[index].valueBuilder(row)),
              ],
            ),
            if (index != columns.length - 1) const Divider(height: 18),
          ],
          if (onEdit != null || onDelete != null || onView != null) ...[
            const SizedBox(height: 8),
            _ActionsRow<T>(
              row: row,
              onEdit: onEdit,
              onDelete: onDelete,
              onView: onView,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionsRow<T> extends StatelessWidget {
  const _ActionsRow({
    required this.row,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  final T row;
  final ValueChanged<T>? onEdit;
  final ValueChanged<T>? onDelete;
  final ValueChanged<T>? onView;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        if (onView != null)
          IconButton(
            onPressed: () => onView!(row),
            icon: const Icon(Icons.visibility_outlined),
          ),
        if (onEdit != null)
          IconButton(
            onPressed: () => onEdit!(row),
            icon: const Icon(Icons.edit_outlined),
          ),
        if (onDelete != null)
          IconButton(
            onPressed: () => onDelete!(row),
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    );
  }
}
