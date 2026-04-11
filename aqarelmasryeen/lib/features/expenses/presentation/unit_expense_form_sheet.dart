import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/utils/grouped_number_input_formatter.dart';
import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/expenses/data/unit_expense_repository.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _UnitExpensePayerOption { currentUser, counterpart }

class UnitExpenseFormSheet extends ConsumerStatefulWidget {
  const UnitExpenseFormSheet({
    super.key,
    required this.propertyId,
    required this.unitId,
    required this.unitLabel,
    required this.partners,
    this.expense,
  });

  final String propertyId;
  final String unitId;
  final String unitLabel;
  final List<Partner> partners;
  final UnitExpenseRecord? expense;

  @override
  ConsumerState<UnitExpenseFormSheet> createState() =>
      _UnitExpenseFormSheetState();
}

class _UnitExpenseFormSheetState extends ConsumerState<UnitExpenseFormSheet> {
  static const _counterpartFallbackPartnerId = '_counterpart_partner_';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  late _UnitExpensePayerOption _payerOption;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _amountController = TextEditingController(
      text: expense == null
          ? ''
          : GroupedNumberInputFormatter.formatNumber(expense.amount),
    );
    _descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );
    _notesController = TextEditingController(text: expense?.notes ?? '');
    _selectedDate = expense?.date ?? DateTime.now();
    _payerOption = _resolveInitialPayerOption();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ar', 'EG'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
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
    final workspaceId = ref.read(currentWorkspaceIdProvider);
    if (workspaceId.isEmpty) {
      return;
    }

    setState(() => _saving = true);
    final savedId = await ref
        .read(unitExpenseRepositoryProvider)
        .save(
          UnitExpenseRecord(
            id: widget.expense?.id ?? '',
            propertyId: widget.propertyId,
            unitId: widget.unitId,
            amount: parseGroupedDouble(_amountController.text),
            description: _descriptionController.text.trim(),
            paidByPartnerId: _resolveSelectedPartnerId(session.userId),
            date: _selectedDate,
            notes: _notesController.text.trim(),
            createdBy: widget.expense?.createdBy ?? session.userId,
            updatedBy: session.userId,
            createdAt:
                widget.expense?.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0),
            updatedAt: DateTime.now(),
            archived: false,
            workspaceId: workspaceId,
          ),
        );

    await ref
        .read(activityRepositoryProvider)
        .log(
          actorId: session.userId,
          actorName: session.profile?.name ?? 'شريك',
          action: widget.expense == null
              ? 'unit_expense_created'
              : 'unit_expense_updated',
          entityType: 'unit_expense',
          entityId: savedId,
          metadata: {'propertyId': widget.propertyId, 'unitId': widget.unitId},
          workspaceId: workspaceId,
        );
    await ref
        .read(notificationRepositoryProvider)
        .create(
          userId: session.userId,
          title: widget.expense == null
              ? 'تمت إضافة مصروف للوحدة'
              : 'تم تحديث مصروف الوحدة',
          body:
              'الوحدة ${widget.unitLabel} - ${_descriptionController.text.trim()}',
          type: NotificationType.expenseAdded,
          route: AppRoutes.propertyUnitDetails(
            widget.propertyId,
            widget.unitId,
          ),
          workspaceId: workspaceId,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  _UnitExpensePayerOption _resolveInitialPayerOption() {
    final expense = widget.expense;
    if (expense == null) {
      return _UnitExpensePayerOption.currentUser;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    final currentUserId = session?.userId;
    final currentPartnerId = _resolveCurrentPartner(currentUserId)?.id;
    final isCurrentSide =
        (currentPartnerId != null &&
            expense.paidByPartnerId == currentPartnerId) ||
        (expense.paidByPartnerId.trim().isEmpty &&
            currentUserId != null &&
            expense.createdBy == currentUserId);

    return isCurrentSide
        ? _UnitExpensePayerOption.currentUser
        : _UnitExpensePayerOption.counterpart;
  }

  Partner? _resolveCurrentPartner(String? currentUserId) {
    if (currentUserId == null) {
      return null;
    }
    for (final partner in widget.partners) {
      if (partner.userId == currentUserId) {
        return partner;
      }
    }
    return null;
  }

  Partner? _resolveCounterpartPartner(String? currentUserId) {
    final currentPartner = _resolveCurrentPartner(currentUserId);
    for (final partner in widget.partners) {
      if (currentPartner == null || partner.id != currentPartner.id) {
        return partner;
      }
    }
    return null;
  }

  String _resolveSelectedPartnerId(String currentUserId) {
    final currentPartner = _resolveCurrentPartner(currentUserId);
    if (_payerOption == _UnitExpensePayerOption.currentUser) {
      return currentPartner?.id ?? '';
    }

    final counterpart = _resolveCounterpartPartner(currentUserId);
    return counterpart?.id ?? _counterpartFallbackPartnerId;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final counterpartName =
        _resolveCounterpartPartner(session?.userId)?.name.trim() ?? '';

    return AppFormSheet(
      title: widget.expense == null ? 'إضافة مصروف' : 'تعديل مصروف',
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
                counterpartName.isEmpty
                    ? 'سيتم حفظ المصروف داخل هذه الوحدة فقط، مع تحديث Totals المستخدم والشريك مباشرة بعد الحفظ.'
                    : 'سجل المصروف على الوحدة ${widget.unitLabel} وسيظهر فورًا داخل ملخص المستخدم والشريك $counterpartName.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'البيان / الوصف'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'أدخل البيان.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              inputFormatters: [GroupedNumberInputFormatter()],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'قيمة المصروف'),
              validator: (value) {
                final parsed = GroupedNumberInputFormatter.tryParse(
                  value ?? '',
                );
                if (parsed == null || parsed <= 0) {
                  return 'أدخل مبلغًا صحيحًا.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
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
            Text(
              'من الذي دفع',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SegmentedButton<_UnitExpensePayerOption>(
              segments: const [
                ButtonSegment<_UnitExpensePayerOption>(
                  value: _UnitExpensePayerOption.currentUser,
                  label: Text('المستخدم'),
                  icon: Icon(Icons.person_outline),
                ),
                ButtonSegment<_UnitExpensePayerOption>(
                  value: _UnitExpensePayerOption.counterpart,
                  label: Text('الشريك'),
                  icon: Icon(Icons.group_outlined),
                ),
              ],
              selected: {_payerOption},
              onSelectionChanged: (selection) {
                setState(() => _payerOption = selection.first);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'جاري الحفظ...' : 'حفظ المصروف'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
