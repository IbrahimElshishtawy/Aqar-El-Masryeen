import 'package:aqarelmasryeen/data/models/app_role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.assignedProperties,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.notes,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final AppRole role;
  final List<String> assignedProperties;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    AppRole? role,
    List<String>? assignedProperties,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      assignedProperties: assignedProperties ?? this.assignedProperties,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'role': role.key,
      'assignedProperties': assignedProperties,
      'isActive': isActive,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String?,
      role: AppRole.fromKey(map['role'] as String?),
      assignedProperties:
          List<String>.from(map['assignedProperties'] as List<dynamic>? ?? []),
      isActive: map['isActive'] as bool? ?? true,
      notes: map['notes'] as String?,
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }
}
