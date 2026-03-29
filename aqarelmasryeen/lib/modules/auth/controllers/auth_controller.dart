import 'dart:async';
import 'dart:io';

import 'package:aqarelmasryeen/app/routes/app_routes.dart';
import 'package:aqarelmasryeen/core/bootstrap/app_bootstrap.dart';
import 'package:aqarelmasryeen/core/firebase/dev_phone_auth_config.dart';
import 'package:aqarelmasryeen/core/services/biometric_service.dart';
import 'package:aqarelmasryeen/core/services/session_service.dart';
import 'package:aqarelmasryeen/core/utils/phone_utils.dart';
import 'package:aqarelmasryeen/data/models/app_role.dart';
import 'package:aqarelmasryeen/data/models/cached_session.dart';
import 'package:aqarelmasryeen/data/models/phone_verification_session.dart';
import 'package:aqarelmasryeen/data/models/user_profile.dart';
import 'package:aqarelmasryeen/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = Get.find();
  final SessionService _sessionService = Get.find();
  final BiometricService _biometricService = Get.find();
  final BootstrapState _bootstrapState = Get.find();

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  final isBusy = false.obs;
  final isRegisterMode = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final biometricAvailable = false.obs;
  final verificationSession = Rxn<PhoneVerificationSession>();

  bool _unlockMode = false;
  bool _hasLoadedPendingVerification = false;
  int _phoneAuthAttemptId = 0;
  String? _lastAutoSubmittedVerificationId;

  bool get unlockMode => _unlockMode;
  bool get firebaseReady => _bootstrapState.firebaseReady;
  String get pendingPhone =>
      verificationSession.value?.phone ??
      PhoneUtils.normalize(phoneController.text);

  String? get debugPhoneAuthHint {
    if (!DevPhoneAuthConfig.isEnabled || !_supportsOtpOnCurrentPlatform) {
      return null;
    }

    return 'Debug test phone: ${DevPhoneAuthConfig.phoneNumber} / ${DevPhoneAuthConfig.smsCode}';
  }

  String? get suggestedOtpCode {
    final session = verificationSession.value;
    if (session == null || !DevPhoneAuthConfig.canAutoSubmitOtp) {
      return null;
    }

    if (!DevPhoneAuthConfig.matchesPhone(session.phone)) {
      return null;
    }

    return DevPhoneAuthConfig.smsCode;
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_restorePendingVerificationSession());
  }

  Future<void> configureEntry(dynamic arguments) async {
    _unlockMode = arguments is Map && arguments['unlock'] == true;
    final cachedSession = await _sessionService.readCachedSession();
    if (cachedSession != null && phoneController.text.isEmpty) {
      phoneController.text = cachedSession.phone;
      nameController.text = cachedSession.fullName;
    }

    await _restorePendingVerificationSession();

    biometricAvailable.value =
        await _sessionService.isBiometricEnabled() &&
        _authRepository.isAuthenticated &&
        await _biometricService.isDeviceSupported();
    update();
  }

  void toggleMode() => isRegisterMode.toggle();

  Future<void> loginWithPassword() async {
    final rawPhone = phoneController.text.trim();
    final password = passwordController.text;
    if (rawPhone.isEmpty || password.isEmpty) {
      _showError('Please enter your phone number and password.');
      return;
    }

    await _runGuarded(() async {
      final profile = await _authRepository.signInWithPhonePassword(
        phone: rawPhone,
        password: password,
      );
      await _clearPendingVerificationSession();

      if (profile.fullName.trim() == profile.phone.trim()) {
        nameController.text = '';
        emailController.text = profile.email ?? '';
        Get.toNamed(AppRoutes.profileCompletion);
        return;
      }
      await _cacheAndUnlock(profile);
      Get.offAllNamed(AppRoutes.dashboard);
    });
  }

  Future<void> sendOtp() async {
    final rawPhone = phoneController.text.trim();
    if (rawPhone.isEmpty) {
      _showError('Please enter your phone number first.');
      return;
    }

    if (!_supportsOtpOnCurrentPlatform) {
      _showError('desktop_otp_note'.tr);
      return;
    }

    final normalizedPhone = PhoneUtils.normalize(rawPhone);
    phoneController.text = normalizedPhone;

    try {
      if (isRegisterMode.value &&
          await _authRepository.isPhoneRegistered(normalizedPhone)) {
        _showError('An account already exists for this phone number.');
        return;
      }
    } on FirebaseAuthException catch (error) {
      _showError(error.message ?? 'Authentication failed.');
      return;
    } on StateError catch (error) {
      _showError(error.message);
      return;
    } catch (error) {
      _showError(error.toString());
      return;
    }

    await _startPhoneVerificationFlow(
      phone: normalizedPhone,
      isRegistration: isRegisterMode.value,
    );
  }

  Future<void> resendOtp() async {
    final session =
        verificationSession.value ?? await _restorePendingVerificationSession();
    final phone = session?.phone ?? PhoneUtils.normalize(phoneController.text);
    if (phone.isEmpty) {
      _showError('Please enter your phone number first.');
      return;
    }

    await _startPhoneVerificationFlow(
      phone: phone,
      isRegistration: session?.isRegistration ?? isRegisterMode.value,
      forceResendingToken: session?.resendToken,
    );
  }

  Future<void> maybeAutoSubmitTestOtp() async {
    final session =
        verificationSession.value ?? await _restorePendingVerificationSession();
    if (session == null || !DevPhoneAuthConfig.canAutoSubmitOtp) {
      return;
    }

    if (!DevPhoneAuthConfig.matchesPhone(session.phone)) {
      return;
    }

    if (_lastAutoSubmittedVerificationId == session.verificationId ||
        isBusy.value) {
      return;
    }

    _lastAutoSubmittedVerificationId = session.verificationId;
    await verifyOtp(DevPhoneAuthConfig.smsCode, isAutomaticTestCode: true);
  }

  Future<void> verifyOtp(
    String code, {
    bool isAutomaticTestCode = false,
  }) async {
    final session =
        verificationSession.value ?? await _restorePendingVerificationSession();
    if (session == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    final trimmedCode = code.trim();
    if (trimmedCode.length < 6) {
      if (!isAutomaticTestCode) {
        _showError('The verification code must be 6 digits.');
      }
      return;
    }

    await _runGuarded(() async {
      await _authRepository.verifyOtp(
        verificationId: session.verificationId,
        code: trimmedCode,
      );

      await _handleVerifiedUser(
        phone: session.phone,
        isRegistration: session.isRegistration,
      );
    });
  }

  Future<void> setupPassword() async {
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    if (password.length < 8) {
      _showError('Password must be at least 8 characters.');
      return;
    }

    if (password != confirm) {
      _showError('The password confirmation does not match.');
      return;
    }

    await _runGuarded(() async {
      await _authRepository.linkPasswordCredential(
        phone: pendingPhone,
        password: password,
      );
      Get.offNamed(AppRoutes.profileCompletion);
    });
  }

  Future<void> completeProfile() async {
    final fullName = nameController.text.trim();
    final email = emailController.text.trim();
    if (fullName.isEmpty) {
      _showError('Please enter your full name.');
      return;
    }

    await _runGuarded(() async {
      final existing = await _authRepository.getCurrentProfile();
      final profile = _authRepository.buildUpdatedProfile(
        existing: existing,
        fullName: fullName,
        phone: pendingPhone,
        email: email.isEmpty ? null : email,
        role: existing?.role ?? AppRole.owner,
      );
      await _authRepository.saveUserProfile(profile);
      await _sessionService.setAppLockEnabled(true);
      await _clearPendingVerificationSession();

      if (await _biometricService.isDeviceSupported()) {
        Get.toNamed(AppRoutes.biometricPrompt);
        return;
      }

      await _cacheAndUnlock(profile);
      Get.offAllNamed(AppRoutes.dashboard);
    });
  }

  Future<void> enableBiometrics() async {
    await _runGuarded(() async {
      final success = await _biometricService.authenticate();
      if (!success) {
        _showError('Biometric authentication is not available on this device.');
        return;
      }

      await _sessionService.setBiometricEnabled(true);
      final profile = await _authRepository.getCurrentProfile();
      if (profile != null) {
        await _cacheAndUnlock(profile);
      }
      Get.offAllNamed(AppRoutes.dashboard);
    });
  }

  Future<void> skipBiometrics() async {
    await _sessionService.setBiometricEnabled(false);
    final profile = await _authRepository.getCurrentProfile();
    if (profile != null) {
      await _cacheAndUnlock(profile);
    }
    Get.offAllNamed(AppRoutes.dashboard);
  }

  Future<void> unlockWithBiometrics() async {
    await _runGuarded(() async {
      final success = await _biometricService.authenticate();
      if (!success) {
        _showError('Biometric verification failed.');
        return;
      }

      await _sessionService.unlockApp();
      Get.offAllNamed(AppRoutes.dashboard);
    });
  }

  Future<void> logout() async {
    await _authRepository.signOut();
    await _sessionService.clearSession();
    await _clearPendingVerificationSession();
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> _startPhoneVerificationFlow({
    required String phone,
    required bool isRegistration,
    int? forceResendingToken,
  }) async {
    final attemptId = ++_phoneAuthAttemptId;
    isBusy.value = true;

    try {
      await _authRepository.startPhoneVerification(
        phone: phone,
        isRegistration: isRegistration,
        forceResendingToken: forceResendingToken,
        onCodeSent: (session) async {
          if (!_isCurrentPhoneAuthAttempt(attemptId)) {
            return;
          }

          await _persistVerificationSession(session);
          isBusy.value = false;

          if (Get.currentRoute != AppRoutes.otp) {
            unawaited(Get.toNamed(AppRoutes.otp));
          }

          if (DevPhoneAuthConfig.matchesPhone(session.phone)) {
            unawaited(
              Future<void>.delayed(
                const Duration(milliseconds: 150),
                maybeAutoSubmitTestOtp,
              ),
            );
          }
        },
        onCodeAutoRetrievalTimeout: (session) async {
          if (!_isCurrentPhoneAuthAttempt(attemptId)) {
            return;
          }

          final persisted = (verificationSession.value ?? session).copyWith(
            verificationId: session.verificationId,
          );
          await _persistVerificationSession(persisted);
          isBusy.value = false;
        },
        onVerificationCompleted: (_) async {
          if (!_isCurrentPhoneAuthAttempt(attemptId)) {
            return;
          }

          isBusy.value = false;
          await _handleVerifiedUser(
            phone: phone,
            isRegistration: isRegistration,
          );
        },
        onVerificationFailed: (error) async {
          if (!_isCurrentPhoneAuthAttempt(attemptId)) {
            return;
          }

          isBusy.value = false;
          await _clearPendingVerificationSession();
          _showError(error.message ?? 'Phone verification failed.');
        },
      );
    } on FirebaseAuthException catch (error) {
      isBusy.value = false;
      _showError(error.message ?? 'Authentication failed.');
    } on StateError catch (error) {
      isBusy.value = false;
      _showError(error.message);
    } catch (error) {
      isBusy.value = false;
      _showError(error.toString());
    }
  }

  Future<void> _handleVerifiedUser({
    required String phone,
    required bool isRegistration,
  }) async {
    final session =
        verificationSession.value ??
        PhoneVerificationSession(
          phone: phone,
          verificationId: '',
          isRegistration: isRegistration,
        );
    await _persistVerificationSession(
      session.copyWith(phone: phone, isRegistration: isRegistration),
    );

    if (isRegistration) {
      Get.offNamed(AppRoutes.passwordSetup);
      return;
    }

    final profile = await _authRepository.ensureCurrentUserProfile(
      phone: phone,
      role: AppRole.owner,
    );

    if (profile.fullName.trim() == profile.phone.trim()) {
      nameController.text = '';
      emailController.text = profile.email ?? '';
      Get.offNamed(AppRoutes.profileCompletion);
      return;
    }

    await _clearPendingVerificationSession();
    await _cacheAndUnlock(profile);
    Get.offAllNamed(AppRoutes.dashboard);
  }

  Future<void> _persistVerificationSession(
    PhoneVerificationSession session,
  ) async {
    verificationSession.value = session;
    phoneController.text = session.phone;
    await _sessionService.cachePhoneVerificationSession(session);
  }

  Future<PhoneVerificationSession?> _restorePendingVerificationSession() async {
    if (_hasLoadedPendingVerification) {
      return verificationSession.value;
    }

    final storedSession = await _sessionService.readPhoneVerificationSession();
    if (storedSession != null) {
      verificationSession.value = storedSession;
      if (phoneController.text.isEmpty) {
        phoneController.text = storedSession.phone;
      }
    }

    _hasLoadedPendingVerification = true;
    return verificationSession.value;
  }

  Future<void> _clearPendingVerificationSession() async {
    verificationSession.value = null;
    _hasLoadedPendingVerification = true;
    _lastAutoSubmittedVerificationId = null;
    await _sessionService.clearPhoneVerificationSession();
  }

  bool _isCurrentPhoneAuthAttempt(int attemptId) =>
      attemptId == _phoneAuthAttemptId && !isClosed;

  Future<void> _cacheAndUnlock(UserProfile profile) async {
    await _sessionService.cacheSession(
      CachedSession(
        userId: profile.id,
        phone: profile.phone,
        fullName: profile.fullName,
        roleKey: profile.role.key,
      ),
    );
    await _sessionService.unlockApp();
  }

  Future<void> _runGuarded(Future<void> Function() action) async {
    if (isBusy.value) {
      return;
    }

    isBusy.value = true;
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      _showError(error.message ?? 'Authentication failed.');
    } on StateError catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError(error.toString());
    } finally {
      isBusy.value = false;
    }
  }

  bool get _supportsOtpOnCurrentPlatform {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  void _showError(String message) {
    Get.snackbar(
      'app_name'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }
}
