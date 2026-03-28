import 'package:aqarelmasryeen/core/localization/locale_service.dart';
import 'package:aqarelmasryeen/core/responsive/app_breakpoints.dart';
import 'package:aqarelmasryeen/core/theme/app_colors.dart';
import 'package:aqarelmasryeen/core/theme/app_spacing.dart';
import 'package:aqarelmasryeen/shared/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F3EA), Color(0xFFF1ECE2), Color(0xFFECE4D6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    if (isDesktop)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsetsDirectional.only(end: 24),
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(36),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.surfaceDark,
                                AppColors.primary,
                                AppColors.primaryMuted,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const AppLogo(showText: false),
                                  const Spacer(),
                                  GetBuilder<LocaleService>(
                                    builder: (localeService) {
                                      final isArabic =
                                          localeService
                                              .currentLocale
                                              .languageCode ==
                                          'ar';
                                      return TextButton(
                                        onPressed: () {
                                          localeService.changeLocale(
                                            isArabic
                                                ? const Locale('en', 'US')
                                                : const Locale('ar', 'EG'),
                                          );
                                        },
                                        child: Text(isArabic ? 'EN' : 'AR'),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                'premium_workspace'.tr,
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'trusted_devices'.tr,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: const Color(0xFFD8E3F4)),
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: const [
                                  _FeatureChip(label: 'OTP + Password'),
                                  _FeatureChip(label: 'Biometric Unlock'),
                                  _FeatureChip(label: 'Role-ready Access'),
                                  _FeatureChip(label: 'FCM + Local Alerts'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isDesktop) ...[
                                const AppLogo(),
                                const SizedBox(height: 24),
                              ],
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.shadow,
                                      blurRadius: 36,
                                      offset: Offset(0, 18),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      subtitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                            height: 1.6,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                    child,
                                  ],
                                ),
                              ),
                              if (footer != null) ...[
                                const SizedBox(height: 16),
                                footer!,
                              ],
                            ],
                          ),
                        ),
                      ),
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

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
