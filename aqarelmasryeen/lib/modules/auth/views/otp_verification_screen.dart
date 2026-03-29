import 'package:aqarelmasryeen/core/theme/app_spacing.dart';
import 'package:aqarelmasryeen/modules/auth/controllers/auth_controller.dart';
import 'package:aqarelmasryeen/shared/layouts/auth_shell.dart';
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
    final suggestedCode = controller.suggestedOtpCode;
    if (suggestedCode != null) {
      pinController.text = suggestedCode;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.maybeAutoSubmitTestOtp();
    });
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestedCode = controller.suggestedOtpCode;
    if (suggestedCode != null && pinController.text != suggestedCode) {
      pinController.text = suggestedCode;
    }

    return Obx(
      () => AuthShell(
        title: 'otp_title'.tr,
        subtitle: '${'otp_subtitle'.tr}\n${controller.pendingPhone}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Pinput(
              controller: pinController,
              length: 6,
              defaultPinTheme: PinTheme(
                width: 54,
                height: 60,
                textStyle: Theme.of(context).textTheme.headlineSmall,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'verify_code'.tr,
              isLoading: controller.isBusy.value,
              onPressed: () => controller.verifyOtp(pinController.text),
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Send Code Again',
              variant: AppButtonVariant.secondary,
              isLoading: controller.isBusy.value,
              onPressed: controller.resendOtp,
            ),
          ],
        ),
      ),
    );
  }
}
