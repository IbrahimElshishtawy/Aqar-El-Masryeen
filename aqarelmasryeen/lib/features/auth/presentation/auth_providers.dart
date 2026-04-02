import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authSessionProvider = StreamProvider<AppSession?>((ref) {
  return ref.watch(authRepositoryProvider).watchSession();
});

class OtpFlowState {
  const OtpFlowState({
    this.phone = '',
    this.verificationId = '',
    this.resendToken,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final String phone;
  final String verificationId;
  final int? resendToken;
  final bool isSubmitting;
  final String? errorMessage;

  OtpFlowState copyWith({
    String? phone,
    String? verificationId,
    int? resendToken,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return OtpFlowState(
      phone: phone ?? this.phone,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class OtpFlowController extends Notifier<OtpFlowState> {
  @override
  OtpFlowState build() => const OtpFlowState();

  Future<void> requestOtp(String phone) async {
    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      phone: phone,
    );
    try {
      await ref
          .read(authRepositoryProvider)
          .sendOtp(
            phone: phone,
            onCodeSent: (verificationId, resendToken) {
              state = state.copyWith(
                verificationId: verificationId,
                resendToken: resendToken,
                isSubmitting: false,
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

  Future<void> verifyOtp(String smsCode) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyOtp(verificationId: state.verificationId, smsCode: smsCode);
      state = state.copyWith(isSubmitting: false);
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: mapException(error).message,
      );
      rethrow;
    }
  }
}

final otpFlowControllerProvider =
    NotifierProvider<OtpFlowController, OtpFlowState>(OtpFlowController.new);
