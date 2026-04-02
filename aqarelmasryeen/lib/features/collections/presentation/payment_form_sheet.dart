import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/collections/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentFormSheet extends ConsumerStatefulWidget {
  const PaymentFormSheet({
    super.key,
    required this.propertyId,
    required this.units,
    required this.installments,
  });

  final String propertyId;
  final List<UnitSale> units;
  final List<Installment> installments;

  @override
  ConsumerState<PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends ConsumerState<PaymentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late String _unitId;
  String? _installmentId;
  PaymentMethod _paymentMethod = PaymentMethod.bankTransfer;
  DateTime _receivedAt = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
    _unitId = widget.units.isEmpty ? '' : widget.units.first.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<Installment> get _matchingInstallments {
    return widget.installments.where((item) => item.unitId == _unitId).toList();
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
    final now = DateTime.now();
    final payment = PaymentRecord(
      id: '',
      propertyId: widget.propertyId,
      unitId: _unitId,
      installmentId: _installmentId,
      amount: double.tryParse(_amountController.text.trim()) ?? 0,
      receivedAt: _receivedAt,
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim(),
      createdAt: now,
      updatedAt: now,
      createdBy: session.firebaseUser.uid,
      updatedBy: session.firebaseUser.uid,
    );

    await ref.read(paymentRepositoryProvider).record(payment);
    await ref
        .read(activityRepositoryProvider)
        .log(
          actorId: session.firebaseUser.uid,
          actorName: session.profile?.name ?? 'Partner',
          action: 'payment_recorded',
          entityType: 'payment',
          entityId: payment.unitId,
          metadata: {
            'propertyId': widget.propertyId,
            'amount': payment.amount,
            'installmentId': payment.installmentId,
          },
        );
    await ref
        .read(notificationRepositoryProvider)
        .create(
          userId: session.firebaseUser.uid,
          title: 'Payment received',
          body: 'EGP ${payment.amount.toStringAsFixed(0)} was recorded',
          type: NotificationType.paymentReceived,
          route: '/properties/${widget.propertyId}',
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: 'Record collection',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _unitId.isEmpty ? null : _unitId,
              items: widget.units
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.unitNumber),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _unitId = value ?? '';
                  _installmentId = null;
                });
              },
              decoration: const InputDecoration(labelText: 'Unit'),
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Select a unit.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _installmentId,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('General collection'),
                ),
                ..._matchingInstallments.map(
                  (item) => DropdownMenuItem<String?>(
                    value: item.id,
                    child: Text('Installment ${item.sequence}'),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _installmentId = value),
              decoration: const InputDecoration(
                labelText: 'Apply to installment',
              ),
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
              borderRadius: BorderRadius.circular(20),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Received date'),
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
