import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/summary_card.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';

class PropertyRecordsOverviewPanel extends StatelessWidget {
  const PropertyRecordsOverviewPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.addLabel,
    required this.onAdd,
    required this.primaryLabel,
    required this.primaryCount,
    required this.primaryTotal,
    required this.onOpenPrimary,
    required this.secondaryLabel,
    required this.secondaryCount,
    required this.secondaryTotal,
    required this.onOpenSecondary,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String addLabel;
  final VoidCallback onAdd;
  final String primaryLabel;
  final int primaryCount;
  final double primaryTotal;
  final VoidCallback onOpenPrimary;
  final String secondaryLabel;
  final int secondaryCount;
  final double secondaryTotal;
  final VoidCallback onOpenSecondary;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: title,
      subtitle: subtitle,
      trailing: FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: Text(addLabel),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 620;
          final cards = [
            _RecordBucketCard(
              label: primaryLabel,
              count: primaryCount,
              total: primaryTotal,
              icon: icon,
              emphasis: true,
              actionLabel: 'عرض الجدول',
              onPressed: onOpenPrimary,
            ),
            _RecordBucketCard(
              label: secondaryLabel,
              count: secondaryCount,
              total: secondaryTotal,
              icon: icon,
              actionLabel: 'عرض الجدول',
              onPressed: onOpenSecondary,
            ),
          ];

          if (isCompact) {
            return Column(
              children: [
                for (var index = 0; index < cards.length; index++) ...[
                  cards[index],
                  if (index != cards.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          );
        },
      ),
    );
  }
}

class PropertyExpensesTable extends StatelessWidget {
  const PropertyExpensesTable({
    super.key,
    required this.expenses,
    required this.partnerNames,
    required this.totalAmount,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.title = 'Expenses',
    this.subtitle,
    this.addLabel = 'Add expense',
    this.emptyLabel = 'No expenses yet',
    this.emptyActionLabel = 'Create expense',
  });

  final List<ExpenseRecord> expenses;
  final Map<String, String> partnerNames;
  final double totalAmount;
  final VoidCallback onAdd;
  final ValueChanged<ExpenseRecord> onEdit;
  final ValueChanged<ExpenseRecord> onDelete;
  final String title;
  final String? subtitle;
  final String addLabel;
  final String emptyLabel;
  final String emptyActionLabel;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: title,
      subtitle:
          subtitle ?? '${expenses.length} record(s) - Total ${totalAmount.egp}',
      trailing: FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: Text(addLabel),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (expenses.isEmpty) {
            return _EmptyTableState(
              label: emptyLabel,
              actionLabel: emptyActionLabel,
              onAction: onAdd,
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                border: TableBorder.all(color: const Color(0xFFD8D8D2)),
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF0F0EA),
                ),
                headingRowHeight: 48,
                dataRowMinHeight: 64,
                dataRowMaxHeight: 74,
                columnSpacing: 18,
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Title')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Paid by')),
                  DataColumn(label: Text('Notes')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: [
                  for (final expense in expenses)
                    DataRow(
                      cells: [
                        DataCell(Text(expense.date.formatShort())),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  expense.category.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(Text(expense.amount.egp)),
                        DataCell(
                          Text(partnerNames[expense.paidByPartnerId] ?? '-'),
                        ),
                        DataCell(
                          SizedBox(
                            width: 180,
                            child: Text(
                              expense.notes.isEmpty ? '-' : expense.notes,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => onEdit(expense),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                onPressed: () => onDelete(expense),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      ],
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

class PropertyPaymentsTable extends StatelessWidget {
  const PropertyPaymentsTable({
    super.key,
    required this.payments,
    required this.totalAmount,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.title = 'Sales',
    this.subtitle,
    this.addLabel = 'Add sale',
    this.emptyLabel = 'No sales yet',
    this.emptyActionLabel = 'Create sale',
  });

  final List<PaymentRecord> payments;
  final double totalAmount;
  final VoidCallback onAdd;
  final ValueChanged<PaymentRecord> onEdit;
  final ValueChanged<PaymentRecord> onDelete;
  final String title;
  final String? subtitle;
  final String addLabel;
  final String emptyLabel;
  final String emptyActionLabel;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: title,
      subtitle:
          subtitle ?? '${payments.length} record(s) - Total ${totalAmount.egp}',
      trailing: FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: Text(addLabel),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (payments.isEmpty) {
            return _EmptyTableState(
              label: emptyLabel,
              actionLabel: emptyActionLabel,
              onAction: onAdd,
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                border: TableBorder.all(color: const Color(0xFFD8D8D2)),
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF0F0EA),
                ),
                headingRowHeight: 48,
                dataRowMinHeight: 64,
                dataRowMaxHeight: 74,
                columnSpacing: 18,
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Customer / Unit')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Method')),
                  DataColumn(label: Text('Notes')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: [
                  for (final payment in payments)
                    DataRow(
                      cells: [
                        DataCell(Text(payment.receivedAt.formatShort())),
                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Text(
                              payment.customerName.trim().isNotEmpty
                                  ? '${payment.customerName} - ${payment.unitId.isEmpty ? 'No unit' : payment.unitId}'
                                  : (payment.unitId.isEmpty
                                        ? 'Direct payment'
                                        : payment.unitId),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text(payment.amount.egp)),
                        DataCell(Text(payment.paymentMethod.label)),
                        DataCell(
                          SizedBox(
                            width: 180,
                            child: Text(
                              payment.notes.isEmpty ? '-' : payment.notes,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => onEdit(payment),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                onPressed: () => onDelete(payment),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      ],
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

class _RecordBucketCard extends StatelessWidget {
  const _RecordBucketCard({
    required this.label,
    required this.count,
    required this.total,
    required this.icon,
    required this.actionLabel,
    required this.onPressed,
    this.emphasis = false,
  });

  final String label;
  final int count;
  final double total;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onPressed;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: emphasis
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFFD8D8D2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onPressed,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SummaryCard(
              label: label,
              value: total.egp,
              subtitle: '$count سجل',
              icon: icon,
              emphasis: emphasis,
              splitLayout: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.table_chart_outlined),
                label: Text(actionLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTableState extends StatelessWidget {
  const _EmptyTableState({
    required this.label,
    required this.actionLabel,
    required this.onAction,
  });

  final String label;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(label),
          const SizedBox(height: 12),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
