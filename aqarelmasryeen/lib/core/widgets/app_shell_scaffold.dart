import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/app_breakpoints.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/security/session_lock_controller.dart';
import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShellScaffold extends ConsumerStatefulWidget {
  const AppShellScaffold({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.child,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final int currentIndex;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  ConsumerState<AppShellScaffold> createState() => _AppShellScaffoldState();
}

class _AppShellScaffoldState extends ConsumerState<AppShellScaffold>
    with WidgetsBindingObserver {
  static const _destinations = [
    AppRoutes.dashboard,
    AppRoutes.properties,
    AppRoutes.partners,
    AppRoutes.reports,
    AppRoutes.settings,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(sessionLockControllerProvider.notifier);
    if (state == AppLifecycleState.paused) {
      controller.handlePause();
    } else if (state == AppLifecycleState.resumed) {
      controller.handleResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(sessionLockControllerProvider);
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

    return Listener(
      onPointerDown: (_) => ref.read(sessionLockControllerProvider.notifier).recordActivity(),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title), actions: widget.actions),
        floatingActionButton: widget.floatingActionButton,
        body: Stack(
          children: [
            SafeArea(
              child: Row(
                children: [
                  if (isWide)
                    NavigationRail(
                      selectedIndex: widget.currentIndex,
                      onDestinationSelected: (index) => context.go(_destinations[index]),
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          label: Text('Dashboard'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.apartment_outlined),
                          label: Text('Properties'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.group_outlined),
                          label: Text('Partners'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.summarize_outlined),
                          label: Text('Reports'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.settings_outlined),
                          label: Text('Settings'),
                        ),
                      ],
                    ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: widget.child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (lockState.isLocked) Positioned.fill(child: _LockOverlay()),
          ],
        ),
        bottomNavigationBar: isWide
            ? null
            : NavigationBar(
                selectedIndex: widget.currentIndex,
                onDestinationSelected: (index) => context.go(_destinations[index]),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.apartment_outlined),
                    label: 'Properties',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.group_outlined),
                    label: 'Partners',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.summarize_outlined),
                    label: 'Reports',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    label: 'Settings',
                  ),
                ],
              ),
      ),
    );
  }
}

class _LockOverlay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56),
              const SizedBox(height: 16),
              Text('Session locked', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Unlock with biometrics or device passcode to continue.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  final enabled = await ref.read(authRepositoryProvider).biometricsEnabled();
                  if (!enabled) {
                    ref.read(sessionLockControllerProvider.notifier).unlock();
                    return;
                  }
                  final authenticated =
                      await ref.read(biometricServiceProvider).authenticate();
                  if (authenticated && context.mounted) {
                    ref.read(sessionLockControllerProvider.notifier).unlock();
                  }
                },
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
