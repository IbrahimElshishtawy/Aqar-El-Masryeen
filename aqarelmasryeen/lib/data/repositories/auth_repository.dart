import 'dart:async';

import 'package:aqarelmasryeen/core/bootstrap/app_bootstrap.dart';
import 'package:aqarelmasryeen/core/constants/firestore_collections.dart';
import 'package:aqarelmasryeen/core/services/session_service.dart';
import 'package:aqarelmasryeen/core/utils/phone_utils.dart';
import 'package:aqarelmasryeen/data/models/app_role.dart';
import 'package:aqarelmasryeen/data/models/cached_session.dart';
import 'package:aqarelmasryeen/data/models/phone_verification_session.dart';
import 'package:aqarelmasryeen/data/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository({
    required BootstrapState bootstrapState,
    required SessionService sessionService,
  })  : _bootstrapState = bootstrapState,
        _sessionService = sessionService;

  final BootstrapState _bootstrapState;
  final SessionService _sessionService;

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  bool get isAuthenticated => _bootstrapState.firebaseReady && _auth.currentUser != null;

  Future<bool> isPhoneRegistered(String phone) async {
    _ensureReady();
    final normalizedPhone = PhoneUtils.normalize(phone);
    final query = await _firestore
        .collection(FirestoreCollections.users)
        .where('phone', isEqualTo: normalizedPhone)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<PhoneVerificationSession> startPhoneVerification({
    required String phone,
    required bool isRegistration,
  }) async {
    _ensureReady();

    final normalizedPhone = PhoneUtils.normalize(phone);
    final completer = Completer<PhoneVerificationSession>();

    await _auth.verifyPhoneNumber(
      phoneNumber: normalizedPhone,
      verificationCompleted: (credential) async {
        if (_auth.currentUser == null) {
          await _auth.signInWithCredential(credential);
        }
      },
      verificationFailed: (exception) {
        if (!completer.isCompleted) {
          completer.completeError(exception);
        }
      },
      codeSent: (verificationId, resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneVerificationSession(
              phone: normalizedPhone,
              verificationId: verificationId,
              isRegistration: isRegistration,
              resendToken: resendToken,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );

    return completer.future;
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String code,
  }) async {
    _ensureReady();
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> linkPasswordCredential({
    required String phone,
    required String password,
  }) async {
    _ensureReady();
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'missing-user',
        message: 'No authenticated user to attach password credentials to.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: PhoneUtils.syntheticEmail(phone),
      password: password,
    );

    try {
      await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'provider-already-linked') {
        await user.updatePassword(password);
        return;
      }
      rethrow;
    }
  }

  Future<UserProfile> signInWithPhonePassword({
    required String phone,
    required String password,
  }) async {
    _ensureReady();
    final normalizedPhone = PhoneUtils.normalize(phone);
    await _auth.signInWithEmailAndPassword(
      email: PhoneUtils.syntheticEmail(normalizedPhone),
      password: password,
    );

    final profile = await getCurrentProfile();
    if (profile == null) {
      final fallback = _buildProfile(
        id: _auth.currentUser!.uid,
        fullName: normalizedPhone,
        phone: normalizedPhone,
        email: null,
        role: AppRole.owner,
      );
      await saveUserProfile(fallback);
      return fallback;
    }

    return profile;
  }

  Future<UserProfile?> getCurrentProfile() async {
    _ensureReady();
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .get();
    if (!doc.exists) {
      return null;
    }

    return UserProfile.fromMap(doc.data()!);
  }

  Future<UserProfile> ensureCurrentUserProfile({
    required String phone,
    required AppRole role,
    String? fullName,
    String? email,
  }) async {
    _ensureReady();
    final existing = await getCurrentProfile();
    if (existing != null) {
      return existing;
    }

    final user = _auth.currentUser!;
    final profile = _buildProfile(
      id: user.uid,
      fullName: fullName ?? phone,
      phone: phone,
      email: email,
      role: role,
    );
    await saveUserProfile(profile);
    return profile;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    _ensureReady();
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(profile.id)
        .set(profile.toMap(), SetOptions(merge: true));
    await _sessionService.cacheSession(
      CachedSession(
        userId: profile.id,
        phone: profile.phone,
        fullName: profile.fullName,
        roleKey: profile.role.key,
      ),
    );
  }

  Future<void> signOut() async {
    if (_bootstrapState.firebaseReady) {
      await _auth.signOut();
    }
  }

  UserProfile buildUpdatedProfile({
    required UserProfile? existing,
    required String fullName,
    required String phone,
    required String? email,
    required AppRole role,
  }) {
    return (existing ??
            _buildProfile(
              id: _auth.currentUser?.uid ?? '',
              fullName: fullName,
              phone: phone,
              email: email,
              role: role,
            ))
        .copyWith(
          fullName: fullName,
          phone: phone,
          email: email,
          role: role,
          updatedAt: DateTime.now(),
        );
  }

  void _ensureReady() {
    if (!_bootstrapState.firebaseReady) {
      throw StateError(
        _bootstrapState.firebaseError ??
            'Firebase is not configured. Add platform Firebase options first.',
      );
    }
  }

  UserProfile _buildProfile({
    required String id,
    required String fullName,
    required String phone,
    required String? email,
    required AppRole role,
  }) {
    final now = DateTime.now();
    return UserProfile(
      id: id,
      fullName: fullName,
      phone: phone,
      email: email,
      role: role,
      assignedProperties: const [],
      isActive: true,
      notes: null,
      createdAt: now,
      updatedAt: now,
    );
  }
}
