import 'package:aqarelmasryeen/core/theme/app_spacing.dart';
import 'package:aqarelmasryeen/modules/auth/controllers/auth_controller.dart';
import 'package:aqarelmasryeen/shared/layouts/auth_shell.dart';
import 'package:aqarelmasryeen/shared/widgets/app_button.dart';
import 'package:aqarelmasryeen/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PasswordSetupScreen extends StatelessWidget {
  const PasswordSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Obx(
      () => AuthShell(
        title: 'password_setup_title'.tr,
        subtitle: 'password_setup_subtitle'.tr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: controller.passwordController,
              label: 'password'.tr,
              obscureText: controller.obscurePassword.value,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => controller.obscurePassword.toggle(),
                icon: Icon(
                  controller.obscurePassword.value
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: controller.confirmPasswordController,
              label: 'confirm_password'.tr,
              obscureText: controller.obscureConfirmPassword.value,
              prefixIcon: const Icon(Icons.verified_user_outlined),
              suffixIcon: IconButton(
                onPressed: () => controller.obscureConfirmPassword.toggle(),
                icon: Icon(
                  controller.obscureConfirmPassword.value
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'continue'.tr,
              isLoading: controller.isBusy.value,
              onPressed: controller.setupPassword,
            ),
          ],
        ),
      ),
    );
  }
}
