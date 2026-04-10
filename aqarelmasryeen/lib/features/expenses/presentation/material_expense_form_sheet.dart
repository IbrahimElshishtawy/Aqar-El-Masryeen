import 'dart:math' as math;

import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MaterialExpenseFormSheet extends ConsumerStatefulWidget {
  const MaterialExpenseFormSheet({
    super.key,
    required this.propertyId,
    required this.partners,
    this.entry,
    this.initialSupplierName,
  });

  final String propertyId;
  final List<Partner> partners;
  final MaterialExpenseEntry? entry;
  final String? initialSupplierName;

  @override
  ConsumerState<MaterialExpenseFormSheet> createState() =>
      _MaterialExpenseFormSheetState();
}

class _MaterialExpenseFormSheetState
    extends ConsumerState<MaterialExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _supplierController;
  late final TextEditingController _itemNameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _totalInvoiceController;
  late final TextEditingController _paidController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  DateTime? _dueDate;
  late String _paidByPartnerId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _supplierController = TextEditingController(
      text: entry?.supplierName ?? widget.initialSupplierName ?? '',
    );
    _itemNameController = TextEditingController(text: entry?.itemName ?? '');
    _quantityController = TextEditingController(
      text: entry == null ? '' : entry.quantity.toStringAsFixed(0),
    );
    _totalInvoiceController = TextEditingController(
      text: entry == null ? '' : entry.totalPrice.toStringAsFixed(0),
    );
    _paidController = TextEditingController(
      text: entry == null ? '' : entry.initialPaidAmount.toStringAsFixed(0),
    );
    _notesController = TextEditingController(text: entry?.notes ?? '');
    _selectedDate = entry?.date ?? DateTime.now();
    _dueDate = entry?.dueDate;
    _paidByPartnerId = _resolveInitialPaidByPartnerId();
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    _totalInvoiceController.dispose();
    _paidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickInvoiceDate() async {
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

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  String _resolveInitialPaidByPartnerId() {
    if (widget.entry?.initialPaidByPartnerId.isNotEmpty == true) {
      return widget.entry!.initialPaidByPartnerId;
    }

    final currentUserId = ref.read(authSessionProvider).valueOrNull?.userId;
    if (currentUserId == null) {
      return widget.partners.isEmpty ? '' : widget.partners.first.id;
    }

    for (final partner in widget.partners) {
      if (partner.userId == currentUserId) {
        return partner.id;
      }
    }
    return widget.partners.isEmpty ? '' : widget.partners.first.id;
  }

  String _currentUserLabel() {
    final session = ref.read(authSessionProvider).valueOrNull;
    final profileName = session?.profile?.fullName.trim() ?? '';
    if (profileName.isNotEmpty) {
      return profileName;
    }

    final displayName = session?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }

    return 'شريك';
  }

  String _partnerLabel(String partnerId) {
    final session = ref.read(authSessionProvider).valueOrNull;
    final currentUserId = session?.userId;
    final currentUserLabel = _currentUserLabel();
    for (final partner in widget.partners) {
      if (partner.id == partnerId) {
        final name = partner.name.trim();
        if (name.isNotEmpty) {
          return name;
        }

        if (currentUserId != null &&
            partner.userId == currentUserId &&
            currentUserLabel.trim().isNotEmpty) {
          return currentUserLabel;
        }

        final linkedEmail = partner.linkedEmail.trim();
        if (linkedEmail.isNotEmpty) {
          return linkedEmail;
        }

        return currentUserLabel;
      }
    }
    return currentUserLabel;
  }

  String _partnerOptionLabel(Partner partner) {
    final name = partner.name.trim();
    if (name.isNotEmpty) {
      return name;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session != null &&
        partner.userId == session.userId &&
        _currentUserLabel().trim().isNotEmpty) {
      return _currentUserLabel();
    }

    final linkedEmail = partner.linkedEmail.trim();
    if (linkedEmail.isNotEmpty) {
      return linkedEmail;
    }

    return 'شريك';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    final quantity = double.parse(_quantityController.text.trim());
    final totalPrice = double.parse(_totalInvoiceController.text.trim());
    final initialPaidAmount = double.parse(_paidController.text.trim());
    final previousExtraPaid = math.max(
      0,
      (widget.entry?.amountPaid ?? 0) - (widget.entry?.initialPaidAmount ?? 0),
    );
    final totalPaid = initialPaidAmount + previousExtraPaid;
    final remainingAmount = (totalPrice - totalPaid)
        .clamp(0, totalPrice)
        .toDouble();
    final unitPrice = quantity <= 0 ? 0.0 : totalPrice / quantity;
    final now = DateTime.now();

    setState(() => _saving = true);
    final savedId = await ref
        .read(materialExpenseRepositoryProvider)
        .save(
          MaterialExpenseEntry(
            id: widget.entry?.id ?? '',
            propertyId: widget.propertyId,
            date: _selectedDate,
            materialCategory:
                widget.entry?.materialCategory ?? MaterialCategory.other,
            itemName: _itemNameController.text.trim(),
            quantity: quantity,
            unitPrice: unitPrice,
            totalPrice: totalPrice,
            supplierName: _supplierController.text.trim(),
            initialPaidAmount: initialPaidAmount,
            initialPaidByPartnerId: initialPaidAmount > 0
                ? _paidByPartnerId
                : '',
            initialPaidByLabel: initialPaidAmount > 0
                ? _partnerLabel(_paidByPartnerId)
                : '',
            amountPaid: totalPaid,
            amountRemaining: remainingAmount,
            notes: _notesController.text.trim(),
            createdBy: widget.entry?.createdBy ?? session.userId,
            updatedBy: session.userId,
            createdAt:
                widget.entry?.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0),
            updatedAt: now,
            archived: false,
            dueDate: _dueDate,
          ),
        );
    await ref
        .read(activityRepositoryProvider)
        .log(
          actorId: session.userId,
          actorName: session.profile?.name ?? 'شريك',
          action: widget.entry == null
              ? 'material_expense_created'
              : 'material_expense_updated',
          entityType: 'material_expense',
          entityId: savedId,
          metadata: {
            'propertyId': widget.propertyId,
            'supplierName': _supplierController.text.trim(),
            'itemName': _itemNameController.text.trim(),
            'amount': totalPrice,
          },
          workspaceId: session.profile?.workspaceId.trim(),
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final payerOptions = widget.partners
        .where((partner) => partner.id.trim().isNotEmpty)
        .toList(growable: false);
    final hasSelectedPayer = payerOptions.any(
      (partner) => partner.id == _paidByPartnerId,
    );

    return AppFormSheet(
      title: widget.entry == null
          ? 'إضافة فاتورة مواد بناء'
          : 'تعديل فاتورة مواد بناء',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8F4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD8D8D2)),
              ),
              child: Text(
                'الفاتورة تحفظ باسم الصنف والمورد وإجمالي الفاتورة فقط. لا يتم عرض نوع المادة أو سعر الوحدة داخل النموذج.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _supplierController,
              decoration: const InputDecoration(
                labelText: 'اسم التاجر / المورد',
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'أدخل اسم المورد.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _itemNameController,
              decoration: const InputDecoration(labelText: 'اسم الصنف'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'أدخل اسم الصنف.' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'الكمية'),
                    validator: (value) {
                      final quantity =
                          double.tryParse((value ?? '').trim()) ?? 0;
                      if (quantity <= 0) {
                        return 'أدخل كمية صحيحة.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _totalInvoiceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'إجمالي الفاتورة',
                    ),
                    validator: (value) {
                      final total = double.tryParse((value ?? '').trim()) ?? 0;
                      if (total <= 0) {
                        return 'أدخل إجمالي الفاتورة.';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _paidController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'المدفوع'),
              validator: (value) {
                final paid = double.tryParse((value ?? '').trim()) ?? 0;
                final total =
                    double.tryParse(_totalInvoiceController.text.trim()) ?? 0;
                if (paid < 0) {
                  return 'أدخل مبلغًا صحيحًا.';
                }
                if (paid > total) {
                  return 'المدفوع لا يمكن أن يكون أكبر من إجمالي الفاتورة.';
                }
                return null;
              },
            ),
            if (payerOptions.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: hasSelectedPayer ? _paidByPartnerId : null,
                items: [
                  for (final partner in payerOptions)
                    DropdownMenuItem(
                      value: partner.id,
                      child: Text(_partnerOptionLabel(partner)),
                    ),
                ],
                onChanged: (value) {
                  setState(() => _paidByPartnerId = value ?? _paidByPartnerId);
                },
                decoration: const InputDecoration(labelText: 'من الذي دفع'),
              ),
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickInvoiceDate,
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
            InkWell(
              onTap: _pickDueDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'تاريخ الاستحقاق'),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dueDate == null ? 'غير محدد' : _dueDate!.formatShort(),
                      ),
                    ),
                    if (_dueDate != null)
                      IconButton(
                        onPressed: () => setState(() => _dueDate = null),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'إزالة التاريخ',
                      ),
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
                child: Text(_saving ? 'جاري الحفظ...' : 'حفظ الفاتورة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
