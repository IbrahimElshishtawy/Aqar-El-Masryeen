import 'package:aqarelmasryeen/core/utils/firestore_parser.dart';

class UnitExpenseRecord {
  const UnitExpenseRecord({
    required this.id,
    required this.propertyId,
    required this.unitId,
    required this.amount,
    required this.description,
    required this.paidByPartnerId,
    required this.date,
    required this.notes,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
  });

  final String id;
  final String propertyId;
  final String unitId;
  final double amount;
  final String description;
  final String paidByPartnerId;
  final DateTime date;
  final String notes;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'unitId': unitId,
      'amount': amount,
      'description': description,
      'paidByPartnerId': paidByPartnerId,
      'date': date,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'archived': archived,
    };
  }

  factory UnitExpenseRecord.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return UnitExpenseRecord(
      id: id,
      propertyId: data['propertyId'] as String? ?? '',
      unitId: data['unitId'] as String? ?? '',
      amount: parseDouble(data['amount']),
      description: data['description'] as String? ?? '',
      paidByPartnerId: data['paidByPartnerId'] as String? ?? '',
      date: parseDate(data['date']),
      notes: data['notes'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      archived: data['archived'] as bool? ?? false,
    );
  }

  UnitExpenseRecord copyWith({
    String? id,
    String? propertyId,
    String? unitId,
    double? amount,
    String? description,
    String? paidByPartnerId,
    DateTime? date,
    String? notes,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? archived,
  }) {
    return UnitExpenseRecord(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      paidByPartnerId: paidByPartnerId ?? this.paidByPartnerId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
    );
  }
}
