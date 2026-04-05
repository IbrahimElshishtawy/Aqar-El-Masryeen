import 'dart:math' as math;

import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:flutter/material.dart';

class LedgerColumn<T> {
  const LedgerColumn({
    required this.label,
    required this.valueBuilder,
    this.flex = 1,
    this.minWidth = 120,
    this.numeric = false,
  });

  final String label;
  final Widget Function(T row) valueBuilder;
  final int flex;
  final double minWidth;
  final bool numeric;
}

class FinancialLedgerTable<T> extends StatelessWidget {
  const FinancialLedgerTable({
    super.key,
    required this.title,
    required this.rows,
    required this.columns,
    this.subtitle,
    this.emptyLabel = 'لا توجد بيانات حالياً',
    this.onAdd,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.addLabel = 'إضافة',
    this.totalsFooter,
    this.sheetLabel,
    this.showRowNumbers = true,
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
  final String? sheetLabel;
  final bool showRowNumbers;

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
                    rowNumber: showRowNumbers ? index + 1 : null,
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
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFDF9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD8D8D2)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _LedgerSheetBanner(
                      label: sheetLabel ?? 'عرض جدولي • ${rows.length} صف',
                      rowCount: rows.length,
                      columnCount: columns.length + (showRowNumbers ? 1 : 0),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: math.max(
                            constraints.maxWidth,
                            _minimumTableWidth,
                          ),
                        ),
                        child: DataTable(
                          columnSpacing: 0,
                          horizontalMargin: 0,
                          dividerThickness: 0,
                          headingRowHeight: 48,
                          dataRowMinHeight: 62,
                          dataRowMaxHeight: 74,
                          border: const TableBorder(
                            horizontalInside: BorderSide(
                              color: Color(0xFFE0E0D7),
                            ),
                            verticalInside: BorderSide(
                              color: Color(0xFFE0E0D7),
                            ),
                          ),
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFE7EFE3),
                          ),
                          columns: [
                            if (showRowNumbers)
                              const DataColumn(
                                numeric: true,
                                label: _HeaderLabel('#'),
                              ),
                            for (final column in columns)
                              DataColumn(
                                numeric: column.numeric,
                                label: _HeaderLabel(column.label),
                              ),
                            if (_hasActions)
                              const DataColumn(
                                label: _HeaderLabel('الإجراءات'),
                              ),
                          ],
                          rows: [
                            for (final entry in rows.asMap().entries)
                              DataRow.byIndex(
                                index: entry.key,
                                color: WidgetStateProperty.all(
                                  entry.key.isEven
                                      ? Colors.white
                                      : const Color(0xFFF7F8F3),
                                ),
                                cells: [
                                  if (showRowNumbers)
                                    DataCell(
                                      _DesktopLedgerCell(
                                        minWidth: 56,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          '${entry.key + 1}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF5F655B),
                                              ),
                                        ),
                                      ),
                                    ),
                                  for (final column in columns)
                                    DataCell(
                                      _DesktopLedgerCell(
                                        minWidth: column.minWidth,
                                        alignment: column.numeric
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: column.valueBuilder(entry.value),
                                      ),
                                    ),
                                  if (_hasActions)
                                    DataCell(
                                      _DesktopLedgerCell(
                                        minWidth: 128,
                                        alignment: Alignment.center,
                                        child: _ActionsRow<T>(
                                          row: entry.value,
                                          onEdit: onEdit,
                                          onDelete: onDelete,
                                          onView: onView,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
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

  double get _minimumTableWidth {
    final columnsWidth = columns.fold<double>(
      0,
      (sum, column) => sum + column.minWidth,
    );
    final actionsWidth = _hasActions ? 128.0 : 0.0;
    final rowNumberWidth = showRowNumbers ? 56.0 : 0.0;
    return columnsWidth + actionsWidth + rowNumberWidth;
  }
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
  const LedgerTotalsFooter({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F3),
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
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CompactLedgerCard<T> extends StatelessWidget {
  const _CompactLedgerCard({
    required this.row,
    required this.rowNumber,
    required this.columns,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  final T row;
  final int? rowNumber;
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
        color: const Color(0xFFFDFDF9),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          if (rowNumber != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.grid_on_rounded,
                  size: 16,
                  color: Color(0xFF2E6B3F),
                ),
                const SizedBox(width: 8),
                Text(
                  'صف $rowNumber',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E6B3F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
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
                      fontWeight: FontWeight.w700,
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
            visualDensity: VisualDensity.compact,
            tooltip: 'عرض',
          ),
        if (onEdit != null)
          IconButton(
            onPressed: () => onEdit!(row),
            icon: const Icon(Icons.edit_outlined),
            visualDensity: VisualDensity.compact,
            tooltip: 'تعديل',
          ),
        if (onDelete != null)
          IconButton(
            onPressed: () => onDelete!(row),
            icon: const Icon(Icons.delete_outline),
            visualDensity: VisualDensity.compact,
            tooltip: 'حذف',
          ),
      ],
    );
  }
}

class _LedgerSheetBanner extends StatelessWidget {
  const _LedgerSheetBanner({
    required this.label,
    required this.rowCount,
    required this.columnCount,
  });

  final String label;
  final int rowCount;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFEFF5EC),
        border: Border(bottom: BorderSide(color: Color(0xFFD8D8D2))),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 8,
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.grid_on_rounded,
                size: 18,
                color: Color(0xFF2E6B3F),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E6B3F),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SheetStatChip(label: '$rowCount صف'),
              _SheetStatChip(label: '$columnCount عمود'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetStatChip extends StatelessWidget {
  const _SheetStatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD5DED1)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF50624E),
        ),
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF465145),
        ),
      ),
    );
  }
}

class _DesktopLedgerCell extends StatelessWidget {
  const _DesktopLedgerCell({
    required this.child,
    required this.minWidth,
    required this.alignment,
  });

  final Widget child;
  final double minWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: child,
    );
  }
}
