import 'package:aqarelmasryeen/core\security\session_lock_controller.dart';
import 'package:aqarelmasryeen/core\widgets\app_shell_scaffold.dart';
import 'package:aqarelmasryeen/features\auth\data\firebase_auth_repository.dart';
import 'package:aqarelmasryeen/features\auth\presentation\auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              title: Text(session?.profile?.name.isNotEmpty == true ? session!.profile!.name : 'Partner account'),
              subtitle: Text(session?.profile?.email ?? session?.firebaseUser.phoneNumber ?? ''),
            ),
          ),
          Card(
            child: SwitchListTile(
              value: session?.profile?.biometricEnabled ?? false,
              onChanged: (value) => ref.read(authRepositoryProvider).setBiometrics(value),
              title: const Text('Biometric unlock'),
              subtitle: const Text('Use fingerprint, Face ID, or device passcode'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_clock_outlined),
              title: const Text('Lock now'),
              subtitle: const Text('Require authentication immediately'),
              onTap: () => ref.read(sessionLockControllerProvider.notifier).forceLock(),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_none_outlined),
              title: const Text('Notification center'),
              onTap: () => context.push('/notifications'),
            ),
          ),
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
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/auth/login');
            },
            child: const Text('Secure logout'),
          ),
        ],
      ),
    );
  }
}
