import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:aqarelmasryeen/core/constants/storage_keys.dart';
import 'package:aqarelmasryeen/core/services/biometric_service.dart';
import 'package:aqarelmasryeen/core/services/secure_storage_service.dart';
import 'package:aqarelmasryeen/core/services/session_service.dart';
import 'package:aqarelmasryeen/core/utils/phone_utils.dart';
import 'package:aqarelmasryeen/data/models/app_role.dart';
import 'package:aqarelmasryeen/data/models/cached_session.dart';
import 'package:aqarelmasryeen/data/models/pending_auth_challenge.dart';
import 'package:aqarelmasryeen/data/models/stored_auth_credentials.dart';
import 'package:aqarelmasryeen/data/models/user_profile.dart';
import 'package:aqarelmasryeen/data/repositories/auth_repository.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef PendingChallengeCallback =
    FutureOr<void> Function(PendingAuthChallenge challenge);

class LocalAuthAvailability {
  const LocalAuthAvailability({
    required this.savedPhone,
    required this.hasStoredCredentials,
    required this.canUseDeviceCredential,
    required this.canUseBiometric,
    required this.biometricLabel,
  });

  final String? savedPhone;
  final bool hasStoredCredentials;
  final bool canUseDeviceCredential;
  final bool canUseBiometric;
  final String biometricLabel;
}

class AuthService {
  AuthService({
    required AuthRepository authRepository,
    required SecureStorageService secureStorageService,
    required SessionService sessionService,
    required BiometricService biometricService,
  }) : _authRepository = authRepository,
       _secureStorageService = secureStorageService,
       _sessionService = sessionService,
       _biometricService = biometricService;

  static const resendCooldown = Duration(seconds: 60);
  static const _otpSendWindow = Duration(minutes: 30);
  static const _otpSendLimit = 5;
  static const _otpFailureLimit = 5;
  static const _otpFailureLockout = Duration(minutes: 10);
  static const _passwordFailureWindow = Duration(minutes: 15);
  static const _passwordFailureLimit = 5;
  static const _passwordFailureLockout = Duration(minutes: 15);

  final AuthRepository _authRepository;
  final SecureStorageService _secureStorageService;
  final SessionService _sessionService;
  final BiometricService _biometricService;

  final AesGcm _aesGcm = AesGcm.with256bits();
  final Random _random = Random.secure();

  Future<LocalAuthAvailability> loadLocalAuthAvailability() async {
    final storedCredentials = await readStoredCredentials();
    final cachedSession = await _sessionService.readCachedSession();
    final availableBiometrics = await _biometricService.getAvailableBiometrics();
    final supportsDeviceCredential =
        storedCredentials != null &&
        await _biometricService.isDeviceSupported();
    final biometricsEnabled = await _sessionService.isBiometricEnabled();
    final canUseBiometric =
        storedCredentials != null &&
        biometricsEnabled &&
        availableBiometrics.isNotEmpty;

    return LocalAuthAvailability(
      savedPhone: storedCredentials?.phone ?? cachedSession?.phone,
      hasStoredCredentials: storedCredentials != null,
      canUseDeviceCredential: supportsDeviceCredential,
      canUseBiometric: canUseBiometric,
      biometricLabel: _biometricService.preferredBiometricLabel(
        availableBiometrics,
      ),
    );
  }

  Future<PendingAuthChallenge?> readPendingChallenge() async {
    final payload = await _secureStorageService.read(StorageKeys.pendingAuthFlow);
    if (payload == null || payload.isEmpty) {
      return null;
    }

    return PendingAuthChallenge.fromJson(payload);
  }

  Future<void> cachePendingChallenge(PendingAuthChallenge challenge) {
    return _secureStorageService.write(
      StorageKeys.pendingAuthFlow,
      challenge.toJson(),
    );
  }

  Future<void> clearPendingChallenge() {
    return _secureStorageService.delete(StorageKeys.pendingAuthFlow);
  }

  Future<StoredAuthCredentials?> readStoredCredentials() async {
    final payload = await _secureStorageService.read(
      StorageKeys.savedAuthCredentials,
    );
    if (payload == null || payload.isEmpty) {
      return null;
    }

    return StoredAuthCredentials.fromJson(payload);
  }

