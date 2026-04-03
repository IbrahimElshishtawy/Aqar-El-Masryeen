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
          .read(phoneRegistrationControllerProvider.notifier)
          .verifyOtp(_codeController.text.trim());
      final session = await ref.read(authSessionProvider.future);
      if (!mounted) return;
      context.go(
        session?.isProfileComplete == true
            ? AppRoutes.securitySetup
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
      await ref.read(phoneRegistrationControllerProvider.notifier).resendOtp();
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

  @override
  Widget build(BuildContext context) {
    ref.watch(otpTickerProvider);
    final state = ref.watch(phoneRegistrationControllerProvider);
    final theme = Theme.of(context);
    final remaining = state.remainingSeconds(DateTime.now());

    return AuthScaffold(
      title: 'Verify OTP',
      subtitle:
          'Enter the 6-digit code sent to ${PhoneUtils.maskForDisplay(state.phone)} to complete verified registration.',
      leading: IconButton.filledTonal(
        onPressed: () {
          ref.read(phoneRegistrationControllerProvider.notifier).reset();
          context.go(AppRoutes.register);
        },
        icon: const Icon(Icons.arrow_back),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Pinput(
              controller: _codeController,
              length: 6,
              autofocus: true,
              keyboardType: TextInputType.number,
              validator: AuthValidators.otp,
              onCompleted: (_) => _verify(),
            ),
            if ((state.errorMessage ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
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
                  state.isSubmitting ? 'Verifying...' : 'Verify and continue',
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: remaining == 0 ? _resendCode : null,
              child: Text(
                remaining == 0 ? 'Resend code' : 'Resend in ${remaining}s',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
