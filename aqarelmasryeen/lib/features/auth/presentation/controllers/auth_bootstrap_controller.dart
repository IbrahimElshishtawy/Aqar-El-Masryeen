import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/security/session_lock_controller.dart';
import 'package:aqarelmasryeen/core/services/secure_storage_service.dart';
import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
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

  try {
    final session = await ref
        .read(authSessionProvider.future)
        .timeout(const Duration(seconds: 8));
    await ref.read(sessionLockControllerProvider.notifier).ensureInitialized();
    final lockState = ref.read(sessionLockControllerProvider);

    if (session == null) {
      return _decisionFromLocalState(storage);
    }

    if (!session.isActive) {
      await ref.read(authRepositoryProvider).signOut();
      return const AuthBootstrapDecision(AppRoutes.login);
    }

    if (!session.isProfileComplete) {
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
    await ref.read(sessionLockControllerProvider.notifier).ensureInitialized();
    return _decisionFromLocalState(storage);
  }
});

Future<AuthBootstrapDecision> _decisionFromLocalState(
  SecureStorageService storage,
) async {
  final hasOpenedApp = await storage.hasOpenedAppBefore();
  final lastUid = await storage.readLastKnownUid();
  return AuthBootstrapDecision(
    !hasOpenedApp || (lastUid == null || lastUid.isEmpty)
        ? AppRoutes.register
        : AppRoutes.login,
  );
}
