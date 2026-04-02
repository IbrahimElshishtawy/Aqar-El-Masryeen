import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BiometricSetupScreen extends ConsumerWidget {
  const BiometricSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(biometricAvailabilityProvider);
    final actionState = ref.watch(biometricSetupControllerProvider);
    final theme = Theme.of(context);

    ref.listen<AsyncValue<void>>(biometricSetupControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapException(next.error!).message)),
        );
      }
      if ((previous?.isLoading ?? false) && next.hasValue && context.mounted) {
        context.go(AppRoutes.dashboard);
      }
    });

    Future<void> submit(bool enabled) {
      return ref
          .read(biometricSetupControllerProvider.notifier)
          .submit(enabled);
    }

    return AuthScaffold(
      title: 'Protect the workspace',
      subtitle:
          'Use Face ID, fingerprint, or device credentials to reopen the app after inactivity and secure financial records.',
      leading: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.fingerprint,
          size: 32,
          color: theme.colorScheme.primary,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            child: availability.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Text(
                mapException(error).message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.isSupported
                        ? 'This device can protect app access'
                        : 'Secure unlock is unavailable on this device',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.isSupported
                        ? 'Available methods: ${data.methodsLabel}. A quick verification will be requested before enabling protection.'
                        : 'You can continue without biometric unlock and enable it later from Settings when device support is available.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.76,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: data.isSupported && !actionState.isLoading
                          ? () => submit(true)
                          : null,
                      icon: actionState.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.shield_outlined),
                      label: const Text('Enable secure unlock'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: actionState.isLoading
                          ? null
                          : () => submit(false),
                      child: const Text('Skip for now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
