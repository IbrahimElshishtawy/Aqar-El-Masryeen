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
    required this.totalPrice,
    required this.downPayment,
    required this.remainingAmount,
    required this.paymentPlanType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  final String id;
  final String propertyId;
  final String unitNumber;
  final int floor;
  final UnitType unitType;
  final double area;
  final String customerName;
  final String customerPhone;
  final double totalPrice;
  final double downPayment;
  final double remainingAmount;
  final PaymentPlanType paymentPlanType;
  final UnitStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'unitNumber': unitNumber,
      'floor': floor,
      'unitType': unitType.name,
      'area': area,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'totalPrice': totalPrice,
      'downPayment': downPayment,
      'remainingAmount': remainingAmount,
      'paymentPlanType': paymentPlanType.name,
      'status': status.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  factory UnitSale.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
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
      totalPrice: parseDouble(data['totalPrice']),
      downPayment: parseDouble(data['downPayment']),
      remainingAmount: parseDouble(data['remainingAmount']),
      paymentPlanType: PaymentPlanType.values.firstWhere(
        (value) => value.name == data['paymentPlanType'],
        orElse: () => PaymentPlanType.installment,
      ),
      status: UnitStatus.values.firstWhere(
        (value) => value.name == data['status'],
        orElse: () => UnitStatus.available,
      ),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
    );
  }
}
