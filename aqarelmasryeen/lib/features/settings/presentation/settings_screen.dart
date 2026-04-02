import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/security/session_lock_controller.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _updatingBiometrics = false;
  bool _signingOut = false;

  Future<void> _setBiometrics(bool enabled) async {
    setState(() => _updatingBiometrics = true);
    try {
      if (enabled) {
        final service = ref.read(biometricServiceProvider);
        final isSupported = await service.canCheckBiometrics();
        if (!isSupported) {
          throw const AppException(
            'Biometric or device-credential unlock is not available on this device.',
          );
        }
        final isAuthenticated = await service.authenticate();
        if (!isAuthenticated) {
          throw const AppException('Security verification was canceled.');
        }
      }
      await ref.read(authRepositoryProvider).setBiometrics(enabled);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Secure unlock was enabled.'
                : 'Secure unlock was disabled.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapException(error).message)));
    } finally {
      if (mounted) setState(() => _updatingBiometrics = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
      ref.read(otpFlowControllerProvider.notifier).reset();
      if (mounted) context.go(AppRoutes.login);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapException(error).message)));
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;

    return AppShellScaffold(
      title: 'Settings',
      currentIndex: 4,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(
                session?.profile?.name.isNotEmpty == true
                    ? session!.profile!.name
                    : 'Partner account',
              ),
              subtitle: Text(
                session?.profile?.email ??
                    session?.firebaseUser.phoneNumber ??
                    '',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              value: session?.profile?.biometricEnabled ?? false,
              onChanged: _updatingBiometrics ? null : _setBiometrics,
              title: const Text('Secure unlock'),
              subtitle: Text(
                _updatingBiometrics
                    ? 'Updating security preference...'
                    : 'Use fingerprint, Face ID, or device passcode after inactivity',
              ),
              secondary: _updatingBiometrics
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fingerprint_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_clock_outlined),
              title: const Text('Lock now'),
              subtitle: const Text('Require authentication immediately'),
              onTap: () =>
                  ref.read(sessionLockControllerProvider.notifier).forceLock(),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ExpansionTile(
              title: const Text('Expense categories'),
              children: const [
                ListTile(title: Text('Construction')),
                ListTile(title: Text('Legal')),
                ListTile(title: Text('Permits')),
                ListTile(title: Text('Utilities')),
                ListTile(title: Text('Marketing')),
                ListTile(title: Text('Maintenance')),
                ListTile(title: Text('Brokerage')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _signingOut ? null : _signOut,
            icon: _signingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_outlined),
            label: Text(_signingOut ? 'Signing out...' : 'Secure logout'),
          ),
        ],
      ),
    );
  }
}
