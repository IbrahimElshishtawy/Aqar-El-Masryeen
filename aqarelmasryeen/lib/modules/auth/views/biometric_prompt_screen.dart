import 'package:aqarelmasryeen/core/theme/app_spacing.dart';
import 'package:aqarelmasryeen/modules/auth/controllers/auth_controller.dart';
import 'package:aqarelmasryeen/shared/layouts/auth_shell.dart';
import 'package:aqarelmasryeen/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BiometricPromptScreen extends StatelessWidget {
  const BiometricPromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Obx(
      () => AuthShell(
        title: 'enable_biometrics'.tr,
        subtitle: 'biometric_prompt_subtitle'.tr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF162033), Color(0xFF375079)],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.fingerprint_rounded,
                  size: 82,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'enable_biometrics'.tr,
              isLoading: controller.isBusy.value,
              onPressed: controller.enableBiometrics,
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'skip_for_now'.tr,
              variant: AppButtonVariant.secondary,
              onPressed: controller.skipBiometrics,
            ),
          ],
        ),
      ),
    );
  }
}
