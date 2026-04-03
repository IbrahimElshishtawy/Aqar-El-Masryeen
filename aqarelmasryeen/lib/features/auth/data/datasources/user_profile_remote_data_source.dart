import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/app_user.dart';
import 'package:aqarelmasryeen/shared/models/auth_device_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileRemoteDataSource {
  UserProfileRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestorePaths.users);

  Stream<AppUser?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return AppUser.fromMap(uid, snapshot.data());
    });
  }

  Future<AppUser?> fetchProfile(String uid) async {
    final snapshot = await _users.doc(uid).get();
    if (!snapshot.exists) return null;
    return AppUser.fromMap(uid, snapshot.data());
  }

  Future<void> createOrMergeProfile({
    required String uid,
    required String fullName,
    required String email,
    required AuthDeviceInfo deviceInfo,
    bool biometricEnabled = false,
    bool appLockEnabled = true,
    bool trustedDeviceEnabled = false,
    bool isActive = true,
    String role = 'partner',
  }) async {
    final existing = await fetchProfile(uid);
    await _users.doc(uid).set({
      'uid': uid,
      'phone': '',
      'fullName': fullName,
      'name': fullName,
      'email': email,
      'role': role,
      'isActive': isActive,
      'trustedDeviceEnabled': trustedDeviceEnabled,
      'biometricEnabled': biometricEnabled,
      'appLockEnabled': appLockEnabled,
      'inactivityTimeoutSeconds': AppConfig.defaultInactivityTimeoutSeconds,
      'createdAt': existing?.createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'deviceInfo': deviceInfo.toMap(),
      'securitySetupCompletedAt': existing?.securitySetupCompletedAt,
    }, SetOptions(merge: true));
  }

  Future<void> completeProfile({
    required User user,
    required String fullName,
    required String email,
    required AuthDeviceInfo deviceInfo,
  }) {
    return _writeCompletedProfile(
      user: user,
      fullName: fullName,
      email: email,
      deviceInfo: deviceInfo,
    );
  }

  Future<void> _writeCompletedProfile({
    required User user,
    required String fullName,
    required String email,
    required AuthDeviceInfo deviceInfo,
  }) async {
    final existing = await fetchProfile(user.uid);
    return _users.doc(user.uid).set({
      'uid': user.uid,
      'phone': user.phoneNumber ?? '',
      'fullName': fullName,
      'name': fullName,
      'email': email,
      'role': UserRole.partner.name,
      'createdAt': existing?.createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'deviceInfo': deviceInfo.toMap(),
      'isActive': existing?.isActive ?? true,
      'trustedDeviceEnabled': existing?.trustedDeviceEnabled ?? false,
      'biometricEnabled': existing?.biometricEnabled ?? false,
      'appLockEnabled': existing?.appLockEnabled ?? true,
      'inactivityTimeoutSeconds':
          existing?.inactivityTimeoutSeconds ??
          AppConfig.defaultInactivityTimeoutSeconds,
      'securitySetupCompletedAt': existing?.securitySetupCompletedAt,
    }, SetOptions(merge: true));
  }

  Future<void> updateSecurityPreferences({
    required String uid,
    required bool trustedDeviceEnabled,
    required bool biometricEnabled,
    required bool appLockEnabled,
    required int inactivityTimeoutSeconds,
    required AuthDeviceInfo deviceInfo,
  }) {
    return _users.doc(uid).set({
      'trustedDeviceEnabled': trustedDeviceEnabled,
      'biometricEnabled': biometricEnabled,
      'appLockEnabled': appLockEnabled,
      'inactivityTimeoutSeconds': inactivityTimeoutSeconds,
      'deviceInfo': deviceInfo.toMap(),
      'securitySetupCompletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> touchLogin({
    required String uid,
    required AuthDeviceInfo deviceInfo,
  }) {
    return _users.doc(uid).set({
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'deviceInfo': deviceInfo.toMap(),
    }, SetOptions(merge: true));
  }

  Future<void> setBiometricPreference({
    required String uid,
    required bool biometricEnabled,
  }) {
    return _users.doc(uid).set({
      'biometricEnabled': biometricEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
