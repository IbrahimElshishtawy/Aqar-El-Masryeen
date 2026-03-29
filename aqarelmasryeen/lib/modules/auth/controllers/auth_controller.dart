import 'dart:async';
import 'dart:io';

import 'package:aqarelmasryeen/app/routes/app_routes.dart';
import 'package:aqarelmasryeen/core/bootstrap/app_bootstrap.dart';
import 'package:aqarelmasryeen/core/firebase/dev_phone_auth_config.dart';
import 'package:aqarelmasryeen/core/services/auth_service.dart';
import 'package:aqarelmasryeen/core/services/biometric_service.dart';
import 'package:aqarelmasryeen/core/services/session_service.dart';
import 'package:aqarelmasryeen/core/utils/password_policy.dart';
import 'package:aqarelmasryeen/core/utils/phone_utils.dart';
import 'package:aqarelmasryeen/data/models/app_role.dart';
import 'package:aqarelmasryeen/data/models/pending_auth_challenge.dart';
import 'package:aqarelmasryeen/data/models/user_profile.dart';
import 'package:aqarelmasryeen/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find();
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
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final showPasswordField = true.obs;
  final canUseDeviceCredential = false.obs;
  final canUseBiometric = false.obs;
  final hasStoredCredentials = false.obs;
  final biometricLabel = 'Use Biometrics'.obs;
  final pendingChallenge = Rxn<PendingAuthChallenge>();
  final resendSecondsRemaining = 0.obs;
  final otpDigits = List<String>.filled(6, '').obs;
  final passwordPolicy = PasswordPolicy.evaluate('').obs;

  final phoneError = RxnString();
  final passwordError = RxnString();
  final confirmPasswordError = RxnString();
  final nameError = RxnString();

  bool _unlockMode = false;
  int _phoneAuthAttemptId = 0;
  String? _lastAutoSubmittedVerificationId;
  Timer? _resendTimer;

  bool get unlockMode => _unlockMode;
  bool get firebaseReady => _bootstrapState.firebaseReady;
  bool get canVerifyOtp => otpDigits.every((digit) => digit.length == 1);
  bool get canResendOtp => resendSecondsRemaining.value == 0 && !isBusy.value;
  String get otpCode => otpDigits.join();
  String get pendingPhone =>
      pendingChallenge.value?.phone ?? PhoneUtils.normalize(phoneController.text);
  String get maskedPendingPhone => PhoneUtils.mask(pendingPhone);

  String? get debugPhoneAuthHint {
    if (!DevPhoneAuthConfig.isEnabled || !_supportsOtpOnCurrentPlatform) {
      return null;
    }

    return 'Debug test phone: ${DevPhoneAuthConfig.phoneNumber} / ${DevPhoneAuthConfig.smsCode}';
  }

  String? get suggestedOtpCode {
    final challenge = pendingChallenge.value;
    if (challenge == null || !DevPhoneAuthConfig.canAutoSubmitOtp) {
      return null;
    }

    if (!DevPhoneAuthConfig.matchesPhone(challenge.phone)) {
      return null;
    }

    return DevPhoneAuthConfig.smsCode;
  }

  @override
  void onInit() {
    super.onInit();
    passwordController.addListener(_updatePasswordPolicy);
    phoneController.addListener(_clearPhoneError);
    confirmPasswordController.addListener(_clearConfirmPasswordError);
    nameController.addListener(_clearNameError);
    unawaited(_restorePendingChallenge());
    unawaited(_refreshLocalAuthState());
  }

  Future<void> configureEntry(dynamic arguments) async {
    _unlockMode = arguments is Map && arguments['unlock'] == true;
    await _restorePendingChallenge();
    await _refreshLocalAuthState();

    if (pendingChallenge.value != null) {
      _syncResendTimer();
    }

    update();
  }

  Future<void> prepareOtpEntry() async {
    final challenge = await _restorePendingChallenge();
    if (challenge == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    _syncResendTimer();
    final suggested = suggestedOtpCode;
    if (suggested != null) {
      fillOtpFromString(suggested);
    }
    await maybeAutoSubmitTestOtp();
  }

  Future<void> goToRegistration() async {
    _clearOtp();
    if (Get.currentRoute != AppRoutes.register) {
      await Get.toNamed(AppRoutes.register);
    }
  }

  Future<void> goToLogin() async {
    _clearOtp();
    if (Get.currentRoute != AppRoutes.login) {
      await Get.offAllNamed(AppRoutes.login);
    }
  }

  Future<void> startRegistration() async {
    if (!_supportsOtpOnCurrentPlatform) {
      _showError('Phone OTP registration is currently supported on Android and iOS only.');
      return;
    }

    if (!_validateRegistrationInputs()) {
      return;
    }

    final rawPhone = phoneController.text.trim();
    final attemptId = ++_phoneAuthAttemptId;
    isBusy.value = true;

    try {
      await _authService.startRegistration(
        fullName: nameController.text.trim(),
        phone: rawPhone,
        password: passwordController.text,
        email: emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
        onCodeSent: (challenge) async {
          if (!_isCurrentPhoneAuthAttempt(attemptId)) {
            return;
          }
          await _handleCodeSent(challenge);
        },
        onCodeAutoRetrievalTimeout: (challenge) async {
          if (!_isCurrentPhoneAuthAttempt(attemptId)) {
            return;
          }
          pendingChallenge.value = challenge;
          _syncResendTimer();
          isBusy.value = false;
        },
        onVerificationResolved: (profile) async {
          if (!_isCurrentPhoneAuthAttempt(attemptId)) {
            return;
          }
          await _handleAuthenticatedProfile(profile, fromRegistration: true);
        },
        onVerificationFailed: (message) async {
          if (!_isCurrentPhoneAuthAttempt(attemptId)) {
            return;
          }
          isBusy.value = false;
          await _restorePendingChallenge();
          _showError(message);
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

  Future<void> sendLoginOtp() async {
    if (!_supportsOtpOnCurrentPlatform) {
      _showError('Phone OTP sign-in is currently supported on Android and iOS only.');
      return;
    }

    if (!_validatePhoneInput()) {
      return;
    }

    final attemptId = ++_phoneAuthAttemptId;
    isBusy.value = true;

    try {
      await _authService.startOtpLogin(
        phone: phoneController.text.trim(),
        onCodeSent: (challenge) async {
          if (!_isCurrentPhoneAuthAttempt(attemptId)) {
            return;
          }
          await _handleCodeSent(challenge);
        },
        onCodeAutoRetrievalTimeout: (challenge) async {
          if (!_isCurrentPhoneAuthAttempt(attemptId)) {
            return;
          }
          pendingChallenge.value = challenge;
          _syncResendTimer();
          isBusy.value = false;
        },
        onVerificationResolved: (profile) async {
          if (!_isCurrentPhoneAuthAttempt(attemptId)) {
            return;
          }
          await _handleAuthenticatedProfile(profile, fromRegistration: false);
        },
        onVerificationFailed: (message) async {
          if (!_isCurrentPhoneAuthAttempt(attemptId)) {
            return;
          }
          isBusy.value = false;
          await _restorePendingChallenge();
          _showError(message);
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

  Future<void> resendOtp() async {
    if (isBusy.value) {
      return;
    }

    final challenge = pendingChallenge.value ?? await _restorePendingChallenge();
    if (challenge == null) {
      _showError('Your verification session expired. Please request a new code.');
      return;
    }

    final attemptId = ++_phoneAuthAttemptId;
    isBusy.value = true;

    try {
      await _authService.resendOtp(
        onCodeSent: (updated) async {
          if (!_isCurrentPhoneAuthAttempt(attemptId)) {
            return;
          }
          await _handleCodeSent(updated, navigateToOtp: false);
        },
        onCodeAutoRetrievalTimeout: (updated) async {
          if (!_isCurrentPhoneAuthAttempt(attemptId)) {
            return;
          }
          pendingChallenge.value = updated;
          _syncResendTimer();
          isBusy.value = false;
        },
        onVerificationResolved: (profile) async {
          if (!_isCurrentPhoneAuthAttempt(attemptId)) {
            return;
          }
          await _handleAuthenticatedProfile(
            profile,
            fromRegistration: challenge.isRegistration,
          );
        },
        onVerificationFailed: (message) async {
          if (!_isCurrentPhoneAuthAttempt(attemptId)) {
            return;
          }
          isBusy.value = false;
          _showError(message);
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

  Future<void> verifyOtp([String? rawCode]) async {
    final candidate = (rawCode ?? otpCode).trim();
    if (candidate.length != 6) {
      _showError('Enter the full 6-digit code to continue.');
      return;
    }

    await _runBusyTask(() async {
      final challenge = pendingChallenge.value ?? await _restorePendingChallenge();
      if (challenge == null) {
        throw StateError('Your verification session expired. Please request a new code.');
      }

      final profile = await _authService.verifyOtp(candidate);
      await _handleAuthenticatedProfile(
        profile,
        fromRegistration: challenge.isRegistration,
      );
    });
  }

  Future<void> loginWithPassword() async {
    if (!_validatePasswordLoginInputs()) {
      return;
    }

    await _runBusyTask(() async {
      await _authService.loginWithPassword(
        phone: phoneController.text.trim(),
        password: passwordController.text,
      );
      await _refreshLocalAuthState();
      Get.offAllNamed(AppRoutes.dashboard);
      _clearOtp();
      _clearRegistrationErrors();
      pendingChallenge.value = null;
    });
  }

  Future<void> loginWithDeviceCredential() async {
    await _runBusyTask(() async {
      await _authService.signInWithDeviceCredential();
      Get.offAllNamed(AppRoutes.dashboard);
    });
  }

  Future<void> unlockWithBiometrics() async {
    await loginWithBiometrics();
  }

  Future<void> loginWithBiometrics() async {
    await _runBusyTask(() async {
      await _authService.signInWithBiometrics();
      Get.offAllNamed(AppRoutes.dashboard);
    });
  }

  Future<void> enableBiometrics() async {
    await _runBusyTask(() async {
      final success = await _biometricService.authenticateWithBiometrics();
      if (!success) {
        throw StateError('Biometric verification was cancelled.');
      }

      await _authService.setBiometricEnabled(true);
      await _refreshLocalAuthState();
      Get.offAllNamed(AppRoutes.dashboard);
    });
  }

  Future<void> skipBiometrics() async {
    await _authService.setBiometricEnabled(false);
    await _refreshLocalAuthState();
    Get.offAllNamed(AppRoutes.dashboard);
  }

  Future<void> logout() async {
    await _authRepository.signOut();
    await _sessionService.clearSession();
    await _authService.clearPendingChallenge();
    Get.offAllNamed(AppRoutes.login);
  }

  void updateOtpDigit(int index, String value) {
    if (index < 0 || index >= otpDigits.length) {
      return;
    }
    otpDigits[index] = value;
  }

  void fillOtpFromString(String value) {
    final trimmed = value.replaceAll(RegExp(r'\s'), '');
    for (var index = 0; index < otpDigits.length; index++) {
      otpDigits[index] = index < trimmed.length ? trimmed[index] : '';
    }
  }

  Future<void> maybeAutoSubmitTestOtp() async {
    final challenge = pendingChallenge.value ?? await _restorePendingChallenge();
    if (challenge == null || !DevPhoneAuthConfig.canAutoSubmitOtp) {
      return;
    }

    if (!DevPhoneAuthConfig.matchesPhone(challenge.phone)) {
      return;
    }

    if (_lastAutoSubmittedVerificationId == challenge.verificationId ||
        isBusy.value) {
      return;
    }

    _lastAutoSubmittedVerificationId = challenge.verificationId;
    fillOtpFromString(DevPhoneAuthConfig.smsCode);
    await verifyOtp(DevPhoneAuthConfig.smsCode);
  }

  Future<void> setupPassword() async {
    await startRegistration();
  }

  Future<void> completeProfile() async {
    if (!_validateRegistrationInputs(requirePassword: false)) {
      return;
    }

    await _runBusyTask(() async {
      final existing = await _authRepository.getCurrentProfile();
      final profile = _authRepository.buildUpdatedProfile(
        existing: existing,
        fullName: nameController.text.trim(),
        phone: pendingPhone,
        email: emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
        role: existing?.role ?? AppRole.owner,
      );
      await _authRepository.saveUserProfile(profile);
      await _authService.finalizeTrustedSession(profile);
      await _authService.clearPendingChallenge();
      Get.offAllNamed(AppRoutes.dashboard);
    });
  }

  Future<void> _handleCodeSent(
    PendingAuthChallenge challenge, {
    bool navigateToOtp = true,
  }) async {
    pendingChallenge.value = challenge;
    phoneController.text = challenge.phone;
    _syncResendTimer();
    _clearOtp();
    isBusy.value = false;

    if (navigateToOtp && Get.currentRoute != AppRoutes.otp) {
      await Get.toNamed(AppRoutes.otp);
    }
  }

  Future<void> _handleAuthenticatedProfile(
    UserProfile profile, {
    required bool fromRegistration,
  }) async {
    _phoneAuthAttemptId++;
    isBusy.value = false;
    pendingChallenge.value = null;
    _resendTimer?.cancel();
    resendSecondsRemaining.value = 0;
    _clearOtp();
    await _refreshLocalAuthState();

    final canPromptBiometrics =
        fromRegistration &&
        !unlockMode &&
        !await _authService.isBiometricEnabled() &&
        (await _biometricService.getAvailableBiometrics()).isNotEmpty;

    if (canPromptBiometrics) {
      Get.offNamed(AppRoutes.biometricPrompt);
      return;
    }

    Get.offAllNamed(AppRoutes.dashboard);
  }

  Future<PendingAuthChallenge?> _restorePendingChallenge() async {
    final challenge = await _authService.readPendingChallenge();
    pendingChallenge.value = challenge;
    if (challenge != null) {
      phoneController.text = challenge.phone;
    }
    return challenge;
  }

  Future<void> _refreshLocalAuthState() async {
    final availability = await _authService.loadLocalAuthAvailability();
    hasStoredCredentials.value = availability.hasStoredCredentials;
    canUseDeviceCredential.value = availability.canUseDeviceCredential;
    canUseBiometric.value = availability.canUseBiometric;
    biometricLabel.value = availability.biometricLabel;
    showPasswordField.value = unlockMode || !availability.canUseBiometric;

    if ((phoneController.text.isEmpty || unlockMode) &&
        availability.savedPhone != null) {
      phoneController.text = availability.savedPhone!;
    }
  }

  Future<void> _runBusyTask(Future<void> Function() action) async {
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

  bool _validateRegistrationInputs({bool requirePassword = true}) {
    _clearRegistrationErrors();

    final fullName = nameController.text.trim();
    final normalizedPhone = PhoneUtils.normalize(phoneController.text.trim());
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (fullName.length < 3) {
      nameError.value = 'Enter your full name as it should appear on the account.';
    }

    if (!_isValidPhone(normalizedPhone)) {
      phoneError.value = 'Enter a valid mobile number including the country code.';
    } else {
      phoneController.text = normalizedPhone;
    }

    if (requirePassword) {
      final passwordValidation = PasswordPolicy.validate(password);
      if (passwordValidation != null) {
        passwordError.value = passwordValidation;
      }

      if (confirmPassword != password) {
        confirmPasswordError.value = 'Password confirmation does not match.';
      }
    }

    return nameError.value == null &&
        phoneError.value == null &&
        (!requirePassword ||
            (passwordError.value == null && confirmPasswordError.value == null));
  }

  bool _validatePhoneInput() {
    _clearPhoneError();
    final normalizedPhone = PhoneUtils.normalize(phoneController.text.trim());
    if (!_isValidPhone(normalizedPhone)) {
      phoneError.value = 'Enter a valid mobile number including the country code.';
      return false;
    }

    phoneController.text = normalizedPhone;
    return true;
  }

  bool _validatePasswordLoginInputs() {
    final phoneValid = _validatePhoneInput();
    passwordError.value = null;

    if (passwordController.text.isEmpty) {
      passwordError.value = 'Enter your password to continue.';
    }

    return phoneValid && passwordError.value == null;
  }

  bool _isValidPhone(String normalizedPhone) {
    final digits = normalizedPhone.replaceAll(RegExp(r'[^\d]'), '');
    return normalizedPhone.startsWith('+') && digits.length >= 11;
  }

  void _updatePasswordPolicy() {
    passwordPolicy.value = PasswordPolicy.evaluate(passwordController.text);
    if (passwordError.value != null) {
      passwordError.value = PasswordPolicy.validate(passwordController.text);
    }
  }

  void _syncResendTimer() {
    _resendTimer?.cancel();
    final challenge = pendingChallenge.value;
    if (challenge == null) {
      resendSecondsRemaining.value = 0;
      return;
    }

    void updateRemaining() {
      final seconds = challenge.resendAvailableAt
          .difference(DateTime.now())
          .inSeconds;
      resendSecondsRemaining.value = seconds > 0 ? seconds : 0;
      if (seconds <= 0) {
        _resendTimer?.cancel();
      }
    }

    updateRemaining();
    if (resendSecondsRemaining.value > 0) {
      _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        updateRemaining();
      });
    }
  }

  bool _isCurrentPhoneAuthAttempt(int attemptId) =>
      attemptId == _phoneAuthAttemptId && !isClosed;

  bool get _supportsOtpOnCurrentPlatform {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  void _showError(String message) {
    Get.snackbar(
      'Aqar El Masryeen',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  void _clearOtp() {
    for (var index = 0; index < otpDigits.length; index++) {
      otpDigits[index] = '';
    }
  }

  void _clearRegistrationErrors() {
    phoneError.value = null;
    passwordError.value = null;
    confirmPasswordError.value = null;
    nameError.value = null;
  }

  void _clearPhoneError() {
    phoneError.value = null;
  }

  void _clearConfirmPasswordError() {
    confirmPasswordError.value = null;
  }

  void _clearNameError() {
    nameError.value = null;
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }
}
