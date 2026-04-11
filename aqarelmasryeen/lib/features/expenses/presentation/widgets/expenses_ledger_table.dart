// ignore_for_file: unused_element

part of '../expenses_ledger_screen.dart';

class _ExpensesDailyTable extends StatelessWidget {
  const _ExpensesDailyTable({
    required this.rows,
    required this.currentColumnLabel,
    required this.counterpartColumnLabel,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final List<_ExpenseDisplayRow> rows;
  final String currentColumnLabel;
  final String counterpartColumnLabel;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'جدول المصروفات',
      subtitle:
          'ثلاثة أعمدة فقط: التاريخ، $currentColumnLabel، $counterpartColumnLabel.',
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
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
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

  final _ExpenseDisplayRow row;
  final double dateColumnWidth;
  final double sideColumnWidth;

  @override
  Widget build(BuildContext context) {
    final userRow = row.isCurrentUser ? row : null;
    final partnerRow = row.isCurrentUser ? null : row;

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFD9DED6))),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ExpenseDateCell(width: dateColumnWidth, date: row.expense.date),
            _ExpenseSideCell(
              width: sideColumnWidth,
              entry: userRow,
              tint: const Color(0xFFEAF4EF),
            ),
            _ExpenseSideCell(
              width: sideColumnWidth,
              entry: partnerRow,
              tint: const Color(0xFFF6F4EF),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseDateCell extends StatelessWidget {
  const _ExpenseDateCell({required this.width, required this.date});

  final double width;
  final DateTime date;

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
        date.formatShort(),
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
  final _ExpenseDisplayRow? entry;
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

  final _ExpenseDisplayRow entry;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final expense = entry.expense;
    final meaning = expense.description.trim().isEmpty
        ? expense.category.label
        : expense.description.trim();

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
            expense.amount.egp,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF17352F),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            meaning,
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
    );
  }
}
