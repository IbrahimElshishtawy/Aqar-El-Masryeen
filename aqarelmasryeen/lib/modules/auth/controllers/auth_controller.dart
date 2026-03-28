import 'dart:io';

import 'package:aqarelmasryeen/app/routes/app_routes.dart';
import 'package:aqarelmasryeen/core/bootstrap/app_bootstrap.dart';
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

  PhoneVerificationSession? _verificationSession;
  bool _unlockMode = false;

  bool get unlockMode => _unlockMode;
  bool get firebaseReady => _bootstrapState.firebaseReady;
  String get pendingPhone => _verificationSession?.phone ?? PhoneUtils.normalize(phoneController.text);

  Future<void> configureEntry(dynamic arguments) async {
    _unlockMode = arguments is Map && arguments['unlock'] == true;
    final cachedSession = await _sessionService.readCachedSession();
    if (cachedSession != null && phoneController.text.isEmpty) {
      phoneController.text = cachedSession.phone;
      nameController.text = cachedSession.fullName;
    }

    biometricAvailable.value =
        await _sessionService.isBiometricEnabled() &&
            _authRepository.isAuthenticated &&
            await _biometricService.isDeviceSupported();
    update();
  }

  void toggleMode() {
    isRegisterMode.toggle();
  }

  Future<void> loginWithPassword() async {
    final rawPhone = phoneController.text.trim();
    final password = passwordController.text;
    if (rawPhone.isEmpty || password.isEmpty) {
      _showError('يرجى إدخال رقم الهاتف وكلمة المرور.');
      return;
    }

    await _runGuarded(() async {
      final profile = await _authRepository.signInWithPhonePassword(
        phone: rawPhone,
        password: password,
      );
      await _cacheAndUnlock(profile);
      Get.offAllNamed(AppRoutes.dashboard);
    });
  }

  Future<void> sendOtp() async {
    final rawPhone = phoneController.text.trim();
    if (rawPhone.isEmpty) {
      _showError('يرجى إدخال رقم الهاتف أولاً.');
      return;
    }

    if (!_supportsOtpOnCurrentPlatform) {
      _showError('desktop_otp_note'.tr);
      return;
    }

    await _runGuarded(() async {
      if (isRegisterMode.value &&
          await _authRepository.isPhoneRegistered(rawPhone)) {
        _showError('الحساب موجود بالفعل. استخدم تسجيل الدخول.');
        return;
      }

      _verificationSession = await _authRepository.startPhoneVerification(
        phone: rawPhone,
        isRegistration: isRegisterMode.value,
      );
      Get.toNamed(AppRoutes.otp);
    });
  }

  Future<void> verifyOtp(String code) async {
    if (_verificationSession == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    if (code.trim().length < 6) {
      _showError('الرمز غير مكتمل.');
      return;
    }

    await _runGuarded(() async {
      await _authRepository.verifyOtp(
        verificationId: _verificationSession!.verificationId,
        code: code,
      );

      if (_verificationSession!.isRegistration) {
        Get.toNamed(AppRoutes.passwordSetup);
        return;
      }

      final profile = await _authRepository.ensureCurrentUserProfile(
        phone: _verificationSession!.phone,
        role: AppRole.owner,
      );

      if (profile.fullName.trim() == profile.phone.trim()) {
        nameController.text = '';
        Get.toNamed(AppRoutes.profileCompletion);
        return;
      }

      await _cacheAndUnlock(profile);
      Get.offAllNamed(AppRoutes.dashboard);
    });
  }

  Future<void> setupPassword() async {
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    if (password.length < 8) {
      _showError('كلمة المرور يجب أن تكون 8 أحرف على الأقل.');
      return;
    }

    if (password != confirm) {
      _showError('كلمتا المرور غير متطابقتين.');
      return;
    }

    await _runGuarded(() async {
      await _authRepository.linkPasswordCredential(
        phone: pendingPhone,
        password: password,
      );
      Get.toNamed(AppRoutes.profileCompletion);
    });
  }

  Future<void> completeProfile() async {
    final fullName = nameController.text.trim();
    final email = emailController.text.trim();
    if (fullName.isEmpty) {
      _showError('يرجى إدخال الاسم الكامل.');
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
        _showError('تعذر تفعيل الدخول الحيوي على هذا الجهاز.');
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
        _showError('تعذر التحقق الحيوي.');
        return;
      }

      await _sessionService.unlockApp();
      Get.offAllNamed(AppRoutes.dashboard);
    });
  }

  Future<void> logout() async {
    await _authRepository.signOut();
    await _sessionService.clearSession();
    _verificationSession = null;
    Get.offAllNamed(AppRoutes.login);
  }

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
      'Aqar El Masryeen',
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