  Future<void> rememberCredentials({
    required String phone,
    required String password,
  }) async {
    final normalizedPhone = PhoneUtils.normalize(phone);
    final now = DateTime.now();
    final existing = await readStoredCredentials();
    final encryptedPassword = await _encryptValue(password);
    final stored = StoredAuthCredentials(
      phone: normalizedPhone,
      encryptedPassword: encryptedPassword,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    await _secureStorageService.write(
      StorageKeys.savedAuthCredentials,
      stored.toJson(),
    );
  }

  Future<void> clearRememberedCredentials() {
    return _secureStorageService.delete(StorageKeys.savedAuthCredentials);
  }

  Future<void> finalizeTrustedSession(UserProfile profile) async {
    await _sessionService.cacheSession(
      CachedSession(
        userId: profile.id,
        phone: profile.phone,
        fullName: profile.fullName,
        roleKey: profile.role.key,
      ),
    );
    await _sessionService.setAppLockEnabled(true);
    await _sessionService.unlockApp();
  }

  Future<void> startRegistration({
    required String fullName,
    required String phone,
    required String password,
    String? email,
    required PendingChallengeCallback onCodeSent,
    required PendingChallengeCallback onCodeAutoRetrievalTimeout,
    required FutureOr<void> Function(UserProfile profile)
    onVerificationResolved,
    required FutureOr<void> Function(String message) onVerificationFailed,
  }) async {
    final normalizedPhone = PhoneUtils.normalize(phone);
    await _consumeAttempt(
      key: _otpSendKey(normalizedPhone),
      maxAttempts: _otpSendLimit,
      window: _otpSendWindow,
      lockout: _otpFailureLockout,
      blockedMessage:
          'Too many OTP requests were made for this phone. Please wait a few minutes before trying again.',
    );

    if (await _authRepository.isPhoneRegistered(normalizedPhone)) {
      throw StateError('An account already exists for this phone number.');
    }

    final encryptedPassword = await _encryptValue(password);

    await _startPhoneVerification(
      phone: normalizedPhone,
      isRegistration: true,
      fullName: fullName.trim(),
      email: email?.trim(),
      encryptedPassword: encryptedPassword,
      onCodeSent: onCodeSent,
      onCodeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      onVerificationResolved: onVerificationResolved,
      onVerificationFailed: onVerificationFailed,
    );
  }

  Future<void> startOtpLogin({
    required String phone,
    required PendingChallengeCallback onCodeSent,
    required PendingChallengeCallback onCodeAutoRetrievalTimeout,
    required FutureOr<void> Function(UserProfile profile)
    onVerificationResolved,
    required FutureOr<void> Function(String message) onVerificationFailed,
  }) async {
    final normalizedPhone = PhoneUtils.normalize(phone);
    await _consumeAttempt(
      key: _otpSendKey(normalizedPhone),
      maxAttempts: _otpSendLimit,
      window: _otpSendWindow,
      lockout: _otpFailureLockout,
      blockedMessage:
          'Too many OTP requests were made for this phone. Please wait a few minutes before trying again.',
    );

    await _startPhoneVerification(
      phone: normalizedPhone,
      isRegistration: false,
      onCodeSent: onCodeSent,
      onCodeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      onVerificationResolved: onVerificationResolved,
      onVerificationFailed: onVerificationFailed,
    );
  }

  Future<void> resendOtp({
    required PendingChallengeCallback onCodeSent,
    required PendingChallengeCallback onCodeAutoRetrievalTimeout,
    required FutureOr<void> Function(UserProfile profile)
    onVerificationResolved,
    required FutureOr<void> Function(String message) onVerificationFailed,
  }) async {
    final challenge = await readPendingChallenge();
    if (challenge == null) {
      throw StateError('Your verification session expired. Please request a new code.');
    }

    if (!challenge.canResend) {
      final seconds = challenge.resendAvailableAt
          .difference(DateTime.now())
          .inSeconds
          .clamp(1, resendCooldown.inSeconds);
      throw StateError('You can resend a new code in $seconds seconds.');
    }

    await _consumeAttempt(
      key: _otpSendKey(challenge.phone),
      maxAttempts: _otpSendLimit,
      window: _otpSendWindow,
      lockout: _otpFailureLockout,
      blockedMessage:
          'Too many OTP requests were made for this phone. Please wait a few minutes before trying again.',
    );

    await _startPhoneVerification(
      phone: challenge.phone,
      isRegistration: challenge.isRegistration,
      fullName: challenge.fullName,
      email: challenge.email,
      encryptedPassword: challenge.encryptedPassword,
      forceResendingToken: challenge.resendToken,
      existingChallenge: challenge,
      onCodeSent: onCodeSent,
      onCodeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      onVerificationResolved: onVerificationResolved,
      onVerificationFailed: onVerificationFailed,
    );
  }

  Future<UserProfile> verifyOtp(String code) async {
    final challenge = await readPendingChallenge();
    if (challenge == null) {
      throw StateError('Your verification session expired. Please request a new code.');
    }

    await _enforceNotLocked(
      key: _otpVerifyKey(challenge.phone),
      blockedMessage:
          'Too many incorrect OTP attempts were made. Please wait before requesting a new code.',
    );

    final trimmedCode = code.trim();
    if (trimmedCode.length != 6) {
      throw StateError('The verification code must contain 6 digits.');
    }

    try {
      await _authRepository.verifyOtp(
        verificationId: challenge.verificationId,
        code: trimmedCode,
      );
      await _clearAttempt(_otpVerifyKey(challenge.phone));
      return _finalizeVerifiedChallenge(challenge);
    } on FirebaseAuthException catch (error) {
      await _recordOtpFailure(challenge);
      rethrow;
    }
  }

  Future<UserProfile> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    final normalizedPhone = PhoneUtils.normalize(phone);
    await _enforceNotLocked(
      key: _passwordLoginKey(normalizedPhone),
      blockedMessage:
          'Too many password attempts were made. Please wait before trying again.',
    );

    try {
      final profile = await _authRepository.signInWithPhonePassword(
        phone: normalizedPhone,
        password: password,
      );
      await rememberCredentials(phone: normalizedPhone, password: password);
      await finalizeTrustedSession(profile);
      await clearPendingChallenge();
      await _clearAttempt(_passwordLoginKey(normalizedPhone));
      return profile;
    } on FirebaseAuthException {
      await _consumeAttempt(
        key: _passwordLoginKey(normalizedPhone),
        maxAttempts: _passwordFailureLimit,
        window: _passwordFailureWindow,
        lockout: _passwordFailureLockout,
        blockedMessage:
            'Too many password attempts were made. Please wait before trying again.',
      );
      rethrow;
    }
  }

