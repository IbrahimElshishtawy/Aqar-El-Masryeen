import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/installments/data/installment_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InstallmentPlanFormSheet extends ConsumerStatefulWidget {
  const InstallmentPlanFormSheet({
    super.key,
    required this.propertyId,
    required this.units,
  });

  final String propertyId;
  final List<UnitSale> units;

  @override
  ConsumerState<InstallmentPlanFormSheet> createState() =>
      _InstallmentPlanFormSheetState();
}

class _InstallmentPlanFormSheetState
    extends ConsumerState<InstallmentPlanFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _countController;
  late final TextEditingController _intervalController;
  late final TextEditingController _amountController;
  late String _unitId;
  DateTime _startDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _countController = TextEditingController(text: '12');
    _intervalController = TextEditingController(text: '30');
    _amountController = TextEditingController();
    _unitId = widget.units.isEmpty ? '' : widget.units.first.id;
    _prefillAmount();
  }

  @override
  void dispose() {
    _countController.dispose();
    _intervalController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _prefillAmount() {
    if (_unitId.isEmpty || widget.units.isEmpty) return;
    final count = int.tryParse(_countController.text.trim()) ?? 1;
    final unit = widget.units.firstWhere(
      (item) => item.id == _unitId,
      orElse: () => widget.units.first,
    );
    final installmentAmount = count <= 0
        ? unit.remainingAmount
        : unit.remainingAmount / count;
    _amountController.text = installmentAmount.toStringAsFixed(0);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    final plan = InstallmentPlan(
      id: '',
      propertyId: widget.propertyId,
      unitId: _unitId,
      installmentCount: int.tryParse(_countController.text.trim()) ?? 0,
      startDate: _startDate,
      intervalDays: int.tryParse(_intervalController.text.trim()) ?? 30,
      installmentAmount: double.tryParse(_amountController.text.trim()) ?? 0,
      createdAt: now,
      updatedAt: now,
      createdBy: session.firebaseUser.uid,
      updatedBy: session.firebaseUser.uid,
    );

    await ref
        .read(installmentRepositoryProvider)
        .savePlan(plan, actorId: session.firebaseUser.uid);
    await ref
        .read(activityRepositoryProvider)
        .log(
          actorId: session.firebaseUser.uid,
          actorName: session.profile?.name ?? 'شريك',
          action: 'installment_plan_created',
          entityType: 'installment_plan',
          entityId: plan.unitId,
          metadata: {
            'propertyId': widget.propertyId,
            'count': plan.installmentCount,
            'amount': plan.installmentAmount,
          },
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: 'إنشاء خطة أقساط',
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
                      child: Text(
                        '${item.unitNumber} • ${item.customerName}'.trim(),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _unitId = value ?? '');
                _prefillAmount();
              },
              decoration: const InputDecoration(labelText: 'الوحدة'),
              validator: (value) =>
                  (value ?? '').isEmpty ? 'اختر الوحدة أولًا.' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _countController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد الأقساط',
                    ),
                    onChanged: (_) => _prefillAmount(),
                    validator: (value) {
                      if ((int.tryParse((value ?? '').trim()) ?? 0) <= 0) {
                        return 'مطلوب';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _intervalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'الفاصل بالأيام',
                    ),
                    validator: (value) {
                      if ((int.tryParse((value ?? '').trim()) ?? 0) <= 0) {
                        return 'مطلوب';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(20),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'تاريخ البداية'),
                child: Row(
                  children: [
                    Expanded(child: Text(_startDate.formatShort())),
                    const Icon(Icons.calendar_today_outlined, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'قيمة القسط',
              ),
              validator: (value) {
                if ((double.tryParse((value ?? '').trim()) ?? 0) <= 0) {
                  return 'أدخل قيمة القسط.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'جار الإنشاء...' : 'إنشاء الخطة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
