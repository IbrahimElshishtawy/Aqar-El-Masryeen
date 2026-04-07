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
  partnerLinkRequest,
  partnerLinkAccepted,
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
        return 'شريك';
      case PropertyStatus.planning:
        return 'تحت التخطيط';
      case PropertyStatus.active:
        return 'نشط';
      case PropertyStatus.delivered:
        return 'تم التسليم';
      case PropertyStatus.archived:
        return 'مؤرشف';
      case ExpenseCategory.construction:
        return 'إنشاءات';
      case ExpenseCategory.legal:
        return 'قانوني';
      case ExpenseCategory.permits:
        return 'تصاريح';
      case ExpenseCategory.utilities:
        return 'مرافق';
      case ExpenseCategory.marketing:
        return 'تسويق';
      case ExpenseCategory.brokerage:
        return 'سمسرة';
      case ExpenseCategory.maintenance:
        return 'صيانة';
      case ExpenseCategory.materials:
        return 'مواد بناء';
      case ExpenseCategory.partnerSettlement:
        return 'تسوية شريك';
      case ExpenseCategory.other:
        return 'أخرى';
      case PaymentMethod.cash:
        return 'كاش';
      case PaymentMethod.bankTransfer:
        return 'تحويل بنكي';
      case PaymentMethod.cheque:
        return 'شيك';
      case PaymentMethod.wallet:
        return 'محفظة';
      case PaymentMethod.other:
        return 'أخرى';
      case UnitType.apartment:
        return 'شقة';
      case UnitType.penthouse:
        return 'بنتهاوس';
      case UnitType.office:
        return 'مكتب';
      case UnitType.retail:
        return 'محل';
      case UnitType.floor:
        return 'دور';
      case UnitType.villa:
        return 'فيلا';
      case UnitStatus.available:
        return 'متاحة';
      case UnitStatus.reserved:
        return 'محجوزة';
      case UnitStatus.sold:
        return 'مباعة';
      case UnitStatus.cancelled:
        return 'ملغاة';
      case InstallmentStatus.pending:
        return 'غير مدفوع';
      case InstallmentStatus.partiallyPaid:
        return 'مدفوع جزئياً';
      case InstallmentStatus.paid:
        return 'مدفوع';
      case InstallmentStatus.overdue:
        return 'متأخر';
      case PaymentPlanType.cash:
        return 'كاش';
      case PaymentPlanType.installment:
        return 'تقسيط';
      case PaymentPlanType.custom:
        return 'مخصص';
      case NotificationType.installmentDue:
        return 'قسط مستحق';
      case NotificationType.overdueInstallment:
        return 'قسط متأخر';
      case NotificationType.installmentCompleted:
        return 'اكتمل السداد';
      case NotificationType.expenseAdded:
        return 'تمت إضافة مصروف';
      case NotificationType.paymentReceived:
        return 'تم استلام دفعة';
      case NotificationType.supplierPaymentDue:
        return 'استحقاق مورد';
      case NotificationType.largeExpenseRecorded:
        return 'مصروف كبير مسجل';
      case NotificationType.ledgerUpdated:
        return 'تم تحديث السجل';
      case NotificationType.partnerLinkRequest:
        return 'طلب ربط شريك';
      case NotificationType.partnerLinkAccepted:
        return 'تم قبول الربط';
      case NotificationType.newDeviceLogin:
        return 'دخول من جهاز جديد';
      case NotificationType.systemAlert:
        return 'تنبيه نظام';
      case MaterialCategory.cement:
        return 'أسمنت';
      case MaterialCategory.brick:
        return 'طوب';
      case MaterialCategory.steel:
        return 'حديد';
      case MaterialCategory.sand:
        return 'رمل';
      case MaterialCategory.gravel:
        return 'زلط';
      case MaterialCategory.finishing:
        return 'تشطيبات';
      case MaterialCategory.electrical:
        return 'كهرباء';
      case MaterialCategory.plumbing:
        return 'سباكة';
      case MaterialCategory.paint:
        return 'دهانات';
      case MaterialCategory.other:
        return 'أخرى';
      case SupplierInvoiceStatus.unpaid:
        return 'غير مدفوع';
      case SupplierInvoiceStatus.partiallyPaid:
        return 'مدفوع جزئياً';
      case SupplierInvoiceStatus.paid:
        return 'مدفوع';
      case SupplierInvoiceStatus.overdue:
        return 'متأخر';
      case PartnerLedgerEntryType.contribution:
        return 'مساهمة';
      case PartnerLedgerEntryType.settlement:
        return 'تسوية';
      case PartnerLedgerEntryType.obligation:
        return 'التزام';
      case PartnerLedgerEntryType.adjustment:
        return 'تعديل';
    }
    return name;
  }
}
