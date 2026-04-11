import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/installments/data/installment_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
part 'widgets/installment_plan_form_fields.dart';
part 'widgets/installment_plan_form_models.dart';

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
  final List<_DraftInstallment> _draftInstallments = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _countController = TextEditingController(text: '12');
    _intervalController = TextEditingController(text: '30');
    _amountController = TextEditingController();
    _unitId = widget.units.isEmpty ? '' : widget.units.first.id;
    _prefillAmount();
    _seedDraftInstallments();
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

  void _seedDraftInstallments() {
    final count = int.tryParse(_countController.text.trim()) ?? 0;
    if (count <= 0 || _draftInstallments.isNotEmpty) return;
    final installmentAmount =
        double.tryParse(_amountController.text.trim()) ?? 0;
    for (var i = 0; i < count; i++) {
      _draftInstallments.add(
        _DraftInstallment(
          dueDate: _startDate.add(Duration(days: i * 30)),
          amount: installmentAmount,
        ),
      );
    }
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
    final workspaceId = session.profile?.workspaceId.trim() ?? '';
    if (workspaceId.isEmpty) return;
    if (_draftInstallments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف قسطًا واحدًا على الأقل.')),
      );
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final planId = 'manual_${_unitId}_${now.microsecondsSinceEpoch}';
    final plan = InstallmentPlan(
      id: planId,
      propertyId: widget.propertyId,
      unitId: _unitId,
      installmentCount: int.tryParse(_countController.text.trim()) ?? 0,
      startDate: _startDate,
      intervalDays: int.tryParse(_intervalController.text.trim()) ?? 30,
      installmentAmount: double.tryParse(_amountController.text.trim()) ?? 0,
      createdAt: now,
      updatedAt: now,
      createdBy: session.userId,
      updatedBy: session.userId,
      workspaceId: workspaceId,
    );

    await ref
        .read(installmentRepositoryProvider)
        .savePlan(plan, actorId: session.userId, generateInstallments: false);
    for (var i = 0; i < _draftInstallments.length; i++) {
      final item = _draftInstallments[i];
      await ref
          .read(installmentRepositoryProvider)
          .saveInstallment(
            Installment(
              id: '',
              planId: planId,
              propertyId: widget.propertyId,
              unitId: _unitId,
              sequence: i + 1,
              amount: item.amount,
              paidAmount: 0,
              dueDate: item.dueDate,
              status: InstallmentStatus.pending,
              notes: item.notes,
              createdAt: now,
              updatedAt: now,
              createdBy: session.userId,
              updatedBy: session.userId,
              workspaceId: workspaceId,
            ),
          );
    }
    await ref
        .read(activityRepositoryProvider)
        .log(
          actorId: session.userId,
          actorName: session.profile?.name ?? 'شريك',
          action: 'installment_plan_created',
          entityType: 'installment_plan',
          entityId: plan.unitId,
          metadata: {
            'propertyId': widget.propertyId,
            'count': plan.installmentCount,
            'amount': plan.installmentAmount,
          },
          workspaceId: workspaceId,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: 'إنشاء خطة أقساط',
      child: Form(key: _formKey, child: _buildFormFields()),
    );
  }

  Future<void> _addInstallment() async {
    final item = await _showInstallmentEditor();
    if (item == null) return;
    setState(() => _draftInstallments.add(item));
  }

  Future<void> _editInstallment(int index) async {
    final item = await _showInstallmentEditor(
      initial: _draftInstallments[index],
    );
    if (item == null) return;
    setState(() => _draftInstallments[index] = item);
  }

  Future<_DraftInstallment?> _showInstallmentEditor({
    _DraftInstallment? initial,
  }) async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: initial == null ? '' : initial.amount.toStringAsFixed(0),
    );
    final notesController = TextEditingController(text: initial?.notes ?? '');
    DateTime dueDate = initial?.dueDate ?? _startDate;

    return showDialog<_DraftInstallment>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(initial == null ? 'إضافة قسط' : 'تعديل قسط'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setStateDialog(() => dueDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'تاريخ القسط',
                      ),
                      child: Text(dueDate.formatShort()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'قيمة القسط'),
                    validator: (value) {
                      if ((double.tryParse((value ?? '').trim()) ?? 0) <= 0) {
                        return 'أدخل قيمة صحيحة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظة (اختياري)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.of(context).pop(
                    _DraftInstallment(
                      dueDate: dueDate,
                      amount:
                          double.tryParse(amountController.text.trim()) ?? 0,
                      notes: notesController.text.trim(),
                    ),
                  );
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }
}
