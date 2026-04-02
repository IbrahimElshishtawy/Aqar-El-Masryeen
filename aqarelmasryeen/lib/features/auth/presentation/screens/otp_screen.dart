import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/utils/phone_utils.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_validators.dart';
import 'package:aqarelmasryeen/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(otpFlowControllerProvider.notifier)
          .verifyOtp(_codeController.text);
      final session = await ref.read(authSessionProvider.future);
      if (!mounted) return;
      context.go(
        session?.isProfileComplete == true
            ? AppRoutes.dashboard
            : AppRoutes.profile,
      );
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapException(error).message)));
    }
  }

  Future<void> _resendCode() async {
    try {
      await ref.read(otpFlowControllerProvider.notifier).resendOtp();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A fresh verification code was sent.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapException(error).message)));
    }
  }

  void _changeNumber() {
    ref.read(otpFlowControllerProvider.notifier).reset();
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(otpTickerProvider);
    final state = ref.watch(otpFlowControllerProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final remainingSeconds = state.remainingSeconds(now);

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
    );

    return AuthScaffold(
      title: 'Verify one-time code',
      subtitle:
          'Enter the 6-digit code sent to ${PhoneUtils.maskForDisplay(state.phone)} to continue the secure sign-in flow.',
      leading: IconButton.filledTonal(
        onPressed: _changeNumber,
        icon: const Icon(Icons.arrow_back),
      ),
      footer: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                remainingSeconds > 0
                    ? 'You can request a new code in ${remainingSeconds}s.'
                    : 'Did not receive the code? Request another SMS now.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verification code',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Auto-fill is supported when available. You can also change the phone number if it was entered incorrectly.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Pinput(
                    controller: _codeController,
                    length: 6,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyDecorationWith(
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 1.4,
                      ),
                    ),
                    errorPinTheme: defaultPinTheme.copyDecorationWith(
                      border: Border.all(
                        color: theme.colorScheme.error,
                        width: 1.2,
                      ),
                    ),
                    validator: AuthValidators.otp,
                    onCompleted: (_) => _verify(),
                  ),
                  if ((state.errorMessage ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      state.errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: state.isSubmitting ? null : _verify,
                      icon: state.isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_user_outlined),
                      label: Text(
                        state.isSubmitting
                            ? 'Verifying...'
                            : 'Verify and continue',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: state.canResend(now) ? _resendCode : null,
                      child: Text(
                        remainingSeconds > 0
                            ? 'Resend code in ${remainingSeconds}s'
                            : 'Resend code',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _changeNumber,
                    child: const Text('Change phone number'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
