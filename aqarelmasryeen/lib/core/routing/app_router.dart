import 'dart:async';

import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/auth/presentation/screens/biometric_setup_screen.dart';
import 'package:aqarelmasryeen/features/auth/presentation/screens/login_screen.dart';
import 'package:aqarelmasryeen/features/auth/presentation/screens/otp_screen.dart';
import 'package:aqarelmasryeen/features/auth/presentation/screens/profile_completion_screen.dart';
import 'package:aqarelmasryeen/features/auth/presentation/screens/splash_screen.dart';
import 'package:aqarelmasryeen/features/dashboard/presentation/dashboard_screen.dart';
import 'package:aqarelmasryeen/features/notifications/presentation/notifications_center_screen.dart';
import 'package:aqarelmasryeen/features/partners/presentation/partners_screen.dart';
import 'package:aqarelmasryeen/features/properties/presentation/properties_screen.dart';
import 'package:aqarelmasryeen/features/properties/presentation/property_detail_screen.dart';
import 'package:aqarelmasryeen/features/properties/presentation/property_form_screen.dart';
import 'package:aqarelmasryeen/features/reports/presentation/reports_screen.dart';
import 'package:aqarelmasryeen/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = GoRouterRefreshStream(
    ref.watch(authRepositoryProvider).watchSession(),
  );
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileCompletionScreen(),
      ),
      GoRoute(
        path: AppRoutes.biometrics,
        builder: (context, state) => const BiometricSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.properties,
        builder: (context, state) => const PropertiesScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const PropertyFormScreen(),
          ),
          GoRoute(
            path: ':propertyId',
            builder: (context, state) => PropertyDetailScreen(
              propertyId: state.pathParameters['propertyId'] ?? '',
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => PropertyFormScreen(
                  propertyId: state.pathParameters['propertyId'],
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.partners,
        builder: (context, state) => const PartnersScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsCenterScreen(),
      ),
    ],
    redirect: (context, state) {
      final sessionState = ref.read(authSessionProvider);
      final session = sessionState.valueOrNull;
      final location = state.matchedLocation;
      final isAuthRoute = location.startsWith('/auth');
      final isPublicRoute = location == AppRoutes.splash || isAuthRoute;

      if (sessionState.isLoading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (session == null) {
        return isPublicRoute ? null : AppRoutes.login;
      }

      if (!session.isProfileComplete) {
        if (location == AppRoutes.profile || location == AppRoutes.biometrics) {
          return null;
        }
        return AppRoutes.profile;
      }

      if (location == AppRoutes.splash || isAuthRoute) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 48),
              const SizedBox(height: 12),
              Text(
                'Unable to open this screen',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.toString() ?? 'Route not found.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go(AppRoutes.dashboard),
                child: const Text('Back to dashboard'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
      onError: (error, stackTrace) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
