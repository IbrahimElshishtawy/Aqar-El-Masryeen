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
  CollectionReference<Map<String, dynamic>> get _userEmailLookup =>
      _firestore.collection(FirestorePaths.userEmailLookup);

  Stream<AppUser?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return AppUser.fromMap(uid, snapshot.data());
    });
  }

  Stream<List<AppUser>> watchAllProfiles() {
    return _users.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => AppUser.fromMap(doc.id, doc.data()))
          .toList(growable: false),
    );
  }

  Stream<List<AppUser>> watchProfilesByWorkspace(String workspaceId) {
    final normalizedWorkspaceId = workspaceId.trim();
    if (normalizedWorkspaceId.isEmpty) {
      return Stream.value(const <AppUser>[]);
    }

    return _users
        .where('workspaceId', isEqualTo: normalizedWorkspaceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  Future<AppUser?> fetchProfile(String uid) async {
    final snapshot = await _users.doc(uid).get();
    if (!snapshot.exists) return null;
    return AppUser.fromMap(uid, snapshot.data());
  }

  Future<String?> fetchUserIdByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return null;
    }

    final snapshot = await _userEmailLookup.doc(normalizedEmail).get();
    if (!snapshot.exists) {
      return null;
    }
    final data = snapshot.data();
    final uid = data?['uid'] as String? ?? '';
    return uid.isEmpty ? null : uid;
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
    bool updateLastLoginAt = true,
    String? createdBy,
    String? createdByName,
    String? workspaceId,
    String? linkedPartnerId,
    String? linkedPartnerName,
  }) async {
    final existing = await _tryFetchProfile(uid);
    final resolvedWorkspaceId = _resolveWorkspaceId(
      requested: workspaceId,
      existing: existing?.workspaceId,
      fallbackUid: uid,
    );
    final resolvedCreatedBy = _resolveCreatedBy(
      requested: createdBy,
      existing: existing?.createdBy,
      fallback: uid,
    );
    final resolvedCreatedByName =
        (existing?.createdByName.trim().isNotEmpty == true
        ? existing!.createdByName
        : (createdByName?.trim().isNotEmpty == true
              ? createdByName!.trim()
              : fullName.trim()));

    final data = <String, dynamic>{
      'uid': uid,
      'phone': existing?.phone ?? '',
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
      'deviceInfo': deviceInfo.toMap(),
      'securitySetupCompletedAt': existing?.securitySetupCompletedAt,
      'createdBy': resolvedCreatedBy,
      'createdByName': resolvedCreatedByName,
      'workspaceId': resolvedWorkspaceId,
      'linkedPartnerId': linkedPartnerId ?? existing?.linkedPartnerId ?? '',
      'linkedPartnerName':
          linkedPartnerName ?? existing?.linkedPartnerName ?? '',
    };

    if (updateLastLoginAt) {
      data['lastLoginAt'] = FieldValue.serverTimestamp();
    } else if (existing?.lastLoginAt != null) {
      data['lastLoginAt'] = existing!.lastLoginAt;
    }

    await _writeProfile(uid: uid, previousEmail: existing?.email, data: data);
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

  Future<void> setPartnerLink({
    required String uid,
    required String partnerId,
    required String partnerName,
    String? workspaceId,
  }) async {
    final existing = await fetchProfile(uid);
    final resolvedWorkspaceId = _resolveWorkspaceId(
      requested: workspaceId,
      existing: existing?.workspaceId,
      fallbackUid: uid,
    );
    return _users.doc(uid).set({
      'linkedPartnerId': partnerId,
      'linkedPartnerName': partnerName,
      'workspaceId': resolvedWorkspaceId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateAccountLinkage({
    required String uid,
    required String workspaceId,
    String? linkedPartnerId,
    String? linkedPartnerName,
    String? createdBy,
  }) async {
    final existing = await fetchProfile(uid);
    final resolvedWorkspaceId = _resolveWorkspaceId(
      requested: workspaceId,
      existing: existing?.workspaceId,
      fallbackUid: uid,
    );
    final resolvedCreatedBy = _resolveCreatedBy(
      requested: createdBy,
      existing: existing?.createdBy,
      fallback: uid,
    );

    await _users.doc(uid).set({
      'workspaceId': resolvedWorkspaceId,
      'linkedPartnerId': linkedPartnerId ?? existing?.linkedPartnerId ?? '',
      'linkedPartnerName':
          linkedPartnerName ?? existing?.linkedPartnerName ?? '',
      'createdBy': resolvedCreatedBy,
      'createdAt': existing?.createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> clearPartnerLink(String uid, {String? expectedPartnerId}) async {
    if (expectedPartnerId?.trim().isNotEmpty == true) {
      final existing = await fetchProfile(uid);
      if (existing == null || existing.linkedPartnerId != expectedPartnerId) {
        return;
      }
    }

    await _users.doc(uid).set({
      'linkedPartnerId': '',
      'linkedPartnerName': '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _writeCompletedProfile({
    required User user,
    required String fullName,
    required String email,
    required AuthDeviceInfo deviceInfo,
  }) async {
    final existing = await _tryFetchProfile(user.uid);
    return _writeProfile(
      uid: user.uid,
      previousEmail: existing?.email,
      data: {
        'uid': user.uid,
        'phone': user.phoneNumber ?? '',
        'fullName': fullName,
        'name': fullName,
        'email': email,
        'role': existing?.role.name ?? UserRole.partner.name,
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
        'createdBy': existing?.createdBy.isNotEmpty == true
            ? existing!.createdBy
            : user.uid,
        'createdByName': existing?.createdByName.isNotEmpty == true
            ? existing!.createdByName
            : fullName,
        'workspaceId': _resolveWorkspaceId(
          requested: existing?.workspaceId,
          existing: null,
          fallbackUid: user.uid,
        ),
        'linkedPartnerId': existing?.linkedPartnerId ?? '',
        'linkedPartnerName': existing?.linkedPartnerName ?? '',
      },
    );
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

  Future<AppUser?> _tryFetchProfile(String uid) async {
    try {
      return await fetchProfile(uid);
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return null;
      }
      rethrow;
    }
  }

  Future<void> _writeProfile({
    required String uid,
    required Map<String, dynamic> data,
    String? previousEmail,
  }) async {
    final normalizedEmail = (data['email'] as String? ?? '')
        .trim()
        .toLowerCase();
    final normalizedPreviousEmail = (previousEmail ?? '').trim().toLowerCase();
    final batch = _firestore.batch();

    batch.set(_users.doc(uid), data, SetOptions(merge: true));

    if (normalizedPreviousEmail.isNotEmpty &&
        normalizedPreviousEmail != normalizedEmail) {
      batch.delete(_userEmailLookup.doc(normalizedPreviousEmail));
    }

    if (normalizedEmail.isNotEmpty) {
      batch.set(_userEmailLookup.doc(normalizedEmail), {
        'uid': uid,
        'email': normalizedEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  String _resolveWorkspaceId({
    required String? requested,
    required String? existing,
    required String fallbackUid,
  }) {
    final normalizedRequested = requested?.trim() ?? '';
    if (normalizedRequested.isNotEmpty) {
      return normalizedRequested;
    }
    final normalizedExisting = existing?.trim() ?? '';
    if (normalizedExisting.isNotEmpty) {
      return normalizedExisting;
    }
    return 'workspace_$fallbackUid';
  }

  String _resolveCreatedBy({
    required String? requested,
    required String? existing,
    required String fallback,
  }) {
    final normalizedRequested = requested?.trim() ?? '';
    if (normalizedRequested.isNotEmpty) {
      return normalizedRequested;
    }
    final normalizedExisting = existing?.trim() ?? '';
    if (normalizedExisting.isNotEmpty) {
      return normalizedExisting;
    }
    return fallback;
  }
}
