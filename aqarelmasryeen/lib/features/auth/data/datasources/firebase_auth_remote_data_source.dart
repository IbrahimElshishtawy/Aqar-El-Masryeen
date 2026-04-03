import 'dart:async';

import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthRemoteDataSource {
  FirebaseAuthRemoteDataSource(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    int? resendToken,
  }) async {
    if (!(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      throw const AppException(
        'Phone verification is supported on Android and iOS only.',
      );
    }

    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      forceResendingToken: resendToken,
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
        if (!completer.isCompleted) completer.complete();
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
      codeSent: (verificationId, token) {
        onCodeSent(verificationId, token);
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (_) {
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> linkEmailCredential({
    required User user,
    required String email,
    required String password,
  }) async {
    final providers = user.providerData.map((provider) => provider.providerId);
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    if (!providers.contains(EmailAuthProvider.PROVIDER_ID)) {
      await user.linkWithCredential(credential);
      return;
    }

    if (user.email != email) {
      await user.verifyBeforeUpdateEmail(email);
    }
  }

  Future<void> updateDisplayName(User user, String fullName) {
    return user.updateDisplayName(fullName);
  }

  Future<void> reloadUser(User user) => user.reload();

  Future<void> signOut() => _auth.signOut();
}
