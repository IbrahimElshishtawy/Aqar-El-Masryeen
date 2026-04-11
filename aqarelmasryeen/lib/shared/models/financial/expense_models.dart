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
    this.workspaceId = '',
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
  final String workspaceId;

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
      'workspaceId': workspaceId,
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
      workspaceId: data['workspaceId'] as String? ?? '',
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
    String? workspaceId,
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
      workspaceId: workspaceId ?? this.workspaceId,
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
    required this.initialPaidAmount,
    required this.initialPaidByPartnerId,
    required this.initialPaidByLabel,
    required this.amountPaid,
    required this.amountRemaining,
    required this.notes,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
    this.workspaceId = '',
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
  final double initialPaidAmount;
  final String initialPaidByPartnerId;
  final String initialPaidByLabel;
  final double amountPaid;
  final double amountRemaining;
  final String notes;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;
  final String workspaceId;
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
      'initialPaidAmount': initialPaidAmount,
      'initialPaidByPartnerId': initialPaidByPartnerId,
      'initialPaidByLabel': initialPaidByLabel,
      'amountPaid': amountPaid,
      'amountRemaining': amountRemaining,
      'dueDate': dueDate,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'archived': archived,
      'workspaceId': workspaceId,
    };
  }

  factory MaterialExpenseEntry.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    final totalPrice = parseDouble(data['totalPrice']);
    final amountPaid = parseDouble(data['amountPaid']);
    final initialPaidAmount = parseDouble(
      data['initialPaidAmount'],
      fallback: amountPaid.clamp(0, totalPrice).toDouble(),
    );
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
      initialPaidAmount: initialPaidAmount,
      initialPaidByPartnerId: data['initialPaidByPartnerId'] as String? ?? '',
      initialPaidByLabel: data['initialPaidByLabel'] as String? ?? '',
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
      workspaceId: data['workspaceId'] as String? ?? '',
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
    double? initialPaidAmount,
    String? initialPaidByPartnerId,
    String? initialPaidByLabel,
    double? amountPaid,
    double? amountRemaining,
    DateTime? dueDate,
    String? notes,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? archived,
    String? workspaceId,
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
      initialPaidAmount: initialPaidAmount ?? this.initialPaidAmount,
      initialPaidByPartnerId:
          initialPaidByPartnerId ?? this.initialPaidByPartnerId,
      initialPaidByLabel: initialPaidByLabel ?? this.initialPaidByLabel,
      amountPaid: amountPaid ?? this.amountPaid,
      amountRemaining: amountRemaining ?? this.amountRemaining,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
      workspaceId: workspaceId ?? this.workspaceId,
    );
  }
}

class SupplierPaymentRecord {
  const SupplierPaymentRecord({
    required this.id,
    required this.propertyId,
    required this.supplierName,
    required this.amount,
    required this.paidAt,
    required this.paidByPartnerId,
    required this.paidByLabel,
    required this.notes,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
    this.workspaceId = '',
  });

  final String id;
  final String propertyId;
  final String supplierName;
  final double amount;
  final DateTime paidAt;
  final String paidByPartnerId;
  final String paidByLabel;
  final String notes;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;
  final String workspaceId;

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'supplierName': supplierName,
      'amount': amount,
      'paidAt': paidAt,
      'paidByPartnerId': paidByPartnerId,
      'paidByLabel': paidByLabel,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'archived': archived,
      'workspaceId': workspaceId,
    };
  }

  factory SupplierPaymentRecord.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return SupplierPaymentRecord(
      id: id,
      propertyId: data['propertyId'] as String? ?? '',
      supplierName: data['supplierName'] as String? ?? '',
      amount: parseDouble(data['amount']),
      paidAt: parseDate(data['paidAt']),
      paidByPartnerId: data['paidByPartnerId'] as String? ?? '',
      paidByLabel: data['paidByLabel'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      archived: data['archived'] as bool? ?? false,
      workspaceId: data['workspaceId'] as String? ?? '',
    );
  }

  SupplierPaymentRecord copyWith({
    String? id,
    String? propertyId,
    String? supplierName,
    double? amount,
    DateTime? paidAt,
    String? paidByPartnerId,
    String? paidByLabel,
    String? notes,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? archived,
    String? workspaceId,
  }) {
    return SupplierPaymentRecord(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      supplierName: supplierName ?? this.supplierName,
      amount: amount ?? this.amount,
      paidAt: paidAt ?? this.paidAt,
      paidByPartnerId: paidByPartnerId ?? this.paidByPartnerId,
      paidByLabel: paidByLabel ?? this.paidByLabel,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
      workspaceId: workspaceId ?? this.workspaceId,
    );
  }
}
