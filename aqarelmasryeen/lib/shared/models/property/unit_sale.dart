import 'package:aqarelmasryeen/core/utils/firestore_parser.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';

class UnitSale {
  const UnitSale({
    required this.id,
    required this.propertyId,
    required this.unitNumber,
    required this.floor,
    required this.unitType,
    required this.area,
    required this.customerName,
    required this.customerPhone,
    required this.apartmentPrice,
    required this.downPayment,
    required this.remainingAmount,
    required this.installmentScheduleCount,
    required this.paymentPlanType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    this.notes = '',
    this.workspaceId = '',
    this.projectedCompletionDate,
  });

  final String id;
  final String propertyId;
  final String unitNumber;
  final int floor;
  final UnitType unitType;
  final double area;
  final String customerName;
  final String customerPhone;
  final double apartmentPrice;
  final double downPayment;
  final double remainingAmount;
  final int installmentScheduleCount;
  final PaymentPlanType paymentPlanType;
  final UnitStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final String notes;
  final String workspaceId;
  final DateTime? projectedCompletionDate;

  double get saleAmount => apartmentPrice;

  double get totalPrice => apartmentPrice;

  double get contractAmount => apartmentPrice;

  bool get hasRecordedSale {
    final hasCustomer = customerName.trim().isNotEmpty;
    final hasFinancialActivity =
        downPayment > 0 ||
        installmentScheduleCount > 0 ||
        remainingAmount < apartmentPrice;
    return apartmentPrice > 0 &&
        status != UnitStatus.cancelled &&
        (status == UnitStatus.sold || hasCustomer || hasFinancialActivity);
  }

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'unitNumber': unitNumber,
      'floor': floor,
      'unitType': unitType.name,
      'area': area,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'apartmentPrice': apartmentPrice,
      'saleAmount': apartmentPrice,
      'totalPrice': apartmentPrice,
      'contractAmount': apartmentPrice,
      'downPayment': downPayment,
      'remainingAmount': remainingAmount,
      'installmentScheduleCount': installmentScheduleCount,
      'paymentPlanType': paymentPlanType.name,
      'status': status.name,
      'notes': notes,
      'projectedCompletionDate': projectedCompletionDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'workspaceId': workspaceId,
    };
  }

  factory UnitSale.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    final apartmentPrice = parseDouble(
      data['apartmentPrice'] ??
          data['contractAmount'] ??
          data['totalPrice'] ??
          data['saleAmount'],
    );
    final downPayment = parseDouble(data['downPayment']);
    final remainingAmount = parseDouble(
      data['remainingAmount'],
      fallback: (apartmentPrice - downPayment)
          .clamp(0, apartmentPrice)
          .toDouble(),
    );

    return UnitSale(
      id: id,
      propertyId: data['propertyId'] as String? ?? '',
      unitNumber: data['unitNumber'] as String? ?? '',
      floor: parseInt(data['floor']),
      unitType: UnitType.values.firstWhere(
        (value) => value.name == data['unitType'],
        orElse: () => UnitType.apartment,
      ),
      area: parseDouble(data['area']),
      customerName: data['customerName'] as String? ?? '',
      customerPhone: data['customerPhone'] as String? ?? '',
      apartmentPrice: apartmentPrice,
      downPayment: downPayment,
      remainingAmount: remainingAmount,
      installmentScheduleCount: parseInt(data['installmentScheduleCount']),
      paymentPlanType: PaymentPlanType.values.firstWhere(
        (value) => value.name == data['paymentPlanType'],
        orElse: () => PaymentPlanType.installment,
      ),
      status: UnitStatus.values.firstWhere(
        (value) => value.name == data['status'],
        orElse: () => UnitStatus.available,
      ),
      notes: data['notes'] as String? ?? '',
      projectedCompletionDate: data['projectedCompletionDate'] == null
          ? null
          : parseDate(data['projectedCompletionDate']),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
      workspaceId: data['workspaceId'] as String? ?? '',
    );
  }

  UnitSale copyWith({
    String? id,
    String? propertyId,
    String? unitNumber,
    int? floor,
    UnitType? unitType,
    double? area,
    String? customerName,
    String? customerPhone,
    double? apartmentPrice,
    double? downPayment,
    double? remainingAmount,
    int? installmentScheduleCount,
    PaymentPlanType? paymentPlanType,
    UnitStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? notes,
    String? workspaceId,
    DateTime? projectedCompletionDate,
  }) {
    return UnitSale(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitNumber: unitNumber ?? this.unitNumber,
      floor: floor ?? this.floor,
      unitType: unitType ?? this.unitType,
      area: area ?? this.area,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      apartmentPrice: apartmentPrice ?? this.apartmentPrice,
      downPayment: downPayment ?? this.downPayment,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      installmentScheduleCount:
          installmentScheduleCount ?? this.installmentScheduleCount,
      paymentPlanType: paymentPlanType ?? this.paymentPlanType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      notes: notes ?? this.notes,
      workspaceId: workspaceId ?? this.workspaceId,
      projectedCompletionDate:
          projectedCompletionDate ?? this.projectedCompletionDate,
    );
  }
}
