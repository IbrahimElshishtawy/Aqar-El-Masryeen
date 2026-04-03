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

  Future<AppUser?> findByPhone(String phone) async {
    final query = await _users.where('phone', isEqualTo: phone).limit(1).get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return AppUser.fromMap(doc.id, doc.data());
  }

  Future<void> ensurePlaceholderProfile({
    required User user,
    required AuthDeviceInfo deviceInfo,
  }) async {
    final now = DateTime.now();
    final existing = await fetchProfile(user.uid);
    if (existing != null) {
      await _users.doc(user.uid).set({
        'uid': user.uid,
        'phone': user.phoneNumber ?? existing.phone,
        'updatedAt': now,
        'lastLoginAt': now,
        'deviceInfo': deviceInfo.toMap(),
      }, SetOptions(merge: true));
      return;
    }

    await _users.doc(user.uid).set({
      'uid': user.uid,
      'phone': user.phoneNumber ?? '',
      'fullName': user.displayName ?? '',
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'role': UserRole.partner.name,
      'createdAt': now,
      'updatedAt': now,
      'lastLoginAt': now,
      'trustedDeviceEnabled': false,
      'biometricEnabled': false,
      'appLockEnabled': true,
      'inactivityTimeoutSeconds': AppConfig.defaultInactivityTimeoutSeconds,
      'deviceInfo': deviceInfo.toMap(),
      'isActive': true,
      'securitySetupCompletedAt': null,
    });
  }

  Future<void> completeProfile({
    required User user,
    required String fullName,
    required String email,
    required AuthDeviceInfo deviceInfo,
  }) {
    final now = DateTime.now();
    return _users.doc(user.uid).set({
      'uid': user.uid,
      'phone': user.phoneNumber ?? '',
      'fullName': fullName,
      'name': fullName,
      'email': email,
      'role': UserRole.partner.name,
      'updatedAt': now,
      'lastLoginAt': now,
      'deviceInfo': deviceInfo.toMap(),
      'isActive': true,
      'trustedDeviceEnabled': false,
      'biometricEnabled': false,
      'appLockEnabled': true,
      'inactivityTimeoutSeconds': AppConfig.defaultInactivityTimeoutSeconds,
      'createdAt': FieldValue.serverTimestamp(),
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
      'securitySetupCompletedAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    }, SetOptions(merge: true));
  }

  Future<void> touchLogin({
    required String uid,
    required AuthDeviceInfo deviceInfo,
  }) {
    return _users.doc(uid).set({
      'lastLoginAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'deviceInfo': deviceInfo.toMap(),
    }, SetOptions(merge: true));
  }

  Future<void> setBiometricPreference({
    required String uid,
    required bool biometricEnabled,
  }) {
    return _users.doc(uid).set({
      'biometricEnabled': biometricEnabled,
      'updatedAt': DateTime.now(),
    }, SetOptions(merge: true));
  }
}
