import 'package:aqarelmasryeen/app/routes/app_routes.dart';
import 'package:aqarelmasryeen/app/routes/route_guards.dart';
import 'package:aqarelmasryeen/modules/auth/bindings/auth_binding.dart';
import 'package:aqarelmasryeen/modules/auth/views/biometric_prompt_screen.dart';
import 'package:aqarelmasryeen/modules/auth/views/login_screen.dart';
import 'package:aqarelmasryeen/modules/auth/views/otp_verification_screen.dart';
import 'package:aqarelmasryeen/modules/auth/views/password_setup_screen.dart';
import 'package:aqarelmasryeen/modules/auth/views/profile_completion_screen.dart';
import 'package:aqarelmasryeen/modules/auth/views/registration_screen.dart';
import 'package:aqarelmasryeen/modules/dashboard/bindings/dashboard_binding.dart';
import 'package:aqarelmasryeen/modules/dashboard/views/dashboard_screen.dart';
import 'package:aqarelmasryeen/modules/onboarding/views/onboarding_screen.dart';
import 'package:aqarelmasryeen/modules/splash/bindings/splash_binding.dart';
import 'package:aqarelmasryeen/modules/splash/views/splash_screen.dart';
import 'package:get/get.dart';

abstract final class AppPages {
  static const initial = AppRoutes.splash;

  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: SplashScreen.new,
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: OnboardingScreen.new,
      middlewares: [GuestOnlyGuard()],
    ),
    GetPage(
      name: AppRoutes.login,
      page: LoginScreen.new,
      binding: AuthBinding(),
      middlewares: [GuestOnlyGuard()],
    ),
    GetPage(
      name: AppRoutes.register,
      page: RegistrationScreen.new,
      binding: AuthBinding(),
      middlewares: [GuestOnlyGuard()],
    ),
    GetPage(
      name: AppRoutes.otp,
      page: OtpVerificationScreen.new,
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.passwordSetup,
      page: PasswordSetupScreen.new,
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.profileCompletion,
      page: ProfileCompletionScreen.new,
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.biometricPrompt,
      page: BiometricPromptScreen.new,
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: DashboardScreen.new,
      binding: DashboardBinding(),
      middlewares: [ProtectedRouteGuard()],
    ),
  ];
}
