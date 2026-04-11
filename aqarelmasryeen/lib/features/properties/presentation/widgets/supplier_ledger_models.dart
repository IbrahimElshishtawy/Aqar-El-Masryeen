part of '../property_material_supplier_screen.dart';

class _SupplierAccountSummary {
  const _SupplierAccountSummary({
    required this.totalQuantity,
    required this.totalRequired,
    required this.totalPaid,
    required this.totalRemaining,
  });

  final double totalQuantity;
  final double totalRequired;
  final double totalPaid;
  final double totalRemaining;
}

class _SupplierLedgerRow {
  const _SupplierLedgerRow({
    required this.sequence,
    required this.displayDate,
    required this.isPayment,
    required this.supplierName,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.addedValue,
    required this.paidValue,
    required this.remainingAfter,
    required this.paidByLabel,
    required this.notes,
    required this.materialEntry,
    required this.paymentEntry,
  });

  final int sequence;
  final DateTime displayDate;
  final bool isPayment;
  final String supplierName;
  final String description;
  final double? quantity;
  final double unitPrice;
  final double addedValue;
  final double paidValue;
  final double remainingAfter;
  final String paidByLabel;
  final String notes;
  final MaterialExpenseEntry? materialEntry;
  final SupplierPaymentRecord? paymentEntry;

  String get typeLabel => isPayment ? 'دفعة' : '';

  String get quantityLabel {
    if (quantity == null || quantity == 0) {
      return '-';
    }
    return _formatQuantity(quantity!);
  }

  String get priceLabel {
    if (isPayment || addedValue <= 0) {
      return '-';
    }
    return addedValue.egp;
  }
}

enum _SupplierLedgerEventType { invoice, payment }

class _SupplierLedgerEvent {
  const _SupplierLedgerEvent._({
    required this.type,
    required this.date,
    required this.createdAt,
    this.material,
    this.payment,
  });

  factory _SupplierLedgerEvent.invoice(MaterialExpenseEntry material) {
    return _SupplierLedgerEvent._(
      type: _SupplierLedgerEventType.invoice,
      date: material.date,
      createdAt: material.createdAt,
      material: material,
    );
  }

  factory _SupplierLedgerEvent.payment(SupplierPaymentRecord payment) {
    return _SupplierLedgerEvent._(
      type: _SupplierLedgerEventType.payment,
      date: payment.paidAt,
      createdAt: payment.createdAt,
      payment: payment,
    );
  }

  final _SupplierLedgerEventType type;
  final DateTime date;
  final DateTime createdAt;
  final MaterialExpenseEntry? material;
  final SupplierPaymentRecord? payment;
}
