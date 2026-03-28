import 'package:aqarelmasryeen/core/theme/app_colors.dart';
import 'package:aqarelmasryeen/core/theme/app_spacing.dart';
import 'package:aqarelmasryeen/data/models/workspace_models.dart';
import 'package:aqarelmasryeen/data/repositories/workspace_repository.dart';
import 'package:aqarelmasryeen/modules/dashboard/widgets/workspace_ui.dart';
import 'package:aqarelmasryeen/shared/widgets/app_button.dart';
import 'package:aqarelmasryeen/shared/widgets/app_card.dart';
import 'package:aqarelmasryeen/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalesSection extends StatelessWidget {
  const SalesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = Get.find<WorkspaceRepository>();

    return SectionScaffold(
      title: 'sales'.tr,
      subtitle: 'sales_subtitle'.tr,
      action: workspace.canManageFinance
          ? SizedBox(
              width: 160,
              child: AppButton(
                label: 'add_contract'.tr,
                onPressed: () => _showContractDialog(context),
              ),
            )
          : null,
      child: Column(
        children: workspace.salesContracts
            .map(
              (contract) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ContractCard(contract: contract),
              ),
            )
            .toList(),
      ),
    );
  }
}

class ExpensesSection extends StatelessWidget {
  const ExpensesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = Get.find<WorkspaceRepository>();

