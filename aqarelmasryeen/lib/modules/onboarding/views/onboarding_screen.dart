import 'package:aqarelmasryeen/app/routes/app_routes.dart';
import 'package:aqarelmasryeen/core/services/session_service.dart';
import 'package:aqarelmasryeen/core/theme/app_colors.dart';
import 'package:aqarelmasryeen/core/theme/app_spacing.dart';
import 'package:aqarelmasryeen/shared/widgets/app_button.dart';
import 'package:aqarelmasryeen/shared/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surfaceDark,
              AppColors.primary,
              Color(0xFF587197),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppLogo(showText: false),
                          SizedBox(
                            height: constraints.maxHeight > 760
                                ? constraints.maxHeight * 0.28
                                : 72,
                          ),
                          Text(
                            'welcome_title'.tr,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 18),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: Text(
                              'welcome_subtitle'.tr,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFFDCE6F3),
                                    height: 1.6,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: 260,
                            child: AppButton(
                              label: 'get_started'.tr,
                              onPressed: () async {
                                await Get.find<SessionService>()
                                    .markOnboardingSeen();
                                Get.offAllNamed(AppRoutes.login);
                              },
                            ),
                          ),
                        ],
                      ),
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
