import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/routing/app_router.dart';
import 'package:aqarelmasryeen/core/security/session_activity_listener.dart';
import 'package:aqarelmasryeen/core/security/session_lock_controller.dart';
import 'package:aqarelmasryeen/core/services/firebase_initializer.dart';
import 'package:aqarelmasryeen/core/services/notification_navigation_controller.dart';
import 'package:aqarelmasryeen/core/theme/app_theme.dart';
import 'package:aqarelmasryeen/core/widgets/app_loading_view.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AqarPartnersApp extends ConsumerStatefulWidget {
  const AqarPartnersApp({super.key});

  @override
  ConsumerState<AqarPartnersApp> createState() => _AqarPartnersAppState();
}

class _AqarPartnersAppState extends ConsumerState<AqarPartnersApp> {
  Future<void>? _firebaseInitializationFuture;

  @override
  void initState() {
    super.initState();
    _firebaseInitializationFuture = _initializeServices();
  }

  Future<void> _initializeServices() async {
    await initializeFirebase();
    try {
      await ref
          .read(notificationServiceProvider)
          .initialize(
            onNotificationTap: (payload) {
              ref
                  .read(notificationNavigationControllerProvider.notifier)
                  .queue(payload);
            },
          );
    } catch (error, stackTrace) {
      debugPrint('Notification service initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final future = _firebaseInitializationFuture;
    if (future == null) {
      return _buildBaseApp(home: const _AppBootstrapScreen());
    }

    return FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildBaseApp(home: const _AppBootstrapScreen());
        }

        if (snapshot.hasError) {
          return _buildBaseApp(
            home: _AppBootstrapErrorScreen(error: snapshot.error.toString()),
          );
        }

        final router = ref.watch(appRouterProvider);
        return _buildBaseApp(
          routerConfig: router,
          wrapChildWithSessionListener: true,
        );
      },
    );
  }

  Widget _buildBaseApp({
    Widget? home,
    dynamic routerConfig,
    bool wrapChildWithSessionListener = false,
  }) {
    Widget builder(BuildContext context, Widget? child) {
      Widget safeChild = Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      );

      if (wrapChildWithSessionListener) {
        safeChild = SessionActivityListener(child: safeChild);
        safeChild = NotificationNavigationListener(child: safeChild);
      }

      return safeChild;
    }

    if (routerConfig != null) {
      return MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        routerConfig: routerConfig,
        builder: builder,
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [Locale('ar', 'EG')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      );
    }

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      home: home,
      builder: builder,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class _AppBootstrapScreen extends StatelessWidget {
  const _AppBootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: AppLoadingView(
          label: 'جاري تجهيز مساحة العمل',
          message: 'يتم تشغيل الخدمات الأساسية وتهيئة الجلسة الحالية.',
        ),
      ),
    );
  }
}

class _AppBootstrapErrorScreen extends StatelessWidget {
  const _AppBootstrapErrorScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  'تعذر تهيئة خدمات التطبيق',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(error, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationNavigationListener extends ConsumerStatefulWidget {
  const NotificationNavigationListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationNavigationListener> createState() =>
      _NotificationNavigationListenerState();
}

class _NotificationNavigationListenerState
    extends ConsumerState<NotificationNavigationListener> {
  String? _scheduledPayload;

  void _attemptNavigation() {
    if (!mounted) {
      return;
    }

    final payload = ref.read(notificationNavigationControllerProvider);
    final sessionState = ref.read(authSessionProvider);
    final lockState = ref.read(sessionLockControllerProvider);
    if (payload == null || sessionState.isLoading || !lockState.isInitialized) {
      return;
    }

    final session = sessionState.valueOrNull;
    final canOpenRoute =
        session != null &&
        session.isActive &&
        !session.needsProfileCompletion &&
        !session.needsSecuritySetup &&
        !lockState.shouldPresentUnlock;
    if (!canOpenRoute) {
      return;
    }

    final encodedPayload = payload.encode();
    if (_scheduledPayload == encodedPayload) {
      return;
    }

    _scheduledPayload = encodedPayload;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduledPayload = null;
      if (!mounted) {
        return;
      }

      final pendingPayload = ref.read(notificationNavigationControllerProvider);
      if (pendingPayload?.encode() != encodedPayload) {
        return;
      }

      ref.read(notificationNavigationControllerProvider.notifier).clear();
      GoRouter.of(context).go(payload.route);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationNavigationControllerProvider, (previous, next) {
      _attemptNavigation();
    });
    ref.listen(authSessionProvider, (previous, next) {
      _attemptNavigation();
    });
    ref.listen(sessionLockControllerProvider, (previous, next) {
      _attemptNavigation();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptNavigation();
    });

    return widget.child;
  }
}
