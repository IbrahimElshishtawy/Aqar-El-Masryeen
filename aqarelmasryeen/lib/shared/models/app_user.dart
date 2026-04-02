import 'package:aqarelmasryeen/core/utils/firestore_parser.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLoginAt,
    required this.role,
    required this.biometricEnabled,
    required this.trustedDevices,
  });

  final String id;
  final String phone;
  final String name;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final UserRole role;
  final bool biometricEnabled;
  final List<String> trustedDevices;

  bool get isProfileComplete =>
      name.trim().isNotEmpty && email.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'name': name,
      'email': email,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastLoginAt': lastLoginAt,
      'role': role.name,
      'biometricEnabled': biometricEnabled,
      'trustedDevices': trustedDevices,
    };
  }

  factory AppUser.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return AppUser(
      id: id,
      phone: data['phone'] as String? ?? '',
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      lastLoginAt: data['lastLoginAt'] == null
          ? null
          : parseDate(data['lastLoginAt']),
      role: UserRole.values.firstWhere(
        (value) => value.name == data['role'],
        orElse: () => UserRole.partner,
      ),
      biometricEnabled: data['biometricEnabled'] as bool? ?? false,
      trustedDevices: (data['trustedDevices'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}
