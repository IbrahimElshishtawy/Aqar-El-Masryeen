import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
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
      await ref.read(otpFlowControllerProvider.notifier).verifyOtp(_codeController.text);
      final session = await ref.read(authSessionProvider.future);
      if (!mounted) return;
      context.go(session?.isProfileComplete == true ? '/dashboard' : '/auth/profile');
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapException(error).message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpFlowControllerProvider);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verify OTP', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('A verification code was sent to ${state.phone}.'),
              const SizedBox(height: 32),
              Pinput(controller: _codeController, length: 6),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.isSubmitting ? null : _verify,
                  child: Text(state.isSubmitting ? 'Verifying...' : 'Verify'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
