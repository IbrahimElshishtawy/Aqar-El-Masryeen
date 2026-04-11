// ignore_for_file: invalid_use_of_protected_member

part of '../installment_plan_form_sheet.dart';

extension _InstallmentPlanFormSheetFields on _InstallmentPlanFormSheetState {
  Widget _buildFormFields() {
    return Column(
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
                decoration: const InputDecoration(labelText: 'عدد الأقساط'),
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
                decoration: const InputDecoration(labelText: 'الفاصل بالأيام'),
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'قيمة القسط'),
          validator: (value) {
            if ((double.tryParse((value ?? '').trim()) ?? 0) <= 0) {
              return 'أدخل قيمة القسط.';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              'الأقساط اليدوية (${_draftInstallments.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _saving ? null : _addInstallment,
              icon: const Icon(Icons.add),
              label: const Text('إضافة قسط'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_draftInstallments.isEmpty)
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('لا توجد أقساط مضافة بعد'),
            subtitle: Text('أضف تواريخ وقيم الأقساط يدويًا قبل الحفظ.'),
          )
        else
          ..._draftInstallments.asMap().entries.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'القسط ${entry.key + 1} • ${entry.value.amount.toStringAsFixed(0)}',
              ),
              subtitle: Text(
                '${entry.value.dueDate.formatShort()}${entry.value.notes.trim().isEmpty ? '' : ' • ${entry.value.notes}'}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => _editInstallment(entry.key),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => setState(
                            () => _draftInstallments.removeAt(entry.key),
                          ),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
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
    );
  }
}
