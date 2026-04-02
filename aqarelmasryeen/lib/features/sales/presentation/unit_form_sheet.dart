import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/sales/data/sales_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnitFormSheet extends ConsumerStatefulWidget {
  const UnitFormSheet({super.key, required this.propertyId, this.unit});

  final String propertyId;
  final UnitSale? unit;

  @override
  ConsumerState<UnitFormSheet> createState() => _UnitFormSheetState();
}

class _UnitFormSheetState extends ConsumerState<UnitFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _unitController;
  late final TextEditingController _floorController;
  late final TextEditingController _areaController;
  late final TextEditingController _customerNameController;
  late final TextEditingController _customerPhoneController;
  late final TextEditingController _totalPriceController;
  late final TextEditingController _downPaymentController;
  late UnitType _unitType;
  late UnitStatus _status;
  late PaymentPlanType _paymentPlanType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final unit = widget.unit;
    _unitController = TextEditingController(text: unit?.unitNumber ?? '');
    _floorController = TextEditingController(
      text: unit == null ? '' : unit.floor.toString(),
    );
    _areaController = TextEditingController(
      text: unit == null ? '' : unit.area.toStringAsFixed(0),
    );
    _customerNameController = TextEditingController(
      text: unit?.customerName ?? '',
    );
    _customerPhoneController = TextEditingController(
      text: unit?.customerPhone ?? '',
    );
    _totalPriceController = TextEditingController(
      text: unit == null ? '' : unit.totalPrice.toStringAsFixed(0),
    );
    _downPaymentController = TextEditingController(
      text: unit == null ? '' : unit.downPayment.toStringAsFixed(0),
    );
    _unitType = unit?.unitType ?? UnitType.apartment;
    _status = unit?.status ?? UnitStatus.available;
    _paymentPlanType = unit?.paymentPlanType ?? PaymentPlanType.installment;
  }

  @override
  void dispose() {
    _unitController.dispose();
    _floorController.dispose();
    _areaController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _totalPriceController.dispose();
    _downPaymentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    final totalPrice = double.tryParse(_totalPriceController.text.trim()) ?? 0;
    final downPayment =
        double.tryParse(_downPaymentController.text.trim()) ?? 0;
    final unit = UnitSale(
      id: widget.unit?.id ?? '',
      propertyId: widget.propertyId,
      unitNumber: _unitController.text.trim(),
      floor: int.tryParse(_floorController.text.trim()) ?? 0,
      unitType: _unitType,
      area: double.tryParse(_areaController.text.trim()) ?? 0,
      customerName: _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim(),
      totalPrice: totalPrice,
      downPayment: downPayment,
      remainingAmount: (totalPrice - downPayment)
          .clamp(0, totalPrice)
          .toDouble(),
      paymentPlanType: _paymentPlanType,
      status: _status,
      createdAt: widget.unit?.createdAt ?? now,
      updatedAt: now,
      createdBy: widget.unit?.createdBy ?? session.firebaseUser.uid,
      updatedBy: session.firebaseUser.uid,
    );

    await ref.read(salesRepositoryProvider).save(unit);
    await ref
        .read(activityRepositoryProvider)
        .log(
          actorId: session.firebaseUser.uid,
          actorName: session.profile?.name ?? 'Partner',
          action: widget.unit == null ? 'unit_created' : 'unit_updated',
          entityType: 'unit',
          entityId: unit.id.isEmpty ? unit.unitNumber : unit.id,
          metadata: {
            'propertyId': widget.propertyId,
            'totalPrice': unit.totalPrice,
            'status': unit.status.name,
          },
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: widget.unit == null ? 'Add unit or sale' : 'Edit unit or sale',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: 'Unit name or number',
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter the unit name.' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _floorController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Floor'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Area m2'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<UnitType>(
              initialValue: _unitType,
              items: UnitType.values
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text(item.label)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _unitType = value ?? _unitType),
              decoration: const InputDecoration(labelText: 'Unit type'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerNameController,
              decoration: const InputDecoration(labelText: 'Customer name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Customer phone'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _totalPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Total price'),
                    validator: (value) {
                      if ((double.tryParse((value ?? '').trim()) ?? 0) <= 0) {
                        return 'Enter a price.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _downPaymentController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Down payment',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentPlanType>(
              initialValue: _paymentPlanType,
              items: PaymentPlanType.values
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text(item.label)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _paymentPlanType = value ?? _paymentPlanType),
              decoration: const InputDecoration(labelText: 'Payment plan'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<UnitStatus>(
              initialValue: _status,
              items: UnitStatus.values
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text(item.label)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _status = value ?? _status),
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Saving...' : 'Save unit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
