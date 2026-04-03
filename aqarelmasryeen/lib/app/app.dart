import 'package:aqarelmasryeen/core/security/session_activity_listener.dart';
import 'package:aqarelmasryeen/core/routing/app_router.dart';
import 'package:aqarelmasryeen/core/services/firebase_initializer.dart';
import 'package:aqarelmasryeen/core/services/notification_service.dart';
import 'package:aqarelmasryeen/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _firebaseInitializationFuture != null) {
        return;
      }
      setState(() {
        _firebaseInitializationFuture = _initializeServices();
      });
    });
  }

  Future<void> _initializeServices() async {
    FirebaseMessagingService.registerBackgroundHandler();
    await initializeFirebase();
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
      final safeChild = child ?? const SizedBox.shrink();
      if (!wrapChildWithSessionListener) {
        return safeChild;
      }
      return SessionActivityListener(child: safeChild);
    }

    if (routerConfig != null) {
      return MaterialApp.router(
        title: 'Aqar El Masryeen',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: routerConfig,
        builder: builder,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      );
    }

    return MaterialApp(
      title: 'Aqar El Masryeen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: home,
      builder: builder,
      supportedLocales: const [Locale('en'), Locale('ar')],
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
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
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
        child: const SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing secure workspace...'),
              ],
            ),
          ),
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
                  'Firebase initialization failed',
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
