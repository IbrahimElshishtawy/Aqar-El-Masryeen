import 'package:aqarelmasryeen/modules/auth/controllers/auth_controller.dart';
import 'package:aqarelmasryeen/shared/widgets/app_button.dart';
import 'package:aqarelmasryeen/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth > 720
                  ? 40.0
                  : 20.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  20,
                  horizontalPadding,
                  28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Create your secure account',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Once your form is valid, Firebase phone auth sends the OTP immediately and the account is completed after code verification.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      height: 1.55,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xFFE3ECFA)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x140E2A47),
                                blurRadius: 26,
                                offset: Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AnimatedField(
                                delay: 0,
                                child: AppTextField(
                                  controller: controller.nameController,
                                  label: 'Full Name',
                                  hint: 'Ahmed Mahmoud',
                                  errorText: controller.nameError.value,
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _AnimatedField(
                                delay: 1,
                                child: AppTextField(
                                  controller: controller.phoneController,
                                  label: 'Phone Number',
                                  hint: '+20 10 1234 5678',
                                  errorText: controller.phoneError.value,
                                  keyboardType: TextInputType.phone,
                                  prefixIcon: const Icon(Icons.phone_rounded),
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.telephoneNumber,
                                  ],
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d+\-\s()]'),
                                    ),
                                  ],
                                ),
                              ),
                              if (controller.debugPhoneAuthHint != null) ...[
                                const SizedBox(height: 10),
                                _InlineNotice(
                                  text: controller.debugPhoneAuthHint!,
                                ),
                              ],
                              const SizedBox(height: 16),
                              _AnimatedField(
                                delay: 2,
                                child: AppTextField(
                                  controller: controller.passwordController,
                                  label: 'Password',
                                  obscureText: controller.obscurePassword.value,
                                  errorText: controller.passwordError.value,
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        controller.obscurePassword.toggle(),
                                    icon: Icon(
                                      controller.obscurePassword.value
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _AnimatedField(
                                delay: 3,
                                child: AppTextField(
                                  controller:
                                      controller.confirmPasswordController,
                                  label: 'Confirm Password',
                                  obscureText:
                                      controller.obscureConfirmPassword.value,
                                  errorText:
                                      controller.confirmPasswordError.value,
                                  prefixIcon: const Icon(
                                    Icons.verified_user_outlined,
                                  ),
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  suffixIcon: IconButton(
                                    onPressed: () => controller
                                        .obscureConfirmPassword
                                        .toggle(),
                                    icon: Icon(
                                      controller.obscureConfirmPassword.value
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                    ),
                                  ),
                                  onSubmitted: (_) =>
                                      controller.startRegistration(),
                                ),
                              ),
                              const SizedBox(height: 18),
                              _PasswordChecklist(controller: controller),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  label: 'Create account and send OTP',
                                  isLoading: controller.isBusy.value,
                                  onPressed: controller.startRegistration,
                                  icon: const Icon(Icons.verified_user_rounded),
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  label: 'Back to sign in',
                                  variant: AppButtonVariant.secondary,
                                  onPressed: controller.goToLogin,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final policy = controller.passwordPolicy.value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: policy.isStrong
              ? const Color(0xFFBEE3CC)
              : const Color(0xFFDCE8F8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password strength',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF0B1F33),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: policy.progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFDCE8F8),
              valueColor: AlwaysStoppedAnimation<Color>(
                policy.isStrong
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF1976D2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PasswordRule(
            label: 'At least 8 characters',
            passed: policy.hasMinLength,
          ),
          _PasswordRule(label: 'Uppercase letter', passed: policy.hasUppercase),
          _PasswordRule(label: 'Lowercase letter', passed: policy.hasLowercase),
          _PasswordRule(label: 'Number', passed: policy.hasDigit),
          _PasswordRule(
            label: 'Special character',
            passed: policy.hasSpecialCharacter,
          ),
          const SizedBox(height: 10),
          Text(
            policy.summary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF5E7288),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordRule extends StatelessWidget {
  const _PasswordRule({required this.label, required this.passed});

  final String label;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 18,
            color: passed ? const Color(0xFF2E7D32) : const Color(0xFF7A8CA0),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF24405F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E8FD)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sms_outlined, size: 18, color: Color(0xFF1976D2)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF31506F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedField extends StatelessWidget {
  const _AnimatedField({required this.delay, required this.child});

  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (delay * 90)),
      curve: Curves.easeOutCubic,
      builder: (context, value, widgetChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: widgetChild,
          ),
        );
      },
      child: child,
    );
  }
}
