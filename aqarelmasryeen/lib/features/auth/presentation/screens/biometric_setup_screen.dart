import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() =>
      _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  bool _seeded = false;
  bool _cameFromOnboarding = false;
  bool _trustedDeviceEnabled = true;
  bool _biometricEnabled = true;
  bool _appLockEnabled = true;
  int _timeoutSeconds = AppConfig.defaultInactivityTimeoutSeconds;

  @override
  Widget build(BuildContext context) {
    final availability = ref.watch(biometricAvailabilityProvider);
    final state = ref.watch(securitySetupControllerProvider);
    final theme = Theme.of(context);
    final session = ref.watch(authSessionProvider).valueOrNull;

    if (!_seeded && session?.profile != null) {
      final profile = session!.profile!;
      _seeded = true;
      _cameFromOnboarding = session.needsSecuritySetup;
      _trustedDeviceEnabled = profile.trustedDeviceEnabled;
      _biometricEnabled = profile.biometricEnabled;
      _appLockEnabled = profile.appLockEnabled;
      _timeoutSeconds = profile.inactivityTimeoutSeconds;
      if (!_trustedDeviceEnabled && !profile.isSecuritySetupComplete) {
        _trustedDeviceEnabled = true;
        _biometricEnabled = true;
      }
    }

    ref.listen<AsyncValue<void>>(securitySetupControllerProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapException(next.error!).message)),
        );
      }
      if ((previous?.isLoading ?? false) && next.hasValue && mounted) {
        if (_cameFromOnboarding) {
          context.go(AppRoutes.dashboard);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Security settings updated.')),
          );
        }
      }
    });

    Future<void> submit() {
      return ref
          .read(securitySetupControllerProvider.notifier)
          .submit(
            trustedDeviceEnabled: _trustedDeviceEnabled,
            biometricEnabled: _biometricEnabled,
            appLockEnabled: _appLockEnabled,
            inactivityTimeoutSeconds: _timeoutSeconds,
          );
    }

    return AuthScaffold(
      title: 'Secure this device',
      subtitle:
          'Configure biometric or device-credential unlock and automatic app locking for this finance workspace.',
      leading: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.fingerprint, color: theme.colorScheme.primary),
      ),
      child: availability.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Text(mapException(error).message),
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile.adaptive(
              value: _trustedDeviceEnabled,
              onChanged: (value) {
                setState(() {
                  _trustedDeviceEnabled = value;
                  if (!value) {
                    _biometricEnabled = false;
                    _appLockEnabled = false;
                  }
                });
              },
              title: const Text('Enable trusted-device quick unlock'),
              subtitle: Text(
                data.canUseSecureUnlock
                    ? 'Uses: ${data.methodsLabel}'
                    : 'This device cannot use biometrics or device credentials.',
              ),
            ),
            SwitchListTile.adaptive(
              value: _biometricEnabled && _trustedDeviceEnabled,
              onChanged:
                  _trustedDeviceEnabled && data.availableBiometrics.isNotEmpty
                  ? (value) => setState(() => _biometricEnabled = value)
                  : null,
              title: const Text('Prefer biometrics when available'),
              subtitle: const Text(
                'Device passcode/PIN remains available when the operating system allows it.',
              ),
            ),
            SwitchListTile.adaptive(
              value: _appLockEnabled && _trustedDeviceEnabled,
              onChanged: _trustedDeviceEnabled
                  ? (value) => setState(() => _appLockEnabled = value)
                  : null,
              title: const Text('Lock app after inactivity'),
              subtitle: const Text(
                'The session also locks when the app remains in the background beyond the timeout.',
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _timeoutSeconds,
              decoration: const InputDecoration(
                labelText: 'Inactivity timeout',
                prefixIcon: Icon(Icons.timer_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 30, child: Text('30 seconds')),
                DropdownMenuItem(value: 60, child: Text('1 minute')),
                DropdownMenuItem(value: 90, child: Text('90 seconds')),
                DropdownMenuItem(value: 180, child: Text('3 minutes')),
                DropdownMenuItem(value: 300, child: Text('5 minutes')),
              ],
              onChanged: _trustedDeviceEnabled && _appLockEnabled
                  ? (value) {
                      if (value != null) {
                        setState(() => _timeoutSeconds = value);
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.isLoading ? null : submit,
                icon: state.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.shield_outlined),
                label: Text(state.isLoading ? 'Saving...' : 'Finish setup'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        setState(() {
                          _trustedDeviceEnabled = false;
                          _biometricEnabled = false;
                          _appLockEnabled = false;
                        });
                        submit();
                      },
                child: const Text('Skip quick unlock for now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
