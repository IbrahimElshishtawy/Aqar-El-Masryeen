import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/features/unit_sales/domain/unit_sales_calculator.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentFormSheet extends ConsumerStatefulWidget {
  const PaymentFormSheet({
    super.key,
    required this.propertyId,
    required this.unitId,
    required this.unitLabel,
    required this.customerName,
    required this.installmentRows,
    this.payment,
    this.installmentId,
  });

  final String propertyId;
  final String unitId;
  final String unitLabel;
  final String customerName;
  final List<InstallmentComputedRow> installmentRows;
  final PaymentRecord? payment;
  final String? installmentId;

  @override
  ConsumerState<PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends ConsumerState<PaymentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late PaymentMethod _paymentMethod;
  late DateTime _receivedAt;
  late String _paymentType;
  late String _selectedInstallmentId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final payment = widget.payment;
    final initialInstallmentId =
        payment?.installmentId?.trim() ??
        widget.installmentId?.trim() ??
        '';

    _amountController = TextEditingController(
      text: payment == null ? '' : payment.amount.toStringAsFixed(0),
    );
    _notesController = TextEditingController(text: payment?.notes ?? '');
    _paymentMethod = payment?.paymentMethod ?? PaymentMethod.cash;
    _receivedAt = payment?.receivedAt ?? DateTime.now();
    _selectedInstallmentId = initialInstallmentId;
    _paymentType = payment?.paymentSource.trim().isNotEmpty == true
        ? payment!.paymentSource.trim()
        : (initialInstallmentId.isNotEmpty
              ? _installmentPaymentType
              : _initialPaymentType);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  InstallmentComputedRow? get _selectedInstallmentRow {
    if (_selectedInstallmentId.isEmpty) {
      return null;
    }
    for (final row in widget.installmentRows) {
      if (row.installment.id == _selectedInstallmentId) {
        return row;
      }
    }
    return null;
  }

  bool get _isInstallmentPaymentType => _paymentType == _installmentPaymentType;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _receivedAt = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    final installmentId = _isInstallmentPaymentType && _selectedInstallmentId.isNotEmpty
        ? _selectedInstallmentId
        : null;

    setState(() => _saving = true);
    final savedId = await ref
        .read(paymentRepositoryProvider)
        .save(
          PaymentRecord(
            id: widget.payment?.id ?? '',
            propertyId: widget.propertyId,
            unitId: widget.unitId,
            payerName: widget.payment?.payerName.trim().isNotEmpty == true
                ? widget.payment!.payerName.trim()
                : widget.customerName.trim(),
            customerName: widget.customerName.trim(),
            installmentId: installmentId,
            amount: double.parse(_amountController.text.trim()),
            receivedAt: _receivedAt,
            paymentMethod: _paymentMethod,
            paymentSource: _paymentType,
            notes: _notesController.text.trim(),
            createdAt:
                widget.payment?.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0),
            updatedAt: DateTime.now(),
            createdBy: widget.payment?.createdBy ?? session.userId,
            updatedBy: session.userId,
          ),
        );

    await ref
        .read(activityRepositoryProvider)
        .log(
          actorId: session.userId,
          actorName: session.profile?.name ?? 'شريك',
          action: widget.payment == null ? 'payment_created' : 'payment_updated',
          entityType: 'payment',
          entityId: savedId,
          metadata: {
            'propertyId': widget.propertyId,
            'unitId': widget.unitId,
            'installmentId': installmentId,
            'paymentType': _paymentType,
            'amount': double.parse(_amountController.text.trim()),
          },
        );
    await ref
        .read(notificationRepositoryProvider)
        .create(
          userId: session.userId,
          title: widget.payment == null ? 'تم استلام دفعة' : 'تم تحديث الدفعة',
          body: widget.customerName.trim().isEmpty
              ? 'تم تسجيل دفعة جديدة على الوحدة ${widget.unitLabel}'
              : 'دفعة للوحدة ${widget.unitLabel} - ${widget.customerName}',
          type: NotificationType.paymentReceived,
          route: '/properties/${widget.propertyId}',
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedInstallment = _selectedInstallmentRow;

    return AppFormSheet(
      title: widget.payment == null ? 'إضافة دفعة' : 'تعديل الدفعة',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PaymentInfoBanner(
              unitLabel: widget.unitLabel,
              customerName: widget.customerName,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'قيمة الدفعة'),
              validator: (value) {
                final parsed = double.tryParse((value ?? '').trim());
                if (parsed == null || parsed <= 0) {
                  return 'أدخل قيمة دفعة صحيحة.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _paymentType,
              items: _paymentTypes
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                final nextValue = value ?? _paymentType;
                setState(() {
                  _paymentType = nextValue;
                  if (!_isInstallmentPaymentType) {
                    _selectedInstallmentId = '';
                  }
                });
              },
              decoration: const InputDecoration(labelText: 'نوع الدفعة'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _paymentMethod,
              items: PaymentMethod.values
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _paymentMethod = value ?? _paymentMethod);
              },
              decoration: const InputDecoration(labelText: 'طريقة التحصيل'),
            ),
            const SizedBox(height: 12),
            if (widget.installmentRows.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue:
                    _selectedInstallmentId.isEmpty ? _noInstallmentValue : _selectedInstallmentId,
                items: [
                  const DropdownMenuItem<String>(
                    value: _noInstallmentValue,
                    child: Text('بدون ربط بقسط'),
                  ),
                  for (final row in widget.installmentRows)
                    DropdownMenuItem<String>(
                      value: row.installment.id,
                      child: Text(
                        'قسط ${row.installment.sequence} - المتبقي ${row.remainingAmount.egp}',
                      ),
                    ),
                ],
                onChanged: (value) {
                  final nextValue =
                      value == null || value == _noInstallmentValue ? '' : value;
                  setState(() {
                    _selectedInstallmentId = nextValue;
                    if (nextValue.isNotEmpty) {
                      _paymentType = _installmentPaymentType;
                    }
                  });
                },
                validator: (value) {
                  final selectedValue =
                      value == null || value == _noInstallmentValue ? '' : value;
                  if (_isInstallmentPaymentType && selectedValue.isEmpty) {
                    return 'اختر القسط المرتبط بهذه الدفعة.';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'القسط المرتبط',
                ),
              ),
            if (widget.installmentRows.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD8D8D2)),
                ),
                child: Text(
                  'لم يتم إنشاء شيت الأقساط لهذه الوحدة بعد. يمكنك تسجيل دفعة غير مربوطة بقسط الآن، وسيظهر الربط بمجرد تجهيز الأقساط.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            if (selectedInstallment != null) ...[
              const SizedBox(height: 12),
              _SelectedInstallmentCard(row: selectedInstallment),
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'تاريخ الدفع'),
                child: Row(
                  children: [
                    Expanded(child: Text(_receivedAt.formatShort())),
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
              decoration: const InputDecoration(labelText: 'ملاحظات اختيارية'),
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

class _PaymentInfoBanner extends StatelessWidget {
  const _PaymentInfoBanner({
    required this.unitLabel,
    required this.customerName,
  });

  final String unitLabel;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    final resolvedCustomerName = customerName.trim().isEmpty
        ? 'عميل غير محدد'
        : customerName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الوحدة $unitLabel',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            resolvedCustomerName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'يتم تسجيل كل مبلغ يدويًا، ولن يتم احتساب أي قسط أو دفعة تلقائيًا بدون إدخال صريح منك.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF55655F),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedInstallmentCard extends StatelessWidget {
  const _SelectedInstallmentCard({required this.row});

  final InstallmentComputedRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'القسط ${row.installment.sequence}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1D5140),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'الاستحقاق ${row.installment.dueDate.formatShort()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'قيمة القسط ${row.installment.amount.egp} - المدفوع ${row.amountPaid.egp} - المتبقي ${row.remainingAmount.egp}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

const String _defaultPaymentType = 'مقدم';
const String _installmentPaymentType = 'دفعة قسط';
const String _noInstallmentValue = '__none__';
const String _initialPaymentType = 'دفعة إضافية';

const List<String> _paymentTypes = <String>[
  _defaultPaymentType,
  _installmentPaymentType,
  'دفعة إضافية',
  'تسوية',
  'أخرى',
];
