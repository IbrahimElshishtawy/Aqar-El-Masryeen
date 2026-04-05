import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentFormSheet extends ConsumerStatefulWidget {
  const PaymentFormSheet({super.key, required this.propertyId, this.payment});

  final String propertyId;
  final PaymentRecord? payment;

  @override
  ConsumerState<PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends ConsumerState<PaymentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _customerController;
  late final TextEditingController _unitController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late PaymentMethod _paymentMethod;
  late DateTime _receivedAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final payment = widget.payment;
    _customerController = TextEditingController(
      text: payment?.customerName ?? '',
    );
    _unitController = TextEditingController(text: payment?.unitId ?? '');
    _amountController = TextEditingController(
      text: payment == null ? '' : payment.amount.toStringAsFixed(0),
    );
    _notesController = TextEditingController(text: payment?.notes ?? '');
    _paymentMethod = payment?.paymentMethod ?? PaymentMethod.bankTransfer;
    _receivedAt = payment?.receivedAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _customerController.dispose();
    _unitController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _receivedAt = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    setState(() => _saving = true);
    final savedId = await ref
        .read(paymentRepositoryProvider)
        .save(
          PaymentRecord(
            id: widget.payment?.id ?? '',
            propertyId: widget.propertyId,
            unitId: _unitController.text.trim(),
            customerName: _customerController.text.trim(),
            installmentId: widget.payment?.installmentId,
            amount: double.parse(_amountController.text.trim()),
            receivedAt: _receivedAt,
            paymentMethod: _paymentMethod,
            notes: _notesController.text.trim(),
            createdAt:
                widget.payment?.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0),
            updatedAt: DateTime.now(),
            createdBy: widget.payment?.createdBy ?? session.userId,
            updatedBy: session.userId,
          ),
        );

    await ref
        .read(activityRepositoryProvider)
        .log(
          actorId: session.userId,
          actorName: session.profile?.name ?? 'Partner',
          action: widget.payment == null
              ? 'payment_created'
              : 'payment_updated',
          entityType: 'payment',
          entityId: savedId,
          metadata: {'propertyId': widget.propertyId},
        );
    await ref
        .read(notificationRepositoryProvider)
        .create(
          userId: session.userId,
          title: widget.payment == null ? 'Payment created' : 'Payment updated',
          body: _customerController.text.trim().isEmpty
              ? 'Incoming payment recorded'
              : _customerController.text.trim(),
          type: NotificationType.paymentReceived,
          route: '/properties/${widget.propertyId}',
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: widget.payment == null ? 'Add payment' : 'Edit payment',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _customerController,
              decoration: const InputDecoration(labelText: 'Customer name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(labelText: 'Unit'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount'),
              validator: (value) {
                final parsed = double.tryParse((value ?? '').trim());
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid amount.';
                }
                return null;
              },
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
              decoration: const InputDecoration(labelText: 'Payment method'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date'),
                child: Row(
                  children: [
                    Expanded(child: Text(_receivedAt.formatShort())),
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
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Saving...' : 'Save payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