  Future<UserProfile> signInWithDeviceCredential() async {
    final credentials = await _readStoredCredentialsOrThrow();
    final success = await _biometricService.authenticateWithDeviceCredential();
    if (!success) {
      throw StateError('Device credential verification was cancelled.');
    }

    return _signInWithStoredCredentials(credentials);
  }

  Future<UserProfile> signInWithBiometrics() async {
    final credentials = await _readStoredCredentialsOrThrow();
    final biometricEnabled = await _sessionService.isBiometricEnabled();
    if (!biometricEnabled) {
      throw StateError('Biometric sign-in is not enabled on this device.');
    }

    final success = await _biometricService.authenticateWithBiometrics();
    if (!success) {
      throw StateError('Biometric verification was cancelled.');
    }

    return _signInWithStoredCredentials(credentials);
  }

  Future<void> setBiometricEnabled(bool enabled) {
    return _sessionService.setBiometricEnabled(enabled);
  }

  Future<bool> isBiometricEnabled() {
    return _sessionService.isBiometricEnabled();
  }

  Future<UserProfile> _signInWithStoredCredentials(
    StoredAuthCredentials credentials,
  ) async {
    final password = await _decryptValue(credentials.encryptedPassword);
    final profile = await _authRepository.signInWithPhonePassword(
      phone: credentials.phone,
      password: password,
    );
    await finalizeTrustedSession(profile);
    return profile;
  }

