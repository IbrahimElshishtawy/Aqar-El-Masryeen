import 'package:aqarelmasryeen/core/utils/firestore_parser.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';

class PropertyProject {
  const PropertyProject({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.status,
    required this.totalBudget,
    required this.totalSalesTarget,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.archived,
  });

  final String id;
  final String name;
  final String location;
  final String description;
  final PropertyStatus status;
  final double totalBudget;
  final double totalSalesTarget;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final bool archived;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'description': description,
      'status': status.name,
      'totalBudget': totalBudget,
      'totalSalesTarget': totalSalesTarget,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'archived': archived,
    };
  }

  factory PropertyProject.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return PropertyProject(
      id: id,
      name: data['name'] as String? ?? '',
      location: data['location'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: PropertyStatus.values.firstWhere(
        (value) => value.name == data['status'],
        orElse: () => PropertyStatus.active,
      ),
      totalBudget: parseDouble(data['totalBudget']),
      totalSalesTarget: parseDouble(data['totalSalesTarget']),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
      archived: data['archived'] as bool? ?? false,
    );
  }

  PropertyProject copyWith({
    String? id,
    String? name,
    String? location,
    String? description,
    PropertyStatus? status,
    double? totalBudget,
    double? totalSalesTarget,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    bool? archived,
  }) {
    return PropertyProject(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      description: description ?? this.description,
      status: status ?? this.status,
      totalBudget: totalBudget ?? this.totalBudget,
      totalSalesTarget: totalSalesTarget ?? this.totalSalesTarget,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      archived: archived ?? this.archived,
    );
  }
}

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
    required this.saleAmount,
    required this.totalPrice,
    required this.contractAmount,
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
  final double saleAmount;
  final double totalPrice;
  final double contractAmount;
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
  final DateTime? projectedCompletionDate;

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'unitNumber': unitNumber,
      'floor': floor,
      'unitType': unitType.name,
      'area': area,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'saleAmount': saleAmount,
      'totalPrice': totalPrice,
      'contractAmount': contractAmount,
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
    };
  }

  factory UnitSale.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    final fallbackSaleAmount = parseDouble(
      data['saleAmount'] ?? data['totalPrice'],
    );
    final contractAmount = parseDouble(
      data['contractAmount'] ?? data['totalPrice'] ?? data['saleAmount'],
    );
    final downPayment = parseDouble(data['downPayment']);
    final remainingAmount = parseDouble(
      data['remainingAmount'],
      fallback: (contractAmount - downPayment)
          .clamp(0, contractAmount)
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
      saleAmount: fallbackSaleAmount,
      totalPrice: parseDouble(data['totalPrice'], fallback: contractAmount),
      contractAmount: contractAmount,
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
    double? saleAmount,
    double? totalPrice,
    double? contractAmount,
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
      saleAmount: saleAmount ?? this.saleAmount,
      totalPrice: totalPrice ?? this.totalPrice,
      contractAmount: contractAmount ?? this.contractAmount,
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
      projectedCompletionDate:
          projectedCompletionDate ?? this.projectedCompletionDate,
    );
  }
}

class PropertyStorageFile {
  const PropertyStorageFile({
    required this.name,
    required this.fullPath,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.updatedAt,
    required this.contentType,
  });

  final String name;
  final String fullPath;
  final String downloadUrl;
  final int sizeBytes;
  final DateTime? updatedAt;
  final String? contentType;
}
