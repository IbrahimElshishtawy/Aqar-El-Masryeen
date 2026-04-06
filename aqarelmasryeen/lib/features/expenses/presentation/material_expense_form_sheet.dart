import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MaterialExpenseFormSheet extends ConsumerStatefulWidget {
  const MaterialExpenseFormSheet({
    super.key,
    required this.propertyId,
    this.entry,
  });

  final String propertyId;
  final MaterialExpenseEntry? entry;

  @override
  ConsumerState<MaterialExpenseFormSheet> createState() =>
      _MaterialExpenseFormSheetState();
}

class _MaterialExpenseFormSheetState
    extends ConsumerState<MaterialExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _itemController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _totalPriceController;
  late final TextEditingController _supplierController;
  late final TextEditingController _amountPaidController;
  late final TextEditingController _notesController;
  late MaterialCategory _category;
  late DateTime _date;
  late DateTime _dueDate;
  bool _saving = false;
  bool _syncingTotalPrice = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _itemController = TextEditingController(text: entry?.itemName ?? '');
    _quantityController = TextEditingController(
      text: entry == null ? '' : entry.quantity.toStringAsFixed(0),
    );
    _unitPriceController = TextEditingController(
      text: entry == null ? '' : entry.unitPrice.toStringAsFixed(0),
    );
    _totalPriceController = TextEditingController(
      text: entry == null ? '' : entry.totalPrice.toStringAsFixed(0),
    );
    _supplierController = TextEditingController(
      text: entry?.supplierName ?? '',
    );
    _amountPaidController = TextEditingController(
      text: entry == null ? '' : entry.amountPaid.toStringAsFixed(0),
    );
    _notesController = TextEditingController(text: entry?.notes ?? '');
    _category = entry?.materialCategory ?? MaterialCategory.brick;
    _date = entry?.date ?? DateTime.now();
    _dueDate = entry?.dueDate ?? DateTime.now();
    _quantityController.addListener(_syncTotalPrice);
    _unitPriceController.addListener(_syncTotalPrice);
    _syncTotalPrice();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _totalPriceController.dispose();
    _supplierController.dispose();
    _amountPaidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool due}) async {
    final current = due ? _dueDate : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (due) {
          _dueDate = picked;
        } else {
          _date = picked;
        }
      });
    }
  }

  void _syncTotalPrice() {
    if (_syncingTotalPrice) {
      return;
    }

    final quantity = double.tryParse(_quantityController.text.trim());
    final unitPrice = double.tryParse(_unitPriceController.text.trim());
    if (quantity == null ||
        unitPrice == null ||
        quantity <= 0 ||
        unitPrice <= 0) {
      if (widget.entry == null &&
          _totalPriceController.text.trim().isNotEmpty) {
        _syncingTotalPrice = true;
        _totalPriceController.clear();
        _syncingTotalPrice = false;
      }
      return;
    }

    final computedTotal = (quantity * unitPrice).toStringAsFixed(0);
    if (_totalPriceController.text.trim() == computedTotal) {
      return;
    }

    _syncingTotalPrice = true;
    _totalPriceController.text = computedTotal;
    _syncingTotalPrice = false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    setState(() => _saving = true);

    final totalPrice = double.parse(_totalPriceController.text.trim());
    final amountPaid = double.tryParse(_amountPaidController.text.trim()) ?? 0;
    final entry = MaterialExpenseEntry(
      id: widget.entry?.id ?? '',
      propertyId: widget.propertyId,
      date: _date,
      materialCategory: _category,
      itemName: _itemController.text.trim(),
      quantity: double.parse(_quantityController.text.trim()),
      unitPrice: double.parse(_unitPriceController.text.trim()),
      totalPrice: totalPrice,
      supplierName: _supplierController.text.trim(),
      amountPaid: amountPaid,
      amountRemaining: (totalPrice - amountPaid)
          .clamp(0, totalPrice)
          .toDouble(),
      dueDate: _dueDate,
      notes: _notesController.text.trim(),
      createdBy: widget.entry?.createdBy ?? session.userId,
      updatedBy: session.userId,
      createdAt:
          widget.entry?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.now(),
      archived: false,
    );

    final savedId = await ref
        .read(materialExpenseRepositoryProvider)
        .save(entry);
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
            'amount': entry.totalPrice,
          },
        );
    await ref
        .read(notificationRepositoryProvider)
        .create(
          userId: session.userId,
          title: entry.totalPrice >= 100000
              ? 'تم تسجيل مصروف مواد كبير'
              : 'تم تحديث مصروف المواد',
          body: '${entry.itemName} - ${entry.supplierName}',
          type: entry.totalPrice >= 100000
              ? NotificationType.largeExpenseRecorded
              : NotificationType.expenseAdded,
          route: '/properties/${widget.propertyId}',
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: widget.entry == null
          ? 'إضافة فاتورة مواد بناء'
          : 'تعديل فاتورة مواد البناء',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<MaterialCategory>(
              initialValue: _category,
              items: MaterialCategory.values
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text(item.label)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _category = value ?? _category),
              decoration: const InputDecoration(labelText: 'نوع المادة'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _itemController,
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
                      if ((double.tryParse((value ?? '').trim()) ?? 0) <= 0) {
                        return 'أدخل الكمية.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unitPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'سعر الوحدة'),
                    validator: (value) {
                      if ((double.tryParse((value ?? '').trim()) ?? 0) <= 0) {
                        return 'أدخل سعر الوحدة.';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _totalPriceController,
              readOnly: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'إجمالي الفاتورة',
                helperText: 'يتم حسابه تلقائيًا من الكمية وسعر الوحدة',
              ),
              validator: (value) {
                if ((double.tryParse((value ?? '').trim()) ?? 0) <= 0) {
                  return 'أدخل إجمالي الفاتورة.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _supplierController,
              decoration: const InputDecoration(
                labelText: 'اسم التاجر / المورد',
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'أدخل اسم التاجر أو المورد.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountPaidController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'المدفوع'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(due: false),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'التاريخ'),
                      child: Text(_date.formatShort()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(due: true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'تاريخ الاستحقاق',
                      ),
                      child: Text(_dueDate.formatShort()),
                    ),
                  ),
                ),
              ],
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
                child: Text(
                  _saving ? 'جاري الحفظ...' : 'حفظ فاتورة مواد البناء',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
