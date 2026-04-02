import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/features/auth\presentation\auth_providers.dart';
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (_notificationReady) return;
      _notificationReady = true;
      await ref.read(notificationServiceProvider).initialize(
            onNotificationTap: (payload) {
              if (mounted) {
                context.go(payload.route);
              }
            },
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider, (previous, next) {
      next.whenData((session) {
        final target = session == null
            ? '/auth/login'
            : session.isProfileComplete
                ? '/dashboard'
                : '/auth/profile';
        if (mounted) context.go(target);
      });
    });

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_outlined, size: 64),
            SizedBox(height: 16),
            Text('Aqar El Masryeen'),
            SizedBox(height: 12),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
