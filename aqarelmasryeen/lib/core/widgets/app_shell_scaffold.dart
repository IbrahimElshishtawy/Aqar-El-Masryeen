import 'package:aqarelmasryeen/core/constants/app_breakpoints.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShellScaffold extends ConsumerWidget {
  const AppShellScaffold({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.child,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
    this.showBottomNavigation = true,
  });

  final String title;
  final int currentIndex;
  final Widget child;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBottomNavigation;

  static const _destinations = [
    _ShellDestination(
      route: AppRoutes.dashboard,
      label: 'الرئيسية',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
    ),
    _ShellDestination(
      route: AppRoutes.properties,
      label: 'المشروعات',
      icon: Icons.apartment_outlined,
      selectedIcon: Icons.apartment_rounded,
    ),
    _ShellDestination(
      route: AppRoutes.profileHome,
      label: 'الحساب',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeIndex = currentIndex.clamp(0, _destinations.length - 1);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: canPop,
        toolbarHeight: subtitle == null ? 68 : 92,
        titleSpacing: canPop ? null : 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ],
        ),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.tablet + 360,
            ),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: showBottomNavigation
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFD8D8D2)),
                ),
                child: NavigationBar(
                  selectedIndex: safeIndex,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  onDestinationSelected: (index) =>
                      context.go(_destinations[index].route),
                  destinations: [
                    for (final destination in _destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: destination.label,
                      ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
