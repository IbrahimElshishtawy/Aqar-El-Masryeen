import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CredentialLoginController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password),
    );
  }
}

final credentialLoginControllerProvider =
    NotifierProvider<CredentialLoginController, AsyncValue<void>>(
      CredentialLoginController.new,
    );
