import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/features/auth/presentation/controllers/auth_bootstrap_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _notificationReady = false;
  String? _pendingRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeNotifications();
      }
    });
  }

  Future<void> _initializeNotifications() async {
    if (_notificationReady) return;
    _notificationReady = true;
    if (AppConfig.useMockData) {
      return;
    }
    try {
      await ref.read(notificationServiceProvider).initialize(
        onNotificationTap: (payload) {
          if (mounted) {
            context.go(payload.route);
          }
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Notification initialization failed on splash: $error');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 6);
    }
  }

  void _scheduleNavigation(String route) {
    if (_pendingRoute == route) return;
    _pendingRoute = route;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingRoute != route) return;
      context.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final decision = ref.watch(authBootstrapControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.18),
              theme.scaffoldBackgroundColor,
              theme.colorScheme.secondary.withValues(alpha: 0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;
              final isCompact = height < 700;
              final isVeryCompact = height < 620;
              final screenPadding = isVeryCompact ? 16.0 : 24.0;
              final logoSize = isVeryCompact ? 72.0 : 88.0;
              final logoRadius = isVeryCompact ? 22.0 : 28.0;
              final logoIconSize = isVeryCompact ? 34.0 : 40.0;
              final largeSpacing = isCompact ? 14.0 : 20.0;
              final smallSpacing = isCompact ? 6.0 : 8.0;

              return SingleChildScrollView(
                padding: EdgeInsets.all(screenPadding),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: logoSize,
                          height: logoSize,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(logoRadius),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            size: logoIconSize,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: largeSpacing),
                        Text(
                          AppConfig.appName,
                          textAlign: TextAlign.center,
                          style:
                              (isCompact
                                      ? theme.textTheme.titleLarge
                                      : theme.textTheme.headlineSmall)
                                  ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: smallSpacing),
                        Text(
                          'مساحة عمل آمنة لإدارة الحسابات العقارية',
                          textAlign: TextAlign.center,
                          style: isCompact
                              ? theme.textTheme.bodyMedium
                              : theme.textTheme.bodyLarge,
                        ),
                        SizedBox(height: largeSpacing),
                        decision.when(
                          data: (decision) {
                            _scheduleNavigation(decision.route);
                            return const CircularProgressIndicator();
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stackTrace) => Text(
                            error.toString(),
                            textAlign: TextAlign.center,
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
