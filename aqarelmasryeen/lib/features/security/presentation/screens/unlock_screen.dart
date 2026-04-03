import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:aqarelmasryeen/features/security/presentation/controllers/unlock_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UnlockScreen extends ConsumerWidget {
  const UnlockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(unlockControllerProvider);
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    ref.listen<UnlockState>(unlockControllerProvider, (previous, next) {
      if ((previous?.isUnlocking ?? false) &&
          !next.isUnlocking &&
          next.errorMessage == null &&
          context.mounted) {
        context.go(AppRoutes.dashboard);
      }
      if ((next.errorMessage ?? '').isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final displayName = session?.profile?.fullName;

    return AuthScaffold(
      title: 'Unlock workspace',
      subtitle:
          'The session for ${displayName?.isNotEmpty == true ? displayName : 'the partner account'} is locked. Authenticate with biometrics or device credentials to continue.',
      leading: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: state.isUnlocking
                  ? null
                  : () => ref.read(unlockControllerProvider.notifier).unlock(),
              icon: state.isUnlocking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fingerprint),
              label: Text(state.isUnlocking ? 'Unlocking...' : 'Unlock now'),
            ),
          ),
          const SizedBox(height: 12),
          if (state.canFallbackToLogin)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  try {
                    await ref
                        .read(unlockControllerProvider.notifier)
                        .useFullLoginFallback();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(mapException(error).message)),
                      );
                    }
                  }
                },
                child: const Text('Use full login instead'),
              ),
            ),
        ],
      ),
    );
  }
}
