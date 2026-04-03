import 'package:aqarelmasryeen/core/security/session_lock_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionActivityListener extends ConsumerStatefulWidget {
  const SessionActivityListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SessionActivityListener> createState() =>
      _SessionActivityListenerState();
}

class _SessionActivityListenerState
    extends ConsumerState<SessionActivityListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(
      () =>
          ref.read(sessionLockControllerProvider.notifier).ensureInitialized(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(sessionLockControllerProvider.notifier);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      controller.handlePause();
    } else if (state == AppLifecycleState.resumed) {
      controller.handleResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) =>
          ref.read(sessionLockControllerProvider.notifier).recordActivity(),
      onPointerSignal: (_) =>
          ref.read(sessionLockControllerProvider.notifier).recordActivity(),
      child: widget.child,
    );
  }
}
