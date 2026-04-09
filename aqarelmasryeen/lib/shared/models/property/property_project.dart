import 'package:aqarelmasryeen/core/utils/firestore_parser.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';

class PropertyProject {
  const PropertyProject({
    required this.id,
    required this.name,
    required this.location,
    required int apartmentCount,
    required this.description,
    required this.status,
    required this.totalBudget,
    required this.totalSalesTarget,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.archived,
  }) : _apartmentCount = apartmentCount;

  final String id;
  final String name;
  final String location;
  final int? _apartmentCount;
  final String description;
  final PropertyStatus status;
  final double totalBudget;
  final double totalSalesTarget;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final bool archived;

  int get apartmentCount => _apartmentCount ?? 0;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'apartmentCount': apartmentCount,
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
      apartmentCount: (data['apartmentCount'] as num?)?.toInt() ?? 0,
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
    int? apartmentCount,
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
      apartmentCount: apartmentCount ?? this.apartmentCount,
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
