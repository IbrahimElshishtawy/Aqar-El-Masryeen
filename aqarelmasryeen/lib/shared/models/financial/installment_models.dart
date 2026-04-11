import 'package:aqarelmasryeen/core/utils/firestore_parser.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';

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
    this.workspaceId = '',
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
  final String workspaceId;

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
      'workspaceId': workspaceId,
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
      workspaceId: data['workspaceId'] as String? ?? '',
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
    String? workspaceId,
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
      workspaceId: workspaceId ?? this.workspaceId,
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
    this.workspaceId = '',
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
  final String workspaceId;

  double get remainingAmount =>
      (amount - paidAmount).clamp(0, amount).toDouble();

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
      'workspaceId': workspaceId,
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
      workspaceId: data['workspaceId'] as String? ?? '',
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
    String? workspaceId,
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
      workspaceId: workspaceId ?? this.workspaceId,
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
    this.workspaceId = '',
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
  final String workspaceId;

  String get effectivePayerName {
    if (payerName.trim().isNotEmpty) {
      return payerName.trim();
    }
    return customerName.trim();
  }

  String get paymentTypeLabel {
    final normalizedSource = paymentSource.trim();
    if (normalizedSource.isNotEmpty) {
      return normalizedSource;
    }
    if (installmentId != null && installmentId!.trim().isNotEmpty) {
      return 'دفعة قسط';
    }
    return 'دفعة';
  }

  bool get isDownPayment => paymentTypeLabel == 'مقدم';

  bool get isInstallmentPayment =>
      installmentId != null && installmentId!.trim().isNotEmpty;

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
      'workspaceId': workspaceId,
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
      workspaceId: data['workspaceId'] as String? ?? '',
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
    String? workspaceId,
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
      workspaceId: workspaceId ?? this.workspaceId,
    );
  }
}
