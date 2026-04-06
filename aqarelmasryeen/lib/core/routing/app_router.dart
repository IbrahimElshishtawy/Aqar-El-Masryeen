import 'dart:async';

import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/security/session_lock_controller.dart';
import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/auth/presentation/screens/biometric_setup_screen.dart';
import 'package:aqarelmasryeen/features/auth/presentation/screens/login_screen.dart';
import 'package:aqarelmasryeen/features/auth/presentation/screens/profile_completion_screen.dart';
import 'package:aqarelmasryeen/features/auth/presentation/screens/register_screen.dart';
import 'package:aqarelmasryeen/features/dashboard/presentation/dashboard_screen.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/expenses_ledger_screen.dart';
import 'package:aqarelmasryeen/features/notifications/presentation/notifications_center_screen.dart';
import 'package:aqarelmasryeen/features/partners/presentation/partners_screen.dart';
import 'package:aqarelmasryeen/features/profile/presentation/profile_screen.dart';
import 'package:aqarelmasryeen/features/properties/presentation/properties_screen.dart';
import 'package:aqarelmasryeen/features/properties/presentation/property_detail_screen.dart';
import 'package:aqarelmasryeen/features/properties/presentation/property_form_screen.dart';
import 'package:aqarelmasryeen/features/security/presentation/screens/unlock_screen.dart';
import 'package:aqarelmasryeen/features/settings/presentation/settings_screen.dart';
import 'package:aqarelmasryeen/features/splash/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = GoRouterRefreshStream(
    ref.watch(authRepositoryProvider).watchSession(),
  );
  ref.onDispose(refreshListenable.dispose);

  final sessionState = ref.watch(authSessionProvider);
  final session = sessionState.valueOrNull;
  final lockState = ref.watch(sessionLockControllerProvider);

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
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileCompletionScreen(),
      ),
      GoRoute(
        path: AppRoutes.securitySetup,
        builder: (context, state) => const BiometricSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.unlock,
        builder: (context, state) => const UnlockScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        pageBuilder: (context, state) =>
            _buildAppPage(state: state, child: const DashboardScreen()),
      ),
      GoRoute(
        path: AppRoutes.expenses,
        pageBuilder: (context, state) =>
            _buildAppPage(state: state, child: const ExpensesLedgerScreen()),
      ),
      GoRoute(
        path: AppRoutes.properties,
        pageBuilder: (context, state) =>
            _buildAppPage(state: state, child: const PropertiesScreen()),
        routes: [
          GoRoute(
            path: 'new',
            pageBuilder: (context, state) =>
                _buildAppPage(state: state, child: const PropertyFormScreen()),
          ),
          GoRoute(
            path: ':propertyId',
            pageBuilder: (context, state) => _buildAppPage(
              state: state,
              child: PropertyDetailScreen(
                propertyId: state.pathParameters['propertyId'] ?? '',
              ),
            ),
            routes: [
              GoRoute(
                path: 'edit',
                pageBuilder: (context, state) => _buildAppPage(
                  state: state,
                  child: PropertyFormScreen(
                    propertyId: state.pathParameters['propertyId'],
                  ),
                ),
              ),
              GoRoute(
                path: 'units/:unitId',
                pageBuilder: (context, state) => _buildAppPage(
                  state: state,
                  child: PropertyDetailScreen(
                    propertyId: state.pathParameters['propertyId'] ?? '',
                    unitId: state.pathParameters['unitId'] ?? '',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.partners,
        pageBuilder: (context, state) =>
            _buildAppPage(state: state, child: const PartnersScreen()),
      ),
      GoRoute(
        path: AppRoutes.profileHome,
        pageBuilder: (context, state) =>
            _buildAppPage(state: state, child: const ProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) =>
            _buildAppPage(state: state, child: const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) => _buildAppPage(
          state: state,
          child: const NotificationsCenterScreen(),
        ),
      ),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isSplashRoute = location == AppRoutes.splash;
      final isAuthRoute = location.startsWith('/auth');
      final isPublicRoute =
          isSplashRoute || isAuthRoute || location == AppRoutes.unlock;

      if (!lockState.isInitialized) {
        return isSplashRoute ? null : AppRoutes.splash;
      }

      if (sessionState.isLoading) {
        return isSplashRoute || isAuthRoute ? null : AppRoutes.splash;
      }

      if (session == null) {
        if (location == AppRoutes.unlock) {
          return AppRoutes.login;
        }
        return isPublicRoute ? null : AppRoutes.login;
      }

      if (!session.isActive) {
        return AppRoutes.login;
      }

      if (session.needsProfileCompletion) {
        if (location == AppRoutes.profile) {
          return null;
        }
        return AppRoutes.profile;
      }

      if (session.needsSecuritySetup && location != AppRoutes.securitySetup) {
        return AppRoutes.securitySetup;
      }

      if (lockState.shouldPresentUnlock) {
        return location == AppRoutes.unlock ? null : AppRoutes.unlock;
      }

      if (location == AppRoutes.unlock) {
        return AppRoutes.dashboard;
      }

      if (location == AppRoutes.securitySetup) {
        return null;
      }

      if (isSplashRoute || isAuthRoute) {
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
                state.error?.toString() ??
                    'The requested route does not exist.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go(AppRoutes.dashboard),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});

CustomTransitionPage<void> _buildAppPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

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
