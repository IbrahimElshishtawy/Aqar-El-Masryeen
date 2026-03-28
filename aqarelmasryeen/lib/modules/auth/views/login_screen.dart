import 'package:aqarelmasryeen/core/bootstrap/app_bootstrap.dart';
import 'package:aqarelmasryeen/core/theme/app_colors.dart';
import 'package:aqarelmasryeen/core/theme/app_spacing.dart';
import 'package:aqarelmasryeen/modules/auth/controllers/auth_controller.dart';
import 'package:aqarelmasryeen/shared/layouts/auth_shell.dart';
import 'package:aqarelmasryeen/shared/widgets/app_button.dart';
import 'package:aqarelmasryeen/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController controller = Get.find();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.configureEntry(Get.arguments);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = Get.find<BootstrapState>();

    return Obx(
      () => AuthShell(
        title: controller.unlockMode ? 'unlock_workspace'.tr : 'sign_in'.tr,
        subtitle: controller.unlockMode
            ? 'biometric_quick_login'.tr
            : 'welcome_subtitle'.tr,
        footer: bootstrap.firebaseReady
            ? null
            : Text(
                'firebase_setup_needed'.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.danger,
                    ),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!controller.unlockMode)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECE2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        selected: !controller.isRegisterMode.value,
                        label: 'sign_in'.tr,
                        onTap: () {
                          if (controller.isRegisterMode.value) {
                            controller.toggleMode();
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: _ModeButton(
                        selected: controller.isRegisterMode.value,
                        label: 'create_account'.tr,
                        onTap: () {
                          if (!controller.isRegisterMode.value) {
                            controller.toggleMode();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: controller.phoneController,
              label: 'phone_number'.tr,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_rounded),
            ),
            const SizedBox(height: AppSpacing.md),
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
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: controller.unlockMode
                  ? 'unlock_workspace'.tr
                  : 'sign_in'.tr,
              isLoading: controller.isBusy.value,
              onPressed: controller.loginWithPassword,
            ),
            const SizedBox(height: 14),
            if (!controller.unlockMode)
              AppButton(
                label: controller.isRegisterMode.value
                    ? 'send_code'.tr
                    : 'use_otp'.tr,
                variant: AppButtonVariant.secondary,
                isLoading: controller.isBusy.value,
                onPressed: controller.sendOtp,
              ),
            if (controller.biometricAvailable.value) ...[
              const SizedBox(height: 14),
              AppButton(
                label: 'enable_biometrics'.tr,
                variant: AppButtonVariant.secondary,
                onPressed: controller.unlockWithBiometrics,
                icon: const Icon(Icons.fingerprint_rounded),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              'desktop_otp_note'.tr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
