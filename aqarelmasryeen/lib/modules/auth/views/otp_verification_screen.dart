import 'package:aqarelmasryeen/modules/auth/controllers/auth_controller.dart';
import 'package:aqarelmasryeen/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final AuthController controller = Get.find();
  final TextEditingController pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.prepareOtpEntry();
      final suggested = controller.suggestedOtpCode;
      if (suggested != null && mounted) {
        pinController.text = suggested;
      }
    });
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTheme = PinTheme(
      width: 50,
      height: 58,
      textStyle: theme.textTheme.headlineSmall?.copyWith(
        color: const Color(0xFF0B1F33),
        fontWeight: FontWeight.w800,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7E3F4)),
      ),
    );

    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFF),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: const Color(0xFFDCE8F8)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2).withValues(
                                alpha: 0.12,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.sms_rounded,
                              color: Color(0xFF1976D2),
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Enter OTP',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: const Color(0xFF0B1F33),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We sent a 6-digit code to your phone',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF5E7288),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            controller.maskedPendingPhone,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: const Color(0xFF1976D2),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Pinput(
                            controller: pinController,
                            length: 6,
                            autofocus: true,
                            defaultPinTheme: defaultTheme,
                            focusedPinTheme: defaultTheme.copyDecorationWith(
                              border: Border.all(
                                color: const Color(0xFF1976D2),
                                width: 1.6,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A1976D2),
                                  blurRadius: 18,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            submittedPinTheme: defaultTheme.copyWith(
                              decoration: defaultTheme.decoration?.copyWith(
                                color: const Color(0xFFF3F8FF),
                                border: Border.all(
                                  color: const Color(0xFF90CAF9),
                                ),
                              ),
                            ),
                            onChanged: controller.fillOtpFromString,
                            onCompleted: controller.fillOtpFromString,
                          ),
                          if (controller.debugPhoneAuthHint != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F7FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                controller.debugPhoneAuthHint!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF31506F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              label: 'Verify',
                              isLoading: controller.isBusy.value,
                              onPressed: controller.canVerifyOtp
                                  ? () => controller.verifyOtp(pinController.text)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              label: controller.resendSecondsRemaining.value > 0
                                  ? 'Resend OTP in ${controller.resendSecondsRemaining.value}s'
                                  : 'Resend OTP',
                              variant: AppButtonVariant.secondary,
                              isLoading: controller.isBusy.value,
                              onPressed: controller.canResendOtp
                                  ? () {
                                      pinController.clear();
                                      controller.fillOtpFromString('');
                                      controller.resendOtp();
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: controller.goToLogin,
                      child: const Text('Back to sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
