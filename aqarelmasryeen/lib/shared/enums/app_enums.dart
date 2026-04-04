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
  expenseAdded,
  paymentReceived,
  newDeviceLogin,
  systemAlert,
}

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
      case ExpenseCategory.other:
        return 'أخرى';
      case PaymentMethod.cash:
        return 'نقدي';
      case PaymentMethod.bankTransfer:
        return 'تحويل بنكي';
      case PaymentMethod.cheque:
        return 'شيك';
      case PaymentMethod.wallet:
        return 'محفظة إلكترونية';
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
        return 'متاح';
      case UnitStatus.reserved:
        return 'محجوز';
      case UnitStatus.sold:
        return 'مباع';
      case UnitStatus.cancelled:
        return 'ملغي';
      case InstallmentStatus.pending:
        return 'مستحق';
      case InstallmentStatus.partiallyPaid:
        return 'مدفوع جزئيا';
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
      case NotificationType.expenseAdded:
        return 'إضافة مصروف';
      case NotificationType.paymentReceived:
        return 'تحصيل دفعة';
      case NotificationType.newDeviceLogin:
        return 'تسجيل دخول من جهاز جديد';
      case NotificationType.systemAlert:
        return 'تنبيه نظام';
    }
    return name;
  }
}
