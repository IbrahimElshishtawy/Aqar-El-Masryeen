import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
import 'package:aqarelmasryeen/core/security/session_lock_controller.dart';
import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnlockState extends Equatable {
  const UnlockState({
    this.isUnlocking = false,
    this.failedAttempts = 0,
    this.errorMessage,
  });

  final bool isUnlocking;
  final int failedAttempts;
  final String? errorMessage;

  bool get canFallbackToLogin => failedAttempts >= 3;

  UnlockState copyWith({
    bool? isUnlocking,
    int? failedAttempts,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UnlockState(
      isUnlocking: isUnlocking ?? this.isUnlocking,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isUnlocking, failedAttempts, errorMessage];
}

class UnlockController extends Notifier<UnlockState> {
  @override
  UnlockState build() => const UnlockState();

  Future<void> unlock() async {
    final lockState = ref.read(sessionLockControllerProvider);
    if (!lockState.shouldPresentUnlock) {
      throw const AppException('هذه الجلسة ليست مقفلة حاليًا.');
    }

    state = state.copyWith(isUnlocking: true, clearError: true);
    try {
      final authenticated = await ref
          .read(biometricServiceProvider)
          .authenticate(reason: 'تحقق لفتح مساحة العمل المحاسبية');
      if (!authenticated) {
        throw const AppException('تم إلغاء عملية التحقق.');
      }
      await ref.read(sessionLockControllerProvider.notifier).unlock();
      state = const UnlockState();
    } catch (error) {
      state = state.copyWith(
        isUnlocking: false,
        failedAttempts: state.failedAttempts + 1,
        errorMessage: mapException(error).message,
      );
      rethrow;
    }
  }

  Future<void> useFullLoginFallback() async {
    await ref.read(sessionLockControllerProvider.notifier).clearForLogout();
    await ref.read(authRepositoryProvider).signOut();
  }
}

final unlockControllerProvider =
    NotifierProvider<UnlockController, UnlockState>(UnlockController.new);
