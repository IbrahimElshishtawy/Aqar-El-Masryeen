import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/security/session_lock_controller.dart';
import 'package:aqarelmasryeen/core/services/secure_storage_service.dart';
import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:aqarelmasryeen/shared/models/app_user.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthBootstrapDecision extends Equatable {
  const AuthBootstrapDecision(this.route);

  final String route;

  @override
  List<Object?> get props => [route];
}

final authBootstrapControllerProvider = FutureProvider<AuthBootstrapDecision>((
  ref,
) async {
  final storage = ref.read(secureStorageProvider);
  final localDataSource = ref.read(authLocalDataSourceProvider);
  final sessionLockNotifier = ref.read(sessionLockControllerProvider.notifier);

  try {
    await sessionLockNotifier.ensureInitialized();
    final session = await ref
        .read(authRepositoryProvider)
        .restoreSession()
        .timeout(const Duration(seconds: 4));
    final lockState = ref.read(sessionLockControllerProvider);

    if (session == null) {
      return _decisionFromLocalState(
        storage: storage,
        cachedProfile: await localDataSource.readLastKnownProfile(),
        lockState: lockState,
      );
    }

    if (!session.isActive) {
      await ref.read(authRepositoryProvider).signOut();
      return const AuthBootstrapDecision(AppRoutes.login);
    }

    if (session.needsProfileCompletion) {
      return const AuthBootstrapDecision(AppRoutes.profile);
    }

    if (session.needsSecuritySetup) {
      return const AuthBootstrapDecision(AppRoutes.securitySetup);
    }

    if (lockState.shouldPresentUnlock) {
      return const AuthBootstrapDecision(AppRoutes.unlock);
    }

    return const AuthBootstrapDecision(AppRoutes.dashboard);
  } catch (_) {
    await sessionLockNotifier.ensureInitialized();
    return _decisionFromLocalState(
      storage: storage,
      cachedProfile: await localDataSource.readLastKnownProfile(),
      lockState: ref.read(sessionLockControllerProvider),
    );
  }
});

Future<AuthBootstrapDecision> _decisionFromLocalState({
  required SecureStorageService storage,
  required AppUser? cachedProfile,
  required SessionLockState lockState,
}) async {
  await storage.hasOpenedAppBefore();
  await storage.readLastKnownUid();

  if (cachedProfile != null) {
    if (!cachedProfile.isActive) {
      return const AuthBootstrapDecision(AppRoutes.login);
    }
    if (!cachedProfile.isProfileComplete) {
      return const AuthBootstrapDecision(AppRoutes.profile);
    }
    if (!cachedProfile.isSecuritySetupComplete) {
      return const AuthBootstrapDecision(AppRoutes.securitySetup);
    }
    if (lockState.shouldPresentUnlock) {
      return const AuthBootstrapDecision(AppRoutes.unlock);
    }
    return const AuthBootstrapDecision(AppRoutes.dashboard);
  }

  return const AuthBootstrapDecision(AppRoutes.login);
}
