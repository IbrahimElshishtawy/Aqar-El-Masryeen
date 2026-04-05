import 'package:aqarelmasryeen/core/utils/firestore_parser.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';

class ExpenseRecord {
  const ExpenseRecord({
    required this.id,
    required this.propertyId,
    required this.amount,
    required this.category,
    required this.description,
    required this.paidByPartnerId,
    required this.paymentMethod,
    required this.date,
    required this.attachmentUrl,
    required this.notes,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
  });

  final String id;
  final String propertyId;
  final double amount;
  final ExpenseCategory category;
  final String description;
  final String paidByPartnerId;
  final PaymentMethod paymentMethod;
  final DateTime date;
  final String? attachmentUrl;
  final String notes;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'amount': amount,
      'category': category.name,
      'description': description,
      'paidByPartnerId': paidByPartnerId,
      'paymentMethod': paymentMethod.name,
      'date': date,
      'attachmentUrl': attachmentUrl,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'archived': archived,
    };
  }

  factory ExpenseRecord.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return ExpenseRecord(
      id: id,
      propertyId: data['propertyId'] as String? ?? '',
      amount: parseDouble(data['amount']),
      category: ExpenseCategory.values.firstWhere(
        (value) => value.name == data['category'],
        orElse: () => ExpenseCategory.other,
      ),
      description: data['description'] as String? ?? '',
      paidByPartnerId: data['paidByPartnerId'] as String? ?? '',
      paymentMethod: PaymentMethod.values.firstWhere(
        (value) => value.name == data['paymentMethod'],
        orElse: () => PaymentMethod.bankTransfer,
      ),
      date: parseDate(data['date']),
      attachmentUrl: data['attachmentUrl'] as String?,
      notes: data['notes'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      archived: data['archived'] as bool? ?? false,
    );
  }

  ExpenseRecord copyWith({
    String? id,
    String? propertyId,
    double? amount,
    ExpenseCategory? category,
    String? description,
    String? paidByPartnerId,
    PaymentMethod? paymentMethod,
    DateTime? date,
    String? attachmentUrl,
    String? notes,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? archived,
  }) {
    return ExpenseRecord(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      paidByPartnerId: paidByPartnerId ?? this.paidByPartnerId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
    );
  }
}

