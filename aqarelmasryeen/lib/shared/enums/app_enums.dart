enum UserRole { partner }

enum PropertyStatus { planning, active, delivered, archived }

enum ExpenseCategory {
  construction,
  legal,
  permits,
  utilities,
  marketing,
  brokerage,
  maintenance,
  materials,
  partnerSettlement,
  other,
}

enum PaymentMethod { cash, bankTransfer, cheque, wallet, other }

enum UnitType { apartment, penthouse, office, retail, floor, villa }

enum UnitStatus { available, reserved, sold, cancelled }

enum InstallmentStatus { pending, partiallyPaid, paid, overdue }

enum PaymentPlanType { cash, installment, custom }

enum NotificationType {
  installmentDue,
  overdueInstallment,
  installmentCompleted,
  expenseAdded,
  paymentReceived,
  supplierPaymentDue,
  largeExpenseRecorded,
  ledgerUpdated,
  newDeviceLogin,
  systemAlert,
}

enum MaterialCategory {
  cement,
  brick,
  steel,
  sand,
  gravel,
  finishing,
  electrical,
  plumbing,
  paint,
  other,
}

enum SupplierInvoiceStatus { unpaid, partiallyPaid, paid, overdue }

enum PartnerLedgerEntryType { contribution, settlement, obligation, adjustment }

extension EnumLabelX on Enum {
  String get label {
    switch (this) {
      case UserRole.partner:
        return 'Partner';
      case PropertyStatus.planning:
        return 'Planning';
      case PropertyStatus.active:
        return 'Active';
      case PropertyStatus.delivered:
        return 'Delivered';
      case PropertyStatus.archived:
        return 'Archived';
      case ExpenseCategory.construction:
        return 'Construction';
      case ExpenseCategory.legal:
        return 'Legal';
      case ExpenseCategory.permits:
        return 'Permits';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.brokerage:
        return 'Brokerage';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.materials:
        return 'Materials';
      case ExpenseCategory.partnerSettlement:
        return 'Partner Settlement';
      case ExpenseCategory.other:
        return 'Other';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.wallet:
        return 'Wallet';
      case PaymentMethod.other:
        return 'Other';
      case UnitType.apartment:
        return 'Apartment';
      case UnitType.penthouse:
        return 'Penthouse';
      case UnitType.office:
        return 'Office';
      case UnitType.retail:
        return 'Retail';
      case UnitType.floor:
        return 'Floor';
      case UnitType.villa:
        return 'Villa';
      case UnitStatus.available:
        return 'Available';
      case UnitStatus.reserved:
        return 'Reserved';
      case UnitStatus.sold:
        return 'Sold';
      case UnitStatus.cancelled:
        return 'Cancelled';
      case InstallmentStatus.pending:
        return 'Unpaid';
      case InstallmentStatus.partiallyPaid:
        return 'Partially Paid';
      case InstallmentStatus.paid:
        return 'Paid';
      case InstallmentStatus.overdue:
        return 'Overdue';
      case PaymentPlanType.cash:
        return 'Cash';
      case PaymentPlanType.installment:
        return 'Installment';
      case PaymentPlanType.custom:
        return 'Custom';
      case NotificationType.installmentDue:
        return 'Installment Due';
      case NotificationType.overdueInstallment:
        return 'Overdue Installment';
      case NotificationType.installmentCompleted:
        return 'Installment Completed';
      case NotificationType.expenseAdded:
        return 'Expense Added';
      case NotificationType.paymentReceived:
        return 'Payment Received';
      case NotificationType.supplierPaymentDue:
        return 'Supplier Payment Due';
      case NotificationType.largeExpenseRecorded:
        return 'Large Expense Recorded';
      case NotificationType.ledgerUpdated:
        return 'Ledger Updated';
      case NotificationType.newDeviceLogin:
        return 'New Device Login';
      case NotificationType.systemAlert:
        return 'System Alert';
      case MaterialCategory.cement:
        return 'Cement';
      case MaterialCategory.brick:
        return 'Brick';
      case MaterialCategory.steel:
        return 'Steel';
      case MaterialCategory.sand:
        return 'Sand';
      case MaterialCategory.gravel:
        return 'Gravel';
      case MaterialCategory.finishing:
        return 'Finishing';
      case MaterialCategory.electrical:
        return 'Electrical';
      case MaterialCategory.plumbing:
        return 'Plumbing';
      case MaterialCategory.paint:
        return 'Paint';
      case MaterialCategory.other:
        return 'Other';
      case SupplierInvoiceStatus.unpaid:
        return 'Unpaid';
      case SupplierInvoiceStatus.partiallyPaid:
        return 'Partially Paid';
      case SupplierInvoiceStatus.paid:
        return 'Paid';
      case SupplierInvoiceStatus.overdue:
        return 'Overdue';
      case PartnerLedgerEntryType.contribution:
        return 'Contribution';
      case PartnerLedgerEntryType.settlement:
        return 'Settlement';
      case PartnerLedgerEntryType.obligation:
        return 'Obligation';
      case PartnerLedgerEntryType.adjustment:
        return 'Adjustment';
    }
  }
}
