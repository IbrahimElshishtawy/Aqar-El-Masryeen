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
