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
            const SnackBar(content: Text('تم تحديث إعدادات الأمان.')),
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
      title: 'تأمين هذا الجهاز',
      subtitle:
          'اضبط فتح التطبيق بالبصمة أو ببيانات قفل الجهاز مع القفل التلقائي لمساحة العمل.',
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
              title: const Text('تفعيل الفتح السريع للجهاز الموثوق'),
              subtitle: Text(
                data.canUseSecureUnlock
                    ? 'طريقة الفتح: ${data.methodsLabel}'
                    : 'هذا الجهاز لا يدعم البصمة أو بيانات قفل الجهاز.',
              ),
            ),
            SwitchListTile.adaptive(
              value: _biometricEnabled && _trustedDeviceEnabled,
              onChanged:
                  _trustedDeviceEnabled && data.availableBiometrics.isNotEmpty
                  ? (value) => setState(() => _biometricEnabled = value)
                  : null,
              title: const Text('استخدام البصمة عند توفرها'),
              subtitle: const Text(
                'سيظل رمز الجهاز أو كلمة المرور متاحين إذا كان نظام التشغيل يسمح بذلك.',
              ),
            ),
            SwitchListTile.adaptive(
              value: _appLockEnabled && _trustedDeviceEnabled,
              onChanged: _trustedDeviceEnabled
                  ? (value) => setState(() => _appLockEnabled = value)
                  : null,
              title: const Text('قفل التطبيق بعد عدم النشاط'),
              subtitle: const Text(
                'يتم قفل الجلسة أيضًا إذا بقي التطبيق في الخلفية لمدة تتجاوز المهلة المحددة.',
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _timeoutSeconds,
              decoration: const InputDecoration(
                labelText: 'مهلة عدم النشاط',
                prefixIcon: Icon(Icons.timer_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 30, child: Text('30 ثانية')),
                DropdownMenuItem(value: 60, child: Text('دقيقة واحدة')),
                DropdownMenuItem(value: 90, child: Text('90 ثانية')),
                DropdownMenuItem(value: 180, child: Text('3 دقائق')),
                DropdownMenuItem(value: 300, child: Text('5 دقائق')),
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
                label: Text(state.isLoading ? 'جار الحفظ...' : 'إنهاء الإعداد'),
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
                child: const Text('تخطي الفتح السريع الآن'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
