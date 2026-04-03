import 'package:aqarelmasryeen/core/constants/app_breakpoints.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
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

class _AppShellScaffoldState extends ConsumerState<AppShellScaffold> {
  static const _destinations = [
    AppRoutes.dashboard,
    AppRoutes.properties,
    AppRoutes.partners,
    AppRoutes.reports,
    AppRoutes.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: widget.actions),
      floatingActionButton: widget.floatingActionButton,
      body: SafeArea(
        child: Row(
          children: [
            if (isWide)
              NavigationRail(
                selectedIndex: widget.currentIndex,
                onDestinationSelected: (index) =>
                    context.go(_destinations[index]),
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
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: widget.currentIndex,
              onDestinationSelected: (index) =>
                  context.go(_destinations[index]),
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
    );
  }
}
