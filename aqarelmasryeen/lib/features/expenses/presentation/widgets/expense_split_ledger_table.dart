import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:flutter/material.dart';

class ExpenseSplitLedgerRow {
  const ExpenseSplitLedgerRow({
    required this.dateLabel,
    required this.amountLabel,
    required this.description,
    required this.isCurrentSide,
    this.onEdit,
    this.onDelete,
  });

  final String dateLabel;
  final String amountLabel;
  final String description;
  final bool isCurrentSide;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
}

class ExpenseSplitLedgerTable extends StatelessWidget {
  const ExpenseSplitLedgerTable({
    super.key,
    required this.rows,
    required this.currentColumnLabel,
    required this.counterpartColumnLabel,
    required this.emptyTitle,
    required this.emptyMessage,
    this.title = 'جدول المصروفات',
    this.subtitle,
    this.onAdd,
    this.trailing,
    this.addLabel =
        '\u0625\u0636\u0627\u0641\u0629 \u0645\u0635\u0631\u0648\u0641',
    this.currentTotalLabel,
    this.counterpartTotalLabel,
    this.totalsDateLabel = 'الإجمالي',
  });

  final List<ExpenseSplitLedgerRow> rows;
  final String currentColumnLabel;
  final String counterpartColumnLabel;
  final String emptyTitle;
  final String emptyMessage;
  final String title;
  final String? subtitle;
  final VoidCallback? onAdd;
  final Widget? trailing;
  final String addLabel;
  final String? currentTotalLabel;
  final String? counterpartTotalLabel;
  final String totalsDateLabel;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: title,
      subtitle:
          subtitle ??
          'ثلاثة أعمدة فقط: التاريخ، $currentColumnLabel، $counterpartColumnLabel.',
      trailing:
          trailing ??
          (onAdd == null
              ? null
              : FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: Text(addLabel),
                )),
      child: rows.isEmpty
          ? EmptyStateView(title: emptyTitle, message: emptyMessage)
          : LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth < 360
                    ? 360.0
                    : constraints.maxWidth;
                final innerTableWidth = tableWidth - 2;
                final dateColumnWidth = 78.0;
                final sideColumnWidth = (innerTableWidth - dateColumnWidth) / 2;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: tableWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFEFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD9DED6)),
                    ),
                    child: Column(
                      children: [
                        _ExpenseTableHeader(
                          dateColumnWidth: dateColumnWidth,
                          sideColumnWidth: sideColumnWidth,
                          currentColumnLabel: currentColumnLabel,
                          counterpartColumnLabel: counterpartColumnLabel,
                        ),
                        for (final row in rows)
                          _ExpenseLedgerTableRow(
                            row: row,
                            dateColumnWidth: dateColumnWidth,
                            sideColumnWidth: sideColumnWidth,
                          ),
                        if (_hasTotals)
                          _ExpenseTotalsTableRow(
                            dateLabel: totalsDateLabel,
                            currentColumnLabel: currentColumnLabel,
                            counterpartColumnLabel: counterpartColumnLabel,
                            currentTotalLabel: currentTotalLabel!,
                            counterpartTotalLabel: counterpartTotalLabel!,
                            dateColumnWidth: dateColumnWidth,
                            sideColumnWidth: sideColumnWidth,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  bool get _hasTotals =>
      currentTotalLabel != null && counterpartTotalLabel != null;
}

class _ExpenseTableHeader extends StatelessWidget {
  const _ExpenseTableHeader({
    required this.dateColumnWidth,
    required this.sideColumnWidth,
    required this.currentColumnLabel,
    required this.counterpartColumnLabel,
  });

  final double dateColumnWidth;
  final double sideColumnWidth;
  final String currentColumnLabel;
  final String counterpartColumnLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE7EEE6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          _HeaderCell(width: dateColumnWidth, label: 'التاريخ'),
          _HeaderCell(width: sideColumnWidth, label: currentColumnLabel),
          _HeaderCell(width: sideColumnWidth, label: counterpartColumnLabel),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.width, required this.label});

  final double width;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFD9DED6))),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF21463D),
        ),
      ),
    );
  }
}

