import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PhoneRegistrationState extends Equatable {
  const PhoneRegistrationState({
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
    final resendAvailableAt = this.resendAvailableAt;
    if (resendAvailableAt == null) return 0;
    final seconds = resendAvailableAt.difference(now).inSeconds;
    return seconds > 0 ? seconds : 0;
  }

  PhoneRegistrationState copyWith({
    String? phone,
    String? verificationId,
    int? resendToken,
    bool clearVerificationId = false,
    bool clearResendToken = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    DateTime? resendAvailableAt,
    bool clearResendAvailableAt = false,
  }) {
    return PhoneRegistrationState(
      phone: phone ?? this.phone,
      verificationId: clearVerificationId
          ? ''
          : verificationId ?? this.verificationId,
      resendToken: clearResendToken ? null : resendToken ?? this.resendToken,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      resendAvailableAt: clearResendAvailableAt
          ? null
          : resendAvailableAt ?? this.resendAvailableAt,
    );
  }

  @override
  List<Object?> get props => [
    phone,
    verificationId,
    resendToken,
    isSubmitting,
    errorMessage,
    resendAvailableAt,
  ];
}

class PhoneRegistrationController extends Notifier<PhoneRegistrationState> {
  @override
  PhoneRegistrationState build() => const PhoneRegistrationState();

  Future<void> requestOtp(String phone, {bool isResend = false}) async {
    state = state.copyWith(
      phone: phone,
      isSubmitting: true,
      clearError: true,
      clearVerificationId: !isResend,
      clearResendAvailableAt: !isResend,
      clearResendToken: !isResend,
    );

    try {
      await ref.read(authRepositoryProvider).sendOtp(
        phone: phone,
        resendToken: isResend ? state.resendToken : null,
        onCodeSent: (verificationId, resendToken) {
          state = state.copyWith(
            verificationId: verificationId,
            resendToken: resendToken,
            resendAvailableAt: DateTime.now().add(const Duration(seconds: 30)),
            isSubmitting: false,
            clearError: true,
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
    final remaining = state.remainingSeconds(DateTime.now());
    if (remaining > 0) {
      throw const AppException(
        'Please wait for the resend timer before requesting another code.',
      );
    }
    await requestOtp(state.phone, isResend: true);
  }

  Future<void> verifyOtp(String smsCode) async {
    if (state.verificationId.isEmpty) {
      throw const AppException('Start the phone verification flow again.');
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).verifyOtp(
        verificationId: state.verificationId,
        smsCode: smsCode.trim(),
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

  void reset() {
    state = const PhoneRegistrationState();
  }
}

final phoneRegistrationControllerProvider =
    NotifierProvider<PhoneRegistrationController, PhoneRegistrationState>(
      PhoneRegistrationController.new,
    );