  Future<void> _startPhoneVerification({
    required String phone,
    required bool isRegistration,
    required PendingChallengeCallback onCodeSent,
    required PendingChallengeCallback onCodeAutoRetrievalTimeout,
    required FutureOr<void> Function(UserProfile profile)
    onVerificationResolved,
    required FutureOr<void> Function(String message) onVerificationFailed,
    String? fullName,
    String? email,
    String? encryptedPassword,
    int? forceResendingToken,
    PendingAuthChallenge? existingChallenge,
  }) async {
    await _authRepository.startPhoneVerification(
      phone: phone,
      isRegistration: isRegistration,
      forceResendingToken: forceResendingToken,
      onCodeSent: (session) async {
        final now = DateTime.now();
        final challenge = PendingAuthChallenge(
          phone: phone,
          verificationId: session.verificationId,
          isRegistration: isRegistration,
          resendToken: session.resendToken,
          fullName: fullName,
          email: email,
          encryptedPassword: encryptedPassword,
          failedOtpAttempts: existingChallenge?.failedOtpAttempts ?? 0,
          sendCount: (existingChallenge?.sendCount ?? 0) + 1,
          createdAt: existingChallenge?.createdAt ?? now,
          lastCodeSentAt: now,
          resendAvailableAt: now.add(resendCooldown),
        );
        await cachePendingChallenge(challenge);
        await onCodeSent(challenge);
      },
      onCodeAutoRetrievalTimeout: (session) async {
        final now = DateTime.now();
        final current = await readPendingChallenge();
        final challenge = (current ??
                PendingAuthChallenge(
                  phone: phone,
                  verificationId: session.verificationId,
                  isRegistration: isRegistration,
                  resendToken: session.resendToken,
                  fullName: fullName,
                  email: email,
                  encryptedPassword: encryptedPassword,
                  createdAt: existingChallenge?.createdAt ?? now,
                  lastCodeSentAt: existingChallenge?.lastCodeSentAt ?? now,
                  resendAvailableAt: existingChallenge?.resendAvailableAt ??
                      now.add(resendCooldown),
                ))
            .copyWith(
              verificationId: session.verificationId,
              resendToken: session.resendToken,
            );
        await cachePendingChallenge(challenge);
        await onCodeAutoRetrievalTimeout(challenge);
      },
      onVerificationCompleted: (_) async {
        final challenge =
            await readPendingChallenge() ??
            PendingAuthChallenge(
              phone: phone,
              verificationId: existingChallenge?.verificationId ?? '',
              isRegistration: isRegistration,
              resendToken: forceResendingToken,
              fullName: fullName,
              email: email,
              encryptedPassword: encryptedPassword,
              createdAt: DateTime.now(),
              lastCodeSentAt: DateTime.now(),
              resendAvailableAt: DateTime.now(),
            );
        final profile = await _finalizeVerifiedChallenge(challenge);
        await onVerificationResolved(profile);
      },
      onVerificationFailed: (error) async {
        await onVerificationFailed(
          error.message ?? 'Phone verification failed. Please try again.',
        );
      },
    );
  }

  Future<UserProfile> _finalizeVerifiedChallenge(
    PendingAuthChallenge challenge,
  ) async {
    if (challenge.isRegistration) {
      final encryptedPassword = challenge.encryptedPassword;
      if (encryptedPassword == null || encryptedPassword.isEmpty) {
        throw StateError(
          'Your registration session expired. Please start again to protect your password.',
        );
      }

      final password = await _decryptValue(encryptedPassword);
      await _authRepository.linkPasswordCredential(
        phone: challenge.phone,
        password: password,
      );

      final existing = await _authRepository.getCurrentProfile();
      final profile = _authRepository.buildUpdatedProfile(
        existing: existing,
        fullName: (challenge.fullName ?? '').trim().isEmpty
            ? challenge.phone
            : challenge.fullName!.trim(),
        phone: challenge.phone,
        email: (challenge.email ?? '').trim().isEmpty
            ? null
            : challenge.email!.trim(),
        role: existing?.role ?? AppRole.owner,
      );
      await _authRepository.saveUserProfile(profile);
      await rememberCredentials(phone: challenge.phone, password: password);
      await finalizeTrustedSession(profile);
      await clearPendingChallenge();
      return profile;
    }

    final profile = await _authRepository.ensureCurrentUserProfile(
      phone: challenge.phone,
      role: AppRole.owner,
    );
    await finalizeTrustedSession(profile);
    await clearPendingChallenge();
    return profile;
  }

  Future<void> _recordOtpFailure(PendingAuthChallenge challenge) async {
    final attempts = challenge.failedOtpAttempts + 1;
    final updated = challenge.copyWith(failedOtpAttempts: attempts);
    await cachePendingChallenge(updated);

    if (attempts >= _otpFailureLimit) {
      await clearPendingChallenge();
      await _setLockout(
        key: _otpVerifyKey(challenge.phone),
        until: DateTime.now().add(_otpFailureLockout),
      );
      throw StateError(
        'Too many incorrect OTP attempts were made. Please request a new code after a short wait.',
      );
    }
  }

