import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/installments/data/installment_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InstallmentFormSheet extends ConsumerStatefulWidget {
  const InstallmentFormSheet({
    super.key,
    required this.propertyId,
    required this.unitId,
    required this.planId,
    this.installment,
    this.suggestedSequence,
  });

  final String propertyId;
  final String unitId;
  final String planId;
  final Installment? installment;
  final int? suggestedSequence;

  @override
  ConsumerState<InstallmentFormSheet> createState() =>
      _InstallmentFormSheetState();
}

class _InstallmentFormSheetState extends ConsumerState<InstallmentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sequenceController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late DateTime _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final installment = widget.installment;
    _sequenceController = TextEditingController(
      text: installment == null
          ? '${widget.suggestedSequence ?? 1}'
          : '${installment.sequence}',
    );
    _amountController = TextEditingController(
      text: installment == null ? '' : installment.amount.toStringAsFixed(0),
    );
    _notesController = TextEditingController(text: installment?.notes ?? '');
    _dueDate = installment?.dueDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _sequenceController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    final workspaceId = session.profile?.workspaceId.trim() ?? '';
    if (workspaceId.isEmpty) return;
    setState(() => _saving = true);

    final amount = double.parse(_amountController.text.trim());
    final status = _dueDate.isBefore(DateTime.now())
        ? InstallmentStatus.overdue
        : InstallmentStatus.pending;
    final installment = Installment(
      id: widget.installment?.id ?? '',
      planId: widget.planId,
      propertyId: widget.propertyId,
      unitId: widget.unitId,
      sequence: int.parse(_sequenceController.text.trim()),
      amount: amount,
      paidAmount: widget.installment?.paidAmount ?? 0,
      dueDate: _dueDate,
      status: widget.installment == null ? status : widget.installment!.status,
      notes: _notesController.text.trim(),
      createdAt:
          widget.installment?.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.now(),
      createdBy: widget.installment?.createdBy ?? session.userId,
      updatedBy: session.userId,
      workspaceId: widget.installment?.workspaceId ?? workspaceId,
    );

    await ref.read(installmentRepositoryProvider).saveInstallment(installment);
    await ref
        .read(activityRepositoryProvider)
        .log(
          actorId: session.userId,
          actorName: session.profile?.name ?? 'شريك',
          action: widget.installment == null
              ? 'installment_created'
              : 'installment_updated',
          entityType: 'installment',
          entityId: installment.id.isEmpty
              ? '${widget.unitId}_${installment.sequence}'
              : installment.id,
          metadata: {'propertyId': widget.propertyId, 'unitId': widget.unitId},
          workspaceId: workspaceId,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: widget.installment == null ? 'إضافة قسط' : 'تعديل القسط',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sequenceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'رقم القسط'),
                    validator: (value) {
                      if ((int.tryParse((value ?? '').trim()) ?? 0) <= 0) {
                        return 'أدخل رقم القسط.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'قيمة القسط'),
                    validator: (value) {
                      if ((double.tryParse((value ?? '').trim()) ?? 0) <= 0) {
                        return 'أدخل قيمة القسط.';
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
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'تاريخ الاستحقاق'),
                child: Row(
                  children: [
                    Expanded(child: Text(_dueDate.formatShort())),
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
                child: Text(_saving ? 'جاري الحفظ...' : 'حفظ القسط'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
