import 'package:aqarelmasryeen/modules/auth/controllers/auth_controller.dart';
import 'package:aqarelmasryeen/shared/widgets/app_button.dart';
import 'package:aqarelmasryeen/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeroPanel(unlockMode: controller.unlockMode),
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
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.unlockMode
                                      ? 'Unlock your workspace'
                                      : 'Sign in securely',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: const Color(0xFF0B1F33),
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  controller.unlockMode
                                      ? 'Use a trusted local method or your password to reopen this device session.'
                                      : 'Choose OTP, password, device PIN, or biometrics based on what is already enabled on this device.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: const Color(0xFF5E7288),
                                        height: 1.5,
                                      ),
                                ),
                                const SizedBox(height: 22),
                                AppTextField(
                                  controller: controller.phoneController,
                                  label: 'Phone Number',
                                  hint: '+20 10 1234 5678',
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  errorText: controller.phoneError.value,
                                  prefixIcon: const Icon(Icons.phone_rounded),
                                  autofillHints: const [
                                    AutofillHints.telephoneNumber,
                                  ],
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d+\-\s()]'),
                                    ),
                                  ],
                                ),
                                if (controller.debugPhoneAuthHint != null) ...[
                                  const SizedBox(height: 10),
                                  _InfoBanner(
                                    icon: Icons.developer_mode_rounded,
                                    text: controller.debugPhoneAuthHint!,
                                  ),
                                ],
                                const SizedBox(height: 16),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: controller.showPasswordField.value
                                      ? Column(
                                          key: const ValueKey('password-field'),
                                          children: [
                                            AppTextField(
                                              controller:
                                                  controller.passwordController,
                                              label: 'Password',
                                              obscureText: controller
                                                  .obscurePassword
                                                  .value,
                                              textInputAction:
                                                  TextInputAction.done,
                                              errorText: controller
                                                  .passwordError
                                                  .value,
                                              prefixIcon: const Icon(
                                                Icons.lock_outline_rounded,
                                              ),
                                              autofillHints: const [
                                                AutofillHints.password,
                                              ],
                                              suffixIcon: IconButton(
                                                onPressed: () => controller
                                                    .obscurePassword
                                                    .toggle(),
                                                icon: Icon(
                                                  controller
                                                          .obscurePassword
                                                          .value
                                                      ? Icons
                                                            .visibility_off_rounded
                                                      : Icons
                                                            .visibility_rounded,
                                                ),
                                              ),
                                              onSubmitted: (_) => controller
                                                  .loginWithPassword(),
                                            ),
                                            const SizedBox(height: 10),
                                          ],
                                        )
                                      : const SizedBox.shrink(
                                          key: ValueKey('password-hidden'),
                                        ),
                                ),
                                _SecurityOptions(controller: controller),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: AppButton(
                                    label: 'Continue with OTP',
                                    isLoading: controller.isBusy.value,
                                    onPressed: controller.unlockMode
                                        ? null
                                        : controller.sendLoginOtp,
                                    icon: const Icon(Icons.sms_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: AppButton(
                                    label: controller.unlockMode
                                        ? 'Unlock with password'
                                        : 'Sign in with password',
                                    isLoading: controller.isBusy.value,
                                    onPressed: controller.loginWithPassword,
                                  ),
                                ),
                                if (!controller.unlockMode) ...[
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      const Expanded(child: Divider()),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          'New here?',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: const Color(0xFF74869A),
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      const Expanded(child: Divider()),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: AppButton(
                                      label: 'Create a new account',
                                      variant: AppButtonVariant.secondary,
                                      onPressed: controller.goToRegistration,
                                    ),
                                  ),
                                ],
                              ],
                            ),
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

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.unlockMode});

  final bool unlockMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              unlockMode ? Icons.lock_open_rounded : Icons.shield_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            unlockMode
                ? 'Trusted device unlock'
                : 'Authentication designed for production',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            unlockMode
                ? 'Device PIN, fingerprint, Face ID, and encrypted local credentials work together to reopen the app quickly without weakening session security.'
                : 'OTP, strong password sign-in, local biometrics, and encrypted credential storage are all wired into the same Firebase and GetX flow.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityOptions extends StatelessWidget {
  const _SecurityOptions({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    if (controller.canUseDeviceCredential.value) {
      actions.add(
        Expanded(
          child: _QuickAccessButton(
            label: 'Use Device PIN',
            icon: Icons.pin_rounded,
            onPressed: controller.loginWithDeviceCredential,
          ),
        ),
      );
    }

    if (controller.canUseBiometric.value) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(width: 12));
      }
      actions.add(
        Expanded(
          child: _QuickAccessButton(
            label: controller.biometricLabel.value,
            icon: Icons.fingerprint_rounded,
            onPressed: controller.loginWithBiometrics,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (actions.isNotEmpty) ...[
          Row(children: actions),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                controller.showPasswordField.value
                    ? 'Password fallback is available.'
                    : 'Password is hidden because biometrics are already enabled.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF5E7288),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => controller.showPasswordField.toggle(),
              child: Text(
                controller.showPasswordField.value
                    ? 'Hide password'
                    : 'Show password',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAccessButton extends StatelessWidget {
  const _QuickAccessButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6FAFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCE8F8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF1976D2)),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF0B1F33),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E8FD)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1976D2)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF31506F),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
