part of '../installment_plan_form_sheet.dart';

class _DraftInstallment {
  const _DraftInstallment({
    required this.dueDate,
    required this.amount,
    this.notes = '',
  });

  final DateTime dueDate;
  final double amount;
  final String notes;
}
