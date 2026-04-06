import 'package:aqarelmasryeen/core/constants/app_breakpoints.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.child,
    this.subtitle,
    this.actions,
    this.titleActions,
    this.floatingActionButton,
    this.showBottomNavigation = true,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final int currentIndex;
  final Widget child;
  final String? subtitle;
  final List<Widget>? actions;
  final List<Widget>? titleActions;
  final Widget? floatingActionButton;
  final bool showBottomNavigation;
  final bool automaticallyImplyLeading;

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
  Widget build(BuildContext context) {
    final safeIndex = currentIndex.clamp(0, _destinations.length - 1);

    return Scaffold(
      appBar: AppTopBar(
        title: title,
        subtitle: subtitle,
        actions: actions,
        titleActions: titleActions,
        automaticallyImplyLeading: automaticallyImplyLeading,
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
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
