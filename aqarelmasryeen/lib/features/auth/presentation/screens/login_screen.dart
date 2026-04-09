import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_validators.dart';
import 'package:aqarelmasryeen/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(credentialLoginControllerProvider.notifier)
        .signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(credentialLoginControllerProvider);
    final theme = Theme.of(context);

    ref.listen<AsyncValue<void>>(credentialLoginControllerProvider, (
      previous,
      next,
    ) {
      if (!mounted || !next.hasError) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapException(next.error!).message)),
      );
    });

    return AuthScaffold(
      maxWidth: 600,
      title: 'تسجيل الدخول',
      subtitle:
          'ادخل إلى مساحة العمل المحاسبية باستخدام البريد الإلكتروني وكلمة المرور.',
      leading: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Icon(
          Icons.lock_person_outlined,
          size: 26,
          color: theme.colorScheme.primary,
        ),
      ),
      footer: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 18,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'بيانات الدخول لا تُحفظ محليًا، فقط إعدادات الأمان السريع.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'الوصول لمساحة الشريك',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.65),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'البريد الإلكتروني',
                        prefixIcon: Icon(
                          Icons.alternate_email_rounded,
                          size: 20,
                          color: theme.colorScheme.secondary,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerLowest,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.2,
                          ),
                        ),
                      ),
                      validator: AuthValidators.email,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'كلمة المرور',
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: theme.colorScheme.secondary,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerLowest,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.2,
                          ),
                        ),
                      ),
                      validator: AuthValidators.loginPassword,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: state.isLoading ? null : _submit,
                      icon: state.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login_rounded, size: 20),
                      label: Text(
                        state.isLoading ? 'جار تسجيل الدخول...' : 'دخول',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
            ),
            child: TextButton.icon(
              onPressed: () => context.go(AppRoutes.register),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('إنشاء حساب جديد'),
            ),
          ),
        ],
      ),
    );
  }
}
