import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/utils/firestore_parser.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/auth_device_info.dart';
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
    this.createdBy = '',
    this.createdByName = '',
    this.workspaceId = AppConfig.defaultWorkspaceId,
    this.linkedPartnerId = '',
    this.linkedPartnerName = '',
    this.fcmTokens = const [],
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
  final String createdBy;
  final String createdByName;
  final String workspaceId;
  final String linkedPartnerId;
  final String linkedPartnerName;
  final List<String> fcmTokens;

  String get id => uid;

  String get name => fullName;

  bool get isProfileComplete =>
      fullName.trim().isNotEmpty && email.trim().isNotEmpty;

  bool get isSecuritySetupComplete => securitySetupCompletedAt != null;

  bool get isLinkedToPartner => linkedPartnerId.trim().isNotEmpty;

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
      'createdBy': createdBy,
      'createdByName': createdByName,
      'workspaceId': workspaceId,
      'linkedPartnerId': linkedPartnerId,
      'linkedPartnerName': linkedPartnerName,
      'fcmTokens': fcmTokens,
    };
  }

  factory AppUser.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    final createdAt = parseDate(data['createdAt'], fallback: DateTime.now());
    final updatedAt = parseDate(data['updatedAt'], fallback: createdAt);
    final createdBy = data['createdBy'] as String? ?? id;
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
      createdBy: createdBy,
      createdByName: data['createdByName'] as String? ?? '',
      workspaceId:
          data['workspaceId'] as String? ?? AppConfig.defaultWorkspaceId,
      linkedPartnerId: data['linkedPartnerId'] as String? ?? '',
      linkedPartnerName: data['linkedPartnerName'] as String? ?? '',
      fcmTokens: (data['fcmTokens'] as List<dynamic>? ?? const [])
          .map((value) => '$value'.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
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
    String? createdBy,
    String? createdByName,
    String? workspaceId,
    String? linkedPartnerId,
    String? linkedPartnerName,
    List<String>? fcmTokens,
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
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      workspaceId: workspaceId ?? this.workspaceId,
      linkedPartnerId: linkedPartnerId ?? this.linkedPartnerId,
      linkedPartnerName: linkedPartnerName ?? this.linkedPartnerName,
      fcmTokens: fcmTokens ?? this.fcmTokens,
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
    createdBy,
    createdByName,
    workspaceId,
    linkedPartnerId,
    linkedPartnerName,
    fcmTokens,
  ];
}
