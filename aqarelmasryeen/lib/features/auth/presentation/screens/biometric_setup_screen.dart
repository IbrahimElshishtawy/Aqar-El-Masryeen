import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:aqarelmasryeen/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BiometricSetupScreen extends ConsumerWidget {
  const BiometricSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> submit(bool enabled) async {
      await ref.read(authRepositoryProvider).setBiometrics(enabled);
      if (context.mounted) context.go(AppRoutes.dashboard);
    }

    return AuthScaffold(
      title: 'Enable biometric unlock',
      subtitle:
          'Use Face ID, fingerprint, or device passcode to reopen the app after inactivity and protect sensitive finance data.',
      leading: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.fingerprint,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => submit(true),
              child: const Text('Enable biometrics'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => submit(false),
              child: const Text('Skip for now'),
            ),
          ),
        ],
      ),
    );
  }
}