class _ExpenseLedgerTableRow extends StatelessWidget {
  const _ExpenseLedgerTableRow({
    required this.row,
    required this.dateColumnWidth,
    required this.sideColumnWidth,
  });

  final ExpenseSplitLedgerRow row;
  final double dateColumnWidth;
  final double sideColumnWidth;

  @override
  Widget build(BuildContext context) {
    final currentRow = row.isCurrentSide ? row : null;
    final counterpartRow = row.isCurrentSide ? null : row;

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFD9DED6))),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ExpenseDateCell(width: dateColumnWidth, dateLabel: row.dateLabel),
            _ExpenseSideCell(
              width: sideColumnWidth,
              entry: currentRow,
              tint: const Color(0xFFEAF4EF),
            ),
            _ExpenseSideCell(
              width: sideColumnWidth,
              entry: counterpartRow,
              tint: const Color(0xFFF6F4EF),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseDateCell extends StatelessWidget {
  const _ExpenseDateCell({required this.width, required this.dateLabel});

  final double width;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8F4),
        border: Border(left: BorderSide(color: Color(0xFFD9DED6))),
      ),
      alignment: Alignment.center,
      child: Text(
        dateLabel,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF17352F),
        ),
      ),
    );
  }
}

class _ExpenseSideCell extends StatelessWidget {
  const _ExpenseSideCell({
    required this.width,
    required this.entry,
    required this.tint,
  });

  final double width;
  final ExpenseSplitLedgerRow? entry;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFD9DED6))),
      ),
      child: entry == null
          ? Center(
              child: Text(
                'لا يوجد',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : _ExpenseEntryCard(entry: entry!, tint: tint),
    );
  }
}

class _ExpenseEntryCard extends StatelessWidget {
  const _ExpenseEntryCard({required this.entry, required this.tint});

  final ExpenseSplitLedgerRow entry;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD5DDD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.amountLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF17352F),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            entry.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF40564F),
              height: 1.25,
            ),
          ),
          if (entry.onEdit != null || entry.onDelete != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (entry.onEdit != null)
                  OutlinedButton.icon(
                    onPressed: entry.onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('\u062a\u0639\u062f\u064a\u0644'),
                  ),
                if (entry.onDelete != null)
                  OutlinedButton.icon(
                    onPressed: entry.onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('\u062d\u0630\u0641'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpenseTotalsTableRow extends StatelessWidget {
  const _ExpenseTotalsTableRow({
    required this.dateLabel,
    required this.currentColumnLabel,
    required this.counterpartColumnLabel,
    required this.currentTotalLabel,
    required this.counterpartTotalLabel,
    required this.dateColumnWidth,
    required this.sideColumnWidth,
  });

  final String dateLabel;
  final String currentColumnLabel;
  final String counterpartColumnLabel;
  final String currentTotalLabel;
  final String counterpartTotalLabel;
  final double dateColumnWidth;
  final double sideColumnWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFD9DED6))),
        color: Color(0xFFF1F5EE),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ExpenseDateCell(width: dateColumnWidth, dateLabel: dateLabel),
            _ExpenseTotalCell(
              width: sideColumnWidth,
              amountLabel: currentTotalLabel,
              description: currentColumnLabel,
              tint: const Color(0xFFE2F0E7),
            ),
            _ExpenseTotalCell(
              width: sideColumnWidth,
              amountLabel: counterpartTotalLabel,
              description: counterpartColumnLabel,
              tint: const Color(0xFFF0ECE2),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTotalCell extends StatelessWidget {
  const _ExpenseTotalCell({
    required this.width,
    required this.amountLabel,
    required this.description,
    required this.tint,
  });

  final double width;
  final String amountLabel;
  final String description;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFD9DED6))),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD5DDD5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              amountLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF17352F),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF40564F),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
