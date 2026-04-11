import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/core/utils/grouped_number_input_formatter.dart';
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
  late final TextEditingController _apartmentPriceController;
  late final TextEditingController _downPaymentController;
  late final TextEditingController _installmentScheduleCountController;
  late final TextEditingController _notesController;
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
      text: unit == null ? '' : '${unit.floor}',
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
    _apartmentPriceController = TextEditingController(
      text: unit == null
          ? ''
          : GroupedNumberInputFormatter.formatNumber(unit.apartmentPrice),
    );
    _downPaymentController = TextEditingController(
      text: unit == null
          ? ''
          : GroupedNumberInputFormatter.formatNumber(unit.downPayment),
    );
    _installmentScheduleCountController = TextEditingController(
      text: unit == null ? '' : '${unit.installmentScheduleCount}',
    );
    _notesController = TextEditingController(text: unit?.notes ?? '');
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
    _apartmentPriceController.dispose();
    _downPaymentController.dispose();
    _installmentScheduleCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }
    final workspaceId = ref.read(currentWorkspaceIdProvider);
    if (workspaceId.isEmpty) {
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final apartmentPrice = parseGroupedDouble(_apartmentPriceController.text);
    final downPayment = parseGroupedDouble(_downPaymentController.text);

    final unit = UnitSale(
      id: widget.unit?.id ?? '',
      propertyId: widget.propertyId,
      unitNumber: _unitController.text.trim(),
      floor: int.tryParse(_floorController.text.trim()) ?? 0,
      unitType: _unitType,
      area: double.tryParse(_areaController.text.trim()) ?? 0,
      customerName: _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim(),
      apartmentPrice: apartmentPrice,
      downPayment: downPayment,
      remainingAmount: (apartmentPrice - downPayment)
          .clamp(0, apartmentPrice)
          .toDouble(),
      installmentScheduleCount:
          int.tryParse(_installmentScheduleCountController.text.trim()) ?? 0,
      paymentPlanType: _paymentPlanType,
      status: _status,
      notes: _notesController.text.trim(),
      projectedCompletionDate: widget.unit?.projectedCompletionDate,
      createdAt: widget.unit?.createdAt ?? now,
      updatedAt: now,
      createdBy: widget.unit?.createdBy ?? session.userId,
      updatedBy: session.userId,
      workspaceId: widget.unit?.workspaceId ?? workspaceId,
    );

    final unitId = await ref.read(salesRepositoryProvider).save(unit);
    final savedUnit = unit.copyWith(id: unitId);
    await ref
        .read(activityRepositoryProvider)
        .log(
          actorId: session.userId,
          actorName: session.profile?.name ?? 'شريك',
          action: widget.unit == null ? 'unit_created' : 'unit_updated',
          entityType: 'unit',
          entityId: unitId,
          metadata: {
            'propertyId': widget.propertyId,
            'apartmentPrice': savedUnit.apartmentPrice,
            'status': savedUnit.status.name,
          },
          workspaceId: workspaceId,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: widget.unit == null ? 'إضافة مبيعات وحدة' : 'تعديل مبيعات الوحدة',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(labelText: 'رقم الوحدة'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'أدخل رقم الوحدة.' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _floorController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'الدور'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'المساحة بالمتر',
                    ),
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
              decoration: const InputDecoration(labelText: 'نوع الوحدة'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerNameController,
              decoration: const InputDecoration(labelText: 'اسم العميل'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم هاتف العميل'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _apartmentPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [GroupedNumberInputFormatter()],
              decoration: const InputDecoration(labelText: 'سعر الشقة'),
              validator: (value) {
                if ((GroupedNumberInputFormatter.tryParse(value ?? '') ?? 0) <=
                    0) {
                  return 'أدخل سعر الشقة.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _downPaymentController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [GroupedNumberInputFormatter()],
                    decoration: const InputDecoration(labelText: 'المقدم'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _installmentScheduleCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد الأقساط المخطط',
                      helperText: 'تسجيل التواريخ يتم يدويًا من شيت الأقساط.',
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
              decoration: const InputDecoration(labelText: 'نظام السداد'),
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
              decoration: const InputDecoration(labelText: 'الحالة'),
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
                child: Text(_saving ? 'جاري الحفظ...' : 'حفظ بيانات الوحدة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