class InstallmentPlan {
  const InstallmentPlan({
    required this.id,
    required this.propertyId,
    required this.unitId,
    required this.installmentCount,
    required this.startDate,
    required this.intervalDays,
    required this.installmentAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  final String id;
  final String propertyId;
  final String unitId;
  final int installmentCount;
  final DateTime startDate;
  final int intervalDays;
  final double installmentAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'unitId': unitId,
      'installmentCount': installmentCount,
      'startDate': startDate,
      'intervalDays': intervalDays,
      'installmentAmount': installmentAmount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  factory InstallmentPlan.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return InstallmentPlan(
      id: id,
      propertyId: data['propertyId'] as String? ?? '',
      unitId: data['unitId'] as String? ?? '',
      installmentCount: parseInt(data['installmentCount']),
      startDate: parseDate(data['startDate']),
      intervalDays: parseInt(data['intervalDays'], fallback: 30),
      installmentAmount: parseDouble(data['installmentAmount']),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
    );
  }

  InstallmentPlan copyWith({
    String? id,
    String? propertyId,
    String? unitId,
    int? installmentCount,
    DateTime? startDate,
    int? intervalDays,
    double? installmentAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return InstallmentPlan(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      installmentCount: installmentCount ?? this.installmentCount,
      startDate: startDate ?? this.startDate,
      intervalDays: intervalDays ?? this.intervalDays,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

class Installment {
  const Installment({
    required this.id,
    required this.planId,
    required this.propertyId,
    required this.unitId,
    required this.sequence,
    required this.amount,
    required this.paidAmount,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    this.notes = '',
  });

  final String id;
  final String planId;
  final String propertyId;
  final String unitId;
  final int sequence;
  final double amount;
  final double paidAmount;
  final DateTime dueDate;
  final InstallmentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final String notes;

  double get remainingAmount => (amount - paidAmount).clamp(0, amount).toDouble();

  bool get isOverdue =>
      remainingAmount > 0 &&
      dueDate.isBefore(DateTime.now()) &&
      status != InstallmentStatus.paid;

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'propertyId': propertyId,
      'unitId': unitId,
      'sequence': sequence,
      'amount': amount,
      'paidAmount': paidAmount,
      'dueDate': dueDate,
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  factory Installment.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return Installment(
      id: id,
      planId: data['planId'] as String? ?? '',
      propertyId: data['propertyId'] as String? ?? '',
      unitId: data['unitId'] as String? ?? '',
      sequence: parseInt(data['sequence']),
      amount: parseDouble(data['amount']),
      paidAmount: parseDouble(data['paidAmount']),
      dueDate: parseDate(data['dueDate']),
      status: InstallmentStatus.values.firstWhere(
        (value) => value.name == data['status'],
        orElse: () => InstallmentStatus.pending,
      ),
      notes: data['notes'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
    );
  }

  Installment copyWith({
    String? id,
    String? planId,
    String? propertyId,
    String? unitId,
    int? sequence,
    double? amount,
    double? paidAmount,
    DateTime? dueDate,
    InstallmentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? notes,
  }) {
    return Installment(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      sequence: sequence ?? this.sequence,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      notes: notes ?? this.notes,
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.propertyId,
    required this.unitId,
    required this.payerName,
    required this.customerName,
    required this.installmentId,
    required this.amount,
    required this.receivedAt,
    required this.paymentMethod,
    required this.paymentSource,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  final String id;
  final String propertyId;
  final String unitId;
  final String payerName;
  final String customerName;
  final String? installmentId;
  final double amount;
  final DateTime receivedAt;
  final PaymentMethod paymentMethod;
  final String paymentSource;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  String get effectivePayerName {
    if (payerName.trim().isNotEmpty) {
      return payerName.trim();
    }
    return customerName.trim();
  }

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'unitId': unitId,
      'payerName': payerName,
      'customerName': customerName,
      'installmentId': installmentId,
      'amount': amount,
      'receivedAt': receivedAt,
      'paymentMethod': paymentMethod.name,
      'paymentSource': paymentSource,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  factory PaymentRecord.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    final payerName = data['payerName'] as String? ?? '';
    final customerName = data['customerName'] as String? ?? '';
    return PaymentRecord(
      id: id,
      propertyId: data['propertyId'] as String? ?? '',
      unitId: data['unitId'] as String? ?? '',
      payerName: payerName,
      customerName: customerName,
      installmentId: data['installmentId'] as String?,
      amount: parseDouble(data['amount']),
      receivedAt: parseDate(data['receivedAt']),
      paymentMethod: PaymentMethod.values.firstWhere(
        (value) => value.name == data['paymentMethod'],
        orElse: () => PaymentMethod.bankTransfer,
      ),
      paymentSource: data['paymentSource'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
    );
  }

  PaymentRecord copyWith({
    String? id,
    String? propertyId,
    String? unitId,
    String? payerName,
    String? customerName,
    String? installmentId,
    double? amount,
    DateTime? receivedAt,
    PaymentMethod? paymentMethod,
    String? paymentSource,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      payerName: payerName ?? this.payerName,
      customerName: customerName ?? this.customerName,
      installmentId: installmentId ?? this.installmentId,
      amount: amount ?? this.amount,
      receivedAt: receivedAt ?? this.receivedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentSource: paymentSource ?? this.paymentSource,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

class MaterialExpenseEntry {
  const MaterialExpenseEntry({
    required this.id,
    required this.propertyId,
    required this.date,
    required this.materialCategory,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.supplierName,
    required this.amountPaid,
    required this.amountRemaining,
    required this.notes,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
    this.dueDate,
  });

  final String id;
  final String propertyId;
  final DateTime date;
  final MaterialCategory materialCategory;
  final String itemName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String supplierName;
  final double amountPaid;
  final double amountRemaining;
  final String notes;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;
  final DateTime? dueDate;

  SupplierInvoiceStatus get status {
    if (amountRemaining <= 0) {
      return SupplierInvoiceStatus.paid;
    }
    if (amountPaid > 0) {
      if (dueDate != null && dueDate!.isBefore(DateTime.now())) {
        return SupplierInvoiceStatus.overdue;
      }
      return SupplierInvoiceStatus.partiallyPaid;
    }
    if (dueDate != null && dueDate!.isBefore(DateTime.now())) {
      return SupplierInvoiceStatus.overdue;
    }
    return SupplierInvoiceStatus.unpaid;
  }

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'date': date,
      'materialCategory': materialCategory.name,
      'itemName': itemName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'supplierName': supplierName,
      'amountPaid': amountPaid,
      'amountRemaining': amountRemaining,
      'dueDate': dueDate,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'archived': archived,
    };
  }

  factory MaterialExpenseEntry.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    final totalPrice = parseDouble(data['totalPrice']);
    final amountPaid = parseDouble(data['amountPaid']);
    return MaterialExpenseEntry(
      id: id,
      propertyId: data['propertyId'] as String? ?? '',
      date: parseDate(data['date']),
      materialCategory: MaterialCategory.values.firstWhere(
        (value) => value.name == data['materialCategory'],
        orElse: () => MaterialCategory.other,
      ),
      itemName: data['itemName'] as String? ?? '',
      quantity: parseDouble(data['quantity']),
      unitPrice: parseDouble(data['unitPrice']),
      totalPrice: totalPrice,
      supplierName: data['supplierName'] as String? ?? '',
      amountPaid: amountPaid,
      amountRemaining: parseDouble(
        data['amountRemaining'],
        fallback: (totalPrice - amountPaid).clamp(0, totalPrice).toDouble(),
      ),
      dueDate: data['dueDate'] == null ? null : parseDate(data['dueDate']),
      notes: data['notes'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      archived: data['archived'] as bool? ?? false,
    );
  }

  MaterialExpenseEntry copyWith({
    String? id,
    String? propertyId,
    DateTime? date,
    MaterialCategory? materialCategory,
    String? itemName,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
    String? supplierName,
    double? amountPaid,
    double? amountRemaining,
    DateTime? dueDate,
    String? notes,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? archived,
  }) {
    return MaterialExpenseEntry(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      date: date ?? this.date,
      materialCategory: materialCategory ?? this.materialCategory,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      supplierName: supplierName ?? this.supplierName,
      amountPaid: amountPaid ?? this.amountPaid,
      amountRemaining: amountRemaining ?? this.amountRemaining,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
    );
  }
}

class PartnerLedgerEntry {
  const PartnerLedgerEntry({
    required this.id,
    required this.partnerId,
    required this.propertyId,
    required this.entryType,
    required this.amount,
    required this.notes,
    required this.authorizedBy,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
  });

  final String id;
  final String partnerId;
  final String propertyId;
  final PartnerLedgerEntryType entryType;
  final double amount;
  final String notes;
  final String authorizedBy;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;

  Map<String, dynamic> toMap() {
    return {
      'partnerId': partnerId,
      'propertyId': propertyId,
      'entryType': entryType.name,
      'amount': amount,
      'notes': notes,
      'authorizedBy': authorizedBy,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'archived': archived,
    };
  }

  factory PartnerLedgerEntry.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return PartnerLedgerEntry(
      id: id,
      partnerId: data['partnerId'] as String? ?? '',
      propertyId: data['propertyId'] as String? ?? '',
      entryType: PartnerLedgerEntryType.values.firstWhere(
        (value) => value.name == data['entryType'],
        orElse: () => PartnerLedgerEntryType.contribution,
      ),
      amount: parseDouble(data['amount']),
      notes: data['notes'] as String? ?? '',
      authorizedBy: data['authorizedBy'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      archived: data['archived'] as bool? ?? false,
    );
  }

  PartnerLedgerEntry copyWith({
    String? id,
    String? partnerId,
    String? propertyId,
    PartnerLedgerEntryType? entryType,
    double? amount,
    String? notes,
    String? authorizedBy,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? archived,
  }) {
    return PartnerLedgerEntry(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      propertyId: propertyId ?? this.propertyId,
      entryType: entryType ?? this.entryType,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      authorizedBy: authorizedBy ?? this.authorizedBy,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.totalProperties,
    required this.totalExpenses,
    required this.totalSalesValue,
    required this.totalCollected,
    required this.totalRemaining,
    required this.overdueInstallmentsCount,
    required this.recentActivityCount,
  });

  final int totalProperties;
  final double totalExpenses;
  final double totalSalesValue;
  final double totalCollected;
  final double totalRemaining;
  final int overdueInstallmentsCount;
  final int recentActivityCount;
}

class PartnerSettlement {
  const PartnerSettlement({
    required this.partnerId,
    required this.partnerName,
    required this.contributedAmount,
    required this.shareRatio,
    required this.expectedContribution,
    required this.balanceDelta,
  });

  final String partnerId;
  final String partnerName;
  final double contributedAmount;
  final double shareRatio;
  final double expectedContribution;
  final double balanceDelta;
}
