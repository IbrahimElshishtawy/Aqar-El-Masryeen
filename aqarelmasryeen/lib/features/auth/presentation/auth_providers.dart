import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

final authSessionProvider = StreamProvider<AppSession?>((ref) {
  return ref.watch(authRepositoryProvider).watchSession();
});

final otpTickerProvider = StreamProvider<DateTime>((ref) {
  return Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});

class BiometricAvailability {
  const BiometricAvailability({
    required this.isSupported,
    required this.methods,
  });

  final bool isSupported;
  final List<BiometricType> methods;

  String get methodsLabel {
    if (methods.isEmpty) return 'Device credentials';

    final labels = methods.map((type) {
      switch (type) {
        case BiometricType.face:
        case BiometricType.strong:
          return 'Face ID / strong biometrics';
        case BiometricType.fingerprint:
          return 'Fingerprint';
        case BiometricType.iris:
          return 'Iris';
        case BiometricType.weak:
          return 'Biometrics';
      }
    }).toSet();

    return labels.join(' / ');
  }
}

final biometricAvailabilityProvider = FutureProvider<BiometricAvailability>((
  ref,
) async {
  final service = ref.watch(biometricServiceProvider);
  final isSupported = await service.canCheckBiometrics();
  final methods = isSupported ? await service.getAvailableBiometrics() : const <BiometricType>[];
  return BiometricAvailability(isSupported: isSupported, methods: methods);
});

const _sentinel = Object();

class OtpFlowState {
  const OtpFlowState({
    this.phone = '',
    this.verificationId = '',
    this.resendToken,
    this.isSubmitting = false,
    this.errorMessage,
    this.resendAvailableAt,
  });

  final String phone;
  final String verificationId;
  final int? resendToken;
  final bool isSubmitting;
  final String? errorMessage;
  final DateTime? resendAvailableAt;

  bool get hasCodeSent => verificationId.isNotEmpty;

  int remainingSeconds(DateTime now) {
    final availableAt = resendAvailableAt;
    if (availableAt == null) return 0;
    final seconds = availableAt.difference(now).inSeconds;
    return seconds > 0 ? seconds : 0;
  }

  bool canResend(DateTime now) =>
      hasCodeSent && !isSubmitting && remainingSeconds(now) == 0;

  OtpFlowState copyWith({
    String? phone,
    String? verificationId,
    Object? resendToken = _sentinel,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
    Object? resendAvailableAt = _sentinel,
  }) {
    return OtpFlowState(
      phone: phone ?? this.phone,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken == _sentinel
          ? this.resendToken
          : resendToken as int?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      resendAvailableAt: resendAvailableAt == _sentinel
          ? this.resendAvailableAt
          : resendAvailableAt as DateTime?,
    );
  }
}

class OtpFlowController extends Notifier<OtpFlowState> {
  @override
  OtpFlowState build() => const OtpFlowState();

  Future<void> requestOtp(String phone, {bool isResend = false}) async {
    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      phone: phone,
      verificationId: isResend ? null : '',
      resendToken: isResend ? _sentinel : null,
      resendAvailableAt: isResend ? _sentinel : null,
    );
    try {
      await ref
          .read(authRepositoryProvider)
          .sendOtp(
            phone: phone,
            resendToken: isResend ? state.resendToken : null,
            onCodeSent: (verificationId, resendToken) {
              state = state.copyWith(
                verificationId: verificationId,
                resendToken: resendToken,
                resendAvailableAt: DateTime.now().add(
                  const Duration(seconds: 30),
                ),
                isSubmitting: false,
                errorMessage: null,
              );
            },
          );
      state = state.copyWith(isSubmitting: false);
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: mapException(error).message,
      );
      rethrow;
    }
  }

  Future<void> resendOtp() async {
    final now = DateTime.now();
    if (!state.canResend(now)) {
      throw const AppException('Please wait a moment before requesting a new code.');
    }
    await requestOtp(state.phone, isResend: true);
  }

  Future<void> verifyOtp(String smsCode) async {
    if (state.verificationId.isEmpty) {
      throw const AppException('Start the phone verification flow again.');
    }
    if (smsCode.trim().length != 6) {
      throw const AppException('Enter the 6-digit verification code.');
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyOtp(
            verificationId: state.verificationId,
            smsCode: smsCode.trim(),
          );
      state = state.copyWith(isSubmitting: false, errorMessage: null);
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: mapException(error).message,
      );
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void reset() {
    state = const OtpFlowState();
  }
}

final otpFlowControllerProvider =
    NotifierProvider<OtpFlowController, OtpFlowState>(OtpFlowController.new);

class EmailSignInController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password),
    );
  }
}

final emailSignInControllerProvider =
    NotifierProvider<EmailSignInController, AsyncValue<void>>(
      EmailSignInController.new,
    );

class ProfileCompletionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> save({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).completeProfile(
            name: name,
            email: email,
            password: password,
          ),
    );
  }
}

final profileCompletionControllerProvider =
    NotifierProvider<ProfileCompletionController, AsyncValue<void>>(
      ProfileCompletionController.new,
    );

class BiometricSetupController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit(bool enabled) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (enabled) {
        final isAuthenticated = await ref
            .read(biometricServiceProvider)
            .authenticate();
        if (!isAuthenticated) {
          throw const AppException('Authentication was canceled. Biometrics were not enabled.');
        }
      }
      await ref.read(authRepositoryProvider).setBiometrics(enabled);
    });
  }
}

final biometricSetupControllerProvider =
    NotifierProvider<BiometricSetupController, AsyncValue<void>>(
      BiometricSetupController.new,
    );
