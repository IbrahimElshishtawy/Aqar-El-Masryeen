import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:aqarelmasryeen/features/auth/presentation/controllers/auth_bootstrap_controller.dart';
import 'package:aqarelmasryeen/features/auth/presentation/controllers/credential_login_controller.dart';
import 'package:aqarelmasryeen/features/auth/presentation/controllers/phone_registration_controller.dart';
import 'package:aqarelmasryeen/features/auth/presentation/controllers/profile_setup_controller.dart';
import 'package:aqarelmasryeen/features/auth/presentation/controllers/security_setup_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authSessionProvider = StreamProvider<AppSession?>((ref) {
  return ref.watch(authRepositoryProvider).watchSession();
});

final otpTickerProvider = StreamProvider<DateTime>((ref) {
  return Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});

final biometricAvailabilityProvider = FutureProvider((ref) async {
  return ref.read(biometricServiceProvider).getAvailability();
});

export 'controllers/auth_bootstrap_controller.dart';
export 'controllers/credential_login_controller.dart';
export 'controllers/phone_registration_controller.dart';
export 'controllers/profile_setup_controller.dart';
export 'controllers/security_setup_controller.dart';
