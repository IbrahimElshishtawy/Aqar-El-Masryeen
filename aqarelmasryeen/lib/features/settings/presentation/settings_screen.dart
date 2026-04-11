import 'package:aqarelmasryeen/app/providers.dart';
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
  bool _notificationsEnabled = true;
  bool _loadingNotificationPreference = true;
  bool _updatingNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    try {
      final enabled = await ref
          .read(notificationServiceProvider)
          .areNotificationsEnabled();
      if (!mounted) {
        return;
      }
      setState(() {
        _notificationsEnabled = enabled;
        _loadingNotificationPreference = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingNotificationPreference = false);
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    setState(() => _updatingNotifications = true);
    try {
      await ref
          .read(notificationServiceProvider)
          .setNotificationsEnabled(enabled);
      if (!mounted) {
        return;
      }
      setState(() => _notificationsEnabled = enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'تم تشغيل الإشعارات على هذا الجهاز.'
                : 'تم إيقاف الإشعارات على هذا الجهاز.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapException(error).message)));
    } finally {
      if (mounted) {
        setState(() => _updatingNotifications = false);
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await ref.read(sessionLockControllerProvider.notifier).clearForLogout();
      await ref.read(authRepositoryProvider).signOut();
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
      title: 'الإعدادات',
      subtitle: 'الأمان وتفضيلات مساحة العمل',
      currentIndex: 3,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(
                profile?.fullName.isNotEmpty == true
                    ? profile!.fullName
                    : 'حساب الشريك',
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
              title: const Text('إعدادات الحماية'),
              subtitle: Text(
                'الجهاز الموثوق: ${profile?.trustedDeviceEnabled == true ? 'مفعل' : 'متوقف'} | قفل التطبيق: ${profile?.appLockEnabled == true ? 'يعمل' : 'متوقف'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.securitySetup),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile.adaptive(
              value: _notificationsEnabled,
              onChanged:
                  _loadingNotificationPreference || _updatingNotifications
                  ? null
                  : _toggleNotifications,
              secondary: _updatingNotifications
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.notifications_active_outlined),
              title: const Text('تشغيل الإشعارات'),
              subtitle: Text(
                _loadingNotificationPreference
                    ? 'جارٍ تحميل حالة الإشعارات...'
                    : _notificationsEnabled
                    ? 'استقبال التنبيهات على هذا الجهاز مفعل.'
                    : 'التنبيهات متوقفة على هذا الجهاز.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_clock_outlined),
              title: const Text('قفل الآن'),
              subtitle: const Text('اطلب البصمة أو قفل الجهاز فورًا.'),
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
              title: const Text('الجهاز الموثوق'),
              subtitle: Text(
                profile?.deviceInfo?.deviceName.isNotEmpty == true
                    ? '${profile!.deviceInfo!.deviceName} | ${profile.deviceInfo!.platform}'
                    : 'لا توجد بيانات محفوظة للجهاز الموثوق حتى الآن.',
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
            label: Text(_signingOut ? 'جار تسجيل الخروج...' : 'تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
