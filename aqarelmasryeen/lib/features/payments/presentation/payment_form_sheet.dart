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
  const PaymentFormSheet({
    super.key,
    required this.propertyId,
    this.payment,
    this.installmentId,
    this.initialUnitId,
  });

  final String propertyId;
  final PaymentRecord? payment;
  final String? installmentId;
  final String? initialUnitId;

  @override
  ConsumerState<PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends ConsumerState<PaymentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _payerController;
  late final TextEditingController _unitController;
  late final TextEditingController _amountController;
  late final TextEditingController _sourceController;
  late final TextEditingController _notesController;
  late PaymentMethod _paymentMethod;
  late DateTime _receivedAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final payment = widget.payment;
    _payerController = TextEditingController(
      text: payment?.effectivePayerName ?? '',
    );
    _unitController = TextEditingController(
      text: payment?.unitId ?? widget.initialUnitId ?? '',
    );
    _amountController = TextEditingController(
      text: payment == null ? '' : payment.amount.toStringAsFixed(0),
    );
    _sourceController = TextEditingController(text: payment?.paymentSource ?? '');
    _notesController = TextEditingController(text: payment?.notes ?? '');
    _paymentMethod = payment?.paymentMethod ?? PaymentMethod.bankTransfer;
    _receivedAt = payment?.receivedAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _payerController.dispose();
    _unitController.dispose();
    _amountController.dispose();
    _sourceController.dispose();
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
    final savedId = await ref.read(paymentRepositoryProvider).save(
      PaymentRecord(
        id: widget.payment?.id ?? '',
        propertyId: widget.propertyId,
        unitId: _unitController.text.trim(),
        payerName: _payerController.text.trim(),
        customerName: _payerController.text.trim(),
        installmentId: widget.payment?.installmentId ?? widget.installmentId,
        amount: double.parse(_amountController.text.trim()),
        receivedAt: _receivedAt,
        paymentMethod: _paymentMethod,
        paymentSource: _sourceController.text.trim(),
        notes: _notesController.text.trim(),
        createdAt:
            widget.payment?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.now(),
        createdBy: widget.payment?.createdBy ?? session.userId,
        updatedBy: session.userId,
      ),
    );

    await ref.read(activityRepositoryProvider).log(
      actorId: session.userId,
      actorName: session.profile?.name ?? 'Partner',
      action: widget.payment == null ? 'payment_created' : 'payment_updated',
      entityType: 'payment',
      entityId: savedId,
      metadata: {
        'propertyId': widget.propertyId,
        'installmentId': widget.installmentId ?? widget.payment?.installmentId,
      },
    );
    await ref.read(notificationRepositoryProvider).create(
      userId: session.userId,
      title: widget.payment == null ? 'Payment received' : 'Payment updated',
      body: _payerController.text.trim().isEmpty
          ? 'Incoming payment recorded'
          : _payerController.text.trim(),
      type: NotificationType.paymentReceived,
      route: '/properties/${widget.propertyId}',
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: widget.payment == null ? 'Add Payment' : 'Edit Payment',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _payerController,
              decoration: const InputDecoration(labelText: 'Payer name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(labelText: 'Unit'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            TextFormField(
              controller: _sourceController,
              decoration: const InputDecoration(labelText: 'Payment source'),
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
                decoration: const InputDecoration(labelText: 'Received at'),
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
