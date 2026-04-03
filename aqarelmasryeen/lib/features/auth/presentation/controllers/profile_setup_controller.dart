import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileSetupController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> save({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).completeProfile(
        fullName: fullName,
        email: email,
        password: password,
      ),
    );
  }
}

final profileSetupControllerProvider =
    NotifierProvider<ProfileSetupController, AsyncValue<void>>(
      ProfileSetupController.new,
    );
