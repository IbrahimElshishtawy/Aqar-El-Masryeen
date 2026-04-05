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
  bool _signingOut = false;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapException(error).message)));
    } finally {
      if (mounted) {
        setState(() => _signingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final profile = session?.profile;

    return AppShellScaffold(
      title: 'Settings',
      subtitle: 'Security and workspace preferences',
      currentIndex: 2,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(
                profile?.fullName.isNotEmpty == true
                    ? profile!.fullName
                    : 'Partner account',
              ),
              subtitle: Text(
                profile?.email.isNotEmpty == true
                    ? profile!.email
                    : session?.phoneNumber ?? '',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Security setup'),
              subtitle: Text(
                'Trusted device: ${profile?.trustedDeviceEnabled == true ? 'Enabled' : 'Off'} | App lock: ${profile?.appLockEnabled == true ? 'On' : 'Off'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.securitySetup),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_clock_outlined),
              title: const Text('Lock now'),
              subtitle: const Text(
                'Require biometrics or device unlock immediately.',
              ),
              onTap: () async {
                final router = GoRouter.of(context);
                await ref
                    .read(sessionLockControllerProvider.notifier)
                    .forceLock();
                if (context.mounted) {
                  router.go(AppRoutes.unlock);
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone_android_outlined),
              title: const Text('Trusted device'),
              subtitle: Text(
                profile?.deviceInfo?.deviceName.isNotEmpty == true
                    ? '${profile!.deviceInfo!.deviceName} | ${profile.deviceInfo!.platform}'
                    : 'No trusted device details available yet.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: _signingOut ? null : _signOut,
            icon: _signingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_outlined),
            label: Text(_signingOut ? 'Signing out...' : 'Sign out'),
          ),
        ],
      ),
    );
  }
}
