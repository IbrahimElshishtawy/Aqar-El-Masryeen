import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .registerWithEmail(
            fullName: fullName,
            email: email,
            password: password,
          ),
    );
  }
}

final registerControllerProvider =
    NotifierProvider<RegisterController, AsyncValue<void>>(
      RegisterController.new,
    );
