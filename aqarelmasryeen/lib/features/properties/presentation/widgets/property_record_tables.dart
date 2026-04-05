import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';

class PropertyExpensesTable extends StatelessWidget {
  const PropertyExpensesTable({
    super.key,
    required this.expenses,
    required this.partnerNames,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ExpenseRecord> expenses;
  final Map<String, String> partnerNames;
  final VoidCallback onAdd;
  final ValueChanged<ExpenseRecord> onEdit;
  final ValueChanged<ExpenseRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'Expenses',
      subtitle: 'Track every outgoing amount for this property',
      trailing: FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (expenses.isEmpty) {
            return _EmptyTableState(
              label: 'No expenses yet',
              actionLabel: 'Create expense',
              onAction: onAdd,
            );
          }

          if (constraints.maxWidth < 760) {
            return Column(
              children: [
                for (var index = 0; index < expenses.length; index++) ...[
                  _ExpenseCard(
                    expense: expenses[index],
                    paidBy:
                        partnerNames[expenses[index].paidByPartnerId] ?? '-',
                    onEdit: () => onEdit(expenses[index]),
                    onDelete: () => onDelete(expenses[index]),
                  ),
                  if (index != expenses.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF0F0EA)),
              dataRowMinHeight: 64,
              dataRowMaxHeight: 74,
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
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(expense.description),
                            Text(
                              expense.category.label,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(expense.amount.egp)),
                      DataCell(
                        Text(partnerNames[expense.paidByPartnerId] ?? '-'),
                      ),
                      DataCell(
                        SizedBox(
                          width: 160,
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
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<PaymentRecord> payments;
  final VoidCallback onAdd;
  final ValueChanged<PaymentRecord> onEdit;
  final ValueChanged<PaymentRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'Payments',
      subtitle: 'Track every incoming amount for this property',
      trailing: FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add payment'),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (payments.isEmpty) {
            return _EmptyTableState(
              label: 'No payments yet',
              actionLabel: 'Create payment',
              onAction: onAdd,
            );
          }

          if (constraints.maxWidth < 760) {
            return Column(
              children: [
                for (var index = 0; index < payments.length; index++) ...[
                  _PaymentCard(
                    payment: payments[index],
                    onEdit: () => onEdit(payments[index]),
                    onDelete: () => onDelete(payments[index]),
                  ),
                  if (index != payments.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF0F0EA)),
              dataRowMinHeight: 64,
              dataRowMaxHeight: 74,
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
                          width: 180,
                          child: Text(
                            payment.customerName.trim().isNotEmpty
                                ? '${payment.customerName} • ${payment.unitId.isEmpty ? 'No unit' : payment.unitId}'
                                : (payment.unitId.isEmpty
                                      ? 'Direct payment'
                                      : payment.unitId),
                          ),
                        ),
                      ),
                      DataCell(Text(payment.amount.egp)),
                      DataCell(Text(payment.paymentMethod.label)),
                      DataCell(
                        SizedBox(
                          width: 160,
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
          );
        },
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.paidBy,
    required this.onEdit,
    required this.onDelete,
  });

  final ExpenseRecord expense;
  final String paidBy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${expense.category.label} • ${expense.date.formatShort()}',
                    ),
                  ],
                ),
              ),
              Text(expense.amount.egp),
            ],
          ),
          const SizedBox(height: 12),
          Text('Paid by: $paidBy'),
          if (expense.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(expense.notes),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: onDelete, child: const Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.onEdit,
    required this.onDelete,
  });

  final PaymentRecord payment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = payment.customerName.trim().isNotEmpty
        ? payment.customerName
        : payment.unitId.isEmpty
        ? 'Direct payment'
        : payment.unitId;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${payment.unitId.isEmpty ? 'No unit' : payment.unitId} • ${payment.receivedAt.formatShort()}',
                    ),
                  ],
                ),
              ),
              Text(payment.amount.egp),
            ],
          ),
          const SizedBox(height: 12),
          Text('Method: ${payment.paymentMethod.label}'),
          if (payment.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(payment.notes),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: onDelete, child: const Text('Delete')),
            ],
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
