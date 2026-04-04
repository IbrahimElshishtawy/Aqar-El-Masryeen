import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_validators.dart';
import 'package:aqarelmasryeen/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState
    extends ConsumerState<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _seeded = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _requiresPassword(WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final user = session?.firebaseUser;
    if (user == null) {
      return false;
    }
    final hasEmailProvider = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    return !hasEmailProvider || (user.email?.trim().isEmpty ?? true);
  }

  Future<void> _submit(bool requiresPassword) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(profileSetupControllerProvider.notifier)
        .save(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: requiresPassword ? _passwordController.text : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileSetupControllerProvider);
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);
    final requiresPassword = _requiresPassword(ref);
    final authEmail = session?.firebaseUser.email?.trim() ?? '';

    if (!_seeded && session != null) {
      _seeded = true;
      _nameController.text =
          session.profile?.fullName ?? session.firebaseUser.displayName ?? '';
      _emailController.text = session.profile?.email.isNotEmpty == true
          ? session.profile!.email
          : authEmail;
    }

    ref.listen<AsyncValue<void>>(profileSetupControllerProvider, (
      previous,
      next,
    ) {
      if (!mounted) {
        return;
      }
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapException(next.error!).message)),
        );
      }
      if ((previous?.isLoading ?? false) && next.hasValue) {
        context.go(AppRoutes.securitySetup);
      }
    });

    return AuthScaffold(
      title: 'استكمال الملف الشخصي',
      subtitle:
          'أكمل بيانات الملف الشخصي حتى يعمل التوجيه وقفل التطبيق وسجل الأنشطة بشكل طبيعي.',
      leading: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
      ),
      footer: Text(
        requiresPassword
            ? 'هذا الحساب ما زال يحتاج إلى ربط كلمة مرور بالبريد الإلكتروني. اختر كلمة مرور قوية لإكمال الترحيل إلى نظام الدخول الجديد.'
            : 'سيتم استخدام البريد الإلكتروني الحالي كمعرّف تسجيل الدخول الأساسي لهذا الحساب.',
        style: theme.textTheme.bodyMedium,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: AuthValidators.name,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              readOnly: authEmail.isNotEmpty && !requiresPassword,
              keyboardType: TextInputType.emailAddress,
              textInputAction: requiresPassword
                  ? TextInputAction.next
                  : TextInputAction.done,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: AuthValidators.email,
            ),
            if (requiresPassword) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: AuthValidators.password,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_person_outlined),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) => AuthValidators.confirmPassword(
                  value,
                  _passwordController.text,
                ),
                onFieldSubmitted: (_) => _submit(requiresPassword),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () => _submit(requiresPassword),
                icon: state.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(state.isLoading ? 'جار الحفظ...' : 'متابعة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
