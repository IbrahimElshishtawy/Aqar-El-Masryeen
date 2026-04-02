enum UserRole { partner }

enum PropertyStatus { planning, active, delivered, archived }

enum ExpenseCategory { construction, legal, permits, utilities, marketing, brokerage, maintenance, other }

enum PaymentMethod { cash, bankTransfer, cheque, wallet, other }

enum UnitType { apartment, penthouse, office, retail, floor, villa }

enum UnitStatus { available, reserved, sold, cancelled }

enum InstallmentStatus { pending, partiallyPaid, paid, overdue }

enum PaymentPlanType { cash, installment, custom }

enum NotificationType { installmentDue, overdueInstallment, expenseAdded, paymentReceived, newDeviceLogin, systemAlert }

extension EnumLabelX on Enum {
  String get label {
    final raw = name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    return raw[0].toUpperCase() + raw.substring(1);
  }
}
