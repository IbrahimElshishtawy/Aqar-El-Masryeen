import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/widgets/app_loading_view.dart';
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
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (_notificationReady) {
      return;
    }

    _notificationReady = true;
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
    if (_pendingRoute == route) {
      return;
    }

    _pendingRoute = route;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingRoute != route) {
        return;
      }
      context.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final decision = ref.watch(authBootstrapControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 700;
            final plateSize = isCompact ? 176.0 : 196.0;
            final spacing = isCompact ? 18.0 : 24.0;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: plateSize,
                        height: plateSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(color: const Color(0xFFD8D8D2)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/image/Apar.jpg',
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: spacing),
                      Text(
                        AppConfig.appName,
                        textAlign: TextAlign.center,
                        style: (isCompact
                                ? theme.textTheme.titleMedium
                                : theme.textTheme.titleLarge)
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      decision.when(
                        data: (decision) {
                          _scheduleNavigation(decision.route);
                          return const AppLoadingView(
                            label: 'تم العثور على أفضل مسار للدخول',
                            message: 'يجري فتح الشاشة المناسبة الآن.',
                            padding: EdgeInsets.zero,
                          );
                        },
                        loading: () => const AppLoadingView(
                          label: 'جار التحقق من الجلسة الحالية',
                          message: 'يتم استخدام البيانات المحلية أولاً ثم تحديث الحالة عند الحاجة.',
                          padding: EdgeInsets.zero,
                        ),
                        error: (error, stackTrace) => Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
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
    );
  }
}