  Future<void> _consumeAttempt({
    required String key,
    required int maxAttempts,
    required Duration window,
    required Duration lockout,
    required String blockedMessage,
  }) async {
    final current = await _readAttempt(key);
    final now = DateTime.now();

    if (current.lockedUntil != null && now.isBefore(current.lockedUntil!)) {
      throw StateError(blockedMessage);
    }

    var firstAttemptAt = current.firstAttemptAt;
    var count = current.count;
    if (firstAttemptAt == null || now.difference(firstAttemptAt) > window) {
      firstAttemptAt = now;
      count = 0;
    }

    count += 1;
    DateTime? lockedUntil;
    if (count >= maxAttempts) {
      lockedUntil = now.add(lockout);
    }

    await _writeAttempt(
      key,
      _AttemptState(
        count: count,
        firstAttemptAt: firstAttemptAt,
        lockedUntil: lockedUntil,
      ),
    );

    if (lockedUntil != null) {
      throw StateError(blockedMessage);
    }
  }

  Future<void> _enforceNotLocked({
    required String key,
    required String blockedMessage,
  }) async {
    final current = await _readAttempt(key);
    final lockedUntil = current.lockedUntil;
    if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
      throw StateError(blockedMessage);
    }
  }

  Future<void> _setLockout({
    required String key,
    required DateTime until,
  }) async {
    final current = await _readAttempt(key);
    await _writeAttempt(
      key,
      _AttemptState(
        count: current.count,
        firstAttemptAt: current.firstAttemptAt ?? DateTime.now(),
        lockedUntil: until,
      ),
    );
  }

  Future<_AttemptState> _readAttempt(String key) async {
    final payload = await _secureStorageService.read(key);
    if (payload == null || payload.isEmpty) {
      return const _AttemptState();
    }

    final map = jsonDecode(payload) as Map<String, dynamic>;
    return _AttemptState(
      count: map['count'] as int? ?? 0,
      firstAttemptAt: _parseDate(map['firstAttemptAt']),
      lockedUntil: _parseDate(map['lockedUntil']),
    );
  }

  Future<void> _writeAttempt(String key, _AttemptState state) {
    return _secureStorageService.write(key, jsonEncode(state.toMap()));
  }

  Future<void> _clearAttempt(String key) {
    return _secureStorageService.delete(key);
  }

  Future<StoredAuthCredentials> _readStoredCredentialsOrThrow() async {
    final credentials = await readStoredCredentials();
    if (credentials == null) {
      throw StateError(
        'Secure saved credentials are not available on this device yet. Sign in with your password first.',
      );
    }
    return credentials;
  }

  Future<String> _encryptValue(String value) async {
    final keyBytes = _randomBytes(32);
    final nonce = _randomBytes(12);
    final secretKey = SecretKey(keyBytes);
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(value),
      secretKey: secretKey,
      nonce: nonce,
    );

    return jsonEncode({
      'k': base64Encode(keyBytes),
      'n': base64Encode(secretBox.nonce),
      'c': base64Encode(secretBox.cipherText),
      'm': base64Encode(secretBox.mac.bytes),
    });
  }

  Future<String> _decryptValue(String payload) async {
    final map = jsonDecode(payload) as Map<String, dynamic>;
    final secretKey = SecretKey(base64Decode(map['k'] as String));
    final secretBox = SecretBox(
      base64Decode(map['c'] as String),
      nonce: base64Decode(map['n'] as String),
      mac: Mac(base64Decode(map['m'] as String)),
    );

    final clearBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: secretKey,
    );
    return utf8.decode(clearBytes);
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }

  String _otpSendKey(String phone) => '${StorageKeys.otpSendAttemptPrefix}$phone';

  String _otpVerifyKey(String phone) =>
      '${StorageKeys.otpVerifyAttemptPrefix}$phone';

  String _passwordLoginKey(String phone) =>
      '${StorageKeys.passwordLoginAttemptPrefix}$phone';

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class _AttemptState {
  const _AttemptState({
    this.count = 0,
    this.firstAttemptAt,
    this.lockedUntil,
  });

  final int count;
  final DateTime? firstAttemptAt;
  final DateTime? lockedUntil;

  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'firstAttemptAt': firstAttemptAt?.toIso8601String(),
      'lockedUntil': lockedUntil?.toIso8601String(),
    };
  }
}
