part of '../property_material_supplier_screen.dart';

class _SupplierPaymentSheet extends StatefulWidget {
  const _SupplierPaymentSheet({
    required this.supplierName,
    required this.currentPartnerId,
    required this.currentUserLabel,
    required this.totalRemaining,
    required this.onSubmit,
  });

  final String supplierName;
  final String? currentPartnerId;
  final String currentUserLabel;
  final double totalRemaining;
  final Future<void> Function(
    double amount,
    DateTime paidAt,
    String notes,
    String paidByPartnerId,
  )
  onSubmit;

  @override
  State<_SupplierPaymentSheet> createState() => _SupplierPaymentSheetState();
}

class _SupplierPaymentSheetState extends State<_SupplierPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late DateTime _paidAt;
  late final String _paidByPartnerId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
    _paidAt = DateTime.now();
    _paidByPartnerId = widget.currentPartnerId ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _paidAt = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        double.parse(_amountController.text.trim()),
        _paidAt,
        _notesController.text.trim(),
        _paidByPartnerId,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: 'إضافة دفعة حساب',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.supplierName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'المتبقي الحالي ${widget.totalRemaining.egp}. سيتم تسجيل هذه الدفعة تلقائيًا على المستخدم الحالي وإظهارها في الجدول باسمه.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'قيمة الدفعة',
                helperText: 'الحد الأقصى ${widget.totalRemaining.egp}',
              ),
              validator: (value) {
                final amount = double.tryParse((value ?? '').trim()) ?? 0;
                if (amount <= 0) {
                  return 'أدخل قيمة دفعة صحيحة.';
                }
                if (amount > widget.totalRemaining) {
                  return 'القيمة أكبر من المتبقي على المورد.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'مسجل الدفعة'),
              child: Text(
                widget.currentUserLabel.trim().isEmpty
                    ? 'المستخدم الحالي'
                    : widget.currentUserLabel,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'تاريخ الدفعة'),
                child: Text(_paidAt.formatShort()),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                helperText: 'اختياري',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'جاري الحفظ...' : 'حفظ الدفعة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
