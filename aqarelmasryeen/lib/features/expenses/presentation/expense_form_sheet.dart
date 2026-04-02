import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpenseFormSheet extends ConsumerStatefulWidget {
  const ExpenseFormSheet({
    super.key,
    required this.propertyId,
    required this.partners,
    this.expense,
  });

  final String propertyId;
  final List<Partner> partners;
  final ExpenseRecord? expense;

  @override
  ConsumerState<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  late final TextEditingController _attachmentController;
  late ExpenseCategory _category;
  late PaymentMethod _paymentMethod;
  late String _partnerId;
  late DateTime _selectedDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _amountController = TextEditingController(
      text: expense == null ? '' : expense.amount.toStringAsFixed(0),
    );
    _descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );
    _notesController = TextEditingController(text: expense?.notes ?? '');
    _attachmentController = TextEditingController(
      text: expense?.attachmentUrl ?? '',
    );
    _category = expense?.category ?? ExpenseCategory.construction;
    _paymentMethod = expense?.paymentMethod ?? PaymentMethod.bankTransfer;
    _partnerId =
        expense?.paidByPartnerId ??
        (widget.partners.isEmpty ? '' : widget.partners.first.id);
    _selectedDate = expense?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    final expense = ExpenseRecord(
      id: widget.expense?.id ?? '',
      propertyId: widget.propertyId,
      amount: double.tryParse(_amountController.text.trim()) ?? 0,
      category: _category,
      description: _descriptionController.text.trim(),
      paidByPartnerId: _partnerId,
      paymentMethod: _paymentMethod,
      date: _selectedDate,
      attachmentUrl: _attachmentController.text.trim().isEmpty
          ? null
          : _attachmentController.text.trim(),
      notes: _notesController.text.trim(),
      createdBy: widget.expense?.createdBy ?? session.firebaseUser.uid,
      updatedBy: session.firebaseUser.uid,
      createdAt: widget.expense?.createdAt ?? now,
      updatedAt: now,
      archived: false,
    );

    await ref.read(expenseRepositoryProvider).save(expense);
    await ref
        .read(activityRepositoryProvider)
        .log(
          actorId: session.firebaseUser.uid,
          actorName: session.profile?.name ?? 'Partner',
          action: widget.expense == null
              ? 'expense_created'
              : 'expense_updated',
          entityType: 'expense',
          entityId: expense.id.isEmpty ? expense.description : expense.id,
          metadata: {
            'propertyId': widget.propertyId,
            'amount': expense.amount,
            'category': expense.category.name,
          },
        );
    await ref
        .read(notificationRepositoryProvider)
        .create(
          userId: session.firebaseUser.uid,
          title: widget.expense == null
              ? 'New expense added'
              : 'Expense updated',
          body:
              '${expense.description} • EGP ${expense.amount.toStringAsFixed(0)}',
          type: NotificationType.expenseAdded,
          route: '/properties/${widget.propertyId}',
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: widget.expense == null ? 'Add expense' : 'Edit expense',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter a description.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount'),
              validator: (value) {
                if ((double.tryParse((value ?? '').trim()) ?? 0) <= 0) {
                  return 'Enter a valid amount.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseCategory>(
              value: _category,
              items: ExpenseCategory.values
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text(item.label)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _category = value ?? _category),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _partnerId.isEmpty ? null : _partnerId,
              items: widget.partners
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _partnerId = value ?? ''),
              decoration: const InputDecoration(labelText: 'Paid by partner'),
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Select the paying partner.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMethod>(
              value: _paymentMethod,
              items: PaymentMethod.values
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text(item.label)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _paymentMethod = value ?? _paymentMethod),
              decoration: const InputDecoration(labelText: 'Payment method'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(20),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Expense date'),
                child: Row(
                  children: [
                    Expanded(child: Text(_selectedDate.formatShort())),
                    const Icon(Icons.calendar_today_outlined, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _attachmentController,
              decoration: const InputDecoration(
                labelText: 'Attachment URL',
                hintText: 'Optional Firebase Storage or signed URL',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Saving...' : 'Save expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
