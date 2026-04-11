// ignore_for_file: invalid_use_of_protected_member

part of '../material_expense_form_sheet.dart';

extension _MaterialExpenseFormSheetFields on _MaterialExpenseFormSheetState {
  Widget _buildFormFields() {
    return Column(
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
            'سيتم حفظ الفاتورة باسم المورد والصنف وإجمالي الفاتورة، وأي مبلغ مدفوع عند الإنشاء سيسجل تلقائيًا على المستخدم الحالي.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _supplierController,
          decoration: const InputDecoration(labelText: 'اسم التاجر / المورد'),
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
                  final quantity = double.tryParse((value ?? '').trim()) ?? 0;
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
                decoration: const InputDecoration(labelText: 'إجمالي الفاتورة'),
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
    );
  }
}
