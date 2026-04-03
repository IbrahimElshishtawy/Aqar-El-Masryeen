import 'package:aqarelmasryeen/core/utils/firestore_parser.dart';
import 'package:aqarelmasryeen/shared/models/auth_device_info.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.phone,
    required this.fullName,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLoginAt,
    required this.role,
    required this.trustedDeviceEnabled,
    required this.biometricEnabled,
    required this.appLockEnabled,
    required this.inactivityTimeoutSeconds,
    required this.deviceInfo,
    required this.isActive,
    required this.securitySetupCompletedAt,
  });

  final String uid;
  final String phone;
  final String fullName;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final UserRole role;
  final bool trustedDeviceEnabled;
  final bool biometricEnabled;
  final bool appLockEnabled;
  final int inactivityTimeoutSeconds;
  final AuthDeviceInfo? deviceInfo;
  final bool isActive;
  final DateTime? securitySetupCompletedAt;

  String get id => uid;

  String get name => fullName;

  bool get isProfileComplete =>
      fullName.trim().isNotEmpty && email.trim().isNotEmpty;

  bool get isSecuritySetupComplete => securitySetupCompletedAt != null;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'fullName': fullName,
      'name': fullName,
      'email': email,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastLoginAt': lastLoginAt,
      'role': role.name,
      'trustedDeviceEnabled': trustedDeviceEnabled,
      'biometricEnabled': biometricEnabled,
      'appLockEnabled': appLockEnabled,
      'inactivityTimeoutSeconds': inactivityTimeoutSeconds,
      'deviceInfo': deviceInfo?.toMap(),
      'isActive': isActive,
      'securitySetupCompletedAt': securitySetupCompletedAt,
    };
  }

  factory AppUser.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    final createdAt = parseDate(data['createdAt'], fallback: DateTime.now());
    final updatedAt = parseDate(data['updatedAt'], fallback: createdAt);
    return AppUser(
      uid: data['uid'] as String? ?? id,
      phone: data['phone'] as String? ?? '',
      fullName: data['fullName'] as String? ?? data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: data['lastLoginAt'] == null
          ? null
          : parseDate(data['lastLoginAt'], fallback: updatedAt),
      role: UserRole.values.firstWhere(
        (value) => value.name == data['role'],
        orElse: () => UserRole.partner,
      ),
      trustedDeviceEnabled: data['trustedDeviceEnabled'] as bool? ?? false,
      biometricEnabled: data['biometricEnabled'] as bool? ?? false,
      appLockEnabled: data['appLockEnabled'] as bool? ?? true,
      inactivityTimeoutSeconds: data['inactivityTimeoutSeconds'] as int? ?? 90,
      deviceInfo: data['deviceInfo'] is Map<String, dynamic>
          ? AuthDeviceInfo.fromMap(data['deviceInfo'] as Map<String, dynamic>)
          : null,
      isActive: data['isActive'] as bool? ?? true,
      securitySetupCompletedAt: data['securitySetupCompletedAt'] == null
          ? null
          : parseDate(data['securitySetupCompletedAt']),
    );
  }

  AppUser copyWith({
    String? uid,
    String? phone,
    String? fullName,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    UserRole? role,
    bool? trustedDeviceEnabled,
    bool? biometricEnabled,
    bool? appLockEnabled,
    int? inactivityTimeoutSeconds,
    AuthDeviceInfo? deviceInfo,
    bool? isActive,
    DateTime? securitySetupCompletedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      role: role ?? this.role,
      trustedDeviceEnabled: trustedDeviceEnabled ?? this.trustedDeviceEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      inactivityTimeoutSeconds:
          inactivityTimeoutSeconds ?? this.inactivityTimeoutSeconds,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      isActive: isActive ?? this.isActive,
      securitySetupCompletedAt:
          securitySetupCompletedAt ?? this.securitySetupCompletedAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    phone,
    fullName,
    email,
    createdAt,
    updatedAt,
    lastLoginAt,
    role,
    trustedDeviceEnabled,
    biometricEnabled,
    appLockEnabled,
    inactivityTimeoutSeconds,
    deviceInfo,
    isActive,
    securitySetupCompletedAt,
  ];
}
