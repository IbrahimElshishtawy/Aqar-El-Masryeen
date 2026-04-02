import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
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

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    try {
      await ref
          .read(otpFlowControllerProvider.notifier)
          .verifyOtp(_codeController.text);
      final session = await ref.read(authSessionProvider.future);
      if (!mounted) return;
      context.go(
        session?.isProfileComplete == true ? '/dashboard' : '/auth/profile',
      );
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapException(error).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpFlowControllerProvider);

    return AuthScaffold(
      title: 'Verify one-time code',
      subtitle: 'Enter the 6-digit code sent to ${state.phone}.',
      leading: IconButton.filledTonal(
        onPressed: () => context.go(AppRoutes.login),
        icon: const Icon(Icons.arrow_back),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pinput(controller: _codeController, length: 6, autofocus: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.isSubmitting ? null : _verify,
              child: Text(
                state.isSubmitting ? 'Verifying...' : 'Verify and continue',
              ),
            ),
          ),
          if ((state.errorMessage ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              state.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
