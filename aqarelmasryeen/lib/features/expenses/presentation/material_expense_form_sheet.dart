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

part 'widgets/material_expense_form_fields.dart';

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
      return '';
    }

    for (final partner in widget.partners) {
      if (partner.userId == currentUserId) {
        return partner.id;
      }
    }
    return '';
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }
    final workspaceId = session.profile?.workspaceId.trim() ?? '';
    if (workspaceId.isEmpty) {
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
            workspaceId: widget.entry?.workspaceId ?? workspaceId,
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
          workspaceId: workspaceId,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: widget.entry == null
          ? 'إضافة فاتورة مواد بناء'
          : 'تعديل فاتورة مواد بناء',
      child: Form(key: _formKey, child: _buildFormFields()),
    );
  }
}
