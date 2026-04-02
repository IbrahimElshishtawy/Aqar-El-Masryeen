import 'dart:async';

import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:aqarelmasryeen/core/services/device_info_service.dart';
import 'package:aqarelmasryeen/core/services/secure_storage_service.dart';
import 'package:aqarelmasryeen/core/utils/phone_utils.dart';
import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:aqarelmasryeen/features/auth/domain/auth_repository.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(
    this._auth,
    this._firestore,
    this._activityRepository,
    this._notificationRepository,
    this._secureStorage,
    this._deviceInfoService,
  );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final ActivityRepository _activityRepository;
  final NotificationRepository _notificationRepository;
  final SecureStorageService _secureStorage;
  final DeviceInfoService _deviceInfoService;

  @override
  Stream<bool> authStateChanges() =>
      _auth.authStateChanges().map((user) => user != null);

  @override
  Stream<AppSession?> watchSession() async* {
    await for (final user in _auth.authStateChanges()) {
      if (user == null) {
        yield null;
        continue;
      }

      yield* _firestore
          .collection(FirestorePaths.users)
          .doc(user.uid)
          .snapshots()
          .asyncMap((doc) async {
            final profile = doc.exists
                ? AppUser.fromMap(doc.id, doc.data())
                : null;
            await _syncLocalSecurityPreferences(profile);
            return AppSession(firebaseUser: user, profile: profile);
          });
    }
  }

  @override
  Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    int? resendToken,
  }) async {
    if (!(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      throw const AppException(
        'Phone auth is supported on Android and iOS only.',
      );
    }

    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: PhoneUtils.normalize(phone),
      forceResendingToken: resendToken,
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
        await _ensureProfileDocument();
        await _recordLogin();
        if (!completer.isCompleted) completer.complete();
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
      codeSent: (verificationId, resendToken) {
        onCodeSent(verificationId, resendToken);
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (_) {
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
  }

  @override
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
    await _ensureProfileDocument();
    await _recordLogin();
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    await _ensureProfileDocument();
    await _recordLogin();
  }

  @override
  Future<void> completeProfile({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AppException('No authenticated user found.');

    final normalizedEmail = email.trim().toLowerCase();
    final emailCredential = EmailAuthProvider.credential(
      email: normalizedEmail,
      password: password,
    );

    final providers = user.providerData.map((item) => item.providerId).toSet();
    if (!providers.contains(EmailAuthProvider.PROVIDER_ID)) {
      await user.linkWithCredential(emailCredential);
    }

    await user.updateDisplayName(name.trim());
    await user.reload();

    final now = DateTime.now();
    final userRef = _firestore.collection(FirestorePaths.users).doc(user.uid);
    final existing = await userRef.get();
    final existingData = existing.data() ?? const <String, dynamic>{};
    await userRef.set({
      'phone': user.phoneNumber ?? '',
      'name': name.trim(),
      'email': normalizedEmail,
      'createdAt': existingData['createdAt'] ?? now,
      'updatedAt': now,
      'lastLoginAt': now,
      'role': existingData['role'] ?? UserRole.partner.name,
      'biometricEnabled': existingData['biometricEnabled'] as bool? ?? false,
      'trustedDevices':
          existingData['trustedDevices'] as List<dynamic>? ?? const <String>[],
    }, SetOptions(merge: true));

    await _activityRepository.log(
      actorId: user.uid,
      actorName: name.trim(),
      action: 'profile_completed',
      entityType: 'user',
      entityId: user.uid,
      metadata: {'email': normalizedEmail},
    );
  }

  @override
  Future<void> setBiometrics(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _secureStorage.write(
      SecureStorageService.biometricEnabledKey,
      enabled ? 'true' : 'false',
    );
    await _firestore.collection(FirestorePaths.users).doc(user.uid).set({
      'biometricEnabled': enabled,
      'updatedAt': DateTime.now(),
    }, SetOptions(merge: true));
    await _activityRepository.log(
      actorId: user.uid,
      actorName: user.displayName ?? user.phoneNumber ?? 'Partner',
      action: enabled ? 'biometric_enabled' : 'biometric_disabled',
      entityType: 'user',
      entityId: user.uid,
    );
  }

  @override
  Future<bool> biometricsEnabled() async {
    return (await _secureStorage.read(
          SecureStorageService.biometricEnabledKey,
        )) ==
        'true';
  }

  @override
  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _activityRepository.log(
        actorId: user.uid,
        actorName: user.displayName ?? user.phoneNumber ?? 'Partner',
        action: 'logout',
        entityType: 'user',
        entityId: user.uid,
      );
    }
    await _secureStorage.clearSession();
    await _auth.signOut();
  }

  Future<void> _ensureProfileDocument() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _firestore.collection(FirestorePaths.users).doc(user.uid);
    final snap = await ref.get();
    final device = await _deviceInfoService.currentDeviceLabel();
    final data = snap.data() ?? const <String, dynamic>{};
    final now = DateTime.now();
    if (!snap.exists) {
      await ref.set({
        'phone': user.phoneNumber ?? '',
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'createdAt': now,
        'updatedAt': now,
        'lastLoginAt': now,
        'role': UserRole.partner.name,
        'biometricEnabled': false,
        'trustedDevices': <String>[device],
      });
      await _secureStorage.write(
        SecureStorageService.biometricEnabledKey,
        'false',
      );
      return;
    }

    final profile = AppUser.fromMap(user.uid, data);
    await _syncLocalSecurityPreferences(profile);
    await ref.set({
      'phone': user.phoneNumber ?? profile.phone,
      'email': user.email ?? profile.email,
      'name': user.displayName ?? profile.name,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Future<void> _recordLogin() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final device = await _deviceInfoService.currentDeviceLabel();
    final userRef = _firestore.collection(FirestorePaths.users).doc(user.uid);
    final profile = await userRef.get();
    final existingDevices =
        (profile.data()?['trustedDevices'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toSet();
    final isNewDevice = !existingDevices.contains(device);

    await _secureStorage.write(SecureStorageService.trustedDeviceKey, device);

    await userRef.set({
      'phone': user.phoneNumber ?? profile.data()?['phone'] ?? '',
      'email': user.email ?? profile.data()?['email'] ?? '',
      'name': user.displayName ?? profile.data()?['name'] ?? '',
      'lastLoginAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'trustedDevices': FieldValue.arrayUnion([device]),
    }, SetOptions(merge: true));

    await _activityRepository.log(
      actorId: user.uid,
      actorName: user.displayName ?? user.phoneNumber ?? 'Partner',
      action: 'login',
      entityType: 'user',
      entityId: user.uid,
      metadata: {'device': device, 'isNewDevice': isNewDevice},
    );

    if (isNewDevice) {
      await _notificationRepository.createSecurityNotification(
        userId: user.uid,
        title: 'New device login',
        body: 'A login was detected from $device',
        route: '/settings',
      );
    }
  }

  Future<void> _syncLocalSecurityPreferences(AppUser? profile) async {
    if (profile == null) return;
    await _secureStorage.write(
      SecureStorageService.biometricEnabledKey,
      profile.biometricEnabled ? 'true' : 'false',
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
    ref.watch(activityRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
    ref.watch(secureStorageProvider),
    ref.watch(deviceInfoServiceProvider),
  );
});
