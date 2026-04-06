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
    final savedId = await ref
        .read(expenseRepositoryProvider)
        .save(
          ExpenseRecord(
            id: widget.expense?.id ?? '',
            propertyId: widget.propertyId,
            amount: double.parse(_amountController.text.trim()),
            category: _category,
            description: _descriptionController.text.trim(),
            paidByPartnerId: _partnerId,
            paymentMethod: _paymentMethod,
            date: _selectedDate,
            attachmentUrl: widget.expense?.attachmentUrl,
            notes: _notesController.text.trim(),
            createdBy: widget.expense?.createdBy ?? session.userId,
            updatedBy: session.userId,
            createdAt:
                widget.expense?.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0),
            updatedAt: DateTime.now(),
            archived: false,
          ),
        );

    await ref
        .read(activityRepositoryProvider)
        .log(
          actorId: session.userId,
          actorName: session.profile?.name ?? 'شريك',
          action: widget.expense == null
              ? 'expense_created'
              : 'expense_updated',
          entityType: 'expense',
          entityId: savedId,
          metadata: {'propertyId': widget.propertyId},
        );
    await ref
        .read(notificationRepositoryProvider)
        .create(
          userId: session.userId,
          title: widget.expense == null
              ? 'تمت إضافة مصروف'
              : 'تم تحديث المصروف',
          body: _descriptionController.text.trim(),
          type: NotificationType.expenseAdded,
          route: '/properties/${widget.propertyId}',
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: widget.expense == null ? 'إضافة مصروف' : 'تعديل مصروف',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'البيان / الوصف'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'أدخل البيان.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'المبلغ'),
              validator: (value) {
                final parsed = double.tryParse((value ?? '').trim());
                if (parsed == null || parsed <= 0) {
                  return 'أدخل مبلغًا صحيحًا.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _category,
              items: ExpenseCategory.values
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text(item.label)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _category = value ?? _category),
              decoration: const InputDecoration(labelText: 'الفئة'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _partnerId.isEmpty ? null : _partnerId,
              items: widget.partners
                  .map(
                    (partner) => DropdownMenuItem(
                      value: partner.id,
                      child: Text(partner.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _partnerId = value ?? ''),
              decoration: const InputDecoration(labelText: 'دُفع بواسطة'),
              validator: (value) =>
                  (value ?? '').isEmpty ? 'اختر الشريك الدافع.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _paymentMethod,
              items: PaymentMethod.values
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text(item.label)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _paymentMethod = value ?? _paymentMethod),
              decoration: const InputDecoration(labelText: 'طريقة الدفع'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'التاريخ'),
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
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'ملاحظات'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'جاري الحفظ...' : 'حفظ المصروف'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
