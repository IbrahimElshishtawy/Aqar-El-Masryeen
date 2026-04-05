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

  double get remainingAmount => amount - paidAmount;

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
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.propertyId,
    required this.unitId,
    this.customerName = '',
    required this.installmentId,
    required this.amount,
    required this.receivedAt,
    required this.paymentMethod,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  final String id;
  final String propertyId;
  final String unitId;
  final String customerName;
  final String? installmentId;
  final double amount;
  final DateTime receivedAt;
  final PaymentMethod paymentMethod;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'unitId': unitId,
      'customerName': customerName,
      'installmentId': installmentId,
      'amount': amount,
      'receivedAt': receivedAt,
      'paymentMethod': paymentMethod.name,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  factory PaymentRecord.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return PaymentRecord(
      id: id,
      propertyId: data['propertyId'] as String? ?? '',
      unitId: data['unitId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      installmentId: data['installmentId'] as String?,
      amount: parseDouble(data['amount']),
      receivedAt: parseDate(data['receivedAt']),
      paymentMethod: PaymentMethod.values.firstWhere(
        (value) => value.name == data['paymentMethod'],
        orElse: () => PaymentMethod.bankTransfer,
      ),
      notes: data['notes'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
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
