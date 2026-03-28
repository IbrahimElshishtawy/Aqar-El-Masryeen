import 'package:aqarelmasryeen/core/theme/app_colors.dart';
import 'package:aqarelmasryeen/core/theme/app_spacing.dart';
import 'package:aqarelmasryeen/modules/auth/controllers/auth_controller.dart';
import 'package:aqarelmasryeen/shared/layouts/auth_shell.dart';
import 'package:aqarelmasryeen/shared/widgets/app_button.dart';
import 'package:aqarelmasryeen/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileCompletionScreen extends StatelessWidget {
  const ProfileCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Obx(
      () => AuthShell(
        title: 'complete_profile'.tr,
        subtitle: 'profile_subtitle'.tr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined),
                  const SizedBox(width: 10),
                  Text(
                    '${'account_secure'.tr} • ${controller.pendingPhone}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: controller.nameController,
              label: 'full_name'.tr,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: controller.emailController,
              label: 'email_optional'.tr,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.alternate_email_rounded),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'continue'.tr,
              isLoading: controller.isBusy.value,
              onPressed: controller.completeProfile,
            ),
          ],
        ),
      ),
    );
  }
}