    return SectionScaffold(
      title: 'expenses'.tr,
      subtitle: 'expenses_subtitle'.tr,
      action: workspace.canManageFinance
          ? SizedBox(
              width: 160,
              child: AppButton(
                label: 'add_expense'.tr,
                onPressed: () => _showExpenseDialog(context),
              ),
            )
          : null,
      child: Column(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 280,
                child: SummaryStatCard(
                  title: 'total_expenses'.tr,
                  value: formatCurrency(workspace.totalExpensesValue),
                  caption: '${workspace.expenses.length} ${'expense_records'.tr}',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.warning,
                ),
              ),
              SizedBox(
                width: 280,
                child: SummaryStatCard(
                  title: 'group_by_user'.tr,
                  value: workspace.expenseTotalsByUser.isEmpty
                      ? '-'
                      : workspace.expenseTotalsByUser.first.key,
                  caption: workspace.expenseTotalsByUser.isEmpty
                      ? '0'
                      : formatCurrency(workspace.expenseTotalsByUser.first.total),
                  icon: Icons.groups_rounded,
                ),
              ),
              SizedBox(
                width: 280,
                child: SummaryStatCard(
                  title: 'group_by_category'.tr,
                  value: workspace.expenseTotalsByCategory.isEmpty
                      ? '-'
                      : workspace.expenseTotalsByCategory.first.key.tr,
                  caption: workspace.expenseTotalsByCategory.isEmpty
                      ? '0'
                      : formatCurrency(workspace.expenseTotalsByCategory.first.total),
                  icon: Icons.pie_chart_outline_rounded,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (context.isDesktop)
            AppCard(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('property'.tr)),
                    DataColumn(label: Text('title'.tr)),
                    DataColumn(label: Text('category'.tr)),
                    DataColumn(label: Text('paid_by'.tr)),
                    DataColumn(label: Text('date'.tr)),
                    DataColumn(label: Text('amount'.tr)),
                  ],
                  rows: workspace.expenses
                      .map(
                        (expense) => DataRow(
                          cells: [
                            DataCell(Text(workspace.propertyNameById(expense.propertyId))),
                            DataCell(Text(expense.title)),
                            DataCell(Text(expense.category.labelKey.tr)),
                            DataCell(Text(workspace.userNameById(expense.paidByUserId))),
                            DataCell(Text(formatDate(expense.date))),
                            DataCell(Text(formatCurrency(expense.amount))),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: workspace.expenses
                  .map(
                    (expense) => SizedBox(
                      width: double.infinity,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(workspace.propertyNameById(expense.propertyId)),
                            const SizedBox(height: 6),
                            Text(
                              '${expense.category.labelKey.tr} • ${formatCurrency(expense.amount)}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.contract});

  final SalesContractRecord contract;

  @override
  Widget build(BuildContext context) {
    final workspace = Get.find<WorkspaceRepository>();
    final unit = workspace.unitById(contract.unitId);
    final installments = workspace.installmentsForContract(contract.id);

    return AppCard(
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
                      workspace.customerNameById(contract.customerId),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${workspace.propertyNameById(contract.propertyId)} • ${unit?.unitNumber ?? '-'}',
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(formatCurrency(contract.netPrice)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _InlineMetric(label: 'down_payment'.tr, value: formatCurrency(contract.downPayment)),
              _InlineMetric(label: 'discount'.tr, value: formatCurrency(contract.discount)),
              _InlineMetric(label: 'installments'.tr, value: '${contract.installmentCount}'),
              _InlineMetric(
                label: 'remaining_receivables'.tr,
                value: formatCurrency(
                  (contract.netPrice -
                          contract.downPayment -
                          workspace.paymentsForContract(contract.id).fold<double>(
                            0,
                            (sum, payment) => sum + payment.amount,
                          ))
                      .clamp(0, double.infinity),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'installments'.tr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...installments.map(
            (installment) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'installment'.tr} ${installment.installmentNumber}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatDate(installment.dueDate)} • ${installment.status.labelKey.tr}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatCurrency(installment.paidAmount)} / ${formatCurrency(installment.amount)}',
                        ),
                      ],
                    ),
                  ),
                  if (workspace.canManageFinance &&
                      installment.remainingAmount > 0)
                    SizedBox(
                      width: 132,
                      child: AppButton(
                        label: 'add_payment'.tr,
                        onPressed: () => _showPaymentDialog(context, installment),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showContractDialog(BuildContext context) async {
  final workspace = Get.find<WorkspaceRepository>();
  var propertyId = workspace.properties.first.id;
  final availableUnits = () => workspace.units
      .where(
        (unit) =>
            unit.propertyId == propertyId &&
            (unit.status == UnitStatus.available || unit.status == UnitStatus.reserved),
      )
      .toList();
  var unitId = availableUnits().isEmpty ? '' : availableUnits().first.id;
  final customerNameController = TextEditingController();
  final customerPhoneController = TextEditingController();
  final customerEmailController = TextEditingController();
  final totalPriceController = TextEditingController();
  final discountController = TextEditingController(text: '0');
  final downPaymentController = TextEditingController(text: '0');
  final installmentCountController = TextEditingController(text: '6');
  final frequencyController = TextEditingController(text: '1');
  final notesController = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('add_contract'.tr),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 560,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: propertyId,
                    items: workspace.properties
                        .map(
                          (property) => DropdownMenuItem(
                            value: property.id,
                            child: Text(property.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        propertyId = value!;
                        unitId = availableUnits().isEmpty ? '' : availableUnits().first.id;
                      });
                    },
                    decoration: InputDecoration(labelText: 'property'.tr),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: unitId.isEmpty ? null : unitId,
                    items: availableUnits()
                        .map(
                          (unit) => DropdownMenuItem(
                            value: unit.id,
                            child: Text('${unit.unitNumber} - ${formatCurrency(unit.price)}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => unitId = value ?? ''),
                    decoration: InputDecoration(labelText: 'unit_number'.tr),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(controller: customerNameController, label: 'customer_name'.tr),
                  const SizedBox(height: 12),
                  AppTextField(controller: customerPhoneController, label: 'phone_number'.tr),
                  const SizedBox(height: 12),
                  AppTextField(controller: customerEmailController, label: 'email_optional'.tr),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: totalPriceController,
                    label: 'total_price'.tr,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: discountController,
                    label: 'discount'.tr,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: downPaymentController,
                    label: 'down_payment'.tr,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: installmentCountController,
                    label: 'installment_count'.tr,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: frequencyController,
                    label: 'frequency_months'.tr,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: notesController,
                    label: 'notes'.tr,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('cancel'.tr),
            ),
            FilledButton(
              onPressed: unitId.isEmpty
                  ? null
                  : () async {
                      final customerId = await workspace.addOrUpdateCustomer(
                        CustomerRecord(
                          id: '',
                          fullName: customerNameController.text.trim(),
                          phone: customerPhoneController.text.trim(),
                          email: customerEmailController.text.trim().isEmpty
                              ? null
                              : customerEmailController.text.trim(),
                          notes: null,
                          createdAt: DateTime.now(),
                        ),
                      );
                      await workspace.addOrUpdateContract(
                        SalesContractRecord(
                          id: 'contract_${DateTime.now().microsecondsSinceEpoch}',
                          propertyId: propertyId,
                          unitId: unitId,
                          customerId: customerId,
                          totalPrice: double.tryParse(totalPriceController.text.trim()) ?? 0,
                          discount: double.tryParse(discountController.text.trim()) ?? 0,
                          downPayment:
                              double.tryParse(downPaymentController.text.trim()) ?? 0,
                          installmentCount:
                              int.tryParse(installmentCountController.text.trim()) ?? 0,
                          installmentFrequencyMonths:
                              int.tryParse(frequencyController.text.trim()) ?? 1,
                          startDate: DateTime.now(),
                          notes: notesController.text.trim(),
                          attachments: const [],
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );
                      Navigator.of(dialogContext).pop();
                    },
              child: Text('save'.tr),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _showPaymentDialog(
  BuildContext context,
  InstallmentRecord installment,
) async {
  final workspace = Get.find<WorkspaceRepository>();
  final amountController = TextEditingController(
    text: installment.remainingAmount.toStringAsFixed(0),
  );

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('add_payment'.tr),
      content: SizedBox(
        width: 420,
        child: AppTextField(
          controller: amountController,
          label: 'payment_amount'.tr,
          keyboardType: TextInputType.number,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text('cancel'.tr),
        ),
        FilledButton(
          onPressed: () async {
            await workspace.recordPayment(
              installmentId: installment.id,
              amount: double.tryParse(amountController.text.trim()) ?? 0,
              createdByUserId: workspace.users.first.id,
            );
            Navigator.of(dialogContext).pop();
          },
          child: Text('save'.tr),
        ),
      ],
    ),
  );
}

Future<void> _showExpenseDialog(BuildContext context) async {
  final workspace = Get.find<WorkspaceRepository>();
  var propertyId = workspace.properties.first.id;
  var userId = workspace.users.first.id;
  var category = ExpenseCategory.other;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final notesController = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('add_expense'.tr),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: propertyId,
                    items: workspace.properties
                        .map(
                          (property) => DropdownMenuItem(
                            value: property.id,
                            child: Text(property.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => propertyId = value!),
                    decoration: InputDecoration(labelText: 'property'.tr),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: userId,
                    items: workspace.users
                        .map(
                          (user) => DropdownMenuItem(
                            value: user.id,
                            child: Text(user.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => userId = value!),
                    decoration: InputDecoration(labelText: 'paid_by'.tr),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ExpenseCategory>(
                    value: category,
                    items: ExpenseCategory.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.labelKey.tr),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => category = value!),
                    decoration: InputDecoration(labelText: 'category'.tr),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(controller: titleController, label: 'title'.tr),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: descriptionController,
                    label: 'description'.tr,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: amountController,
                    label: 'amount'.tr,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: notesController,
                    label: 'notes'.tr,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('cancel'.tr),
            ),
            FilledButton(
              onPressed: () async {
                await workspace.addOrUpdateExpense(
                  ExpenseRecord(
                    id: 'expense_${DateTime.now().microsecondsSinceEpoch}',
                    propertyId: propertyId,
                    paidByUserId: userId,
                    category: category,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    amount: double.tryParse(amountController.text.trim()) ?? 0,
                    date: DateTime.now(),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    notes: notesController.text.trim(),
                  ),
                );
                Navigator.of(dialogContext).pop();
              },
              child: Text('save'.tr),
            ),
          ],
        ),
      );
    },
  );
}
